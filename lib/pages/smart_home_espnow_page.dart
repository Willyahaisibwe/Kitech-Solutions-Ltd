import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/smart_home_espnow.dart';
import 'package:smart_crop_dryer/view_models/smart_home_espnow_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartHomeEspNowPage extends StatefulWidget {
  const SmartHomeEspNowPage({super.key});

  @override
  State<SmartHomeEspNowPage> createState() => _SmartHomeEspNowPageState();
}

class _SmartHomeEspNowPageState extends State<SmartHomeEspNowPage> {
  bool _watchingExpanded = false;
  bool _nearbyExpanded =
      true; // start expanded — usually the primary thing users check

  @override
  Widget build(BuildContext context) {
    final espNowVM = context.watch<SmartHomeEspNowViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Neighbour Alerts",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Neighbourhood Watch",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Link nearby Smart Homes so your alarm can reach them for help.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: espNowVM.canScan ? () => espNowVM.startScan() : null,
                icon: espNowVM.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.wifi_tethering_outlined),
                label: Text(
                  !espNowVM.isReady
                      ? 'Waiting for device setup'
                      : espNowVM.isScanning
                      ? 'Scanning nearby...'
                      : 'Scan for neighbours',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              espNowVM.isReady
                  ? espNowVM.isScanning
                        ? 'Scanning for nearby homes...'
                        : 'Tap the button to scan nearby homes.'
                  : espNowVM.readyMessage,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _nearbyExpanded = !_nearbyExpanded),
              child: Row(
                children: [
                  Expanded(child: _sectionHeader("Nearby Homes")),
                  if (espNowVM.resolvedDiscovered.isNotEmpty) ...[
                    Text(
                      "${espNowVM.resolvedDiscovered.length}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _nearbyExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_nearbyExpanded) ...[
              if (espNowVM.isScanning && espNowVM.resolvedDiscovered.isEmpty)
                _emptyState(
                  icon: Icons.wifi_find_outlined,
                  text: "Looking for nearby Smart Homes...",
                )
              else if (espNowVM.resolvedDiscovered.isEmpty)
                _emptyState(
                  icon: Icons.wifi_find_outlined,
                  text:
                      "No neighbours found yet. Tap the button above to scan.",
                )
              else
                ...espNowVM.resolvedDiscovered.map(
                  (n) => _neighbourCard(
                    context: context,
                    espNowVM: espNowVM,
                    neighbour: n,
                  ),
                ),
            ],

            if (espNowVM.state.linkedBy.isNotEmpty) ...[
              const SizedBox(height: 28),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    setState(() => _watchingExpanded = !_watchingExpanded),
                child: Row(
                  children: [
                    Expanded(
                      child: _sectionHeader("Neighbours Watching Your Home"),
                    ),
                    Text(
                      "${espNowVM.state.linkedBy.length}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _watchingExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "These neighbours will be alerted if they trigger their alarm. You can remove them at any time.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (_watchingExpanded) ...[
                const SizedBox(height: 10),
                ...espNowVM.state.linkedBy.entries.map(
                  (entry) => _linkedByCard(
                    context: context,
                    espNowVM: espNowVM,
                    mac: entry.key,
                    info: entry.value,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }

  Widget _emptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? photoUrl, {String? ownerUid}) {
    const size = 44.0;

    // If we know the owner's uid, listen live so the photo updates the
    // instant they change it — no relink/toggle needed.
    if (ownerUid != null && ownerUid.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(ownerUid)
            .snapshots(),
        builder: (context, snapshot) {
          final livePhotoUrl =
              snapshot.data?.data()?['profileImageUrl']?.toString() ?? photoUrl;
          if (livePhotoUrl != null && livePhotoUrl.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                livePhotoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                key: ValueKey(livePhotoUrl),
                errorBuilder: (_, __, ___) => _avatarFallback(),
              ),
            );
          }
          return _avatarFallback();
        },
      );
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          key: ValueKey(photoUrl),
          errorBuilder: (_, __, ___) => _avatarFallback(),
        ),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.home_outlined, color: Colors.blue),
    );
  }

  Widget _neighbourCard({
    required BuildContext context,
    required SmartHomeEspNowViewModel espNowVM,
    required DiscoveredNeighbour neighbour,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(neighbour.ownerPhotoUrl, ownerUid: neighbour.ownerUid),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  neighbour.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  !espNowVM.isReady
                      ? "Connecting..."
                      : neighbour.alreadyLinked
                      ? "Linked"
                      : "Nearby",
                  style: TextStyle(
                    fontSize: 12,
                    color: neighbour.alreadyLinked
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                  ),
                ),
                if (neighbour.ownerName == 'Unknown device')
                  Text(
                    neighbour.mac,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          !espNowVM.isReady
              ? const SizedBox(
                  width: 40,
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Switch(
                  value: neighbour.alreadyLinked,
                  activeThumbColor: Colors.green.shade700,
                  onChanged: (value) async {
                    try {
                      if (value) {
                        await espNowVM.linkTo(neighbour);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Linked with ${neighbour.ownerName}",
                              ),
                            ),
                          );
                        }
                      } else {
                        await espNowVM.unlinkPeer(neighbour);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Unlinked from ${neighbour.ownerName}",
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Couldn't update link: $e"),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _linkedByCard({
    required BuildContext context,
    required SmartHomeEspNowViewModel espNowVM,
    required String mac,
    required LinkedByEntry info,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(info.photoUrl, ownerUid: info.ownerUid),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Can alert your home",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400),
            tooltip: "Remove",
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text("Remove ${info.name}?"),
                  content: Text(
                    "Are you sure you want to remove ${info.name}? "
                    "They will no longer be able to alert your home.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Yes, Remove",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await espNowVM.revokeLinkedBy(mac, info.deviceId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Removed ${info.name}")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
