import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/models/plan.dart';
import '../../shared/widgets/stat_chip.dart';
import '../../shared/widgets/consumption_bar.dart';
import 'dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatBytes(double bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    }
    return '${bytes.toStringAsFixed(0)} o';
  }

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1_000_000) return '${(tokens / 1_000_000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(0)}K';
    return tokens.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activePlansAsync = ref.watch(activePlansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ConsoTélécom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: 'Réglages',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(activePlansProvider);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.danger)),
          ),
          data: (stats) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- Carte résumé du cycle ----
                _CycleSummaryCard(stats: stats, formatFcfa: _formatFcfa),

                const SizedBox(height: 16),

                // ---- Ligne de StatChips ----
                Text(
                  'Ce mois',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatChip(
                        icon: Icons.signal_cellular_alt,
                        value: stats.dataMobileMb >= 1024
                            ? stats.dataMobileGb.toStringAsFixed(2)
                            : stats.dataMobileMb.toStringAsFixed(0),
                        unit: stats.dataMobileMb >= 1024 ? 'Go' : 'Mo',
                        iconColor: AppTheme.primary,
                        onTap: () => context.go('/data'),
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        icon: Icons.call,
                        value: stats.callsMinutes.toStringAsFixed(0),
                        unit: 'min',
                        iconColor: AppTheme.success,
                        onTap: () => context.go('/calls'),
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        icon: Icons.sms,
                        value: stats.smsCount.toString(),
                        unit: 'SMS',
                        iconColor: AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      StatChip(
                        icon: Icons.psychology,
                        value: _formatTokens(stats.aiTokensTotal),
                        unit: 'tokens',
                        iconColor: AppTheme.aiPurple,
                        onTap: () => context.go('/ai'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Forfaits actifs ----
                activePlansAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (plans) {
                    if (plans.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Forfaits actifs',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/plans'),
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...plans.take(3).map(
                          (plan) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: _PlanConsumptionBar(
                                plan: plan,
                                usedMb: plan.isDataPlan
                                    ? stats.dataMobileMb
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // ---- Dépense IA ce mois ----
                _AiCostCard(stats: stats, formatFcfa: _formatFcfa),

                const SizedBox(height: 20),

                // ---- Accès rapide ----
                Text(
                  'Accès rapide',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.compare_arrows,
                        label: 'Comparateur',
                        color: AppTheme.primary,
                        onTap: () => context.push('/comparator'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.history,
                        label: 'Historique',
                        color: AppTheme.aiPurple,
                        onTap: () => context.push('/history'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.phone_in_talk,
                        label: 'Appels',
                        color: AppTheme.success,
                        onTap: () => context.push('/calls'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CycleSummaryCard extends StatelessWidget {
  const _CycleSummaryCard({
    required this.stats,
    required this.formatFcfa,
  });

  final DashboardStats stats;
  final String Function(double) formatFcfa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;
    final cycleProgress = daysPassed / daysInMonth;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF2563eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cycle ${DateFormat('MMMM yyyy', 'fr_FR').format(now)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'J$daysPassed / $daysInMonth',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression du cycle
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cycleProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Dépense estimée',
                  value: formatFcfa(stats.estimatedCostFcfa),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Moy. journalière',
                  value: formatFcfa(stats.dailyAverageCostFcfa),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Jours restants',
                  value: '$daysRemaining j',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlanConsumptionBar extends StatelessWidget {
  const _PlanConsumptionBar({required this.plan, required this.usedMb});

  final Plan plan;
  final double usedMb;

  @override
  Widget build(BuildContext context) {
    final total = plan.dataLimitMb ?? plan.voiceLimitMinutes ?? 1;
    final used = plan.isDataPlan ? usedMb.clamp(0, total) : 0.0;

    String usedLabel;
    String remainingLabel;
    if (plan.isDataPlan) {
      usedLabel = usedMb >= 1024
          ? '${(usedMb / 1024).toStringAsFixed(2)} Go'
          : '${usedMb.toStringAsFixed(0)} Mo';
      final remaining = (total - used).clamp(0, total);
      remainingLabel = remaining >= 1024
          ? '${(remaining / 1024).toStringAsFixed(2)} Go'
          : '${remaining.toStringAsFixed(0)} Mo';
    } else {
      usedLabel = '${used.toStringAsFixed(0)} min';
      remainingLabel = '${(total - used).clamp(0, total).toStringAsFixed(0)} min';
    }

    return ConsumptionBar(
      title: plan.name,
      used: used,
      total: total,
      usedLabel: usedLabel,
      remainingLabel: remainingLabel,
      subtitle: 'Expire le ${DateFormat('dd/MM/yyyy').format(plan.expiryDate)} • ${plan.daysRemaining} j',
    );
  }
}

class _AiCostCard extends StatelessWidget {
  const _AiCostCard({required this.stats, required this.formatFcfa});

  final DashboardStats stats;
  final String Function(double) formatFcfa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.aiPurple, Color(0xFF6d28d9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Dépense IA ce mois',
                style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatFcfa(stats.aiCostUsd * 610),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '≈ \$${stats.aiCostUsd.toStringAsFixed(2)} USD',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatTokens(stats.aiTokensTotal)} tokens',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'total utilisés',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1_000_000) return '${(tokens / 1_000_000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(0)}K';
    return tokens.toString();
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
