import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  // Indispensable pour l'initialisation asynchrone avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation globale
  await MinfoSdk.instance.init(
    clientId: 'VOTRE_CLIENT_ID',
    apiKey: 'VOTRE_API_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const MinfoExamplePage(),
    );
  }
}

class MinfoExamplePage extends StatefulWidget {
  const MinfoExamplePage({super.key});

  @override
  State<MinfoExamplePage> createState() => _MinfoExamplePageState();
}

class _MinfoExamplePageState extends State<MinfoExamplePage> {
  bool _isProcessing = false;
  String _statusMessage = "Prêt à scanner";

  /// Étape 1 : Demander la permission et lancer la détection audio
  Future<void> _handleMinfoLink() async {
    // Vérification des permissions (Requis pour iOS/Android réels)
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showError("Permission micro nécessaire pour détecter l'AudioQR.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Écoute du signal Minfo...";
    });

    // 2. Lancer la détection via le moteur AudioQR
    final detectionResult = await MinfoSdk.instance.audioEngine.startDetection();

    detectionResult.when(
      success: (signal) {
        setState(() => _statusMessage = "Signal détecté ! Connexion...");
        _connectToMinfo(signal.signature);
      },
      failure: (error) {
        setState(() => _isProcessing = false);
        _showError("Erreur détection : ${error.message}");
      },
    );
  }

  /// Étape 2 : Envoyer la signature au serveur Minfo pour obtenir l'URL
  Future<void> _connectToMinfo(String signature) async {
    try {
      final deviceContext = await DeviceContext.current();

      final request = ConnectRequest(
        requestingClientType: ClientType.sdkClient,
        requestingClientId: 'VOTRE_CLIENT_ID',
        audioSignature: signature,
        deviceContext: deviceContext,
        sdkVersion: '2.3.0',
        supportedContentTypes: [ContentType.webUrl], engineVersion: '', activeFeatureFlags: [],
      );

      final result = await MinfoSdk.instance.apiClient.connect(request);

      result.when(
        success: (response) {
          setState(() => _isProcessing = false);
          if (response.outcome == Outcome.allow && response.payload?['url'] != null) {
            _openWebView(response.payload!['url']);
          } else {
            _showError("Aucune campagne associée à ce signal.");
          }
        },
        failure: (error) {
          setState(() => _isProcessing = false);
          _showError("Échec de connexion API : $error");
        },
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError("Exception : $e");
    }
  }

  void _openWebView(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MinfoWebView(campaignUrl: url)),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Minfo SDK Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleMinfoLink,
              icon: const Icon(Icons.mic),
              label: const Text("DÉTECTER AUDIO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}