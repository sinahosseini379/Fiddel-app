import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/fiddel_tester/model/test_result.dart';
import 'package:hiddify/features/fiddel_tester/notifier/tester_notifier.dart';
import 'package:hiddify/features/fiddel_tester/widget/config_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FiddelTesterResultsPage extends HookConsumerWidget {
  const FiddelTesterResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = ref.watch(testerNotifierProvider);
    final result = state.lastResult;
    final theme = Theme.of(context);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.fiddelTester.results)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science_off_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant),
              const Gap(16),
              Text(t.fiddelTester.noResults, style: theme.textTheme.headlineSmall),
              const Gap(8),
              Text(t.fiddelTester.noResultsDesc, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.fiddelTester.results),
        actions: [
          IconButton(
            onPressed: () => _showExportDialog(context, ref, result),
            icon: const Icon(Icons.download_rounded),
            tooltip: t.fiddelTester.export,
          ),
          const Gap(8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSummaryCard(context, t, result),
            ),
          ),
          // Tabs for All / Selected
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              tabs: [
                _TabInfo(label: '${t.fiddelTester.all} (${result.allResults.length})', index: 0),
                _TabInfo(label: '${t.fiddelTester.selected} (${result.selectedConfigs.length})', index: 1),
              ],
            ),
          ),
          // Tab content
          SliverFillRemaining(
            child: DefaultTabController(
              length: 2,
              child: TabBarView(
                children: [
                  _ResultsList(results: result.allResults, showCountry: true),
                  _ResultsList(results: result.selectedConfigs, showCountry: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TranslationsEn t, TestRunResult result) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.fiddelTester.summary, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _StatItem(label: t.fiddelTester.tested, value: result.allResults.length.toString(), icon: Icons.list_alt_rounded)),
                Expanded(child: _StatItem(label: t.fiddelTester.selected, value: result.selectedConfigs.length.toString(), icon: Icons.star_rounded, color: Colors.amber)),
                Expanded(child: _StatItem(label: t.fiddelTester.countries, value: result.selectedConfigs.map((c) => c.country).toSet().length.toString(), icon: Icons.public_rounded)),
              ],
            ),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.selectedConfigs.map((c) => _CountryChip(config: c)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref, TestRunResult result) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export Configs', style: Theme.of(ctx).textTheme.titleLarge),
            const Gap(16),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: const Text('Copy Base64 to Clipboard'),
              onTap: () {
                // Generate base64 from selected configs
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Save to File'),
              onTap: () {
                // Save to file
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final int index;
  _TabInfo({required this.label, required this.index});
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<_TabInfo> tabs;
  final TabController _tabController;

  _TabHeaderDelegate({required this.tabs}) : _tabController = TabController(length: tabs.length, vsync: _NoOpVsync());

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: tabs.map((t) => Tab(text: t.label)).toList(),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _NoOpVsync extends ChangeNotifier implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

class _ResultsList extends StatelessWidget {
  final List<TestResult> results;
  final bool showCountry;

  const _ResultsList({required this.results, this.showCountry = false});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const Gap(16),
            Text('No results', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (context, index) => ConfigTile(config: results[index], index: index + 1, showCountry: showCountry),
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

class _CountryChip extends StatelessWidget {
  final TestResult config;

  const _CountryChip({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Text(config.flag),
      label: Text(config.countryName),
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
    );
  }
}