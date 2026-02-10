
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/ios_audio_debug.dart';
import 'dart:io';
import 'dart:developer' as developer;

class AudioSessionManager {
  static Future<bool> setupAudioSessionForMinfo() async {
    developer.log('🎵 Configuration session audio pour Minfo...');
    
    try {
      final session = await AudioSession.instance;
      
      // Configuration spécifique pour la détection audio
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      
      // Debug spécifique iOS
      if (Platform.isIOS) {
        developer.log('🎵 📱 Debug session audio iOS...');
        await IOSAudioDebug.logAudioSessionDetails();
        await IOSAudioDebug.optimizeForAudioDetection();
      }
      
      developer.log('🎵 ✅ Session audio configurée avec succès');
      return true;
    } catch (e) {
      developer.log('🎵 ❌ Erreur configuration session audio: $e');
      return false;
    }
  }
  
  static Future<bool> requestMicrophoneWithAudioSession() async {
    developer.log('🎤 Début processus complet permission + session audio', name: 'minfo.permissions');
    
    // 1. Vérifier permission microphone
    final status = await Permission.microphone.status;
    developer.log('🎤 Statut permission: $status', name: 'minfo.permissions');
    
    if (status.isPermanentlyDenied) {
      developer.log('🎤 ❌ Permission refusée définitivement', name: 'minfo.permissions');
      await openAppSettings();
      return false;
    }
    
    // 2. Demander permission si nécessaire
    if (!status.isGranted) {
      developer.log('🎤 📱 Demande permission...', name: 'minfo.permissions');
      final result = await Permission.microphone.request();
      developer.log('🎤 📱 Résultat: $result', name: 'minfo.permissions');
      
      if (!result.isGranted) {
        developer.log('🎤 ❌ Permission refusée par utilisateur', name: 'minfo.permissions');
        return false;
      }
    }
    
    // 3. Attendre iOS
    await Future.delayed(Duration(milliseconds: 500));
    
    // 4. Configurer session audio APRÈS permission
    developer.log('🎤 ✅ Permission accordée, configuration session audio...', name: 'minfo.permissions');
    final audioConfigured = await setupAudioSessionForMinfo();
    
    if (!audioConfigured) {
      developer.log('🎤 ❌ Échec configuration session audio', name: 'minfo.permissions');
      return false;
    }
    
    // 5. Vérification finale
    final finalStatus = await Permission.microphone.status;
    developer.log('🎤 Statut final: $finalStatus', name: 'minfo.permissions');
    
    return finalStatus.isGranted;
  }
}

class MinfoDetectionManager {
  static Future<bool> startDetectionWithProperSetup() async {
    developer.log('🚀 Début détection Minfo avec setup complet');
    
    try {
      // 1. Setup permissions + audio session
      final hasAccess = await AudioSessionManager.requestMicrophoneWithAudioSession();
      
      if (!hasAccess) {
        developer.log('🚀 ❌ Pas d\'accès audio, arrêt');
        return false;
      }
      
      // 2. Initialiser le moteur AudioQR AVANT de démarrer
      developer.log('🚀 🔧 Initialisation du moteur AudioQR...');
      final engineInitialized = await MinfoSdk.instance.audioEngine.initialise();
      
      if (!engineInitialized) {
        developer.log('🚀 ❌ Échec initialisation moteur AudioQR');
        return false;
      }
      
      developer.log('🚀 ✅ Moteur AudioQR initialisé');
      
      // 3. Configurer le listener
      developer.log('🚀 📡 Configuration du listener...');
      MinfoSdk.instance.configureListener();
      
      // 4. Attendre stabilisation iOS
      developer.log('🚀 ⏳ Attente stabilisation iOS...');
      await Future.delayed(Duration(milliseconds: 1000));
      
      // 5. Démarrer détection Minfo
      developer.log('🚀 🎯 Démarrage détection Minfo...');
      await MinfoSdk.instance.audioEngine.startDetection();
      
      developer.log('🚀 ✅ Détection démarrée avec succès');
      return true;
      
    } catch (e) {
      developer.log('🚀 ❌ Erreur détection: $e');
      return false;
    }
  }
}
