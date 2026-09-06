import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'eye_of_ender_radio.dart';
import 'minecraft_flag.dart';
import 'signal_bars.dart';
import '../../../features/servers/domain/utils/country_detector.dart';

/// Строка сервера в стиле Apple (iOS Glass Server Row).
class ServerRow extends StatefulWidget {
  const ServerRow({
    super.key,
    required this.countryCode,
    required this.name,
    this.protocol = 'VLESS · Reality',
    this.pingMs,
    this.selected = false,
    this.onTap,
  });

  final String countryCode;
  final String name;
  final String protocol;
  final int? pingMs;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<ServerRow> createState() => _ServerRowState();
}

class _ServerRowState extends State<ServerRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: radius,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 66,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.selected
                    ? const Color(0x288B5CF6)
                    : const Color(0x14FFFFFF),
                borderRadius: radius,
                border: Border.all(
                  color: widget.selected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0x1AFFFFFF),
                  width: widget.selected ? 1.5 : 1.0,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Пиксельный флаг страны Minecraft
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: MinecraftFlag(
                      countryCode: widget.countryCode,
                      width: 28,
                      height: 19,
                      borderRadius: 4,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Название и протокол (максимальная ширина)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CountryDetector.cleanServerName(widget.name),
                          style: AppTypography.label(
                            widget.selected ? Colors.white : AppColors.mcText,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.protocol,
                          style: AppTypography.caption(AppColors.mcTextDim).copyWith(
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Компактный бейдж: Сигнал-бары + Пинг
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0x1AFFFFFF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SignalBars(latencyMs: widget.pingMs),
                        const SizedBox(width: 5),
                        Text(
                          widget.pingMs == null || widget.pingMs == 0 ? '---' : '${widget.pingMs} мс',
                          style: AppTypography.caption(
                            widget.pingMs != null && widget.pingMs! > 0 && widget.pingMs! < 180
                                ? AppColors.mcGrass
                                : AppColors.mcTextDim,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Радио-селектор «Око Края»
                  EyeOfEnderRadio(
                    selected: widget.selected,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
