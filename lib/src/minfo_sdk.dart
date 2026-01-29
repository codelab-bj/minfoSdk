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

  // Getters de compatibilité (anciens noms)
  String? get campaignName => name;
  String? get campaignImage => image;
  String? get campaignId => id?.toString();
  String? get name => campaignData?['name'];
  String? get campaignDescription => campaignData?['campaign_description'];
  String? get image => campaignData?['image'];
  String? get qrCode => campaignData?['qr_code'];
  String? get smartLink => campaignData?['smart_link'];
  String? get smartShortLink => campaignData?['smart_short_link'];
  String? get shareSmartLink => campaignData?['share_smart_link'];
  String? get campaignNo => campaignData?['campaign_no'];
  String? get hashtags => campaignData?['hashtags'];
  String? get department => campaignData?['department'];
  String? get fromEvent => campaignData?['from_event'];
  
  // Couleurs et style
  String? get backgroundColor => campaignData?['background_color'];
  String? get foregroundColor => campaignData?['foreground_color'];
  String? get backgroundImage => campaignData?['background_image'];
  String? get backgroundSelectedColor => campaignData?['background_selected_color'];
  String? get appbarBackgroundColor => campaignData?['background_app_bar_color'];
  String? get appbarForegroundColor => campaignData?['foreground_app_bar_color'];
  String? get qrCodeColor => campaignData?['qr_code_color'];
  
  // Icônes
  String? get iconBackgroundLeft => campaignData?['icon_background_color_left'];
  String? get iconBackgroundRight => campaignData?['icon_background_color_right'];
  String? get iconForegroundLeft => campaignData?['icon_foreground_color_left'];
  String? get iconForegroundRight => campaignData?['icon_foreground_color_right'];
  int? get itemRowIcons => campaignData?['item_row_icons'];
  
  // Dates et temps
  DateTime? get startTime => campaignData?['start_time'] != null ? DateTime.tryParse(campaignData!['start_time']) : null;
  DateTime? get endTime => campaignData?['end_time'] != null ? DateTime.tryParse(campaignData!['end_time']) : null;
  DateTime? get createdAt => campaignData?['created_at'] != null ? DateTime.tryParse(campaignData!['created_at']) : null;
  int? get timezone => campaignData?['timezone'];
  String? get campaignTimeZone => campaignData?['campaign_time_zone'];
  
  // Flags booléens
  bool? get isEnable => campaignData?['is_enable'];
  bool? get isDeleted => campaignData?['is_deleted'];
  bool? get displayInSearch => campaignData?['display_in_search'];
  bool? get isElevator => campaignData?['is_elevator'];
  bool? get isTvRemote => campaignData?['is_tv_remote'];
  bool? get isCountryRegion => campaignData?['is_country_region'];
  bool? get isParticipant => campaignData?['is_participant'];
  bool? get isSellingItem => campaignData?['is_selling_item'];
  bool? get enableAbTesting => campaignData?['enable_ab_testing'];
  bool? get sendEmailToParticipant => campaignData?['send_email_to_participant'];
  bool? get canScan => campaignData?['can_scan'];
  
  // Types et compteurs
  int? get scanType => campaignData?['scanType'];
  int? get campaignType => campaignData?['campaign_type'];
  int? get numViews => campaignData?['num_views'];
  int? get itemCount => campaignData?['itemscounts'];
  int? get campaignItemsGroupsNumber => campaignData?['count_campaign_item_group'];
  int? get campaignItemsNumber => campaignData?['count_campaign_item'];
  
  // Statistiques de connexion
  int? get audioType1Count => campaignData?['count_audio_type_1'];
  int? get audioType2Count => campaignData?['count_audio_type_2'];
  int? get smartLinkCount => campaignData?['count_smart_link'];
  int? get qrCodeCount => campaignData?['count_qr_code'];
  int? get uniqueShareCount => campaignData?['share_count_campaign']?['share_unique'];
  int? get totalConnections => campaignData?['total_connections'];
  int? get totalUniqueConnections => campaignData?['total_unique_connections'];
  int? get mostConnectionDuration => campaignData?['most_connection_duration'];
  int? get totalLengthContent => campaignData?['total_length_content'];
  int? get totalUniqueChatsStarted => campaignData?['total_unique_chats_started'];
  
  // Chat et communication
  bool? get contactUserByChat => campaignData?['contact_user_by_chat'];
  bool? get addDiscusionGroup => campaignData?['add_discusion_group'];
  bool? get displayAsList => campaignData?['display_as_list'];
  bool? get directChatCampaign => campaignData?['direct_chat_campaign'];
  String? get tchatGroupId => campaignData?['tchat_group_id'];
  
  // IA et automatisation
  bool? get aiAutoResponseEnabled => campaignData?['ai_auto_response_enabled'];
  String? get selectedAi => campaignData?['selected_ai'];
  String? get openaiApiKey => campaignData?['openai_api_key'];
  String? get openaiModel => campaignData?['openai_model'];
  String? get geminiApiKey => campaignData?['gemini_api_key'];
  String? get geminiModel => campaignData?['gemini_model'];
  String? get claudeApiKey => campaignData?['claude_api_key'];
  String? get claudeModel => campaignData?['claude_model'];
  String? get baseInstructions => campaignData?['base_instructions'];
  String? get videoTranscript => campaignData?['video_transcript'];
  String? get videoDescription => campaignData?['video_description'];
  
  // Classification industrielle
  String? get sector => campaignData?['sector'];
  String? get industryGroup => campaignData?['industry_group'];
  String? get industry => campaignData?['industry'];
  String? get subIndustry => campaignData?['sub_industry'];
  
  // Objets complexes
  Map<String, dynamic>? get brand => campaignData?['brand'];
  Map<String, dynamic>? get category => campaignData?['category'];
  Map<String, dynamic>? get createdBy => campaignData?['created_by'];
  Map<String, dynamic>? get campaignSecurity => campaignData?['campaign_security'];
  Map<String, dynamic>? get elevatorDetails => campaignData?['elevator_details'];
  Map<String, dynamic>? get itemSetup => campaignData?['item_setup'];
  Map<String, dynamic>? get sellingItemDetails => campaignData?['selling_item_details'];
  Map<String, dynamic>? get tvRemoteDetails => campaignData?['tv_remote_details'];
  Map<String, dynamic>? get eventDetails => campaignData?['event_details'];
  Map<String, dynamic>? get participation => campaignData?['participation'];
  Map<String, dynamic>? get minfoMediaPowered => campaignData?['minfo_powered_media'];
  Map<String, dynamic>? get videoThumbnail => campaignData?['video_thumbnail'];
  
  // Listes
  List<dynamic>? get campaignAudios => campaignData?['campaign_audios'];
  List<dynamic>? get campaignGroups => campaignData?['campaign_groups'];
  List<dynamic>? get campaignLocations => campaignData?['campaign_locations'];
  List<dynamic>? get campaignMedialinks => campaignData?['campaign_medialinks'];
  List<dynamic>? get campaignLiftFloors => campaignData?['campaign_lift_floors'];
  List<dynamic>? get campaignLiftAreas => campaignData?['campaign_lift_areas'];
  List<dynamic>? get eventRoles => campaignData?['event_roles'];
  List<dynamic>? get contextFiles => campaignData?['context_files'];
  List<dynamic>? get userCanEdit => campaignData?['user_can_edit'];
  List<dynamic>? get additionalCreators => campaignData?['additional_creators'];
  List<dynamic>? get tabAllUserFriend => campaignData?['tab_all_user_friend'];

  @override
  String toString() {
    return 'CampaignResult(audioId: $audioId, name: $name, url: $campaignUrl, error: $error)';
  }
}
