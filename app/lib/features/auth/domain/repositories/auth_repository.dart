import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';

/// Контракт аутентификации через Telegram-бота (MASTER-PROMPT §1.2).
abstract interface class AuthRepository {
  /// Вход по одноразовому токену из Telegram-бота или direct-ссылке.
  Future<Result<AuthSession>> loginWithToken(String token);

  /// Обновление пары токенов (refresh-ротация).
  Future<Result<AuthSession>> refreshToken();

  /// Выход из аккаунта.
  Future<ResultUnit> logout();

  /// Получение сохранённой локальной сессии.
  Future<AuthSession?> getCurrentSession();

  /// Получение стойкого HWID устройства.
  Future<String> getDeviceId();
}
