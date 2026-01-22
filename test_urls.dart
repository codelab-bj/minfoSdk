import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://api.dev.minfo.com/api';
  
  final urls = [
    '$baseUrl/auth/generate-api-keys',
    '$baseUrl/minfo/campaigns',
    '$baseUrl/minfo/campaignfromaudio',
    '$baseUrl/soundcoder',
    '$baseUrl/minfo/categories',
    '$baseUrl/minfo/campaigns_search',
    '$baseUrl/minfo/campaign/v2',
    '$baseUrl/minfo/campaignfromno/v2',
    '$baseUrl/minfo/campaignfromno/v3',
    '$baseUrl/minfo/campaignhistorique',
  ];

  print('🔍 Test des URLs API...\n');

  for (final url in urls) {
    try {
      final response = await http.get(Uri.parse(url));
      final status = response.statusCode;
      
      if (status == 401 || status == 403) {
        print('✅ $url - Accessible (${status} - Auth requis)');
      } else if (status == 200) {
        print('✅ $url - OK (${status})');
      } else if (status == 404) {
        print('❌ $url - Non trouvé (${status})');
      } else {
        print('⚠️  $url - Status: ${status}');
      }
    } catch (e) {
      print('💥 $url - Erreur: $e');
    }
  }
}
