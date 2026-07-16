import 'package:just_audio/just_audio.dart';

/// Single shared audio player for the live radio stream.
///
/// This is a plain singleton (no external package needed) so that the
/// AudioPlayer instance is created once when the app starts and lives
/// for the entire app lifetime — it is never tied to a widget's State,
/// so navigating between pages (even popping all the way back to Home)
/// never disposes it and never interrupts playback.
class RadioPlayerService {
  RadioPlayerService._internal();
  static final RadioPlayerService instance = RadioPlayerService._internal();

  static const String streamUrl = 'https://stream.zeno.fm/dkuhicsenvqtv';

  final AudioPlayer player = AudioPlayer();

  bool get isPlaying => player.playing;

  /// Starts a fresh connection to the live edge of the stream.
  /// Always tears down and reconnects rather than resuming a buffer,
  /// so playback is never stale after a stop/pause.
  Future<void> play() async {
    await player
        .setUrl(streamUrl)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw Exception('Connection to stream timed out');
          },
        );
    // Don't await: play()'s Future only completes when playback ends,
    // which for a live stream is effectively never.
    // ignore: unawaited_futures
    player.play();
  }

  Future<void> stop() => player.stop();

  /// Call this only if/when the app itself is shutting down — do NOT
  /// call this from a widget's dispose(), or you'll reintroduce the
  /// original bug.
  Future<void> disposePlayer() => player.dispose();
}
