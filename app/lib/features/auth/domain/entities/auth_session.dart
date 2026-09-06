/// Модель авторизованной сессии пользователя.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.subscriptionUrl,
    this.username,
    this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String? subscriptionUrl;
  final String? username;
  final DateTime? expiresAt;

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }
}
