import 'dart:async';
import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:fiddel/features/profile/data/profile_parser.dart';
import 'package:fiddel/features/fiddel_subscription/model/fiddel_config.dart';
import 'package:fiddel/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

class FiddelSubscriptionFetcher {
  final DioHttpClient _httpClient;
  final Ref _ref;

  FiddelSubscriptionFetcher({required Ref ref, required DioHttpClient httpClient})
    : _ref = ref,
      _httpClient = httpClient;

  static const String _fiddelSubscriptionUrl = 
      'https://raw.githubusercontent.com/sinahosseini379/VPN-Subscription-Tester-USA/main/felfelconfig.txt';
  
  static const String _fiddelMetaUrl = 
      'https://raw.githubusercontent.com/sinahosseini379/VPN-Subscription-Tester-USA/main/felfelconfig.txt.meta.json';

  /// Fetch and decode the base64 subscription
  TaskEither<String, List<String>> fetchSubscription() {
    return TaskEither.tryCatch(() async {
      final response = await _httpClient.get(
        _fiddelSubscriptionUrl,
        cancelToken: CancelToken(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch subscription: ${response.statusCode}');
      }
      
      final base64Content = response.data.toString().trim();
      if (base64Content.isEmpty) {
        throw Exception('Empty subscription content');
      }
      
      // Decode base64
      final decoded = base64Decode(base64Content);
      final content = utf8.decode(decoded);
      
      // Parse URIs
      final uris = content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      return uris;
    }, (err, st) => 'Failed to fetch subscription: $err');
  }

  /// Fetch metadata JSON
  TaskEither<String, FiddelSubscriptionMetadata> fetchMetadata() {
    return TaskEither.tryCatch(() async {
      final response = await _httpClient.get(
        _fiddelMetaUrl,
        cancelToken: CancelToken(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch metadata: ${response.statusCode}');
      }
      
      final json = response.data as Map<String, dynamic>;
      return FiddelSubscriptionMetadata.fromJson(json);
    }, (err, st) => 'Failed to fetch metadata: $err');
  }

  /// Parse subscription URIs into FiddelConfig objects
  Either<String, List<FiddelConfig>> parseSubscription(List<String> uris) {
    try {
      final configs = <FiddelConfig>[];
      
      for (final uri in uris) {
        final parsed = _parseUri(uri);
        if (parsed != null) {
          configs.add(parsed);
        }
      }
      
      return Right(configs);
    } catch (e, st) {
      return Left('Failed to parse subscription: $e\n$st');
    }
  }

  @visibleForTesting
  FiddelConfig? _parseUri(String uri) {
    try {
      final parsed = ProfileParser.parseUri(uri);
      if (parsed == null) return null;
      
      final stealth = ProfileParser.extractStealthInfo(parsed);
      
      // Extract country from URI fragment/name
      String country = 'US';
      String countryName = 'United States';
      String flag = '🇺🇸';
      
      // Try to parse index from name
      int index = 0;
      final nameParts = parsed.name.split('|');
      if (nameParts.length > 1) {
        final numPart = nameParts[1].trim();
        index = int.tryParse(numPart.replaceAll(RegExp(r'\D'), '')) ?? 0;
      }
      
      return FiddelConfig(
        uri: uri,
        name: parsed.name,
        protocol: parsed.protocol,
        transport: stealth['transport'] as String,
        security: stealth['security'] as String,
        fingerprint: stealth['fingerprint'] as String,
        country: country,
        countryName: countryName,
        flag: flag,
        index: index,
        stealthScore: (stealth['stealth_score'] as num).toDouble(),
        avgLatency: 0,
        errorRate: 0,
        samples: 0,
        perTarget: {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch, parse and return full metadata with configs
  TaskEither<String, FiddelSubscriptionMetadata> fetchAndParse() async {
    // Try to get metadata first (has pre-tested configs with latency/error rates)
    final metaResult = await fetchMetadata().run();
    
    if (metaResult is Right) {
      return Right(metaResult.value);
    }
    
    // Fallback: fetch subscription and parse manually
    final subResult = await fetchSubscription().run();
    if (subResult is Left) {
      return Left(subResult.value);
    }
    
    final parseResult = parseSubscription(subResult.value);
    if (parseResult is Left) {
      return Left(parseResult.value);
    }
    
    // Build minimal metadata
    return Right(FiddelSubscriptionMetadata(
      version: '1.0.0',
      generatedAt: DateTime.now().toIso8601String(),
      count: parseResult.value.length,
      avgLatencyMs: 0,
      avgErrorRate: 0,
      byCountry: {'US': parseResult.value.length},
      targets: [
        FiddelTestTarget(label: 'Google', url: 'http://www.gstatic.com/generate_204', weight: 1.0),
        FiddelTestTarget(label: 'YouTube', url: 'https://www.youtube.com/generate_204', weight: 1.0),
        FiddelTestTarget(label: 'Cloudflare', url: 'http://cp.cloudflare.com/', weight: 1.0),
        FiddelTestTarget(label: 'X.com', url: 'https://x.com/', weight: 1.0),
      ],
      items: parseResult.value,
    ));
  }
}