import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Legacy BlockPainter для обратной совместимости.
class BlockPainter extends CustomPainter {
  const BlockPainter({
    required this.fill,
    this.light = AppColors.mcStoneLight,
    this.dark = AppColors.mcStoneDark,
    this.border = AppColors.mcInk,
    this.borderWidth = 1,
    this.bevel = 0,
    this.pressed = false,
    this.shadowOffset = const Offset(0, 4),
    this.showShadow = true,
  });

  final Color fill;
  final Color light;
  final Color dark;
  final Color border;
  final double borderWidth;
  final double bevel;
  final bool pressed;
  final Offset shadowOffset;
  final bool showShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = border
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant BlockPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.border != border ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.pressed != pressed;
}

/// Визуальный примитив: премиальная стеклянная карточка в стиле Apple (Glassmorphism & Squircles).
class BlockBox extends StatelessWidget {
  const BlockBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.fill = AppColors.mcStone,
    this.border = AppColors.mcInk,
    this.pressed = false,
    this.borderWidth = 1.0,
    this.bevel = 0,
    this.showShadow = true,
    this.glow,
    this.semanticLabel,
    this.borderRadius,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Alignment? alignment;
  final Color fill;
  final Color border;
  final bool pressed;
  final double borderWidth;
  final double bevel;
  final bool showShadow;
  final Color? glow;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);

    // Подбираем полупрозрачную стеклянную заливку
    Color effectiveFill;
    if (fill == AppColors.mcStone || fill == AppColors.mcDeepslate) {
      effectiveFill = const Color(0x16FFFFFF);
    } else if (fill == AppColors.mcVoid) {
      effectiveFill = const Color(0x0CFFFFFF);
    } else {
      effectiveFill = fill.withOpacity(fill.opacity == 1.0 ? 0.75 : fill.opacity);
    }

    // Подбираем изящный стеклянный кант
    Color effectiveBorder;
    if (border == AppColors.mcInk || border == Colors.black) {
      effectiveBorder = const Color(0x1FFFFFFF);
    } else {
      effectiveBorder = border.withOpacity(border.opacity == 1.0 ? 0.45 : border.opacity);
    }

    Widget content = SizedBox(
      width: width,
      height: height,
      child: padding == null && alignment == null
          ? child
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: alignment == null ? child : Align(alignment: alignment!, child: child),
            ),
    );

    Widget box = ClipRRect(
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: effectiveFill,
          borderRadius: radius,
          border: Border.all(
            color: effectiveBorder,
            width: borderWidth > 2 ? 1.5 : borderWidth,
          ),
          boxShadow: [
            if (glow != null)
              BoxShadow(
                color: glow!.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            if (showShadow)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: content,
      ),
    );

    if (pressed) {
      box = Transform.scale(
        scale: 0.98,
        child: box,
      );
    }

    return Semantics(label: semanticLabel, container: semanticLabel != null, child: box);
  }
}
