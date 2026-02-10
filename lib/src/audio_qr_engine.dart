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
  final _logger = MinfoLogger();
  final _uuid = const Uuid();

  String _version = '1.0.0-native';
  bool _isAvailable = false;
  bool _isDetecting = false;
  final List<AudioQRSignal> _queuedSignals = [];
  Completer<DetectionResult>? _detectionCompleter;

  // Correction du constructeur (suppression du paramètre inutilisé minfoChannel)
  AudioQREngine({
    required MethodChannel channel,
  }) : _channel = channel;

  String get version => _version;
  bool get isAvailable => _isAvailable;

  Future<bool> initialise() async {
    try {
      final result = await _channel.invokeMethod<Map>('initialise');
      if (result != null) {
        _version = result['version'] as String? ?? _version;
        _isAvailable = result['available'] as bool? ?? false;

        if (!_isAvailable) {
          final error = result['error'] as String?;
          _logger.error('❌ AudioQR engine unavailable: $error');
        }
        return _isAvailable;
      }
      return false;
    } catch (e) {
      _logger.error('❌ AudioQR engine initialisation failed: $e');
      return false;
    }
  }

  Future<DetectionResult> startDetection() async {
    _logger.info('🚀 [AUDIOQR] startDetection() appelé');

    if (!_isAvailable) {
      _logger.error('❌ [AUDIOQR] Moteur non initialisé');
      return DetectionResult.failure(NotInitialisedException());
    }

    if (_isDetecting) {
      _logger.warning('⚠️ [AUDIOQR] Détection déjà en cours');
      return DetectionResult.failure(
          EngineFailureException('Detection already in progress'));
    }

    _logger.info('✅ [AUDIOQR] Création du Completer pour attendre les résultats');
    _isDetecting = true;
    _detectionCompleter = Completer<DetectionResult>();

    try {
      _logger.info('📤 [AUDIOQR] Envoi de startDetection vers le natif...');
      await _channel.invokeMethod('startDetection');

      _logger.info('⏳ En attente du signal audio via listener...');
      return await _detectionCompleter!.future;
    } catch (e) {
      _logger.error('❌ [AUDIOQR] Erreur dans startDetection: $e');
      _isDetecting = false;
      _detectionCompleter = null;

      if (e.toString().contains('LIBS_UNAVAILABLE')) {
        return DetectionResult.failure(NativeLibrariesUnavailableException(e.toString()));
      }
      return DetectionResult.failure(EngineFailureException(e.toString()));
    }
  }

  void handleDetectedId(List<dynamic> detectedData) {
    _logger.info('📥 [AUDIOQR] handleDetectedId() reçu: $detectedData');

    try {
      if (detectedData.length >= 2) {
        final int audioId = detectedData[1] as int;
        _logger.info('🎯 [AUDIOQR] AudioId extrait: $audioId');

        final signal = AudioQRSignal(
          signature: audioId.toString(),
          confidence: 0.95,
          detectedAt: DateTime.now(),
          signalId: _uuid.v4(),
        );

        _isDetecting = false;

        if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
          _logger.info('📤 [AUDIOQR] Complétion du Future avec succès');
          _detectionCompleter!.complete(DetectionResult.success(signal));
          _detectionCompleter = null;
        }
      } else {
        _logger.warning('❌ [AUDIOQR] Format de données invalide');
      }
    } catch (e) {
      _logger.error('❌ [AUDIOQR] Erreur dans handleDetectedId: $e');
      _isDetecting = false;
      if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
        _detectionCompleter!.complete(DetectionResult.failure(EngineFailureException(e.toString())));
        _detectionCompleter = null;
      }
    }
  }

  void stopDetection() {
    _logger.info('⏹️ [AUDIOQR] stopDetection() appelé');
    _isDetecting = false;
    if (_detectionCompleter != null && !_detectionCompleter!.isCompleted) {
      _detectionCompleter!.complete(DetectionResult.failure(EngineFailureException('Stopped')));
      _detectionCompleter = null;
    }
    try {
      _channel.invokeMethod('stopDetection');
    } catch (e) {
      _logger.error('❌ Erreur stopDetection natif: $e');
    }
  }

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
