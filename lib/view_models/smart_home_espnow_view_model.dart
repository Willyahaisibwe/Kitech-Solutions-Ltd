import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_crop_dryer/models/smart_home_espnow.dart';
import 'package:smart_crop_dryer/services/smart_home_espnow_service.dart';

class SmartHomeEspNowViewModel extends ChangeNotifier {
  final SmartHomeEspNowService espNowService;
  String myMac;
  String myOwnerName;
  String? myPhotoUrl;
  String? myOwnerUid;
  String? _deviceId;

  SmartHomeEspNowState _state = SmartHomeEspNowState.empty();
  SmartHomeEspNowState get state => _state;

  // Optimistic overrides — set the instant the user taps a toggle, so the
  // UI never has to wait on a Firebase round-trip to reflect the action.
  // Cleared automatically once the real stream confirms the same value.
  final Map<String, bool> _optimisticLinked = {};

  List<DiscoveredNeighbour> _resolvedDiscovered = [];
  List<DiscoveredNeighbour> get resolvedDiscovered => _resolvedDiscovered
      .map(
        (n) => DiscoveredNeighbour(
          mac: n.mac,
          deviceId: n.deviceId,
          ownerName: n.ownerName,
          alreadyLinked: _optimisticLinked[_key(n.mac)] ?? n.alreadyLinked,
          ownerPhotoUrl: n.ownerPhotoUrl,
          ownerUid: n.ownerUid,
        ),
      )
      .toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Timer? _scanTimeout;
  bool _scanTimedOut = false;

  bool get isScanning => _isLoading || (_state.scanning && !_scanTimedOut);
  bool get canScan => isReady && !isScanning;
  bool get isReady =>
      _deviceId != null && _deviceId!.isNotEmpty && myMac.isNotEmpty;

  String get readyMessage {
    if (isReady) return '';
    return 'Waiting for your home device to connect...';
  }

  StreamSubscription<SmartHomeEspNowState>? _subscription;
  int _resolveRequestId = 0;
  Timer? _macRetryTimer;

  SmartHomeEspNowViewModel({
    required this.espNowService,
    this.myMac = '',
    this.myOwnerName = '',
    this.myPhotoUrl,
    this.myOwnerUid,
    String? deviceId,
  }) {
    initialize(deviceId: deviceId, myMac: myMac, myOwnerName: myOwnerName);
  }

  String _key(String mac) =>
      mac.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();

  void _listen() {
    _subscription?.cancel();
    _subscription = espNowService.listenState().listen((state) async {
      _state = state;
      if (!_state.scanning) {
        _scanTimedOut = false;
        _scanTimeout?.cancel();
      }

      // Real data has arrived — drop any optimistic override that now
      // matches reality (keeps the map from growing forever, and lets a
      // genuinely different remote change take over cleanly).
      _optimisticLinked.removeWhere((mac, optimisticValue) {
        final realValue =
            _state.peerMacs.containsKey(mac) ||
            _state.peerMacs.keys.any((k) => _key(k) == mac);
        return realValue == optimisticValue;
      });

      notifyListeners();

      final requestId = ++_resolveRequestId;
      await _resolveDiscovered(requestId);
    });
  }

  void initialize({
    String? deviceId,
    required String myMac,
    required String myOwnerName,
  }) {
    this.myMac = myMac;
    this.myOwnerName = myOwnerName;

    if (deviceId != null && deviceId.isNotEmpty) {
      if (_deviceId != deviceId) {
        _deviceId = deviceId;
        espNowService.updateDeviceId(deviceId);
      }
      if (_subscription == null) {
        _listen();
      }
      if (this.myMac.isEmpty) {
        _startMacRetry(deviceId);
      } else {
        _macRetryTimer?.cancel();
      }
    }
  }

  void _startMacRetry(String deviceId) {
    _macRetryTimer?.cancel();
    _macRetryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (myMac.isNotEmpty) {
        timer.cancel();
        return;
      }
      final fetchedMac = await espNowService.fetchDeviceMacDirect(deviceId);
      if (fetchedMac != null && fetchedMac.isNotEmpty) {
        myMac = fetchedMac;
        notifyListeners();
        timer.cancel();
      }
    });
  }

  Future<void> _resolveDiscovered(int requestId) async {
    final macsToResolve = _state.discovered.keys.toList();
    final peerMacsSnapshot = _state.peerMacs;

    final resolved = <DiscoveredNeighbour>[];
    for (final mac in macsToResolve) {
      try {
        final alreadyLinked = peerMacsSnapshot.keys.any(
          (k) => _key(k) == _key(mac),
        );
        final neighbour = await espNowService.resolveMac(
          mac,
          alreadyLinked: alreadyLinked,
        );
        resolved.add(
          neighbour ??
              DiscoveredNeighbour(
                mac: mac,
                deviceId: '',
                ownerName: 'Unknown device',
                alreadyLinked: alreadyLinked,
              ),
        );
      } catch (_) {
        // Skip this MAC on error, keep resolving the rest.
      }
    }

    if (requestId != _resolveRequestId) return;

    _resolvedDiscovered = resolved;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (!isReady) return;

    if (_subscription == null) {
      _listen();
    }

    _scanTimedOut = false;
    _scanTimeout?.cancel();
    _scanTimeout = Timer(const Duration(seconds: 20), () {
      if (_state.scanning) {
        _scanTimedOut = true;
        notifyListeners();
      }
    });

    _state = SmartHomeEspNowState(
      discovered: _state.discovered,
      peerMacs: _state.peerMacs,
      linkedBy: _state.linkedBy,
      scanning: true,
    );
    _isLoading = true;
    notifyListeners();

    try {
      await espNowService.requestScan();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> linkTo(DiscoveredNeighbour neighbour) async {
    // Flip the UI immediately — don't wait for Firebase.
    _optimisticLinked[_key(neighbour.mac)] = true;
    notifyListeners();

    try {
      await espNowService.linkTo(
        myMac: myMac,
        theirMac: neighbour.mac,
        theirDeviceId: neighbour.deviceId,
        myOwnerName: myOwnerName,
        myPhotoUrl: myPhotoUrl,
        myOwnerUid: myOwnerUid,
      );
    } catch (e) {
      // Real write failed — revert the optimistic flip so the UI doesn't
      // lie about a link that was never actually saved.
      _optimisticLinked[_key(neighbour.mac)] = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unlinkPeer(DiscoveredNeighbour neighbour) async {
    // Flip the UI immediately — don't wait for Firebase.
    _optimisticLinked[_key(neighbour.mac)] = false;
    notifyListeners();

    try {
      await espNowService.unlinkPeer(
        myMac: myMac,
        theirMac: neighbour.mac,
        theirDeviceId: neighbour.deviceId,
      );
    } catch (e) {
      _optimisticLinked[_key(neighbour.mac)] = true;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> revokeLinkedBy(String theirMac, String theirDeviceId) async {
    await espNowService.revokeLinkedBy(
      myMac: myMac,
      theirMac: theirMac,
      theirDeviceId: theirDeviceId,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanTimeout?.cancel();
    _macRetryTimer?.cancel();
    super.dispose();
  }
}
