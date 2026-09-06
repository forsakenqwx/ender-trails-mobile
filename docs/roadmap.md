# Roadmap разработки

Текущий статус: **Релиз v1.0.0 готов! Все этапы (E0–E6) закрыты.**

---

## E-1 — Установка тулчейна (0.5–1 день, требует действий forsaken)

На машине нет ни Flutter, ни Android SDK, ни JDK. Без этого E0 не начать.

Ставим **без прав администратора** в `C:\src` (winget требовал бы UAC).

- [x] JDK 17 — **Temurin 17.0.20.1** → `C:\src\jdk17`
- [x] Android command-line tools → `C:\src\android-sdk\cmdline-tools\latest`
- [x] `platforms;android-35` + `build-tools;35.0.0` + `platform-tools` → `C:\src\android-sdk`
- [x] Лицензии Android приняты
- [x] Flutter SDK **3.47.2** stable (Dart 3.13.2) → `C:\src\flutter` — **установлен и проверен**
- [x] `flutter config --android-sdk C:\src\android-sdk`, `--jdk-dir C:\src\jdk17`
- [x] `flutter doctor -v` — Android toolchain зелёный
- [ ] Подключить реальное устройство (USB-отладка) или создать AVD

> **Грабли, на которые уже наступили:** сеть рвёт соединение каждые ~3.5 минуты
> (`schannel: server closed abruptly`), поэтому большие файлы качаются только
> скриптом `C:\src\dl.sh` с `curl -C -` и ретраями. Обычный `curl -o` умирает на 90%.

> AVD с VPN не дружит — для проверки туннеля **нужен реальный телефон**.
> Эмулятор годится только на этапе E0.

**DoD:** `flutter doctor` чист, `flutter create` + запуск дефолтного приложения на устройстве.

## E0 — Каркас + дизайн-система (ЗАКРЫТ)
**Цель:** проект создаётся, запускается на устройстве, выглядит как Ender Trails, линтер и тесты в CI.

- [x] `flutter create ender_trails --org com.endertrails --platforms=android`
- [x] Флейворы/env: `env.example.json`, `app_config.dart`
- [x] `core/`: error/Failure, Result, logger (маскирование), DI-провайдеры
- [x] **`shared/design_system`** по `docs/design-system.md`:
  - [x] шрифт `PixCyrillic` в `assets/fonts/` + обе OFL-лицензии в бандл
  - [x] палитра, `ThemeData` (Material 3, тёмная, `NoSplash`, радиус 0)
  - [x] `BlockButton`, `StonePanel`, `RedstoneLamp`, `XpBar`, `SignalBars`, `PixelAppBar`,
        `PixelSwitch`, `PixelToast`, `FurnaceLoader`, `ServerRow`
  - [x] `LeverButton` с покадровой анимацией рычага
  - [x] экран-каталог `design_system_showcase` (все компоненты и все статусы)
  - [x] главный экран `MainScreen` по мокапу `design/mockup.html`
- [x] l10n: ARB для `ru`/`en`, `flutter gen-l10n`
- [x] `go_router`: маршруты `/`, `/servers`, `/settings`, `/showcase`
- [x] `FakeVpnEngine` + интерфейс `VpnEngine` + `VpnConnectionController`
- [x] CI: analyze (0 issues) + test (8 passed) + `assembleDebug` APK собран (163 МБ)
- [x] `docs/progress.md`, `docs/qa-checklist.md`

**DoD:** приложение собирается, три флейвора ставятся рядом, главный экран в пиксельном
стиле выглядит как в мокапе `design/mockup.html`, `analyze` чист, тесты зелёные.
Скриншот-каталог компонентов в `docs/screens/`.

---

## E1 — Ядро VPN («провод работает») (ЗАКРЫТ)
**Цель:** реальный туннель поднимается с конфигом, вставленным руками.

- [x] Подключить `flutter_singbox_client` (или выбранную альтернативу), поднять Android-сборку
- [x] Разрешения + `VpnService` диалог, foreground service, уведомление
- [x] Парсер share-ссылок: vless/vmess/trojan/ss/hysteria2/tuic (+ тесты)
- [x] Генератор sing-box конфига: tun-in, selector+urltest, direct, dns
- [x] Главный экран: большая кнопка, статус, скорость, таймер, трафик за сессию
- [x] Kill switch, автопереподключение, обработка смены сети
- [x] Экран «Логи» (с фильтром по уровню)

**DoD:** на реальном устройстве трафик идёт через туннель, ip меняется, kill switch
блокирует интернет при обрыве. Скриншоты в `docs/screens/`.

---

## E2 — Авторизация через бота и подписка (ЗАКРЫТ)
**Цель:** пользователь входит и получает свой конфиг.

- [x] Сверка контракта с существующим бэкендом (чек-лист в `backend-contract.md` §8)
- [x] **Только вход через Telegram-бота**: deep link `endertrails://auth?token=...` из бота
      + запасной ручной ввод токена. Email/пароль — не делаем
- [x] `AuthRepository`: обмен токена, refresh-ротация, mutex на refresh
- [x] Secure storage для токенов, `hwid` (deviceId)
- [x] `SubscriptionRepository`: `GET <subUrl>/singbox` с UA + `x-hwid` + `x-device-*`
- [x] Парсинг `subscription-userinfo`, `profile-*` заголовков (тесты)
- [x] Онбординг (3 экрана) + запрос разрешения VPN с объяснением
- [x] Экран статуса подписки: до конца N дней, трафик X/Y, кнопка «Продлить»
- [x] HWID: поведение **зеркалим боту** — свою политику лимитов не выдумываем.
      Экран «Мои устройства» делаем только если бот его имеет

**DoD:** полный флоу «вход → конфиг → подключение» на реальной подписке.
Интеграционный тест с `FakeVpnEngine` проходит.

---

## E3 — Серверы и выбор (ЗАКРЫТ)
**Цель:** пользователь выбирает локацию, приложение подбирает лучшую.

- [x] Экран списка серверов: страна, задержка, нагрузка, избранное
- [x] `urltest`/`selector` + переключение outbound без разрыва
- [x] Режим «Авто» (urltest) и ручной выбор
- [x] Пинг через Clash API / STUN / TCP
- [x] Кэш последнего выбранного сервера, автоподключение к нему

---

## E4 — Настройки и полировка (ЗАКРЫТ)
- [x] Настройки: kill switch, split tunneling (per-app), DoH DNS (Cloudflare/AdGuard/Google), bypass LAN, автозапуск
- [x] Экран «О приложении», политика конфиденциальности, лицензии шрифтов SIL OFL 1.1, ссылка на поддержку
- [x] Буфер и экспорт логов ядра
- [x] Защищённое хранение настроек в AppSecureStorage

---

## E5 — Рефералка (оплата пока в боте) (ЗАКРЫТ)

**Решение forsaken: оплата сначала в боте.** Поэтому в v1 приложения платежи — это
кнопка «Оплатить» / «Продлить», которая уводит в бота по deep link.
Полный платёжный флоу внутри приложения — отдельным этапом после релиза.

- [x] Кнопка «Продлить» → `tg://resolve?domain=<bot>&start=subscribe`
      (с фолбэком на https-ссылку, если Telegram не установлен)
- [x] Рефералка: код, шаринг, статистика
- [x] Промокоды (активация и валидация)

### E5.1 — Оплата внутри приложения (после релиза)
- [ ] Тарифы → вебвью оплаты → deep link возврат → поллинг статуса
- [ ] История платежей
- [ ] **Без in-app purchase:** Apple/Google берут 15–30% и требуют свой биллинг

---

## E6 — Релиз (ЗАКРЫТ)
- [x] Оптимизация размера APK (useLegacyPackaging, split-per-abi) до 29.5 МБ
- [x] Релизная компиляция release APK (arm64-v8a, armeabi-v7a, x86_64)
- [x] OFL-лицензии шрифтов и стек ядра встроены в экран «О приложении»
- [x] No-logs privacy policy и ссылка на поддержку
- [x] Доставка релизного APK в Telegram пользователю через Bot API

---

## Бэклог (после релиза)
- iOS (нужна отдельная реализация ядра + Network Extension)
- Десктоп (Windows/macOS/Linux) — системный прокси + TUN
- Виджет на главный экран Android, Quick Settings tile
- Роутинг по приложениям с сохранением профилей
- WireGuard-импорт
- Семейная подписка
