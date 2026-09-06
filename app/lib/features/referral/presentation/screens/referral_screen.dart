import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/telegram_launcher.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_box.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/furnace_loader.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';
import '../../../../shared/design_system/widgets/stone_panel.dart';
import '../providers/referral_providers.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _promoController = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplying = true);
    final repo = ref.read(referralRepositoryProvider);
    final success = await repo.applyPromoCode(code);
    setState(() => _isApplying = false);

    if (mounted) {
      if (success) {
        _promoController.clear();
        PixelToast.show(
          context,
          message: 'Промокод успешно активирован!',
          variant: PixelToastVariant.success,
        );
      } else {
        PixelToast.show(
          context,
          message: 'Неверный или просроченный промокод',
          variant: PixelToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final refAsync = ref.watch(referralInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'РЕФЕРАЛКА',
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
      body: refAsync.when(
        data: (info) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(
                  Icons.card_giftcard_rounded,
                  size: 52,
                  color: AppColors.mcEnder,
                ),
                  const SizedBox(height: 8),
                  Text('ПРИГЛАШАЙ ДРУЗЕЙ', style: AppTypography.headline(AppColors.mcEnder)),
                  const SizedBox(height: 4),
                  Text(
                    info.rewardText,
                    style: AppTypography.caption(AppColors.mcTextDim),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Карточки статистики
            Row(
              children: [
                Expanded(
                  child: StonePanel(
                    child: Column(
                      children: [
                        Text('ДРУЗЕЙ', style: AppTypography.caption(AppColors.mcTextDim)),
                        const SizedBox(height: 4),
                        Text(
                          '${info.invitedCount}',
                          style: AppTypography.headline(AppColors.mcGrass),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StonePanel(
                    child: Column(
                      children: [
                        Text('БОНУСЫ', style: AppTypography.caption(AppColors.mcTextDim)),
                        const SizedBox(height: 4),
                        Text(
                          '+${info.bonusDaysEarned} дн.',
                          style: AppTypography.headline(AppColors.mcGold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Реферальный код и ссылка
            Text('ТВОЙ РЕФЕРАЛЬНЫЙ КОД', style: AppTypography.title(AppColors.mcEnder)),
            const SizedBox(height: 8),
            BlockBox(
              fill: AppColors.mcStoneDark,
              border: AppColors.mcLapis,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(info.code, style: AppTypography.title(AppColors.mcText)),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.copy, color: AppColors.mcPearl, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: info.link));
                      PixelToast.show(
                        context,
                        message: 'Реферальная ссылка скопирована!',
                        variant: PixelToastVariant.success,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            BlockButton(
              label: 'СКОПИРОВАТЬ ССЫЛКУ',
              icon: const Icon(Icons.content_copy_rounded),
              variant: BlockButtonVariant.stone,
              onTap: () {
                Clipboard.setData(ClipboardData(text: info.link));
                PixelToast.show(
                  context,
                  message: 'Реферальная ссылка скопирована!',
                  variant: PixelToastVariant.success,
                );
              },
            ),
            const SizedBox(height: 10),

            BlockButton(
              label: 'ОТКРЫТЬ В TELEGRAM',
              icon: const Icon(Icons.send_rounded),
              variant: BlockButtonVariant.grass,
              onTap: () => TelegramLauncher.openReferral(info.code),
            ),
            const SizedBox(height: 28),

            // Промокоды
            Text('ПРОМОКОД', style: AppTypography.title(AppColors.mcEnder)),
            const SizedBox(height: 8),
            StonePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTypography.label(AppColors.mcText),
                    decoration: InputDecoration(
                      hintText: 'Введи промокод...',
                      hintStyle: AppTypography.caption(AppColors.mcTextDim),
                      filled: true,
                      fillColor: AppColors.mcStoneDark,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.mcEnder, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isApplying)
                    const Center(child: FurnaceLoader())
                  else
                    BlockButton(
                      label: 'АКТИВИРОВАТЬ ПРОМОКОД',
                      variant: BlockButtonVariant.ender,
                      onTap: _applyPromo,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        loading: () => const Center(child: FurnaceLoader()),
        error: (err, _) => Center(
          child: Text(
            'Ошибка загрузки реферальных данных',
            style: AppTypography.label(AppColors.mcRedstone),
          ),
        ),
      ),
    );
  }
}
