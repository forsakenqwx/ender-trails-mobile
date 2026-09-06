import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/vpn/vpn_engine.dart';
import '../../../../core/vpn/vpn_providers.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/dexter_location_card.dart';
import '../../../../shared/design_system/widgets/dexter_traffic_card.dart';
import '../../../../shared/design_system/widgets/enchanting_matrix_background.dart';
import '../../../../shared/design_system/widgets/marcelo_profile_button.dart';
import '../../../../shared/design_system/widgets/minecraft_pickaxe_icon.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_power_button.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';
import '../../../../shared/design_system/widgets/remote_announcement_card.dart';
import '../../../announcements/presentation/providers/banner_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/subscription_details_dialog.dart';

/// Главный экран подключения Ender Trails VPN.
///
/// Эргономичный, удобный под палец пиксельный интерфейс в стиле The End / Minecraft.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        ref.read(subscriptionProfileProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatSpeed(int bps) {
    if (bps <= 0) return '0 КБ/с';
    const kb = 1024;
    const mb = kb * 1024;
    if (bps >= mb) {
      return '${(bps / mb).toStringAsFixed(1)} МБ/с';
    }
    return '${(bps / kb).toStringAsFixed(0)} КБ/с';
  }

  void _showNoSubscriptionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.mcDeepslate,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.mcStoneLight, width: 1.5),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_rounded, size: 20, color: AppColors.mcEnder),
                  const SizedBox(width: 8),
                  Text(
                    'НУЖЕН КЛЮЧ ДОСТУПА',
                    style: AppTypography.title(AppColors.mcEnder).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Для подключения требуется активный ключ. Получите его в нашем боте или вставьте готовую ссылку.',
                style: AppTypography.caption(AppColors.mcTextDim),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              BlockButton(
                label: 'ВОЙТИ ЧЕРЕЗ TELEGRAM БОТА',
                icon: const Icon(Icons.send_rounded),
                variant: BlockButtonVariant.ender,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
              ),
              const SizedBox(height: 10),
              BlockButton(
                label: 'ВСТАВИТЬ ИЗ БУФЕРА',
                icon: const Icon(Icons.content_paste_rounded),
                variant: BlockButtonVariant.grass,
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text?.trim();
                    if (text != null && text.isNotEmpty) {
                      final token =
                          ref.read(deepLinkServiceProvider).extractToken(text);
                      if (token != null && token.isNotEmpty) {
                        final ok = await ref
                            .read(authControllerProvider.notifier)
                            .loginWithToken(token);
                        if (ok && context.mounted) {
                          PixelToast.show(
                            context,
                            message: 'Ключ успешно применён!',
                            variant: PixelToastVariant.success,
                          );
                          return;
                        }
                      }
                    }
                  } catch (_) {}
                  if (context.mounted) {
                    context.push('/login');
                  }
                },
              ),
              const SizedBox(height: 10),
              BlockButton(
                label: 'ВВЕСТИ КЛЮЧ ВРУЧНУЮ',
                icon: const Icon(Icons.edit_note_rounded),
                variant: BlockButtonVariant.stone,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(vpnConnectionControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final subAsync = ref.watch(subscriptionProfileProvider);
    final bannerAsync = ref.watch(remoteBannerNotifierProvider);

    final isConnected = connState.status == VpnStatus.connected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PixelAppBar(
        title: 'ENDER TRAILS',
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MinecraftPickaxeIcon(
              size: 20,
              isEnder: true,
            ),
            const SizedBox(width: 8),
            Text(
              'ENDER TRAILS',
              style: AppTypography.label(AppColors.mcText).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.mcPurple.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.mcPurpleLight.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Text(
                'BETA',
                style: AppTypography.label(AppColors.mcPurpleLight).copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Глянцевая кнопка профиля (marcelodolza)
          MarceloProfileButton(
            isAuthenticated: authState.isAuthenticated,
            onTap: () {
              if (authState.isAuthenticated) {
                SubscriptionDetailsDialog.show(context);
              } else {
                context.push('/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Живая матрица рун Стола Зачарования Minecraft (SGA Matrix)
          const EnchantingMatrixBackground(),

          // Атмосферные градиентные сферы (Apple Ambient Mesh Glow)
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mcEnder.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mcEnder.withOpacity(0.16),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? AppColors.mcGrass.withOpacity(0.10)
                    : AppColors.mcDiamond.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    color: isConnected
                        ? AppColors.mcGrass.withOpacity(0.14)
                        : AppColors.mcDiamond.withOpacity(0.08),
                    blurRadius: 90,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.mcEnder,
              backgroundColor: AppColors.mcDeepslate,
              onRefresh: () async {
                final ok =
                    await ref.read(subscriptionProfileProvider.notifier).refresh();
                if (context.mounted) {
                  PixelToast.show(
                    context,
                    message: ok
                        ? 'Данные синхронизированы!'
                        : 'Ошибка синхронизации',
                    variant:
                        ok ? PixelToastVariant.success : PixelToastVariant.error,
                  );
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 1. Верхняя секция: баннер для неавторизованного пользователя
                            if (!authState.isAuthenticated) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => context.push('/login'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x188B5CF6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.mcEnder.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.smart_toy_rounded,
                                          size: 22,
                                          color: AppColors.mcEnder,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'ПОДКЛЮЧИ БОТА ИЛИ ВВЕДИ КЛЮЧ',
                                            style: AppTypography.caption(Colors.white).copyWith(
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 20,
                                          color: AppColors.mcEnder,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                            ],

                            // 2. Центральная секция: Кнопка включения -> Локация -> Опыт/трафик
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Кнопка включения (3D гиперкуб)
                                  PixelPowerButton(
                                    status: connState.status,
                                    onTap: () async {
                                      final auth = ref.read(authControllerProvider);
                                      if (!auth.isAuthenticated) {
                                        final savedUrl = await ref
                                            .read(secureStorageProvider)
                                            .getSubscriptionUrl();
                                        if (savedUrl != null && savedUrl.isNotEmpty) {
                                          await ref
                                              .read(authControllerProvider.notifier)
                                              .loginWithToken(savedUrl);
                                        }
                                      }

                                      final ok = await ref
                                          .read(vpnConnectionControllerProvider.notifier)
                                          .toggle();
                                      if (!ok && context.mounted) {
                                        final currentAuth =
                                            ref.read(authControllerProvider);
                                        if (!currentAuth.isAuthenticated) {
                                          _showNoSubscriptionSheet(context);
                                        } else {
                                          PixelToast.show(
                                            context,
                                            message:
                                                '⚠️ Сбой туннеля: проверьте системное разрешение VPN',
                                            variant: PixelToastVariant.error,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Тактильная карточка выбора локации туннеля (dexter-st)
                                  DexterLocationCard(
                                    countryCode: connState.selectedServerCountry,
                                    serverName: connState.selectedServerName,
                                    pingMs: connState.selectedServerPing,
                                    onTap: () => context.go('/servers'),
                                  ),
                                  const SizedBox(height: 14),

                                  // Карточка опыта и трафика с мягкой аурой (dexter-st)
                                  subAsync.maybeWhen(
                                    data: (p) => DexterTrafficCard(
                                      usedBytes: p?.userInfo.usedBytes ?? 0,
                                      totalBytes: p?.userInfo.totalBytes ?? 0,
                                      isUnlimited: p?.userInfo.isUnlimited ?? false,
                                      statusText: p == null
                                          ? 'Подписка активна'
                                          : p.userInfo.isExpired
                                              ? 'Подписка истекла'
                                              : (p.userInfo.expireDate == null
                                                  ? 'Бессрочно'
                                                  : 'Осталось ${p.userInfo.daysRemaining} дн.'),
                                      onTap: () =>
                                          SubscriptionDetailsDialog.show(context),
                                    ),
                                    orElse: () => DexterTrafficCard(
                                      usedBytes: 12 * 1024 * 1024 * 1024,
                                      totalBytes: 100 * 1024 * 1024 * 1024,
                                      isUnlimited: false,
                                      statusText: 'Подписка активна',
                                      onTap: () =>
                                          SubscriptionDetailsDialog.show(context),
                                    ),
                                  ),
                                  if (isConnected) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        '${_formatDuration(connState.duration)}  •  ↓ ${_formatSpeed(connState.traffic.downlinkBps)}  ↑ ${_formatSpeed(connState.traffic.uplinkBps)}',
                                        style: AppTypography.caption(AppColors.mcGrass)
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 3. Онлайн-плашка анонсов и новостей (между блоком опыт/трафик и меню)
                            bannerAsync.maybeWhen(
                              data: (banner) {
                                if (banner == null) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                                  child: RemoteAnnouncementCard(
                                    banner: banner,
                                    onClose: () => ref
                                        .read(remoteBannerNotifierProvider.notifier)
                                        .dismiss(),
                                  ),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),

                            // 4. Нижний отступ под парящий док меню (меню фиксировано)
                            const SizedBox(height: 96),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
