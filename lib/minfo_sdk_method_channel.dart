import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'minfo_sdk_platform_interface.dart';

// La CLASSE doit s'appeler MethodChannelMinfoSdk (Majuscule au début)
class MethodChannelMinfoSdk extends MinfoSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('com.gzone.campaign/audioCapture');

  MethodChannelMinfoSdk() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == "onDetectedId") {
        final List<dynamic> args = call.arguments;
        final int id = args[1];
        debugPrint("🚀 VICTOIRE : Flutter a reçu l'ID $id");
      }
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    return 'Native';
  }
}