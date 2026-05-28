import 'package:isar/isar.dart';

part 'ai_usage_record.g.dart';

@Collection()
class AiUsageRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime timestamp;

  @Index()
  late String providerId;

  @Index()
  late String modelId;

  late long inputTokens;
  late long outputTokens;

  late double costUsd;
  late double costLocal;

  String? projectName;

  /// Source des données: API / CSV_IMPORT / MANUAL
  @Index()
  late String source;

  AiUsageRecord();

  AiUsageRecord.create({
    required this.timestamp,
    required this.providerId,
    required this.modelId,
    required this.inputTokens,
    required this.outputTokens,
    required this.costUsd,
    required this.costLocal,
    this.projectName,
    this.source = 'MANUAL',
  });

  long get totalTokens => inputTokens + outputTokens;

  String get providerDisplayName {
    switch (providerId.toLowerCase()) {
      case 'anthropic':
        return 'Anthropic';
      case 'openai':
        return 'OpenAI';
      case 'google':
        return 'Google';
      case 'mistral':
        return 'Mistral';
      default:
        return providerId;
    }
  }
}
