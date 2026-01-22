import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'minfo_auth.dart';
import 'audio_qr_engine.dart';

class MinfoSdk {
  static const MethodChannel _channel = MethodChannel('com.minfo_sdk/audioqr');
  static const MethodChannel _minfoChannel = MethodChannel(
    'com.gzone.campaign/audioCapture',
  );

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
  Future<bool> init({
    String? clientId,
    String? apiKey,
    String? publicKey,
    String? privateKey,
    String? baseUrl,
  }) async {
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
  Future<Map<String, String>?> loginAndGenerateKeys(
    String email,
    String password, {
    String? baseUrl,
  }) async {
    final auth = MinfoAuth(baseUrl: baseUrl ?? 'https://api.dev.minfo.com');
    return await auth.getApiKeys(email, password);
  }

  // Générer les clés API (méthode publique selon documentation)
  Future<bool> generateApiKeys() async {
    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'minfo_jwt_token');

    if (jwt == null) {
      throw Exception(
        'JWT token requis. Utilisez loginAndGenerateKeys() d\'abord.',
      );
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

  // Démarrer la détection audio - Système exact du fichier de référence
  Future<void> _demarrerDetectionAudio() async {
    _soundcodeController = StreamController<String>.broadcast();

    try {
      // Initialiser le moteur AudioQR (pour compatibilité)
      await _audioEngine.initialise();

      // Configurer le listener pour le channel exact du fichier de référence
      _minfoChannel.setMethodCallHandler(_gererAppelsNatifsMinfo);

      // Démarrer la capture audio avec le système exact
      await _minfoChannel.invokeMethod('startAudioCapture');

      print('✅ Moteur AudioQR initialisé et capture démarrée');
    } catch (e) {
      print('Erreur initialisation moteur AudioQR: $e');
    }
  }

  // Gérer les appels depuis le code natif - Format exact du fichier de référence
  Future<void> _gererAppelsNatifsMinfo(MethodCall call) async {
    switch (call.method) {
      case 'onDetectedId':
        // Format exact du fichier de référence : [type, result[1], result[2], result[3]]
        // type: 0 = Sons normaux (SoundCode), 1 = Ultrasons (UltraCode)
        final detectedData = call.arguments as List<dynamic>;

        if (detectedData.length >= 4) {
          final int soundType = detectedData[0] as int;
          final int audioId = detectedData[1] as int;
          final int counter = detectedData[2] as int;
          final int timestamp = detectedData[3] as int;

          print(
            '🔔 [MINFO FORMAT] Signal détecté ! Type: $soundType, ID: $audioId, Counter: $counter, Timestamp: $timestamp',
          );

          // Convertir l'audioId en signature pour l'API
          final signature = audioId.toString();
          final soundcode = await _apiClient.genererSoundcode(signature);
          if (soundcode != null) {
            _soundcodeController?.add(soundcode);
          }
        }
        break;
      case 'onSignalDetected':
        // Ancien format pour compatibilité
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

  // Démarrer la capture audio manuellement - Système exact du fichier de référence
  Future<void> startAudioCapture() async {
    try {
      await _minfoChannel.invokeMethod('startAudioCapture');
      print('✅ Capture audio démarrée');
    } catch (e) {
      print('Erreur lors du démarrage de la capture: $e');
      rethrow;
    }
  }

  // Arrêter la capture audio manuellement - Système exact du fichier de référence
  Future<void> stopAudioCapture() async {
    try {
      await _minfoChannel.invokeMethod('stopAudioCapture');
      print('✅ Capture audio arrêtée');
    } catch (e) {
      print('Erreur lors de l\'arrêt de la capture: $e');
      rethrow;
    }
  }

  // Arrêter la détection - Système exact du fichier de référence
  Future<void> arreter() async {
    try {
      // Utiliser stopAudioCapture du système exact
      await stopAudioCapture();
      // Garder aussi l'ancien système pour compatibilité
      await _channel.invokeMethod('stopDetection');
    } catch (e) {
      print('Erreur lors de l\'arrêt de la détection: $e');
    }
    _soundcodeController?.close();
    _soundcodeController = null;
  }
}
