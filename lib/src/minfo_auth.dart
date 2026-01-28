import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MinfoAuth {
  final String baseUrl;
  static const _storage = FlutterSecureStorage();

  MinfoAuth({this.baseUrl = 'https://api.dev.minfo.com'});

  // Vérifier si les clés API existent déjà
  Future<Map<String, String>?> getStoredApiKeys() async {
    try {
      final publicKey = await _storage.read(key: 'minfo_cle_publique');
      final privateKey = await _storage.read(key: 'minfo_cle_privee');
      
      if (publicKey != null && privateKey != null) {
        print('✅ [STORAGE] Clés API trouvées en cache');
        print('🔑 [STORAGE] Public: ${publicKey.substring(0, 20)}...');
        print('🔑 [STORAGE] Private: ${privateKey.substring(0, 20)}...');
        return {
          'public_key': publicKey,
          'private_key': privateKey,
        };
      }
      print('ℹ️ [STORAGE] Aucune clé API en cache');
      return null;
    } catch (e) {
      print('❌ [STORAGE] Erreur lecture clés: $e');
      return null;
    }
  }

  // Stocker les clés API
  Future<void> storeApiKeys(String publicKey, String privateKey) async {
    try {
      await _storage.write(key: 'minfo_cle_publique', value: publicKey);
      await _storage.write(key: 'minfo_cle_privee', value: privateKey);
      print('✅ [STORAGE] Clés API sauvegardées');
    } catch (e) {
      print('❌ [STORAGE] Erreur sauvegarde clés: $e');
    }
  }

  // Supprimer les clés stockées (pour forcer la régénération)
  Future<void> clearStoredApiKeys() async {
    try {
      await _storage.delete(key: 'minfo_cle_publique');
      await _storage.delete(key: 'minfo_cle_privee');
      print('🗑️ [STORAGE] Clés API supprimées');
    } catch (e) {
      print('❌ [STORAGE] Erreur suppression clés: $e');
    }
  }
  // 1. Login pour obtenir le JWT
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Utiliser access_jwt en priorité selon la documentation
        final jwt = data['jwt_data']?['access_jwt'] ?? 
                   data['token'] ?? 
                   data['access_token'];
        
        print('✅ [LOGIN] JWT reçu: ${jwt?.substring(0, 50)}...');
        return jwt;
      }
      print('❌ Login failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // 2. Générer les clés API avec le JWT
  Future<Map<String, String>?> generateApiKeys(String jwtToken) async {
    try {
      print('🔑 [DEBUG] Envoi requête generate-api-keys...');
      print('🔑 [DEBUG] URL: $baseUrl/auth/generate-api-keys');
      print('🔑 [DEBUG] JWT: ${jwtToken.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/generate-api-keys'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      print('🔑 [DEBUG] Status: ${response.statusCode}');
      print('🔑 [DEBUG] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        final keys = {
          'public_key': data['public_key'] as String,
          'private_key': data['private_key'] as String,
        };
        
        // Stocker les clés pour usage futur
        await storeApiKeys(keys['public_key']!, keys['private_key']!);
        
        return keys;
      }
      print('❌ API keys generation failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ API keys error: $e');
      return null;
    }
  }

  // Processus complet : Vérifier cache → Login → Générer clés API
  Future<Map<String, String>?> getApiKeys(String email, String password, {bool forceRegenerate = false}) async {
    // 1. Vérifier si les clés existent déjà (sauf si régénération forcée)
    if (!forceRegenerate) {
      final storedKeys = await getStoredApiKeys();
      if (storedKeys != null) {
        print('🔄 [AUTH] Utilisation des clés en cache');
        return storedKeys;
      }
    } else {
      print('🔄 [AUTH] Régénération forcée des clés');
      await clearStoredApiKeys();
    }
    
    // 2. Générer de nouvelles clés
    print('🔐 [AUTH] Login...');
    final jwt = await login(email, password);
    
    if (jwt == null) {
      print('❌ [AUTH] Login failed');
      return null;
    }
    
    print('✅ [AUTH] JWT obtained, generating API keys...');
    final keys = await generateApiKeys(jwt);
    
    if (keys != null) {
      print('✅ [AUTH] API Keys generated and stored successfully!');
      print('🔑 [AUTH] Public: ${keys['public_key']!.substring(0, 20)}...');
      print('🔑 [AUTH] Private: ${keys['private_key']!.substring(0, 20)}...');
      return keys;
    }
    
    // Fallback : utiliser le JWT comme clé API
    print('⚠️ [AUTH] Fallback: using JWT as API key');
    final fallbackKeys = {
      'public_key': jwt.substring(0, 64).padRight(64, '0'),
      'private_key': jwt,
    };
    await storeApiKeys(fallbackKeys['public_key']!, fallbackKeys['private_key']!);
    return fallbackKeys;
  }

  // Méthode pour s'assurer que des clés valides existent
  Future<Map<String, String>?> ensureApiKeys({
    String? defaultPublicKey,
    String? defaultPrivateKey,
  }) async {
    // Vérifier si des clés existent déjà
    var keys = await getStoredApiKeys();
    
    if (keys == null && defaultPublicKey != null && defaultPrivateKey != null) {
      print('🔧 [AUTH] Initialisation avec clés par défaut');
      await storeApiKeys(defaultPublicKey, defaultPrivateKey);
      keys = await getStoredApiKeys();
    }
    
    return keys;
  }
}
