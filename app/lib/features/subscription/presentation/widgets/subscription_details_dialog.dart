import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/subscription_profile.dart';
import '../../domain/parsers/subscription_userinfo_parser.dart';
import '../providers/subscription_providers.dart';
import 'ender_pass_ticket.dart';

/// Диалог детальной информации о подписке (Ender Pass '26 Ticket).
///
/// Дизайн:
/// - Чистый парящий билет без фоновой карточки-обёртки.
/// - Внутри билета расположена кнопка «ПРОДЛИТЬ В TELEGRAM».
/// - Закрытие профиля выполняется интерактивным отрыванием нижнего корешка билета.
class SubscriptionDetailsDialog extends ConsumerWidget {
  const SubscriptionDetailsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      barrierDismissible: true,
      builder: (_) => const SubscriptionDetailsDialog(),
    );
  }

  static const _defaultProfile = SubscriptionProfile(
    userInfo: SubscriptionUserInfo(
      uploadBytes: 0,
      downloadBytes: 0,
      totalBytes: 0,
    ),
    outbounds: [],
    singboxConfig: '',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProfileProvider);
    final session = ref.watch(authControllerProvider).session;
    final userName = session?.username;

    final profile = subAsync.value ?? _defaultProfile;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Парящий билет Ender Pass '26 с отрывным корешком
              EnderPassTicket(
                profile: profile,
                userName: userName,
                onTorn: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),

              const SizedBox(height: 18),

              // 2. Полупрозрачный текст-подсказка для закрытия
              Text(
                'проведите по нижней части чтоб закрыть',
                style: AppTypography.caption(
                  Colors.white.withValues(alpha: 0.40),
                ).copyWith(
                  letterSpacing: 0.4,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
