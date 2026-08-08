import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fiddel/core/localization/translations.dart';
import 'package:fiddel/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';
import 'package:fiddel/features/fiddel/notifier/fiddel_subscription_notifier.dart';
import 'package:fiddel/features/fiddel/widget/fiddel_config_card.dart';
import 'package:fiddel/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FiddelSubscriptionPage extends HookConsumerWidget {
  const FiddelSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final state = ref.watch(fiddelSubscriptionNotifierProvider);
    final notifier = ref.read(fiddelSubscriptionNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Assets.images.logo.svg(height: 24, colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn)),
            const Gap(8),
            Text(t.pages.fiddel.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t.common.refresh,
            onPressed: state.isLoading || state.isTesting
                ? null
                : () => notifier.fetchAndTestBest(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const Gap(8),
        ],
      ),
      body: _buildBody(context, ref, state, notifier, t, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FiddelSubscriptionState state,
    FiddelSubscriptionNotifier notifier,
    TranslationsEn t,
    ThemeData theme,
  ) {
    if (state.isLoading && state.configs.isEmpty) {
      return _LoadingState(message: t.pages.fiddel.loadingSubscription);
    }

    if (state.error != null && state.configs.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => notifier.fetchAndTestBest(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.fetchAndTestBest(),
      child: CustomScrollView(
        slivers: [
          if (state.isLoading || state.isTesting) _ProgressSliver(state: state, t: t),
          if (state.configs.isNotEmpty) _StatsSliver(state: state, t: t),
          if (state.bestConfigs.isNotEmpty) _BestConfigsSliver(configs: state.bestConfigs, t: t),
          if (!state.isTesting && state.bestConfigs.isEmpty && state.configs.isNotEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                message: t.pages.fiddel.noWorkingConfigs,
                onRetry: () => notifier.fetchAndTestBest(),
              ),
            ),
          if (state.bestConfigs.isNotEmpty) _AddProfilesSliver(state: state, notifier: notifier, t: t),
        ],
      ),
    );
  }
}

class _ProgressSliver extends HookConsumerWidget {
  const _ProgressSliver({required this.state, required this.t});
  final FiddelSubscriptionState state;
  final TranslationsEn t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = state.progress.clamp(0.0, 1.0);
    final label = state.isLoading
        ? t.pages.fiddel.loadingSubscription
        : state.isTesting
            ? t.pages.fiddel.testingConfigs(state.totalTested, state.configs.length)
            : '';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
            const Gap(8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (state.totalTested != null && state.totalPassed != null) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(label: t.common.tested, value: state.totalTested.toString(), color: theme.colorScheme.primary),
                  const Gap(12),
                  _StatChip(label: t.pages.fiddel.passed, value: state.totalPassed.toString(), color: Colors.green),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsSliver extends StatelessWidget {
  const _StatsSliver({required this.state, required this.t});
  final FiddelSubscriptionState state;
  final TranslationsEn t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _StatCard(title: t.pages.fiddel.totalFound, value: state.configs.length.toString(), icon: Icons.list_alt, color: theme.colorScheme.primary)),
            const Gap(12),
            Expanded(child: _StatCard(title: t.pages.fiddel.working, value: state.totalPassed?.toString() ?? '0', icon: Icons.check_circle, color: Colors.green)),
            const Gap(12),
            Expanded(child: _StatCard(title: t.pages.fiddel.bestSelected, value: state.bestConfigs.length.toString(), icon: Icons.star, color: Colors.amber)),
          ],
        ),
      ),
    );
  }
}

class _BestConfigsSliver extends StatelessWidget {
  const _BestConfigsSliver({required this.configs, required this.t});
  final List<FiddelConfig> configs;
  final TranslationsEn t;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: configs.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (context, index) {
        final config = configs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FiddelConfigCard(config: config, index: index + 1),
        );
      },
    );
  }
}

class _AddProfilesSliver extends HookConsumerWidget {
  const _AddProfilesSliver({required this.state, required this.notifier, required this.t});
  final FiddelSubscriptionState state;
  final FiddelSubscriptionNotifier notifier;
  final TranslationsEn t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: Text(t.pages.fiddel.addToProfiles(state.bestConfigs.length)),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () async {
            await notifier.addBestConfigsAsProfiles();
            if (ref.context.mounted) {
              ScaffoldMessenger.of(ref.context).showSnackBar(
                SnackBar(content: Text(t.pages.fiddel.addedSuccess(state.bestConfigs.length))),
              );
            }
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const Gap(16),
          Text(message, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const Gap(16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const Gap(16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(t.common.retry)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_statusbar_4_bar, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const Gap(16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const Gap(16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(t.common.retry)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const Gap(4),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}