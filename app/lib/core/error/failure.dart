/// Иерархия ошибок приложения.
///
/// Правило (MASTER-PROMPT §3.7): наружу из репозиториев/юзкейсов исключения
/// не пробрасываются — только [Result] с одной из этих ошибок.
///
/// [messageKey] — стабильная константа, на которую опирается UI (и l10n).
/// [debugMessage] — только в логи. Секретов здесь быть не должно:
/// логгер дополнительно режет их по маске (см. [AppLogger]).
sealed class Failure {
  const Failure({required this.messageKey, this.debugMessage});

  final String messageKey;
  final String? debugMessage;

  @override
  String toString() => '$runtimeType($messageKey${debugMessage == null ? '' : ', $debugMessage'})';
}

/// Нет сети, таймаут, 5xx.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.debugMessage}) : super(messageKey: FailureKeys.network);
}

/// 401/403 — сессия протухла, нужен разлогин.
final class AuthFailure extends Failure {
  const AuthFailure({super.debugMessage}) : super(messageKey: FailureKeys.auth);
}

/// 4xx с телом ошибки от бэкенда.
final class ServerFailure extends Failure {
  const ServerFailure({super.debugMessage, this.statusCode})
      : super(messageKey: FailureKeys.server);

  final int? statusCode;
}

/// Подписка истекла, отключена, исчерпан трафик или превышен лимит устройств.
final class SubscriptionFailure extends Failure {
  const SubscriptionFailure({required super.messageKey, super.debugMessage});
}

/// Ядро VPN не поднялось или упало.
final class VpnFailure extends Failure {
  const VpnFailure({super.debugMessage}) : super(messageKey: FailureKeys.vpn);
}

/// Не распарсили конфиг или share-ссылку.
final class ParseFailure extends Failure {
  const ParseFailure({super.debugMessage}) : super(messageKey: FailureKeys.parse);
}

/// Локальное хранилище недоступно (secure storage, isar).
final class StorageFailure extends Failure {
  const StorageFailure({super.debugMessage}) : super(messageKey: FailureKeys.storage);
}

/// Стабильные ключи ошибок.
abstract final class FailureKeys {
  static const network = 'error.network';
  static const auth = 'error.auth';
  static const server = 'error.server';
  static const vpn = 'error.vpn';
  static const parse = 'error.parse';
  static const storage = 'error.storage';

  static const subscriptionExpired = 'error.subscription.expired';
  static const subscriptionDisabled = 'error.subscription.disabled';
  static const subscriptionBlocked = 'error.subscription.blocked';
  static const subscriptionNotFound = 'error.subscription.notFound';
  static const deviceLimit = 'error.subscription.deviceLimit';
}
