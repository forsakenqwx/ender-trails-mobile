import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';

/// Сервис обработки deep links приложения (endertrails://auth?token=...).
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  final _tokenController = StreamController<String>.broadcast();

  Stream<String> get tokenStream => _tokenController.stream;

  /// Инициализирует прослушивание ссылок.
  Future<void> initialize() async {
    if (kIsWeb) {
      try {
        final base = Uri.base;
        if (base.queryParameters.isNotEmpty) {
          AppLogger.info('Web initial query params detected: ${base.queryParameters}');
          _handleUri(base);
        }
      } catch (e) {
        AppLogger.warning('Failed to parse web initial URI: $e');
      }
    }

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      AppLogger.warning('Failed to get initial deep link: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (err) {
        AppLogger.warning('Deep link stream error: $err');
      },
    );
  }

  void _handleUri(Uri uri) {
    AppLogger.info('Received deep link: $uri');

    // 1. Проверяем query параметры (?token=..., ?key=..., ?sub=..., ?url=...)
    String? token = uri.queryParameters['token'] ??
        uri.queryParameters['key'] ??
        uri.queryParameters['sub'] ??
        uri.queryParameters['url'] ??
        uri.queryParameters['link'];

    if (token != null && token.isNotEmpty) {
      final extracted = extractToken(token);
      if (extracted != null && extracted.isNotEmpty) {
        token = extracted;
      }
    }

    // 2. Если ссылка формата endertrails://auth/<token>
    if (token == null || token.isEmpty) {
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last != 'auth' && last != 'login' && last.isNotEmpty) {
          token = last;
        }
      }
    }

    // 3. Если host сам является токеном (например, endertrails://<token>)
    if ((token == null || token.isEmpty) && uri.scheme == 'endertrails') {
      if (uri.host.isNotEmpty && uri.host != 'auth' && uri.host != 'login') {
        token = uri.host;
      }
    }

    // 4. Если это прямая https ссылка на подписку
    if (token == null && uri.scheme.startsWith('http') && uri.path.contains('/aggr/')) {
      token = uri.toString();
    }

    if (token != null && token.trim().isNotEmpty) {
      AppLogger.info('Emitting deep link auth token: $token');
      _tokenController.add(token.trim());
    }
  }

  /// Парсинг произвольной строки (если пользователь вставил ссылку вручную или из буфера).
  String? extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('happ://add/')) {
      final after = trimmed.substring('happ://add/'.length).trim();
      if (after.isNotEmpty) return extractToken(after);
    }

    if (trimmed.startsWith('endertrails://')) {
      try {
        final uri = Uri.parse(trimmed);
        final param = uri.queryParameters['token'] ??
            uri.queryParameters['key'] ??
            uri.queryParameters['sub'] ??
            uri.queryParameters['url'];
        if (param != null && param.isNotEmpty) return param;
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
          return uri.pathSegments.last;
        }
        if (uri.host.isNotEmpty && uri.host != 'auth') {
          return uri.host;
        }
      } catch (_) {
        return null;
      }
    }

    // Если это прямая sub-ссылка (http:// или https://)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Если это share-ссылка (vless://, vmess:// и т.д.)
    if (trimmed.contains('://')) {
      return trimmed;
    }

    // Если это просто токен, UUID или код
    return trimmed;
  }

  void dispose() {
    _linkSub?.cancel();
    _tokenController.close();
  }
}
