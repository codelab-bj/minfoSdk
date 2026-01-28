import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/src/minfo_config.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation directe avec les clés du fichier config
  await MinfoSdk.instance.init(
    publicKey: MinfoKeys.publicKey,
    privateKey: MinfoKeys.privateKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const MinfoExamplePage(),
    );
  }
}

class MinfoExamplePage extends StatefulWidget {
  const MinfoExamplePage({super.key});

  @override
  _MinfoExamplePageState createState() => _MinfoExamplePageState();
}

class _MinfoExamplePageState extends State<MinfoExamplePage> {
  bool _isProcessing = false;
  String _statusMessage = "Prêt pour la detection";

  // --- VOTRE LOGIQUE DE DÉMARRAGE ---
  Future<void> _handleMinfoLink() async {
    final micStatus = await Permission.microphone.request();
    
    // Sur iOS, on ne demande pas la permission phone
    if (!micStatus.isGranted) {
      _showError("Permission microphone nécessaire.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Écoute en cours...";
    });

    try {
      await MinfoSdk.instance.startAudioCapture();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "❌ $e";
      });
    }

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "⏰ Aucun signal détecté";
        });
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleMinfoLink,
                child: Text(_isProcessing ? "Écoute..." : "Démarrer détection"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
