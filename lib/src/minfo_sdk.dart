import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'api_client.dart';
import 'minfo_auth.dart';
import 'audio_qr_engine.dart';
import 'utils.dart';

class MinfoSdk {
  static const MethodChannel _minfoChannel = MethodChannel('com.gzone.campaign/audioCapture');
  static const MethodChannel _qrChannel = MethodChannel('com.minfo_sdk/audioqr');

  static final MinfoSdk _instance = MinfoSdk._internal();
  factory MinfoSdk() => _instance;
  static MinfoSdk get instance => _instance;

  final _logger = MinfoLogger();
  final _apiClient = MinfoApiClient();
  final _auth = MinfoAuth();
  late final AudioQREngine _audioEngine;

  bool _isListening = false;
  bool _hasDetected = false;
  bool _isProcessing = false;

  StreamSubscription? _internalSub;
  StreamController<CampaignResult>? _controller;

  MinfoSdk._internal() {
    _audioEngine = AudioQREngine(
      channel: _qrChannel,
      minfoChannel: _minfoChannel,
    );
    // On attache le handler dès l'instanciation
    _minfoChannel.setMethodCallHandler(_handleNativeEvents);
  }

  // ---------- GETTER STREAM ----------

  Stream<CampaignResult> get campaignStream {
    _controller ??= StreamController<CampaignResult>.broadcast();
    return _controller!.stream;
  }

  // ---------- INIT ----------

  static Future<void> initialize({
    required String publicApiKey,
    required String privateApiKey,
  }) async {
    final auth = MinfoAuth();
    await auth.storeApiKeys(publicApiKey, privateApiKey);
  }

  // ---------- API PUBLIQUE ----------

  Future<void> startScan({
    required Function(CampaignResult) onResult,
    Function(String)? onError,
  }) async {
    if (_isListening) return;

    try {
      // 1. GESTION INTELLIGENTE DES PERMISSIONS
      // Sur iOS : Uniquement MICROPHONE
      // Sur Android : MICROPHONE + PHONE
      List<Permission> permissionsToRequest = [Permission.microphone];

      if (Platform.isAndroid) {
        permissionsToRequest.add(Permission.phone);
      }

      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

      // Vérification Microphone (Commun à tous)
      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        onError?.call("L'accès au microphone est indispensable pour scanner.");
        return;
      }

      // Vérification Téléphone (Spécifique Android)
      if (Platform.isAndroid && statuses[Permission.phone] != PermissionStatus.granted) {
        onError?.call("Permission téléphone requise sur Android pour le moteur audio.");
        return;
      }

      // 2. CONFIGURATION API
      final keys = await _auth.getStoredApiKeys();
      if (keys != null) {
        _apiClient.setExternalKeys(keys['public_key']!, keys['private_key']!);
      } else {
        onError?.call("Clés API manquantes. Initialisez le SDK.");
        return;
      }

      // 3. RÉINITIALISATION DES ÉTATS
      _isListening = true;
      _isProcessing = true;
      _hasDetected = false;

      // 4. ÉCOUTE DU FLUX POUR L'UI
      await _internalSub?.cancel();
      _internalSub = campaignStream.listen(
            (result) => onResult(result),
        onError: (e) => onError?.call(e.toString()),
      );

      // 5. DÉMARRAGE NATIF
      await _minfoChannel.invokeMethod('startAudioCapture');
      _logger.info("🚀 Scan Minfo démarré");

    } catch (e) {
      _isListening = false;
      _isProcessing = false;
      onError?.call("Erreur lors du démarrage : $e");
    }
  }

  Future<void> stop() async {
    _isListening = false;
    _isProcessing = false;
    _hasDetected = false;

    await _internalSub?.cancel();
    _internalSub = null;

    try {
      await _minfoChannel.invokeMethod('stopAudioCapture');
      _audioEngine.stopDetection();
      _logger.info("⏹️ Scan Minfo arrêté");
    } catch (e) {
      _logger.error("Erreur lors de l'arrêt : $e");
    }
  }

  // ---------- GESTIONNAIRE D'ÉVÉNEMENTS NATIFS ----------

  Future<void> _handleNativeEvents(MethodCall call) async {
    if (call.method != 'onDetectedId') return;

    // On ignore si on ne scanne pas ou si on traite déjà un ID
    if (!_isListening || _hasDetected || !_isProcessing) return;

    final args = call.arguments as List<dynamic>;
    if (args.length < 2) return;

    final int audioId = args[1];

    // Verrouillage immédiat pour éviter les appels API en boucle
    _hasDetected = true;
    _isProcessing = false;

    try {
      _logger.info("🎯 Audio ID détecté nativement : $audioId. Récupération campagne...");

      final data = await _apiClient.getCampaignData(audioId.toString());

      if (data == null) {
        _logger.warning("⚠️ Aucune donnée pour l'ID $audioId");
        _hasDetected = false;
        _isProcessing = true; // On déverrouille pour continuer à chercher
        return;
      }

      final result = CampaignResult(
        audioId: audioId,
        campaignUrl: data['campaign_url'] ?? data['url'],
        campaignData: data,
        timestamp: DateTime.now(),
      );

      // Envoi du résultat à l'UI via le Stream
      _controller?.add(result);

      // On attend un peu pour que l'utilisateur voit l'info avant de couper le micro
      Future.delayed(const Duration(milliseconds: 500), () => stop());

    } catch (e) {
      _logger.error("❌ Erreur API Minfo : $e");
      _hasDetected = false;
      _isProcessing = true;
    }
  }
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
  String? get id => campaignData?['id']?.toString();
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