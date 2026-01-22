import 'dart:convert';
import 'package:http/http.dart' as http;

class MinfoAuth {
  final String baseUrl;

  MinfoAuth({this.baseUrl = 'https://api.dev.minfo.com'});

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
        return {
          'public_key': data['public_key'],
          'private_key': data['private_key'],
        };
      }
      print('❌ API keys generation failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ API keys error: $e');
      return null;
    }
  }

  // Processus complet : Login → Générer clés API
  Future<Map<String, String>?> getApiKeys(String email, String password) async {
    print('🔐 Login...');
    final jwt = await login(email, password);
    
    if (jwt == null) {
      print('❌ Login failed');
      return null;
    }
    
    print('✅ JWT obtained, generating API keys...');
    final keys = await generateApiKeys(jwt);
    
    if (keys != null) {
      print('✅ API Keys generated successfully!');
      return keys;
    }
    
    // Fallback : utiliser le JWT comme clé API
    print('⚠️ Fallback: using JWT as API key');
    return {
      'public_key': jwt.substring(0, 64).padRight(64, '0'),
      'private_key': jwt,
    };
  }
}
