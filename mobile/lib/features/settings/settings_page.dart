import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:isar/isar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/models/data_record.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Map<Permission, PermissionStatus> _permissionStatus = {};
  int _billingCycleDay = 1;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.sms,
      Permission.callLog,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final p in permissions) {
      statuses[p] = await p.status;
    }

    if (mounted) setState(() => _permissionStatus = statuses);
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() => _permissionStatus[permission] = status);
  }

  String _permissionLabel(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return 'Téléphone';
      case Permission.sms:
        return 'SMS';
      case Permission.callLog:
        return 'Journal d\'appels';
      default:
        return permission.toString();
    }
  }

  Future<void> _exportData() async {
    final isar = IsarService.instance;
    final records = await isar.dataRecords.where().findAll();

    final rows = <List<dynamic>>[
      ['Horodatage', 'Application', 'Mobile RX', 'Mobile TX', 'WiFi RX', 'WiFi TX'],
      ...records.map((r) => [
        r.timestamp.toIso8601String(),
        r.appName,
        r.mobileRxBytes,
        r.mobileTxBytes,
        r.wifiRxBytes,
        r.wifiTxBytes,
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await Share.share(csv, subject: 'ConsoTélécom - Export données');
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer toutes les données'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos données locales. '
          'Clés API, historique et forfaits seront effacés. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await IsarService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toutes les données ont été supprimées.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          // ---- Pays & Devise ----
          _SectionHeader(title: 'Pays & Devise'),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Pays'),
            subtitle: const Text('Burkina Faso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Devise'),
            subtitle: const Text('FCFA (XOF)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(height: 1),

          // ---- Opérateurs & SIM ----
          _SectionHeader(title: 'Opérateurs & SIM'),
          ListTile(
            leading: const Icon(Icons.sim_card),
            title: const Text('Configuration des SIM'),
            subtitle: const Text('Opérateur, forfait, USSD'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/operators'),
          ),

          const Divider(height: 1),

          // ---- Cycle de facturation ----
          _SectionHeader(title: 'Cycle de facturation'),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Début du cycle'),
            subtitle: Text('Jour $_billingCycleDay de chaque mois'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _billingCycleDay > 1
                      ? () => setState(() => _billingCycleDay--)
                      : null,
                ),
                Text('$_billingCycleDay', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _billingCycleDay < 28
                      ? () => setState(() => _billingCycleDay++)
                      : null,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ---- Langue ----
          _SectionHeader(title: 'Langue'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue de l\'interface'),
            subtitle: const Text('Français'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(height: 1),

          // ---- IA ----
          _SectionHeader(title: 'Intelligence artificielle'),
          ListTile(
            leading: const Icon(Icons.key, color: AppTheme.aiPurple),
            title: const Text('Clés API IA'),
            subtitle: const Text('Anthropic, OpenAI, Google, Mistral'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/ai-keys'),
          ),

          const Divider(height: 1),

          // ---- Alertes ----
          _SectionHeader(title: 'Alertes'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppTheme.warning),
            title: const Text('Seuils d\'alerte'),
            subtitle: const Text('Données, coûts, tokens IA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/alerts'),
          ),

          const Divider(height: 1),

          // ---- Permissions ----
          _SectionHeader(title: 'Permissions'),
          ..._permissionStatus.entries.map((entry) {
            final granted = entry.value == PermissionStatus.granted;
            return ListTile(
              leading: Icon(
                granted ? Icons.check_circle : Icons.error_outline,
                color: granted ? AppTheme.success : AppTheme.danger,
                size: 20,
              ),
              title: Text(_permissionLabel(entry.key)),
              subtitle: Text(granted ? 'Accordée' : 'Non accordée'),
              trailing: granted
                  ? null
                  : TextButton(
                      onPressed: () => _requestPermission(entry.key),
                      child: const Text('Accorder'),
                    ),
            );
          }),

          const Divider(height: 1),

          // ---- Vie privée ----
          _SectionHeader(title: 'Vie privée & données'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exporter mes données'),
            subtitle: const Text('Export CSV de l\'historique'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.danger),
            title: const Text('Supprimer toutes les données', style: TextStyle(color: AppTheme.danger)),
            subtitle: const Text('Action irréversible'),
            onTap: _deleteAllData,
          ),

          const Divider(height: 1),

          // ---- À propos ----
          _SectionHeader(title: 'À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ConsoTélécom'),
            subtitle: Text('Version 2.0.0 • eDefence • Burkina Faso'),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Stockage'),
            subtitle: Text('Toutes vos données restent sur l\'appareil. Rien n\'est transmis à un serveur tiers.'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
