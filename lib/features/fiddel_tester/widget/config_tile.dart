import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fiddel/core/localization/translations.dart';
import 'package:fiddel/features/fiddel_tester/model/test_result.dart';
import 'package:fiddel/utils/utils.dart';

class ConfigTile extends StatelessWidget {
  final TestResult config;
  final int index;
  final bool showCountry;

  const ConfigTile({
    super.key,
    required this.config,
    required this.index,
    this.showCountry = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = translations(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showCountry && config.country.isNotEmpty) ...[
                        const Gap(2),
                        Row(
                          children: [
                            Text(config.flag),
                            const Gap(4),
                            Text(
                              config.countryName,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (config.stealthScore > 0) ...[
                  const Gap(8),
                  _StealthBadge(score: config.stealthScore),
                ],
              ],
            ),
            const Gap(12),
            Row(
              children: [
                _MetricChip(
                  icon: Icons.wifi_rounded,
                  label: '${config.errorRate.toStringAsFixed(0)}%',
                  color: _errorRateColor(config.errorRate),
                  tooltip: t.fiddelTester.errorRate,
                ),
                const Gap(8),
                _MetricChip(
                  icon: Icons.speed_rounded,
                  label: '${config.avgLatency.round()}ms',
                  color: _latencyColor(config.avgLatency),
                  tooltip: t.fiddelTester.avgLatency,
                ),
                const Gap(8),
                _MetricChip(
                  icon: Icons.insights_rounded,
                  label: 'P95: ${config.p95}ms',
                  color: _latencyColor(config.p95.toDouble()),
                  tooltip: t.fiddelTester.p95Latency,
                ),
              ],
            ),
            if (config.transport.isNotEmpty || config.security.isNotEmpty) ...[
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (config.protocol.isNotEmpty)
                    _ProtocolChip(label: config.protocol.toUpperCase(), color: theme.colorScheme.primary),
                  if (config.transport.isNotEmpty)
                    _ProtocolChip(label: config.transport.toUpperCase(), color: theme.colorScheme.secondary),
                  if (config.security.isNotEmpty)
                    _ProtocolChip(label: config.security.toUpperCase(), color: theme.colorScheme.tertiary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _errorRateColor(double rate) {
    if (rate == 0) return Colors.green;
    if (rate < 0.1) return Colors.lightGreen;
    if (rate < 0.3) return Colors.orange;
    return Colors.red;
  }

  Color _latencyColor(double latency) {
    if (latency < 100) return Colors.green;
    if (latency < 300) return Colors.lightGreen;
    if (latency < 600) return Colors.orange;
    return Colors.red;
  }
}

class _StealthBadge extends StatelessWidget {
  final double score;

  const _StealthBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    String label;
    
    if (score >= 0.8) {
      color = Colors.green;
      label = 'Excellent';
    } else if (score >= 0.6) {
      color = Colors.lightGreen;
      label = 'Good';
    } else if (score >= 0.4) {
      color = Colors.orange;
      label = 'Fair';
    } else {
      color = Colors.red;
      label = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 12, color: color),
          const Gap(4),
          Text(
            '$label ${(score * 100).round()}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
    
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}

class _ProtocolChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ProtocolChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}