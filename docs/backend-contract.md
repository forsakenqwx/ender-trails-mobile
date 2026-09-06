# Контракт BFF для мобильного приложения

> **Статус: ПРЕДЛОЖЕНИЕ.** Это контракт, который приложению *удобно* иметь.
> Часть эндпоинтов уже есть в текущем бэкенде — нужно сверить и переиспользовать;
> часть придётся добавить. Сверка — отдельная задача этапа E2.
> Формат: `v1`, JSON, `Authorization: Bearer <accessToken>`.

---

## 0. Принципы

1. Приложение **никогда** не общается с Remnawave-панелью напрямую.
   Единственное исключение — **subscription URL** (публичный домен подписки),
   откуда приложение тянет конфиг ядра. Там нет админ-секретов: секрет — сам `shortUuid`.
2. Все суммы — в копейках/центах (целое число). Все даты — ISO 8601 UTC.
   Все объёмы трафика — в байтах (целое).
3. Ошибки — единая обёртка:
   ```json
   { "error": { "code": "subscription_expired", "message": "...", "details": {} } }
   ```
   `code` — стабильная константа, на неё опирается UI. `message` — только для логов.
4. Идемпотентность: `Idempotency-Key` на всех `POST`, меняющих состояние.
5. Версионирование: мажорная версия в пути (`/v1`), минорные — аддитивно.

---

## 1. Аутентификация

> **Решение forsaken: вход только через Telegram-бота.** Email/пароль не делаем вообще —
> ни в v1, ни в бэклоге, пока не попросят.

### `POST /v1/auth/telegram`
Вход по одноразовому токену, который выдаёт бот (сценарий «Открыть приложение» в боте
или deep link `endertrails://auth?token=...`).

Request:
```json
{ "token": "one-time-token-from-bot", "deviceId": "<hwid>", "deviceName": "Pixel 8 Pro" }
```
Response `200`:
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresAt": "2026-09-01T12:00:00Z",
  "user": {
    "id": "usr_123",
    "telegramId": 123456,
    "username": "forsaken",
    "language": "ru",
    "createdAt": "2026-01-01T00:00:00Z"
  },
  "subscriptionUrl": "https://sub.endertrails.example/abcd1234"
}
```
Ошибки: `token_invalid`, `token_expired`, `user_banned`, `device_limit_reached`.

### ~~`POST /v1/auth/email`~~ — **НЕ ДЕЛАЕМ**

Клиентский флоу входа:

1. Пользователь в боте жмёт «Открыть приложение» → бот отдаёт кнопку с deep link
   `https://t.me/<bot>?start=app_<token>` или сразу `endertrails://auth?token=<token>`.
2. Приложение ловит deep link (`app_links`), показывает «Входим…», меняет токен на сессию.
3. Запасной путь: если приложение открыто вручную — экран с полем «Введите код из бота»
   и кнопкой «Получить код», которая уводит в бота.
4. Токен одноразовый, живёт ~5 минут. Просрочен — просим новый в боте.

### `POST /v1/auth/refresh`
```json
{ "refreshToken": "...", "deviceId": "..." }
```
→ новая пара токенов. Ротация refresh-токена, старый инвалидируется.
Ошибка `refresh_invalid` → принудительный разлогин.

### `POST /v1/auth/logout`
Инвалидирует текущий refresh и отвязывает `deviceId` (если это последнее устройство —
по настройке панели).

### Клиентская логика
- Access token живёт 15 минут. За 60 секунд до истечения — проактивный refresh.
- На любой `401` — один refresh и повтор запроса. Второй `401` → разлогин.
- Параллельные refresh'ы склеиваются в один (mutex в Dio-интерцепторе).

---

## 2. Профиль и подписка

### `GET /v1/me`
```json
{
  "user": { "id": "usr_123", "username": "forsaken", "language": "ru", "balance": 0 },
  "subscription": {
    "status": "active",              // active | trial | expired | disabled | limited
    "expiresAt": "2026-10-01T00:00:00Z",
    "usedBytes": 12345678,
    "totalBytes": 107374182400,      // 0 или null = безлимит
    "deviceLimit": 3,
    "deviceCount": 2,
    "tariff": { "id": "t_1m", "name": "1 месяц", "periodDays": 30 },
    "autoRenew": true
  },
  "subscriptionUrl": "https://sub.endertrails.example/abcd1234",
  "referral": { "code": "ABC123", "earnedTotal": 50000, "invitedCount": 3 }
}
```

### `GET /v1/subscription/usage`
Оперативные данные трафика (если BFF их кэширует):
```json
{ "uploadBytes": 0, "downloadBytes": 12345678, "totalBytes": 107374182400,
  "expiresAt": "2026-10-01T00:00:00Z", "updatedAt": "2026-09-01T08:00:00Z" }
```
> Если BFF не кэширует — берём из ответа подписки (заголовок `subscription-userinfo`)
> при каждом обновлении конфига.

### `GET /v1/devices` / `DELETE /v1/devices/{id}`
```json
[ { "id": "dev_1", "hwid": "and-3a9c...", "name": "Pixel 8 Pro",
    "platform": "android", "osVersion": "14",
    "lastActiveAt": "2026-09-01T08:00:00Z", "isCurrent": true } ]
```

### `POST /v1/promocode`
```json
{ "code": "SUMMER2026" }
```
```json
{ "applied": true, "bonusDays": 30, "newExpiresAt": "2026-11-01T00:00:00Z" }
```

---

## 3. Серверы

> **Решение forsaken: список серверов тянем из агрегатора.**
> Конфиг ядра — напрямую с sub-домена Remnawave, а **метаданные серверов**
> (названия, страны, доступность, нагрузка) — от агрегатора.
> Эндпоинт **обязателен**. Список из `outbounds` конфига — только фолбэк,
> если агрегатор недоступен (и тогда без красивых названий).

### `GET /v1/servers`
```json
[{
  "id": "srv_nl_1",
  "outboundTag": "NL-1",              // совпадает с tag в sing-box конфиге
  "displayName": "Нидерланды · Amsterdam",
  "countryCode": "NL",
  "protocol": "vless",
  "isAvailable": true,
  "loadPercent": 42,
  "isPremium": false
}]
```
> Приложение дополнительно меряет пинг само (STUN/urltest) и мержит с этими данными.
> Если эндпоинта нет — список берётся из `outbounds` полученного конфига.

---

## 4. Оплата — **ОТЛОЖЕНО**

**Решение forsaken: сначала оплата в боте, в приложении — потом.**
Значит в v1 из платежей в приложении ровно одно: кнопка, уводящая в бота.

- «Продлить» → `tg://resolve?domain=<bot>&start=subscribe`,
  фолбэк — `https://t.me/<bot>?start=subscribe`.
- Тарифы и цены в приложении **не отображаем**, пока нет собственного флоу оплаты:
  показываем только статус подписки и дату.

Контракт ниже остаётся как задел на этап **E5.1**, но не реализуется сейчас.

### Общие принципы будущего флоу
**Без in-app purchase.** Apple/Google берут 15–30% и требуют использовать их
биллинг для цифровых подписок — для VPN это плохая экономика и риск блокировки.
Оплата — через нашего провайдера в вебвью / внешнем браузере.

### `GET /v1/tariffs`
```json
[{ "id": "t_1m", "name": "1 месяц", "periodDays": 30, "priceAmount": 29900,
   "priceCurrency": "RUB", "isPopular": true, "discountPercent": 0 }]
```

### `POST /v1/payments`
```json
{ "tariffId": "t_1m", "promocode": "SUMMER2026", "returnUrl": "endertrails://payment/done" }
```
```json
{ "paymentId": "pay_1", "amount": 26900, "currency": "RUB",
  "confirmUrl": "https://pay.example/xyz", "expiresAt": "..." }
```

### `GET /v1/payments/{id}`
```json
{ "paymentId": "pay_1", "status": "succeeded" }   // pending | succeeded | failed | canceled
```

Клиентский флоу: открываем `confirmUrl` в `webview_flutter` или `url_launcher` →
на `returnUrl` (deep link `endertrails://...`) возвращаемся в приложение →
опрашиваем `GET /v1/payments/{id}` (до 10 попыток с задержкой 2с) → обновляем `/v1/me`.

---

## 5. Рефералка

### `GET /v1/referral`
```json
{
  "code": "ABC123",
  "link": "https://t.me/endertrails_bot?start=ABC123",
  "invitedCount": 3,
  "activeCount": 2,
  "earnedTotalAmount": 50000,
  "withdrawableAmount": 30000,
  "currency": "RUB",
  "rulesUrl": "https://..."
}
```

---

## 6. Поддержка и служебное

### `GET /v1/support/faq` → `[{ "id", "question", "answerHtml" }]`
### `POST /v1/support/tickets` → `{ "subject", "message" }` → `{ "ticketId" }`
### `GET /v1/app/config` — remote config, вызывается при старте:
```json
{
  "minSupportedVersion": "1.0.0",
  "latestVersion": "1.2.0",
  "maintenance": false,
  "maintenanceMessage": null,
  "announcement": { "id": "a1", "title": "...", "body": "...", "ctaUrl": null },
  "defaultOutboundTag": null,
  "features": { "referral": true, "promocode": true, "splitTunneling": true }
}
```

---

## 7. Что приложение НЕ получает с бэкенда

- Никаких админ-токенов Remnawave.
- Паролей (только при вводе, в тело `POST /v1/auth/email`, без логирования).
- Приватных ключей серверов в открытом виде — только в составе конфига по subscription URL.

---

## 8. Чек-лист сверки с текущим бэкендом (задача E2)

- [ ] Сверить существующие эндпоинты агрегатора/сайта с этим списком
- [ ] Решить: что переиспользуем, что добавляем
- [ ] Договориться о схеме Telegram-входа: бот отдаёт одноразовый токен? Какое время жизни?
- [ ] **Как бот работает с HWID** — зеркалим его поведение, свою политику не выдумываем
- [ ] Есть ли в агрегаторе `GET /v1/servers`? Какой формат полей? Есть ли протокол и нагрузка?
- [ ] Уточнить фактический формат `subscription-userinfo` (`total=0` — безлимит или лимит?)
- [ ] Какой реальный список протоколов на нодах (для иконок и подсказок)
- [ ] Есть ли у бота экран «Мои устройства»? Если да — повторяем в приложении
- [ ] TLS-пиннинг: согласовать отпечатки/ротацию сертификатов
- [ ] Deep link схема: `endertrails://` — занята ли, как registrируем в приложении
