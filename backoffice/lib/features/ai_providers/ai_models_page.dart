import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final aiModelsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, providerId) async {
  return ref.read(apiClientProvider).getAiModels(providerId);
});

final _usdFmt = NumberFormat('\$#,##0.000000', 'en_US');

class AiModelsPage extends ConsumerWidget {
  final String providerId;

  const AiModelsPage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(aiModelsProvider(providerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Modèles IA — $providerId',
          subtitle: 'Gérer les modèles et leur tarification (USD/MTok)',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/ai-providers'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showModelDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un modèle'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Card(
              child: modelsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(aiModelsProvider(providerId)),
                ),
                data: (models) => DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('ID / Slug'), size: ColumnSize.M),
                    DataColumn2(label: Text('Nom'), size: ColumnSize.L),
                    DataColumn2(label: Text('Input (\$/MTok)'), size: ColumnSize.M),
                    DataColumn2(label: Text('Output (\$/MTok)'), size: ColumnSize.M),
                    DataColumn2(label: Text('Fenêtre ctx'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: models.map<DataRow>((m) {
                    return DataRow2(
                      cells: [
                        DataCell(Text(m['id'], style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                        DataCell(Text(m['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(
                          '\$${m['input_price_per_mtok_usd']}',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          '\$${m['output_price_per_mtok_usd']}',
                          style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          m['context_window'] != null
                              ? _formatCtx(m['context_window'] as int)
                              : '—',
                          style: const TextStyle(fontSize: 12),
                        )),
                        DataCell(_StatusBadge(active: m['is_active'] as bool)),
                        DataCell(Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showModelDialog(context, ref, m),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                              onPressed: () => _deleteModel(context, ref, m),
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

  String _formatCtx(int ctx) {
    if (ctx >= 1000000) return '${ctx ~/ 1000000}M';
    if (ctx >= 1000) return '${ctx ~/ 1000}k';
    return ctx.toString();
  }

  Future<void> _showModelDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? model,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ModelDialog(providerId: providerId, model: model, ref: ref),
    );
  }

  Future<void> _deleteModel(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> m,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ce modèle?',
      message: 'Supprimer ${m['name']} (${m['id']}) ?',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteAiModel(providerId, m['id']);
      ref.refresh(aiModelsProvider(providerId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _ModelDialog extends ConsumerStatefulWidget {
  final String providerId;
  final Map<String, dynamic>? model;
  final WidgetRef ref;

  const _ModelDialog({required this.providerId, this.model, required this.ref});

  @override
  ConsumerState<_ModelDialog> createState() => _ModelDialogState();
}

class _ModelDialogState extends ConsumerState<_ModelDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _inputPriceCtrl;
  late final TextEditingController _outputPriceCtrl;
  late final TextEditingController _ctxCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.model != null;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.model?['id'] ?? '');
    _nameCtrl = TextEditingController(text: widget.model?['name'] ?? '');
    _inputPriceCtrl = TextEditingController(text: widget.model?['input_price_per_mtok_usd']?.toString() ?? '');
    _outputPriceCtrl = TextEditingController(text: widget.model?['output_price_per_mtok_usd']?.toString() ?? '');
    _ctxCtrl = TextEditingController(text: widget.model?['context_window']?.toString() ?? '');
    _isActive = widget.model?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _inputPriceCtrl.dispose();
    _outputPriceCtrl.dispose();
    _ctxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = widget.ref.read(apiClientProvider);
    try {
      final data = {
        'id': _idCtrl.text.trim(),
        'provider_id': widget.providerId,
        'name': _nameCtrl.text.trim(),
        'input_price_per_mtok_usd': double.parse(_inputPriceCtrl.text),
        'output_price_per_mtok_usd': double.parse(_outputPriceCtrl.text),
        if (_ctxCtrl.text.isNotEmpty) 'context_window': int.parse(_ctxCtrl.text),
        'is_active': _isActive,
      };
      if (_isEdit) {
        await client.updateAiModel(widget.providerId, widget.model!['id'], data);
      } else {
        await client.createAiModel(widget.providerId, data);
      }
      widget.ref.refresh(aiModelsProvider(widget.providerId));
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
      title: Text(_isEdit ? 'Modifier le modèle' : 'Ajouter un modèle IA'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEdit)
                TextFormField(
                  controller: _idCtrl,
                  decoration: const InputDecoration(labelText: 'ID slug (ex: claude-sonnet-4-6)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              if (!_isEdit) const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom affiché'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inputPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Input (USD/MTok)',
                        hintText: 'ex: 3.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _outputPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Output (USD/MTok)',
                        hintText: 'ex: 15.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctxCtrl,
                decoration: const InputDecoration(labelText: 'Fenêtre de contexte (tokens, optionnel)'),
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
