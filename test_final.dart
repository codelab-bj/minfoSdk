import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/src/minfo_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await MinfoSdk.instance.init(
      publicKey: MinfoConfig.PUBLIC_KEY,
      privateKey: MinfoConfig.PRIVATE_KEY,
      baseUrl: MinfoConfig.BASE_URL,
    );
    print("✅ SDK initialisé avec succès");
  } catch (e) {
    print("❌ Erreur SDK: $e");
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Minfo SDK Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await MinfoSdk.instance.audioEngine.startDetection();
              print("Résultat détection: $result");
            },
            child: Text('Démarrer détection'),
          ),
        ),
      ),
    );
  }
}
