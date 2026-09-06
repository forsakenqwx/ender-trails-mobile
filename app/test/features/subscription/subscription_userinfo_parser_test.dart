import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/subscription/domain/parsers/subscription_userinfo_parser.dart';

void main() {
  const parser = SubscriptionUserInfoParser();

  group('SubscriptionUserInfoParser', () {
    test('parses standard Remnawave subscription-userinfo header', () {
      const header =
          'upload=1073741824; download=2147483648; total=107374182400; expire=1735689600';
      final info = parser.parse(header);

      expect(info, isNotNull);
      expect(info!.uploadBytes, 1073741824);
      expect(info.downloadBytes, 2147483648);
      expect(info.usedBytes, 3221225472);
      expect(info.totalBytes, 107374182400);
      expect(info.isUnlimited, isFalse);
      expect(info.expireDate, isNotNull);
      expect(info.expireDate!.year, 2025);
    });

    test('treats total=0 as unlimited traffic', () {
      const header = 'upload=100; download=200; total=0; expire=1800000000';
      final info = parser.parse(header);

      expect(info, isNotNull);
      expect(info!.isUnlimited, isTrue);
      expect(info.usageRatio, 0.0);
    });

    test('returns null on null or empty input', () {
      expect(parser.parse(null), isNull);
      expect(parser.parse(''), isNull);
      expect(parser.parse('   '), isNull);
    });

    test('handles whitespace and unordered keys gracefully', () {
      const header =
          'expire=1893456000; total=5000000000 ; upload = 1000 ; download = 2000 ';
      final info = parser.parse(header);

      expect(info, isNotNull);
      expect(info!.uploadBytes, 1000);
      expect(info.downloadBytes, 2000);
      expect(info.totalBytes, 5000000000);
    });
  });
}
