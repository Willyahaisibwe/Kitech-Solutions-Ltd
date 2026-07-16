import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smart_crop_dryer/services/radio_player_service.dart';

class RadioPlayerCard extends StatefulWidget {
  const RadioPlayerCard({super.key});

  @override
  State<RadioPlayerCard> createState() => _RadioPlayerCardState();
}

class _RadioPlayerCardState extends State<RadioPlayerCard> {
  final _service = RadioPlayerService.instance;

  bool _isConnecting = false;
  bool _hasError = false;

  // NOTE: no AudioPlayer created here, and no dispose() override that
  // touches the player. The player belongs to RadioPlayerService and
  // outlives this widget, so navigating away never stops playback.

  Future<void> _togglePlayback() async {
    if (_service.isPlaying) {
      await _service.stop();
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _isConnecting = true;
      _hasError = false;
    });

    try {
      await _service.play();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      color: primary.withValues(alpha: .06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primary.withValues(alpha: .15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<PlayerState>(
          // Listening to the shared player's stream means this card
          // (and any other card built elsewhere) always reflects the
          // real, current playback state — even if playback was
          // started from a different screen instance.
          stream: _service.player.playerStateStream,
          builder: (context, snapshot) {
            final isPlaying = _service.isPlaying;

            String label;
            if (_hasError) {
              label = "Couldn't connect. Tap to retry.";
            } else if (isPlaying) {
              label = 'Live now';
            } else if (_isConnecting) {
              label = 'Connecting...';
            } else {
              label = 'Tap play to listen';
            }

            return Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.radio, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kitech Radio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: _hasError
                              ? Colors.red.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isConnecting ? null : _togglePlayback,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isConnecting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
