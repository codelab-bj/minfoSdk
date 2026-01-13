import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 [MINFO] Démarrage de l\'application...');

  try {
    // 1. Initialisation globale
    debugPrint('⚙️ [MINFO] Initialisation du SDK...');
    await MinfoSdk.instance.init(
      clientId: 'VOTRE_CLIENT_ID',
      apiKey: 'VOTRE_API_KEY',
    );
    debugPrint('✅ [MINFO] SDK Initialisé avec succès.');
  } catch (e) {
    debugPrint('❌ [MINFO] Erreur critique lors de l\'initialisation: $e');
  }

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
    debugPrint('🎤 [ACTION] Bouton pressé : Vérification des permissions...');

    final status = await Permission.microphone.request();
    debugPrint('📡 [PERMISSION] Statut du micro : $status');

    if (!status.isGranted) {
      debugPrint('⚠️ [PERMISSION] Accès micro refusé par l\'utilisateur.');
      _showError("Permission micro nécessaire pour détecter l'AudioQR.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Écoute du signal Minfo...";
    });

    debugPrint('👂 [MINFO] Démarrage de audioEngine.startDetection()...');
    final detectionResult = await MinfoSdk.instance.audioEngine.startDetection();

    detectionResult.when(
      success: (signal) {
        debugPrint('🎯 [DETECTION] Signal capturé ! Signature: ${signal.signature}');
        debugPrint('📊 [DETECTION] Confiance: ${signal.confidence}');
        setState(() => _statusMessage = "Signal détecté ! Connexion...");
        _connectToMinfo(signal.signature);
      },
      failure: (error) {
        debugPrint('🚨 [DETECTION] Échec : ${error.message}');
        setState(() => _isProcessing = false);
        _showError("Erreur détection : ${error.message}");
      },
    );
  }

  /// Étape 2 : Envoyer la signature au serveur Minfo pour obtenir l'URL
  Future<void> _connectToMinfo(String signature) async {
    debugPrint('🌐 [API] Tentative de connexion au serveur Minfo...');
    try {
      final deviceContext = await DeviceContext.current();
      debugPrint('📱 [DEVICE] Context récupéré ');

      final request = ConnectRequest(
        requestingClientType: ClientType.sdkClient,
        requestingClientId: 'VOTRE_CLIENT_ID',
        audioSignature: signature,
        deviceContext: deviceContext,
        sdkVersion: '2.3.0',
        supportedContentTypes: [ContentType.webUrl],
        engineVersion: '1.0.0',
        activeFeatureFlags: ['audioqr_enabled'],
      );

      debugPrint('📤 [API] Envoi de la requête Connect...');
      final result = await MinfoSdk.instance.apiClient.connect(request);

      result.when(
        success: (response) {
          debugPrint('📥 [API] Réponse reçue. Outcome: ${response.outcome}');
          setState(() => _isProcessing = false);

          if (response.outcome == Outcome.allow && response.payload?['url'] != null) {
            String url = response.payload!['url'];
            debugPrint('🔗 [API] URL de la campagne : $url');
            _openWebView(url);
          } else {
            debugPrint('❓ [API] Pas d\'URL trouvée ou accès refusé.');
            _showError("Aucune campagne associée à ce signal.");
          }
        },
        failure: (error) {
          debugPrint('❌ [API] Erreur de communication : $error');
          setState(() => _isProcessing = false);
          _showError("Échec de connexion API : $error");
        },
      );
    } catch (e) {
      debugPrint('💥 [EXCEPTION] Une erreur est survenue : $e');
      setState(() => _isProcessing = false);
      _showError("Exception : $e");
    }
  }

  void _openWebView(String url) {
    debugPrint('🖥️ [UI] Ouverture de la WebView Minfo...');
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