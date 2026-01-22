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
    _audioEngine = AudioQREngine(
      channel: _channel,
      minfoChannel: _minfoChannel,
    );
  }
  static MinfoSdk get instance => _instance;

  StreamController<String>? _soundcodeController;
  Stream<String>? get soundcodeStream => _soundcodeController?.stream;

  // Initialiser le SDK avec JWT
  Future<bool> initialiser(String tokenJwt) async {
    final success = await _apiClient.genererClesApi(tokenJwt);
    // NE PAS démarrer automatiquement la détection ici
    // L'app doit d'abord demander les permissions puis appeler startAudioCapture()
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

  // Vérifier et configurer le listener si nécessaire
  void _ensureListenerConfigured() {
    // Vérifier si le listener est déjà configuré en testant si le channel a un handler
    // Note: On ne peut pas vérifier directement, donc on le configure toujours
    print('🔧 [MINFO_SDK] Vérification/Configuration du listener...');
    _minfoChannel.setMethodCallHandler(_gererAppelsNatifsMinfo);
    print('✅ [MINFO_SDK] Listener configuré/recongfiguré');
  }

  // Méthode publique pour configurer le listener manuellement
  void configureListener() {
    _ensureListenerConfigured();
  }

  // Charger les clés existantes
  Future<bool> chargerCles() async {
    final success = await _apiClient.chargerClesApi();
    // NE PAS démarrer automatiquement la détection ici
    // L'app doit d'abord demander les permissions puis appeler startAudioCapture()
    return success;
  }

  // Démarrer la détection audio - Système exact du fichier de référence
  Future<void> _demarrerDetectionAudio() async {
    print('🚀 [MINFO_SDK] _demarrerDetectionAudio() appelé');
    _soundcodeController = StreamController<String>.broadcast();
    print('✅ [MINFO_SDK] StreamController créé');

    try {
      // Initialiser le moteur AudioQR (pour compatibilité)
      print('⚙️ [MINFO_SDK] Initialisation du moteur AudioQR...');
      await _audioEngine.initialise();
      print('✅ [MINFO_SDK] Moteur AudioQR initialisé');

      // Configurer le listener pour le channel exact du fichier de référence
      print(
          '📡 [MINFO_SDK] Configuration du listener pour le channel minfo...');
      _minfoChannel.setMethodCallHandler(_gererAppelsNatifsMinfo);
      print('✅ [MINFO_SDK] Listener configuré');

      // Démarrer la capture audio avec le système exact
      print('📤 [MINFO_SDK] Envoi de startAudioCapture vers le natif...');
      await _minfoChannel.invokeMethod('startAudioCapture');
      print('✅ [MINFO_SDK] startAudioCapture envoyé avec succès');
      print('✅ [MINFO_SDK] Moteur AudioQR initialisé et capture démarrée');
    } catch (e) {
      print('❌ [MINFO_SDK] Erreur initialisation moteur AudioQR: $e');
    }
  }

  // Gérer les appels depuis le code natif - Format exact du fichier de référence
  Future<void> _gererAppelsNatifsMinfo(MethodCall call) async {
    print('📥 [MINFO_SDK] Événement reçu depuis le natif: ${call.method}');
    print('📦 [MINFO_SDK] Arguments bruts: ${call.arguments}');

    switch (call.method) {
      case 'onDetectedId':
        print('🎯 [MINFO_SDK] onDetectedId reçu - Traitement...');
        // Format exact du fichier de référence : [type, result[1], result[2], result[3]]
        // type: 0 = Sons normaux (SoundCode), 1 = Ultrasons (UltraCode)
        final detectedData = call.arguments as List<dynamic>;
        print('📊 [MINFO_SDK] Données détectées (format): $detectedData');

        if (detectedData.length >= 4) {
          final int soundType = detectedData[0] as int;
          final int audioId = detectedData[1] as int;
          final int counter = detectedData[2] as int;
          final int timestamp = detectedData[3] as int;

          print(
              '🔔 [MINFO_SDK] Signal détecté ! Type: $soundType, ID: $audioId, Counter: $counter, Timestamp: $timestamp');

          // Transmettre à AudioQREngine pour startDetection()
          print(
              '📤 [MINFO_SDK] Transmission à AudioQREngine.handleDetectedId()...');
          _audioEngine.handleDetectedId(detectedData);
          print('✅ [MINFO_SDK] Transmission à AudioQREngine terminée');

          // Convertir l'audioId en signature pour l'API
          print('🌐 [MINFO_SDK] Génération du soundcode pour l\'API...');
          final signature = audioId.toString();
          final soundcode = await _apiClient.genererSoundcode(signature);
          if (soundcode != null) {
            print('✅ [MINFO_SDK] Soundcode généré: $soundcode');
            print('📤 [MINFO_SDK] Ajout au stream...');
            _soundcodeController?.add(soundcode);
            print('✅ [MINFO_SDK] Ajouté au stream avec succès');
          } else {
            print('⚠️ [MINFO_SDK] Soundcode null, non ajouté au stream');
          }
        } else {
          print(
              '❌ [MINFO_SDK] Format de données invalide, longueur: ${detectedData.length}');
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
    print('🚀 [MINFO_SDK] startAudioCapture() appelé manuellement');
    try {
      // Créer le StreamController si nécessaire
      _soundcodeController ??= StreamController<String>.broadcast();

      // Configurer le listener pour recevoir les résultats
      print('📡 [MINFO_SDK] Configuration du listener...');
      _minfoChannel.setMethodCallHandler(_gererAppelsNatifsMinfo);
      print('✅ [MINFO_SDK] Listener configuré');

      // Envoyer la commande au natif
      print('📤 [MINFO_SDK] Envoi de startAudioCapture vers le natif...');
      await _minfoChannel.invokeMethod('startAudioCapture');
      print('✅ [MINFO_SDK] Capture audio démarrée');
    } catch (e) {
      print('❌ [MINFO_SDK] Erreur lors du démarrage de la capture: $e');
      rethrow;
    }
  }

  // Arrêter la capture audio manuellement - Système exact du fichier de référence
  Future<void> stopAudioCapture() async {
    print('⏹️ [MINFO_SDK] stopAudioCapture() appelé manuellement');
    try {
      print('📤 [MINFO_SDK] Envoi de stopAudioCapture vers le natif...');
      await _minfoChannel.invokeMethod('stopAudioCapture');
      print('✅ [MINFO_SDK] Capture audio arrêtée');
    } catch (e) {
      print('❌ [MINFO_SDK] Erreur lors de l\'arrêt de la capture: $e');
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
