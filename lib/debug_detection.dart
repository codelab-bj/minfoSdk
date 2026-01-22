import 'package:flutter/services.dart';

class DebugDetection {
  // Channel exact du fichier de référence
  static const MethodChannel _minfoChannel = MethodChannel('com.gzone.campaign/audioCapture');
  // Channel pour compatibilité
  static const MethodChannel _channel = MethodChannel('com.minfo_sdk/audioqr');
  
  static void setupDebugListeners() {
    // Listener pour le channel exact du fichier de référence
    _minfoChannel.setMethodCallHandler((call) async {
      print('🔔 [MINFO CHANNEL] Méthode reçue: ${call.method}');
      print('📦 [MINFO CHANNEL] Arguments: ${call.arguments}');
      
      switch (call.method) {
        case 'onDetectedId':
          // Format exact du fichier de référence : [type, result[1], result[2], result[3]]
          final data = call.arguments as List?;
          print('✅ [MINFO FORMAT] Données détectées: $data');
          if (data != null && data.length >= 4) {
            final int soundType = data[0] as int;
            final int audioId = data[1] as int;
            final int counter = data[2] as int;
            final int timestamp = data[3] as int;
            print('🎯 [MINFO FORMAT] Type: $soundType, ID: $audioId, Counter: $counter, Timestamp: $timestamp');
          }
          break;
      }
    });
    
    // Listener pour le channel de compatibilité
    _channel.setMethodCallHandler((call) async {
      print('🔔 [AUDIOQR CHANNEL] Méthode reçue: ${call.method}');
      print('📦 [AUDIOQR CHANNEL] Arguments: ${call.arguments}');
      
      switch (call.method) {
        case 'onSignalDetected':
          final args = call.arguments as Map?;
          final codes = args?['codes'] as String?;
          print('✅ [AUDIOQR] ID détecté: $codes');
          break;
      }
    });
  }
}
