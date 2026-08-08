import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fiddel/features/profile/model/profile_entity.dart';

part 'fiddel_config.freezed.dart';
part 'fiddel_config.g.dart';

@freezed
class FiddelConfig with _$FiddelConfig {
  const factory FiddelConfig({
    required String uri,
    required String name,
    required String protocol,
    required String server,
    required int port,
    required String transport,
    required String security,
    required String fingerprint,
    required double stealthScore,
    String? country,
    String? countryName,
    String? flag,
    int? index,
    double? latency,
    double? errorRate,
  }) = _FiddelConfig;

  factory FiddelConfig.fromJson(Map<String, dynamic> json) => _$FiddelConfigFromJson(json);

  /// Convert to ProfileEntity for integration with existing profile system
  ProfileEntity toProfileEntity({required String id, required bool active}) {
    return ProfileEntity.remote(
      id: id,
      active: active,
      name: name,
      uri: uri,
      lastUpdate: DateTime.now(),
    );
  }
}

@freezed
class FiddelTestResult with _$FiddelTestResult {
  const factory FiddelTestResult({
    required String uri,
    required bool success,
    required double latency,
    required String error,
  }) = _FiddelTestResult;

  factory FiddelTestResult.fromJson(Map<String, dynamic> json) => _$FiddelTestResultFromJson(json);
}

@freezed
class FiddelSubscriptionState with _$FiddelSubscriptionState {
  const factory FiddelSubscriptionState({
    @Default([]) List<FiddelConfig> configs,
    @Default([]) List<FiddelConfig> testedConfigs,
    @Default([]) List<FiddelConfig> bestConfigs,
    @Default(false) bool isLoading,
    @Default(false) bool isTesting,
    @Default(0.0) double progress,
    String? error,
    String? lastUpdate,
    int? totalTested,
    int? totalPassed,
  }) = _FiddelSubscriptionState;

  factory FiddelSubscriptionState.fromJson(Map<String, dynamic> json) => _$FiddelSubscriptionStateFromJson(json);
}