import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/alert_threshold.dart';
import '../../core/database/models/data_record.dart';
import '../../core/database/models/ai_usage_record.dart';
import '../../core/database/models/call_record.dart';

class AlertsService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'conso_telecom_alerts',
    'Alertes ConsoTélécom',
    channelDescription: 'Notifications d\'alerte de consommation',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  /// Vérifie les seuils et envoie des notifications si dépassés.
  /// Appelé par WorkManager en arrière-plan.
  static Future<void> checkAndFireAlerts() async {
    if (!IsarService.isOpen) {
      await IsarService.open();
    }

    final isar = IsarService.instance;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Charger les seuils actifs
    final thresholds = await isar.alertThresholds
        .filter()
        .isEnabledEqualTo(true)
        .findAll();

    if (thresholds.isEmpty) return;

    // Calculer les métriques actuelles
    final metrics = await _computeCurrentMetrics(isar, startOfMonth, now);

    int notifId = 100;

    for (final threshold in thresholds) {
      // Vérifier le délai anti-spam (max 1 alerte/4h par seuil)
      if (!threshold.canTriggerAgain) continue;

      final currentValue = metrics[threshold.type] ?? 0.0;
      if (currentValue >= threshold.value) {
        // Déclencher la notification
        await _fireNotification(
          id: notifId++,
          threshold: threshold,
          currentValue: currentValue,
        );

        // Mettre à jour lastTriggeredAt
        threshold.lastTriggeredAt = now;
        await isar.writeTxn(() async {
          await isar.alertThresholds.put(threshold);
        });

        debugPrint(
          'AlertsService: alerte déclenchée [${threshold.type}] '
          'valeur=$currentValue seuil=${threshold.value}',
        );
      }
    }
  }

  static Future<Map<String, double>> _computeCurrentMetrics(
    Isar isar,
    DateTime startOfMonth,
    DateTime now,
  ) async {
    final metrics = <String, double>{};

    // DATA_MB: données mobiles du mois
    final dataRecords = await isar.dataRecords
        .filter()
        .timestampBetween(startOfMonth, now)
        .findAll();

    double totalMobileBytes = 0;
    for (final r in dataRecords) {
      totalMobileBytes += r.mobileRxBytes + r.mobileTxBytes;
    }
    metrics['DATA_MB'] = totalMobileBytes / (1024 * 1024);

    // VOICE_MINUTES: appels sortants du mois
    final callRecords = await isar.callRecords
        .filter()
        .timestampBetween(startOfMonth, now)
        .callTypeEqualTo('outgoing')
        .findAll();

    double totalMinutes = 0;
    for (final r in callRecords) {
      totalMinutes += r.durationMinutes;
    }
    metrics['VOICE_MINUTES'] = totalMinutes;

    // AI_COST_USD: coût IA du mois
    final aiRecords = await isar.aiUsageRecords
        .filter()
        .timestampBetween(startOfMonth, now)
        .findAll();

    double totalAiUsd = 0;
    double totalAiLocal = 0;
    for (final r in aiRecords) {
      totalAiUsd += r.costUsd;
      totalAiLocal += r.costLocal;
    }
    metrics['AI_COST_USD'] = totalAiUsd;

    // COST_LOCAL: coût total estimé en FCFA
    final dataCostFcfa = metrics['DATA_MB']! * 5.0;
    final callCostFcfa = metrics['VOICE_MINUTES']! * 45.0;
    metrics['COST_LOCAL'] = dataCostFcfa + callCostFcfa + totalAiLocal;

    return metrics;
  }

  static Future<void> _fireNotification({
    required int id,
    required AlertThreshold threshold,
    required double currentValue,
  }) async {
    String title;
    String body;

    switch (threshold.type) {
      case 'DATA_MB':
        title = 'Alerte données mobiles';
        body = 'Vous avez consommé ${currentValue.toStringAsFixed(0)} Mo '
            '(seuil: ${threshold.value.toStringAsFixed(0)} Mo)';
        break;
      case 'COST_LOCAL':
        title = 'Alerte coût télécom';
        body = 'Dépense estimée: ${currentValue.toStringAsFixed(0)} FCFA '
            '(seuil: ${threshold.value.toStringAsFixed(0)} FCFA)';
        break;
      case 'AI_COST_USD':
        title = 'Alerte coût IA';
        body = 'Dépense IA: \$${currentValue.toStringAsFixed(2)} '
            '(seuil: \$${threshold.value.toStringAsFixed(2)})';
        break;
      case 'VOICE_MINUTES':
        title = 'Alerte appels';
        body = 'Vous avez utilisé ${currentValue.toStringAsFixed(0)} min '
            '(seuil: ${threshold.value.toStringAsFixed(0)} min)';
        break;
      default:
        title = 'Alerte ConsoTélécom';
        body = 'Seuil atteint: ${threshold.valueLabel}';
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        _notificationDetails,
      );
    } catch (e) {
      debugPrint('AlertsService: erreur notification: $e');
    }
  }

  /// Initialise le canal de notifications (à appeler au démarrage).
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }
}
