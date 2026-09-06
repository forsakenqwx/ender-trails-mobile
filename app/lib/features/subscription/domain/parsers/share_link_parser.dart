import 'dart:convert';

import '../entities/outbound_ref.dart';

/// Парсер share-ссылок протоколов (vless, vmess, trojan, shadowsocks, hysteria2, tuic).
///
/// Документация: docs/vpn-core.md §3.
class ShareLinkParser {
  const ShareLinkParser();

  /// Парсит share-ссылку и возвращает [OutboundRef] или `null`, если формат не поддерживается/поврежден.
  OutboundRef? parse(String rawLink) {
    final link = rawLink.trim();
    if (link.isEmpty) return null;

    try {
      if (link.startsWith('vless://')) {
        return _parseVless(link);
      } else if (link.startsWith('vmess://')) {
        return _parseVmess(link);
      } else if (link.startsWith('trojan://')) {
        return _parseTrojan(link);
      } else if (link.startsWith('ss://')) {
        return _parseShadowsocks(link);
      } else if (link.startsWith('hysteria2://') || link.startsWith('hy2://')) {
        return _parseHysteria2(link);
      } else if (link.startsWith('tuic://')) {
        return _parseTuic(link);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Парсинг списка ссылок (построчно или в base64).
  List<OutboundRef> parseList(String rawContent) {
    var content = rawContent.trim();
    if (content.isEmpty) return const [];

    // Если контент закодирован в base64, декодируем его
    if (!content.contains('://')) {
      try {
        final clean = content.replaceAll(RegExp(r'\s+'), '');
        final decoded = utf8.decode(base64Decode(base64.normalize(clean)));
        if (decoded.contains('://')) {
          content = decoded;
        }
      } catch (_) {}
    }

    final lines = content.split(RegExp(r'[\r\n]+'));
    final results = <OutboundRef>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final outbound = parse(trimmed);
      if (outbound != null) {
        results.add(outbound);
      }
    }
    return results;
  }

  // ──── VLESS ────────────────────────────────────────────────────────────────

  OutboundRef? _parseVless(String link) {
    final uri = Uri.parse(link);
    final uuid = uri.userInfo;
    final host = uri.host;
    final port = uri.port;

    if (uuid.isEmpty || host.isEmpty || port <= 0) {
      return null;
    }

    final tag = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';
    final params = uri.queryParameters;

    final security = params['security'] ?? 'none';
    final flow = params['flow'];
    final sni = params['sni'] ?? host;
    final pbk = params['pbk'];
    final sid = params['sid'];
    final fp = params['fp'] ?? 'chrome';
    final type = params['type'] ?? 'tcp';

    final outbound = <String, dynamic>{
      'type': 'vless',
      'tag': tag,
      'server': host,
      'server_port': port,
      'uuid': uuid,
    };

    if (flow != null && flow.isNotEmpty) {
      outbound['flow'] = flow;
    }

    if (security == 'reality') {
      outbound['tls'] = {
        'enabled': true,
        'server_name': sni,
        'reality': {
          'enabled': true,
          'public_key': pbk ?? '',
          'short_id': sid ?? '',
        },
        'utls': {
          'enabled': true,
          'fingerprint': fp,
        },
      };
    } else if (security == 'tls') {
      outbound['tls'] = {
        'enabled': true,
        'server_name': sni,
        'utls': {
          'enabled': true,
          'fingerprint': fp,
        },
      };
    }

    if (type == 'ws') {
      outbound['transport'] = {
        'type': 'ws',
        'path': params['path'] ?? '/',
        if (params['host'] != null) 'headers': {'Host': params['host']},
      };
    } else if (type == 'grpc') {
      outbound['transport'] = {
        'type': 'grpc',
        'service_name': params['serviceName'] ?? '',
      };
    }

    return OutboundRef(
      tag: tag,
      type: 'vless',
      server: host,
      serverPort: port,
      rawConfig: outbound,
    );
  }

  // ──── VMESS ────────────────────────────────────────────────────────────────

  OutboundRef? _parseVmess(String link) {
    final b64 = link.substring('vmess://'.length).trim();
    final normalized = base64.normalize(b64);
    final jsonStr = utf8.decode(base64.decode(normalized));
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    final host = (map['add'] as String?) ?? '';
    final port = int.tryParse(map['port']?.toString() ?? '0') ?? 0;
    final uuid = (map['id'] as String?) ?? '';

    if (uuid.isEmpty || host.isEmpty || port <= 0) {
      return null;
    }

    final tag = (map['ps'] as String?)?.isNotEmpty == true
        ? map['ps'] as String
        : '$host:$port';
    final alterId = int.tryParse(map['aid']?.toString() ?? '0') ?? 0;
    final net = (map['net'] as String?) ?? 'tcp';
    final tls = (map['tls'] as String?) ?? 'none';
    final sni = (map['sni'] as String?) ?? (map['host'] as String?) ?? host;

    final outbound = <String, dynamic>{
      'type': 'vmess',
      'tag': tag,
      'server': host,
      'server_port': port,
      'uuid': uuid,
      'alter_id': alterId,
      'security': 'auto',
    };

    if (tls == 'tls') {
      outbound['tls'] = {
        'enabled': true,
        'server_name': sni,
      };
    }

    if (net == 'ws') {
      outbound['transport'] = {
        'type': 'ws',
        'path': map['path'] ?? '/',
        if (map['host'] != null) 'headers': {'Host': map['host']},
      };
    }

    return OutboundRef(
      tag: tag,
      type: 'vmess',
      server: host,
      serverPort: port,
      rawConfig: outbound,
    );
  }

  // ──── TROJAN ───────────────────────────────────────────────────────────────

  OutboundRef? _parseTrojan(String link) {
    final uri = Uri.parse(link);
    final password = uri.userInfo;
    final host = uri.host;
    final port = uri.port;

    if (password.isEmpty || host.isEmpty || port <= 0) {
      return null;
    }

    final tag = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';
    final params = uri.queryParameters;
    final sni = params['sni'] ?? host;

    final outbound = <String, dynamic>{
      'type': 'trojan',
      'tag': tag,
      'server': host,
      'server_port': port,
      'password': password,
      'tls': {
        'enabled': true,
        'server_name': sni,
      },
    };

    return OutboundRef(
      tag: tag,
      type: 'trojan',
      server: host,
      serverPort: port,
      rawConfig: outbound,
    );
  }

  // ──── SHADOWSOCKS ──────────────────────────────────────────────────────────

  OutboundRef? _parseShadowsocks(String link) {
    final raw = link.substring('ss://'.length);
    final hashIdx = raw.indexOf('#');
    final fragment = hashIdx != -1 ? raw.substring(hashIdx + 1) : '';
    final body = hashIdx != -1 ? raw.substring(0, hashIdx) : raw;
    final tag = fragment.isNotEmpty
        ? Uri.decodeComponent(fragment)
        : 'Shadowsocks';

    String method;
    String password;
    String server;
    int port;

    if (body.contains('@')) {
      // SIP002 format: base64(method:password)@server:port
      final parts = body.split('@');
      final userPart = parts[0];
      final serverPart = parts[1];

      final decodedUser =
          utf8.decode(base64.decode(base64.normalize(userPart)));
      final upParts = decodedUser.split(':');
      method = upParts[0];
      password = upParts.sublist(1).join(':');

      final sParts = serverPart.split(':');
      server = sParts[0];
      port = int.tryParse(sParts.length > 1 ? sParts[1] : '0') ?? 0;
    } else {
      // Legacy format: base64(method:password@server:port)
      final decoded = utf8.decode(base64.decode(base64.normalize(body)));
      final atParts = decoded.split('@');
      if (atParts.length < 2) return null;

      final upParts = atParts[0].split(':');
      method = upParts[0];
      password = upParts.sublist(1).join(':');

      final sParts = atParts[1].split(':');
      server = sParts[0];
      port = int.tryParse(sParts.length > 1 ? sParts[1] : '0') ?? 0;
    }

    if (server.isEmpty || port <= 0 || method.isEmpty) {
      return null;
    }

    final outbound = <String, dynamic>{
      'type': 'shadowsocks',
      'tag': tag,
      'server': server,
      'server_port': port,
      'method': method,
      'password': password,
    };

    return OutboundRef(
      tag: tag,
      type: 'shadowsocks',
      server: server,
      serverPort: port,
      rawConfig: outbound,
    );
  }

  // ──── HYSTERIA 2 ───────────────────────────────────────────────────────────

  OutboundRef? _parseHysteria2(String link) {
    final prefix = link.startsWith('hysteria2://') ? 'hysteria2://' : 'hy2://';
    final uri = Uri.parse('hysteria2://${link.substring(prefix.length)}');
    final password = uri.userInfo;
    final host = uri.host;
    final port = uri.port == 0 ? 443 : uri.port;

    if (host.isEmpty || port <= 0) {
      return null;
    }

    final tag = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';
    final params = uri.queryParameters;
    final sni = params['sni'] ?? host;

    final outbound = <String, dynamic>{
      'type': 'hysteria2',
      'tag': tag,
      'server': host,
      'server_port': port,
      if (password.isNotEmpty) 'password': password,
      'tls': {
        'enabled': true,
        'server_name': sni,
      },
    };

    return OutboundRef(
      tag: tag,
      type: 'hysteria2',
      server: host,
      serverPort: port,
      rawConfig: outbound,
    );
  }

  // ──── TUIC ─────────────────────────────────────────────────────────────────

  OutboundRef? _parseTuic(String link) {
    final uri = Uri.parse(link);
    final userParts = uri.userInfo.split(':');
    final uuid = userParts[0];
    final password = userParts.length > 1 ? userParts[1] : '';
    final host = uri.host;
    final port = uri.port;

    if (uuid.isEmpty || host.isEmpty || port <= 0) {
      return null;
    }

    final tag = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '$host:$port';
    final params = uri.queryParameters;
    final sni = params['sni'] ?? host;
    final cc = params['congestion_control'] ?? 'bbr';

    final outbound = <String, dynamic>{
      'type': 'tuic',
      'tag': tag,
      'server': host,
      'server_port': port,
      'uuid': uuid,
      'password': password,
      'congestion_control': cc,
      'tls': {
        'enabled': true,
        'server_name': sni,
      },
    };

    return OutboundRef(
      tag: tag,
      type: 'tuic',
      server: host,
      serverPort: port,
      rawConfig: outbound,
    );
  }
}
