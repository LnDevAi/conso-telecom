import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/models/ai_usage_record.dart';
import '../../core/database/isar_service.dart';
import '../../shared/widgets/ai_provider_badge.dart';
import 'ai_tokens_provider.dart';
import 'ai_key_manager.dart';

class AiTokensPage extends ConsumerStatefulWidget {
  const AiTokensPage({super.key});

  @override
  ConsumerState<AiTokensPage> createState() => _AiTokensPageState();
}

class _AiTokensPageState extends ConsumerState<AiTokensPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatFcfa(double amount) {
    final fmt = NumberFormat('#,###', 'fr_BF');
    return '${fmt.format(amount.round())} FCFA';
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1_000_000) return '${(tokens / 1_000_000).toStringAsFixed(2)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return tokens.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tokens IA'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Par fournisseur'),
            Tab(text: 'Importer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(formatFcfa: _formatFcfa, formatTokens: _formatTokens),
          _ByProviderTab(formatFcfa: _formatFcfa, formatTokens: _formatTokens),
          const _ImportTab(),
        ],
      ),
    );
  }
}

// ─── Tab Résumé ──────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.formatFcfa, required this.formatTokens});

  final String Function(double) formatFcfa;
  final String Function(int) formatTokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(aiUsageSummaryProvider);
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (summary) {
        if (summary.totalTokens == 0) {
          return const Center(
            child: Text(
              'Aucune donnée IA ce mois.\nImportez ou saisissez vos données.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Totaux
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.aiPurple, Color(0xFF6d28d9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total tokens ce mois',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTokens(summary.totalTokens),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TokenStat(
                          label: 'Entrée',
                          value: formatTokens(summary.totalInputTokens),
                        ),
                      ),
                      Expanded(
                        child: _TokenStat(
                          label: 'Sortie',
                          value: formatTokens(summary.totalOutputTokens),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Text(
                    formatFcfa(summary.totalCostLocal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '≈ \$${summary.totalCostUsd.toStringAsFixed(4)} USD',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Camembert par fournisseur
            if (summary.byProvider.isNotEmpty) ...[
              Text(
                'Répartition par fournisseur',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: summary.byProvider.entries.toList().asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final ratio = summary.totalTokens > 0
                          ? entry.value.totalTokens / summary.totalTokens
                          : 0.0;
                      return PieChartSectionData(
                        color: AppTheme.chartColors[idx % AppTheme.chartColors.length],
                        value: entry.value.totalTokens.toDouble(),
                        title: '${(ratio * 100).toStringAsFixed(0)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 0,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: summary.byProvider.entries.toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.chartColors[idx % AppTheme.chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(entry.key, style: theme.textTheme.bodySmall),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Meilleur modèle
            if (summary.topModelId != null) ...[
              Text(
                'Modèle le plus utilisé',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: AiProviderBadge(
                    providerId: summary.topProviderId ?? '',
                    showName: false,
                  ),
                  title: Text(summary.topModelId!),
                  subtitle: Text(summary.topProviderId ?? ''),
                  trailing: const Icon(Icons.star, color: AppTheme.warning),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TokenStat extends StatelessWidget {
  const _TokenStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Tab Par fournisseur ──────────────────────────────────────────────────────

class _ByProviderTab extends ConsumerWidget {
  const _ByProviderTab({required this.formatFcfa, required this.formatTokens});

  final String Function(double) formatFcfa;
  final String Function(int) formatTokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(aiUsageSummaryProvider);
    final theme = Theme.of(context);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (summary) {
        if (summary.byProvider.isEmpty) {
          return const Center(
            child: Text('Aucune donnée.', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: summary.byProvider.values.map((ps) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: AiProviderBadge(providerId: ps.providerId, showName: false),
                title: Text(ps.providerId, style: theme.textTheme.titleSmall),
                subtitle: Text(
                  '${formatTokens(ps.totalTokens)} tokens • ${formatFcfa(ps.costLocal)}',
                  style: theme.textTheme.bodySmall,
                ),
                children: ps.byModel.values.map((ms) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    title: Text(ms.modelId, style: theme.textTheme.bodyMedium),
                    subtitle: Text(
                      'Entrée: ${formatTokens(ms.inputTokens)} | Sortie: ${formatTokens(ms.outputTokens)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '\$${ms.costUsd.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.aiPurple,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Tab Importer ────────────────────────────────────────────────────────────

class _ImportTab extends ConsumerStatefulWidget {
  const _ImportTab();

  @override
  ConsumerState<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<_ImportTab> {
  final _apiKeyController = TextEditingController();
  final _manualInputController = TextEditingController();
  final _manualOutputController = TextEditingController();
  final _projectController = TextEditingController();
  String _selectedProvider = 'anthropic';
  String _manualProvider = 'anthropic';
  String _manualModel = 'claude-sonnet-4-5';
  bool _obscureKey = true;
  bool _saving = false;

  final _providers = [
    {'id': 'anthropic', 'name': 'Anthropic'},
    {'id': 'openai', 'name': 'OpenAI'},
    {'id': 'google', 'name': 'Google'},
    {'id': 'mistral', 'name': 'Mistral'},
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    _manualInputController.dispose();
    _manualOutputController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une clé API')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(saveAiApiKeyProvider(
        providerId: _selectedProvider,
        plainKey: key,
        label: '$_selectedProvider - ${DateTime.now().toLocal().toString().substring(0, 10)}',
      ).future);
      _apiKeyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clé enregistrée avec succès')),
        );
      }
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

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier sélectionné: ${result.files.first.name}'),
        ),
      );
    }
  }

  Future<void> _saveManualEntry() async {
    final inputTokens = int.tryParse(_manualInputController.text.trim()) ?? 0;
    final outputTokens = int.tryParse(_manualOutputController.text.trim()) ?? 0;

    if (inputTokens == 0 && outputTokens == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les tokens')),
      );
      return;
    }

    // Calcul du coût approximatif
    const defaultCostPerMtok = 3.0; // USD
    final costUsd = ((inputTokens + outputTokens) / 1_000_000) * defaultCostPerMtok;

    final record = AiUsageRecord.create(
      timestamp: DateTime.now(),
      providerId: _manualProvider,
      modelId: _manualModel,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      costUsd: costUsd,
      costLocal: costUsd * 610.0,
      projectName: _projectController.text.trim().isEmpty ? null : _projectController.text.trim(),
      source: 'MANUAL',
    );

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      await isar.aiUsageRecords.put(record);
    });

    ref.invalidate(aiUsageSummaryProvider);
    _manualInputController.clear();
    _manualOutputController.clear();
    _projectController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrée enregistrée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Via API ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Via API', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: const InputDecoration(labelText: 'Fournisseur'),
                  items: _providers.map((p) => DropdownMenuItem(
                    value: p['id'],
                    child: Text(p['name']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedProvider = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'Clé API',
                    hintText: 'sk-ant-...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveApiKey,
                    child: _saving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer et synchroniser'),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppTheme.warning, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Clé stockée localement chiffrée AES-256. Jamais transmise.',
                          style: TextStyle(fontSize: 11, color: AppTheme.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ---- Import CSV ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Text('Importer CSV', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf9fafb),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Formats supportés:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('• Anthropic: Usage > Export CSV', style: theme.textTheme.bodySmall),
                      Text('• OpenAI: Usage dashboard > Export', style: theme.textTheme.bodySmall),
                      Text('• Google: AI Studio > History > Export', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _importCsv,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choisir un fichier CSV'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ---- Saisie manuelle ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: AppTheme.aiPurple, size: 18),
                    const SizedBox(width: 8),
                    Text('Saisie manuelle', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _manualProvider,
                  decoration: const InputDecoration(labelText: 'Fournisseur'),
                  items: _providers.map((p) => DropdownMenuItem(
                    value: p['id'],
                    child: Text(p['name']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _manualProvider = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Modèle (ex: claude-sonnet-4-5)'),
                  onChanged: (v) => _manualModel = v,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualInputController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tokens entrée'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _manualOutputController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tokens sortie'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _projectController,
                  decoration: const InputDecoration(labelText: 'Projet (optionnel)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveManualEntry,
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
