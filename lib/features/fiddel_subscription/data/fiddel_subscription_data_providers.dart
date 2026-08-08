import 'package:fiddel/core/http_client/http_client_provider.dart';
import 'package:fiddel/features/fiddel_subscription/data/fiddel_subscription_fetcher.dart';
import 'package:fiddel/features/fiddel_subscription/notifier/fiddel_subscription_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fiddel_subscription_data_providers.g.dart';

@Riverpod(keepAlive: true)
FiddelSubscriptionFetcher fiddelSubscriptionFetcher(Ref ref) {
  return FiddelSubscriptionFetcher(
    ref: ref,
    httpClient: ref.watch(httpClientProvider),
  );
}

@Riverpod(keepAlive: true)
FiddelSubscriptionNotifier fiddelSubscriptionNotifier(Ref ref) {
  return FiddelSubscriptionNotifier(ref);
}