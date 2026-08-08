import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/features/fiddel_tester/model/config_model.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:meta/meta.dart';

class UrlTester {
  static const _defaultTargets = [
    TestTarget(label: 'Google', url: 'http://www.gstatic.com/generate_204', weight: 1.0),
    TestTarget(label: 'YouTube', url: 'https://www.youtube.com/generate_204', weight: 1.0),
    TestTarget(label: 'Cloudflare', url: 'http://cp.cloudflare.com/', weight: 1.0),
    TestTarget(label: 'X.com', url: 'https://x.com/', weight: 1.0),
  ];

  final Dio _dio;
  final List<TestTarget> _targets;
  final Duration _connectTimeout;
  final Duration _requestTimeout;

  UrlTester({
    Dio? dio,
    List<TestTarget>? targets,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _dio = dio ?? Dio(),
       _targets = targets ?? _defaultTargets,
       _connectTimeout = connectTimeout,
       _requestTimeout = requestTimeout {
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = requestTimeout;
    _dio.options.sendTimeout = requestTimeout;
  }

  Future<TestResult> testConfig({
    required ProxyConfig config,
    required String socksProxy,
    int rounds = 5,
  }) async {
    final targetStats = <String, TargetStat>{};
    final allLatencies = <int>[];
    int totalTests = 0;
    int passedTests = 0;

    // Initialize target stats
    for (final target in _targets) {
      targetStats[target.label] = TargetStat(success: 0, fail: 0, latencies: []);
    }

    for (int round = 0; round < rounds; round++) {
      for (final target in _targets) {
        final result = await _testSingleTarget(config, socksProxy, target);
        totalTests++;
        
        if (result != null) {
          passedTests++;
          allLatencies.add(result);
          targetStats[target.label] = targetStats[target.label]!.copyWith(
            success: targetStats[target.label]!.success + 1,
            latencies: [...targetStats[target.label]!.latencies, result],
          );
        } else {
          targetStats[target.label] = targetStats[target.label]!.copyWith(
            fail: targetStats[target.label]!.fail + 1,
          );
        }
      }
    }

    // Extract stealth info
    final stealthInfo = _extractStealthInfo(config);

    return TestResult(
      configId: config.id,
      configName: config.displayName,
      country: '', // Will be filled by GeoIP
      countryName: '',
      flag: '',
      protocol: config.scheme,
      transport: stealthInfo['transport'] as String? ?? '',
      security: stealthInfo['security'] as String? ?? '',
      stealthScore: stealthInfo['stealthScore'] as double? ?? 0.0,
      targetStats: targetStats,
      allLatencies: allLatencies,
      totalTests: totalTests,
      passedTests: passedTests,
    );
  }

  Future<int?> _testSingleTarget(ProxyConfig config, String socksProxy, TestTarget target) async {
    try {
      final proxyDio = Dio(BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _requestTimeout,
        sendTimeout: _requestTimeout,
      ));
      proxyDio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..findProxy = ((_) => 'PROXY $socksProxy')
          ..badCertificateCallback = ((_, __, ___) => true),
      );

      final stopwatch = Stopwatch()..start();
      final response = await proxyDio.get(
        target.url,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
          followRedirects: true,
        ),
      );
      stopwatch.stop();

      if (response.statusCode != null && response.statusCode! < 400) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _extractStealthInfo(ProxyConfig config) {
    final transport = config.map(
      vless: (c) => c.type ?? 'tcp',
      vmess: (c) => c.type ?? 'tcp',
      trojan: (c) => c.type ?? 'tcp',
      shadowsocks: (_) => 'tcp',
      hysteria2: (_) => 'hysteria2',
    );

    final security = config.map(
      vless: (c) => c.security ?? 'none',
      vmess: (c) => c.security ?? 'none',
      trojan: (_) => 'tls',
      shadowsocks: (_) => 'none',
      hysteria2: (_) => 'tls',
    );

    final fingerprint = config.map(
      vless: (c) => c.fingerprint ?? 'chrome',
      vmess: (_) => 'chrome',
      trojan: (c) => c.fingerprint ?? 'chrome',
      shadowsocks: (_) => 'none',
      hysteria2: (_) => 'none',
    );

    // Calculate stealth score based on protocol/transport/security
    double score = 0.0;
    
    // Security scoring
    switch (security) {
      case 'reality': score += 0.4; break;
      case 'tls': score += 0.3; break;
      case 'none': score += 0.0; break;
    }
    
    // Transport scoring
    switch (transport) {
      case 'ws': score += 0.2; break;
      case 'grpc': score += 0.15; break;
      case 'http': score += 0.1; break;
      case 'xhttp': score += 0.25; break;
      default: score += 0.05;
    }
    
    // Fingerprint scoring
    if (fingerprint == 'chrome' || fingerprint == 'firefox' || fingerprint == 'safari') {
      score += 0.2;
    } else if (fingerprint != 'none') {
      score += 0.1;
    }

    // Port bonus
    final port = config.port;
    if (port == 443 || port == 8443 || port == 2053 || port == 2083 || port == 2087 || port == 2096 || port == 8443) {
      score += 0.15;
    }

    return {
      'transport': transport,
      'security': security,
      'fingerprint': fingerprint,
      'stealthScore': score.clamp(0.0, 1.0),
    };
  }
}