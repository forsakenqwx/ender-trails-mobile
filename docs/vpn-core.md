# VPN-ядро и интеграция с Remnawave

Детальное описание к `MASTER-PROMPT.md` → раздел 6.

---

## 1. Как Remnawave отдаёт подписку (проверено по документации панели)

### 1.1 URL

```
https://<SUB_PUBLIC_DOMAIN>/<shortUuid>            публичный маршрут (прокси снимает /sub)
https://<domain>/api/sub/<shortUuid>               через remnawave-subscription-page
```

`shortUuid` — секрет пользователя. Он же является аутентификацией: **токенов и кук не надо**,
и слать их вредно (ломают кэш прокси).

### 1.2 Явное указание формата (суффикс)

| Суффикс | Формат тела |
|---|---|
| `/json` | Xray JSON |
| `/v2ray-json` | V2Ray-style JSON |
| `/singbox` | **sing-box JSON** ← наш основной |
| `/clash` | Clash YAML |
| `/mihomo` | Mihomo YAML |
| `/stash` | Stash YAML |
| *(без суффикса)* | автоопределение по User-Agent / SRH-заголовку → **не полагаемся** |

Также есть `GET /sub/<shortUuid>/info` — JSON с инфой о пользователе и списком ссылок.
**Клиент его не должен дёргать** — он для админки/сабскрипшн-пейдж.

### 1.3 Заголовки запроса

| Заголовок | Обязательность | Комментарий |
|---|---|---|
| `User-Agent` | **обязателен** | управляет правилами ответа панели. Драйвит выбор формата |
| `x-hwid` | обязателен при включённом HWID | без него — пустое тело + `x-hwid-not-supported: true` |
| `x-device-os` | рекомендуется | `Android` / `iOS` / `Windows` / `macOS` / `Linux` |
| `x-ver-os` | рекомендуется | версия ОС |
| `x-device-model` | рекомендуется | маркетинговое имя устройства |

Не слать: cookies, `Authorization`, `Accept-Encoding: br` без поддержки Brotli.

**Формат UA приложения:**
```
EnderTrails/<appVersion> (<platform>; <osVersion>; <deviceModel>)
```
Категорически не должен выглядеть как браузер (`Mozilla/...`), иначе панель вернёт HTML-лендинг.

> Если на панели включён `serveJsonAtBaseSubscription`, для UA из белого списка
> (`JSON_SUBSCRIPTION_FALLBACK_CLIENTS`) отдаётся JSON даже без суффикса.
> Мы всегда шлём явный суффикс — это снимает зависимость от настроек панели.

### 1.4 Заголовки ответа (обязательно парсим)

```
content-type: application/json
content-disposition: attachment; filename=<username>
support-url: https://t.me/example_support
profile-title: base64:<base64 of title>
profile-update-interval: 12                       (часы)
subscription-userinfo: upload=0; download=12345678; total=107374182400; expire=1798761600
profile-web-page-url: https://sub.example.com/<shortUuid>
x-hwid-active: true
x-hwid-limit: true
```

`subscription-userinfo` — источник правды по трафику и дате окончания:
- `upload`, `download` — байты (суммируем → `usedBytes`)
- `total` — лимит, 0 означает безлимит (проверить на реальной панели!)
- `expire` — unix timestamp окончания подписки

### 1.5 HWID

- `x-hwid` = стабильный идентификатор установки. Генерируем один раз, храним в
  `flutter_secure_storage` (переживает переустановку **не** должен — это нормально и ожидаемо).
- Если `x-hwid-limit: true` и устройство не в списке → обрабатываем как
  «превышен лимит устройств» и предлагаем экран управления устройствами.
- Панель умеет лимитировать устройства, значит в приложении нужен экран
  «Мои устройства» с удалением (эндпоинт — см. `docs/backend-contract.md`).

---

## 2. Что делает приложение: цепочка получения конфига

```
BFF (наш бэкенд)
  └─ POST /v1/auth/telegram  →  accessToken + subscriptionUrl + profile
                                     │
SubscriptionRepository.fetchConfig() │
  └─ GET  <subscriptionUrl>/singbox  │  headers: User-Agent, x-hwid, x-device-*
        │                            │
        ├─ 200 + JSON  → VpnConfigBundle(rawConfig, outbounds, userInfo)
        ├─ 200 + base64 → fallback: парсим share-ссылки → строим конфиг сами
        ├─ 403          → SubscriptionFailure.blocked
        ├─ 404          → SubscriptionFailure.notFound (подписка удалена)
        └─ x-hwid-*     → SubscriptionFailure.deviceLimit
                                     │
VpnEngine.connect(VpnSession(config, mode, notification, perApp, killSwitch))
```

**Правило:** приложение работает и без BFF-конфига — если в настройках вручную вставили
subscription URL или строку `vless://...`, всё должно подниматься (режим «своя подписка»).

---

## 3. Парсер share-ссылок (fallback и ручной ввод)

Поддерживаемые схемы:
- `vless://uuid@host:port?params#name` (Reality: `pbk`, `sid`, `fp`, `sni`, `flow`)
- `vmess://` (base64 JSON)
- `trojan://password@host:port?params#name`
- `ss://` (SIP002 + legacy base64)
- `hysteria2://password@host:port?params#name` (и `hy2://`)
- `tuic://uuid:password@host:port?params#name`

Каждая ссылка → `OutboundRef` + JSON-outbound для sing-box.
Юнит-тесты на каждую схему + на битые ссылки (обязательно).

---

## 4. Сборка sing-box конфига

Если сервер отдал готовый конфиг — **не переписываем его**, а минимально патчим
(добавляем `tun` inbound при отсутствии, подставляем DNS, включаем Clash API),
валидируем (`checkConfig`) и скармливаем ядру.

Если собираем сами (fallback / ручной ввод) — базовый каркас:

```jsonc
{
  "log": { "level": "warn" },
  "dns": {
    "servers": [{ "tag": "remote", "address": "https://1.1.1.1/dns-query", "detour": "proxy" }],
    "strategy": "ipv4_only"
  },
  "inbounds": [{
    "type": "tun",
    "tag": "tun-in",
    "address": ["172.19.0.1/30", "fdfe:dcba:9876::1/126"],
    "auto_route": true,
    "strict_route": true,
    "sniff": true,
    "route_exclude_address": ["10.0.0.0/8", "192.168.0.0/16"]   // при lanBypass
  }],
  "outbounds": [
    /* из подписки, с сохранением tag */
    { "type": "selector", "tag": "proxy", "outbounds": ["auto", ...tags], "default": "auto" },
    { "type": "urltest", "tag": "auto", "outbounds": [...tags], "url": "https://cp.cloudflare.com", "interval": "3m" },
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "block" },
    { "type": "dns", "tag": "dns-out" }
  ],
  "route": {
    "rules": [
      { "protocol": "dns", "outbound": "dns-out" },
      { "geoip": "private", "outbound": "direct" },      // если lanBypass
      { "clash_mode": "direct", "outbound": "direct" },
      { "clash_mode": "global", "outbound": "proxy" },
      { "geoip": ["ru", "by", "kz"], "outbound": "direct" }  // при «роутинге РФ напрямую»
    ],
    "auto_detect_interface": true
  },
  "experimental": { "clash_api": { "external_controller": "127.0.0.1:9090" } }
}
```

**Решения:**
- `selector` + `urltest` дают «Авто» и ручной выбор сервера без переподключения туннеля
  (переключение через Clash API / `selectOutbound`).
- Гео-роутинг РФ-напрямую — настраиваемый пункт, **по умолчанию выключен** (пользователь
  ждёт, что весь трафик идёт через VPN).
- `route_exclude_address` / `geoip: private` — чтобы не ломать локальную сеть и
  не светить LAN в туннель.

---

## 5. Жизненный цикл соединения

```
idle → preparing (инициализация ядра, чтение кэша)
     → permission (VpnService dialog)
     → fetching config (если кэш протух по profile-update-interval)
     → validating config
     → connecting
     → connected  ──(обрыв/смена сети)──→ reconnecting → connected
                                                      └→ error
     → disconnecting → idle
```

Обязательные поведения:
- **Kill switch**: при `reconnecting`/`error` трафик блокируется (системный уровень).
- **Автопереподключение**: экспоненциальная задержка 1s → 2s → 4s … до 30s, не более 5 попыток,
  дальше — `error` и ручной режим.
- **Смена сети** (Wi-Fi ↔ LTE): переподключаемся без участия пользователя.
- **Foreground service** с уведомлением: статус, скорость, кнопка «Отключить».
  Без него Android убьёт туннель.
- **Boot autostart** — опционально, через boot broadcast relay.
- **Батарея**: не отключать оптимизации Doze без предупреждения; показываем подсказку
  «разрешите работу в фоне», если туннель стабильно падает.

---

## 6. Выбор реализации ядра (открытое решение)

| Вариант | Плюсы | Минусы |
|---|---|---|
| **A. `flutter_singbox_client`** (sing-box 1.14) | готово за часы, TUN, kill switch, per-app, Clash API, трафик, логи | GPL-3.0; Android-билд бесплатный, **iOS/Win/macOS/Linux — платные** у автора |
| **B. Свой плагин на `libbox`** (gomobile + pigeon) | все платформы, полный контроль, свой UA/брендинг | 1–3 недели; поддержка сборок sing-box на себя; ядро всё ещё GPL-3.0 |
| **C. Свой плагин на Xray-core** | MPL-2.0 — мягче для коммерции | нет Hysteria2/TUIC/AnyTLS; Android-only референсы; больше писанины по TUN |
| **D. `flutter_v2ray_client`** | быстро, Xray, Android | Android-only, MPL, качество кода под вопросом |

**Дефолт:** стартуем на **A** (Android), чтобы проверить продуктовую гипотезу максимально быстро,
при этом с первого дня весь код живёт за `VpnEngine` и ни один экран не импортирует
пакет ядра напрямую. Миграция на **B** или **C** = новая реализация одного класса + плагина.

**Блокер:** лицензирование. sing-box — GPL-3.0, коммерческая лицензия у SagerNet.
Для закрытого проприетарного приложения это надо решить до публикации. См. Q6 в мастер-промпте.
