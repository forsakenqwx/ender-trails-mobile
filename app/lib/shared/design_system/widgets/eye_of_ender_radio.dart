import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Радио-селектор в стиле «Око Края» и «Оправа портала в Энд».
///
/// Вдохновлен компонентом с Uiverse.io (by the404_1512).
/// При активации Око Края вылетает слева с аутентичной кинематикой
/// `cubic-bezier(1, -0.4, 0, 1.4)` — замах назад, ускорение и упругий овершут
/// прямо в гнездо портала.
class EyeOfEnderRadio extends StatefulWidget {
  const EyeOfEnderRadio({
    super.key,
    required this.selected,
    this.size = 28.0,
    this.onTap,
  });

  /// Выбран ли данный элемент.
  final bool selected;

  /// Размер внешнего гнезда (диаметр).
  final double size;

  /// Опциональный коллбэк клика.
  final VoidCallback? onTap;

  @override
  State<EyeOfEnderRadio> createState() => _EyeOfEnderRadioState();
}

class _EyeOfEnderRadioState extends State<EyeOfEnderRadio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    // Точная кривая из CSS: cubic-bezier(1, -0.4, 0, 1.4)
    const overshootCurve = Cubic(1.0, -0.4, 0.0, 1.4);

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: overshootCurve,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: overshootCurve,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.75, curve: Curves.easeIn),
    );

    if (widget.selected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant EyeOfEnderRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketSize = widget.size;
    final eyeSize = widget.size * 0.76;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: socketSize,
        height: socketSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Оправа портала в Энд (Гнездо сокета)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: socketSize,
              height: socketSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected
                    ? const Color(0x33064E3B)
                    : const Color(0x1A000000),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.mcGrass
                      : const Color(0x33FFFFFF),
                  width: widget.selected ? 2.2 : 1.8,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: AppColors.mcGrass.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Container(
                  width: socketSize * 0.6,
                  height: socketSize * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selected
                        ? const Color(0x2210B981)
                        : const Color(0x0DFFFFFF),
                  ),
                ),
              ),
            ),

            // 2. Око Края (Шар с текстурой и кинематикой Uiverse)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.value == 0.0) {
                  return const SizedBox.shrink();
                }

                // Вылетает справа, но строго в пределах экрана (не более 24px вправо)
                final translationX =
                    ((1.0 - _slideAnimation.value) * (socketSize * 0.65))
                        .clamp(-6.0, 24.0);

                return Positioned(
                  left: (socketSize - eyeSize) / 2 + translationX,
                  top: (socketSize - eyeSize) / 2,
                  child: Opacity(
                    opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _scaleAnimation.value.clamp(0.1, 1.4),
                      child: Container(
                        width: eyeSize,
                        height: eyeSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: Size(eyeSize, eyeSize),
                          painter: const EyeOfEnderPainter(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Высокопроизводительный 120 FPS рендерер текстуры Ока Края (Eye of Ender).
///
/// Рисует 3D-сферу изумрудного цвета с глубоким градиентом, огненный зрачок
/// Края и реалистичные блики без использования шейдеров или размытия на GPU.
class EyeOfEnderPainter extends CustomPainter {
  const EyeOfEnderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Тело сферы: многослойный 3D изумрудный градиент с освещением сверху-слева
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [
          Color(0xFF34D399), // Яркий изумрудный блик
          Color(0xFF10B981), // Основной малахитовый цвет Ока
          Color(0xFF059669), // Плотный темный изумруд
          Color(0xFF064E3B), // Глубокая тень Края
          Color(0xFF022C22), // Внешний темный край
        ],
        stops: const [0.0, 0.35, 0.65, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // 2. Внешняя тонкая темная окантовка сферы
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x66022C22);
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    // 3. Вертикальный огненный зрачок Края (Ender Pupil)
    // 3.1 Внешнее огненное свечение (янтарно-оранжевое)
    final outerIrisPath = Path();
    final irisWidth = size.width * 0.32;
    final irisHeight = size.height * 0.64;
    outerIrisPath.addOval(
      Rect.fromCenter(
        center: center,
        width: irisWidth,
        height: irisHeight,
      ),
    );
    final outerIrisPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawPath(outerIrisPath, outerIrisPaint);

    // 3.2 Внутреннее яркое золотое пламя
    final innerFlamePath = Path();
    final flameWidth = size.width * 0.18;
    final flameHeight = size.height * 0.48;
    innerFlamePath.addOval(
      Rect.fromCenter(
        center: center,
        width: flameWidth,
        height: flameHeight,
      ),
    );
    final innerFlamePaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawPath(innerFlamePath, innerFlamePaint);

    // 3.3 Центральный вертикальный зрачок (темный обсидиановый разрез)
    final pupilPath = Path();
    final pupilWidth = math.max(1.5, size.width * 0.08);
    final pupilHeight = size.height * 0.34;
    pupilPath.addOval(
      Rect.fromCenter(
        center: center,
        width: pupilWidth,
        height: pupilHeight,
      ),
    );
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawPath(pupilPath, pupilPaint);

    // 4. Спекулярные световые блики (3D объём)
    // 4.1 Основной яркий блик сверху-слева
    final highlightPaint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.fill;
    final highlightCenter = Offset(
      center.dx - radius * 0.36,
      center.dy - radius * 0.36,
    );
    canvas.drawCircle(highlightCenter, radius * 0.22, highlightPaint);

    // 4.2 Микро-блик рядом для реалистичного стеклянного блеска
    final microHighlightPaint = Paint()
      ..color = const Color(0x8CFFFFFF)
      ..style = PaintingStyle.fill;
    final microCenter = Offset(
      center.dx - radius * 0.16,
      center.dy - radius * 0.54,
    );
    canvas.drawCircle(microCenter, radius * 0.10, microHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
