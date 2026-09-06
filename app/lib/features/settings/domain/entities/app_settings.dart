/// Поддерживаемые DNS-серверы для безопасного резолвинга в sing-box.
enum DnsProvider {
  cloudflare(
    name: 'Cloudflare',
    url: 'https://1.1.1.1/dns-query',
    ip: '1.1.1.1',
    description: 'Быстрый и приватный DoH (1.1.1.1)',
  ),
  adguard(
    name: 'AdGuard DNS',
    url: 'https://dns.adguard-dns.com/dns-query',
    ip: '94.140.14.14',
    description: 'Блокировка рекламы и трекеров',
  ),
  google(
    name: 'Google DNS',
    url: 'https://dns.google/dns-query',
    ip: '8.8.8.8',
    description: 'Надёжный DoH от Google (8.8.8.8)',
  ),
  system(
    name: 'Системный DNS',
    url: '',
    ip: '',
    description: 'DNS провайдера или текущей сети',
  );

  const DnsProvider({
    required this.name,
    required this.url,
    required this.ip,
    required this.description,
  });

  final String name;
  final String url;
  final String ip;
  final String description;
}

/// Модель настроек приложения.
class AppSettings {
  const AppSettings({
    this.killSwitch = false,
    this.bypassLan = true,
    this.autoConnect = false,
    this.dnsProvider = DnsProvider.cloudflare,
    this.splitTunnelingEnabled = false,
    this.bypassedPackages = const [],
  });

  final bool killSwitch;
  final bool bypassLan;
  final bool autoConnect;
  final DnsProvider dnsProvider;
  final bool splitTunnelingEnabled;
  final List<String> bypassedPackages;

  AppSettings copyWith({
    bool? killSwitch,
    bool? bypassLan,
    bool? autoConnect,
    DnsProvider? dnsProvider,
    bool? splitTunnelingEnabled,
    List<String>? bypassedPackages,
  }) {
    return AppSettings(
      killSwitch: killSwitch ?? this.killSwitch,
      bypassLan: bypassLan ?? this.bypassLan,
      autoConnect: autoConnect ?? this.autoConnect,
      dnsProvider: dnsProvider ?? this.dnsProvider,
      splitTunnelingEnabled:
          splitTunnelingEnabled ?? this.splitTunnelingEnabled,
      bypassedPackages: bypassedPackages ?? this.bypassedPackages,
    );
  }

  Map<String, dynamic> toJson() => {
        'killSwitch': killSwitch,
        'bypassLan': bypassLan,
        'autoConnect': autoConnect,
        'dnsProvider': dnsProvider.name,
        'splitTunnelingEnabled': splitTunnelingEnabled,
        'bypassedPackages': bypassedPackages,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final dnsName = json['dnsProvider'] as String?;
    final dns = DnsProvider.values.firstWhere(
      (d) => d.name == dnsName,
      orElse: () => DnsProvider.cloudflare,
    );

    return AppSettings(
      killSwitch: json['killSwitch'] as bool? ?? false,
      bypassLan: json['bypassLan'] as bool? ?? true,
      autoConnect: json['autoConnect'] as bool? ?? false,
      dnsProvider: dns,
      splitTunnelingEnabled: json['splitTunnelingEnabled'] as bool? ?? false,
      bypassedPackages: (json['bypassedPackages'] as List?)?.cast<String>() ?? const [],
    );
  }
}
