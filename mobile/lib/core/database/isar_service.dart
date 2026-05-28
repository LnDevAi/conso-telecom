import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/data_record.dart';
import 'models/call_record.dart';
import 'models/sms_record.dart';
import 'models/plan.dart';
import 'models/ai_usage_record.dart';
import 'models/ai_api_key.dart';
import 'models/alert_threshold.dart';
import 'models/service_review.dart';

class IsarService {
  IsarService._();

  static Isar? _instance;
  static const _encryptionKeyName = 'isar_encryption_key';

  static Isar get instance {
    if (_instance == null || !_instance!.isOpen) {
      throw StateError('IsarService non initialisé. Appelez IsarService.open() d\'abord.');
    }
    return _instance!;
  }

  static bool get isOpen => _instance != null && _instance!.isOpen;

  /// Ouvre la base de données Isar avec toutes les collections.
  /// Génère une clé de chiffrement unique stockée dans FlutterSecureStorage.
  static Future<Isar> open() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    final dir = await getApplicationDocumentsDirectory();
    final secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    // Récupérer ou générer la clé de chiffrement
    List<int>? encryptionKey;
    final storedKey = await secureStorage.read(key: _encryptionKeyName);

    if (storedKey != null) {
      encryptionKey = storedKey.split(',').map(int.parse).toList();
    } else {
      encryptionKey = Isar.generateSecureKey();
      await secureStorage.write(
        key: _encryptionKeyName,
        value: encryptionKey.join(','),
      );
    }

    _instance = await Isar.open(
      [
        DataRecordSchema,
        CallRecordSchema,
        SmsRecordSchema,
        PlanSchema,
        AiUsageRecordSchema,
        AiApiKeySchema,
        AlertThresholdSchema,
        ServiceReviewSchema,
      ],
      directory: dir.path,
      name: 'conso_telecom',
      encryptionKey: encryptionKey,
    );

    debugPrint('IsarService: base de données ouverte dans ${dir.path}');
    return _instance!;
  }

  /// Ferme la base de données.
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
    }
  }

  /// Supprime toutes les données (export/suppression vie privée).
  static Future<void> clearAll() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.writeTxn(() async {
        await _instance!.clear();
      });
    }
  }
}
