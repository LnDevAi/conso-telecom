import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final exchangeRatesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiClientProvider).getExchangeRates();
});

final _rateFmt = NumberFormat('#,##0.000000', 'fr_FR');
final _dateFmt = DateFormat('dd/MM/yyyy');

class ExchangeRatesPage extends ConsumerStatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  ConsumerState<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends ConsumerState<ExchangeRatesPage> {
  bool _isRefreshing = false;

  Future<void> _autoRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      final result = await ref.read(apiClientProvider).refreshExchangeRates();
      ref.refresh(exchangeRatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.length} taux mis à jour depuis open.er-api.com'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Taux de change',
          subtitle: 'Gérer les taux de conversion de devises',
          actions: [
            OutlinedButton.icon(
              onPressed: _isRefreshing ? null : _autoRefresh,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: const Text('Synchroniser les taux'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddRateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un taux'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Card(
              child: ratesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(exchangeRatesProvider),
                ),
                data: (rates) => DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('De'), size: ColumnSize.S),
                    DataColumn2(label: Text('Vers'), size: ColumnSize.S),
                    DataColumn2(label: Text('Taux'), size: ColumnSize.L),
                    DataColumn2(label: Text('Source'), size: ColumnSize.M),
                    DataColumn2(label: Text('Date effet'), size: ColumnSize.M),
                    DataColumn2(label: Text('Créé le'), size: ColumnSize.M),
                  ],
                  rows: rates.map<DataRow>((r) {
                    return DataRow2(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r['from_currency'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r['to_currency'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          r['rate'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(r['source'] ?? '—', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(r['effective_date'] ?? '—')),
                        DataCell(Text(
                          r['created_at'] != null
                              ? _formatDate(r['created_at'])
                              : '—',
                          style: const TextStyle(fontSize: 12),
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showAddRateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => _AddRateDialog(onAdded: () => ref.refresh(exchangeRatesProvider)),
    );
  }
}

class _AddRateDialog extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddRateDialog({required this.onAdded});

  @override
  ConsumerState<_AddRateDialog> createState() => _AddRateDialogState();
}

class _AddRateDialogState extends ConsumerState<_AddRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'manual');
  DateTime _effectiveDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _rateCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(apiClientProvider).createExchangeRate({
        'from_currency': _fromCtrl.text.trim().toUpperCase(),
        'to_currency': _toCtrl.text.trim().toUpperCase(),
        'rate': double.parse(_rateCtrl.text),
        'source': _sourceCtrl.text.trim(),
        'effective_date': DateFormat('yyyy-MM-dd').format(_effectiveDate),
      });
      widget.onAdded();
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
      title: const Text('Ajouter un taux de change'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromCtrl,
                      decoration: const InputDecoration(labelText: 'De (ex: USD)'),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _toCtrl,
                      decoration: const InputDecoration(labelText: 'Vers (ex: XOF)'),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateCtrl,
                decoration: const InputDecoration(labelText: 'Taux de conversion'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceCtrl,
                decoration: const InputDecoration(labelText: 'Source'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Date d\'effet: ${DateFormat('dd/MM/yyyy').format(_effectiveDate)}',
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _effectiveDate = picked);
                },
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
