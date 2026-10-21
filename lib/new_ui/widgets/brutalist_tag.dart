import 'package:flutter/material.dart';
import '../theme/brutalist_theme.dart';

class BrutalistTag extends StatelessWidget {
  final String label;
  final bool inverted;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const BrutalistTag({
    super.key,
    required this.label,
    this.inverted = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (inverted ? BrutalColors.black : BrutalColors.surfaceContainerLow);
    final fg = textColor ?? (inverted ? BrutalColors.white : BrutalColors.black);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: BrutalColors.black, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: BrutalTheme.label(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
