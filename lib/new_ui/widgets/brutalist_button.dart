import 'package:flutter/material.dart';
import '../theme/brutalist_theme.dart';

enum BrutalButtonStyle { primary, secondary, outlined, dashed }

class BrutalistButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String label;
  final BrutalButtonStyle style;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool isExpanded;
  final TextStyle? textStyle;

  const BrutalistButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.style = BrutalButtonStyle.primary,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.isExpanded = false,
    this.textStyle,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    Color bgColor;
    Color fgColor;
    Border border;
    List<BoxShadow> shadows;

    switch (widget.style) {
      case BrutalButtonStyle.primary:
        bgColor = isEnabled ? BrutalColors.black : BrutalColors.surfaceContainerHigh;
        fgColor = isEnabled ? BrutalColors.white : BrutalColors.textMuted;
        border = BrutalTheme.brutalBorder;
        shadows = isEnabled && !_isPressed ? BrutalTheme.brutalShadowSm : [];
        break;
      case BrutalButtonStyle.secondary:
        bgColor = isEnabled ? BrutalColors.white : BrutalColors.surfaceContainerLow;
        fgColor = isEnabled ? BrutalColors.black : BrutalColors.textMuted;
        border = BrutalTheme.brutalBorder;
        shadows = isEnabled && !_isPressed ? BrutalTheme.brutalShadowSm : [];
        break;
      case BrutalButtonStyle.outlined:
        bgColor = Colors.transparent;
        fgColor = BrutalColors.black;
        border = BrutalTheme.brutalBorder;
        shadows = [];
        break;
      case BrutalButtonStyle.dashed:
        bgColor = BrutalColors.white;
        fgColor = BrutalColors.black;
        border = Border.all(color: BrutalColors.black, width: 1.5);
        shadows = [];
        break;
    }

    final transform = _isPressed && isEnabled
        ? Matrix4.translationValues(1.5, 1.5, 0)
        : Matrix4.identity();

    Widget buttonContent = Container(
      height: widget.height,
      padding: widget.padding,
      transform: transform,
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.textStyle ??
                  BrutalTheme.label(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: widget.isExpanded ? buttonContent : buttonContent,
    );
  }
}
