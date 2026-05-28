import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiKeyManager {
  static const _keyName = 'ai_key_encryption_secret';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static enc.Key? _cachedKey;

  /// Récupère ou génère la clé AES-256 depuis le stockage sécurisé.
  static Future<enc.Key> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final stored = await _storage.read(key: _keyName);
    if (stored != null) {
      _cachedKey = enc.Key(base64Decode(stored));
      return _cachedKey!;
    }

    // Générer une nouvelle clé 32 octets (256 bits)
    final newKey = enc.Key.fromSecureRandom(32);
    await _storage.write(key: _keyName, value: base64Encode(newKey.bytes));
    _cachedKey = newKey;
    return _cachedKey!;
  }

  /// Chiffre une clé API en AES-256 CBC.
  /// Retourne une chaîne base64 contenant IV + données chiffrées.
  static Future<String> encryptKey(String plainKey) async {
    final key = await _getKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainKey, iv: iv);

    // Format: base64(iv_bytes) + ':' + base64(encrypted_bytes)
    final ivBase64 = base64Encode(iv.bytes);
    final dataBase64 = encrypted.base64;

    return '$ivBase64:$dataBase64';
  }

  /// Déchiffre une clé API précédemment chiffrée par [encryptKey].
  static Future<String> decryptKey(String encryptedBase64) async {
    final key = await _getKey();

    final parts = encryptedBase64.split(':');
    if (parts.length != 2) {
      throw const FormatException('Format de clé chiffrée invalide');
    }

    final iv = enc.IV(base64Decode(parts[0]));
    final encrypted = enc.Encrypted(base64Decode(parts[1]));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Invalide le cache de la clé (utile pour les tests).
  static void clearCache() {
    _cachedKey = null;
  }

  /// Vérifie qu'une clé API a le format attendu selon le fournisseur.
  static bool validateKeyFormat(String providerId, String key) {
    switch (providerId.toLowerCase()) {
      case 'anthropic':
        return key.startsWith('sk-ant-');
      case 'openai':
        return key.startsWith('sk-');
      case 'google':
        return key.length > 20;
      case 'mistral':
        return key.length > 20;
      default:
        return key.isNotEmpty;
    }
  }
}
