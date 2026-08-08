import 'dart:convert';
import 'dart:typed_data';

import 'package:dartx/dartx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';
import 'package:fiddel/features/profile/data/profile_parser.dart';
import 'package:fiddel/singbox/model/singbox_proxy_type.dart';
import 'package:fiddel/utils/utils.dart';

class FiddelSubscriptionParser {
  static const List<String> supportedSchemes = [
    'vmess',
    'vless',
    'trojan',
    'ss',
    'ssconf',
    'tuic',
    'hy2',
    'hysteria2',
    'hy',
    'hysteria',
    'ssh',
    'wg',
    'awg',
    'shadowtls',
    'mieru',
    'warp',
  ];

  /// Parse raw subscription content (base64 / plain text / JSON) into URIs
  static Either<String, List<String>> parseSubscription(String content) {
    try {
      // 1) Try base64 first
      final decoded = _tryBase64Decode(content);
      if (decoded != null) {
        final uris = _uniqueLines(decoded);
        if (uris.isNotEmpty) return Right(uris);
      }

      // 2) Try JSON (sing-box / Clash)
      final jsonUris = _tryParseJson(content);
      if (jsonUris.isNotEmpty) return Right(jsonUris);

      // 3) Plain text lines
      final plainUris = _uniqueLines(content);
      if (plainUris.isNotEmpty) return Right(plainUris);

      return const Left('No valid configs found in subscription');
    } catch (e) {
      return Left('Parse error: $e');
    }
  }

  static String? _tryBase64Decode(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleaned.isEmpty) return null;

    for (final decoder in [base64, base64Url]) {
      try {
        final padded = cleaned + '=' * ((4 - cleaned.length % 4) % 4);
        final bytes = decoder.decode(padded);
        final str = utf8.decode(bytes, allowMalformed: true);
        if (supportedSchemes.any((s) => str.startsWith('$s://'))) {
          return str;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static List<String> _tryParseJson(String text) {
    try {
      final obj = jsonDecode(text);
      final uris = <String>[];
      _extractJsonUris(obj, uris);
      return _uniqueLines(uris.join('\n'));
    } catch (_) {
      return [];
    }
  }

  static void _extractJsonUris(dynamic obj, List<String> uris) {
    if (obj is Map) {
      for (final out in (obj['outbounds'] as List? ?? [])) {
        final uri = ProfileParser.singboxOutboundToUri(out);
        if (uri != null) uris.add(uri);
      }
      for (final proxy in (obj['proxies'] as List? ?? [])) {
        final uri = ProfileParser.clashProxyToUri(proxy);
        if (uri != null) uris.add(uri);
      }
      for (final nested in (obj['proxies'] as List? ?? []) + (obj['configs'] as List? ?? [])) {
        if (nested is String) uris.add(nested);
      }
    } else if (obj is List) {
      for (final item in obj) {
        _extractJsonUris(item, uris);
      }
    }
  }

  static List<String> _uniqueLines(String text) {
    final seen = <String>{};
    final out = <String>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed) && _isValidUri(trimmed)) {
        out.add(trimmed);
      }
    }
    return out;
  }

  static bool _isValidUri(String uri) {
    try {
      final u = Uri.parse(uri);
      return u.hasScheme && supportedSchemes.contains(u.scheme.toLowerCase()) && u.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Convert parsed URIs to FiddelConfig objects with stealth info
  static List<FiddelConfig> urisToConfigs(List<String> uris) {
    final configs = <FiddelConfig>[];
    for (final uri in uris) {
      final parsed = ProfileParser.parseUri(uri);
      if (parsed == null) continue;

      final stealth = ProfileParser.extractStealthInfo(parsed);
      configs.add(
        FiddelConfig(
          uri: uri,
          name: parsed.name,
          protocol: parsed.protocol,
          server: parsed.server,
          port: parsed.port,
          transport: stealth['transport'] as String,
          security: stealth['security'] as String,
          fingerprint: stealth['fingerprint'] as String,
          stealthScore: (stealth['stealth_score'] as num).toDouble(),
        ),
      );
    }
    return configs;
  }

  /// Filter by country using geoip (simplified - real impl uses SOCKS proxy)
  static Future<List<FiddelConfig>> filterByCountry(
    List<FiddelConfig> configs,
    String targetCountry,
    Future<String?> Function(String server) getCountry,
  ) async {
    final filtered = <FiddelConfig>[];
    for (final config in configs) {
      final country = await getCountry(config.server);
      if (country == targetCountry) {
        filtered.add(config.copyWith(country: country, countryName: _countryName(country), flag: _countryFlag(country)));
      }
    }
    return filtered;
  }

  static String _countryName(String code) {
    const names = {
      'US': 'United States',
      'DE': 'Germany',
      'FI': 'Finland',
      'NL': 'Netherlands',
      'GB': 'United Kingdom',
      'TR': 'Turkey',
    };
    return names[code] ?? code;
  }

  static String _countryFlag(String code) {
    const flags = {
      'US': '🇺🇸',
      'DE': '🇩🇪',
      'FI': '🇫🇮',
      'NL': '🇳🇱',
      'GB': '🇬🇧',
      'TR': '🇹🇷',
    };
    return flags[code] ?? '🏳️';
  }
}