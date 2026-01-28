import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class PermissionFix {
  static Future<bool> requestMicrophonePermission() async {
    developer.log('🎤 Début demande permission microphone');
    
    // Vérifier d'abord le statut actuel
    final status = await Permission.microphone.status;
    developer.log('🎤 Statut initial: $status');
    
    if (status.isGranted) {
      developer.log('🎤 ✅ Permission déjà accordée');
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      developer.log('🎤 ❌ Permission refusée définitivement - ouverture paramètres');
      await openAppSettings();
      return false;
    }
    
    // Demander la permission
    developer.log('🎤 📱 Demande de permission en cours...');
    final result = await Permission.microphone.request();
    developer.log('🎤 📱 Résultat demande: $result');
    
    // Attendre un délai pour iOS
    developer.log('🎤 ⏳ Attente 500ms pour iOS...');
    await Future.delayed(Duration(milliseconds: 500));
    
    // Vérifier à nouveau le statut après la demande
    final finalStatus = await Permission.microphone.status;
    developer.log('🎤 Statut final: $finalStatus');
    
    final granted = finalStatus.isGranted;
    developer.log('🎤 ${granted ? "✅ SUCCÈS" : "❌ ÉCHEC"} - Permission ${granted ? "accordée" : "refusée"}');
    
    return granted;
  }
}
