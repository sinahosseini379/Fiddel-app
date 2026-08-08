import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class SubscriptionSource with _$SubscriptionSource {
  const factory SubscriptionSource({
    required String id,
    required String name,
    required String url,
    @Default(true) bool enabled,
    @Default(0) int lastTestedAt,
    @Default(0) int configsFound,
  }) = _SubscriptionSource;

  factory SubscriptionSource.fromJson(Map<String, dynamic> json) => _$SubscriptionSourceFromJson(json);
}

@freezed
class TesterSettings with _$TesterSettings {
  const factory TesterSettings({
    @Default(8) int configsPerCountry,
    @Default('04:34') String scheduleTime,
    @Default('Asia/Tehran') String timezone,
    @Default(5) int urlTestRounds,
    @Default(5) int tcpPingTries,
    @Default(4) int tcpPingMinSuccess,
    @Default(100) int tcpConcurrency,
    @Default(1000) int maxConfigs,
    @Default(true) bool allowInsecure,
    @Default(0.15) double maxErrorRate,
    @Default(10) int maxConcurrent,
    @Default(10) int maxSubscriptionUrls,
    @Default('prefer') String stealthMode,
    @Default(0.4) double stealthMinScore,
    @Default(true) bool incremental,
    @Default([]) List<String> allowedCountries,
    @Default([]) List<TestTarget> testUrls,
    @Default({}) Map<String, dynamic> geoipProviders,
    @Default('Fiddel USA') String subscriptionName,
    @Default(24) int subscriptionIntervalHours,
  }) = _TesterSettings;

  factory TesterSettings.fromJson(Map<String, dynamic> json) => _$TesterSettingsFromJson(json);
}