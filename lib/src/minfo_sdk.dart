import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'minfo_auth.dart';
import 'audio_qr_engine.dart';

class MinfoSdk {
  static const MethodChannel _channel = MethodChannel('com.minfo_sdk/audioqr');
  static const MethodChannel _minfoChannel = MethodChannel('com.gzone.campaign/audioCapture');

  final MinfoApiClient _apiClient = MinfoApiClient();
  late final AudioQREngine _audioEngine;
  
  // Singleton
  static final MinfoSdk _instance = MinfoSdk._internal();
  factory MinfoSdk() => _instance;
  MinfoSdk._internal() {
    _audioEngine = AudioQREngine(channel: _channel);
  }
  static MinfoSdk get instance => _instance;
  
  StreamController<String>? _soundcodeController;
  Stream<String>? get soundcodeStream => _soundcodeController?.stream;

  // Initialiser le SDK avec JWT
  Future<bool> initialiser(String tokenJwt) async {
    final success = await _apiClient.genererClesApi(tokenJwt);
    if (success) {
      await _demarrerDetectionAudio();
    }
    return success;
  }

  // Méthode init pour compatibilité avec l'exemple
  Future<bool> init({String? clientId, String? apiKey, String? publicKey, String? privateKey, String? baseUrl}) async {
    if (apiKey != null) {
      return await initialiser(apiKey);
    }
    if (publicKey != null && privateKey != null) {
      // Charger directement les clés API
      const storage = FlutterSecureStorage();
      await storage.write(key: 'minfo_cle_publique', value: publicKey);
      await storage.write(key: 'minfo_cle_privee', value: privateKey);
      return await chargerCles();
    }
    return false;
  }

  // Login et génération de clés
  Future<Map<String, String>?> loginAndGenerateKeys(String email, String password, {String? baseUrl}) async {
    final auth = MinfoAuth(baseUrl: baseUrl ?? 'https://api.dev.minfo.com');
    return await auth.getApiKeys(email, password);
  }

  // Générer les clés API (méthode publique selon documentation)
  Future<bool> generateApiKeys() async {
    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'minfo_jwt_token');
    
    if (jwt == null) {
      throw Exception('JWT token requis. Utilisez loginAndGenerateKeys() d\'abord.');
    }
    
    return await _apiClient.genererClesApi(jwt);
  }

  // Accès aux composants
  MinfoApiClient get apiClient => _apiClient;
  AudioQREngine get audioEngine => _audioEngine;

  // Charger les clés existantes
  Future<bool> chargerCles() async {
    final success = await _apiClient.chargerClesApi();
    if (success) {
      await _demarrerDetectionAudio();
    }
    return success;
  }

  // Démarrer la détection audio
  Future<void> _demarrerDetectionAudio() async {
    _soundcodeController = StreamController<String>.broadcast();
    
    try {
      // Initialiser le moteur AudioQR
      await _audioEngine.initialise();
      _channel.setMethodCallHandler(_gererAppelsNatifs);
      print('✅ Moteur AudioQR initialisé');
    } catch (e) {
      print('Erreur initialisation moteur AudioQR: $e');
    }
  }

  // Gérer les appels depuis le code natif
  Future<void> _gererAppelsNatifs(MethodCall call) async {
    switch (call.method) {
      case 'onSignalDetected':
        final args = call.arguments as Map;
        final signature = args['codes'] as String;
        final soundcode = await _apiClient.genererSoundcode(signature);
        if (soundcode != null) {
          _soundcodeController?.add(soundcode);
        }
        break;
    }
  }

  // Récupérer les campagnes
  Future<List<dynamic>?> obtenirCampagnes() async {
    return await _apiClient.obtenirCampagnes();
  }

  // Obtenir l'URL de campagne pour une signature
  Future<String?> getCampaignUrl(String signature) async {
    return await _apiClient.getCampaignUrl(signature);
  }

  // Arrêter la détection
  Future<void> arreter() async {
    await _channel.invokeMethod('stopDetection');
    _soundcodeController?.close();
    _soundcodeController = null;
  }
}
