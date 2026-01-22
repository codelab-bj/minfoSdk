import 'package:flutter/services.dart';

class DebugDetection {
  static const MethodChannel _channel = MethodChannel('minfo_sdk');
  
  static void setupDebugListeners() {
    _channel.setMethodCallHandler((call) async {
      print('🔔 Channel reçu: ${call.method}');
      print('📦 Arguments: ${call.arguments}');
      
      switch (call.method) {
        case 'onSignalDetected':
          final codes = call.arguments['codes'] as String?;
          print('✅ ID détecté: $codes');
          break;
        case 'onDetectedId':
          final data = call.arguments as List?;
          print('✅ Données Minfo: $data');
          if (data != null && data.length > 1) {
            final audioId = data[1];
            print('🎯 Audio ID extrait: $audioId');
          }
          break;
      }
    });
  }
}
