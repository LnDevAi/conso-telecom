import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/models/data_record.dart';
import '../../core/database/models/ai_usage_record.dart';

class _DailyHistory {
  final DateTime date;
  final double dataMobileMb;
  final double dataWifiMb;
  final double estimatedCostFcfa;
  final int aiTokens;
  final double aiCostFcfa;

  const _DailyHistory({
    required this.date,
    required this.dataMobileMb,
    required this.dataWifiMb,
    required this.estimatedCostFcfa,
    required this.aiTokens,
    required this.aiCostFcfa,
  });
}

class _MonthlyHistory {
  final DateTime month;
  final double telecomCostFcfa;
  final double aiCostFcfa;

  const _MonthlyHistory({
    required this.month,
    required this.telecomCostFcfa,
    required this.aiCostFcfa,
  });
}

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<_DailyHistory> _dailyHistory = [];
  List<_MonthlyHistory> _monthlyHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final isar = IsarService.instance;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    // Données 30 jours
    final dataRecords = await isar.dataRecords
        .filter()
        .timestampBetween(thirtyDaysAgo, now)
        .sortByTimestamp()
        .findAll();

    final aiRecords = await isar.aiUsageRecords
        .filter()
        .timestampBetween(thirtyDaysAgo, now)
        .sortByTimestamp()
        .findAll();

    // Agréger par jour
    final dayMap = <String, _MutableDailyHistory>{};
    for (final r in dataRecords) {
      final key = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
      dayMap.putIfAbsent(key, () => _MutableDailyHistory(r.timestamp));
      dayMap[key]!.dataMobileMb += (r.mobileRxBytes + r.mobileTxBytes) / (1024 * 1024);
      dayMap[key]!.dataWifiMb += (r.wifiRxBytes + r.wifiTxBytes) / (1024 * 1024);
      dayMap[key]!.estimatedCostFcfa += dayMap[key]!.dataMobileMb * 5.0;
    }

    for (final r in aiRecords) {
      final key = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
      dayMap.putIfAbsent(key, () => _MutableDailyHistory(r.timestamp));
      dayMap[key]!.aiTokens += r.totalTokens;
      dayMap[key]!.aiCostFcfa += r.costLocal;
    }

    final daily = dayMap.values
        .map((d) => _DailyHistory(
              date: DateTime(d.date.year, d.date.month, d.date.day),
              dataMobileMb: d.dataMobileMb,
              dataWifiMb: d.dataWifiMb,
              estimatedCostFcfa: d.estimatedCostFcfa + d.aiCostFcfa,
              aiTokens: d.aiTokens,
              aiCostFcfa: d.aiCostFcfa,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Données 6 mois
    final allDataRecords = await isar.dataRecords
        .filter()
        .timestampBetween(sixMonthsAgo, now)
        .findAll();

    final allAiRecords = await isar.aiUsageRecords
        .filter()
        .timestampBetween(sixMonthsAgo, now)
        .findAll();

    final monthMap = <String, _MutableMonthHistory>{};
    for (final r in allDataRecords) {
      final key = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}';
      monthMap.putIfAbsent(key, () => _MutableMonthHistory(DateTime(r.timestamp.year, r.timestamp.month, 1)));
      monthMap[key]!.telecomCostFcfa += (r.mobileRxBytes + r.mobileTxBytes) / (1024 * 1024) * 5.0;
    }
    for (final r in allAiRecords) {
      final key = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}';
      monthMap.putIfAbsent(key, () => _MutableMonthHistory(DateTime(r.timestamp.year, r.timestamp.month, 1)));
      monthMap[key]!.aiCostFcfa += r.costLocal;
    }

    final monthly = monthMap.values
        .map((m) => _MonthlyHistory(
              month: m.month,
              telecomCostFcfa: m.telecomCostFcfa,
              aiCostFcfa: m.aiCostFcfa,
            ))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    setState(() {
      _dailyHistory = daily;
      _monthlyHistory = monthly;
      _loading = false;
    });
  }

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[
      ['Date', 'Données Mobile (Mo)', 'Données WiFi (Mo)', 'Tokens IA', 'Coût IA (FCFA)', 'Coût Total Estimé (FCFA)'],
      ..._dailyHistory.map((d) => [
        DateFormat('yyyy-MM-dd').format(d.date),
        d.dataMobileMb.toStringAsFixed(2),
        d.dataWifiMb.toStringAsFixed(2),
        d.aiTokens,
        d.aiCostFcfa.toStringAsFixed(0),
        d.estimatedCostFcfa.toStringAsFixed(0),
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await Share.share(csv, subject: 'ConsoTélécom - Historique');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Exporter CSV',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- Tendance 30 jours ----
                  Text(
                    'Tendance données (30 jours)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _dailyHistory.isEmpty
                        ? const Center(child: Text('Aucune donnée', style: TextStyle(color: AppTheme.textSecondary)))
                        : LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _dailyHistory.asMap().entries
                                      .map((e) => FlSpot(e.key.toDouble(), e.value.dataMobileMb))
                                      .toList(),
                                  isCurved: true,
                                  color: AppTheme.primary,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.primary.withOpacity(0.1),
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    getTitlesWidget: (val, meta) => Text(
                                      '${val.toInt()}Mo',
                                      style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ),
                                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // ---- Coûts 6 mois ----
                  Text(
                    'Coûts par mois (6 mois)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _monthlyHistory.isEmpty
                        ? const Center(child: Text('Aucune donnée', style: TextStyle(color: AppTheme.textSecondary)))
                        : BarChart(
                            BarChartData(
                              barGroups: _monthlyHistory.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final m = entry.value;
                                return BarChartGroupData(
                                  x: idx,
                                  barRods: [
                                    BarChartRodData(
                                      toY: m.telecomCostFcfa,
                                      color: AppTheme.primary,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                    BarChartRodData(
                                      toY: m.aiCostFcfa,
                                      color: AppTheme.aiPurple,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      if (idx < 0 || idx >= _monthlyHistory.length) return const SizedBox.shrink();
                                      return Text(
                                        DateFormat('MMM', 'fr_FR').format(_monthlyHistory[idx].month),
                                        style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (val, meta) => Text(
                                      '${(val / 1000).toStringAsFixed(0)}K',
                                      style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                    ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Dot(color: AppTheme.primary, label: 'Télécom'),
                      const SizedBox(width: 16),
                      _Dot(color: AppTheme.aiPurple, label: 'IA'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ---- Tableau journalier ----
                  Text(
                    'Détail jour par jour',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_dailyHistory.isEmpty)
                    const Text('Aucune donnée', style: TextStyle(color: AppTheme.textSecondary))
                  else
                    Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Date', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('Mobile', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('Wi-Fi', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('Tokens', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('Coût est.', style: TextStyle(fontSize: 12))),
                          ],
                          rows: _dailyHistory.reversed.take(30).map((d) {
                            return DataRow(cells: [
                              DataCell(Text(DateFormat('dd/MM').format(d.date), style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${d.dataMobileMb.toStringAsFixed(1)} Mo', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${d.dataWifiMb.toStringAsFixed(1)} Mo', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(_formatTokens(d.aiTokens), style: const TextStyle(fontSize: 12))),
                              DataCell(Text(_formatFcfa(d.estimatedCostFcfa), style: const TextStyle(fontSize: 11))),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(0)}K';
    return tokens.toString();
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _MutableDailyHistory {
  final DateTime date;
  double dataMobileMb = 0;
  double dataWifiMb = 0;
  double estimatedCostFcfa = 0;
  int aiTokens = 0;
  double aiCostFcfa = 0;

  _MutableDailyHistory(this.date);
}

class _MutableMonthHistory {
  final DateTime month;
  double telecomCostFcfa = 0;
  double aiCostFcfa = 0;

  _MutableMonthHistory(this.month);
}
