import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // L'app fournit ses propres clés (pas celles du SDK)
  await MinfoSdk.initialize(
    publicKey: "44aa1a343d185494158eb275b17063855fccfbe4ae270e33ebc69372fe3c941a",
    privateKey: "00b7b3d2f0d27f1ffddf9875b57a8eb96d4fed21f8880ec915ec4962c8e95419",
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

  @override
  void initState() {
    super.initState();
    _setupCampaignListener();
  }

  void _setupCampaignListener() {
    // Attendre que le stream soit disponible
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (MinfoSdk.instance.campaignStream != null) {
        timer.cancel();
        MinfoSdk.instance.campaignStream!.listen((result) {
          print("🔥 Stream reçu: ${result.toString()}");
          
          if (mounted) {
            setState(() {
              _isProcessing = false;
              if (result.campaignData != null && result.error == null) {
                _statusMessage = "✅ ${result.campaignData!['name'] ?? 'Campagne détectée'}";
              } else {
                _statusMessage = "❌ ${result.error ?? 'Erreur inconnue'}";
              }
            });
          }
        });
      }
    });
  }

  // --- VOTRE LOGIQUE DE DÉMARRAGE ---
  Future<void> _handleMinfoLink() async {
    // 1. Demander uniquement le micro (Indispensable pour l'Activation)
    final micStatus = await Permission.microphone.request();

    if (!micStatus.isGranted) {
      _showError("Permission microphone nécessaire.");
      return;
    }

    // 2. Optionnel : Demander le téléphone sans bloquer si refusé
    await Permission.phone.request();

    setState(() {
      _isProcessing = true;
      _statusMessage = "Écoute en cours...";
    });

    try {
      // Étape 1 & 2 du SDK : Activation du micro et Décodage
      await MinfoSdk.instance.listen();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "❌ $e";
      });
    }
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
