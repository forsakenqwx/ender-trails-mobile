import 'package:flutter/animation.dart';

/// Ступенчатая кривая — «покадровая» анимация.
///
/// Пиксельный стиль требует дискретных кадров: плавный easing здесь выглядит чужеродно.
/// `StepsCurve(4)` даёт 4 кадра за длительность.
class StepsCurve extends Curve {
  const StepsCurve(this.steps) : assert(steps > 0);

  final int steps;

  @override
  double transformInternal(double t) {
    if (t >= 1.0) return 1.0;
    return (t * steps).floor() / steps;
  }
}

/// Длительности анимаций. Кратны «кадру» 40 мс.
abstract final class AppDurations {
  static const tap = Duration(milliseconds: 80);
  static const screen = Duration(milliseconds: 160);
  static const lever = Duration(milliseconds: 320);
  static const furnace = Duration(milliseconds: 400);
}
