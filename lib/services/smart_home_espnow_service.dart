import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_crop_dryer/models/smart_home_espnow.dart';

class SmartHomeEspNowService {
  DatabaseReference? ref;
  String? _deviceId;
  final DatabaseReference _macRegistryRef = FirebaseDatabase.instance.ref(
    'MacRegistry',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get deviceId => _deviceId;

  SmartHomeEspNowService(String? deviceId) {
    if (deviceId != null && deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartHome/$deviceId/EspNow");
      _deviceId = deviceId;
    }
  }

  void updateDeviceId(String deviceId) {
    if (deviceId.isNotEmpty) {
      ref = FirebaseDatabase.instance.ref("Devices/SmartHome/$deviceId/EspNow");
      _deviceId = deviceId;
    }
  }

  /// Canonical MAC format used for every key comparison/write in this
  /// service: uppercase, colon-separated. Prevents any case/format
  /// mismatch between firmware-written keys and app-written keys.
  static String normalizeMac(String mac) {
    final hex = mac.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();
    final buf = StringBuffer();
    for (int i = 0; i < hex.length; i += 2) {
      if (i > 0) buf.write(':');
      buf.write(hex.substring(i, i + 2 > hex.length ? hex.length : i + 2));
    }
    return buf.toString();
  }

  /// One-off direct read of this device's own MAC, bypassing the normal
  /// provider chain — used as a fallback when that chain is slow to
  /// deliver its first value.
  Future<String?> fetchDeviceMacDirect(String deviceId) async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('Devices/SmartHome/$deviceId/info/macAddress')
          .get();
      if (snap.exists) return snap.value.toString();
    } catch (_) {}
    return null;
  }

  Stream<SmartHomeEspNowState> listenState() {
    return ref!.onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value != null && value is Map) {
            return SmartHomeEspNowState.fromMap(
              Map<String, dynamic>.from(value),
            );
          }
          return SmartHomeEspNowState.empty();
        })
        .handleError((_) => SmartHomeEspNowState.empty());
  }

  /// Tell the node to open a discovery window. Node clears this itself
  /// once the scan window closes (see firmware).
  Future<void> requestScan() async {
    await ref!.child('ScanRequest').set({
      'active': true,
      'requestedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Resolve a raw MAC to its owning device + name.
  Future<DiscoveredNeighbour?> resolveMac(
    String mac, {
    required bool alreadyLinked,
  }) async {
    final normalized = normalizeMac(mac);
    final compact = normalized.replaceAll(':', '');
    final possibleKeys = <String>{
      compact,
      compact.toLowerCase(),
      normalized,
      normalized.toLowerCase(),
    };

    String? targetDeviceId;
    for (final key in possibleKeys) {
      final snap = await _macRegistryRef.child(key).get();
      if (snap.exists) {
        targetDeviceId = snap.value.toString();
        break;
      }
    }

    if (targetDeviceId == null) return null;

    String? resolvedName;
    String? resolvedPhotoUrl;
    String? resolvedOwnerUid;
    final infoSnap = await FirebaseDatabase.instance
        .ref('Devices/SmartHome/$targetDeviceId/info')
        .get();

    if (infoSnap.exists) {
      final info = Map<String, dynamic>.from(infoSnap.value as Map);
      final ownerUid = info['userId']?.toString();

      if (ownerUid != null && ownerUid.isNotEmpty && ownerUid != 'null') {
        resolvedOwnerUid = ownerUid;
        final userDoc = await _firestore
            .collection('Users')
            .doc(ownerUid)
            .get();
        if (userDoc.exists) {
          final firstName = userDoc.data()?['name']?.toString();
          if (firstName != null && firstName.isNotEmpty) {
            resolvedName = firstName;
          }
          final photoUrl = userDoc.data()?['profileImageUrl']?.toString();
          if (photoUrl != null && photoUrl.isNotEmpty) {
            resolvedPhotoUrl = photoUrl;
          }
        }
      }
    }

    if (resolvedName == null) {
      final userQuery = await _firestore
          .collection('Users')
          .where('deviceId', isEqualTo: targetDeviceId)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final firstName = userQuery.docs.first.data()['name']?.toString();
        if (firstName != null && firstName.isNotEmpty) {
          resolvedName = firstName;
        }
      }
    }

    final ownerName = resolvedName != null
        ? "$resolvedName's Home"
        : targetDeviceId;

    return DiscoveredNeighbour(
      mac: normalized,
      deviceId: targetDeviceId,
      ownerName: ownerName,
      alreadyLinked: alreadyLinked,
      ownerPhotoUrl: resolvedPhotoUrl,
      ownerUid: resolvedOwnerUid,
    );
  }

  /// Link to a discovered neighbour: writes both sides.
  Future<void> linkTo({
    required String myMac,
    required String theirMac,
    required String theirDeviceId,
    required String myOwnerName,
    String? myPhotoUrl,
    String? myOwnerUid,
  }) async {
    if (myMac.trim().isEmpty || theirMac.trim().isEmpty) {
      throw Exception(
        'Cannot link: MAC address not yet available. Please try again in a moment.',
      );
    }

    final theirKey = normalizeMac(theirMac);
    final myKey = normalizeMac(myMac);

    // My side: they become a peer I notify
    await ref!.child('PeerMacs').child(theirKey).set(true);

    // Their side: record that I linked to them, so they can see + revoke
    await FirebaseDatabase.instance
        .ref('Devices/SmartHome/$theirDeviceId/EspNow/LinkedBy/$myKey')
        .set({
          'name': myOwnerName,
          'linkedAt': DateTime.now().toIso8601String(),
          'deviceId': _deviceId,
          'photoUrl': myPhotoUrl,
          'ownerUid': myOwnerUid,
        });
  }

  /// Revoke a link that a neighbour made to me (B revoking A's link).
  Future<void> revokeLinkedBy({
    required String myMac,
    required String theirMac,
    required String theirDeviceId,
  }) async {
    final theirKey = normalizeMac(theirMac);
    final myKey = normalizeMac(myMac);

    await ref!.child('LinkedBy').child(theirKey).remove();
    await FirebaseDatabase.instance
        .ref('Devices/SmartHome/$theirDeviceId/EspNow/PeerMacs/$myKey')
        .remove();
  }

  /// A un-linking a neighbour they originally linked to (reverse of linkTo).
  Future<void> unlinkPeer({
    required String myMac,
    required String theirMac,
    required String theirDeviceId,
  }) async {
    final theirKey = normalizeMac(theirMac);
    final myKey = normalizeMac(myMac);

    await ref!.child('PeerMacs').child(theirKey).remove();
    await FirebaseDatabase.instance
        .ref('Devices/SmartHome/$theirDeviceId/EspNow/LinkedBy/$myKey')
        .remove();
  }
}
