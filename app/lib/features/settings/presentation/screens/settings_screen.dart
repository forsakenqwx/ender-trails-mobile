import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_switch.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';
import '../../../../shared/design_system/widgets/stone_panel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';

/// Экран настроек приложения.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final settings = settingsAsync.value ?? const AppSettings();
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'НАСТРОЙКИ',
        actions: [
          GestureDetector(
            onTap: () => context.pop(),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('АККАУНТ И ПОДПИСКА', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Статус:', style: AppTypography.caption(AppColors.mcTextDim)),
                    Text(
                      authState.isAuthenticated ? 'ПРИВЯЗАН' : 'НЕ АВТОРИЗОВАН',
                      style: AppTypography.label(
                        authState.isAuthenticated ? AppColors.mcGrass : AppColors.mcRedstone,
                      ),
                    ),
                  ],
                ),
                if (authState.session?.subscriptionUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ссылка: ${authState.session!.subscriptionUrl!}',
                    style: AppTypography.caption(AppColors.mcTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (authState.isAuthenticated) ...[
            BlockButton(
              label: 'СИНХРОНИЗИРОВАТЬ АККАУНТ',
              icon: const Icon(Icons.refresh_rounded),
              variant: BlockButtonVariant.ender,
              fontSize: 13.5,
              onTap: () async {
                final ok = await ref.read(subscriptionProfileProvider.notifier).refresh();
                if (context.mounted) {
                  PixelToast.show(
                    context,
                    message: ok ? 'Аккаунт синхронизирован!' : 'Ошибка синхронизации',
                    variant: ok ? PixelToastVariant.success : PixelToastVariant.error,
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: BlockButton(
                    label: 'СМЕНИТЬ КЛЮЧ',
                    icon: const Icon(Icons.key_rounded, size: 16),
                    variant: BlockButtonVariant.stone,
                    fontSize: 12.5,
                    onTap: () => context.push('/login'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BlockButton(
                    label: 'ВЫЙТИ',
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    variant: BlockButtonVariant.stone,
                    fontSize: 12.5,
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        PixelToast.show(
                          context,
                          message: 'Вы вышли из аккаунта',
                          variant: PixelToastVariant.info,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            BlockButton(
              label: 'ВОЙТИ / ПРИВЯЗАТЬ АККАУНТ',
              icon: const Icon(Icons.login_rounded),
              variant: BlockButtonVariant.grass,
              onTap: () => context.push('/login'),
            ),
          ],
          const SizedBox(height: 24),

          Text('СЕТЬ И БЕЗОПАСНОСТЬ', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              children: [
                _SettingSwitchRow(
                  title: 'Kill Switch',
                  subtitle: 'Блокировать интернет при обрыве туннеля',
                  value: settings.killSwitch,
                  onChanged: notifier.updateKillSwitch,
                ),
                const Divider(),
                _SettingSwitchRow(
                  title: 'Bypass LAN',
                  subtitle: 'Прямой доступ к локальной сети и роутеру',
                  value: settings.bypassLan,
                  onChanged: notifier.updateBypassLan,
                ),
                const Divider(),
                _SettingSwitchRow(
                  title: 'Автоподключение',
                  subtitle: 'Поднимать туннель при старте приложения',
                  value: settings.autoConnect,
                  onChanged: notifier.updateAutoConnect,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('БЕЗОПАСНЫЙ DNS', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              children: DnsProvider.values.map((dns) {
                final isSelected = settings.dnsProvider == dns;
                return GestureDetector(
                  onTap: () => notifier.updateDnsProvider(dns),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: dns != DnsProvider.values.last
                            ? const BorderSide(color: AppColors.mcStoneDark)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.mcGrass : AppColors.mcStoneDark,
                            border: Border.all(
                              color: isSelected ? AppColors.mcInk : AppColors.mcStoneLight,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? const Icon(Icons.check, size: 12, color: AppColors.mcInk)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dns.name, style: AppTypography.label(AppColors.mcText)),
                              const SizedBox(height: 2),
                              Text(
                                dns.description,
                                style: AppTypography.caption(AppColors.mcTextDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Text('РАЗДЕЛЬНОЕ ТУННЕЛИРОВАНИЕ', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          StonePanel(
            child: Column(
              children: [
                _SettingSwitchRow(
                  title: 'Обход для приложений',
                  subtitle: 'Банки и российские сервисы в обход VPN',
                  value: settings.splitTunnelingEnabled,
                  onChanged: notifier.updateSplitTunneling,
                ),
                if (settings.splitTunnelingEnabled) ...[
                  const Divider(),
                  GestureDetector(
                    onTap: () => context.push('/settings/split-tunneling'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.apps_rounded,
                            size: 20,
                            color: AppColors.mcGrass,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Выбор приложений',
                                  style: AppTypography.label(AppColors.mcText),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.bypassedPackages.isEmpty
                                      ? 'Нажмите, чтобы выбрать приложения'
                                      : 'Выбрано: ${settings.bypassedPackages.length} (идут в обход VPN)',
                                  style: AppTypography.caption(
                                    settings.bypassedPackages.isEmpty
                                        ? AppColors.mcTextDim
                                        : AppColors.mcGrass,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.mcTextDim,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('БОНУСЫ И ДРУЗЬЯ', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          BlockButton(
            label: 'РЕФЕРАЛКА И ПРОМОКОДЫ',
            icon: const Icon(
              Icons.card_giftcard_rounded,
              size: 18,
              color: Colors.white,
            ),
            variant: BlockButtonVariant.grass,
            onTap: () => context.push('/referral'),
          ),
          const SizedBox(height: 24),

          Text('ДИАГНОСТИКА', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          BlockButton(
            label: 'ЛОГИ ЯДРА (SING-BOX)',
            variant: BlockButtonVariant.stone,
            onTap: () => context.push('/logs'),
          ),
          const SizedBox(height: 10),
          BlockButton(
            label: 'ВИТРИНА ДИЗАЙН-СИСТЕМЫ',
            variant: BlockButtonVariant.stone,
            onTap: () => context.push('/showcase'),
          ),
          const SizedBox(height: 24),

          Text('О ПРИЛОЖЕНИИ', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 12),
          BlockButton(
            label: 'О ПРИЛОЖЕНИИ И ЛИЦЕНЗИИ',
            variant: BlockButtonVariant.ender,
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.label(AppColors.mcText)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption(AppColors.mcTextDim)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PixelSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
