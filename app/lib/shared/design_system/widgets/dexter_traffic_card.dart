import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'xp_bar.dart';

/// Карточка Опыта и Трафика с гипнотическим вращающимся градиентным слоем
/// и пульсирующим световым бликом.
/// Вдохновлена концептом dexter-st с Uiverse.io и адаптирована под Minecraft/Ender:
/// - Тёмная обсидиановая основа с деликатным радиальным градиентом (без ослепления).
/// - Вращающийся градиентный слой (gradient-layer, 8 сек) глубоких тонов Края (End violet & emerald XP).
/// - Пульсирующая линзовая полоса света (.light, 3 сек).
/// - Аутентичный XP-бар Minecraft с делениями уровня.
class DexterTrafficCard extends StatefulWidget {
  const DexterTrafficCard({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
    required this.isUnlimited,
    required this.statusText,
    required this.onTap,
  });

  final int usedBytes;
  final int totalBytes;
  final bool isUnlimited;
  final String statusText;
  final VoidCallback onTap;

  @override
  State<DexterTrafficCard> createState() => _DexterTrafficCardState();
}

class _DexterTrafficCardState extends State<DexterTrafficCard>
    with TickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _rotateController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Непрерывное вращение градиентного слоя (8 секунд)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Дыхание световой полосы (3 секунды)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 ГБ';
    const gb = 1024 * 1024 * 1024;
    final val = bytes / gb;
    if (val < 0.1) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${val.toStringAsFixed(1)} ГБ';
  }

  double get _progress {
    if (widget.isUnlimited || widget.totalBytes <= 0) return 0.05;
    return (widget.usedBytes / widget.totalBytes).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;

    final trafficText = widget.isUnlimited
        ? '${_formatBytes(widget.usedBytes)} / ∞'
        : '${_formatBytes(widget.usedBytes)} / ${_formatBytes(widget.totalBytes)}';

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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: const Color(0xFF0C0D14),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.mcEnder.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // 1. Мягкая эфирная авангардная аура опыта (Aurora Mesh Glow)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, _) {
                      // Плавное синусоидальное покачивание ауры без вращения углов
                      final shiftX = math.sin(_rotateController.value * 2 * math.pi) * 0.45;
                      final shiftY = math.cos(_rotateController.value * 2 * math.pi) * 0.20;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(shiftX, shiftY),
                            radius: 1.35,
                            colors: const [
                              Color(0x2E10B981), // Мягкий изумрудный опыт
                              Color(0x1C8B5CF6), // Фиолетовая аура Края
                              Color(0x00000000), // Абсолютно прозрачный край
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. Дышащая световая полоса линзы (dexter-st .light)
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  height: 16,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final pulse = _pulseController.value;

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(
                                alpha: 0.12 + (pulse * 0.18),
                              ),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. Контентная подложка и элементы UI
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x990A0B10), // полупрозрачное затемнение
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя строка: Опыт / Трафик и счётчик
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.data_usage_rounded,
                                size: 15,
                                color: AppColors.mcGrass,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ОПЫТ / ТРАФИК',
                                style: AppTypography.caption(AppColors.mcTextDim)
                                    .copyWith(
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              trafficText,
                              style: AppTypography.caption(AppColors.mcText)
                                  .copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Полоса опыта Minecraft (XpBar)
                      XpBar(
                        progress: _progress,
                        height: 12,
                      ),
                      const SizedBox(height: 10),

                      // Нижняя строка: Статус подписки
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.mcGrass,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mcGrass.withValues(alpha: 0.7),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.statusText,
                            style: AppTypography.caption(AppColors.mcTextDim)
                                .copyWith(
                              fontSize: 11,
                              color: AppColors.mcTextDim.withValues(alpha: 0.8),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Подробнее ›',
                            style: AppTypography.caption(AppColors.mcEnder)
                                .copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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
