import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Кнопка профиля с эффектом глубокого стеклянного линзового купола.
/// Вдохновлена концептом marcelodolza с Uiverse.io:
/// - Тёмная обсидиановая основа (#080808) с радиусом скругления капсулы.
/// - Многослойные внутренние блики (inset highlights) сверху и снизу.
/// - Стеклянный полусферический купол отражения (curved dome reflection).
/// - Тактильное смещение при нажатии (translateY + haptic feedback).
class MarceloProfileButton extends StatefulWidget {
  const MarceloProfileButton({
    super.key,
    required this.isAuthenticated,
    required this.onTap,
  });

  final bool isAuthenticated;
  final VoidCallback onTap;

  @override
  State<MarceloProfileButton> createState() => _MarceloProfileButtonState();
}

class _MarceloProfileButtonState extends State<MarceloProfileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const double btnHeight = 36.0;
    const double radius = 18.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0.0, 0),
          height: btnHeight,
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0E),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: widget.isAuthenticated
                  ? AppColors.mcEnder.withValues(alpha: 0.55)
                  : const Color(0x33FFFFFF),
              width: 1.0,
            ),
            boxShadow: [
              // Внешняя мягкая тень парения
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (widget.isAuthenticated)
                BoxShadow(
                  color: AppColors.mcEnder.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Верхний зеркальный блик стеклянной линзы (.wrap::after)
                Positioned(
                  top: 2,
                  left: 8,
                  right: 8,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Нижний контурный рефлекс
                Positioned(
                  bottom: 2,
                  left: 12,
                  right: 12,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // 3. Содержимое: иконка + текст «Профиль»
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          widget.isAuthenticated
                              ? Icons.person_rounded
                              : Icons.vpn_key_rounded,
                          size: 16,
                          color: widget.isAuthenticated
                              ? Colors.white
                              : AppColors.mcTextDim,
                          shadows: [
                            Shadow(
                              color: widget.isAuthenticated
                                  ? AppColors.mcEnder
                                  : Colors.black,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        // Зелёный статус активной подписки
                        if (widget.isAuthenticated)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mcGrass,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mcGrass.withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Профиль',
                      style: const TextStyle(
                        fontFamily: 'PixCyrillic',
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
