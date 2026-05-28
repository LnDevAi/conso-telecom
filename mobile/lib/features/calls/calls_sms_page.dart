import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/models/call_record.dart';
import '../../core/database/models/sms_record.dart';

final _callStatsProvider = FutureProvider<_CallStats>((ref) async {
  final isar = IsarService.instance;
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  final calls = await isar.callRecords
      .filter()
      .timestampBetween(startOfMonth, now)
      .findAll();

  final smsCount = await isar.smsRecords
      .filter()
      .timestampBetween(startOfMonth, now)
      .count();

  double outgoingMinutes = 0;
  double incomingMinutes = 0;
  int missed = 0;

  for (final c in calls) {
    if (c.isOutgoing) outgoingMinutes += c.durationMinutes;
    if (c.isIncoming) incomingMinutes += c.durationMinutes;
    if (c.isMissed) missed++;
  }

  return _CallStats(
    outgoingMinutes: outgoingMinutes,
    incomingMinutes: incomingMinutes,
    missedCalls: missed,
    smsCount: smsCount,
    totalCalls: calls.length,
  );
});

class CallsSmsPage extends ConsumerWidget {
  const CallsSmsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_callStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appels & SMS')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ce mois',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.call_made,
                    label: 'Appels sortants',
                    value: '${stats.outgoingMinutes.toStringAsFixed(0)} min',
                    color: AppTheme.primary,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.call_received,
                    label: 'Appels reçus',
                    value: '${stats.incomingMinutes.toStringAsFixed(0)} min',
                    color: AppTheme.success,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.call_missed,
                    label: 'Appels manqués',
                    value: '${stats.missedCalls}',
                    color: AppTheme.danger,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(
                    icon: Icons.sms,
                    label: 'SMS envoyés',
                    value: '${stats.smsCount}',
                    color: AppTheme.warning,
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Estimation coût appels',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _CostEstimateCard(stats: stats),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Permission d\'accès au journal d\'appels requise pour le suivi automatique. '
                  'Sans cette permission, les données sont estimées.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CostEstimateCard extends StatelessWidget {
  const _CostEstimateCard({required this.stats});

  final _CallStats stats;

  String _fmt(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    // Estimation: 60% on-net à 35 FCFA/min, 40% off-net à 60 FCFA/min
    final onNet = stats.outgoingMinutes * 0.6 * 35;
    final offNet = stats.outgoingMinutes * 0.4 * 60;
    final smsCost = stats.smsCount * 15.0;
    final total = onNet + offNet + smsCost;

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _Row(label: 'Appels on-net (est. 60%)', value: _fmt(onNet), theme: theme),
          const SizedBox(height: 6),
          _Row(label: 'Appels off-net (est. 40%)', value: _fmt(offNet), theme: theme),
          const SizedBox(height: 6),
          _Row(label: 'SMS envoyés', value: _fmt(smsCost), theme: theme),
          const Divider(height: 16),
          _Row(label: 'Total estimé', value: _fmt(total), theme: theme, bold: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.theme, this.bold = false});

  final String label;
  final String value;
  final ThemeData theme;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium),
        Text(value, style: bold
            ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primary)
            : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CallStats {
  final double outgoingMinutes;
  final double incomingMinutes;
  final int missedCalls;
  final int smsCount;
  final int totalCalls;

  const _CallStats({
    required this.outgoingMinutes,
    required this.incomingMinutes,
    required this.missedCalls,
    required this.smsCount,
    required this.totalCalls,
  });
}
