# Архитектура приложения

Детальное описание к `MASTER-PROMPT.md` → раздел 5.

---

## 1. Слои и зависимости

```
presentation  →  domain  ←  data
     │              ▲          │
     └──────────────┴──────────┘
              core (утилиты, сеть, DI, ошибки)
```

- `domain` — чистый Dart, **ноль** импортов Flutter/Dio/sing-box. Содержит entity,
  абстракции репозиториев, use-case'ы. Это делает бизнес-логику тривиально тестируемой.
- `data` — DTO, datasource'ы, реализация репозиториев. Знает про Dio, Isar, secure storage,
  платформенные каналы.
- `presentation` — экраны, виджеты, Riverpod-нотификаторы. Не знает о DTO и Dio.
- `core` — инфраструктура, доступная всем слоям.

Зависимости направлены внутрь. Нарушение = `analyze` с кастомным lint-правилом
(`invalid_implementation_imports` через `custom_lint` — ставим на этапе E0).

---

## 2. Ключевые абстракции

### 2.1 Ошибки

```dart
sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure { ... }   // нет сети, таймаут, 5xx
final class AuthFailure extends Failure { ... }      // 401/403 → разлогин
final class ServerFailure extends Failure { ... }   // 4xx с телом ошибки
final class SubscriptionFailure extends Failure { ... } // подписка истекла/отключена
final class VpnFailure extends Failure { ... }      // ядро не поднялось
final class ParseFailure extends Failure { ... }    // не распарсили конфиг
final class StorageFailure extends Failure { ... }
```

Каждый `Failure` обязан дать `messageKey` (для l10n) и опционально `debugMessage`
(в логи, без секретов).

Тип-алиас: `typedef Result<T> = Either<Failure, T>;`

### 2.2 VPN-ядро

```dart
abstract interface class VpnEngine {
  Future<Result<void>> initialize();
  Future<Result<bool>> ensurePermission();
  Future<Result<void>> connect(VpnSession session);
  Future<Result<void>> disconnect();
  Future<Result<void>> selectOutbound(String tag);   // переключение без разрыва
  Stream<VpnStatus> get statusStream;                 // connected/connecting/.../error
  Stream<TrafficStats> get trafficStream;             // ~1 Гц
  Future<Result<List<ConnectionInfo>>> activeConnections();
  Future<Result<int>> pingOutbound(String tag);
  Future<Result<Unit>> setKillSwitch(bool enabled);
  Future<Result<Unit>> setPerAppRules(PerAppRules rules);
  Future<Result<Unit>> reloadConfig(String configJson);
}

enum VpnStatus { disconnected, preparing, connecting, connected, reconnecting, disconnecting, error }
```

Реализации:
- `SingboxVpnEngine` — через `flutter_singbox_client` (дефолт).
- `LibboxVpnEngine` — свой FFI/pigeon-плагин (миграция для iOS/десктопа).
- `FakeVpnEngine` — для тестов и для разработки UI без ядра.

### 2.3 Репозитории

```dart
abstract interface class AuthRepository {
  Future<Result<Session>> loginWithTelegram(String token);
  Future<Result<Session>> loginWithEmail(String email, String password);
  Future<Result<Session>> refresh(String refreshToken);
  Future<Result<Unit>> logout();
  Stream<Session?> watchSession();
}

abstract interface class SubscriptionRepository {
  Future<Result<Subscription>> getSubscription();          // статус, трафик, expire
  Future<Result<VpnConfigBundle>> fetchConfig();           // sing-box JSON + метаданные
  Future<Result<List<ServerNode>>> getServers();           // локации, пинг, нагрузка
  Future<Result<Unit>> activatePromocode(String code);
}

abstract interface class DeviceRepository {
  Future<Result<String>> getOrCreateHwid();                // стабильный per-install ID
  Future<Result<List<UserDevice>>> getDevices();
  Future<Result<Unit>> removeDevice(String id);
}

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> load();
  Future<Result<Unit>> save(AppSettings s);
  Stream<AppSettings> watch();
}
```

---

## 3. Модели домена (ядро)

```dart
@freezed
class Session with _$Session {
  const factory Session({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required String userId,
    String? subscriptionUrl,     // https://<sub>/<shortUuid>
  }) = _Session;
}

@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required SubscriptionStatus status,     // active | expired | disabled | limited | trial
    required DateTime? expiresAt,
    required int usedBytes,
    required int? totalBytes,               // null = безлимит
    required int? deviceLimit,
    required int deviceCount,
    String? supportUrl,
    String? webPageUrl,
    int? updateIntervalHours,
  }) = _Subscription;
}

@freezed
class VpnConfigBundle with _$VpnConfigBundle {
  const factory VpnConfigBundle({
    required String rawConfig,          // sing-box JSON как отдал сервер
    required DateTime fetchedAt,
    required List<OutboundRef> outbounds,  // tag → человеческое имя, флаг, страна
    required SubscriptionUserInfo userInfo, // из subscription-userinfo
  }) = _VpnConfigBundle;
}

@freezed
class OutboundRef with _$OutboundRef {
  const factory OutboundRef({
    required String tag,
    required String displayName,
    String? countryCode,
    required String protocol,       // vless | hysteria2 | tuic | trojan | ...
  }) = _OutboundRef;
}

@freezed
class ServerNode with _$ServerNode {
  const factory ServerNode({
    required String id,
    required String displayName,
    required String countryCode,
    required String outboundTag,
    int? latencyMs,
    int? loadPercent,
    required bool isAvailable,
  }) = _ServerNode;
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required bool autoConnectOnLaunch,
    required bool autoConnectOnBoot,
    required bool killSwitch,
    required AppLocale locale,
    required ThemeMode themeMode,
    required SplitTunnelMode splitMode,      // off | include | exclude
    required Set<String> splitPackages,
    required DnsMode dnsMode,                // system | remote | custom
    String? customDns,
    required bool lanBypass,
    required String? selectedOutboundTag,    // null = авто
  }) = _AppSettings;
}
```

---

## 4. State management

- Riverpod, генерация провайдеров через `riverpod_generator`.
- Экран подключается к одному `Notifier`/`AsyncNotifier` фичи.
- Глобальные стримы (статус VPN, трафик) — `StreamProvider`, подписанный на `VpnEngine`.
- Юзкейсы инжектируются как провайдеры, чтобы их можно было подменить в тестах.

Пример главного экрана:

```dart
@riverpod
class ConnectionController extends _$ConnectionController {
  @override
  Future<ConnectionState> build() async {
    final engine = ref.watch(vpnEngineProvider);
    ref.listen(vpnStatusStreamProvider, (_, next) { ... });
    return const ConnectionState.disconnected();
  }

  Future<void> toggle() async { /* usecase.connect(...) */ }
}
```

---

## 5. Конфигурация и флейворы

`env.json` (не в git) → `--dart-define-from-file`:

```json
{
  "API_BASE_URL": "https://api.endertrails.example",
  "SENTRY_DSN": "",
  "APP_VERSION_SUFFIX": "",
  "SUPPORT_URL": "https://t.me/...",
  "ANALYTICS_ENABLED": "false"
}
```

Флейворы: `dev` / `stage` / `prod` — через entrypoint'ы
`main_dev.dart`, `main_stage.dart`, `main.dart` + отдельные `applicationId`-суффиксы
(`.dev`, `.stage`), чтобы на устройстве жили три сборки одновременно.

---

## 6. Логирование

- `talker` с фильтрами: в prod — только `error`/`critical` + breadcrumbs в Sentry.
- Автоматическое маскирование: regex на `Bearer\s+\S+`, `(?i)(token|password|secret|key)"?\s*[:=]`,
  `vless://[^"'\s]+`, `x-hwid`.
- Логи ядра sing-box пишутся в отдельный файл, в UI показываются по кнопке «Логи»
  с предупреждением, что они могут содержать чувствительное.

---

## 7. Тестовая стратегия

| Уровень | Что | Инструмент |
|---|---|---|
| Unit | парсеры, мапперы, usecase'ы, форматтеры | `flutter_test` + `mocktail` |
| Widget | экраны в разных состояниях | `flutter_test` + golden |
| Integration | сценарий «вход → конфиг → подключение» | `integration_test` + `FakeVpnEngine` |
| Manual | реальное устройство, реальная подписка | чек-лист в `docs/qa-checklist.md` |

`FakeVpnEngine` — обязателен с этапа E0: он позволяет разрабатывать весь UI и логику,
не имея собранного ядра.
