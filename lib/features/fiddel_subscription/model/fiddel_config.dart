import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fiddel_config.freezed.dart';
part 'fiddel_config.g.dart';

@freezed
abstract class FiddelConfig with _$FiddelConfig {
  const factory FiddelConfig({
    required String uri,
    required String name,
    required String protocol,
    required String transport,
    required String security,
    required String fingerprint,
    required String country,
    required String countryName,
    required String flag,
    required int index,
    required double stealthScore,
    required double avgLatency,
    required double errorRate,
    required int samples,
    required Map<String, dynamic> perTarget,
  }) = _FiddelConfig;

  factory FiddelConfig.fromJson(Map<String, dynamic> json) => _$FiddelConfigFromJson(json);
}

@freezed
abstract class FiddelSubscriptionMetadata with _$FiddelSubscriptionMetadata {
  const factory FiddelSubscriptionMetadata({
    required String version,
    required String generatedAt,
    required int count,
    required double avgLatencyMs,
    required double avgErrorRate,
    required Map<String, int> byCountry,
    required List<FiddelTestTarget> targets,
    required List<FiddelConfig> items,
  }) = _FiddelSubscriptionMetadata;

  factory FiddelSubscriptionMetadata.fromJson(Map<String, dynamic> json) => _$FiddelSubscriptionMetadataFromJson(json);
}

@freezed
abstract class FiddelTestTarget with _$FiddelTestTarget {
  const factory FiddelTestTarget({
    required String label,
    required String url,
    required double weight,
  }) = _FiddelTestTarget;

  factory FiddelTestTarget.fromJson(Map<String, dynamic> json) => _$FiddelTestTargetFromJson(json);
}

@freezed
abstract class FiddelTestResult with _$FiddelTestResult {
  const factory FiddelTestResult({
    required String configUri,
    required bool success,
    required int latencyMs,
    required String targetLabel,
    String? error,
  }) = _FiddelTestResult;

  factory FiddelTestResult.fromJson(Map<String, dynamic> json) => _$FiddelTestResultFromJson(json);
}

@freezed
abstract class FiddelSubscriptionState with _$FiddelSubscriptionState {
  const factory FiddelSubscriptionState({
    @Default(false) bool isLoading,
    @Default(false) bool isTesting,
    @Default(0) double progress,
    String? currentStage,
    String? error,
    FiddelSubscriptionMetadata? metadata,
    @Default([]) List<FiddelConfig> testedConfigs,
    @Default([]) List<FiddelConfig> workingConfigs,
  }) = _FiddelSubscriptionState;

  factory FiddelSubscriptionState.fromJson(Map<String, dynamic> json) => _$FiddelSubscriptionStateFromJson(json);
}