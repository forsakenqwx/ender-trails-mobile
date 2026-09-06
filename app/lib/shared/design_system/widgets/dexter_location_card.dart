import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'minecraft_flag.dart';
import '../../../features/servers/domain/utils/country_detector.dart';

/// Тактильная карточка выбора локации туннеля с многослойными тенями и фаской.
/// Вдохновлена концептом dexter-st с Uiverse.io:
/// - Базовая пластина глубокого тёмного цвета (#10121A).
/// - Многоуровневые внутренние тени (inset highlights сверху, тень снизу).
/// - Верхний световой кант с бирюзовым отливом Края (hsl 210°).
/// - Нежное дыхание свечения пинга и статуса.
class DexterLocationCard extends StatefulWidget {
  const DexterLocationCard({
    super.key,
    required this.countryCode,
    required this.serverName,
    required this.pingMs,
    required this.onTap,
  });

  final String countryCode;
  final String serverName;
  final int? pingMs;
  final VoidCallback onTap;

  @override
  State<DexterLocationCard> createState() => _DexterLocationCardState();
}

class _DexterLocationCardState extends State<DexterLocationCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;

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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final shimmer = _shimmerController.value;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10121A),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0x33FFFFFF),
                    const Color(0x6638BDF8),
                    shimmer * 0.4,
                  )!,
                  width: 1.2,
                ),
                boxShadow: [
                  // Внешняя мягкая тень блока
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  // Верхний неоновый кант (dexter-st ::after highlight)
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(
                      alpha: 0.08 + (shimmer * 0.08),
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Верхний внутренний световой срез (specular top highlight)
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    height: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.35),
                            const Color(0xFF38BDF8).withValues(alpha: 0.50),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Контент карточки
                  Row(
                    children: [
                      // 1. Пиксельный флаг страны
                      MinecraftFlag(
                        countryCode: widget.countryCode,
                        width: 44,
                        height: 30,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 14),

                      // 2. Название локации и подпись
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ЛОКАЦИЯ ТУННЕЛЯ',
                              style: AppTypography.caption(AppColors.mcTextDim)
                                  .copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.6,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.serverName.isNotEmpty
                                  ? CountryDetector.cleanServerName(widget.serverName)
                                  : 'Авто-выбор',
                              style: AppTypography.label(AppColors.mcText)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 3. Пинг-бейдж
                      if (widget.pingMs != null && widget.pingMs! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1F10B981),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0x3310B981),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.pingMs} мс',
                            style: AppTypography.caption(AppColors.mcGrass)
                                .copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 4. Шеврон перехода
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color.lerp(
                          AppColors.mcTextDim,
                          Colors.white,
                          shimmer * 0.5,
                        ),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
