// src/utils.dart
// Minfo SDK v2.3.0 - Utilitaires de logging optimisés

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'; // Import requis pour kReleaseMode

enum LogLevel { debug, info, warning, error }

class MinfoLogger {
  LogLevel minLevel = LogLevel.info;

  // Désactive le logging verbeux en mode release par défaut pour la sécurité
  bool verboseLogging = !kReleaseMode;

  // NE JAMAIS LOGUER : audio brut, signatures, clés API, identifiants personnels
  static const _sensitiveKeys = {'audioSignature', 'apiKey', 'rawAudio', 'userId', 'token', 'privateKey'};

  void debug(String message, [Map<String, dynamic>? metadata]) {
    _log(LogLevel.debug, message, metadata);
  }

  void info(String message, [Map<String, dynamic>? metadata]) {
    _log(LogLevel.info, message, metadata);
  }

  void warning(String message, [Map<String, dynamic>? metadata]) {
    _log(LogLevel.warning, message, metadata);
  }

  void error(String message, [Map<String, dynamic>? metadata]) {
    _log(LogLevel.error, message, metadata);
  }

  void _log(LogLevel level, String message, Map<String, dynamic>? metadata) {
    // 1. Vérification du niveau de log
    if (level.index < minLevel.index) return;

    // 2. En mode Release, on restreint les logs au minimum (Warning et Error uniquement)
    if (kReleaseMode && level.index < LogLevel.warning.index) return;

    // 3. Filtrage des données sensibles dans les métadonnées
    String safeMetadata = "";
    if (metadata != null && metadata.isNotEmpty) {
      safeMetadata = metadata.entries
          .where((e) => !_sensitiveKeys.contains(e.key.toLowerCase()))
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }

    final logMessage = safeMetadata.isNotEmpty
        ? '$message | Data: {$safeMetadata}'
        : message;

    // 4. Utilisation de developer.log (Parfait pour Pub.dev car invisible dans les logs système de production)
    developer.log(
      logMessage,
      name: 'MinfoSDK',
      level: _levelToInt(level),
      time: DateTime.now(),
    );
  }

  int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}