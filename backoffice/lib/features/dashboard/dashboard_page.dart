import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/error_view.dart';

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(apiClientProvider).getDashboardStats();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Tableau de bord',
            subtitle: 'Vue d\'ensemble de la plateforme ConsoTélécom',
          ),
          const SizedBox(height: 32),
          statsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            )),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(dashboardStatsProvider),
              ),
            ),
            data: (stats) => Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats grid
                  LayoutBuilder(builder: (context, constraints) {
                    final crossAxis = constraints.maxWidth > 800 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxis,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.8,
                      children: [
                        _StatCard(
                          icon: Icons.flag_outlined,
                          label: 'Pays',
                          value: stats['countries'] ?? 0,
                          color: const Color(0xFF1565C0),
                          route: '/countries',
                        ),
                        _StatCard(
                          icon: Icons.cell_tower_outlined,
                          label: 'Opérateurs',
                          value: stats['operators'] ?? 0,
                          color: const Color(0xFF2E7D32),
                          route: '/countries',
                        ),
                        _StatCard(
                          icon: Icons.smart_toy_outlined,
                          label: 'Fournisseurs IA',
                          value: stats['ai_providers'] ?? 0,
                          color: const Color(0xFF6A1B9A),
                          route: '/ai-providers',
                        ),
                        _StatCard(
                          icon: Icons.currency_exchange_outlined,
                          label: 'Taux de change',
                          value: stats['exchange_rates'] ?? 0,
                          color: const Color(0xFFE65100),
                          route: '/exchange-rates',
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),

                  // Quick actions
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        icon: Icons.add,
                        label: 'Ajouter un pays',
                        onTap: () => context.go('/countries'),
                      ),
                      _QuickAction(
                        icon: Icons.add_business_outlined,
                        label: 'Ajouter un opérateur',
                        onTap: () => context.go('/countries'),
                      ),
                      _QuickAction(
                        icon: Icons.psychology_outlined,
                        label: 'Ajouter un modèle IA',
                        onTap: () => context.go('/ai-providers'),
                      ),
                      _QuickAction(
                        icon: Icons.sync_outlined,
                        label: 'Synchroniser les taux',
                        onTap: () => context.go('/exchange-rates'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String route;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
