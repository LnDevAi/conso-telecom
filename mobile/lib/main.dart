import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'core/database/isar_service.dart';
import 'features/alerts/alerts_service.dart';

/// Nom des tâches WorkManager
const String networkSamplerTask = 'networkSamplerTask';
const String alertCheckerTask = 'alertCheckerTask';

/// Point d'entrée des tâches WorkManager (top-level function obligatoire)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case networkSamplerTask:
        await _runNetworkSampler();
        break;
      case alertCheckerTask:
        await _runAlertChecker();
        break;
      default:
        break;
    }
    return Future.value(true);
  });
}

Future<void> _runNetworkSampler() async {
  // Ouvrir la base de données et enregistrer un échantillon réseau
  try {
    await IsarService.open();
    // La logique de collecte est dans DataUsageProvider
    // Ici on se contente d'ouvrir la base pour que les providers puissent l'utiliser
  } catch (e) {
    debugPrint('NetworkSampler error: $e');
  }
}

Future<void> _runAlertChecker() async {
  try {
    await IsarService.open();
    await AlertsService.checkAndFireAlerts();
  } catch (e) {
    debugPrint('AlertChecker error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ouvrir la base de données Isar
  await IsarService.open();

  // Initialiser WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Enregistrer la tâche d'échantillonnage réseau (toutes les 15 minutes)
  await Workmanager().registerPeriodicTask(
    networkSamplerTask,
    networkSamplerTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Enregistrer la tâche de vérification des alertes (toutes les heures)
  await Workmanager().registerPeriodicTask(
    alertCheckerTask,
    alertCheckerTask,
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.not_required,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Initialiser les notifications locales
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(
    const ProviderScope(
      child: ConsoTelecomApp(),
    ),
  );
}
