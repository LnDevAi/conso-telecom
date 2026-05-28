import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/models/ai_api_key.dart';
import '../../core/database/isar_service.dart';
import '../../shared/widgets/ai_provider_badge.dart';
import '../ai_tokens/ai_tokens_provider.dart';
import '../ai_tokens/ai_key_manager.dart';

class AiKeysPage extends ConsumerStatefulWidget {
  const AiKeysPage({super.key});

  @override
  ConsumerState<AiKeysPage> createState() => _AiKeysPageState();
}

class _AiKeysPageState extends ConsumerState<AiKeysPage> {
  void _showAddKeySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddKeySheet(onSaved: () {
        ref.invalidate(aiApiKeysProvider);
      }),
    );
  }

  Future<void> _testKey(AiApiKey key) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test de la clé en cours...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final decrypted = await AiKeyManager.decryptKey(key.encryptedKey);
      final isValid = AiKeyManager.validateKeyFormat(key.providerId, decrypted);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValid ? 'Format de clé valide' : 'Format de clé invalide'),
            backgroundColor: isValid ? AppTheme.success : AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteKey(AiApiKey key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la clé'),
        content: Text('Supprimer la clé "${key.label}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.aiApiKeys.delete(key.id);
      });
      ref.invalidate(aiApiKeysProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(aiApiKeysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clés API IA')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddKeySheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Avertissement sécurité
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock, color: AppTheme.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stockage sécurisé local',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Vos clés API sont chiffrées avec AES-256 et stockées uniquement sur votre appareil. '
                        'Elles ne sont jamais transmises à un serveur externe.',
                        style: TextStyle(color: AppTheme.success, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: keysAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (keys) {
                if (keys.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune clé API enregistrée.\nAppuyez sur + pour ajouter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return _KeyCard(
                      apiKey: key,
                      onTest: () => _testKey(key),
                      onDelete: () => _deleteKey(key),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.apiKey,
    required this.onTest,
    required this.onDelete,
  });

  final AiApiKey apiKey;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiProviderBadge(providerId: apiKey.providerId),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.danger,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(apiKey.label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Clé: ${apiKey.maskedKey}',
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 4),
          Text(
            'Créée le ${DateFormat('dd/MM/yyyy').format(apiKey.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (apiKey.lastUsedAt != null)
            Text(
              'Dernière utilisation: ${DateFormat('dd/MM/yyyy HH:mm').format(apiKey.lastUsedAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onTest,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Tester'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddKeySheet extends StatefulWidget {
  const _AddKeySheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_AddKeySheet> createState() => _AddKeySheetState();
}

class _AddKeySheetState extends State<_AddKeySheet> {
  final _keyController = TextEditingController();
  final _labelController = TextEditingController();
  String _providerId = 'anthropic';
  bool _obscure = true;
  bool _saving = false;

  final _providers = [
    {'id': 'anthropic', 'name': 'Anthropic (Claude)'},
    {'id': 'openai', 'name': 'OpenAI (ChatGPT)'},
    {'id': 'google', 'name': 'Google (Gemini)'},
    {'id': 'mistral', 'name': 'Mistral AI'},
  ];

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _keyController.text.trim();
    final label = _labelController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une clé API')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final encrypted = await AiKeyManager.encryptKey(key);
      final isar = IsarService.instance;
      final apiKey = AiApiKey.create(
        providerId: _providerId,
        encryptedKey: encrypted,
        label: label.isEmpty ? '$_providerId clé' : label,
      );
      await isar.writeTxn(() async {
        await isar.aiApiKeys.put(apiKey);
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          Text('Nouvelle clé API', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _providerId,
            decoration: const InputDecoration(labelText: 'Fournisseur'),
            items: _providers.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!))).toList(),
            onChanged: (v) => setState(() => _providerId = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Étiquette (optionnel)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Clé API',
              hintText: 'sk-ant-... / sk-...',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
