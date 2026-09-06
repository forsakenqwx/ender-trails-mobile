import '../entities/referral_info.dart';

/// Контракт работы с реферальной программой и промокодами.
abstract interface class ReferralRepository {
  /// Получает реферальные данные и ссылку пользователя.
  Future<ReferralInfo> getReferralInfo();

  /// Активирует промокод.
  Future<bool> applyPromoCode(String code);
}
