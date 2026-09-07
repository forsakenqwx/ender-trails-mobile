/// Конфигурация времени сборки (--dart-define / env.json).
class AppConfig {
  const AppConfig._();

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.endertrails.online',
  );

  static const String subDomain = String.fromEnvironment(
    'SUB_DOMAIN',
    defaultValue: 'panel-ender.duckdns.org',
  );

  static const String supportBot = String.fromEnvironment(
    'SUPPORT_BOT',
    defaultValue: 'EnderTrailsVPN_bot',
  );

  static const String supportUsername = 'Yuvixshin';

  static const String appVersion = '1.0.1 Beta';
  static const int buildNumber = 2;

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
}
