import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fiddel/core/http_client/dio_http_client.dart';
import 'package:fiddel/features/fiddel_tester/data/config_parser.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final subscriptionFetcherProvider = Provider<SubscriptionFetcher>((ref) {
  return SubscriptionFetcher(ref.read(dioHttpClientProvider));
});

class SubscriptionFetcher {
  final DioHttpClient _httpClient;
  
  SubscriptionFetcher(this._httpClient);

  Future<SubscriptionFetchResult> fetch(SubscriptionSource source, {CancelToken? cancelToken}) async {
    try {
      final response = await _httpClient.get(
        source.url,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.plain),
      );
      
      final uris = ConfigParser.decodeSubscription(response.data.toString());
      
      return SubscriptionFetchResult(
        sourceId: source.id,
        uris: uris,
        headers: response.headers.map.map((k, v) => MapEntry(k, v.firstOrNull ?? '')),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return SubscriptionFetchResult(
          sourceId: source.id,
          uris: [],
          error: 'Cancelled',
        );
      }
      return SubscriptionFetchResult(
        sourceId: source.id,
        uris: [],
        error: e.message ?? 'Failed to fetch',
      );
    } catch (e) {
      return SubscriptionFetchResult(
        sourceId: source.id,
        uris: [],
        error: e.toString(),
      );
    }
  }
}

class SubscriptionFetchResult {
  final String sourceId;
  final List<String> uris;
  final Map<String, String> headers;
  final int timestamp;
  final String? error;
  
  SubscriptionFetchResult({
    required this.sourceId,
    required this.uris,
    this.headers = const {},
    required this.timestamp,
    this.error,
  });
  
  bool get success => error == null;
}