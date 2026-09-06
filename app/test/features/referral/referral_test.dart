import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/core/storage/secure_storage.dart';
import 'package:ender_trails/features/referral/data/repositories/referral_repository_impl.dart';
import 'package:ender_trails/features/referral/domain/entities/referral_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  group('ReferralInfo', () {
    test('instantiates with expected default reward text', () {
      const info = ReferralInfo(
        code: 'ET-123456',
        link: 'https://t.me/EnderTrailsVPN_bot?start=ET-123456',
        invitedCount: 3,
        activeCount: 2,
        bonusDaysEarned: 21,
      );

      expect(info.code, 'ET-123456');
      expect(info.invitedCount, 3);
      expect(info.bonusDaysEarned, 21);
      expect(info.rewardText, contains('+7 дней'));
    });

    test('copyWith properly copies updated fields', () {
      const info = ReferralInfo(
        code: 'ET-123456',
        link: 'https://t.me/EnderTrailsVPN_bot?start=ET-123456',
        invitedCount: 0,
        activeCount: 0,
        bonusDaysEarned: 0,
      );

      final updated = info.copyWith(invitedCount: 5, bonusDaysEarned: 35);
      expect(updated.invitedCount, 5);
      expect(updated.bonusDaysEarned, 35);
      expect(updated.code, 'ET-123456');
    });
  });

  group('ReferralRepositoryImpl', () {
    test('generates valid code format when offline', () async {
      // Mocking storage isn't strictly required if default storage in test environment behaves
      final repo = ReferralRepositoryImpl(storage: AppSecureStorage());
      final info = await repo.getReferralInfo();

      expect(info.code, startsWith('ET-'));
      expect(info.link, contains(info.code));
    });

    test('validates offline promocodes', () async {
      final repo = ReferralRepositoryImpl(storage: AppSecureStorage());

      expect(await repo.applyPromoCode('ENDER'), isTrue);
      expect(await repo.applyPromoCode('START'), isTrue);
      expect(await repo.applyPromoCode('INVALID_CODE_999'), isFalse);
      expect(await repo.applyPromoCode(''), isFalse);
    });
  });
}
