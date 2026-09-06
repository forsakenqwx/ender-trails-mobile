import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Варианты кнопки в стиле Uiverse.io by marcelodolza.
enum BlockButtonVariant { stone, ender, grass, redstone }

/// Премиальная 3D кнопка-капсула (Glass Dome Capsule Button by marcelodolza).
///
/// Характеристики дизайна:
/// - Тёмная обсидиановая основа (#080808) со скруглёнными краями капсулы (radius: 100px).
/// - Многослойная глубина света (inset reflections).
/// - Сферический купол отражения сверху (.wrap::before).
/// - Зеркальный блик стеклянной линзы (.wrap::after).
/// - Тактильный клик (translateY + haptic feedback).
class BlockButton extends StatefulWidget {
  const BlockButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = BlockButtonVariant.stone,
    this.enabled = true,
    this.icon,
    this.height = 52,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onTap;
  final BlockButtonVariant variant;
  final bool enabled;
  final Widget? icon;
  final double height;
  final double? fontSize;

  @override
  State<BlockButton> createState() => _BlockButtonState();
}

class _BlockButtonState extends State<BlockButton> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled;
    final radius = widget.height / 2;

    // Тонкий акцентный контур при необходимости
    final Color accentBorderColor;
    final Color accentGlowColor;
    switch (widget.variant) {
      case BlockButtonVariant.ender:
        accentBorderColor = AppColors.mcEnder.withValues(alpha: 0.45);
        accentGlowColor = AppColors.mcEnder.withValues(alpha: 0.20);
        break;
      case BlockButtonVariant.grass:
        accentBorderColor = const Color(0x33FFFFFF);
        accentGlowColor = Colors.white.withValues(alpha: 0.08);
        break;
      case BlockButtonVariant.redstone:
        accentBorderColor = AppColors.mcRedstone.withValues(alpha: 0.50);
        accentGlowColor = AppColors.mcRedstone.withValues(alpha: 0.20);
        break;
      case BlockButtonVariant.stone:
        accentBorderColor = const Color(0x28FFFFFF);
        accentGlowColor = Colors.transparent;
        break;
    }

    return Semantics(
      button: true,
      enabled: _interactive,
      child: GestureDetector(
        onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _interactive ? () => setState(() => _pressed = false) : null,
        onTap: _interactive
            ? () {
                HapticFeedback.lightImpact();
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.translationValues(0, _pressed ? 2.5 : 0.0, 0),
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFF060608) : const Color(0xFF080808),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: disabled ? const Color(0x14FFFFFF) : accentBorderColor,
                width: 1.0,
              ),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      if (accentGlowColor != Colors.transparent)
                        BoxShadow(
                          color: accentGlowColor,
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // 1. Внутренний линзовый купол отражения (.wrap::before)
                  Positioned(
                    left: -30,
                    right: -30,
                    top: -widget.height * 1.1,
                    height: widget.height * 1.8,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: disabled ? 0.02 : 0.08),
                      ),
                    ),
                  ),

                  // 2. Верхний зеркальный блик стеклянной линзы (.wrap::after)
                  Positioned(
                    top: 2,
                    left: 14,
                    right: 14,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: disabled ? 0.08 : 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Нижний контурный рефлекс
                  Positioned(
                    bottom: 2,
                    left: 20,
                    right: 20,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.white.withValues(alpha: disabled ? 0.02 : 0.08),
                      ),
                    ),
                  ),

                  // 4. Текст и иконка с авто-подгонкой (FittedBox) против вылетов за края
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              IconTheme(
                                data: IconThemeData(
                                  color: disabled
                                      ? AppColors.mcTextMuted
                                      : const Color(0xFFFFFFFF),
                                  size: widget.fontSize != null ? (widget.fontSize! + 2).clamp(14.0, 20.0) : 18.0,
                                ),
                                child: widget.icon!,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: AppTypography.label(
                                disabled ? AppColors.mcTextMuted : const Color(0xFFFFFFFF),
                              ).copyWith(
                                fontSize: widget.fontSize ?? 15,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w600,
                                shadows: disabled
                                    ? null
                                    : [
                                        const Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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
