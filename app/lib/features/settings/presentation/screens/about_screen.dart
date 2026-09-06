import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/telegram_launcher.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_box.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';
import '../../../../shared/design_system/widgets/stone_panel.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _licenseText = 'Загрузка лицензий...';

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    try {
      final pixCyrillic =
          await rootBundle.loadString('assets/fonts/PixCyrillic-LICENSE.txt');
      setState(() {
        _licenseText = pixCyrillic;
      });
    } catch (_) {
      setState(() {
        _licenseText = 'SIL OPEN FONT LICENSE Version 1.1\n\nCopyright (c) PixCyrillic & Pixellari Authors.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'О ПРИЛОЖЕНИИ',
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
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.mcText,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 52,
                  color: AppColors.mcEnder,
                ),
                const SizedBox(height: 8),
                Text(
                  'Версия ${AppConfig.appVersion} (Сборка ${AppConfig.buildNumber})',
                  style: AppTypography.caption(AppColors.mcTextDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          StonePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ТЕХНИЧЕСКИЙ СТЕК', style: AppTypography.title(AppColors.mcEnder)),
                const SizedBox(height: 8),
                Text('• Ядро: sing-box (libbox / Go runtime)', style: AppTypography.label(AppColors.mcText)),
                const SizedBox(height: 4),
                Text('• Протоколы: VLESS Reality, Trojan, Hysteria 2', style: AppTypography.label(AppColors.mcText)),
                const SizedBox(height: 4),
                Text('• Фреймворк: Flutter 3.47 (Dart 3.13)', style: AppTypography.label(AppColors.mcText)),
                const SizedBox(height: 4),
                Text('• Окружение: ${AppConfig.environment.toUpperCase()}', style: AppTypography.label(AppColors.mcText)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          StonePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('КОНФИДЕНЦИАЛЬНОСТЬ', style: AppTypography.title(AppColors.mcEnder)),
                const SizedBox(height: 8),
                Text(
                  'Мы придерживаемся строгой политики нулевого логирования (No-Logs Policy). Приложение не ведёт историю посещаемых сайтов, DNS-запросов и не собирает личные данные.',
                  style: AppTypography.caption(AppColors.mcText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          StonePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ПОДДЕРЖКА В TELEGRAM', style: AppTypography.title(AppColors.mcEnder)),
                const SizedBox(height: 10),
                BlockButton(
                  label: 'НАПИСАТЬ В ПОДДЕРЖКУ',
                  icon: const Icon(
                    Icons.support_agent_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  variant: BlockButtonVariant.ender,
                  onTap: () async {
                    final ok = await TelegramLauncher.openSupport();
                    if (!ok && context.mounted) {
                      PixelToast.show(
                        context,
                        message: 'Поддержка: @${AppConfig.supportUsername}',
                        variant: PixelToastVariant.info,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('ЛИЦЕНЗИИ ШРИФТОВ (SIL OFL 1.1)', style: AppTypography.title(AppColors.mcEnder)),
          const SizedBox(height: 8),
          BlockBox(
            fill: AppColors.mcStoneDark,
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 160,
              child: SingleChildScrollView(
                child: Text(
                  _licenseText,
                  style: AppTypography.caption(AppColors.mcTextDim),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
