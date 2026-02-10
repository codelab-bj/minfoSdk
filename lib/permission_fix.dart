import 'package:permission_handler/permission_handler.dart';
import 'src/utils.dart'; // Utilise ton MinfoLogger ici aussi pour la cohérence

class PermissionFix {
  static final _logger = MinfoLogger();

  static Future<bool> requestMicrophonePermission() async {
    _logger.info('🎤 Début demande permission microphone');

    final status = await Permission.microphone.status;
    _logger.info('🎤 Statut initial: $status');

    if (status.isGranted) {
      _logger.info('🎤 ✅ Permission déjà accordée');
      return true;
    }

    if (status.isPermanentlyDenied) {
      _logger.error('🎤 ❌ Permission refusée définitivement - ouverture paramètres');
      await openAppSettings();
      return false;
    }

    _logger.info('🎤 📱 Demande de permission en cours...');
   // final result = await Permission.microphone.request();

    // CORRECTION: Utilisation de const pour la performance
    await Future.delayed(const Duration(milliseconds: 500));

    final finalStatus = await Permission.microphone.status;
    final granted = finalStatus.isGranted;
    _logger.info('🎤 ${granted ? "✅ SUCCÈS" : "❌ ÉCHEC"}');

    return granted;
  }
}