import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/settings/domain/entities/app_settings.dart';
import 'package:ender_trails/features/subscription/domain/builder/singbox_config_builder.dart';
import 'package:ender_trails/features/subscription/domain/entities/outbound_ref.dart';

void main() {
  const builder = SingboxConfigBuilder();

  final sampleOutbounds = [
    const OutboundRef(
      tag: 'NL - Amsterdam',
      type: 'vless',
      server: '198.51.100.1',
      serverPort: 443,
      rawConfig: {
        'type': 'vless',
        'tag': 'NL - Amsterdam',
        'server': '198.51.100.1',
        'server_port': 443,
      },
    ),
    const OutboundRef(
      tag: 'DE - Frankfurt',
      type: 'vmess',
      server: '198.51.100.2',
      serverPort: 443,
      rawConfig: {
        'type': 'vmess',
        'tag': 'DE - Frankfurt',
        'server': '198.51.100.2',
        'server_port': 443,
      },
    ),
  ];

  group('SingboxConfigBuilder', () {
    test('buildFromOutbounds generates valid sing-box configuration', () {
      final jsonStr = builder.buildFromOutbounds(
        sampleOutbounds,
        bypassLan: true,
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Inbounds
      final inbounds = map['inbounds'] as List;
      expect(inbounds.length, 1);
      final tun = inbounds[0] as Map<String, dynamic>;
      expect(tun['type'], 'tun');
      expect(tun['mtu'], 1400);
      expect(tun['auto_route'], isTrue);
      expect(tun['route_exclude_address'], contains('192.168.0.0/16'));

      // Outbounds: 2 nodes + selector + urltest + direct + block = 6 (dns outbound removed in 1.13+)
      final outbounds = map['outbounds'] as List;
      expect(outbounds.length, 6);

      final selector = outbounds.firstWhere((o) => o['tag'] == 'proxy');
      expect(selector['type'], 'selector');
      expect(selector['outbounds'], contains('NL - Amsterdam'));
      expect(selector['outbounds'], contains('DE - Frankfurt'));
      expect(selector['outbounds'], contains('auto'));

      final urltest = outbounds.firstWhere((o) => o['tag'] == 'auto');
      expect(urltest['type'], 'urltest');

      // Experimental
      expect(map['experimental']['clash_api'], isNotNull);
    });

    test('buildFromOutbounds uses hijack-dns and ip_is_private in sing-box 1.14', () {
      final jsonStr = builder.buildFromOutbounds(
        sampleOutbounds,
        bypassLan: true,
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rules = map['route']['rules'] as List;

      expect(rules.any((r) => r['action'] == 'hijack-dns'), isTrue);
      expect(rules.any((r) => r['ip_is_private'] == true), isTrue);
    });

    test('buildFromOutbounds configures AdGuard DNS server correctly', () {
      final jsonStr = builder.buildFromOutbounds(
        sampleOutbounds,
        dnsProvider: DnsProvider.adguard,
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final dnsServers = map['dns']['servers'] as List;

      final remoteUdp = dnsServers.firstWhere((s) => s['tag'] == 'remote-dns');
      expect(remoteUdp['server'], '94.140.14.14');
      expect(remoteUdp['detour'], 'proxy');

      final remoteTcp = dnsServers.firstWhere((s) => s['tag'] == 'remote-dns-tcp');
      expect(remoteTcp['server'], '94.140.14.14');
      expect(remoteTcp['detour'], 'proxy');
    });

    test('patchExistingConfig adds missing tun inbound and clash_api', () {
      final raw = jsonEncode({
        'outbounds': [
          {'type': 'direct', 'tag': 'direct'}
        ]
      });

      final patched = builder.patchExistingConfig(raw);
      final map = jsonDecode(patched) as Map<String, dynamic>;

      final inbounds = map['inbounds'] as List;
      expect(inbounds.any((i) => i['type'] == 'tun'), isTrue);
      expect(map['experimental']['clash_api'], isNotNull);
    });

    test('patchExistingConfig preserves existing tun inbound without duplicates', () {
      final raw = jsonEncode({
        'inbounds': [
          {'type': 'tun', 'tag': 'custom-tun'}
        ],
        'outbounds': []
      });

      final patched = builder.patchExistingConfig(raw);
      final map = jsonDecode(patched) as Map<String, dynamic>;

      final inbounds = map['inbounds'] as List;
      expect(inbounds.length, 1);
      expect(inbounds[0]['tag'], 'custom-tun');
    });

    test('buildFromOutbounds preserves whitelist and LTE backup nodes', () {
      final outbounds = [
        const OutboundRef(
          tag: '🇪🇺 📍БЕЛЫЕ СПИСКИ 1🧿',
          type: 'vless',
          server: '144.31.215.7',
          serverPort: 443,
          rawConfig: {'type': 'vless', 'tag': '🇪🇺 📍БЕЛЫЕ СПИСКИ 1🧿'},
        ),
        const OutboundRef(
          tag: 'LTE(бс) Запасной 1',
          type: 'vless',
          server: '144.31.215.7',
          serverPort: 443,
          rawConfig: {'type': 'vless', 'tag': 'LTE(бс) Запасной 1'},
        ),
        const OutboundRef(
          tag: 'Все сервера находятся в белых списках',
          type: 'freedom',
          server: '127.0.0.1',
          serverPort: 0,
          rawConfig: {'type': 'freedom', 'tag': 'Все сервера находятся в белых списках'},
        ),
      ];

      final jsonStr = builder.buildFromOutbounds(outbounds);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final selector = (map['outbounds'] as List).firstWhere((o) => o['tag'] == 'proxy');
      final proxyOutbounds = selector['outbounds'] as List;

      expect(proxyOutbounds, contains('🇪🇺 📍БЕЛЫЕ СПИСКИ 1🧿'));
      expect(proxyOutbounds, contains('LTE(бс) Запасной 1'));
      expect(proxyOutbounds, isNot(contains('Все сервера находятся в белых списках')));
    });

    test('buildFromOutbounds configures split tunneling in tun, route, and dns', () {
      final jsonStr = builder.buildFromOutbounds(
        sampleOutbounds,
        splitTunnelingEnabled: true,
        bypassedPackages: ['ru.sberbankmobile'],
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final tun = (map['inbounds'] as List).first;
      expect(tun['exclude_package'], contains('ru.sberbankmobile'));

      final routeRules = map['route']['rules'] as List;
      expect(
        routeRules.any((r) =>
            r['package_name'] != null &&
            (r['package_name'] as List).contains('ru.sberbankmobile') &&
            r['outbound'] == 'direct'),
        isTrue,
      );

      final dnsRules = map['dns']['rules'] as List;
      expect(
        dnsRules.any((r) =>
            r['package_name'] != null &&
            (r['package_name'] as List).contains('ru.sberbankmobile') &&
            r['server'] == 'local-dns'),
        isTrue,
      );
    });
  });
}
