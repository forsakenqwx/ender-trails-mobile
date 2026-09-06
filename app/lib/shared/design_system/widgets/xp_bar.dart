import 'package:flutter/material.dart';

/// Шкала расхода трафика в стиле Apple (Capsule Progress Bar).
///
/// Плавный неоновый градиент с закруглёнными концами и пороговым изменением цвета (>80% золото, >95% коралл).
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.progress,
    this.segments = 16,
    this.height = 8,
  }) : assert(progress >= 0 && progress <= 1);

  /// Доля от 0 до 1.
  final double progress;
  final int segments;
  final double height;

  List<Color> get _gradientColors {
    if (progress > 0.95) {
      return const [Color(0xFFFF5252), Color(0xFFD50000)];
    }
    if (progress > 0.8) {
      return const [Color(0xFFFFD600), Color(0xFFFF9100)];
    }
    // Классический сочный градиент опыта Minecraft (Lime / Emerald)
    return const [Color(0xFF76FF03), Color(0xFF10B981), Color(0xFF047857)];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height > 14 ? 10.0 : (height < 6 ? 6.0 : height);
    final radius = BorderRadius.circular(effectiveHeight / 2);

    return Container(
      height: effectiveHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x28000000),
        borderRadius: radius,
        border: Border.all(color: const Color(0x24FFFFFF), width: 1),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // 1. Полоса заполнения опыта
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);

                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: barWidth,
                    height: effectiveHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gradientColors.first.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. Аутентичные деления/сегменты полосы опыта Minecraft
            if (segments > 1)
              Row(
                children: List.generate(segments, (index) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: index < segments - 1
                            ? const Border(
                                right: BorderSide(
                                  color: Color(0x66000000),
                                  width: 1.5,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
