import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/block_button.dart';
import '../widgets/furnace_loader.dart';
import '../widgets/lever_button.dart';
import '../widgets/pixel_app_bar.dart';
import '../widgets/pixel_switch.dart';
import '../widgets/pixel_toast.dart';
import '../widgets/redstone_lamp.dart';
import '../widgets/signal_bars.dart';
import '../widgets/stone_panel.dart';
import '../widgets/xp_bar.dart';

/// Экран-витрина дизайн-системы (Showcase).
///
/// Предназначен для визуальной валидации и утверждения стиля всех компонентов:
/// LeverButton, RedstoneLamp, XpBar, SignalBars, BlockButton, StonePanel,
/// PixelSwitch, FurnaceLoader, PixelToast.
class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState
    extends State<DesignSystemShowcaseScreen> {
  LeverState _leverState = LeverState.off;
  bool _switchValue = false;
  double _xpProgress = 0.45;

  void _cycleLeverState() {
    setState(() {
      _leverState = switch (_leverState) {
        LeverState.off => LeverState.connecting,
        LeverState.connecting => LeverState.on,
        LeverState.on => LeverState.error,
        LeverState.error => LeverState.off,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: const PixelAppBar(
        title: 'ENDER TRAILS · SHOWCASE',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секция 1: Главный интерактивный рычаг
          _SectionHeader(title: 'LEVER BUTTON (192x192)'),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                LeverButton(
                  state: _leverState,
                  onTap: _cycleLeverState,
                ),
                const SizedBox(height: 12),
                Text(
                  'Нажмите для переключения (Текущее: ${_leverState.name.toUpperCase()})',
                  style: AppTypography.caption(AppColors.mcTextDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция 2: Редстоун-лампы и статусы
          _SectionHeader(title: 'REDSTONE LAMPS & STATUSES'),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              children: [
                _StatusRow(
                  lamp: const RedstoneLamp(color: AppColors.mcStoneLight, lit: false),
                  label: 'ОТКЛЮЧЕНО (DISCONNECTED)',
                  color: AppColors.mcTextDim,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  lamp: const RedstoneLamp(color: AppColors.mcGold),
                  label: 'ПОДКЛЮЧАЕМСЯ... (CONNECTING)',
                  color: AppColors.mcGold,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  lamp: const RedstoneLamp(color: AppColors.mcGrass),
                  label: 'ПОДКЛЮЧЕНО (CONNECTED)',
                  color: AppColors.mcGrass,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  lamp: const RedstoneLamp(color: AppColors.mcRedstone),
                  label: 'ОШИБКА (ERROR)',
                  color: AppColors.mcRedstone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция 3: Шкала опыта (XP Bar / Трафик)
          _SectionHeader(title: 'XP BAR (TRAFFIC)'),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Норма (<80%): ${(_xpProgress * 100).toInt()}%',
                  style: AppTypography.caption(AppColors.mcText),
                ),
                const SizedBox(height: 6),
                XpBar(progress: _xpProgress),
                const SizedBox(height: 12),
                Text(
                  'Предупреждение (>80%): 85%',
                  style: AppTypography.caption(AppColors.mcGold),
                ),
                const SizedBox(height: 6),
                const XpBar(progress: 0.85),
                const SizedBox(height: 12),
                Text(
                  'Критический (>95%): 98%',
                  style: AppTypography.caption(AppColors.mcRedstone),
                ),
                const SizedBox(height: 6),
                const XpBar(progress: 0.98),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BlockButton(
                        label: '-10% XP',
                        onTap: () {
                          setState(() {
                            _xpProgress = (_xpProgress - 0.1).clamp(0.0, 1.0);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BlockButton(
                        label: '+10% XP',
                        onTap: () {
                          setState(() {
                            _xpProgress = (_xpProgress + 0.1).clamp(0.0, 1.0);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция 4: Пинг серверов (SignalBars)
          _SectionHeader(title: 'SIGNAL BARS (PING)'),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              children: [
                _SignalRow(pingMs: 45, label: '< 100 ms (Green)'),
                const SizedBox(height: 8),
                _SignalRow(pingMs: 140, label: '< 200 ms (Light Green)'),
                const SizedBox(height: 8),
                _SignalRow(pingMs: 280, label: '< 350 ms (Gold)'),
                const SizedBox(height: 8),
                _SignalRow(pingMs: 420, label: '> 350 ms (Red)'),
                const SizedBox(height: 8),
                _SignalRow(pingMs: null, label: 'Нет ответа (Grey)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция 5: Кнопки-блоки (BlockButtons)
          _SectionHeader(title: 'BLOCK BUTTONS'),
          const SizedBox(height: 12),
          Column(
            children: [
              BlockButton(
                label: 'STONE BUTTON (DEFAULT)',
                onTap: () {},
                variant: BlockButtonVariant.stone,
              ),
              const SizedBox(height: 8),
              BlockButton(
                label: 'ENDER BUTTON (PRIMARY)',
                onTap: () {},
                variant: BlockButtonVariant.ender,
              ),
              const SizedBox(height: 8),
              BlockButton(
                label: 'GRASS BUTTON (SUCCESS)',
                onTap: () {},
                variant: BlockButtonVariant.grass,
              ),
              const SizedBox(height: 8),
              BlockButton(
                label: 'REDSTONE BUTTON (DANGER)',
                onTap: () {},
                variant: BlockButtonVariant.redstone,
              ),
              const SizedBox(height: 8),
              const BlockButton(
                label: 'DISABLED BUTTON',
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Секция 6: Тумблер и Печь-лоадер
          _SectionHeader(title: 'SWITCH & FURNACE LOADER'),
          const SizedBox(height: 12),
          StonePanel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PixelSwitch(
                      value: _switchValue,
                      onChanged: (val) => setState(() => _switchValue = val),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _switchValue ? 'ВКЛ' : 'ВЫКЛ',
                      style: AppTypography.label(AppColors.mcText),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'FURNACE:',
                      style: AppTypography.caption(AppColors.mcTextDim),
                    ),
                    const SizedBox(width: 8),
                    const FurnaceLoader(size: 40),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция 7: Уведомления (PixelToast)
          _SectionHeader(title: 'PIXEL TOAST'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BlockButton(
                  label: 'INFO TOAST',
                  variant: BlockButtonVariant.stone,
                  onTap: () {
                    PixelToast.show(
                      context,
                      message: 'Локация обновлена!',
                      variant: PixelToastVariant.info,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BlockButton(
                  label: 'ERROR TOAST',
                  variant: BlockButtonVariant.redstone,
                  onTap: () {
                    PixelToast.show(
                      context,
                      message: 'Ошибка туннеля',
                      variant: PixelToastVariant.error,
                      actionLabel: 'ПОВТОР',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.title(AppColors.mcEnder),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.lamp,
    required this.label,
    required this.color,
  });

  final Widget lamp;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        lamp,
        const SizedBox(width: 12),
        Text(label, style: AppTypography.label(color)),
      ],
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.pingMs, required this.label});

  final int? pingMs;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption(AppColors.mcText)),
        SignalBars(latencyMs: pingMs),
      ],
    );
  }
}
