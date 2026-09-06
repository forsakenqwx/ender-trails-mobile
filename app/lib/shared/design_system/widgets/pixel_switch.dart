import 'package:flutter/material.dart';

/// Тактильный физический переключатель в стиле Uiverse.io (by njesenberger).
///
/// Обладает реалистичной металлической/пластиковой фаской, углубленным треком,
/// слайдерной кнопкой с 3D-тенями, 3 выдавленными точками захвата (grip dots)
/// и янтарно-золотой подсветкой (#f3b519) во включенном состоянии.
class PixelSwitch extends StatelessWidget {
  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFFF3B519),
    this.inactiveColor = const Color(0xFFE8E8E8),
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    // Базовые пропорции согласно оригинальному CSS (1em = 18.0dp)
    const em = 18.0;
    const trackWidth = 3.0 * em; // 54.0
    const trackHeight = 1.5 * em; // 27.0
    const padding = 0.125 * em; // 2.25
    const wrapperRadius = 0.5 * em; // 9.0
    const trackRadius = 0.375 * em; // 6.75
    const buttonSize = 1.375 * em; // 24.75
    const buttonRadius = 0.3125 * em; // 5.6
    const leftUnchecked = 0.0625 * em; // 1.125
    const leftChecked = 1.5625 * em; // 28.125

    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          width: trackWidth + (padding * 2),
          height: trackHeight + (padding * 2),
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(wrapperRadius),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD5D5D5),
                Color(0xFFE8E8E8),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99FFFFFF),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            width: trackWidth,
            height: trackHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(trackRadius),
              color: value ? activeColor : inactiveColor,
              border: Border.all(
                color: value ? const Color(0x40B37F09) : const Color(0x33000000),
                width: 1.0,
              ),
              boxShadow: [
                // Имитация inset shadow 0 0 .0625em .125em rgb(255 255 255 / .2)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  offset: const Offset(0, 0),
                  blurRadius: 1.5,
                  spreadRadius: 0.5,
                ),
                // Имитация глубокого внутреннего углубления трека
                BoxShadow(
                  color: Colors.black.withValues(alpha: value ? 0.2 : 0.35),
                  offset: const Offset(0, 1.2),
                  blurRadius: 2.0,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Внутренняя легкая градиентная тень для эффекта углубления
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(trackRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: value ? 0.15 : 0.25),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45],
                      ),
                    ),
                  ),
                ),

                // Ползунок (слайдерная кнопка)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  left: value ? leftChecked : leftUnchecked,
                  top: (trackHeight - buttonSize) / 2,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonRadius),
                      color: const Color(0xFFE8E8E8),
                      border: Border(
                        top: const BorderSide(color: Color(0x80FFFFFF), width: 1.4),
                        left: const BorderSide(color: Color(0x40FFFFFF), width: 1.0),
                        right: const BorderSide(color: Color(0x26000000), width: 1.0),
                        bottom: const BorderSide(color: Color(0x33000000), width: 1.6),
                      ),
                      boxShadow: const [
                        // Внешняя тень ползунка
                        BoxShadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 2.0),
                          blurRadius: 2.2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: index == 1 ? 2.0 : 0),
                          width: 2.6,
                          height: 2.6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(0.0, -0.6),
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFB0B0B0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                offset: Offset(0, 0.6),
                                blurRadius: 0.6,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
