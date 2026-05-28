import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final countriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiClientProvider).getCountries();
});

class CountriesPage extends ConsumerWidget {
  const CountriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Pays',
          subtitle: 'Gérer les pays et leurs opérateurs télécom',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCountryDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un pays'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Card(
              child: countriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(countriesProvider),
                ),
                data: (countries) => DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('Code'), size: ColumnSize.S),
                    DataColumn2(label: Text('Nom (FR)'), size: ColumnSize.L),
                    DataColumn2(label: Text('Nom (EN)'), size: ColumnSize.L),
                    DataColumn2(label: Text('Devise'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M, numeric: true),
                  ],
                  rows: countries.map<DataRow>((c) {
                    return DataRow2(
                      cells: [
                        DataCell(Text(c['code'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(c['name_fr'])),
                        DataCell(Text(c['name_en'])),
                        DataCell(Text(c['default_currency'])),
                        DataCell(_StatusBadge(active: c['is_active'] as bool)),
                        DataCell(Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Voir opérateurs',
                              icon: const Icon(Icons.cell_tower_outlined, size: 18),
                              onPressed: () => context.go('/countries/${c['code']}/operators'),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showCountryDialog(context, ref, c),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                              onPressed: () => _deleteCountry(context, ref, c),
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

  Future<void> _showCountryDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? country,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _CountryDialog(country: country, ref: ref),
    );
  }

  Future<void> _deleteCountry(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> country,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ce pays?',
      message: 'Supprimer ${country['name_fr']} (${country['code']}) ? Cette action supprimera également tous les opérateurs associés.',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteCountry(country['code']);
      ref.refresh(countriesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _CountryDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? country;
  final WidgetRef ref;

  const _CountryDialog({this.country, required this.ref});

  @override
  ConsumerState<_CountryDialog> createState() => _CountryDialogState();
}

class _CountryDialogState extends ConsumerState<_CountryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameFrCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _currencyCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.country != null;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.country?['code'] ?? '');
    _nameFrCtrl = TextEditingController(text: widget.country?['name_fr'] ?? '');
    _nameEnCtrl = TextEditingController(text: widget.country?['name_en'] ?? '');
    _currencyCtrl = TextEditingController(text: widget.country?['default_currency'] ?? 'XOF');
    _isActive = widget.country?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameFrCtrl.dispose();
    _nameEnCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = widget.ref.read(apiClientProvider);
    try {
      if (_isEdit) {
        await client.updateCountry(widget.country!['code'], {
          'name_fr': _nameFrCtrl.text.trim(),
          'name_en': _nameEnCtrl.text.trim(),
          'default_currency': _currencyCtrl.text.trim().toUpperCase(),
          'is_active': _isActive,
        });
      } else {
        await client.createCountry({
          'code': _codeCtrl.text.trim().toUpperCase(),
          'name_fr': _nameFrCtrl.text.trim(),
          'name_en': _nameEnCtrl.text.trim(),
          'default_currency': _currencyCtrl.text.trim().toUpperCase(),
          'is_active': _isActive,
        });
      }
      widget.ref.refresh(countriesProvider);
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
      title: Text(_isEdit ? 'Modifier le pays' : 'Ajouter un pays'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEdit)
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code ISO (ex: BF)'),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              if (!_isEdit) const SizedBox(height: 12),
              TextFormField(
                controller: _nameFrCtrl,
                decoration: const InputDecoration(labelText: 'Nom en français'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEnCtrl,
                decoration: const InputDecoration(labelText: 'Nom en anglais'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyCtrl,
                decoration: const InputDecoration(labelText: 'Devise (ex: XOF)'),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
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
