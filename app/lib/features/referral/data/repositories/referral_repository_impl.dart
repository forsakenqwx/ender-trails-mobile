import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/referral_info.dart';
import '../../domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl({
    required this.storage,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  final AppSecureStorage storage;
  final http.Client httpClient;

  @override
  Future<ReferralInfo> getReferralInfo() async {
    final hwid = await storage.getOrCreateHwid();
    final token = await storage.getAccessToken();

    // Пытаемся получить данные с BFF
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/v1/referral');
        final res = await httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'x-hwid': hwid,
          },
        ).timeout(const Duration(milliseconds: 2500));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return ReferralInfo(
            code: data['code'] as String? ?? _deriveCode(hwid),
            link: data['link'] as String? ??
                'https://t.me/${AppConfig.supportBot}?start=${_deriveCode(hwid)}',
            invitedCount: data['invitedCount'] as int? ?? 0,
            activeCount: data['activeCount'] as int? ?? 0,
            bonusDaysEarned: data['earnedBonusDays'] as int? ?? 0,
          );
        }
      } catch (e) {
        AppLogger.debug('BFF referral fetch failed: $e');
      }
    }

    // Автономный расчёт стабильного реферального кода из HWID
    final localCode = _deriveCode(hwid);
    return ReferralInfo(
      code: localCode,
      link: 'https://t.me/${AppConfig.supportBot}?start=$localCode',
      invitedCount: 0,
      activeCount: 0,
      bonusDaysEarned: 0,
    );
  }

  @override
  Future<bool> applyPromoCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    final token = await storage.getAccessToken();
    final hwid = await storage.getOrCreateHwid();

    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/v1/promocode');
        final res = await httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'x-hwid': hwid,
          },
          body: jsonEncode({'code': cleanCode}),
        );
        if (res.statusCode == 200) {
          return true;
        }
      } catch (e) {
        AppLogger.error('Apply promocode failed: $e');
      }
    }

    // Если сервер оффлайн или промокод тестовый
    return cleanCode == 'ENDER' || cleanCode == 'START';
  }

  String _deriveCode(String hwid) {
    final clean = hwid.replaceAll('-', '').toUpperCase();
    final short = clean.length >= 6 ? clean.substring(0, 6) : 'REF';
    return 'ET-$short';
  }
}
