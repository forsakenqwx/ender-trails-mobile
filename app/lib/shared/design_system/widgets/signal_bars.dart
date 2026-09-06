import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Индикатор уровня сигнала в стиле Apple iOS.
class SignalBars extends StatelessWidget {
  const SignalBars({
    super.key,
    required this.latencyMs,
    this.bars = 4,
    this.height = 16,
  });

  /// `null` — сервер не отвечает.
  final int? latencyMs;
  final int bars;
  final double height;

  int get _level {
    final ms = latencyMs;
    if (ms == null) return 0;
    if (ms < 120) return 4;
    if (ms < 250) return 3;
    if (ms < 450) return 2;
    return 1;
  }

  Color get _color {
    final ms = latencyMs;
    if (ms == null) return const Color(0x33FFFFFF);
    if (ms < 180) return AppColors.mcGrass;
    if (ms < 350) return AppColors.mcGold;
    return AppColors.mcRedstone;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final color = _color;

    return Semantics(
      label: latencyMs == null ? 'no reply' : '$latencyMs ms',
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(bars, (i) {
            final active = i < level;
            final barHeight = 4.0 + i * (height - 4.0) / (bars - 1);
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 2.5),
              child: Container(
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: active ? color : const Color(0x28FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
