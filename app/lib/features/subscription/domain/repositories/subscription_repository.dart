import '../../../../core/error/result.dart';
import '../entities/subscription_profile.dart';

/// Контракт работы с подпиской и получением конфигураций узлов.
abstract interface class SubscriptionRepository {
  /// Получение подписки с Remnawave-поддомена с заголовками HWID и User-Agent.
  Future<Result<SubscriptionProfile>> fetchSubscription(
    String subUrl, {
    bool forceRefresh = false,
  });

  /// Получение кэшированного профиля подписки.
  Future<SubscriptionProfile?> getCachedProfile();
}
