/// Represents a single voice command pattern and what to do when matched.
class VoiceCommand {
  final List<String> triggers;
  final bool expectsNumber;

  /// Called when this command matches. Should return null if it succeeded
  /// (in which case [confirmationText] is spoken), or a String with an
  /// override message if it couldn't proceed (e.g. device offline) —
  /// that override message is spoken instead.
  final String? Function(double? number) onMatch;

  final String Function(double? number) confirmationText;

  VoiceCommand({
    required this.triggers,
    this.expectsNumber = false,
    required this.onMatch,
    required this.confirmationText,
  });
}
