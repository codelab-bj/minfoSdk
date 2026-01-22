// Test manuel avec un ID simulé
import 'minfo_api_client.dart';

void main() async {
  final client = MinfoApiClient();
  
  // Simuler un ID détecté
  final testIds = ['12345', '67890', '999'];
  
  for (final id in testIds) {
    print('🧪 Test avec ID: $id');
    final result = await client.connect(id);
    print('📡 Résultat: $result\n');
  }
}
