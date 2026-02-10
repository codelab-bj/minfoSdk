import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/ios_audio_debug.dart';
import 'dart:io';


class AudioSessionManager {
  static final _logger = MinfoLogger();

  static Future<bool> setupAudioSessionForMinfo() async {
    _logger.info('🎵 Configuration session audio pour Minfo...');

    try {
      final session = await AudioSession.instance;

      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      if (Platform.isIOS) {
        await IOSAudioDebug.logAudioSessionDetails();
        await IOSAudioDebug.optimizeForAudioDetection();
      }

      _logger.info('🎵 ✅ Session audio configurée');
      return true;
    } catch (e) {
      _logger.error('🎵 ❌ Erreur session audio: $e');
      return false;
    }
  }

  static Future<bool> requestMicrophoneWithAudioSession() async {
    final status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) return false;
    }

    // CORRECTION: const Duration
    await Future.delayed(const Duration(milliseconds: 500));

    return await setupAudioSessionForMinfo();
  }
}

class MinfoDetectionManager {
  static final _logger = MinfoLogger();

  static Future<bool> startDetectionWithProperSetup() async {
    _logger.info('🚀 Début détection Minfo avec setup complet');

    try {
      final hasAccess = await AudioSessionManager.requestMicrophoneWithAudioSession();
      if (!hasAccess) return false;

      final engineInitialized = await MinfoSdk.instance.audioEngine.initialise();
      if (!engineInitialized) return false;

      MinfoSdk.instance.configureListener();

      // CORRECTION: const Duration
      await Future.delayed(const Duration(milliseconds: 1000));

      await MinfoSdk.instance.audioEngine.startDetection();
      return true;
    } catch (e) {
      _logger.error('🚀 ❌ Erreur détection: $e');
      return false;
    }
  }
}