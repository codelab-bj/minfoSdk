import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class IOSAudioDebug {
  static const MethodChannel _channel = MethodChannel('com.minfo_sdk/audio_debug');
  
  static Future<Map<String, dynamic>> getAudioSessionInfo() async {
    try {
      final result = await _channel.invokeMethod('getAudioSessionInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      developer.log('❌ Erreur récupération info audio: $e');
      return {};
    }
  }
  
  static Future<bool> optimizeForAudioDetection() async {
    try {
      final result = await _channel.invokeMethod('optimizeForAudioDetection');
      return result == true;
    } catch (e) {
      developer.log('❌ Erreur optimisation audio: $e');
      return false;
    }
  }
  
  static Future<void> logAudioSessionDetails() async {
    final info = await getAudioSessionInfo();
    developer.log('🎵 === INFO SESSION AUDIO iOS ===');
    info.forEach((key, value) {
      developer.log('🎵 $key: $value');
    });
    developer.log('🎵 ================================');
  }
}
