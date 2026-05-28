import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';

import '../../core/database/isar_service.dart';
import '../../core/database/models/ai_usage_record.dart';
import '../../core/database/models/ai_api_key.dart';
import 'ai_key_manager.dart';

part 'ai_tokens_provider.g.dart';

class AiUsageSummary {
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCostUsd;
  final double totalCostLocal;
  final Map<String, ProviderSummary> byProvider;
  final String? topModelId;
  final String? topProviderId;

  const AiUsageSummary({
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCostUsd,
    required this.totalCostLocal,
    required this.byProvider,
    this.topModelId,
    this.topProviderId,
  });

  int get totalTokens => totalInputTokens + totalOutputTokens;

  static const empty = AiUsageSummary(
    totalInputTokens: 0,
    totalOutputTokens: 0,
    totalCostUsd: 0,
    totalCostLocal: 0,
    byProvider: {},
  );
}

class ProviderSummary {
  final String providerId;
  final int totalTokens;
  final double costUsd;
  final double costLocal;
  final Map<String, ModelSummary> byModel;

  const ProviderSummary({
    required this.providerId,
    required this.totalTokens,
    required this.costUsd,
    required this.costLocal,
    required this.byModel,
  });
}

class ModelSummary {
  final String modelId;
  final String providerId;
  final int inputTokens;
  final int outputTokens;
  final double costUsd;

  const ModelSummary({
    required this.modelId,
    required this.providerId,
    required this.inputTokens,
    required this.outputTokens,
    required this.costUsd,
  });

  int get totalTokens => inputTokens + outputTokens;
}

@riverpod
Future<AiUsageSummary> aiUsageSummary(Ref ref) async {
  final isar = IsarService.instance;
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  final records = await isar.aiUsageRecords
      .filter()
      .timestampBetween(startOfMonth, now)
      .findAll();

  if (records.isEmpty) return AiUsageSummary.empty;

  int totalInput = 0;
  int totalOutput = 0;
  double totalUsd = 0;
  double totalLocal = 0;
  final providerMap = <String, Map<String, dynamic>>{};

  for (final r in records) {
    totalInput += r.inputTokens;
    totalOutput += r.outputTokens;
    totalUsd += r.costUsd;
    totalLocal += r.costLocal;

    providerMap.putIfAbsent(r.providerId, () => {'tokens': 0, 'usd': 0.0, 'local': 0.0, 'models': <String, Map<String, dynamic>>{}});
    providerMap[r.providerId]!['tokens'] = (providerMap[r.providerId]!['tokens'] as int) + r.totalTokens;
    providerMap[r.providerId]!['usd'] = (providerMap[r.providerId]!['usd'] as double) + r.costUsd;
    providerMap[r.providerId]!['local'] = (providerMap[r.providerId]!['local'] as double) + r.costLocal;

    final models = providerMap[r.providerId]!['models'] as Map<String, Map<String, dynamic>>;
    models.putIfAbsent(r.modelId, () => {'input': 0, 'output': 0, 'usd': 0.0});
    models[r.modelId]!['input'] = (models[r.modelId]!['input'] as int) + r.inputTokens;
    models[r.modelId]!['output'] = (models[r.modelId]!['output'] as int) + r.outputTokens;
    models[r.modelId]!['usd'] = (models[r.modelId]!['usd'] as double) + r.costUsd;
  }

  final byProvider = <String, ProviderSummary>{};
  for (final entry in providerMap.entries) {
    final models = (entry.value['models'] as Map<String, Map<String, dynamic>>).map(
      (modelId, m) => MapEntry(
        modelId,
        ModelSummary(
          modelId: modelId,
          providerId: entry.key,
          inputTokens: m['input'] as int,
          outputTokens: m['output'] as int,
          costUsd: m['usd'] as double,
        ),
      ),
    );
    byProvider[entry.key] = ProviderSummary(
      providerId: entry.key,
      totalTokens: entry.value['tokens'] as int,
      costUsd: entry.value['usd'] as double,
      costLocal: entry.value['local'] as double,
      byModel: models,
    );
  }

  // Trouver le modèle le plus utilisé
  String? topModel;
  String? topProvider;
  int maxTokens = 0;
  for (final ps in byProvider.values) {
    for (final ms in ps.byModel.values) {
      if (ms.totalTokens > maxTokens) {
        maxTokens = ms.totalTokens;
        topModel = ms.modelId;
        topProvider = ms.providerId;
      }
    }
  }

  return AiUsageSummary(
    totalInputTokens: totalInput,
    totalOutputTokens: totalOutput,
    totalCostUsd: totalUsd,
    totalCostLocal: totalLocal,
    byProvider: byProvider,
    topModelId: topModel,
    topProviderId: topProvider,
  );
}

@riverpod
Stream<List<AiApiKey>> aiApiKeys(Ref ref) {
  final isar = IsarService.instance;
  return isar.aiApiKeys.where().watch(fireImmediately: true);
}

@riverpod
Future<void> saveAiApiKey(
  Ref ref, {
  required String providerId,
  required String plainKey,
  required String label,
}) async {
  final encrypted = await AiKeyManager.encryptKey(plainKey);
  final isar = IsarService.instance;

  final key = AiApiKey.create(
    providerId: providerId,
    encryptedKey: encrypted,
    label: label,
  );

  await isar.writeTxn(() async {
    await isar.aiApiKeys.put(key);
  });

  ref.invalidate(aiApiKeysProvider);
}

@riverpod
Future<String?> decryptApiKey(Ref ref, int keyId) async {
  final isar = IsarService.instance;
  final key = await isar.aiApiKeys.get(keyId);
  if (key == null) return null;
  return AiKeyManager.decryptKey(key.encryptedKey);
}
