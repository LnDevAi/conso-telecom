import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/page_header.dart';

final aiProvidersProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiClientProvider).getAiProviders();
});

class AiProvidersPage extends ConsumerWidget {
  const AiProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(aiProvidersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Fournisseurs IA',
          subtitle: 'Gérer les fournisseurs d\'IA et leurs modèles avec tarification',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showProviderDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un fournisseur'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Card(
              child: providersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(aiProvidersProvider),
                ),
                data: (providers) => DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn2(label: Text('ID'), size: ColumnSize.S),
                    DataColumn2(label: Text('Nom'), size: ColumnSize.L),
                    DataColumn2(label: Text('Site web'), size: ColumnSize.L),
                    DataColumn2(label: Text('Modèles'), size: ColumnSize.S),
                    DataColumn2(label: Text('Statut'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.M, numeric: true),
                  ],
                  rows: providers.map<DataRow>((p) {
                    final modelCount = (p['models'] as List?)?.length ?? 0;
                    return DataRow2(
                      cells: [
                        DataCell(Text(p['id'], style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
                        DataCell(Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(
                          p['website'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                          overflow: TextOverflow.ellipsis,
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAF6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$modelCount modèle${modelCount > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF3949AB), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        DataCell(_StatusBadge(active: p['is_active'] as bool)),
                        DataCell(Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Gérer les modèles',
                              icon: const Icon(Icons.psychology_outlined, size: 18),
                              onPressed: () => context.go('/ai-providers/${p['id']}/models'),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showProviderDialog(context, ref, p),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                              onPressed: () => _deleteProvider(context, ref, p),
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

  Future<void> _showProviderDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? provider,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ProviderDialog(provider: provider, ref: ref),
    );
  }

  Future<void> _deleteProvider(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> p,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer ce fournisseur?',
      message: 'Supprimer ${p['name']} ? Tous les modèles associés seront supprimés.',
    );
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteAiProvider(p['id']);
      ref.refresh(aiProvidersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _ProviderDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? provider;
  final WidgetRef ref;

  const _ProviderDialog({this.provider, required this.ref});

  @override
  ConsumerState<_ProviderDialog> createState() => _ProviderDialogState();
}

class _ProviderDialogState extends ConsumerState<_ProviderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _apiEndpointCtrl;
  late final TextEditingController _apiDocCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.provider != null;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.provider?['id'] ?? '');
    _nameCtrl = TextEditingController(text: widget.provider?['name'] ?? '');
    _websiteCtrl = TextEditingController(text: widget.provider?['website'] ?? '');
    _apiEndpointCtrl = TextEditingController(text: widget.provider?['usage_api_endpoint'] ?? '');
    _apiDocCtrl = TextEditingController(text: widget.provider?['usage_api_doc_url'] ?? '');
    _isActive = widget.provider?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _websiteCtrl.dispose();
    _apiEndpointCtrl.dispose();
    _apiDocCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = widget.ref.read(apiClientProvider);
    try {
      if (_isEdit) {
        await client.updateAiProvider(widget.provider!['id'], {
          'name': _nameCtrl.text.trim(),
          'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
          'usage_api_endpoint': _apiEndpointCtrl.text.trim().isEmpty ? null : _apiEndpointCtrl.text.trim(),
          'usage_api_doc_url': _apiDocCtrl.text.trim().isEmpty ? null : _apiDocCtrl.text.trim(),
          'is_active': _isActive,
        });
      } else {
        await client.createAiProvider({
          'id': _idCtrl.text.trim().toLowerCase(),
          'name': _nameCtrl.text.trim(),
          'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
          'usage_api_endpoint': _apiEndpointCtrl.text.trim().isEmpty ? null : _apiEndpointCtrl.text.trim(),
          'usage_api_doc_url': _apiDocCtrl.text.trim().isEmpty ? null : _apiDocCtrl.text.trim(),
          'is_active': _isActive,
        });
      }
      widget.ref.refresh(aiProvidersProvider);
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
      title: Text(_isEdit ? 'Modifier le fournisseur' : 'Ajouter un fournisseur IA'),
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
                  decoration: const InputDecoration(labelText: 'ID (slug, ex: anthropic)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                ),
              if (!_isEdit) const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(labelText: 'Site web (optionnel)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apiEndpointCtrl,
                decoration: const InputDecoration(labelText: 'Endpoint API usage (optionnel)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apiDocCtrl,
                decoration: const InputDecoration(labelText: 'URL doc API (optionnel)'),
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
