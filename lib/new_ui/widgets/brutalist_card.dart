import 'package:flutter/material.dart';
import '../theme/brutalist_theme.dart';

class BrutalistCard extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enablePressFeedback;
  final double? width;
  final double? height;

  const BrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor = BrutalColors.surface,
    this.border,
    this.boxShadow,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.onTap,
    this.enablePressFeedback = true,
    this.width,
    this.height,
  });

  @override
  State<BrutalistCard> createState() => _BrutalistCardState();
}

class _BrutalistCardState extends State<BrutalistCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.border ?? BrutalTheme.brutalBorder;
    final defaultShadow = widget.boxShadow ?? BrutalTheme.brutalShadow;
    final isInteractive = widget.onTap != null;

    final shadow = _isPressed && widget.enablePressFeedback ? <BoxShadow>[] : defaultShadow;
    final transform = _isPressed && widget.enablePressFeedback
        ? Matrix4.translationValues(2, 2, 0)
        : Matrix4.identity();

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      transform: transform,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: border,
        boxShadow: shadow,
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (isInteractive) {
      return GestureDetector(
        onTapDown: widget.enablePressFeedback ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enablePressFeedback ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enablePressFeedback ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
