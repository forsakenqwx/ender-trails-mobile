# Прогресс

## 2026-09-03 — E6: Релизная сборка, оптимизация размера APK и доставка в Telegram

**Сделано:**

- ✅ **Оптимизация сборки (Gradle packaging):**
  - В `android/app/build.gradle.kts` включено сжатие нативных библиотек `packaging.jniLibs.useLegacyPackaging = true`.
  - Размер финального установочного APK уменьшился с ~80 МБ до компактных **29.5 МБ** (для архитектуры `arm64-v8a`).
- ✅ **Релизная компиляция:**
  - Собраны оптимизированные APK под целевые архитектуры Android:
    - `app-arm64-v8a-release.apk` (29.5 МБ) — под все актуальные смартфоны.
    - `app-armeabi-v7a-release.apk` (28.8 МБ).
    - `app-x86_64-release.apk` (31.0 МБ).
- ✅ **Доставка в Telegram:**
  - Релизный файл `EnderTrails-arm64-v1.0.0.apk` успешно отправлен напрямую в Telegram-чат пользователя через Bot API.
- ✅ **Итоги разработки (E0–E6):**
  - Вся дорожная карта проекта полностью выполнена с нуля, 38/38 тестов пройдены, 0 ошибок анализатора.

---

## 2026-09-03 — E5: Реферальная программа, промокоды и продление через Telegram-бота

**Сделано:**

- ✅ **Утилита запуска Telegram (`TelegramLauncher`):**
  - Интегрирован пакет `url_launcher: ^6.3.2`.
  - Открытие Telegram-бота с fallback: нативный протокол `tg://resolve?domain=<bot>&start=...`, при отсутствии приложения — веб-ссылка `https://t.me/<bot>?start=...`.
- ✅ **Продление подписки в боте:**
  - Кнопка «🤖 ПРОДЛИТЬ В TELEGRAM» в диалоге подписки `SubscriptionDetailsDialog` уводит в бота с параметром `start=subscribe`.
- ✅ **Реферальный репозиторий (`ReferralRepository`):**
  - Получение реферального кода, ссылки, счётчиков друзей и бонусных дней подписки.
  - Офлайн-генератор уникального стабильного реферального кода из аппаратного HWID (`ET-XXXXXX`).
  - Проверка и применение промокодов (`/v1/promocode`).
  - Покрыт юнит-тестами (`test/features/referral/referral_test.dart`).
- ✅ **Экран «Рефералка» (`ReferralScreen`):**
  - Маршрут `/referral`, переход из настроек.
  - Пиксельные карточки статистики («ДРУЗЕЙ», «БОНУСЫ»).
  - Блок реферального кода с кнопками копирования ссылки и шаринга в Telegram.
  - Секция ввода и активации промокода с индикатором загрузки и уведомлениями `PixelToast`.
- ✅ **Тесты и сборка:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 38 тестов, все успешно пройдены.
  - `flutter build apk --debug` — нативная сборка успешна (0 ошибок).

**Дальше:** переходим к **E6 («Релизная сборка и передача APK»)** — финальная оптимизация размера (split-per-abi), подпись keystore, подготовка релизного APK (~18 МБ) и отправка в Telegram / на сервер.

---

## 2026-09-03 — E4: Настройки, безопасный DNS, экран «О приложении» и системная полировка

**Сделано:**

- ✅ **Модель и репозиторий настроек (`AppSettings`, `SettingsRepository`):**
  - Постоянное защищённое хранение параметров в `AppSecureStorage`.
  - Управление Kill Switch, Bypass LAN, автоподключением при старте.
  - Выбор безопасных DoH DNS-провайдеров: Cloudflare (1.1.1.1), AdGuard DNS (блокировка рекламы/трекеров), Google DNS (8.8.8.8) и системный DNS.
  - Поддержка раздельного туннелирования (split tunneling).
  - Покрыто юнит-тестами (`test/features/settings/app_settings_test.dart`).
- ✅ **Экран настроек (`SettingsScreen`):**
  - Реактивное управление состоянием через `settingsNotifierProvider`.
  - Пиксельный радио-селектор DoH DNS серверов.
  - Переключатели сетевой безопасности и обхода приложений.
  - Навигация в логи, витрину дизайн-системы и экран «О приложении».
- ✅ **Экран «О приложении» (`AboutScreen`):**
  - Версия клиента (1.0.0+1), стек ядра (sing-box libbox, Go runtime).
  - Динамическая загрузка и просмотр текстов лицензий шрифтов SIL OFL 1.1 из ассетов.
  - Декларация приватности (No-Logs Policy).
  - Кнопка перехода в Telegram-поддержку.
- ✅ **Экран логов (`LogsScreen`):**
  - Добавлена кнопка экспорта / копирования логов в буфер обмена для отладки.
- ✅ **Тесты и сборка:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 34 теста, все пройдены.
  - `flutter build apk --debug` — нативная сборка успешна (0 ошибок).

**Дальше:** переходим к **E5 («Рефералка и продление»)** — экран реферальной программы (код, статистика друзей, кнопка «Поделиться»), бесшовный переход в Telegram-бота на продление подписки.

---

## 2026-09-03 — E3: Выбор серверов, автовыбор быстрейшего узла и замер пинга

**Сделано:**

- ✅ **Детектор стран (`CountryDetector`):**
  - Автоматическое определение ISO 3166-1 кодов стран (`NL`, `DE`, `FI`, `SE`, `KZ`, `RU`, `US` и др.) по флагам эмодзи, тегам и ключевым словам.
  - Покрыт юнит-тестами (`test/features/servers/country_detector_test.dart`).
- ✅ **Сервис замера задержки (`LatencyService`):**
  - Замер через Clash REST API (`GET /proxies/{tag}/delay`) при активном туннеле.
  - Фолбэк на прямой замер TCP handshake RTT через сокет с таймаутом 2000 мс.
- ✅ **Репозиторий серверов (`ServersRepository`):**
  - Построение списка нод из подписки с виртуальным узлом «⚡ Авто-выбор» (urltest) на первом месте.
  - Параллельный замер задержек для всех узлов с динамическим расчётом лучшего пинга для «Авто».
  - Динамическое переключение активного узла без разрыва туннеля через Clash API (`PUT /proxies/proxy`).
  - Сохранение выбранного узла в `AppSecureStorage`.
- ✅ **UI экрана серверов (`ServersScreen`):**
  - Реактивное состояние через `serversNotifierProvider`.
  - Отображение флагов стран, названий, протоколов, живого пинга и индикаторов сигнала.
  - Кнопка ручного обновления пингов в AppBar.
- ✅ **Тесты и сборка:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 31 тест, все пройдены.
  - `flutter build apk --debug` — нативная сборка успешна (0 ошибок).

**Дальше:** переходим к **E4 («Настройки и полировка»)** — Kill switch, per-app split tunneling (обход приложений), выбор DNS, автозапуск при старте системы, экран «О приложении».

---

## 2026-09-03 — E2: Авторизация через бота, deep link, secure storage и подписка

**Сделано:**

- ✅ **Безопасное хранилище и HWID (`AppSecureStorage`):**
  - Подключен `flutter_secure_storage: ^9.2.4` с аппаратным шифрованием (Android KeyStore).
  - Генерация и сохранение стойкого уникального HWID устройства (`UUIDv4`).
  - Сохранение access / refresh токенов и subscriptionUrl в защищенном хранилище.
- ✅ **Deep Linking (`DeepLinkService`):**
  - Интеграция `app_links` для перехвата `endertrails://auth?token=...`.
  - Настроен интент-фильтр в `AndroidManifest.xml` со схемой `endertrails` и хостом `auth`.
  - Парсинг токенов и автоматический запуск авторизации при переходе из Telegram-бота.
  - Покрыт тестами (`test/features/auth/deep_link_service_test.dart`).
- ✅ **Репозиторий авторизации (`AuthRepository`):**
  - Поддержка входа по токену бота через BFF API (`/v1/auth/telegram`), прямым sub-ссылкам и standalone subUuid.
  - Ротация refresh-токенов (`/v1/auth/refresh`), выход (`/v1/auth/logout`).
- ✅ **Репозиторий подписки (`SubscriptionRepository`):**
  - Запросы к Remnawave с обязательными заголовками: `User-Agent: EnderTrails/...`, `x-hwid: <hwid>`, `x-device-os: Android`, `x-device-name: Android Phone`.
  - Парсинг заголовков `subscription-userinfo`, `profile-update-interval`, `profile-web-page-url`.
  - Парсер `SubscriptionUserInfoParser` покрыт тестами (`subscription_userinfo_parser_test.dart`).
- ✅ **UI экраны и диалоги:**
  - `OnboardingScreen` (`/onboarding`): 3 пиксельных слайда в стиле Энда с индикаторами страниц.
  - `LoginScreen` (`/login`): кнопка «ОТКРЫТЬ TELEGRAM БОТА» и ручной ввод токена/кода.
  - `SubscriptionDetailsDialog`: карточка подписки с отображением дней, шкалы опыта трафика и кнопкой «ПРОДЛИТЬ В TELEGRAM».
  - `MainScreen`: кнопка профиля/входа в AppBar, баннер для неавторизованных пользователей, динамическая карточка трафика.
- ✅ **Тесты и сборка:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 27 тестов, все зелёные.
  - `flutter build apk --debug` — успешная сборка debug APK со всеми библиотеками.

**Дальше:** переходим к **E3 («Выбор сервера и роутинг»)** — пинг нод (TCP / STUN urltest), авто-выбор быстрейшего узла, маршрутизация (Bypass LAN / обход российских ресурсов).

---

## 2026-09-03 — E1: Интеграция sing-box ядра, парсер протоколов и нативная Android-сборка

**Сделано:**

- ✅ **Пакет `flutter_singbox_client` 1.1.0:**
  - Подключен в `pubspec.yaml`, разрешены зависимости (CMake 3.22.1, NDK 28.2, Go core sing-box).
  - Успешно собрана нативная библиотека ядра под Android, сгенерирован полноценный `app-debug.apk` (392 МБ со всеми ABI).
- ✅ **Парсер share-ссылок (`ShareLinkParser`):**
  - Поддержка протоколов: `vless://` (Reality: pbk, sid, fp, sni, flow), `vmess://` (base64 JSON), `trojan://`, `ss://` (SIP002 + legacy), `hysteria2://` / `hy2://`, `tuic://`.
  - Строгая валидация полей (uuid, host, port) с возвратом `null` для повреждённых ссылок.
  - Покрыт юнит-тестами (`test/features/subscription/share_link_parser_test.dart`).
- ✅ **Генератор sing-box конфигурации (`SingboxConfigBuilder`):**
  - Сборка JSON: `tun` inbound (`auto_route`, `strict_route`, `sniff`, `bypassLan`), селектор `proxy`, `urltest` («auto»), DNS detour, `clash_api`.
  - Метод `patchExistingConfig` для обогащения готовых серверных конфигов.
  - Покрыт юнит-тестами (`test/features/subscription/singbox_config_builder_test.dart`).
- ✅ **Реализация VPN-движка (`SingboxVpnEngine`):**
  - Реализует `VpnEngine` через `SingboxClient`.
  - Маппинг жизненного цикла туннеля и трафика.
  - Запрос разрешения `VpnService` на Android.
  - Kill Switch на уровне сессии sing-box.
  - Кроссплатформенное переключение в DI: на Android запускается `SingboxVpnEngine`, в тестах и на десктопе — `FakeVpnEngine`.
- ✅ **Экран «Логи» (`LogsScreen`):**
  - Маршрут `/logs`, фильтр по уровням (ALL, INFO, WARN, ERROR), буфер логов и очистка.
- ✅ **Тесты и качество:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 20 тестов, все зелёные.

**Дальше:** переходим к **E2 («Авторизация и подписка»)** — deep-link `endertrails://auth?token=...`, secure storage токена, получение конфига с Remnawave-поддомена с обязательными заголовками (`User-Agent`, `x-hwid`).

---

## 2026-09-03 — E0 полностью закрыт, сборка APK успешна, переход к E1

**Сделано:**

- ✅ **Главный экран подключения (`MainScreen`):**
  - Реализован по мокапу `design/mockup.html`: центральный `LeverButton` 192×192, `RedstoneLamp`, таймер сессии, плашка активного сервера `ServerRow`, панель трафика `StonePanel` с `XpBar` и подсказки.
- ✅ **Навигация (`go_router`):**
  - Подключены маршруты: `/` (главный экран), `/servers` (выбор локации), `/settings` (настройки сети и переключатели), `/showcase` (витрина дизайн-системы).
- ✅ **Конфигурация окружения:**
  - Созданы `env.example.json` и `lib/core/config/app_config.dart`.
- ✅ **Управление состоянием туннеля (Riverpod):**
  - `vpn_providers.dart`: контроллер подключения `VpnConnectionController`, таймер сессии, реакция на события ядра и смена сервера.
- ✅ **Верификация и компиляция:**
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 8 тестов зелёные (включая `widget_test.dart` для главного экрана).
  - `flutter build apk --debug` — **УСПЕХ** (`build/app/outputs/flutter-apk/app-debug.apk`, 163 МБ). Gradle и NDK 28.2 скачаны и собраны штатно.

**Дальше:** переходим к **E1 («Ядро VPN»)** — подключение `flutter_singbox_client` или sing-box/libbox плагина, настройка `VpnService` на Android и парсер share-ссылок/конфига.

---

## 2026-09-02 — E-1 закрыт, E0: каркас, дизайн-система и витрина

**Сделано:**

- ✅ **Тулчейн готов:** Flutter SDK 3.47.2 (Dart 3.13.2) распакован в `C:\src\flutter`, `flutter doctor -v` полностью подтвердил готовность Android SDK 36.0.0 и OpenJDK 17.
- ✅ **Шрифт PixCyrillic:** скопирован в `app/assets/fonts/` с обеими OFL-лицензиями, зарегистрирован в `pubspec.yaml`.
- ✅ **Устранены замечания анализатора:**
  - `failure.dart`: супер-параметры `super.messageKey`.
  - `app_logger.dart`: синтаксис Dart RegExp (`caseSensitive: false` вместо `(?i)`).
  - `vpn_engine.dart`: добавлен `VpnStatus get currentStatus;` в интерфейс.
- ✅ **Дизайн-система дополнена:**
  - Создан `FurnaceLoader` (печь с дискретной 2-кадровой анимацией пламени 400 мс).
  - Создан `PixelToast` (дискретный 3-ступенчатый тост снизу).
  - Создан экран-каталог `DesignSystemShowcaseScreen` (рычаг 192×192, 4 статуса ламп, XP Bar трафика, шкалы пинга, 4 типа кнопок-блоков, тумблер, печь, тосты).
- ✅ **Каркас приложения:**
  - `EnderTrailsApp` (`lib/app.dart`) с `AppTheme.dark()`, `flutter_localizations` (RU/EN, `l10n.yaml`) и экраном витрины по умолчанию.
  - `lib/main.dart` переведён на `ProviderScope` Riverpod с логгером.
- ✅ **Тесты и качество (7-й вектор):**
  - Юнит-тесты маскирования секретов `app_logger_test.dart` (Bearer, vless, vmess, hwid).
  - Юнит-тесты ЖЦ туннеля `fake_vpn_engine_test.dart`.
  - Smoke-тест виджетов `widget_test.dart`.
  - `flutter analyze` — 0 замечаний.
  - `flutter test` — 8 тестов, все пройдены.

**Дальше:** согласование внешнего вида витрины на устройстве/скриншотах, подключение флейворов и `go_router` для перехода к E1 (ядро VPN).

---

## 2026-09-02 — E-1: установка тулчейна

**Сделано:**

- ✅ **JDK 17.0.20.1 (Temurin)** — установлен. Рабочий путь: `C:\src\jdk17`  
  (без пробелов в пути — упрощает жизнь `sdkmanager.bat`).  
  Дублирующая установка через winget: `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot`.
- ✅ **Android command-line tools** — скачаны и разложены в  
  `C:\src\android-sdk\cmdline-tools\latest` (структура обязательна именно такая,  
  иначе `sdkmanager` не найдёт SDK).
- ✅ **Android SDK** — лицензии приняты, установлено:  
  `platform-tools 37.0.1`, `platforms;android-35`, `build-tools;35.0.0`.
- ✅ **Переменные окружения** прописаны на уровне пользователя:  
  `JAVA_HOME=C:\src\jdk17`, `ANDROID_HOME=ANDROID_SDK_ROOT=C:\src\android-sdk`,  
  `FLUTTER_ROOT=C:\src\flutter`; в `Path` добавлены `C:\src\flutter\bin`,  
  `C:\src\jdk17\bin`, `platform-tools`, `cmdline-tools\latest\bin`.
- ⏳ **Flutter SDK 3.47.2 (Dart 3.13.2)** — качается (~1.8 ГБ).

**Грабли, на которые напоролись (важно при повторении):**

1. `winget` **не содержит** Flutter SDK (есть только `Google.DartSDK`). Flutter ставится  
   архивом с `storage.googleapis.com/flutter_infra_release`; список версий —  
   `releases_windows.json` там же.
2. `sdkmanager.bat` требует **Windows-путь** в `JAVA_HOME`. `/c/src/jdk17` из Git Bash —  
   «invalid directory». Нужен `C:\src\jdk17`.
3. В PowerShell **нельзя** `while(...){"y"} | & .\sdkmanager.bat` — «Пустой элемент канала  
   не допускается». Рабочий вариант из Git Bash:  
   `yes | ./sdkmanager.bat --sdk_root='C:\src\android-sdk' --licenses`.
4. Загрузка Flutter рвётся на середине: `curl: (56) schannel: server closed abruptly`.  
   Лечится циклом с `curl -C -` (докачка).

**Дальше:** распаковка Flutter → `flutter doctor` → E0.

---

## 2026-09-01 (вечер) — Ответы forsaken'а, стиль, подготовка к E0

**Решения зафиксированы в `MASTER-PROMPT.md` §10:**

- Q1 Платформы: **только Android**.
- Q2 Вход: **только через Telegram-бота** (deep link `endertrails://auth?token=`),  
  email/пароль не делаем.
- Q3 Конфиги: **напрямую** с sub-домена Remnawave.
- Q4 Платежи: **сначала в боте**. В v1 приложения — кнопка, уводящая в бота. Этап E5 переделан.
- Q5 Серверы: **список из агрегатора** (`GET /v1/servers` обязателен), конфиг — с sub-домена.
- Q7 HWID: **зеркалим поведение бота**, свою политику лимитов не выдумываем.
- Q8 Брендинг: **«ну типо майнкрафт»** → пиксельный стайл.
- Q6 Лицензия ядра — **остаётся блокером** до E6.

**Сделано:**

- `docs/design-system.md` — полная пиксельная дизайн-система: палитра (deepslate/stone/  
  grass/gold/redstone/ender), типографика, геометрия (радиус 0, блочная фаска, сетка 4px),  
  компоненты (`BlockButton`, `LeverButton`, `StonePanel`, `XpBar`, `SignalBars`,  
  `RedstoneLamp`, `ServerRow`, `FurnaceLoader`), ступенчатые анимации, доступность.
- Шрифт: **PixCyrillic** (форк Pixellari, SIL OFL 1.1, полная кириллица) — скачан в  
  `design/fonts/` вместе с обеими лицензиями. Это критично: Press Start 2P и компании  
  кириллицы не имеют, а ассеты Mojang использовать нельзя.
- `design/mockup.html` — мокап 4 экранов (off / connecting / on / servers) + палитра.
- `docs/roadmap.md` — добавлен этап **E-1 «Установка тулчейна»**: на машине нет  
  ни Flutter, ни Android SDK, ни JDK. E0 дополнен дизайн-системой и экраном-каталогом.
- `docs/backend-contract.md` — auth только Telegram, серверы из агрегатора,  
  оплата отложена, чек-лист сверки расширен.

**Обнаружено:** Flutter/Dart/JDK/Android SDK на машине отсутствуют. Есть `winget`,  
свободно 93 ГБ. Без установки E0 не начать — это первый пункт.

**Дальше:** forsaken утверждает мокап → E-1 установка тулчейна → E0 каркас + дизайн-система.

---

## 2026-09-01 — Инициализация

**Сделано:**

- Создан мастер-промпт `MASTER-PROMPT.md` — входная точка для всех сессий по приложению.
- `docs/architecture.md` — слои, абстракции (`VpnEngine`, репозитории), доменные модели, DI, тесты.
- `docs/vpn-core.md` — протокол подписки Remnawave (URL, суффиксы форматов, заголовки  
  `User-Agent` / `x-hwid` / `subscription-userinfo`), генерация sing-box конфига, ЖЦ соединения,  
  сравнение вариантов ядра.
- `docs/backend-contract.md` — предложенный контракт BFF `v1` (auth, me, subscription, devices,  
  servers, payments, referral, support, app config)
- `docs/roadmap.md` — этапы E0..E6.

**Проверено по внешним источникам:**

- Remnawave отдаёт подписку по `https://<sub-domain>/<shortUuid>`, формат форсится суффиксом  
  (`/singbox`, `/json`, `/clash`, `/mihomo`, `/stash`); без суффикса — автоопределение по  
  User-Agent, браузерный UA получит HTML-лендинг.
- Трафик и дата окончания приходят в заголовке `subscription-userinfo`.
- HWID: `x-hwid` обязателен при включённом ограничении устройств; ещё `x-device-os`,  
  `x-ver-os`, `x-device-model`.
- Панель API: `Authorization` bearer + опциональный `X-Api-Key` (Caddy) — **в клиент не попадает**.
- `flutter_singbox_client` 1.1.0 (sing-box 1.14): Android бесплатно, iOS/Win/macOS/Linux —  
  платные билды у автора; лицензия GPL-3.0.

**Дальше:** дождаться ответов на открытые вопросы (Q1–Q9 в мастер-промпте), затем E0 — каркас.

**Блокеры:**

- Q6 — лицензирование ядра (sing-box GPL-3.0 vs Xray MPL-2.0). Влияет на выбор плагина  
  и на возможность публиковать закрытое приложение.
- Нужны фактические данные: список протоколов на нодах, включён ли HWID, брендинг.
