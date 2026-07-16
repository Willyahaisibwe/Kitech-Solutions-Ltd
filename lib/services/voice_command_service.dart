import 'package:smart_crop_dryer/models/voice_command.dart';

class VoiceCommandResult {
  final bool matched;
  final String spokenResponse;

  VoiceCommandResult({required this.matched, required this.spokenResponse});
}

class VoiceCommandService {
  VoiceCommandResult processCommand({
    required String spokenText,
    required List<VoiceCommand> commands,
  }) {
    final normalized = spokenText.toLowerCase().trim();

    for (final command in commands) {
      for (final trigger in command.triggers) {
        if (normalized.contains(trigger)) {
          double? number;

          if (command.expectsNumber) {
            number = _extractNumber(normalized);
            if (number == null) {
              return VoiceCommandResult(
                matched: false,
                spokenResponse:
                    "I heard the command but couldn't find a number. Please try again, for example, set threshold to 65.",
              );
            }
          }

          final overrideMessage = command.onMatch(number);

          return VoiceCommandResult(
            matched: true,
            spokenResponse: overrideMessage ?? command.confirmationText(number),
          );
        }
      }
    }

    return VoiceCommandResult(
      matched: false,
      spokenResponse:
          "Sorry, I didn't understand that command. Please try again.",
    );
  }

  double? _extractNumber(String text) {
    final digitMatch = RegExp(r'\d+(\.\d+)?').firstMatch(text);
    if (digitMatch != null) {
      return double.tryParse(digitMatch.group(0)!);
    }
    return null;
  }
}
