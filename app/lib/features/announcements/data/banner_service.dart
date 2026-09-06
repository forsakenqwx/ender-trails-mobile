import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/entities/remote_banner.dart';

/// Сервис загрузки и кэширования онлайн-баннера анонсов.
class BannerService {
  const BannerService({
    required this.storage,
    this.httpClient,
  });

  final AppSecureStorage storage;
  final http.Client? httpClient;

  static const _bannerUrl = 'https://endertrails.online/aggr/banner';

  /// Загружает актуальный баннер с сервера.
  /// Возвращает null при ошибке сети, отключенном баннере или пустом тексте.
  Future<RemoteBanner?> fetchBanner() async {
    final client = httpClient ?? http.Client();
    try {
      final res = await client
          .get(
            Uri.parse(_bannerUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final banner = RemoteBanner.fromJson(data);
      if (!banner.enabled || banner.text.trim().isEmpty) {
        return null;
      }

      // Проверяем, не был ли этот баннер уже закрыт пользователем
      final dismissedId = await storage.getDismissedBannerId();
      if (dismissedId != null && dismissedId == banner.id) {
        return null;
      }

      return banner;
    } catch (e) {
      AppLogger.debug('Failed to fetch remote banner: $e');
      return null;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Закрывает баннер и сохраняет его ID в хранилище.
  Future<void> dismissBanner(String bannerId) async {
    try {
      await storage.saveDismissedBannerId(bannerId);
    } catch (e) {
      AppLogger.warning('Failed to save dismissed banner id: $e');
    }
  }
}
