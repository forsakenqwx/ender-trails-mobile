import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/builder/singbox_config_builder.dart';
import '../../domain/entities/outbound_ref.dart';
import '../../domain/entities/subscription_profile.dart';
import '../../domain/parsers/share_link_parser.dart';
import '../../domain/parsers/subscription_userinfo_parser.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required this.storage,
    http.Client? httpClient,
    this.linkParser = const ShareLinkParser(),
    this.configBuilder = const SingboxConfigBuilder(),
    this.userinfoParser = const SubscriptionUserInfoParser(),
  }) : httpClient = httpClient ?? http.Client();

  final AppSecureStorage storage;
  final http.Client httpClient;
  final ShareLinkParser linkParser;
  final SingboxConfigBuilder configBuilder;
  final SubscriptionUserInfoParser userinfoParser;

  SubscriptionProfile? _cachedProfile;
  String? _cachedUrl;

  @override
  Future<SubscriptionProfile?> getCachedProfile() async {
    if (_cachedProfile != null) return _cachedProfile;

    try {
      final savedBody = await storage.getCachedSubBody();
      if (savedBody != null && savedBody.isNotEmpty) {
        final savedUserInfoStr = await storage.getCachedUserinfo();
        final userInfo = userinfoParser.parse(savedUserInfoStr) ??
            const SubscriptionUserInfo(
              uploadBytes: 0,
              downloadBytes: 0,
              totalBytes: 0,
            );

        final profile = _parseBody(
          savedBody,
          userInfo: userInfo,
          updateInterval: 24,
        );
        _cachedProfile = profile;
        return profile;
      }
    } catch (_) {}
    return null;
  }

  SubscriptionProfile? _parseBody(
    String rawBody, {
    required SubscriptionUserInfo userInfo,
    int updateInterval = 24,
    String? webPageUrl,
  }) {
    final body = rawBody.trim();
    if (body.isEmpty) return null;

    String singboxConfig = '';
    List<OutboundRef> outbounds = [];

    // Проверяем, вернул ли сервер готовый JSON sing-box
    if (body.startsWith('{') && body.contains('"outbounds"')) {
      try {
        singboxConfig = configBuilder.patchExistingConfig(body);
        final map = jsonDecode(body) as Map<String, dynamic>;
        final rawOuts = map['outbounds'] as List?;
        if (rawOuts != null) {
          for (final item in rawOuts) {
            if (item is Map<String, dynamic>) {
              final tag = item['tag']?.toString() ?? 'Server';
              final type = item['type']?.toString() ?? 'vless';
              final server = item['server']?.toString() ?? '';
              final port = int.tryParse(item['server_port']?.toString() ?? '443') ?? 443;
              if (server.isNotEmpty) {
                outbounds.add(
                  OutboundRef(
                    tag: tag,
                    type: type,
                    server: server,
                    serverPort: port,
                    rawConfig: item,
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    // Если outbounds пустые или это base64/ссылки
    if (outbounds.isEmpty) {
      outbounds = linkParser.parseList(body);
      if (outbounds.isNotEmpty) {
        singboxConfig = configBuilder.buildFromOutbounds(outbounds);
      }
    }

    if (outbounds.isEmpty) return null;

    return SubscriptionProfile(
      userInfo: userInfo,
      outbounds: outbounds,
      singboxConfig: singboxConfig,
      updateIntervalHours: updateInterval,
      webPageUrl: webPageUrl,
    );
  }

  @override
  Future<Result<SubscriptionProfile>> fetchSubscription(
    String subUrl, {
    bool forceRefresh = false,
  }) async {
    var rawUrl = subUrl.trim();
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://${AppConfig.subDomain}/aggr/$rawUrl';
    }

    if (!forceRefresh && _cachedProfile != null && _cachedUrl == rawUrl) {
      return ok(_cachedProfile!);
    }

    try {
      final hwid = await storage.getOrCreateHwid();

      var rawUrl = subUrl.trim();
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        rawUrl = 'https://${AppConfig.subDomain}/aggr/$rawUrl';
      }

      var targetUri = Uri.parse(rawUrl);
      // Не трогаем путь, если это агрегатор (/aggr/) или уже содержит формат
      if (!targetUri.path.contains('/aggr/') &&
          !targetUri.path.endsWith('/singbox') &&
          !targetUri.path.endsWith('/json') &&
          !targetUri.path.contains('/sub/')) {
        targetUri = targetUri.replace(
          path: '${targetUri.path.replaceAll(RegExp(r'/+$'), '')}/singbox',
        );
      }

      final headers = <String, String>{
        'User-Agent': 'v2rayNG/1.8.5 (Android; okhttp)',
        'Accept': 'text/plain, application/json, */*',
        'x-hwid': hwid,
        'x-device-os': 'Android',
        'x-device-name': 'Android Phone',
      };

      Uri requestUri = targetUri;
      if (kIsWeb) {
        requestUri = Uri.parse('/api/sub-proxy').replace(
          queryParameters: {'url': targetUri.toString()},
        );
      }

      AppLogger.info('Fetching subscription with HWID header: $requestUri');
      final response = await httpClient.get(requestUri, headers: headers);

      if (response.statusCode != 200) {
        AppLogger.warning('Sub fetch returned ${response.statusCode}: ${response.body}');
        if (response.statusCode == 404) {
          return fail(const SubscriptionFailure(
            messageKey: FailureKeys.subscriptionNotFound,
          ));
        }
        if (response.statusCode == 403 || response.statusCode == 401) {
          return fail(const SubscriptionFailure(
            messageKey: FailureKeys.subscriptionBlocked,
          ));
        }
        return fail(ServerFailure(statusCode: response.statusCode));
      }

      // Парсинг заголовков подписки
      final userinfoHeader = response.headers['subscription-userinfo'];
      final userInfo = userinfoParser.parse(userinfoHeader) ??
          const SubscriptionUserInfo(
            uploadBytes: 0,
            downloadBytes: 0,
            totalBytes: 0,
          );

      final intervalStr = response.headers['profile-update-interval'];
      final updateInterval = int.tryParse(intervalStr ?? '24') ?? 24;
      final webPage = response.headers['profile-web-page-url'];

      final body = response.body.trim();
      final profile = _parseBody(
        body,
        userInfo: userInfo,
        updateInterval: updateInterval,
        webPageUrl: webPage,
      );

      if (profile == null) {
        return fail(const ParseFailure(
          debugMessage: 'No valid proxy outbounds found in subscription',
        ));
      }

      await storage.saveCachedSubBody(body);
      if (userinfoHeader != null && userinfoHeader.isNotEmpty) {
        await storage.saveCachedUserinfo(userinfoHeader);
      }
      _cachedProfile = profile;
      _cachedUrl = rawUrl;
      return ok(profile);
    } catch (e, st) {
      AppLogger.error('fetchSubscription failed: $e', e, st);
      final cached = await getCachedProfile();
      if (cached != null) {
        return ok(cached);
      }
      return fail(NetworkFailure(debugMessage: e.toString()));
    }
  }
}
