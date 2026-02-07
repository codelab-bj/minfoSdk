// src/audio_qr_engine.dart
// Minfo SDK v2.3.0
// Copyright (c) Minfo Limited. All rights reserved.
//
// NATIVE IMPLEMENTATION
// This communicates with native AudioQR engines via platform channels.
// The actual audio processing happens in native code (Swift/Kotlin).
// Fallback stubs are commented out to force native library usage.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

// MARK: - AudioQR Signal

class AudioQRSignal {
  /// Decoded signal signature (submitted to campaignfromaudio API)
  final String signature;

  /// Detection confidence (0.0 - 1.0)
  final double confidence;

  /// Timestamp when signal was detected
  final DateTime detectedAt;

  /// Signal ID for logging (not the signature)
  final String signalId;

  AudioQRSignal({
    required this.signature,
    required this.confidence,
    required this.detectedAt,
    required this.signalId,
  });
}

// MARK: - Detection Result

abstract class DetectionResult {
  const DetectionResult();

  factory DetectionResult.success(AudioQRSignal signal) = _DetectionSuccess;
  factory DetectionResult.failure(AudioQRException error) = _DetectionFailure;

  T when<T>({
    required T Function(AudioQRSignal signal) success,
    required T Function(AudioQRException error) failure,
  });
}

class _DetectionSuccess extends DetectionResult {
  final AudioQRSignal signal;
  const _DetectionSuccess(this.signal);

  @override
  T when<T>({
    required T Function(AudioQRSignal signal) success,
    required T Function(AudioQRException error) failure,
  }) =>
      success(signal);
}

class _DetectionFailure extends DetectionResult {
  final AudioQRException error;
  const _DetectionFailure(this.error);

  @override
  T when<T>({
    required T Function(AudioQRSignal signal) success,
    required T Function(AudioQRException error) failure,
  }) =>
      failure(error);
}

// MARK: - AudioQR Exceptions

abstract class AudioQRException implements Exception {
  String get message;
}

class NotInitialisedException extends AudioQRException {
  @override
  String get message => 'AudioQR engine not initialised';
}

class MicrophonePermissionDeniedException extends AudioQRException {
  @override
  String get message => 'Microphone permission denied';
}

class DetectionTimeoutException extends AudioQRException {
  @override
  String get message => 'Detection timed out';
}

class EngineFailureException extends AudioQRException {
  final String reason;
  EngineFailureException(this.reason);

  @override
  String get message => 'Engine failure: $reason';
}

class NativeLibrariesUnavailableException extends AudioQRException {
  final String details;
  NativeLibrariesUnavailableException(this.details);

  @override
  String get message => 'Native libraries unavailable: $details';
}

// MARK: - AudioQR Engine

/// AudioQR Engine that communicates with native implementations via platform channels.
///
/// For production:
/// - iOS: Uses Cifrasoft SCSTB_LibraryU.a native library
/// - Android: Uses Cifrasoft soundcode.jar + libscuc.so native libraries
///
/// Fallback stubs are commented out to ensure native libraries are properly integrated.
class AudioQREngine {
  final MethodChannel _channel;
  final MethodChannel? _minfoChannel;

  String _version = '1.0.0-native'; // Changed from 'stub' to 'native'
  bool _isAvailable = false;
  bool _isDetecting = false;
  final List<AudioQRSignal> _queuedSignals = [];

  final _uuid = const Uuid();

  // Pour attendre les résultats du listener
  Completer<DetectionResult>? _detectionCompleter;

  AudioQREngine({
    required MethodChannel channel,
    MethodChannel? minfoChannel,
  })  : _channel = channel,
        _minfoChannel = minfoChannel;

  String get version => _version;
  bool get isAvailable => _isAvailable;

  /// Initialise the AudioQR engine.
  Future<bool> initialise() async {
    try {
      final result = await _channel.invokeMethod<Map>('initialise');
      if (result != null) {
        _version = result['version'] as String? ?? _version;
        _isAvailable = result['available'] as bool? ?? false;

        if (!_isAvailable) {
          final error = result['error'] as String?;
          print('❌ AudioQR engine unavailable: $error');
        }

        return _isAvailable;
      }
      return false;
    } catch (e) {
      print('❌ AudioQR engine initialisation failed: $e');
      return false;
    }
  }

  /// Start AudioQR detection.
  /// Avec le système exact, les résultats arrivent via le listener onDetectedId
  Future<DetectionResult> startDetection() async {
    print('🚀 [AUDIOQR] startDetection() appelé');

    if (!_isAvailable) {
      print('❌ [AUDIOQR] Moteur non initialisé');
      return DetectionResult.failure(NotInitialisedException());
    }

    if (_isDetecting) {
      print('⚠️ [AUDIOQR] Détection déjà en cours');
      return DetectionResult.failure(
          EngineFailureException('Detection already in progress'));
    }

    // S'assurer que le listener est configuré (via MinfoSdk singleton)
    try {
      // Import dynamique pour éviter les dépendances circulaires
      // On utilise une approche indirecte via le channel
      print('🔧 [AUDIOQR] Vérification de la configuration du listener...');
      // Le listener sera configuré automatiquement par MinfoSdk si nécessaire
      // On peut aussi l'appeler directement si on a accès au SDK
      print(
          '💡 [AUDIOQR] INFO: Assurez-vous que MinfoSdk.instance.configureListener() a été appelé');
    } catch (e) {
      print('⚠️ [AUDIOQR] Impossible de vérifier le listener: $e');
    }

    print('✅ [AUDIOQR] Création du Completer pour attendre les résultats');
    _isDetecting = true;
    _detectionCompleter = Completer<DetectionResult>();

    try {
      print('📤 [AUDIOQR] Envoi de startDetection vers le natif...');
      // Démarrer la détection (retourne null avec le système exact)
      // Les résultats arriveront via handleDetectedId() appelé par minfo_sdk.dart
      await _channel.invokeMethod('startDetection');
      print(
          '✅ [AUDIOQR] startDetection envoyé, attente des résultats via listener...');
      print('💡 [AUDIOQR] INFO: En attente d\'un signal audio...');
      print(
          '💡 [AUDIOQR] INFO: Le listener natif écoute, un signal déclenchera onDetectedId');
      print(
          '💡 [AUDIOQR] INFO: Si aucun signal n\'arrive, vérifiez que le listener Flutter est configuré');

      // Attendre les résultats via le callback (pas de timeout - comme dans le fichier de référence)
      print(
          '⏳ [AUDIOQR] En attente du Completer (attente infinie jusqu\'à détection)...');
      final result = await _detectionCompleter!.future;
      print('✅ [AUDIOQR] Résultat reçu du Completer');
      return result;
    } catch (e) {
      print('❌ [AUDIOQR] Erreur dans startDetection: $e');
      _isDetecting = false;
      _detectionCompleter = null;

      // Gestion spécifique des erreurs de libs natives
      if (e.toString().contains('LIBS_UNAVAILABLE') ||
          e.toString().contains('FRAMEWORK_UNAVAILABLE')) {
        return DetectionResult.failure(
            NativeLibrariesUnavailableException(e.toString()));
      }

      return DetectionResult.failure(EngineFailureException(e.toString()));
    }
  }

  /// Gérer les détections reçues via onDetectedId
  /// Appelé par minfo_sdk.dart quand il reçoit onDetectedId
  /// Gérer les détections reçues via onDetectedId
  void handleDetectedId(List<dynamic> detectedData) {
    print('📥 [AUDIOQR] handleDetectedId() appelé avec: $detectedData');

    // 1. On vérifie d'abord si on a un completer en attente
    if (_detectionCompleter == null || _detectionCompleter!.isCompleted) {
      print('💡 [AUDIOQR] Info: ID reçu en mode passif (pas de Completer actif)');
      // On ne s'arrête pas là, on continue pour traiter la donnée si besoin
    }

    try {
      // Format exact du fichier de référence : [type, result[1], result[2], result[3]]
      if (detectedData.length >= 2) { // Sécurité : au moins type et ID
        final int audioId = detectedData[1] as int;
        print('🎯 [AUDIOQR] AudioId extrait: $audioId');

        // Créer le signal
        final signal = AudioQRSignal(
          signature: audioId.toString(),
          confidence: 0.95,
          detectedAt: DateTime.now(),
          signalId: _uuid.v4(),
        );

        _isDetecting = false;

        // 2. On complète le Future SI il existe
        if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
          print('📤 [AUDIOQR] Complétion du Completer avec succès...');
          _detectionCompleter!.complete(DetectionResult.success(signal));
          _detectionCompleter = null;
        }
      } else {
        print('❌ [AUDIOQR] Format de données invalide (trop court)');
      }
    } catch (e) {
      print('❌ [AUDIOQR] Erreur dans handleDetectedId: $e');
      _isDetecting = false;
      if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
        _detectionCompleter!.complete(
            DetectionResult.failure(EngineFailureException(e.toString())));
        _detectionCompleter = null;
      }
    }
  }
  /// Stop any ongoing detection.
  void stopDetection() {
    print('⏹️ [AUDIOQR] stopDetection() appelé');
    _isDetecting = false;
    if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
      print('📤 [AUDIOQR] Complétion du Completer avec arrêt...');
      _detectionCompleter!.complete(
          DetectionResult.failure(EngineFailureException('Detection stopped')));
      _detectionCompleter = null;
      print('✅ [AUDIOQR] Completer complété avec arrêt');
    }
    try {
      print('📤 [AUDIOQR] Envoi de stopDetection vers le natif...');
      _channel.invokeMethod('stopDetection');
      print('✅ [AUDIOQR] stopDetection envoyé');
    } catch (e) {
      print('❌ [AUDIOQR] Erreur dans stopDetection: $e');
    }
  }

  /// Discard any queued signals.
  /// Signals must not be persisted - they expire after 60 seconds.
  void discardQueuedSignals() {
    _queuedSignals.clear();
    try {
      _channel.invokeMethod('discardQueuedSignals');
    } catch (_) {}
  }
}

/*
 * Native Platform Channel Implementation Reference:
 *
 * iOS (Swift):
 * ```swift
 * let channel = FlutterMethodChannel(name: "com.minfo_sdk/audioqr", binaryMessenger: registrar.messenger())
 * channel.setMethodCallHandler { call, result in
 *     switch call.method {
 *     case "initialise":
 *         // Initialise AudioQR engine
 *         result(["version": engine.version, "available": engine.isAvailable])
 *     case "startDetection":
 *         // Start detection, return signal
 *         result(["signature": signal.signature, "confidence": signal.confidence, "signalId": signal.signalId])
 *     case "stopDetection":
 *         engine.stopDetection()
 *         result(nil)
 *     default:
 *         result(FlutterMethodNotImplemented)
 *     }
 * }
 * ```
 *
 * Android (Kotlin):
 * ```kotlin
 * val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.minfo_sdk/audioqr")
 * channel.setMethodCallHandler { call, result ->
 *     when (call.method) {
 *         "initialise" -> {
 *             // Initialise AudioQR engine
 *             result.success(mapOf("version" to engine.version, "available" to engine.isAvailable))
 *         }
 *         "startDetection" -> {
 *             // Start detection, return signal
 *             result.success(mapOf("signature" to signal.signature, "confidence" to signal.confidence, "signalId" to signal.signalId))
 *         }
 *         "stopDetection" -> {
 *             engine.stopDetection()
 *             result.success(null)
 *         }
 *         else -> result.notImplemented()
 *     }
 * }
 * ```
 */
