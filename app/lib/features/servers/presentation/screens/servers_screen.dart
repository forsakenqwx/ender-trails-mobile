import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import '../../../../core/vpn/vpn_providers.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/furnace_loader.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/server_row.dart';
import '../providers/servers_providers.dart';

/// Экран выбора серверов в пиксельном стиле.
class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(vpnConnectionControllerProvider);
    final serversAsync = ref.watch(serversNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'СЕРВЕРЫ',
        actions: [
          const _PingRefreshButton(),
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x18FFFFFF),
                border: Border.all(color: const Color(0x22FFFFFF), width: 1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close_rounded, color: AppColors.mcText, size: 20),
            ),
          ),
        ],
      ),
      body: serversAsync.when(
        data: (servers) {
          if (servers.isEmpty) {
            return Center(
              child: Text(
                'Список узлов пуст',
                style: AppTypography.label(AppColors.mcTextDim),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: servers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _WhitelistBadgeCard();
              }
              final server = servers[index - 1];
              final isSelected =
                  connState.selectedServerName == server.name ||
                  (server.isAuto && connState.selectedServerCountry == 'AUTO') ||
                  connState.selectedServerCountry == server.countryCode;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ServerRow(
                  countryCode: server.countryCode,
                  name: server.name,
                  protocol: server.protocol,
                  pingMs: server.pingMs ?? 0,
                  selected: isSelected,
                  onTap: () {
                    ref.read(serversNotifierProvider.notifier).selectServer(server);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: FurnaceLoader(),
        ),
        error: (err, _) => Center(
          child: Text(
            'Ошибка загрузки серверов',
            style: AppTypography.label(AppColors.mcRedstone),
          ),
        ),
      ),
    );
  }
}

/// Отзывчивая кнопка замера пинга с анимацией вращения и тактильным откликом
class _PingRefreshButton extends ConsumerStatefulWidget {
  const _PingRefreshButton();

  @override
  ConsumerState<_PingRefreshButton> createState() => _PingRefreshButtonState();
}

class _PingRefreshButtonState extends ConsumerState<_PingRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPinging = ref.watch(isPingingProvider);

    if (isPinging && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!isPinging && _anim.isAnimating) {
      _anim.stop();
      _anim.reset();
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (isPinging) return;
        HapticFeedback.mediumImpact();
        ref.read(serversNotifierProvider.notifier).refreshPings();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPinging ? const Color(0x3310B981) : const Color(0x18FFFFFF),
            border: Border.all(
              color: isPinging ? AppColors.mcGrass : const Color(0x22FFFFFF),
              width: 1.2,
            ),
            boxShadow: isPinging
                ? [
                    BoxShadow(
                      color: AppColors.mcGrass.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: RotationTransition(
            turns: _anim,
            child: const Icon(
              Icons.refresh_rounded,
              color: AppColors.mcGrass,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Плашка «Все страны в белых списках» с изумрудным бейджем и статусом 100%
class _WhitelistBadgeCard extends StatelessWidget {
  const _WhitelistBadgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1219),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mcEmerald.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mcEmerald.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.mcEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.mcEmerald.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.mcEmerald,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ВСЕ СТРАНЫ В БЕЛЫХ СПИСКАХ',
                  style: AppTypography.label(AppColors.mcText).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Узлы оптимизированы и работают без блокировок',
                  style: AppTypography.caption(AppColors.mcTextDim).copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.mcEmerald.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.mcEmerald.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.mcEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '100%',
                  style: AppTypography.label(AppColors.mcEmerald).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
