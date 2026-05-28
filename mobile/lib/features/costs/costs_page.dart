import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/period_selector.dart';
import 'costs_provider.dart';

class CostsPage extends ConsumerStatefulWidget {
  const CostsPage({super.key});

  @override
  ConsumerState<CostsPage> createState() => _CostsPageState();
}

class _CostsPageState extends ConsumerState<CostsPage> {
  PeriodOption _period = PeriodOption.mois;
  double? _actualAmount;

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  void _showActualAmountDialog(CostBreakdown breakdown) {
    final controller = TextEditingController(
      text: _actualAmount?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dépense réelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez le montant réellement payé ce mois:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant en FCFA',
                suffixText: 'FCFA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              setState(() => _actualAmount = val);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdownAsync = ref.watch(costBreakdownProvider(_period));

    return Scaffold(
      appBar: AppBar(title: const Text('Estimation des coûts')),
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
            child: breakdownAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (breakdown) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ---- Carte total ----
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dépense estimée totale',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatFcfa(breakdown.totalFcfa),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_actualAmount != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Réel: ${_formatFcfa(_actualAmount!)} '
                                '(${breakdown.variancePercent >= 0 ? '+' : ''}${breakdown.variancePercent.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => _showActualAmountDialog(breakdown),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Saisir dépense réelle'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---- Graphique camembert ----
                    if (breakdown.totalFcfa > 0) ...[
                      Text(
                        'Répartition',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    if (breakdown.telecomCostFcfa > 0)
                                      PieChartSectionData(
                                        color: AppTheme.primary,
                                        value: breakdown.telecomCostFcfa,
                                        title: '${(breakdown.telecomCostFcfa / breakdown.totalFcfa * 100).toStringAsFixed(0)}%',
                                        radius: 70,
                                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    if (breakdown.aiCostFcfa > 0)
                                      PieChartSectionData(
                                        color: AppTheme.aiPurple,
                                        value: breakdown.aiCostFcfa,
                                        title: '${(breakdown.aiCostFcfa / breakdown.totalFcfa * 100).toStringAsFixed(0)}%',
                                        radius: 70,
                                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                  centerSpaceRadius: 30,
                                  sectionsSpace: 3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendItem(color: AppTheme.primary, label: 'Télécom', value: _formatFcfa(breakdown.telecomCostFcfa)),
                                const SizedBox(height: 10),
                                _LegendItem(color: AppTheme.aiPurple, label: 'IA', value: _formatFcfa(breakdown.aiCostFcfa)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ---- Détail ----
                    Text(
                      'Détail des coûts',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _CostRow(icon: Icons.signal_cellular_alt, label: 'Données mobiles', amount: breakdown.dataCostFcfa, formatFcfa: _formatFcfa, color: AppTheme.primary),
                    _CostRow(icon: Icons.call, label: 'Appels', amount: breakdown.callCostFcfa, formatFcfa: _formatFcfa, color: AppTheme.success),
                    _CostRow(icon: Icons.sms, label: 'SMS', amount: breakdown.smsCostFcfa, formatFcfa: _formatFcfa, color: AppTheme.warning),
                    _CostRow(icon: Icons.psychology, label: 'Tokens IA', amount: breakdown.aiCostFcfa, formatFcfa: _formatFcfa, color: AppTheme.aiPurple,
                      subtitle: '≈ \$${breakdown.aiCostUsd.toStringAsFixed(4)} USD'),

                    const SizedBox(height: 16),

                    // ---- Avertissement ----
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les montants affichés sont des estimations calculées localement. '
                              'Ils peuvent différer de votre facture réelle. '
                              'Vérifiez auprès de votre opérateur pour les montants exacts.',
                              style: TextStyle(fontSize: 11, color: AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.formatFcfa,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final double amount;
  final String Function(double) formatFcfa;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              formatFcfa(amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
