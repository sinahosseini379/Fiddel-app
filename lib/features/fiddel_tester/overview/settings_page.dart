import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fiddel/core/localization/translations.dart';
import 'package:fiddel/features/fiddel_tester/model/subscription.dart';
import 'package:fiddel/features/fiddel_tester/notifier/tester_notifier.dart';
import 'package:fiddel/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FiddelTesterSettingsPage extends HookConsumerWidget {
  const FiddelTesterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final state = ref.watch(testerNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.fiddelTester.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestSettings(context, ref, t, state.settings),
          const Gap(24),
          _buildAdvancedSettings(context, ref, t, state.settings),
          const Gap(24),
          _buildTargetUrls(context, ref, t, state.settings),
        ],
      ),
    );
  }

  Widget _buildTestSettings(BuildContext context, WidgetRef ref, TranslationsEn t, TesterSettings settings) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.fiddelTester.testSettings, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.configsPerCountry}: ${settings.configsPerCountry}',
              value: settings.configsPerCountry.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(configsPerCountry: v.round()),
              ),
            ),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.urlTestRounds}: ${settings.urlTestRounds}',
              value: settings.urlTestRounds.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(urlTestRounds: v.round()),
              ),
            ),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.tcpPingTries}: ${settings.tcpPingTries}',
              value: settings.tcpPingTries.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(tcpPingTries: v.round()),
              ),
            ),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.tcpPingMinSuccess}: ${settings.tcpPingMinSuccess}',
              value: settings.tcpPingMinSuccess.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(tcpPingMinSuccess: v.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, WidgetRef ref, TranslationsEn t, TesterSettings settings) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.fiddelTester.advancedSettings, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            SwitchListTile(
              title: Text(t.fiddelTester.allowInsecure),
              subtitle: Text(t.fiddelTester.allowInsecureDesc),
              value: settings.allowInsecure,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(allowInsecure: v),
              ),
            ),
            const Gap(8),
            SwitchListTile(
              title: Text(t.fiddelTester.incremental),
              subtitle: Text(t.fiddelTester.incrementalDesc),
              value: settings.incremental,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(incremental: v),
              ),
            ),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.maxErrorRate}: ${(settings.maxErrorRate * 100).round()}%',
              value: settings.maxErrorRate * 100,
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(maxErrorRate: v / 100),
              ),
            ),
            const Gap(16),
            _buildSlider(
              context,
              label: '${t.fiddelTester.stealthMinScore}: ${(settings.stealthMinScore * 100).round()}%',
              value: settings.stealthMinScore * 100,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(stealthMinScore: v / 100),
              ),
            ),
            const Gap(16),
            DropdownButtonFormField<String>(
              value: settings.stealthMode,
              decoration: InputDecoration(labelText: t.fiddelTester.stealthMode),
              items: ['off', 'prefer', 'strict'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => ref.read(testerNotifierProvider.notifier).updateSettings(
                settings.copyWith(stealthMode: v ?? 'prefer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetUrls(BuildContext context, WidgetRef ref, TranslationsEn t, TesterSettings settings) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.fiddelTester.testTargets, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            ...settings.testUrls.map((target) => ListTile(
              leading: const Icon(Icons.web_rounded),
              title: Text(target.label),
              subtitle: Text(target.url),
              trailing: Text('Weight: ${target.weight}'),
            )).toList(),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: () => _showAddTargetDialog(context, ref, settings),
              icon: const Icon(Icons.add_rounded),
              label: Text(t.fiddelTester.addTarget),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showAddTargetDialog(BuildContext context, WidgetRef ref, TesterSettings settings) {
    final labelCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '1.0');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Test Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: 'Label')),
            const Gap(12),
            TextField(controller: urlCtrl, decoration: InputDecoration(labelText: 'URL')),
            const Gap(12),
            TextField(controller: weightCtrl, decoration: InputDecoration(labelText: 'Weight'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (labelCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                final newTarget = TestTarget(
                  label: labelCtrl.text,
                  url: urlCtrl.text,
                  weight: double.tryParse(weightCtrl.text) ?? 1.0,
                );
                ref.read(testerNotifierProvider.notifier).updateSettings(
                  settings.copyWith(testUrls: [...settings.testUrls, newTarget]),
                );
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