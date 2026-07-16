import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_crop_dryer/models/voice_command.dart';
import 'package:smart_crop_dryer/services/voice_command_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// A tappable mic button that listens for speech, matches it against
/// a provided list of [commands], executes the match, and speaks a
/// confirmation back to the user.
class VoiceCommandButton extends StatefulWidget {
  final List<VoiceCommand> commands;
  final Color activeColor;

  const VoiceCommandButton({
    super.key,
    required this.commands,
    this.activeColor = Colors.blue,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final VoiceCommandService _commandService = VoiceCommandService();

  bool _isListening = false;
  String _lastWords = '';

  Future<void> _startListening() async {
    final micStatus = await Permission.microphone.request();
    print('🎤 Mic permission status: $micStatus');

    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for voice commands.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('🎤 Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print(
          '🎤 Speech error: ${error.errorMsg}, permanent: ${error.permanent}',
        );
        setState(() => _isListening = false);
      },
    );

    print('🎤 Speech available: $available');

    if (available) {
      setState(() {
        _isListening = true;
        _lastWords = '';
      });

      _speech.listen(
        onResult: (result) {
          print(
            '🎤 Recognized so far: ${result.recognizedWords}, final: ${result.finalResult}',
          );
          setState(() {
            _lastWords = result.recognizedWords;
          });

          if (result.finalResult) {
            _handleFinalResult(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 5),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available on this device.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _handleFinalResult(String spokenText) async {
    if (spokenText.trim().isEmpty) return;

    final result = _commandService.processCommand(
      spokenText: spokenText,
      commands: widget.commands,
    );

    await _tts.speak(result.spokenResponse);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.matched ? 'Heard: "$spokenText"' : result.spokenResponse,
          ),
          backgroundColor: result.matched ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isListening
              ? Colors.red.withValues(alpha: .15)
              : widget.activeColor.withValues(alpha: .1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? Colors.red : widget.activeColor,
          size: 22,
        ),
      ),
    );
  }
}
