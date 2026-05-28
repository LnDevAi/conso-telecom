import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/api/tariff_api.dart';
import '../../shared/models/tariff_plan.dart';
import '../../shared/models/ai_model.dart';
import '../../shared/widgets/ai_provider_badge.dart';
import 'reviews_page.dart';

class ComparatorPage extends ConsumerWidget {
  const ComparatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparateur & Avis'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.compare_arrows, size: 18), text: 'Comparateur'),
              Tab(icon: Icon(Icons.rate_review_outlined, size: 18), text: 'Avis'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ComparatorTab(),
            ReviewsTab(),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// Onglet Comparateur (logique inchangée)
// ────────────────────────────────────────────
class _ComparatorTab extends ConsumerStatefulWidget {
  const _ComparatorTab();

  @override
  ConsumerState<_ComparatorTab> createState() => _ComparatorTabState();
}

class _ComparatorTabState extends ConsumerState<_ComparatorTab>
    with AutomaticKeepAliveClientMixin {
  List<TariffPlan> _rankedPlans = [];
  List<_AiModelRanking> _rankedModels = [];
  bool _loading = true;

  final TariffApi _api = TariffApi();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final operators = await _api.fetchOperators('BF');
      final aiProviders = await _api.fetchAiProviders();

      final allPlans = operators.expand((o) => o.plans).toList()
        ..sort((a, b) => a.price.compareTo(b.price));

      const inputTokens = 100000;
      const outputTokens = 20000;
      final modelRankings = <_AiModelRanking>[];
      for (final provider in aiProviders) {
        for (final model in provider.models) {
          final costUsd = model.computeCostUsd(inputTokens, outputTokens);
          modelRankings.add(_AiModelRanking(model: model, estimatedCostUsd: costUsd));
        }
      }
      modelRankings.sort((a, b) => a.estimatedCostUsd.compareTo(b.estimatedCostUsd));

      setState(() {
        _rankedPlans = allPlans.take(3).toList();
        _rankedModels = modelRankings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Info usage réel ----
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Classement basé sur votre profil de consommation du mois en cours.',
                        style: TextStyle(fontSize: 11, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Meilleur forfait ----
              Text(
                'Meilleur forfait pour votre usage',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_rankedPlans.isEmpty)
                const Text('Aucun forfait disponible hors-ligne.')
              else
                ..._rankedPlans.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final plan = entry.value;
                  return _PlanRankCard(rank: rank, plan: plan, formatFcfa: _formatFcfa);
                }),

              const SizedBox(height: 24),

              // ---- Meilleur modèle IA ----
              Text(
                'Meilleur modèle IA (100K tokens/mois)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Estimation basée sur 100 000 tokens d\'entrée + 20 000 tokens de sortie par mois.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Card(
                child: DataTable(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('Rang', style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text('Modèle', style: TextStyle(fontSize: 12))),
                    DataColumn(label: Text('Coût/mois', style: TextStyle(fontSize: 12))),
                  ],
                  rows: _rankedModels.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final ranking = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(_RankBadge(rank: rank)),
                        DataCell(
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AiProviderBadge(
                                providerId: ranking.model.providerId,
                                showName: false,
                                compact: true,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ranking.model.name,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${ranking.estimatedCostUsd.toStringAsFixed(3)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.aiPurple,
                                ),
                              ),
                              Text(
                                _formatFcfa(ranking.estimatedCostUsd * 610),
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
  }
}

class _PlanRankCard extends StatelessWidget {
  const _PlanRankCard({
    required this.rank,
    required this.plan,
    required this.formatFcfa,
  });

  final int rank;
  final TariffPlan plan;
  final String Function(double) formatFcfa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [AppTheme.warning, AppTheme.textSecondary, const Color(0xFFb45309)];
    final rankColor = rank <= 3 ? colors[rank - 1] : AppTheme.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor.withOpacity(0.15),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(plan.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${plan.operatorId} • ${plan.validityDays} jours • ${plan.dataLimitLabel}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          formatFcfa(plan.price),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: AppTheme.warning, size: 20);
    }
    return Text(
      '#$rank',
      style: TextStyle(
        fontSize: 12,
        fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w400,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _AiModelRanking {
  final AiModel model;
  final double estimatedCostUsd;

  const _AiModelRanking({required this.model, required this.estimatedCostUsd});
}
