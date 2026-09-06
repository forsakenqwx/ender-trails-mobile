import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.storage,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  final AppSecureStorage storage;
  final http.Client httpClient;

  @override
  Future<String> getDeviceId() => storage.getOrCreateHwid();

  @override
  Future<AuthSession?> getCurrentSession() async {
    final access = await storage.getAccessToken();
    final refresh = await storage.getRefreshToken();
    final subUrl = await storage.getSubscriptionUrl();

    if (access == null && subUrl == null) {
      return null;
    }

    return AuthSession(
      accessToken: access ?? 'direct-session',
      refreshToken: refresh ?? 'direct-session',
      subscriptionUrl: subUrl,
    );
  }

  @override
  Future<Result<AuthSession>> loginWithToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      return fail(const AuthFailure(debugMessage: 'Token is empty'));
    }

    // Извлекаем чистый shortUuid, если передан полный URL или deep link
    String shortUuid = cleanToken;
    if (shortUuid.contains('/')) {
      final uri = Uri.tryParse(shortUuid);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        shortUuid = uri.pathSegments.last;
      }
    }
    shortUuid = shortUuid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

    // Собираем валидный URL подписки:
    String targetUrl = cleanToken;
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://${AppConfig.subDomain}/aggr/$shortUuid';
    }

    AppLogger.info('Saving auth session: shortUuid=$shortUuid, targetUrl=$targetUrl');

    final session = AuthSession(
      accessToken: shortUuid.isNotEmpty ? shortUuid : cleanToken,
      refreshToken: shortUuid.isNotEmpty ? shortUuid : cleanToken,
      subscriptionUrl: targetUrl,
    );

    // Сохраняем сессию сразу же, без блокирующих сетевых вызовов
    await storage.saveAuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      subscriptionUrl: targetUrl,
    );

    // В фоновом режиме прогреваем подписку, не задерживая UI
    unawaited(
      httpClient.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent': 'v2rayNG/1.8.5 (Android; okhttp)',
          'Accept': 'text/plain, application/json, */*',
        },
      ).then((res) {
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          storage.saveCachedSubBody(res.body.trim());
          final userinfo = res.headers['subscription-userinfo'];
          if (userinfo != null && userinfo.isNotEmpty) {
            storage.saveCachedUserinfo(userinfo);
          }
          AppLogger.info('Background sub cache warm-up succeeded');
        }
      }).catchError((e) {
        AppLogger.warning('Background sub cache warm-up error: $e');
      }),
    );

    return ok(session);
  }

  @override
  Future<Result<AuthSession>> refreshToken() async {
    final currentRefresh = await storage.getRefreshToken();
    if (currentRefresh == null) {
      return fail(const AuthFailure(debugMessage: 'No refresh token'));
    }

    final hwid = await storage.getOrCreateHwid();

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/v1/auth/refresh');
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': currentRefresh,
          'deviceId': hwid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;

        await storage.saveAuthSession(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        return ok(
          AuthSession(
            accessToken: newAccess,
            refreshToken: newRefresh,
            subscriptionUrl: await storage.getSubscriptionUrl(),
          ),
        );
      } else {
        await storage.clearAuth();
        return fail(const AuthFailure(debugMessage: 'Refresh failed'));
      }
    } catch (e) {
      return fail(NetworkFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<ResultUnit> logout() async {
    try {
      final refresh = await storage.getRefreshToken();
      final hwid = await storage.getOrCreateHwid();
      if (refresh != null) {
        final url = Uri.parse('${AppConfig.apiBaseUrl}/v1/auth/logout');
        await httpClient.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refresh, 'deviceId': hwid}),
        );
      }
    } catch (_) {}
    await storage.clearAuth();
    return okUnit;
  }
}
