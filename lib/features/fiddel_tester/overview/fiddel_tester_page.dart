import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:fiddel/core/localization/translations.dart';
import 'package:fiddel/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:fiddel/features/fiddel_tester/overview/fiddel_tester_page.dart';
import 'package:fiddel/features/settings/overview/settings_page.dart';
import 'package:fiddel/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FiddelTesterOverview extends HookConsumerWidget {
  const FiddelTesterOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final breakpoint = Breakpoint(context).activeBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.fiddelTester.title),
        actions: [
          IconButton(
            onPressed: () => context.goNamed('fiddelTesterSettings'),
            icon: const Icon(Icons.settings_rounded),
            tooltip: t.common.settings,
          ),
          const Gap(8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, t),
          const Gap(24),
          _buildQuickActions(context, t),
          const Gap(24),
          _buildSubscriptionList(context, ref, t),
          const Gap(24),
          _buildLastResult(context, ref, t),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TranslationsEn t) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    size: 28,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.fiddelTester.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        t.fiddelTester.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, TranslationsEn t) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.fiddelTester.quickActions,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.play_arrow_rounded,
                title: t.fiddelTester.runTest,
                subtitle: t.fiddelTester.runTestDesc,
                color: theme.colorScheme.primary,
                onTap: () => ref.read(testerNotifierProvider.notifier).runTest(),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _ActionCard(
                icon: Icons.add_rounded,
                title: t.fiddelTester.addSubscription,
                subtitle: t.fiddelTester.addSubscriptionDesc,
                color: theme.colorScheme.secondary,
                onTap: () => _showAddSubscriptionDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionList(BuildContext context, WidgetRef ref, TranslationsEn t) {
    final state = ref.watch(testerNotifierProvider);
    
    if (state.subscriptions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const Gap(12),
              Text(t.fiddelTester.noSubscriptions, style: theme.textTheme.titleMedium),
              const Gap(4),
              Text(t.fiddelTester.noSubscriptionsDesc, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Gap(16),
              FilledButton.icon(
                onPressed: () => _showAddSubscriptionDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.fiddelTester.addSubscription),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.fiddelTester.subscriptions, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Gap(12),
        ...state.subscriptions.map((sub) => _SubscriptionCard(sub: sub)).toList(),
      ],
    );
  }

  Widget _buildLastResult(BuildContext context, WidgetRef ref, TranslationsEn t) {
    final state = ref.watch(testerNotifierProvider);
    final result = state.lastResult;

    if (result == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.fiddelTester.lastResult, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Gap(12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: t.fiddelTester.tested,
                        value: result.allResults.length.toString(),
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: t.fiddelTester.selected,
                        value: result.selectedConfigs.length.toString(),
                        icon: Icons.star_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: t.fiddelTester.countries,
                        value: result.selectedConfigs.map((c) => c.country).toSet().length.toString(),
                        icon: Icons.public_rounded,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                FilledButton(
                  onPressed: () => context.goNamed('fiddelTesterResults'),
                  child: Text(t.fiddelTester.viewDetails),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')),
            const Gap(12),
            TextField(controller: urlCtrl, decoration: InputDecoration(labelText: 'URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                ref.read(testerNotifierProvider.notifier).addSubscription(nameCtrl.text, urlCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Gap(12),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(4),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionSource sub;

  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sub.enabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.link_rounded,
            color: sub.enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(sub.name),
        subtitle: Text(sub.url, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Switch(
          value: sub.enabled,
          onChanged: (v) => ref.read(testerNotifierProvider.notifier).toggleSubscription(sub.id, v),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Column(
      children: [
        Icon(icon, color: c, size: 28),
        const Gap(4),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: c)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}