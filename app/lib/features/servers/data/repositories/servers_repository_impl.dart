import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../subscription/domain/entities/subscription_profile.dart';
import '../../../subscription/domain/repositories/subscription_repository.dart';
import '../../domain/entities/server_item.dart';
import '../../domain/repositories/servers_repository.dart';
import '../../domain/utils/country_detector.dart';
import '../latency_service.dart';

class ServersRepositoryImpl implements ServersRepository {
  ServersRepositoryImpl({
    required this.storage,
    required this.subscriptionRepository,
    LatencyService? latencyService,
    http.Client? httpClient,
  })  : latencyService = latencyService ?? LatencyService(),
        httpClient = httpClient ?? http.Client();

  final AppSecureStorage storage;
  final SubscriptionRepository subscriptionRepository;
  final LatencyService latencyService;
  final http.Client httpClient;

  static const _fallbackServers = <ServerModel>[
    ServerModel(
      tag: 'NL-1',
      name: 'Нидерланды · Amsterdam',
      countryCode: 'NL',
      protocol: 'VLESS · Reality · 10 Гбит/с',
      server: 'amsterdam.endertrails.online',
      port: 443,
      pingMs: 42,
    ),
    ServerModel(
      tag: 'DE-1',
      name: 'Германия · Frankfurt',
      countryCode: 'DE',
      protocol: 'VLESS · Reality · 10 Гбит/с',
      server: 'frankfurt.endertrails.online',
      port: 443,
      pingMs: 58,
    ),
    ServerModel(
      tag: 'KZ-1',
      name: 'Казахстан · Almaty',
      countryCode: 'KZ',
      protocol: 'VLESS · Reality · 1 Гбит/с',
      server: 'almaty.endertrails.online',
      port: 443,
      pingMs: 110,
    ),
  ];

  @override
  Future<List<ServerModel>> getServers() async {
    SubscriptionProfile? profile;

    final savedSubUrl = await storage.getSubscriptionUrl();
    if (savedSubUrl != null && savedSubUrl.isNotEmpty) {
      final res = await subscriptionRepository.fetchSubscription(savedSubUrl);
      profile = res.fold((l) => null, (r) => r);
    }

    profile ??= await subscriptionRepository.getCachedProfile();

    if (profile == null || profile.outbounds.isEmpty) {
      try {
        final res = await subscriptionRepository.fetchSubscription('txhbm_QWJD9a6zfk');
        profile = res.fold((l) => null, (r) => r);
      } catch (_) {}
    }

    if (profile == null || profile.outbounds.isEmpty) {
      return [ServerModel.auto, ..._fallbackServers];
    }

    final list = <ServerModel>[ServerModel.auto];
    for (final out in profile.outbounds) {
      if (out.server == '127.0.0.1' || out.server == 'localhost') continue;
      if (out.rawConfig['uuid'] == '00000000-0000-0000-0000-000000000000') continue;
      // Исключаем собственные ноды Финляндии и Швеции (выдаются как в Happ)
      if (out.server == '31.76.240.210' || out.server == '2.26.124.209') continue;
      if (out.tag.contains('Gemini ✨')) continue;

      final tagLower = out.tag.toLowerCase();
      if (tagLower.contains('все сервера находятся') ||
          tagLower.contains('промокод') ||
          tagLower.contains('даже если') ||
          tagLower.contains('будет работать')) {
        continue;
      }

      final code = CountryDetector.detect(out.tag);
      final cleanName = CountryDetector.cleanServerName(out.tag);
      list.add(
        ServerModel(
          tag: out.tag,
          name: cleanName,
          countryCode: code,
          protocol: '${out.type.toUpperCase()} · Reality',
          server: out.server,
          port: out.serverPort,
        ),
      );
    }
    return list;
  }

  @override
  Future<List<ServerModel>> pingAllServers(List<ServerModel> servers) async {
    final resultList = List<ServerModel>.from(servers);

    // Пакетный замер с пулом параллельности 4 (предотвращает троттлинг сокетов на мобильной сети)
    const chunkSize = 4;
    for (int i = 0; i < resultList.length; i += chunkSize) {
      final end = (i + chunkSize < resultList.length) ? i + chunkSize : resultList.length;
      final chunk = resultList.sublist(i, end);

      final updatedChunk = await Future.wait(chunk.map((s) async {
        if (s.isAuto) return s;
        final ping = await latencyService.measureLatency(
          tag: s.tag,
          host: s.server,
          port: s.port,
        );
        return s.copyWith(pingMs: ping);
      }));

      for (int k = 0; k < updatedChunk.length; k++) {
        resultList[i + k] = updatedChunk[k];
      }
    }

    // Вычисляем минимальный пинг для кнопки "Авто"
    int? minPing;
    for (final s in resultList) {
      if (!s.isAuto && s.pingMs != null && s.pingMs! > 0) {
        if (minPing == null || s.pingMs! < minPing) {
          minPing = s.pingMs;
        }
      }
    }

    return resultList.map((s) {
      if (s.isAuto) {
        return s.copyWith(pingMs: minPing ?? 40);
      }
      return s;
    }).toList();
  }

  @override
  Future<bool> switchServer(String tag) async {
    await saveSelectedTag(tag);

    // Пытаемся динамически переключить узел через Clash REST API
    try {
      final uri = Uri.parse('http://127.0.0.1:9090/proxies/proxy');
      final res = await httpClient
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': tag}),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (res.statusCode == 204 || res.statusCode == 200) {
        AppLogger.info('Switched sing-box outbound to $tag dynamically');
        return true;
      }
    } catch (e) {
      AppLogger.debug('Clash API switch failed (tunnel might be off): $e');
    }
    return false;
  }

  @override
  Future<void> saveSelectedTag(String tag) =>
      storage.saveSelectedServerTag(tag);

  @override
  Future<String?> getSelectedTag() => storage.getSelectedServerTag();
}
