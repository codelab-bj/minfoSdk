import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Test manuel des IDs...\n');
  
  // Test avec des IDs simulés
  final testIds = [12345, 67890, 999, 0];
  
  for (final audioId in testIds) {
    await testApiCall(audioId);
    print('');
  }
}

Future<void> testApiCall(int audioId) async {
  print('🎯 Test avec ID: $audioId');
  
  if (audioId == 0) {
    print('❌ ID invalide détecté');
    return;
  }
  
  final counter = 1;
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  final url = 'https://api.dev.minfo.com/api/minfo/campaign/v2?audio_id=$audioId&counter=$counter&timestamp=$timestamp&origin=FLUTTER_SDK&source=AUDIO_ID&lang=fr';
  
  print('🔗 URL: $url');
  
  try {
    final response = await http.get(Uri.parse(url));
    print('📡 Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Réponse: ${data.toString().substring(0, 100)}...');
    } else {
      print('❌ Erreur: ${response.body}');
    }
  } catch (e) {
    print('💥 Exception: $e');
  }
}
