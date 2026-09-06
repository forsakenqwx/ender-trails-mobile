import 'dart:developer' as dev;

/// Уровни логирования.
enum LogLevel { debug, info, warning, error }

/// Минималистичный логгер с маскированием секретов.
///
/// Собственная реализация вместо внешнего пакета: ноль зависимостей,
/// работает офлайн, а маскирование — требование MASTER-PROMPT §3.3,
/// которое всё равно пришлось бы писать поверх любого логгера.
///
/// TODO(E4): подключить Sentry как второй sink для error/critical.
class AppLogger {
  const AppLogger._();

  static LogLevel minLevel = LogLevel.debug;

  /// Маски: вырезаем всё, что может быть секретом.
  static final List<RegExp> _secretPatterns = <RegExp>[
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
    RegExp(
      r'(token|password|secret|api[-_]?key|authorization)"?\s*[:=]\s*"?[^\s",}]+',
      caseSensitive: false,
    ),
    RegExp(r'vless://[^\s"''<>]+'),
    RegExp(r'vmess://[^\s"''<>]+'),
    RegExp(r'trojan://[^\s"''<>]+'),
    RegExp(r'ss://[^\s"''<>]+'),
    RegExp(r'x-hwid"?\s*[:=]\s*\S+', caseSensitive: false),
  ];

  /// Режет секреты в произвольной строке.
  static String mask(String input) {
    var out = input;
    for (final pattern in _secretPatterns) {
      out = out.replaceAllMapped(pattern, (m) => '<masked>');
    }
    return out;
  }

  static void debug(String message) => _log(LogLevel.debug, message);

  static void info(String message) => _log(LogLevel.info, message);

  static void warning(String message) => _log(LogLevel.warning, message);

  static void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message);
    if (error != null) _log(LogLevel.error, 'cause: ${mask(error.toString())}');
    if (stack != null) dev.log(mask(stack.toString()), name: 'ET.stack');
  }

  static void _log(LogLevel level, String message) {
    if (level.index < minLevel.index) return;
    dev.log(
      mask(message),
      name: 'ET.${level.name}',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }
}
