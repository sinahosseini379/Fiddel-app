import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:fiddel/features/fiddel/data/fiddel_subscription_parser.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';

class FiddelSubscriptionFetcher {
  FiddelSubscriptionFetcher({required DioHttpClient httpClient}) : _httpClient = httpClient;

  final DioHttpClient _httpClient;

  static const String defaultSubscriptionUrl =
      'https://raw.githubusercontent.com/sinahosseini379/VPN-Subscription-Tester-USA/main/felfelconfig.txt';
  static const String fallbackSubscriptionUrl =
      'https://raw.githubusercontent.com/sinahosseini379/VPN-Subscription-Tester-/main/felfelconfig.txt';

  /// Fetch and parse the Fiddel USA subscription
  Future<Either<String, List<FiddelConfig>>> fetchAndParse({String? customUrl, CancelToken? cancelToken}) async {
    final urls = [
      if (customUrl != null && customUrl.isNotEmpty) customUrl,
      defaultSubscriptionUrl,
      fallbackSubscriptionUrl,
    ];

    String? lastError;
    for (final url in urls) {
      try {
        final result = await _downloadAndParse(url, cancelToken);
        if (result.isRight()) return result;
        lastError = result.getLeft();
      } catch (e) {
        lastError = e.toString();
      }
    }
    return Left(lastError ?? 'Failed to fetch subscription from all sources');
  }

  Future<Either<String, List<FiddelConfig>>> _downloadAndParse(String url, CancelToken? cancelToken) async {
    try {
      final response = await _httpClient
          .downloadRaw(url.trim(), cancelToken: cancelToken ?? CancelToken())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return Left('HTTP ${response.statusCode}: ${response.statusMessage}');
      }

      final content = response.data as String;
      final parseResult = FiddelSubscriptionParser.parseSubscription(content);

      return parseResult.fold(
        (error) => Left('Parse failed: $error'),
        (uris) => Right(FiddelSubscriptionParser.urisToConfigs(uris)),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return const Left('Cancelled by user');
      }
      return Left('Download error: ${e.message}');
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }
}