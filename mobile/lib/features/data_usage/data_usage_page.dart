import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/period_selector.dart';
import 'data_usage_provider.dart';

class DataUsagePage extends ConsumerStatefulWidget {
  const DataUsagePage({super.key});

  @override
  ConsumerState<DataUsagePage> createState() => _DataUsagePageState();
}

class _DataUsagePageState extends ConsumerState<DataUsagePage> {
  PeriodOption _period = PeriodOption.mois;

  String _formatMb(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} Go';
    return '${mb.toStringAsFixed(1)} Mo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(dataUsageProvider(_period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consommation données'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
          ),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.danger)),
              ),
              data: (data) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ---- Totaux ----
                    Row(
                      children: [
                        Expanded(
                          child: _TotalCard(
                            label: 'Mobile',
                            value: _formatMb(data.totalMobileMb),
                            color: AppTheme.primary,
                            icon: Icons.signal_cellular_alt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TotalCard(
                            label: 'Wi-Fi',
                            value: _formatMb(data.totalWifiMb),
                            color: AppTheme.success,
                            icon: Icons.wifi,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ---- Graphique en barres journalier ----
                    if (data.dailyPoints.isNotEmpty) ...[
                      Text(
                        'Usage quotidien',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: data.dailyPoints
                                    .map((p) => p.mobileMb + p.wifiMb)
                                    .fold(0.0, (a, b) => a > b ? a : b) *
                                1.2,
                            barGroups: data.dailyPoints.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final point = entry.value;
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: point.mobileMb,
                                    color: AppTheme.primary,
                                    width: 6,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                  BarChartRodData(
                                    toY: point.wifiMb,
                                    color: AppTheme.success,
                                    width: 6,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text(
                                    _formatMb(value),
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= data.dailyPoints.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = data.dailyPoints[idx].date;
                                    return Text(
                                      '${date.day}',
                                      style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Légende
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: AppTheme.primary, label: 'Mobile'),
                          const SizedBox(width: 16),
                          _LegendDot(color: AppTheme.success, label: 'Wi-Fi'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ---- Par application ----
                    Text(
                      'Par application',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    if (data.perAppUsage.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Aucune donnée disponible.\nVérifiez la permission d\'accès aux statistiques d\'utilisation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...data.perAppUsage.map((app) {
                        final total = data.totalMobileMb + data.totalWifiMb;
                        final ratio = total > 0 ? app.totalMb / total : 0.0;
                        return _AppUsageRow(
                          app: app,
                          ratio: ratio,
                          formatMb: _formatMb,
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

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
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  const _AppUsageRow({
    required this.app,
    required this.ratio,
    required this.formatMb,
  });

  final AppDataUsage app;
  final double ratio;
  final String Function(double) formatMb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app.appName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatMb(app.totalMb),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFe5e7eb),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Mobile: ${formatMb(app.totalMobileMb)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              Text(
                'Wi-Fi: ${formatMb(app.totalWifiMb)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
