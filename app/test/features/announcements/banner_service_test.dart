import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ender_trails/core/storage/secure_storage.dart';
import 'package:ender_trails/features/announcements/data/banner_service.dart';
import 'package:ender_trails/features/announcements/domain/entities/remote_banner.dart';

class FakeSecureStorage extends AppSecureStorage {
  FakeSecureStorage() : super(storage: null);

  String? _dismissedId;

  @override
  Future<String?> getDismissedBannerId() async => _dismissedId;

  @override
  Future<void> saveDismissedBannerId(String id) async {
    _dismissedId = id;
  }
}

void main() {
  group('RemoteBanner', () {
    test('parses JSON correctly', () {
      final json = {
        'id': 'banner_123',
        'enabled': true,
        'title': 'АКЦИЯ',
        'text': 'Скидка 20% на подписку!',
        'action_url': 'https://t.me/EnderTrailsVPN_bot',
        'type': 'promo',
      };

      final banner = RemoteBanner.fromJson(json);

      expect(banner.id, equals('banner_123'));
      expect(banner.enabled, isTrue);
      expect(banner.title, equals('АКЦИЯ'));
      expect(banner.text, equals('Скидка 20% на подписку!'));
      expect(banner.actionUrl, equals('https://t.me/EnderTrailsVPN_bot'));
      expect(banner.type, equals('promo'));
    });
  });

  group('BannerService', () {
    test('fetches valid banner when not dismissed', () async {
      final fakeStorage = FakeSecureStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'banner_2026',
            'enabled': true,
            'title': 'ТЕСТ',
            'text': 'Тестовое объявление',
            'type': 'info',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BannerService(
        storage: fakeStorage,
        httpClient: mockClient,
      );

      final banner = await service.fetchBanner();
      expect(banner, isNotNull);
      expect(banner!.id, equals('banner_2026'));
      expect(banner.text, equals('Тестовое объявление'));
    });

    test('returns null when banner was dismissed by user', () async {
      final fakeStorage = FakeSecureStorage();
      await fakeStorage.saveDismissedBannerId('banner_2026');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'banner_2026',
            'enabled': true,
            'title': 'ТЕСТ',
            'text': 'Тестовое объявление',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BannerService(
        storage: fakeStorage,
        httpClient: mockClient,
      );

      final banner = await service.fetchBanner();
      expect(banner, isNull);
    });

    test('returns null when banner is disabled', () async {
      final fakeStorage = FakeSecureStorage();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'banner_2026',
            'enabled': false,
            'text': 'Тест',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BannerService(
        storage: fakeStorage,
        httpClient: mockClient,
      );

      final banner = await service.fetchBanner();
      expect(banner, isNull);
    });
  });
}
