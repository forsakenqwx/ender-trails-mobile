/// Модель сервера для списка выбора.
class ServerModel {
  const ServerModel({
    required this.tag,
    required this.name,
    required this.countryCode,
    required this.protocol,
    required this.server,
    required this.port,
    this.pingMs,
    this.isAuto = false,
  });

  final String tag;
  final String name;
  final String countryCode;
  final String protocol;
  final String server;
  final int port;
  final int? pingMs;
  final bool isAuto;

  ServerModel copyWith({
    String? tag,
    String? name,
    String? countryCode,
    String? protocol,
    String? server,
    int? port,
    int? pingMs,
    bool? isAuto,
  }) {
    return ServerModel(
      tag: tag ?? this.tag,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      pingMs: pingMs ?? this.pingMs,
      isAuto: isAuto ?? this.isAuto,
    );
  }

  /// Специальный узел «Авто-выбор» (быстрейший).
  static const auto = ServerModel(
    tag: 'auto',
    name: 'Авто-выбор',
    countryCode: 'AUTO',
    protocol: 'URLTEST',
    server: '',
    port: 0,
    isAuto: true,
  );
}
