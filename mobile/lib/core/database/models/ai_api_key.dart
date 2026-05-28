import 'package:isar/isar.dart';

part 'ai_api_key.g.dart';

@Collection()
class AiApiKey {
  Id id = Isar.autoIncrement;

  @Index()
  late String providerId;

  /// Clé API chiffrée en AES-256 (base64)
  late String encryptedKey;

  late String label;

  late DateTime createdAt;
  DateTime? lastUsedAt;

  AiApiKey();

  AiApiKey.create({
    required this.providerId,
    required this.encryptedKey,
    required this.label,
    DateTime? createdAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
  }

  String get providerDisplayName {
    switch (providerId.toLowerCase()) {
      case 'anthropic':
        return 'Anthropic (Claude)';
      case 'openai':
        return 'OpenAI (ChatGPT)';
      case 'google':
        return 'Google (Gemini)';
      case 'mistral':
        return 'Mistral AI';
      default:
        return providerId;
    }
  }

  String get maskedKey {
    if (encryptedKey.length <= 8) return '****';
    return '${encryptedKey.substring(0, 4)}...${encryptedKey.substring(encryptedKey.length - 4)}';
  }
}
