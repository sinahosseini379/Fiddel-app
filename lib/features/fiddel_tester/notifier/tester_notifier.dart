import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/fiddel_tester/data/tester_service.dart';
import 'package:hiddify/features/fiddel_tester/model/subscription.dart';
import 'package:hiddify/features/fiddel_tester/model/test_result.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

final fiddelTesterServiceProvider = Provider((ref) => FiddelTesterService());

class TesterState {
  final TestProgress? progress;
  final List<SubscriptionSource> subscriptions;
  final TesterSettings settings;
  final TestRunResult? lastResult;
  final String? error;

  const TesterState({
    this.progress,
    this.subscriptions = const [],
    TesterSettings? settings,
    this.lastResult,
    this.error,
  }) : settings = settings ?? const TesterSettings();

  TesterState copyWith({
    TestProgress? progress,
    List<SubscriptionSource>? subscriptions,
    TesterSettings? settings,
    TestRunResult? lastResult,
    String? error,
    bool clearError = false,
  }) => TesterState(
    progress: progress ?? this.progress,
    subscriptions: subscriptions ?? this.subscriptions,
    settings: settings ?? this.settings,
    lastResult: lastResult ?? this.lastResult,
    error: clearError ? null : (error ?? this.error),
  );
}

class TesterNotifier extends StateNotifier<TesterState> {
  final FiddelTesterService _service;
  bool _isRunning = false;

  TesterNotifier(this._service) : super(const TesterState()) {
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    // Load from shared preferences or default
    final defaultSubs = [
      SubscriptionSource(
        id: 'fiddel-usa',
        name: 'Fiddel USA',
        url: 'https://raw.githubusercontent.com/sinahosseini379/VPN-Subscription-Tester-USA/main/felfelconfig.txt',
        enabled: true,
      ),
    ];
    state = state.copyWith(subscriptions: defaultSubs);
  }

  Future<void> addSubscription(String name, String url) async {
    final newSub = SubscriptionSource(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: url,
      enabled: true,
    );
    state = state.copyWith(subscriptions: [...state.subscriptions, newSub]);
    await _saveSubscriptions();
  }

  Future<void> removeSubscription(String id) async {
    state = state.copyWith(subscriptions: state.subscriptions.where((s) => s.id != id).toList());
    await _saveSubscriptions();
  }

  Future<void> toggleSubscription(String id, bool enabled) async {
    state = state.copyWith(
      subscriptions: state.subscriptions.map((s) => 
        s.id == id ? s.copyWith(enabled: enabled) : s
      ).toList(),
    );
    await _saveSubscriptions();
  }

  Future<void> updateSettings(TesterSettings settings) async {
    state = state.copyWith(settings: settings);
    // Save to preferences
  }

  Future<void> runTest() async {
    if (_isRunning) return;
    _isRunning = true;
    state = state.copyWith(clearError: true);

    try {
      final result = await _service.runFullTest(
        subscriptions: state.subscriptions,
        settings: state.settings,
        socksProxyBase: 'socks5://127.0.0.1',
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      result.fold(
        (error) => state = state.copyWith(error: error),
        (runResult) => state = state.copyWith(lastResult: runResult, progress: TestProgress.completed('Test completed!')),
      );
    } catch (e) {
      state = state.copyWith(error: 'Test failed: $e');
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _saveSubscriptions() async {
    // Save to shared preferences
  }
}

final testerNotifierProvider = StateNotifierProvider<TesterNotifier, TesterState>((ref) {
  return TesterNotifier(ref.watch(fiddelTesterServiceProvider));
});