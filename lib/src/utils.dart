// src/utils.dart
// Minfo SDK v2.3.0 - Utilitaires uniquement

import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class MinfoLogger {
  LogLevel minLevel = LogLevel.info;
  bool verboseLogging = false;

  // NEVER LOG: raw audio, audioSignature payload, API keys, user identifiers
  static const _sensitiveKeys = {'audioSignature', 'apiKey', 'rawAudio', 'userId'};

  void debug(String message, [Map<String, String>? metadata]) {
    _log(LogLevel.debug, message, metadata);
  }

  void info(String message, [Map<String, String>? metadata]) {
    _log(LogLevel.info, message, metadata);
  }

  void warning(String message, [Map<String, String>? metadata]) {
    _log(LogLevel.warning, message, metadata);
  }

  void error(String message, [Map<String, String>? metadata]) {
    _log(LogLevel.error, message, metadata);
  }

  void _log(LogLevel level, String message, Map<String, String>? metadata) {
    if (level.index < minLevel.index) return;

    final safeMetadata = metadata?.entries
        .where((e) => !_sensitiveKeys.contains(e.key))
        .map((e) => '${e.key}=${e.value}')
        .join(', ');

    final logMessage = safeMetadata != null && safeMetadata.isNotEmpty
        ? '$message {$safeMetadata}'
        : message;

    developer.log(
      logMessage,
      name: 'MinfoSDK',
      level: _levelToInt(level),
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
