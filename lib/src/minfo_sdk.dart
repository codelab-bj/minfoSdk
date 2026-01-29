import 'dart:async';
import 'package:flutter/services.dart';
import 'api_client.dart';
import 'minfo_auth_manager.dart';
import 'audio_qr_engine.dart';
import 'utils.dart';

/// SDK Minfo pour détection AudioQR avec contrôle utilisateur
class MinfoSdk {
  static const MethodChannel _channel = MethodChannel('com.minfo_sdk/audioqr');
  static const MethodChannel _minfoChannel = MethodChannel(
    'com.gzone.campaign/audioCapture',
  );
  static final _logger = MinfoLogger();

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

  StreamController<CampaignResult>? _campaignController;
  Stream<CampaignResult>? get campaignStream => _campaignController?.stream;
  bool _isListening = false;

  /// Initialise le SDK
  static Future<void> initialize({required String publicApiKey}) async {
    MinfoAuthManager.initialize(publicApiKey);
  }

  // Accès aux composants
  MinfoApiClient get apiClient => _apiClient;
  AudioQREngine get audioEngine => _audioEngine;

  /// Démarre l'écoute AudioQR
  Future<void> listen() async {
    if (_isListening) return;
    
    MinfoAuthManager.ensureInitialized();
    _logger.info('MinfoSdk: Démarrage de l\'écoute');
    
    _campaignController = StreamController<CampaignResult>.broadcast();
    _minfoChannel.setMethodCallHandler(_handleNativeEvents);
    
    try {
      await _minfoChannel.invokeMethod('startAudioCapture');
      _isListening = true;
      _logger.info('MinfoSdk: Écoute démarrée');
    } catch (e) {
      _logger.error('Erreur lors du démarrage: $e');
      rethrow;
    }
  }

  /// Met en pause l'écoute AudioQR
  Future<void> pause() async {
    if (!_isListening) return;
    
    _logger.info('MinfoSdk: Pause de l\'écoute');
    try {
      await _minfoChannel.invokeMethod('stopAudioCapture');
      _isListening = false;
      _logger.info('MinfoSdk: Écoute en pause');
    } catch (e) {
      _logger.error('Erreur lors de la pause: $e');
    }
  }

  /// Arrête complètement l'écoute et ferme le stream
  Future<void> stop() async {
    _logger.info('MinfoSdk: Arrêt complet');
    try {
      if (_isListening) {
        await _minfoChannel.invokeMethod('stopAudioCapture');
      }
      _campaignController?.close();
      _campaignController = null;
      _isListening = false;
    } catch (e) {
      _logger.error('Erreur lors de l\'arrêt: $e');
    }
  }

  /// Gère les événements natifs et retourne les objets campaign
  Future<void> _handleNativeEvents(MethodCall call) async {
    _logger.debug('Événement reçu: ${call.method}');

    switch (call.method) {
      case 'onDetectedId':
        final detectedData = call.arguments as List<dynamic>;

        if (detectedData.length >= 4) {
          final int audioId = detectedData[1] as int;
          _logger.info('Signal détecté ! ID: $audioId');

          // Récupérer les données de campagne complètes
          final campaignData = await _apiClient.getCampaignData(audioId.toString());
          
          if (campaignData != null) {
            final result = CampaignResult(
              audioId: audioId,
              campaignUrl: campaignData['campaign_url'] ?? campaignData['url'],
              campaignData: campaignData,
              timestamp: DateTime.now(),
            );
            
            _logger.info('Campagne trouvée: ${result.campaignUrl}');
            _campaignController?.add(result);
          } else {
            final errorResult = CampaignResult(
              audioId: audioId,
              error: 'Aucune campagne trouvée pour cet ID',
              timestamp: DateTime.now(),
            );
            _campaignController?.add(errorResult);
          }
        }
        break;
    }
  }

  /// Récupère les données d'une campagne par signature
  Future<Map<String, dynamic>?> getCampaignData(String signature) async {
    MinfoAuthManager.ensureInitialized();
    return await _apiClient.getCampaignData(signature);
  }

  /// Vérifie si l'écoute est active
  bool get isListening => _isListening;
}

/// Résultat de détection de campagne
class CampaignResult {
  final int audioId;
  final String? campaignUrl;
  final Map<String, dynamic>? campaignData;
  final String? error;
  final DateTime timestamp;

  CampaignResult({
    required this.audioId,
    this.campaignUrl,
    this.campaignData,
    this.error,
    required this.timestamp,
  });

  bool get hasError => error != null;
  bool get isSuccess => campaignUrl != null && campaignData != null;

  // Getters pour accès facile aux données
  String? get campaignId => campaignData?['id']?.toString();
  String? get campaignName => campaignData?['name'];
  String? get campaignDescription => campaignData?['description'];
  String? get campaignImage => campaignData?['image'];
  Map<String, dynamic>? get metadata => campaignData?['metadata'];

  @override
  String toString() {
    return 'CampaignResult(audioId: $audioId, url: $campaignUrl, error: $error)';
  }
}
