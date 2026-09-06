/// Представление исходящего узла (outbound) для sing-box.
class OutboundRef {
  const OutboundRef({
    required this.tag,
    required this.type,
    required this.server,
    required this.serverPort,
    required this.rawConfig,
  });

  /// Уникальный тег узла (например, "NL - Amsterdam").
  final String tag;

  /// Протокол: vless, vmess, trojan, shadowsocks, hysteria2, tuic.
  final String type;

  /// Адрес сервера (домен или IP).
  final String server;

  /// Порт сервера.
  final int serverPort;

  /// Полная JSON-структура outbound для sing-box.
  final Map<String, dynamic> rawConfig;
}
