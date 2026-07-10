import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String text;
  final bool isEnabled;

  final List<Color> gradientColors;
  final Color textColor;
  final Color? shadowColor;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.isEnabled = true,
    this.gradientColors = const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    this.textColor = Colors.white,
    this.shadowColor,
    this.textStyle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedBorderRadius =
        borderRadius ?? BorderRadius.circular(8.0);

    // Fixed consistent padding:
    const EdgeInsets fixedPadding =
        EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    final List<Color> activeGradient = isEnabled
        ? gradientColors
        : [Colors.grey.shade400, Colors.grey.shade500];

    final Color activeTextColor = isEnabled ? textColor : Colors.grey.shade700;

    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: Material(
        elevation: isEnabled ? 4 : 0,
        shadowColor: shadowColor ?? Colors.black.withValues(alpha: .3),
        color: Colors.transparent,
        borderRadius: resolvedBorderRadius,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: resolvedBorderRadius,
          splashColor: Colors.white.withValues(alpha: .1),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: activeGradient),
              borderRadius: resolvedBorderRadius,
            ),
            child: Padding(
              padding: fixedPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(color: activeTextColor),
                    child: icon,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: textStyle ??
                        TextStyle(
                          color: activeTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
