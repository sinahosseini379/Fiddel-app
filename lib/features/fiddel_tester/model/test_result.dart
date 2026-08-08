import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_result.freezed.dart';
part 'test_result.g.dart';

@freezed
class TestTarget with _$TestTarget {
  const factory TestTarget({
    required String label,
    required String url,
    @Default(1.0) double weight,
  }) = _TestTarget;

  factory TestTarget.fromJson(Map<String, dynamic> json) => _$TestTargetFromJson(json);
}

@freezed
class TargetStat with _$TargetStat {
  const factory TargetStat({
    required int success,
    required int fail,
    @Default([]) List<int> latencies,
  }) = _TargetStat;

  factory TargetStat.fromJson(Map<String, dynamic> json) => _$TargetStatFromJson(json);
}

@freezed
class TestResult with _$TestResult {
  const factory TestResult({
    required String configId,
    required String configName,
    required String country,
    required String countryName,
    required String flag,
    required String protocol,
    required String transport,
    required String security,
    required double stealthScore,
    @Default({}) Map<String, TargetStat> targetStats,
    @Default([]) List<int> allLatencies,
    @Default(0) int totalTests,
    @Default(0) int passedTests,
  }) = _TestResult;

  factory TestResult.fromJson(Map<String, dynamic> json) => _$TestResultFromJson(json);
}

extension TestResultX on TestResult {
  double get errorRate => totalTests > 0 ? (totalTests - passedTests) / totalTests : 1.0;
  
  double get weightedErrorRate {
    // Simplified - in real implementation use target weights
    return errorRate;
  }

  double get avgLatency {
    if (allLatencies.isEmpty) return 0;
    return allLatencies.reduce((a, b) => a + b) / allLatencies.length;
  }

  int get p50 {
    if (allLatencies.isEmpty) return 0;
    final sorted = [...allLatencies]..sort();
    return sorted[sorted.length ~/ 2];
  }

  int get p95 {
    if (allLatencies.isEmpty) return 0;
    final sorted = [...allLatencies]..sort();
    return sorted[(sorted.length * 0.95).ceil()];
  }

  String get displayName => '$flag $countryName | ${configName.isEmpty ? configId.substring(0, 8) : configName}';
}