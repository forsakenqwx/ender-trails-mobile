import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Безопасное хранилище токенов и аппаратного идентификатора устройства (HWID).
class AppSecureStorage {
  AppSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'ender_trails_db',
                publicKey: 'ender_trails_secure_key',
              ),
            );

  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keySubUrl = 'auth_sub_url';
  static const _keyHwid = 'device_hwid';
  static const _keyOnboardingSeen = 'onboarding_seen';
  static const _keySelectedServer = 'selected_server_tag';
  static const _keyAppSettings = 'app_settings_json';

  /// Возвращает существующий или генерирует новый стойкий HWID устройства.
  Future<String> getOrCreateHwid() async {
    final existing = await _storage.read(key: _keyHwid);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newHwid = const Uuid().v4();
    await _storage.write(key: _keyHwid, value: newHwid);
    return newHwid;
  }

  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    String? subscriptionUrl,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    if (subscriptionUrl != null) {
      await _storage.write(key: _keySubUrl, value: subscriptionUrl);
    }
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getSubscriptionUrl() => _storage.read(key: _keySubUrl);

  Future<void> saveSubscriptionUrl(String url) =>
      _storage.write(key: _keySubUrl, value: url);

  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keySubUrl);
  }

  Future<bool> isOnboardingSeen() async {
    final val = await _storage.read(key: _keyOnboardingSeen);
    return val == 'true';
  }

  Future<void> setOnboardingSeen(bool seen) async {
    await _storage.write(key: _keyOnboardingSeen, value: seen ? 'true' : 'false');
  }

  Future<String?> getSelectedServerTag() => _storage.read(key: _keySelectedServer);

  Future<void> saveSelectedServerTag(String tag) =>
      _storage.write(key: _keySelectedServer, value: tag);

  Future<String?> getSettingsJson() => _storage.read(key: _keyAppSettings);

  Future<void> saveSettingsJson(String json) =>
      _storage.write(key: _keyAppSettings, value: json);

  static const _keyCachedSub = 'cached_sub_body';
  static const _keyCachedUserinfo = 'cached_userinfo_header';

  Future<String?> getCachedSubBody() => _storage.read(key: _keyCachedSub);

  Future<void> saveCachedSubBody(String body) =>
      _storage.write(key: _keyCachedSub, value: body);

  Future<String?> getCachedUserinfo() => _storage.read(key: _keyCachedUserinfo);

  Future<void> saveCachedUserinfo(String header) =>
      _storage.write(key: _keyCachedUserinfo, value: header);

  static const _keyDismissedBanner = 'dismissed_banner_id';

  Future<String?> getDismissedBannerId() =>
      _storage.read(key: _keyDismissedBanner);

  Future<void> saveDismissedBannerId(String id) =>
      _storage.write(key: _keyDismissedBanner, value: id);
}
