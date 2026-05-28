import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final operatorsForCountryProvider =
    FutureProvider.family<List<dynamic>, String>((ref, countryCode) async {
  return ref.read(apiClientProvider).getOperatorsForCountry(countryCode);
});

class OperatorsPage extends ConsumerWidget {
  final String countryCode;

  const OperatorsPage({super.key, required this.countryCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(operatorsForCountryProvider(countryCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Opérateurs — $countryCode',
          subtitle: 'Gérer les opérateurs et leurs forfaits',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/countries'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour aux pays'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showOperatorDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un opérateur'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Card(
              child: opsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(operatorsForCountryProvider(countryCode)),
                ),
                data: (ops) => DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('Nom'), size: ColumnSize.L),
                    DataColumn2(label: Text('USSD Solde'), size: ColumnSize.S),
                    DataColumn2(label: Text('USSD Data'), size: ColumnSize.S),
                    DataColumn2(label: Text('Forfaits'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M, numeric: true),
                  ],
                  rows: ops.map<DataRow>((op) {
                    final planCount = (op['tariff_plans'] as List?)?.length ?? 0;
                    return DataRow2(
                      cells: [
                        DataCell(Text(op['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(op['ussd_balance_code'] ?? '—', style: const TextStyle(fontFamily: 'monospace'))),
                        DataCell(Text(op['ussd_data_code'] ?? '—', style: const TextStyle(fontFamily: 'monospace'))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$planCount forfait${planCount > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        DataCell(_StatusBadge(active: op['is_active'] as bool)),
                        DataCell(Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Gérer les forfaits',
                              icon: const Icon(Icons.list_alt_outlined, size: 18),
                              onPressed: () => context.go('/operators/${op['id']}/tariffs'),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showOperatorDialog(context, ref, op),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                              onPressed: () => _deleteOperator(context, ref, op),
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
        ),
      ],
    );
  }

  Future<void> _showOperatorDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? operator,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _OperatorDialog(
        countryCode: countryCode,
        operator: operator,
        ref: ref,
      ),
    );
  }

  Future<void> _deleteOperator(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> op,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cet opérateur?',
      message: 'Supprimer ${op['name']} ? Tous les forfaits associés seront supprimés.',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteOperator(op['id']);
      ref.refresh(operatorsForCountryProvider(countryCode));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _OperatorDialog extends ConsumerStatefulWidget {
  final String countryCode;
  final Map<String, dynamic>? operator;
  final WidgetRef ref;

  const _OperatorDialog({required this.countryCode, this.operator, required this.ref});

  @override
  ConsumerState<_OperatorDialog> createState() => _OperatorDialogState();
}

class _OperatorDialogState extends ConsumerState<_OperatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _dataCtrl;
  late final TextEditingController _logoCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.operator != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.operator?['name'] ?? '');
    _balanceCtrl = TextEditingController(text: widget.operator?['ussd_balance_code'] ?? '');
    _dataCtrl = TextEditingController(text: widget.operator?['ussd_data_code'] ?? '');
    _logoCtrl = TextEditingController(text: widget.operator?['logo_url'] ?? '');
    _isActive = widget.operator?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _dataCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = widget.ref.read(apiClientProvider);
    try {
      if (_isEdit) {
        await client.updateOperator(widget.operator!['id'], {
          'name': _nameCtrl.text.trim(),
          'ussd_balance_code': _balanceCtrl.text.trim().isEmpty ? null : _balanceCtrl.text.trim(),
          'ussd_data_code': _dataCtrl.text.trim().isEmpty ? null : _dataCtrl.text.trim(),
          'logo_url': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
          'is_active': _isActive,
        });
      } else {
        await client.createOperator({
          'name': _nameCtrl.text.trim(),
          'country_code': widget.countryCode,
          'ussd_balance_code': _balanceCtrl.text.trim().isEmpty ? null : _balanceCtrl.text.trim(),
          'ussd_data_code': _dataCtrl.text.trim().isEmpty ? null : _dataCtrl.text.trim(),
          'logo_url': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
          'is_active': _isActive,
        });
      }
      widget.ref.refresh(operatorsForCountryProvider(widget.countryCode));
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
      title: Text(_isEdit ? 'Modifier l\'opérateur' : 'Ajouter un opérateur'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de l\'opérateur'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(labelText: 'USSD Solde (ex: #124#)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dataCtrl,
                decoration: const InputDecoration(labelText: 'USSD Data (ex: *150*1#)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logoCtrl,
                decoration: const InputDecoration(labelText: 'URL du logo (optionnel)'),
              ),
              const SizedBox(height: 8),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
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
