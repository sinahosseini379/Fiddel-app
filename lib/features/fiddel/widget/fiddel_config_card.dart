import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fiddel/core/localization/translations.dart';
import 'package:fiddel/features/fiddel/model/fiddel_config.dart';
import 'package:fiddel/features/fiddel/widget/fiddel_subscription_page.dart';
import 'package:fiddel/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FiddelConfigCard extends HookConsumerWidget {
  const FiddelConfigCard({super.key, required this.config, required this.index});
  final FiddelConfig config;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (config.flag != null)
                            Text(config.flag!, style: const TextStyle(fontSize: 16)),
                          const Gap(6),
                          Flexible(
                            child: Text(
                              config.name.isNotEmpty ? config.name : config.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${config.protocol.toUpperCase()} • ${config.transport}/${config.security}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (config.latency != null) ...[
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _latencyColor(config.latency!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${config.latency!.round()} ms',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _latencyColor(config.latency!),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(12),
            Row(
              children: [
                _InfoChip(icon: Icons.dns, label: config.server, color: theme.colorScheme.primary),
                const Gap(8),
                _InfoChip(icon: Icons.pin, label: config.port.toString(), color: Colors.orange),
                const Gap(8),
                if (config.stealthScore > 0)
                  _InfoChip(
                    icon: Icons.security,
                    label: t.pages.fiddel.stealthScore(config.stealthScore.toStringAsFixed(2)),
                    color: Colors.purple,
                  ),
              ],
            ),
            if (config.countryName != null) ...[
              const Gap(8),
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const Gap(4),
                  Text('${config.countryName} (${config.country})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _latencyColor(double latency) {
    if (latency < 200) return Colors.green;
    if (latency < 500) return Colors.orange;
    return Colors.red;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

extension FiddelConfigDisplay on FiddelConfig {
  String get displayName {
    if (name.isNotEmpty) return name;
    return '$protocol://$server:$port';
  }
}