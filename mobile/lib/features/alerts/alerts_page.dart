import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/models/alert_threshold.dart';

final _alertsProvider = StreamProvider<List<AlertThreshold>>((ref) {
  return IsarService.instance.alertThresholds.where().watch(fireImmediately: true);
});

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlertSheet(context),
        child: const Icon(Icons.add),
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                'Aucune alerte configurée.\nAppuyez sur + pour en ajouter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertCard(
                alert: alert,
                onToggle: (enabled) async {
                  alert.isEnabled = enabled;
                  await IsarService.instance.writeTxn(() async {
                    await IsarService.instance.alertThresholds.put(alert);
                  });
                },
                onEdit: () => _showEditAlertSheet(context, alert),
                onDelete: () async {
                  await IsarService.instance.writeTxn(() async {
                    await IsarService.instance.alertThresholds.delete(alert.id);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAlertSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AlertSheet(),
    );
  }

  void _showEditAlertSheet(BuildContext context, AlertThreshold alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AlertSheet(existing: alert),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final AlertThreshold alert;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _alertColor {
    switch (alert.type) {
      case 'DATA_MB':
        return AppTheme.primary;
      case 'COST_LOCAL':
        return AppTheme.warning;
      case 'AI_COST_USD':
        return AppTheme.aiPurple;
      case 'VOICE_MINUTES':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData get _alertIcon {
    switch (alert.type) {
      case 'DATA_MB':
        return Icons.signal_cellular_alt;
      case 'COST_LOCAL':
        return Icons.account_balance_wallet;
      case 'AI_COST_USD':
        return Icons.psychology;
      case 'VOICE_MINUTES':
        return Icons.call;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_alertIcon, color: _alertColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.typeLabel, style: theme.textTheme.titleSmall),
                Text(
                  'Seuil: ${alert.valueLabel}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: alert.isEnabled,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.danger,
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AlertSheet extends StatefulWidget {
  const _AlertSheet({this.existing});

  final AlertThreshold? existing;

  @override
  State<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<_AlertSheet> {
  late String _type;
  late TextEditingController _valueController;

  final _types = [
    {'id': 'DATA_MB', 'label': 'Données mobiles (Mo)'},
    {'id': 'COST_LOCAL', 'label': 'Coût total (FCFA)'},
    {'id': 'AI_COST_USD', 'label': 'Coût IA (USD)'},
    {'id': 'VOICE_MINUTES', 'label': 'Appels (minutes)'},
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? 'DATA_MB';
    _valueController = TextEditingController(
      text: widget.existing?.value.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valeur invalide')),
      );
      return;
    }

    final isar = IsarService.instance;
    if (widget.existing != null) {
      widget.existing!.type = _type;
      widget.existing!.value = value;
      await isar.writeTxn(() async {
        await isar.alertThresholds.put(widget.existing!);
      });
    } else {
      final threshold = AlertThreshold.create(type: _type, value: value);
      await isar.writeTxn(() async {
        await isar.alertThresholds.put(threshold);
      });
    }

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
          Text(
            widget.existing != null ? 'Modifier l\'alerte' : 'Nouvelle alerte',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type d\'alerte'),
            items: _types
                .map((t) => DropdownMenuItem(value: t['id'], child: Text(t['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valeur seuil'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
