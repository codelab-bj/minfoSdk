import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MinfoAuth {
  // Utilisation de FlutterSecureStorage pour crypter les clés sur le téléphone
  static const _storage = FlutterSecureStorage();

  // Clés utilisées pour le stockage interne
  static const _keyPublic = 'minfo_cle_publique';
  static const _keyPrivate = 'minfo_cle_privee';

  /// Récupère les clés stockées.
  /// Retourne null si l'une des deux clés est manquante.
  Future<Map<String, String>?> getStoredApiKeys() async {
    try {
      final publicKey = await _storage.read(key: _keyPublic);
      final privateKey = await _storage.read(key: _keyPrivate);

      if (publicKey != null && privateKey != null) {
        return {
          'public_key': publicKey,
          'private_key': privateKey,
        };
      }
    } catch (e) {
      print('❌ [STORAGE] Erreur lors de la lecture des clés: $e');
    }
    return null;
  }

  /// Sauvegarde les clés transmises par le MinfoSdk.initialize
  Future<void> storeApiKeys(String publicKey, String privateKey) async {
    try {
      await _storage.write(key: _keyPublic, value: publicKey);
      await _storage.write(key: _keyPrivate, value: privateKey);
      print('✅ [STORAGE] Clés API sauvegardées localement.');
    } catch (e) {
      print('❌ [STORAGE] Erreur lors de la sauvegarde: $e');
    }
  }

  /// Supprime les clés (Utile pour une déconnexion ou un reset)
  Future<void> clearKeys() async {
    try {
      await _storage.delete(key: _keyPublic);
      await _storage.delete(key: _keyPrivate);
      print('🗑️ [STORAGE] Clés API supprimées.');
    } catch (e) {
      print('❌ [STORAGE] Erreur lors de la suppression: $e');
    }
  }
}