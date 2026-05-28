import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/models/plan.dart';
import '../../shared/widgets/consumption_bar.dart';
import 'plans_provider.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final notifier = ref.read(planNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Forfaits')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text(
                'Aucun forfait.\nAppuyez sur + pour ajouter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _PlanCard(
                plan: plan,
                formatFcfa: _formatFcfa,
                onUssd: () => notifier.dialUssdBalance(plan.operatorId),
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer le forfait'),
                      content: Text('Supprimer "${plan.name}" ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await notifier.deletePlan(plan.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddPlanSheet(ref: ref),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.formatFcfa,
    required this.onUssd,
    required this.onDelete,
  });

  final Plan plan;
  final String Function(double) formatFcfa;
  final VoidCallback onUssd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = plan.isExpired;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? AppTheme.danger.withOpacity(0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _PlanTypeBadge(planType: plan.planType),
              const SizedBox(width: 8),
              if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Expiré', style: TextStyle(color: AppTheme.danger, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.operatorId} • SIM ${plan.simSlot + 1} • ${formatFcfa(plan.priceFcfa)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (plan.isDataPlan && plan.dataLimitMb != null)
            ConsumptionBar(
              title: 'Données',
              used: 0, // Sera connecté au DataRecord
              total: plan.dataLimitMb!,
              usedLabel: '0 Mo',
              remainingLabel: plan.dataLimitMb! >= 1024
                  ? '${(plan.dataLimitMb! / 1024).toStringAsFixed(1)} Go'
                  : '${plan.dataLimitMb!.toStringAsFixed(0)} Mo',
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: isExpired ? AppTheme.danger : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Expire le ${DateFormat('dd/MM/yyyy').format(plan.expiryDate)} • ${plan.daysRemaining} j',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isExpired ? AppTheme.danger : AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onUssd,
                icon: const Icon(Icons.dialpad, size: 14),
                label: const Text('USSD', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.danger,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanTypeBadge extends StatelessWidget {
  const _PlanTypeBadge({required this.planType});

  final String planType;

  Color get _color {
    switch (planType) {
      case 'DATA':
        return AppTheme.primary;
      case 'VOICE':
        return AppTheme.success;
      case 'SMS':
        return AppTheme.warning;
      case 'COMBO':
        return AppTheme.aiPurple;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        planType,
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _dataController = TextEditingController();
  final _voiceController = TextEditingController();

  String _operatorId = 'orange_bf';
  String _planType = 'DATA';
  int _simSlot = 0;
  int _validityDays = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _dataController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final dataMb = double.tryParse(_dataController.text);
    final voiceMin = double.tryParse(_voiceController.text);

    if (name.isEmpty || price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et prix requis')),
      );
      return;
    }

    final now = DateTime.now();
    final plan = Plan.create(
      name: name,
      operatorId: _operatorId,
      planType: _planType,
      dataLimitMb: dataMb,
      voiceLimitMinutes: voiceMin,
      priceFcfa: price,
      validityDays: _validityDays,
      startDate: now,
      expiryDate: now.add(Duration(days: _validityDays)),
      simSlot: _simSlot,
    );

    await widget.ref.read(planNotifierProvider.notifier).addPlan(plan);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajouter un forfait', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom du forfait')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _planType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['DATA', 'VOICE', 'SMS', 'COMBO'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _planType = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _simSlot,
                  decoration: const InputDecoration(labelText: 'SIM'),
                  items: [0, 1].map((s) => DropdownMenuItem(value: s, child: Text('SIM ${s + 1}'))).toList(),
                  onChanged: (v) => setState(() => _simSlot = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _dataController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Data (Mo)', hintText: 'Optionnel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _voiceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutes voix (optionnel)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Enregistrer le forfait'),
            ),
          ),
        ],
      ),
    );
  }
}
