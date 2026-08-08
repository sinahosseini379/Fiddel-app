import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/features/fiddel_tester/model/config_model.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:fiddel/utils/utils.dart';
import 'package:meta/meta.dart';

class ConfigParser {
  static const _allowedProtocols = [
    'vless', 'vmess', 'trojan', 'ss', 'shadowsocks', 'hysteria2', 'hy2', 'hy'
  ];

  static Either<String, List<ProxyConfig>> parseSubscription(String content) {
    try {
      // 1. Try base64 first
      final decoded = _tryDecodeBase64(content);
      if (decoded != null && _hasProtocolPrefix(decoded)) {
        return _parseUris(decoded);
      }

      // 2. Try JSON
      try {
        final json = jsonDecode(content);
        final uris = _extractUrisFromJson(json);
        if (uris.isNotEmpty) {
          return _parseUris(uris.join('\n'));
        }
      } catch (_) {}

      // 3. Plain text URIs
      return _parseUris(content);
    } catch (e) {
      return Left('Failed to parse subscription: $e');
    }
  }

  /// Decodes a raw subscription body into the list of proxy URI strings it
  /// contains, handling the same base64 / JSON / plain-text shapes as
  /// [parseSubscription] but without parsing each URI into a [ProxyConfig].
  static List<String> decodeSubscription(String content) {
    String text = content;

    final decoded = _tryDecodeBase64(content);
    if (decoded != null && _hasProtocolPrefix(decoded)) {
      text = decoded;
    } else {
      try {
        final uris = _extractUrisFromJson(jsonDecode(content));
        if (uris.isNotEmpty) return uris;
      } catch (_) {}
    }

    final seen = <String>{};
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && _hasProtocolPrefix(l) && seen.add(l))
        .toList();
  }

  static String? _tryDecodeBase64(String text) {
    try {
      final t = text.replaceAll(RegExp(r'\s+'), '');
      if (t.isEmpty) return null;
      final padded = t + '=' * (-t.length % 4);
      return utf8.decode(base64.decode(padded), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static bool _hasProtocolPrefix(String text) {
    return _allowedProtocols.any((p) => text.startsWith('$p://'));
  }

  static List<String> _extractUrisFromJson(dynamic json) {
    final uris = <String>[];
    if (json is Map) {
      // sing-box format
      for (final outbound in (json['outbounds'] as List?) ?? const []) {
        final uri = _singboxToUri(outbound as Map);
        if (uri != null) uris.add(uri);
      }
      // Clash format
      for (final proxy in (json['proxies'] as List?) ?? const []) {
        final uri = _clashToUri(proxy as Map);
        if (uri != null) uris.add(uri);
      }
    } else if (json is List) {
      for (final item in json) {
        uris.addAll(_extractUrisFromJson(item));
      }
    }
    return uris;
  }

  static String? _singboxToUri(Map outbound) {
    final type = outbound['type'] as String?;
    final server = outbound['server'] as String?;
    final port = outbound['server_port'] as int? ?? 443;
    if (server == null) return null;
    final tag = Uri.encodeComponent(outbound['tag'] as String? ?? 'config');
    
    switch (type) {
      case 'vless':
        return 'vless://${outbound['uuid']}@$server:$port?type=tcp#$tag';
      case 'shadowsocks':
      case 'ss':
        final ui = base64.encode(utf8.encode('${outbound['method']}:${outbound['password']}'));
        return 'ss://$ui@$server:$port#$tag';
      case 'trojan':
        return 'trojan://${outbound['password']}@$server:$port#$tag';
    }
    return null;
  }

  static String? _clashToUri(Map proxy) {
    final type = proxy['type'] as String?;
    final server = proxy['server'] as String?;
    final port = proxy['port'] as int? ?? 443;
    if (server == null) return null;
    final name = Uri.encodeComponent(proxy['name'] as String? ?? 'config');
    
    switch (type) {
      case 'ss':
        final ui = base64.encode(utf8.encode('${proxy['cipher']}:${proxy['password']}'));
        return 'ss://$ui@$server:$port#$name';
      case 'trojan':
        return 'trojan://${proxy['password']}@$server:$port#$name';
      case 'vless':
      case 'vmess':
        return '$type://${proxy['uuid']}@$server:$port?type=tcp#$name';
    }
    return null;
  }

  static Either<String, List<ProxyConfig>> _parseUris(String text) {
    final lines = text.split('\n');
    final configs = <ProxyConfig>[];
    final seen = <String>{};
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      
      final parsed = _parseUri(trimmed);
      if (parsed != null) {
        configs.add(parsed);
      }
    }
    
    if (configs.isEmpty) {
      return Left('No valid configs found');
    }
    return Right(configs);
  }

  static ProxyConfig? _parseUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      final scheme = parsed.scheme.toLowerCase();
      final fragment = parsed.hasFragment ? Uri.decodeComponent(parsed.fragment.split(' -> ')[0]) : null;
      
      switch (scheme) {
        case 'vless':
          return _parseVless(parsed, fragment);
        case 'vmess':
          return _parseVmess(parsed, fragment);
        case 'trojan':
          return _parseTrojan(parsed, fragment);
        case 'ss':
        case 'shadowsocks':
          return _parseShadowsocks(parsed, fragment);
        case 'hysteria2':
        case 'hy2':
        case 'hy':
          return _parseHysteria2(parsed, fragment);
      }
    } catch (_) {}
    return null;
  }

  static ProxyConfig _parseVless(Uri uri, String? name) {
    final query = uri.queryParameters;
    return ProxyConfig.vless(
      id: uri.userInfo,
      name: name ?? 'VLESS',
      server: uri.host,
      port: uri.port,
      uuid: uri.userInfo,
      flow: query['flow'],
      security: query['security'],
      sni: query['sni'],
      fingerprint: query['fp'],
      publicKey: query['pbk'],
      shortId: query['sid'],
      type: query['type'],
      host: query['host'],
      path: query['path'],
      extra: query['extra'] != null ? jsonDecode(query['extra']!) as Map<String, dynamic>? : null,
    );
  }

  static ProxyConfig _parseVmess(Uri uri, String? name) {
    return ProxyConfig.vmess(
      id: uri.userInfo,
      name: name ?? 'VMess',
      server: uri.host,
      port: uri.port,
      uuid: uri.userInfo,
      security: uri.queryParameters['security'],
      type: uri.queryParameters['type'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
    );
  }

  static ProxyConfig _parseTrojan(Uri uri, String? name) {
    return ProxyConfig.trojan(
      id: uri.userInfo,
      name: name ?? 'Trojan',
      server: uri.host,
      port: uri.port,
      password: uri.userInfo,
      sni: uri.queryParameters['sni'],
      fingerprint: uri.queryParameters['fp'],
      type: uri.queryParameters['type'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
    );
  }

  static ProxyConfig _parseShadowsocks(Uri uri, String? name) {
    // Decode userinfo (base64 of method:password)
    String cipher = 'aes-256-gcm';
    String password = uri.userInfo;
    try {
      final decoded = utf8.decode(base64.decode(uri.userInfo));
      final parts = decoded.split(':');
      if (parts.length >= 2) {
        cipher = parts[0];
        password = parts[1];
      }
    } catch (_) {}
    
    return ProxyConfig.shadowsocks(
      id: uri.userInfo,
      name: name ?? 'Shadowsocks',
      server: uri.host,
      port: uri.port,
      cipher: cipher,
      password: password,
      plugin: uri.queryParameters['plugin'],
    );
  }

  static ProxyConfig _parseHysteria2(Uri uri, String? name) {
    return ProxyConfig.hysteria2(
      id: uri.userInfo,
      name: name ?? 'Hysteria2',
      server: uri.host,
      port: uri.port,
      password: uri.userInfo,
      sni: uri.queryParameters['sni'],
      alpn: uri.queryParameters['alpn'],
      insecure: uri.queryParameters['insecure'] == '1',
    );
  }
}