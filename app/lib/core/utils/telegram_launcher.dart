import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Утилита надёжного открытия Telegram-бота (сначала native tg://, затем веб https://t.me/).
class TelegramLauncher {
  const TelegramLauncher._();

  /// Открывает Telegram-бота с указанным payload (start-параметром).
  static Future<bool> openBot({
    String? botUsername,
    String? startParam,
  }) async {
    final bot = botUsername ?? AppConfig.supportBot;
    final queryParams = <String, String>{'domain': bot};
    if (startParam != null && startParam.isNotEmpty) {
      queryParams['start'] = startParam;
    }

    final nativeUri = Uri(
      scheme: 'tg',
      host: 'resolve',
      queryParameters: queryParams,
    );

    final webUri = Uri.https(
      't.me',
      '/$bot',
      startParam != null && startParam.isNotEmpty
          ? {'start': startParam}
          : null,
    );

    // 1. Сначала пробуем открыть нативный клиент Telegram
    try {
      final launched = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launched) return true;
    } catch (_) {}

    // 2. Вторая попытка нативного открытия
    try {
      final launched = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {}

    // 3. Фолбэк на веб https://t.me/...
    try {
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      AppLogger.error('Failed to launch web Telegram: $e');
      return false;
    }
  }

  /// Открытие оплаты/продления в боте.
  static Future<bool> openSubscription() => openBot(startParam: 'subscribe');

  /// Открытие бота для реферала.
  static Future<bool> openReferral(String refCode) =>
      openBot(startParam: 'ref_$refCode');

  /// Открытие профиля/чата пользователя по username (например, @Yuvixshin).
  static Future<bool> openUsername(String username) async {
    final clean = username.replaceAll('@', '').trim();
    return openBot(botUsername: clean);
  }

  /// Открытие прямой связи со службой поддержки (@Yuvixshin).
  static Future<bool> openSupport() =>
      openUsername(AppConfig.supportUsername);
}
