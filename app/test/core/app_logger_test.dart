import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/core/logging/app_logger.dart';

void main() {
  group('AppLogger.mask', () {
    test('masks Bearer tokens', () {
      final input = 'Request Authorization: Bearer secret-token-123456';
      final masked = AppLogger.mask(input);
      expect(masked, contains('<masked>'));
      expect(masked, isNot(contains('secret-token-123456')));
    });

    test('masks vless share links', () {
      final input = 'Connecting to vless://user@server.com:443?type=tcp#Node1';
      final masked = AppLogger.mask(input);
      expect(masked, contains('<masked>'));
      expect(masked, isNot(contains('vless://')));
    });

    test('masks vmess share links', () {
      final input = 'Parsed vmess://eyJ2IjoiMiIsInBzIjoi...';
      final masked = AppLogger.mask(input);
      expect(masked, contains('<masked>'));
      expect(masked, isNot(contains('vmess://')));
    });

    test('masks x-hwid headers', () {
      final input = 'Headers: x-hwid: android-unique-id-998877';
      final masked = AppLogger.mask(input);
      expect(masked, contains('<masked>'));
      expect(masked, isNot(contains('android-unique-id-998877')));
    });

    test('preserves ordinary log messages', () {
      final input = 'Connecting to server Amsterdam (45 ms)';
      final masked = AppLogger.mask(input);
      expect(masked, equals(input));
    });
  });
}
