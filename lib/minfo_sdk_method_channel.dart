import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'minfo_sdk_platform_interface.dart';

class MethodChannelMinfoSdk extends MinfoSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('minfo_sdk');

  // Canal spécifique pour la capture audio (Control)
  final minfoChannel = const MethodChannel('com.gzone.campaign/audioCapture');

  // Stream pour diffuser les résultats à l'UI
  final StreamController<Map<String, dynamic>> _detectionController = StreamController.broadcast();

  MethodChannelMinfoSdk() {
    // Écoute les appels provenant du code natif (iOS/Android)
    minfoChannel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == "onDetectedId") {
      // Réception des données décodées : [type, audioId, counter, timestamp]
      final List<dynamic> args = call.arguments;

      _detectionController.add({
        "audioId": args[1],
        "timestamp": args[3],
      });
      print("🎯 ID Détecté reçu dans Flutter : ${args[1]}");
    }
  }

  @override
  Stream<Map<String, dynamic>> get detectionStream => _detectionController.stream;

  @override
  Future<void> startDetection() async {
    // Active le micro et lance le moteur (Activation + Decoding)
    await minfoChannel.invokeMethod('startAudioCapture');
  }

  @override
  Future<void> stopDetection() async {
    await minfoChannel.invokeMethod('stopAudioCapture');
  }

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }
}

