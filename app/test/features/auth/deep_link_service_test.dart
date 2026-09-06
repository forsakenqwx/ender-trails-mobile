import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/auth/data/deep_link_service.dart';

void main() {
  late DeepLinkService service;

  setUp(() {
    service = DeepLinkService();
  });

  tearDown(() {
    service.dispose();
  });

  group('DeepLinkService.extractToken', () {
    test('extracts token from endertrails://auth?token=...', () {
      final token = service.extractToken('endertrails://auth?token=token_xyz123');
      expect(token, equals('token_xyz123'));
    });

    test('accepts raw tokens', () {
      final token = service.extractToken('manual_code_456');
      expect(token, equals('manual_code_456'));
    });

    test('returns null on empty input', () {
      expect(service.extractToken(''), isNull);
      expect(service.extractToken('   '), isNull);
    });
  });
}
