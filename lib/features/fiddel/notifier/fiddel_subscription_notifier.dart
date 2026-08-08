import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:fiddel/features/fiddel/data/fiddel_config_tester.dart';
import 'package:fiddel/features/fiddel/data/fiddel_subscription_fetcher.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.g.dart';
import 'package:fiddel/features/profile/data/profile_parser.dart';
import 'package:fiddel/features/profile/data/profile_repository.dart';
import 'package:fiddel/features/profile/model/profile_entity.dart';
import 'package:fiddel/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:fiddel/core/http_client/http_client_provider.dart';
import 'package:fiddel/features/profile/data/profile_data_providers.dart';

part 'fiddel_subscription_notifier.g.dart';

@Riverpod(keepAlive: true)
class FiddelSubscriptionNotifier extends _$FiddelSubscriptionNotifier {
  @override
  FiddelSubscriptionState build() {
    return const FiddelSubscriptionState();
  }

  /// Fetch, test, and select best configs from Fiddel USA subscription
  Future<void> fetchAndTestBest({
    String? customUrl,
    int maxConfigs = 8,
    CancelToken? cancelToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null, progress: 0);
    final fetcher = FiddelSubscriptionFetcher(httpClient: ref.read(httpClientProvider));
    final tester = FiddelConfigTester(httpClient: ref.read(httpClientProvider));

    try {
      // Step 1: Fetch subscription
      state = state.copyWith(isLoading: true, progress: 0.1);
      final fetchResult = await fetcher.fetchAndParse(customUrl: customUrl, cancelToken: cancelToken);

      final configs = fetchResult.fold(
        (error) => throw Exception(error),
        (configs) => configs,
      );

      if (configs.isEmpty) {
        throw Exception('No valid configs found');
      }

      state = state.copyWith(
        configs: configs,
        isLoading: false,
        isTesting: true,
        progress: 0.2,
        totalTested: 0,
        totalPassed: 0,
      );

      // Step 2: Test configs
      final testResults = await tester.testConfigs(
        configs,
        cancelToken: cancelToken,
        concurrency: 5,
        onProgress: (progress) {
          state = state.copyWith(
            progress: 0.2 + (progress * 0.6),
            totalTested: (configs.length * progress).round(),
          );
        },
      );

      final passedConfigs = testResults.where((r) => r.success).toList();
      state = state.copyWith(
        totalTested: testResults.length,
        totalPassed: passedConfigs.length,
        progress: 0.8,
      );

      // Step 3: Select best configs (sort by latency)
      final bestConfigs = _selectBestConfigs(configs, passedConfigs, maxConfigs);
      state = state.copyWith(
        bestConfigs: bestConfigs,
        isTesting: false,
        progress: 1.0,
        lastUpdate: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isTesting: false,
        error: e.toString(),
        progress: 0,
      );
    }
  }

  /// Add selected configs as profiles in the app
  Future<void> addBestConfigsAsProfiles() async {
    if (state.bestConfigs.isEmpty) return;

    final parser = ProfileParser(
      ref: ref,
      httpClient: ref.read(httpClientProvider),
    );
    final repo = ref.read(profileRepositoryProvider);

    for (int i = 0; i < state.bestConfigs.length; i++) {
      final config = state.bestConfigs[i];
      final id = 'fiddel_${DateTime.now().millisecondsSinceEpoch}_$i';

      final result = await parser.addRemote(
        id: id,
        url: config.uri,
        tempFilePath: '${PlatformUtils.tempDir}/fiddel_$i.txt',
        userOverride: null,
      ).run();

      result.fold(
        (failure) => Logger.e('Failed to add Fiddel config: $failure'),
        (entry) async => await repo.insert(entry),
      );
    }

    // Refresh profile list
    ref.invalidate(profilesProvider);
  }

  List<FiddelConfig> _selectBestConfigs(
    List<FiddelConfig> allConfigs,
    List<FiddelTestResult> passedResults,
    int maxConfigs,
  ) {
    final passedUris = passedResults.where((r) => r.success).map((r) => r.uri).toSet();
    final passedConfigs = allConfigs.where((c) => passedUris.contains(c.uri)).toList();

    // Sort by latency (ascending), then by stealth score (descending)
    passedConfigs.sort((a, b) {
      final latA = passedResults.firstWhere((r) => r.uri == a.uri).latency;
      final latB = passedResults.firstWhere((r) => r.uri == b.uri).latency;
      if (latA != latB) return latA.compareTo(latB);
      return b.stealthScore.compareTo(a.stealthScore);
    });

    // Take top N and assign indices
    final selected = passedConfigs.take(maxConfigs).toList();
    for (int i = 0; i < selected.length; i++) {
      selected[i] = selected[i].copyWith(index: i + 1);
    }
    return selected;
  }

  void reset() {
    state = const FiddelSubscriptionState();
  }
}

/// Provider for the fetcher
final fiddelSubscriptionFetcherProvider = Provider<FiddelSubscriptionFetcher>((ref) {
  return FiddelSubscriptionFetcher(httpClient: ref.read(httpClientProvider));
});

/// Provider for the tester
final fiddelConfigTesterProvider = Provider<FiddelConfigTester>((ref) {
  return FiddelConfigTester(httpClient: ref.read(httpClientProvider));
});