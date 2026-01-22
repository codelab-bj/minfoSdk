import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import de l'outil de diagnostic
import 'audio_diagnostic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController(text: MinfoEnvironments.defaultUrl);
  
  bool _isLoading = false;
  String _status = 'Entrez vos identifiants pour générer les clés API';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minfo SDK - Configuration"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'URL Serveur',
                  hintText: MinfoEnvironments.defaultUrl,
                  helperText: '✅ URL testée et fonctionnelle',
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String url) {
                      _urlController.text = url;
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: MinfoEnvironments.prod, child: Text('Prod/Dev ✅')),
                      PopupMenuItem(value: "https://api.staging.minfo.com", child: Text('Staging ❌')),
                      PopupMenuItem(value: "http://192.168.100.55:8081", child: Text('Local ❌')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'votre@email.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateKeysAndInit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text("GÉNÉRER CLÉS & INITIALISER SDK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateKeysAndInit() async {
    setState(() {
      _isLoading = true;
      _status = 'Génération des clés...';
    });

    try {
      final keys = await MinfoSdk.instance.loginAndGenerateKeys(
        _emailController.text,
        _passwordController.text,
      );

      if (keys != null) {
        await MinfoSdk.instance.init(
          publicKey: keys['public_key']!,
          privateKey: keys['private_key']!,
          baseUrl: _urlController.text,
        );

        setState(() {
          _status = '✅ SDK initialisé avec succès!';
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MinfoExamplePage()),
        );
      } else {
        setState(() {
          _status = '❌ Échec de la génération des clés';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class MinfoExamplePage extends StatefulWidget {
  const MinfoExamplePage({super.key});

  @override
  State<MinfoExamplePage> createState() => _MinfoExamplePageState();
}

class _MinfoExamplePageState extends State<MinfoExamplePage> {
  bool _isProcessing = false;
  String _statusMessage = "SDK initialisé - Prêt à scanner";

  static const MethodChannel _channel = MethodChannel('com.gzone.campaign/audioCapture');

  @override
  void initState() {
    super.initState();

    _channel.setMethodCallHandler((call) async {
      print('🔔 [DEBUG] Channel reçu: ${call.method}');
      print('📦 [DEBUG] Arguments bruts: ${call.arguments}');
      
      if (call.method == "onDetectedId") {
        final List<dynamic> detectedData = call.arguments;
        print('✅ [DEBUG] Données détectées: $detectedData');
        
        if (detectedData.length >= 4) {
          final int soundType = detectedData[0];
          final int audioId = detectedData[1]; 
          final int counter = detectedData[2];
          final int timestamp = detectedData[3];

          print("🎯 [DEBUG] ID extrait: $audioId");
          debugPrint("🔔 [MINFO FORMAT] Signal détecté ! Type: $soundType, ID: $audioId, Counter: $counter, Timestamp: $timestamp");

          setState(() {
            _statusMessage = "✅ Signal ID $audioId détecté ! Analyse serveur...";
          });

          HapticFeedback.mediumImpact();
          
          // Appeler l'API avec le format exact de l'app Minfo
          _connectToMinfoV2(audioId, counter, timestamp, soundType == 0 ? "AUDIO_ID" : "ULTRASOUND");
        }
      }
    });
  }

  Future<void> _connectToMinfoV2(int audioId, int counter, int timestamp, String source) async {
    print('🌐 [API V2] AudioID reçu: $audioId');
    print('🌐 [API V2] Counter: $counter, Timestamp: $timestamp, Source: $source');
    
    if (audioId == 0 || audioId.toString().isEmpty) {
      print('❌ [API V2] AudioID invalide: $audioId');
      setState(() => _statusMessage = "❌ ID audio invalide");
      return;
    }
    
    try {
      final url = 'https://api.dev.minfo.com/api/minfo/campaign/v2?audio_id=$audioId&counter=$counter&timestamp=$timestamp&origin=FLUTTER_SDK&source=$source&lang=fr';
      print('🔗 [API V2] URL construite: $url');
      
      // Utiliser MinfoSdk pour l'API call
      final result = await MinfoSdk.instance.apiClient.connect({
        'audioSignature': audioId.toString(),
        'counter': counter,
        'timestamp': timestamp,
        'source': source
      });
      
      print('📡 [API V2] Résultat: $result');

      setState(() => _isProcessing = false);

      if (result != null && result['outcome'] == 'allow') {
        setState(() => _statusMessage = "✅ Campagne trouvée !");
      } else {
        setState(() => _statusMessage = "❌ Aucune campagne trouvée.");
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Erreur: $e";
      });
    }
  }

  Future<void> _handleMinfoLink() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showError("Permission micro nécessaire.");
      return;
    }

    print('🎤 [DEBUG] Permission micro accordée');
    print('🎤 [DEBUG] Démarrage détection...');

    setState(() {
      _isProcessing = true;
      _statusMessage = "Écoute en cours...";
    });

    final detectionResult = await MinfoSdk.instance.audioEngine.startDetection();

    detectionResult.when(
      success: (signal) {
        print('🎯 [DETECTION] Signature reçue: ${signal.signature}');
        debugPrint('🎯 [DETECTION] Signature: ${signal.signature}');
      },
      failure: (error) {
        print('❌ [DETECTION] Erreur: ${error.message}');
        setState(() {
          _isProcessing = false;
          _statusMessage = "❌ ${error.message}";
        });
      },
    );

    // Ajouter un timeout côté Flutter aussi
    Future.delayed(const Duration(seconds: 10), () {
      if (_isProcessing) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "⏰ Timeout - Aucun signal détecté";
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
        title: const Text("Minfo Audio Detector"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AudioDiagnostic()),
              ),
              icon: const Icon(Icons.bug_report),
              label: const Text('DIAGNOSTIC AUDIO'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 20),
            
            Icon(
              _isProcessing ? Icons.waves : Icons.mic_none,
              size: 80,
              color: _isProcessing ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 30),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleMinfoLink,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_isProcessing ? "SCAN EN COURS..." : "DÉTECTER LE SON"),
            ),
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton(
                  onPressed: () => setState(() => _isProcessing = false),
                  child: const Text("Annuler"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
