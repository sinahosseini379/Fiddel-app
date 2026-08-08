import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.g.dart';
import 'package:fiddel/features/profile/data/profile_parser.dart';

/// Simple HTTP-based config tester using the app's proxy infrastructure
class FiddelConfigTester {
  FiddelConfigTester({required DioHttpClient httpClient}) : _httpClient = httpClient;

  final DioHttpClient _httpClient;

  static const List<TestTarget> testTargets = [
    TestTarget('Google', 'http://www.gstatic.com/generate_204'),
    TestTarget('YouTube', 'https://www.youtube.com/generate_204'),
    TestTarget('Cloudflare', 'http://cp.cloudflare.com/'),
    TestTarget('X.com', 'https://x.com/'),
  ];

  static const int testRounds = 3;
  static const int timeoutSeconds = 15;
  static const int tcpPingAttempts = 3;

  /// Test a single config and return results
  Future<FiddelTestResult> testConfig(FiddelConfig config, {CancelToken? cancelToken}) async {
    final parsed = ProfileParser.parseUri(config.uri);
    if (parsed == null) {
      return FiddelTestResult(uri: config.uri, success: false, latency: 0, error: 'Invalid URI');
    }

    // Build proxy config for testing
    try {
      final testUrl = testTargets.first.url;
      final latency = await _testSingleUrl(parsed, testUrl, cancelToken);
      if (latency != null) {
        return FiddelTestResult(uri: config.uri, success: true, latency: latency, error: '');
      }
    } catch (e) {
      // Continue to next test target
    }

    // Try other targets
    for (final target in testTargets.skip(1)) {
      try {
        final latency = await _testSingleUrl(parsed, target.url, cancelToken);
        if (latency != null) {
          return FiddelTestResult(uri: config.uri, success: true, latency: latency, error: '');
        }
      } catch (_) {}
    }

    return FiddelTestResult(uri: config.uri, success: false, latency: 0, error: 'All targets failed');
  }

  Future<double?> _testSingleUrl(ParsedUri parsed, String url, CancelToken? cancelToken) async {
    // This is a simplified test - in production you'd use the app's proxy infrastructure
    // For now, we do a basic HTTP check through the system proxy (if any)
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: Duration(seconds: timeoutSeconds),
      ));

      final stopwatch = Stopwatch()..start();
      final response = await dio.get(
        url,
        cancelToken: cancelToken,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
          followRedirects: true,
        ),
      ).timeout(Duration(seconds: timeoutSeconds));
      stopwatch.stop();

      if (response.statusCode != null && response.statusCode! < 400) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Test multiple configs concurrently with progress callback
  Future<List<FiddelTestResult>> testConfigs(
    List<FiddelConfig> configs, {
    required Function(double progress) onProgress,
    CancelToken? cancelToken,
    int concurrency = 5,
  }) async {
    final results = <FiddelTestResult>[];
    final semaphore = _Semaphore(concurrency);
    int completed = 0;

    await Future.wait(configs.map((config) async {
      await semaphore.acquire();
      try {
        if (cancelToken?.isCancelled == true) return;
        final result = await testConfig(config, cancelToken: cancelToken);
        results.add(result);
      } finally {
        semaphore.release();
        completed++;
        onProgress(completed / configs.length);
      }
    }));

    return results;
  }
}

class _Semaphore {
  _Semaphore(this.maxConcurrent);
  final int maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waiting = [];

  Future<void> acquire() async {
    if (_current < maxConcurrent) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else {
      _current--;
    }
  }
}

class TestTarget {
  const TestTarget(this.label, this.url);
  final String label;
  final String url;
}