 import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'minfo_auth_manager.dart';

class MinfoApiClient {
  static const String _baseUrl = 'https://api.dev.minfo.com/api';
  static const _storage = FlutterSecureStorage();

  String? _clePublique;
  String? _clePrivee;

  // Générer les clés API avec le token JWT
  Future<bool> genererClesApi(String tokenJwt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/generate-api-keys'),
        headers: {'Authorization': 'Bearer $tokenJwt'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        _clePublique = data['public_key'];
        _clePrivee = data['private_key'];

        // Validation des clés (64 caractères hexadécimaux)
        if (!_isValidApiKey(_clePublique) || !_isValidApiKey(_clePrivee)) {
          throw Exception('Clés API invalides reçues du serveur');
        }

        await _storage.write(key: 'minfo_cle_publique', value: _clePublique);
        await _storage.write(key: 'minfo_cle_privee', value: _clePrivee);
        return true;
      }
    } catch (e) {
      print('Erreur génération clés API: $e');
    }
    return false;
  }

  // Validation des clés API (64 caractères hexadécimaux OU JWT)
  bool _isValidApiKey(String? key) {
    if (key == null) return false;
    // Accepter JWT (commence par eyJ) ou clés hex 64 chars
    return key.startsWith('eyJ') || (key.length == 64 && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(key));
  }

  // Charger les clés API stockées
  Future<bool> chargerClesApi() async {
    _clePublique = await _storage.read(key: 'minfo_cle_publique');
    _clePrivee = await _storage.read(key: 'minfo_cle_privee');
    return _clePublique != null && _clePrivee != null;
  }

  // Récupérer les campagnes
  Future<List<dynamic>?> obtenirCampagnes() async {
    if (_clePublique == null || _clePrivee == null) return null;

    try {
      final headers = _clePrivee!.startsWith('eyJ')
          ? {'Authorization': 'Bearer $_clePrivee'}
          : {
        'X-API-Key': _clePublique!,
        'X-API-Secret': _clePrivee!,
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/minfo/campaigns'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
    } catch (e) {
      print('Erreur récupération campagnes: $e');
    }
    return null;
  }

  // Obtenir l'URL de campagne pour une signature AudioQR
  Future<String?> getCampaignUrl(String signature) async {
    if (_clePublique == null || _clePrivee == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/minfo/campaignfromaudio').replace(
          queryParameters: {
            'audio_id': signature,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
        headers: {
          'X-API-Key': _clePublique!,
          'X-API-Secret': _clePrivee!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['campaign_url'] ?? data['url'];
      }
      print('Erreur API connect: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Erreur récupération URL campagne: $e');
      return null;
    }
  }

  // Obtenir les données complètes de campagne (pour MinfoDetector)
  Future<Map<String, dynamic>?> getCampaignData(String signature) async {
    // Utiliser les clés depuis MinfoAuthManager
    final publicKey = MinfoAuthManager.publicKey;
    final privateKey = MinfoAuthManager.privateKey;
    
    if (publicKey == null || privateKey == null) {
      print('❌ [API] Clés API manquantes: public=$publicKey, private=$privateKey');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/minfo/campaignfromaudio').replace(
        queryParameters: {
          'audio_id': signature,
        },
      );
      
      print('🌐 [API] URL appelée: $url');
      print('🔑 [API] Headers: X-API-Key=${publicKey.substring(0, 8)}..., X-API-Secret=${privateKey.substring(0, 8)}...');
      
      final response = await http.get(
        url,
        headers: {
          'X-API-Key': publicKey,
          'X-API-Secret': privateKey,
        },
      );

      print('📡 [API] Status: ${response.statusCode}');
      print('📡 [API] Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print('❌ [API] Erreur campaign data: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ [API] Exception: $e');
      return null;
    }
  }

  // Générer un soundcode
  Future<String?> genererSoundcode(String signatureAudio) async {
    if (_clePublique == null || _clePrivee == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/soundcoder'),
        headers: {
          'X-API-Key': _clePublique!,
          'X-API-Secret': _clePrivee!,
          'Content-Type': 'application/json',
        },
        body: json.encode({'signature': signatureAudio}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['soundcode'];
      }
    } catch (e) {
      print('Erreur génération soundcode: $e');
    }
    return null;
  }

  // Méthode connect pour l'exemple
  Future<Map<String, dynamic>?> connect(dynamic request) async {
    if (_clePublique == null || _clePrivee == null) {
      print('❌ [API] Clés API manquantes');
      return null;
    }

    String audioId;
    if (request is Map<String, dynamic>) {
      audioId = request['audioSignature'] ?? request['signature'] ?? '';
    } else {
      audioId = request.toString();
    }

    try {
      final url = Uri.parse('$_baseUrl/minfo/campaignfromaudio').replace(
        queryParameters: {
          'audio_id': audioId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('🌐 [API] URL: $url');
      print('🔑 [API] Headers: X-API-Key=${_clePublique?.substring(0, 20)}...');

      final response = await http.get(url, headers: {
        'X-API-Key': _clePublique!,
        'X-API-Secret': _clePrivee!,
      });

      print('📡 [API] Status: ${response.statusCode}');
      print('📡 [API] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'outcome': data['id'] != null ? 'allow' : 'error',
          'payload': data['id'] != null ? {
            'url': 'https://app.minfo.com/campaign/${data['id']}',
            'campaign_data': data,
          } : null,
        };

        // Ouvrir automatiquement la page web si une campagne est trouvée
        if (data['id'] != null) {
          final campaignUrl = 'https://app.minfo.com/campaign/${data['id']}';
          print('🌐 [AUTO-OPEN] Ouverture de: $campaignUrl');
          await _openUrl(campaignUrl);
        }

        return result;
      } else {
        print('❌ [API] Erreur ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 [API] Exception: $e');
      return null;
    }
  }

  // APIs compatibles selon documentation
  Future<List<dynamic>?> getCategories() async {
    return await _makeApiCall('categories');
  }

  Future<List<dynamic>?> searchCampaigns(Map<String, dynamic> params) async {
    return await _makeApiCall('campaigns_search', method: 'POST', body: params);
  }

  Future<Map<String, dynamic>?> createCampaignFromAudio(Map<String, dynamic> data) async {
    return await _makeApiCall('campaignfromaudio', method: 'POST', body: data);
  }

  Future<List<dynamic>?> getCampaignsV2() async {
    return await _makeApiCall('campaign/v2');
  }

  Future<Map<String, dynamic>?> createCampaignFromNoV2(Map<String, dynamic> data) async {
    return await _makeApiCall('campaignfromno/v2', method: 'POST', body: data);
  }

  Future<Map<String, dynamic>?> createCampaignFromNoV3(Map<String, dynamic> data) async {
    return await _makeApiCall('campaignfromno/v3', method: 'POST', body: data);
  }

  Future<List<dynamic>?> getCampaignHistory() async {
    return await _makeApiCall('campaignhistorique');
  }

  // Méthode générique pour les appels API
  Future<dynamic> _makeApiCall(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    if (_clePublique == null || _clePrivee == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/minfo/$endpoint');
      final headers = _clePrivee!.startsWith('eyJ')
          ? {
        'Authorization': 'Bearer $_clePrivee',
        'Content-Type': 'application/json',
      }
          : {
        'X-API-Key': _clePublique!,
        'X-API-Secret': _clePrivee!,
        'Content-Type': 'application/json',
      };

      http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body != null ? json.encode(body) : null);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] ?? decoded;
      }
    } catch (e) {
      print('Erreur API $endpoint: $e');
    }
    return null;
  }

  // Ouvrir une URL dans le navigateur
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        print('✅ [URL] Page ouverte: $url');
      } else {
        print('❌ [URL] Impossible d\'ouvrir: $url');
      }
    } catch (e) {
      print('❌ [URL] Erreur: $e');
    }
  }
}