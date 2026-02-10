import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils.dart';

class MinfoApiClient {
  final _logger = MinfoLogger();
  static const String _baseUrl = 'https://api.dev.minfo.com/api';
  String? _pubKey;
  String? _privKey;

  void setExternalKeys(String pub, String priv) {
    _pubKey = pub;
    _privKey = priv;
  }

  Future<Map<String, dynamic>?> getCampaignData(String signature) async {
    if (_pubKey == null || _privKey == null) {
      _logger.error('❌ [API] Clés non configurées');

      return null;
    }

    try {
      // Utilisation de Uri.parse pour une construction d'URL propre
      final url = Uri.parse('$_baseUrl/minfo/campaignfromaudio').replace(
        queryParameters: {'audio_id': signature},
      );

      final response = await http.get(
        url,
        headers: {
          'X-API-Key': _pubKey!,
          'X-API-Secret': _privKey!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _logger.error('❌ [API] Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
     _logger.error('❌ [API] Exception: $e');
    }
    return null;
  }
}