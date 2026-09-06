import 'package:flutter/material.dart';

import '../motion/steps_curve.dart';
import '../theme/app_colors.dart';
import 'block_box.dart';

/// Состояние рычага.
enum LeverState { off, connecting, on, error }

/// Главная кнопка подключения — рычаг.
///
/// Анимация покадровая ([StepsCurve]): рычаг «щёлкает», а не плавно едет.
/// Размер фиксированный 192×192 — это якорь композиции главного экрана.
class LeverButton extends StatelessWidget {
  const LeverButton({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 192,
  });

  final LeverState state;
  final VoidCallback onTap;
  final double size;

  bool get _up => state == LeverState.connecting || state == LeverState.on;

  Color get _fill => switch (state) {
        LeverState.off => AppColors.mcStone,
        LeverState.connecting => const Color(0xFF4A4023),
        LeverState.on => const Color(0xFF253D25),
        LeverState.error => const Color(0xFF3D2320),
      };

  Color? get _glow => switch (state) {
        LeverState.on => AppColors.mcGrass.withValues(alpha: 0.45),
        LeverState.connecting => AppColors.mcGold.withValues(alpha: 0.35),
        LeverState.error => AppColors.mcRedstone.withValues(alpha: 0.45),
        LeverState.off => null,
      };

  Color get _handleColor => switch (state) {
        LeverState.off => AppColors.mcStoneLight,
        LeverState.connecting => AppColors.mcGold,
        LeverState.on => AppColors.mcGrass,
        LeverState.error => AppColors.mcRedstone,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lever',
      child: GestureDetector(
        onTap: onTap,
        child: BlockBox(
          width: size,
          height: size,
          fill: _fill,
          glow: _glow,
          borderWidth: 3,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Направляющая (паз), по которой ходит рукоять
              Align(
                alignment: const Alignment(0, 0.35),
                child: Container(
                  width: 12,
                  height: 84,
                  color: AppColors.mcStoneDark,
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(color: AppColors.mcInk, width: 2),
                  ),
                ),
              ),
              // Основание рычага
              Align(
                alignment: const Alignment(0, 0.72),
                child: BlockBox(
                  width: 64,
                  height: 16,
                  fill: AppColors.mcStoneLight,
                  borderWidth: 3,
                  showShadow: false,
                ),
              ),
              // Рукоять
              AnimatedPositioned(
                duration: AppDurations.lever,
                curve: const StepsCurve(4),
                bottom: _up ? 118 : 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BlockBox(
                      width: 44,
                      height: 16,
                      fill: _handleColor,
                      borderWidth: 3,
                      showShadow: false,
                    ),
                    BlockBox(
                      width: 20,
                      height: 20,
                      fill: AppColors.mcEnder,
                      borderWidth: 3,
                      showShadow: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
