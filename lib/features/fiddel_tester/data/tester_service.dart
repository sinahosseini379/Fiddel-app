import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/features/fiddel_tester/data/config_parser.dart';
import 'package:fiddel/features/fiddel_tester/data/geoip_checker.dart';
import 'package:fiddel/features/fiddel_tester/data/tcp_tester.dart';
import 'package:fiddel/features/fiddel_tester/data/url_tester.dart';
import 'package:fiddel/features/fiddel_tester/model/config_model.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

class FiddelTesterService {
  final ConfigParser _parser;
  final TcpTester _tcpTester;
  final UrlTester _urlTester;
  final GeoIpChecker _geoIp;

  FiddelTesterService({
    ConfigParser? parser,
    TcpTester? tcpTester,
    UrlTester? urlTester,
    GeoIpChecker? geoIp,
  }) : _parser = parser ?? ConfigParser(),
       _tcpTester = tcpTester ?? TcpTester(),
       _urlTester = urlTester ?? UrlTester(),
       _geoIp = geoIp ?? GeoIpChecker();

  Future<Either<String, TestRunResult>> runFullTest({
    required List<SubscriptionSource> subscriptions,
    required TesterSettings settings,
    required String socksProxyBase,
    Function(TestProgress)? onProgress,
  }) async {
    onProgress?.call(TestProgress.downloading('Downloading subscriptions...'));

    // 1. Download and parse all subscriptions
    final allConfigs = <ProxyConfig>[];
    final seen = <String>{};
    
    for (final sub in subscriptions.where((s) => s.enabled)) {
      try {
        // In real implementation, this would download from URL
        // For now, we'll use a mock or the user would provide content
        onProgress?.call(TestProgress.downloading('Parsing ${sub.name}...'));
        
        // Mock: assume we have the content
        // final content = await _download(sub.url);
        // final parsed = _parser.parseSubscription(content);
        // if (parsed.isRight()) {
        //   for (final c in parsed.getRight()) {
        //     if (seen.add(c.id)) allConfigs.add(c);
        //   }
        // }
      } catch (_) {}
    }

    if (allConfigs.isEmpty) {
      return Left('No configs found in subscriptions');
    }

    // Limit configs
    final limitedConfigs = allConfigs.take(settings.maxConfigs).toList();

    onProgress?.call(TestProgress.tcpFilter('TCP filtering ${limitedConfigs.length} configs...'));

    // 2. TCP Filter
    final tcpPassed = await _tcpTester.filterByTcp(
      configs: limitedConfigs,
      minSuccess: settings.tcpPingMinSuccess,
      tries: settings.tcpPingTries,
      concurrency: settings.tcpConcurrency,
    );

    if (tcpPassed.isEmpty) {
      return Left('All configs failed TCP test');
    }

    onProgress?.call(TestProgress.countryFilter('Checking countries for ${tcpPassed.length} configs...'));

    // 3. Country Filter
    final allowedCountries = settings.allowedCountries.isNotEmpty 
        ? settings.allowedCountries.toSet() 
        : {'US'};
    
    final countryPassed = <ProxyConfig>[];
    for (int i = 0; i < tcpPassed.length; i++) {
      final config = tcpPassed.elementAt(i);
      onProgress?.call(TestProgress.countryFilter(
        'Checking country ${i + 1}/${tcpPassed.length}...',
        i / tcpPassed.length,
      ));
      
      final socksPort = 20000 + i;
      final socksProxy = 'socks5://127.0.0.1:$socksPort';
      final country = await _geoIp.getCountry(socksProxy);
      
      if (country != null && allowedCountries.contains(country.toUpperCase())) {
        countryPassed.add(config);
      }
    }

    if (countryPassed.isEmpty) {
      return Left('No configs from allowed countries');
    }

    onProgress?.call(TestProgress.urlTesting('URL testing ${countryPassed.length} configs...'));

    // 4. URL Tests
    final results = <TestResult>[];
    for (int i = 0; i < countryPassed.length; i++) {
      final config = countryPassed.elementAt(i);
      onProgress?.call(TestProgress.urlTesting(
        'Testing ${i + 1}/${countryPassed.length}: ${config.displayName}',
        i / countryPassed.length,
      ));
      
      final socksPort = 20000 + i;
      final socksProxy = 'socks5://127.0.0.1:$socksPort';
      
      // In real implementation, launch core process for each config
      // For now, mock result
      final result = await _urlTester.testConfig(
        config: config,
        socksProxy: socksProxy,
        rounds: settings.urlTestRounds,
      );
      
      // Fill country info
      final countryInfo = GeoIpChecker.getCountryInfo(result.country);
      results.add(result.copyWith(
        country: result.country,
        countryName: countryInfo.$1,
        flag: countryInfo.$2,
      ));
    }

    onProgress?.call(TestProgress.selecting('Selecting best ${settings.configsPerCountry} configs...'));

    // 5. Select top configs
    final selected = _selectTop(results, settings);

    onProgress?.call(TestProgress.completed('Test completed! ${selected.length} configs selected.'));

    return Right(TestRunResult(
      allResults: results,
      selectedConfigs: selected,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  List<TestResult> _selectTop(List<TestResult> results, TesterSettings settings) {
    final weights = {for (final t in settings.testUrls) t.label: t.weight};
    
    // Filter by error rate
    final filtered = results.where((r) => r.weightedErrorRate <= settings.maxErrorRate).toList();
    
    // Sort by: error rate (asc), stealth score (desc), avg latency (asc)
    filtered.sort((a, b) {
      final errCmp = a.weightedErrorRate.compareTo(b.weightedErrorRate);
      if (errCmp != 0) return errCmp;
      
      final stealthCmp = (-a.stealthScore).compareTo(-b.stealthScore);
      if (stealthCmp != 0) return stealthCmp;
      
      return a.avgLatency.compareTo(b.avgLatency);
    });
    
    // Group by country and take top N per country
    final byCountry = groupBy(filtered, (TestResult r) => r.country);
    final selected = <TestResult>[];
    
    for (final country in settings.allowedCountries) {
      final countryResults = byCountry[country] ?? [];
      selected.addAll(countryResults.take(settings.configsPerCountry));
    }
    
    return selected;
  }
}

class TestRunResult {
  final List<TestResult> allResults;
  final List<TestResult> selectedConfigs;
  final int timestamp;

  TestRunResult({
    required this.allResults,
    required this.selectedConfigs,
    required this.timestamp,
  });
}

class TestProgress {
  final String stage;
  final String message;
  final double progress; // 0.0 to 1.0

  TestProgress(this.stage, this.message, [this.progress = 0.0]);

  static TestProgress downloading(String msg, [double p = 0.0]) => TestProgress('download', msg, p);
  static TestProgress tcpFilter(String msg, [double p = 0.0]) => TestProgress('tcp', msg, p);
  static TestProgress countryFilter(String msg, [double p = 0.0]) => TestProgress('country', msg, p);
  static TestProgress urlTesting(String msg, [double p = 0.0]) => TestProgress('url', msg, p);
  static TestProgress selecting(String msg, [double p = 0.0]) => TestProgress('select', msg, p);
  static TestProgress completed(String msg) => TestProgress('done', msg, 1.0);
}