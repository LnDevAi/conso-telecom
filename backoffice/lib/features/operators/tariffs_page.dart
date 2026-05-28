import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final plansProvider =
    FutureProvider.family<List<dynamic>, String>((ref, operatorId) async {
  return ref.read(apiClientProvider).getPlansForOperator(operatorId);
});

final unitTariffsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, operatorId) async {
  return ref.read(apiClientProvider).getUnitTariffsForOperator(operatorId);
});

const _planTypes = ['DATA', 'VOICE', 'SMS', 'COMBO'];
const _resourceTypes = [
  'DATA_MB',
  'CALL_ONNET_MIN',
  'CALL_OFFNET_MIN',
  'CALL_INTL_MIN',
  'SMS_ONNET',
  'SMS_OFFNET',
];

class TariffsPage extends ConsumerStatefulWidget {
  final String operatorId;

  const TariffsPage({super.key, required this.operatorId});

  @override
  ConsumerState<TariffsPage> createState() => _TariffsPageState();
}

class _TariffsPageState extends ConsumerState<TariffsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Tarifs',
          subtitle: 'Forfaits et tarifs unitaires de l\'opérateur',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/countries'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Forfaits'),
              Tab(text: 'Tarifs unitaires'),
            ],
            isScrollable: true,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PlansTab(operatorId: widget.operatorId, ref: ref),
              _UnitTariffsTab(operatorId: widget.operatorId, ref: ref),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlansTab extends StatelessWidget {
  final String operatorId;
  final WidgetRef ref;

  const _PlansTab({required this.operatorId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider(operatorId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showPlanDialog(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un forfait'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: plansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(plansProvider(operatorId)),
                ),
                data: (plans) => DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('Nom'), size: ColumnSize.L),
                    DataColumn2(label: Text('Type'), size: ColumnSize.S),
                    DataColumn2(label: Text('Data (Mo)'), size: ColumnSize.S),
                    DataColumn2(label: Text('Prix'), size: ColumnSize.S),
                    DataColumn2(label: Text('Validité'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: plans.map<DataRow>((p) {
                    return DataRow2(
                      cells: [
                        DataCell(Text(p['name'])),
                        DataCell(_TypeBadge(type: p['plan_type'])),
                        DataCell(Text(p['data_limit_mb']?.toString() ?? '—')),
                        DataCell(Text('${p['price']} ${p['currency']}')),
                        DataCell(Text('${p['validity_days']}j')),
                        DataCell(_StatusBadge(active: p['is_active'] as bool)),
                        DataCell(Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showPlanDialog(context, p),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                              onPressed: () => _deletePlan(context, p),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlanDialog(BuildContext context, Map<String, dynamic>? plan) async {
    await showDialog(
      context: context,
      builder: (ctx) => _PlanDialog(operatorId: operatorId, plan: plan, ref: ref),
    );
  }

  Future<void> _deletePlan(BuildContext context, Map<String, dynamic> plan) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ce forfait?',
      message: 'Supprimer "${plan['name']}" ?',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deletePlan(operatorId, plan['id']);
      ref.refresh(plansProvider(operatorId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _UnitTariffsTab extends StatelessWidget {
  final String operatorId;
  final WidgetRef ref;

  const _UnitTariffsTab({required this.operatorId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final utAsync = ref.watch(unitTariffsProvider(operatorId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showUnitDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un tarif unitaire'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: utAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(unitTariffsProvider(operatorId)),
                ),
                data: (uts) => DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('Type de ressource'), size: ColumnSize.L),
                    DataColumn2(label: Text('Prix unitaire'), size: ColumnSize.M),
                    DataColumn2(label: Text('Devise'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: uts.map<DataRow>((ut) {
                    return DataRow2(
                      cells: [
                        DataCell(Text(_labelForType(ut['resource_type']))),
                        DataCell(Text(ut['price'].toString())),
                        DataCell(Text(ut['currency'])),
                        DataCell(_StatusBadge(active: ut['is_active'] as bool)),
                        DataCell(
                          IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                            onPressed: () => _deleteUt(context, ut),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForType(String type) {
    const labels = {
      'DATA_MB': 'Data hors forfait (par Mo)',
      'CALL_ONNET_MIN': 'Appel on-net (par min)',
      'CALL_OFFNET_MIN': 'Appel off-net (par min)',
      'CALL_INTL_MIN': 'Appel international (par min)',
      'SMS_ONNET': 'SMS on-net',
      'SMS_OFFNET': 'SMS off-net',
    };
    return labels[type] ?? type;
  }

  Future<void> _showUnitDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => _UnitTariffDialog(operatorId: operatorId, ref: ref),
    );
  }

  Future<void> _deleteUt(BuildContext context, Map<String, dynamic> ut) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ce tarif?',
      message: 'Supprimer le tarif ${_labelForType(ut['resource_type'])} ?',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteUnitTariff(operatorId, ut['id']);
      ref.refresh(unitTariffsProvider(operatorId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _PlanDialog extends ConsumerStatefulWidget {
  final String operatorId;
  final Map<String, dynamic>? plan;
  final WidgetRef ref;

  const _PlanDialog({required this.operatorId, this.plan, required this.ref});

  @override
  ConsumerState<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends ConsumerState<_PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _validityCtrl;
  late final TextEditingController _dataMbCtrl;
  late final TextEditingController _voiceCtrl;
  late final TextEditingController _smsCtrl;
  String _planType = 'DATA';
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.plan != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.plan?['name'] ?? '');
    _priceCtrl = TextEditingController(text: widget.plan?['price']?.toString() ?? '');
    _validityCtrl = TextEditingController(text: widget.plan?['validity_days']?.toString() ?? '30');
    _dataMbCtrl = TextEditingController(text: widget.plan?['data_limit_mb']?.toString() ?? '');
    _voiceCtrl = TextEditingController(text: widget.plan?['voice_limit_minutes']?.toString() ?? '');
    _smsCtrl = TextEditingController(text: widget.plan?['sms_limit']?.toString() ?? '');
    _planType = widget.plan?['plan_type'] ?? 'DATA';
    _isActive = widget.plan?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _validityCtrl.dispose();
    _dataMbCtrl.dispose();
    _voiceCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = widget.ref.read(apiClientProvider);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'plan_type': _planType,
        'price': double.parse(_priceCtrl.text),
        'currency': 'XOF',
        'validity_days': int.parse(_validityCtrl.text),
        'is_active': _isActive,
        'operator_id': widget.operatorId,
        if (_dataMbCtrl.text.isNotEmpty) 'data_limit_mb': int.parse(_dataMbCtrl.text),
        if (_voiceCtrl.text.isNotEmpty) 'voice_limit_minutes': int.parse(_voiceCtrl.text),
        if (_smsCtrl.text.isNotEmpty) 'sms_limit': int.parse(_smsCtrl.text),
      };
      if (_isEdit) {
        await client.updatePlan(widget.operatorId, widget.plan!['id'], data);
      } else {
        await client.createPlan(widget.operatorId, data);
      }
      widget.ref.refresh(plansProvider(widget.operatorId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier le forfait' : 'Ajouter un forfait'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom du forfait'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _planType,
                  decoration: const InputDecoration(labelText: 'Type de forfait'),
                  items: _planTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _planType = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validityCtrl,
                        decoration: const InputDecoration(labelText: 'Validité (jours)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dataMbCtrl,
                  decoration: const InputDecoration(labelText: 'Limite data (Mo, optionnel)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _voiceCtrl,
                  decoration: const InputDecoration(labelText: 'Limite voix (min, optionnel)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _smsCtrl,
                  decoration: const InputDecoration(labelText: 'Limite SMS (optionnel)'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Actif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}

class _UnitTariffDialog extends ConsumerStatefulWidget {
  final String operatorId;
  final WidgetRef ref;

  const _UnitTariffDialog({required this.operatorId, required this.ref});

  @override
  ConsumerState<_UnitTariffDialog> createState() => _UnitTariffDialogState();
}

class _UnitTariffDialogState extends ConsumerState<_UnitTariffDialog> {
  final _formKey = GlobalKey<FormState>();
  String _resourceType = 'DATA_MB';
  final _priceCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.ref.read(apiClientProvider).createUnitTariff(widget.operatorId, {
        'resource_type': _resourceType,
        'price': double.parse(_priceCtrl.text),
        'currency': 'XOF',
        'operator_id': widget.operatorId,
      });
      widget.ref.refresh(unitTariffsProvider(widget.operatorId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un tarif unitaire'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _resourceType,
                decoration: const InputDecoration(labelText: 'Type de ressource'),
                items: _resourceTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _resourceType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Créer'),
        ),
      ],
    );
  }
}

// ── Shared badges ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Actif' : 'Inactif',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  static const _colors = {
    'DATA': Color(0xFF1565C0),
    'VOICE': Color(0xFF2E7D32),
    'SMS': Color(0xFF6A1B9A),
    'COMBO': Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
