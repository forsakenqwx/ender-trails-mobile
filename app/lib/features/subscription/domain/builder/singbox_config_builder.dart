import 'dart:convert';

import '../../../settings/domain/entities/app_settings.dart';
import '../entities/outbound_ref.dart';

/// Генератор и патчер sing-box конфигурации.
///
/// Документация: docs/vpn-core.md §4.
class SingboxConfigBuilder {
  const SingboxConfigBuilder();

  /// Собирает валидный sing-box JSON из списка [outbounds].
  String buildFromOutbounds(
    List<OutboundRef> outbounds, {
    String? selectedTag,
    bool bypassLan = true,
    bool routeRuDirect = false,
    DnsProvider dnsProvider = DnsProvider.cloudflare,
    bool splitTunnelingEnabled = false,
    List<String> bypassedPackages = const [],
  }) {
    // Отфильтровываем заглушки, инфо-карточки и внутренние RU-мосты/бс
    final validOutbounds = outbounds.where((o) {
      if (o.server == '127.0.0.1' || o.server == 'localhost') return false;
      final raw = o.rawConfig;
      if (raw['uuid'] == '00000000-0000-0000-0000-000000000000') return false;
      final tagLower = o.tag.toLowerCase();
      if (tagLower.contains('lte') ||
          tagLower.contains('запасной') ||
          tagLower.contains('белых спис') ||
          tagLower.contains('промокод') ||
          o.server == '31.129.42.172' ||
          o.server.contains('ru-bridge')) {
        return false;
      }
      return true;
    }).toList();

    final targetList = validOutbounds.isNotEmpty ? validOutbounds : outbounds;
    final tags = targetList.map((o) => o.tag).toList();
    final rawOutbounds = targetList.map((o) => o.rawConfig).toList();

    // Определяем активный сервер: выбранный пользователем или быстрый европейский
    String defaultTag;
    if (selectedTag != null && tags.contains(selectedTag)) {
      defaultTag = selectedTag;
    } else {
      final preferred = targetList.firstWhere(
        (o) =>
            o.tag.contains('Швеция') ||
            o.tag.contains('Германия') ||
            o.tag.contains('Нидерланды') ||
            o.tag.contains('Финляндия'),
        orElse: () => targetList.first,
      );
      defaultTag = preferred.tag;
    }

    final isSystemDns = dnsProvider == DnsProvider.system;
    final remoteIp = dnsProvider.ip.isNotEmpty ? dnsProvider.ip : '1.1.1.1';

    final config = <String, dynamic>{
      'log': {
        'level': 'warn',
        'timestamp': true,
      },
      'dns': {
        'servers': [
          if (!isSystemDns) ...[
            {
              'tag': 'remote-dns',
              'type': 'udp',
              'server': remoteIp,
              'server_port': 53,
              'detour': 'proxy',
            },
            {
              'tag': 'remote-dns-tcp',
              'type': 'tcp',
              'server': remoteIp,
              'server_port': 53,
              'detour': 'proxy',
            },
          ],
          {
            'tag': 'local-dns',
            'type': 'local',
            'detour': 'direct',
          },
        ],
        'rules': [
          {'clash_mode': 'direct', 'server': 'local-dns'},
          {
            'domain_suffix': [
              'duckdns.org',
              'endertrails.online',
              'tbank.ru',
              'tinkoff.ru',
              'sber.ru',
              'sberbank.ru',
              'gosuslugi.ru',
              'vk.com',
              'yandex.ru',
              'ya.ru',
              'ru',
              'su',
              'рф',
            ],
            'server': 'local-dns',
          },
        ],
        'final': isSystemDns ? 'local-dns' : 'remote-dns',
        'strategy': 'ipv4_only',
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
          'mtu': 1400,
          'auto_route': true,
          'stack': 'gvisor',
          if (bypassLan)
            'route_exclude_address': [
              '10.0.0.0/8',
              '172.16.0.0/12',
              '192.168.0.0/16',
              '100.64.0.0/10',
            ],
          if (splitTunnelingEnabled && bypassedPackages.isNotEmpty)
            'exclude_package': bypassedPackages,
        },
      ],
      'outbounds': [
        {
          'type': 'selector',
          'tag': 'proxy',
          'outbounds': [...tags, 'auto'],
          'default': defaultTag,
        },
        {
          'type': 'urltest',
          'tag': 'auto',
          'outbounds': tags,
          'url': 'https://cp.cloudflare.com',
          'interval': '3m',
        },
        ...rawOutbounds,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
      ],
      'route': {
        'default_domain_resolver': 'local-dns',
        'rules': [
          {'action': 'sniff'},
          {'protocol': 'dns', 'action': 'hijack-dns'},
          if (bypassLan) {'ip_is_private': true, 'outbound': 'direct'},
          if (splitTunnelingEnabled && bypassedPackages.isNotEmpty)
            {
              'package_name': bypassedPackages,
              'outbound': 'direct',
            },
          {'clash_mode': 'direct', 'outbound': 'direct'},
          {'clash_mode': 'global', 'outbound': 'proxy'},
          {
            'domain_suffix': [
              'duckdns.org',
              'endertrails.online',
              'tbank.ru',
              'tinkoff.ru',
              'sber.ru',
              'sberbank.ru',
              'gosuslugi.ru',
              'vk.com',
              'yandex.ru',
              'ya.ru',
            ],
            'outbound': 'direct',
          },
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
      },
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:9090',
        },
      },
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  /// Минимально патчит готовый sing-box конфиг (BFF), добавляя tun и DNS при их отсутствии.
  String patchExistingConfig(
    String rawConfigJson, {
    bool bypassLan = true,
    bool splitTunnelingEnabled = false,
    List<String> bypassedPackages = const [],
  }) {
    final map = jsonDecode(rawConfigJson) as Map<String, dynamic>;

    // Проверяем наличие inbounds
    final inbounds = (map['inbounds'] as List<dynamic>?) ?? <dynamic>[];
    final hasTun = inbounds.any(
      (inb) => inb is Map<String, dynamic> && inb['type'] == 'tun',
    );

    if (!hasTun) {
      inbounds.insert(0, {
        'type': 'tun',
        'tag': 'tun-in',
        'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
        'mtu': 1400,
        'auto_route': true,
        if (bypassLan)
          'route_exclude_address': [
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
          ],
        if (splitTunnelingEnabled && bypassedPackages.isNotEmpty)
          'exclude_package': bypassedPackages,
      });
      map['inbounds'] = inbounds;
    } else if (splitTunnelingEnabled && bypassedPackages.isNotEmpty) {
      for (final inb in inbounds) {
        if (inb is Map<String, dynamic> && inb['type'] == 'tun') {
          inb['exclude_package'] = bypassedPackages;
        }
      }
    }

    // Включаем clash_api для переключения режимов
    final exp = (map['experimental'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (!exp.containsKey('clash_api')) {
      exp['clash_api'] = {
        'external_controller': '127.0.0.1:9090',
      };
      map['experimental'] = exp;
    }

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
