import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/subscription/domain/parsers/share_link_parser.dart';

void main() {
  const parser = ShareLinkParser();

  group('ShareLinkParser', () {
    test('parses VLESS with Reality', () {
      const link =
          'vless://b831381d-6324-4d53-ad4f-8cda48b30811@198.51.100.1:443?security=reality&sni=example.com&fp=chrome&pbk=112233445566778899aabbccddeeff0011223344556&sid=12345678&type=tcp&flow=xtls-rprx-vision#NL%20-%20Amsterdam';
      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'vless');
      expect(res.server, '198.51.100.1');
      expect(res.serverPort, 443);
      expect(res.tag, 'NL - Amsterdam');

      final cfg = res.rawConfig;
      expect(cfg['uuid'], 'b831381d-6324-4d53-ad4f-8cda48b30811');
      expect(cfg['flow'], 'xtls-rprx-vision');
      expect(cfg['tls']['reality']['enabled'], isTrue);
      expect(cfg['tls']['reality']['public_key'],
          '112233445566778899aabbccddeeff0011223344556');
    });

    test('parses VMess base64 JSON', () {
      final jsonMap = {
        'v': '2',
        'ps': 'DE - Frankfurt',
        'add': '198.51.100.2',
        'port': '443',
        'id': 'b831381d-6324-4d53-ad4f-8cda48b30812',
        'aid': '0',
        'net': 'ws',
        'tls': 'tls',
        'host': 'de.example.com',
        'path': '/vmess-ws',
      };
      final b64 = base64.encode(utf8.encode(jsonEncode(jsonMap)));
      final link = 'vmess://$b64';

      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'vmess');
      expect(res.tag, 'DE - Frankfurt');
      expect(res.server, '198.51.100.2');
      expect(res.serverPort, 443);
      expect(res.rawConfig['transport']['path'], '/vmess-ws');
    });

    test('parses Trojan', () {
      const link =
          'trojan://my-trojan-pass@198.51.100.3:443?sni=trojan.example.com#FI%20-%20Helsinki';
      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'trojan');
      expect(res.tag, 'FI - Helsinki');
      expect(res.rawConfig['password'], 'my-trojan-pass');
      expect(res.rawConfig['tls']['server_name'], 'trojan.example.com');
    });

    test('parses Shadowsocks (SIP002)', () {
      // chacha20-ietf-poly1305:secret123 -> base64: Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpzZWNyZXQxMjM=
      const userB64 = 'Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpzZWNyZXQxMjM=';
      const link = 'ss://$userB64@198.51.100.4:8388#SE%20-%20Stockholm';

      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'shadowsocks');
      expect(res.tag, 'SE - Stockholm');
      expect(res.rawConfig['method'], 'chacha20-ietf-poly1305');
      expect(res.rawConfig['password'], 'secret123');
      expect(res.serverPort, 8388);
    });

    test('parses Hysteria 2', () {
      const link =
          'hysteria2://my-hy2-pass@198.51.100.5:443?sni=hy2.example.com#KZ%20-%20Almaty';
      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'hysteria2');
      expect(res.tag, 'KZ - Almaty');
      expect(res.rawConfig['password'], 'my-hy2-pass');
    });

    test('parses TUIC', () {
      const link =
          'tuic://b831381d-6324-4d53-ad4f-8cda48b30815:pass123@198.51.100.6:8443?sni=tuic.example.com#US%20-%20New%20York';
      final res = parser.parse(link);
      expect(res, isNotNull);
      expect(res!.type, 'tuic');
      expect(res.tag, 'US - New York');
      expect(res.rawConfig['uuid'], 'b831381d-6324-4d53-ad4f-8cda48b30815');
      expect(res.rawConfig['password'], 'pass123');
    });

    test('handles invalid and broken links gracefully', () {
      expect(parser.parse(''), isNull);
      expect(parser.parse('https://google.com'), isNull);
      expect(parser.parse('vless://invalid-link-without-at'), isNull);
      expect(parser.parse('vmess://not-valid-base-64!!!'), isNull);
    });

    test('parses multi-line content via parseList', () {
      const content = '''
vless://b831381d-6324-4d53-ad4f-8cda48b30811@198.51.100.1:443?security=none#Node1

trojan://pass@198.51.100.2:443#Node2
invalid-line
''';
      final list = parser.parseList(content);
      expect(list.length, 2);
      expect(list[0].tag, 'Node1');
      expect(list[1].tag, 'Node2');
    });
  });
}
