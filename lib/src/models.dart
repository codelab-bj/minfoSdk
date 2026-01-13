// src/models.dart
// Minfo SDK v2.3.0
// Copyright (c) Minfo Limited. All rights reserved.

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// MARK: - Client Type

enum ClientType {
  sdkClient('sdk_client');
  // Other types (minfo_universal_app) are internal only

  final String value;
  const ClientType(this.value);

  Map<String, dynamic> toJson() => {'value': value};
}

// MARK: - Outcome

enum Outcome {
  allow('allow'),
  redirectToMinfo('redirect_to_minfo'),
  error('error'),
  unknown('unknown');

  final String value;
  const Outcome(this.value);

  static Outcome fromString(String value) {
    return Outcome.values.firstWhere(
          (e) => e.value == value,
      orElse: () => Outcome.unknown,
    );
  }
}

// MARK: - Content Type

enum ContentType {
  webUrl('web_url'),
  deepLink('deep_link'),
  nativePayload('native_payload'),
  redirect('redirect'),
  unknown('unknown');

  final String value;
  const ContentType(this.value);

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => ContentType.unknown,
    );
  }
}

// MARK: - Device Context

class DeviceContext {
  final String osVersion;
  final String deviceModel;
  final String appVersion;

  DeviceContext({
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
  });

  static Future<DeviceContext> current() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String osVersion;
    String deviceModel;

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osVersion = iosInfo.systemVersion;
      deviceModel = iosInfo.model;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      osVersion = androidInfo.version.release;
      deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
    } else {
      osVersion = 'unknown';
      deviceModel = 'unknown';
    }

    return DeviceContext(
      osVersion: osVersion,
      deviceModel: deviceModel,
      appVersion: packageInfo.version,
    );
  }

  Map<String, dynamic> toJson() => {
    'osVersion': osVersion,
    'deviceModel': deviceModel,
    'appVersion': appVersion,
  };
}

// MARK: - Connect Request

class ConnectRequest {
  final ClientType requestingClientType;
  final String requestingClientId;
  final String audioSignature;
  final DeviceContext deviceContext;
  final String sdkVersion;
  final String engineVersion;
  final List<ContentType> supportedContentTypes;
  final List<String> activeFeatureFlags;

  ConnectRequest({
    required this.requestingClientType,
    required this.requestingClientId,
    required this.audioSignature,
    required this.deviceContext,
    required this.sdkVersion,
    required this.engineVersion,
    required this.supportedContentTypes,
    required this.activeFeatureFlags,
  });

  Map<String, dynamic> toJson() => {
    'requestingClientType': requestingClientType.value,
    'requestingClientId': requestingClientId,
    'audioSignature': audioSignature,
    'deviceContext': deviceContext.toJson(),
    'sdkVersion': sdkVersion,
    'engineVersion': engineVersion,
    'supportedContentTypes':
    supportedContentTypes.map((e) => e.value).toList(),
    'activeFeatureFlags': activeFeatureFlags,
  };
}

// MARK: - Connect Response

class ConnectResponse {
  /// Correlation ID - include in all logs
  final String requestId;

  /// Outcome determines SDK behaviour
  final Outcome outcome;

  /// Content type for allow outcomes
  final ContentType? contentType;

  /// Payload data
  final Map<String, dynamic>? payload;

  /// User-facing message
  final String? message;

  /// Additional metadata (ignore unknown fields)
  final Map<String, dynamic>? metadata;

  ConnectResponse({
    required this.requestId,
    required this.outcome,
    this.contentType,
    this.payload,
    this.message,
    this.metadata,
  });

  factory ConnectResponse.fromJson(Map<String, dynamic> json) {
    return ConnectResponse(
      // CORRECTION : On gère le cas où requestId est absent ou null
      requestId: (json['requestId'] ?? json['request_id'] ?? json['id'] ?? 'unknown').toString(),

      // CORRECTION : On force une valeur par défaut pour l'outcome si null
      outcome: Outcome.fromString(json['outcome'] as String? ?? 'error'),
      contentType: json['contentType'] != null
          ? ContentType.fromString(json['contentType'] as String)
          : null,
      payload: json['payload'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// MARK: - Config Models

class MinfoConfig {
  final String configVersion;
  final FeatureFlags featureFlags;
  final Endpoints endpoints;
  final Constraints constraints;
  final String? minimumSdkVersion;

  MinfoConfig({
    required this.configVersion,
    required this.featureFlags,
    required this.endpoints,
    required this.constraints,
    this.minimumSdkVersion,
  });

  factory MinfoConfig.fromJson(Map<String, dynamic> json) {
    return MinfoConfig(
      // CORRECTION : Valeurs par défaut pour éviter les crashs au démarrage
      configVersion: json['configVersion'] as String? ?? '1.0.0',
      featureFlags: FeatureFlags.fromJson(
          json['featureFlags'] as Map<String, dynamic>),
      endpoints: Endpoints.fromJson(json['endpoints'] as Map<String, dynamic>),
      constraints:
      Constraints.fromJson(json['constraints'] as Map<String, dynamic>),
      minimumSdkVersion: json['minimumSdkVersion'] as String?,
    );
  }

  static MinfoConfig get safeDefaults => MinfoConfig(
    configVersion: 'defaults',
    featureFlags: FeatureFlags.defaults(),
    endpoints: Endpoints.defaults(),
    constraints: Constraints.defaults(),
  );
}

class FeatureFlags {
  final bool audioqrEnabled;
  final bool verboseLogging;
  final bool nativeCheckout;
  final bool concurrentDetection;
  final bool backgroundDetection;
  final bool sandboxMode;

  FeatureFlags({
    required this.audioqrEnabled,
    required this.verboseLogging,
    required this.nativeCheckout,
    required this.concurrentDetection,
    required this.backgroundDetection,
    required this.sandboxMode,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      audioqrEnabled: json['audioqr_enabled'] as bool? ?? true,
      verboseLogging: json['verbose_logging'] as bool? ?? false,
      nativeCheckout: json['native_checkout'] as bool? ?? false,
      concurrentDetection: json['concurrent_detection'] as bool? ?? false,
      backgroundDetection: json['background_detection'] as bool? ?? false,
      sandboxMode: json['sandbox_mode'] as bool? ?? false,
    );
  }

  factory FeatureFlags.defaults() => FeatureFlags(
    audioqrEnabled: true,
    verboseLogging: false,
    nativeCheckout: false,
    concurrentDetection: false,
    backgroundDetection: false,
    sandboxMode: false,
  );

  List<String> get activeFlags {
    final flags = <String>[];
    if (audioqrEnabled) flags.add('audioqr_enabled');
    if (verboseLogging) flags.add('verbose_logging');
    if (nativeCheckout) flags.add('native_checkout');
    if (concurrentDetection) flags.add('concurrent_detection');
    if (backgroundDetection) flags.add('background_detection');
    if (sandboxMode) flags.add('sandbox_mode');
    return flags;
  }
}

class Endpoints {
  final String connect;
  final String config;

  Endpoints({required this.connect, required this.config});

  factory Endpoints.fromJson(Map<String, dynamic> json) {
    return Endpoints(
      connect: json['connect'] as String,
      config: json['config'] as String,
    );
  }

  factory Endpoints.defaults() => Endpoints(
    connect: 'https://api.dev.minfo.com/api/minfo/campaignfromaudio',//'https://api.minfo.com/v1/connect',
    config: 'https://api.minfo.com/v1/config',
  );
}

class Constraints {
  final int signatureMaxAgeSecs;
  final double minConfidenceThreshold;
  final int configRefreshIntervalSecs;

  Constraints({
    required this.signatureMaxAgeSecs,
    required this.minConfidenceThreshold,
    required this.configRefreshIntervalSecs,
  });

  factory Constraints.fromJson(Map<String, dynamic> json) {
    return Constraints(
      signatureMaxAgeSecs: json['signatureMaxAgeSecs'] as int? ?? 60,
      minConfidenceThreshold:
      (json['minConfidenceThreshold'] as num?)?.toDouble() ?? 0.85,
      configRefreshIntervalSecs:
      json['configRefreshIntervalSecs'] as int? ?? 3600,
    );
  }

  factory Constraints.defaults() => Constraints(
    signatureMaxAgeSecs: 60,
    minConfidenceThreshold: 0.85,
    configRefreshIntervalSecs: 3600,
  );
}

// MARK: - Result Types

sealed class MinfoConnectResult {
  const MinfoConnectResult();
}

class MinfoAllowed extends MinfoConnectResult {
  final Uri contentUrl;
  final String requestId;
  MinfoAllowed({required this.contentUrl, required this.requestId});
}

class MinfoRedirectToMinfo extends MinfoConnectResult {
  final Uri redirectUrl;
  final String message;
  final String requestId;
  MinfoRedirectToMinfo({
    required this.redirectUrl,
    required this.message,
    required this.requestId
  });
}

class MinfoError extends MinfoConnectResult {
  final String code;
  final String message;
  final String? requestId;
  MinfoError({required this.code, required this.message, this.requestId});
}

class MinfoPermissionRequired extends MinfoConnectResult {
  final String message;
  MinfoPermissionRequired({required this.message});
}

abstract class ConnectResult {
  const ConnectResult();

  factory ConnectResult.success(ConnectSuccess success) = _ConnectSuccess;
  factory ConnectResult.failure(ConnectError error) = _ConnectFailure;

  T when<T>({
    required T Function(ConnectSuccess success) success,
    required T Function(ConnectError error) failure,
  });
}

class _ConnectSuccess extends ConnectResult {
  final ConnectSuccess _success;
  const _ConnectSuccess(this._success);

  @override
  T when<T>({
    required T Function(ConnectSuccess success) success,
    required T Function(ConnectError error) failure,
  }) =>
      success(_success);
}

class _ConnectFailure extends ConnectResult {
  final ConnectError _error;
  const _ConnectFailure(this._error);

  @override
  T when<T>({
    required T Function(ConnectSuccess success) success,
    required T Function(ConnectError error) failure,
  }) =>
      failure(_error);
}

// MARK: - Connect Success

abstract class ConnectSuccess {
  const ConnectSuccess();

  factory ConnectSuccess.webContent(String url) = WebContentSuccess;
  factory ConnectSuccess.deepLink(String uri) = DeepLinkSuccess;
  factory ConnectSuccess.nativePayload(Map<String, dynamic> payload) =
  NativePayloadSuccess;
  factory ConnectSuccess.redirectedToMinfoApp() = RedirectedToMinfoAppSuccess;
  factory ConnectSuccess.redirectedToMinfoWeb() = RedirectedToMinfoWebSuccess;
}

class WebContentSuccess extends ConnectSuccess {
  final String url;
  const WebContentSuccess(this.url);
}

class DeepLinkSuccess extends ConnectSuccess {
  final String uri;
  const DeepLinkSuccess(this.uri);
}

class NativePayloadSuccess extends ConnectSuccess {
  final Map<String, dynamic> payload;
  const NativePayloadSuccess(this.payload);
}

class RedirectedToMinfoAppSuccess extends ConnectSuccess {
  const RedirectedToMinfoAppSuccess();
}

class RedirectedToMinfoWebSuccess extends ConnectSuccess {
  const RedirectedToMinfoWebSuccess();
}

// MARK: - Connect Error

abstract class ConnectError implements Exception {
  const ConnectError();

  static const notInitialised = NotInitialisedError();
  static const engineUnavailable = EngineUnavailableError();
  static const featureDisabled = FeatureDisabledError();
  static const lowConfidence = LowConfidenceError();

  factory ConnectError.detectionFailed(dynamic cause) =
  DetectionFailedError;
  factory ConnectError.apiError(dynamic cause) = ApiErrorError;
  factory ConnectError.serverError(String message) = ServerErrorError;
}

class NotInitialisedError extends ConnectError {
  const NotInitialisedError();
}

class EngineUnavailableError extends ConnectError {
  const EngineUnavailableError();
}

class FeatureDisabledError extends ConnectError {
  const FeatureDisabledError();
}

class LowConfidenceError extends ConnectError {
  const LowConfidenceError();
}

class DetectionFailedError extends ConnectError {
  final dynamic cause;
  const DetectionFailedError(this.cause);
}

class ApiErrorError extends ConnectError {
  final dynamic cause;
  const ApiErrorError(this.cause);
}

class ServerErrorError extends ConnectError {
  final String message;
  const ServerErrorError(this.message);
}
