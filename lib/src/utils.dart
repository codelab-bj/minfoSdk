// src/config_manager.dart
// Minfo SDK v2.2.2

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:math';
import 'package:http/http.dart' as http;

import 'dart:developer' as developer;

enum ConfigSource { fresh, cached, defaults }

class ConfigManager {
  final MinfoAPIClient apiClient;
  final MinfoLogger logger;

  ConfigSource lastConfigSource = ConfigSource.defaults;
  MinfoConfig? _cachedConfig;
  DateTime? _cacheTimestamp;

  static const _cacheKey = 'com.minfo.sdk.config';
  static const _timestampKey = 'com.minfo.sdk.config_timestamp';

  ConfigManager({required this.apiClient, required this.logger}) {
    _loadCachedConfig();
  }

  Future<MinfoConfig> fetchConfig() async {
    try {
      final config = await apiClient.fetchConfig();

      // Cache the config
      await _cacheConfig(config);
      lastConfigSource = ConfigSource.fresh;

      logger.info('Config fetched successfully', {
        'configVersion': config.configVersion,
        'source': 'fresh',
      });

      return config;
    } catch (e) {
      logger.warning('Config fetch failed: $e');

      // Fall back to cached config if available
      if (_cachedConfig != null && _isCacheValid()) {
        lastConfigSource = ConfigSource.cached;
        logger.info('Using cached config', {
          'configVersion': _cachedConfig!.configVersion,
          'source': 'cached',
        });
        return _cachedConfig!;
      }

      // Fall back to safe defaults
      lastConfigSource = ConfigSource.defaults;
      logger.info('Using safe defaults', {'source': 'defaults'});
      return MinfoConfig.safeDefaults;
    }
  }

  Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_timestampKey);

      if (json != null) {
        _cachedConfig = MinfoConfig.fromJson(jsonDecode(json));
        _cacheTimestamp =
        timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
      }
    } catch (e) {
      logger.debug('Failed to load cached config: $e');
    }
  }

  Future<void> _cacheConfig(MinfoConfig config) async {
    _cachedConfig = config;
    _cacheTimestamp = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_configToJson(config)));
      await prefs.setInt(_timestampKey, _cacheTimestamp!.millisecondsSinceEpoch);
    } catch (e) {
      logger.debug('Failed to cache config: $e');
    }
  }

  bool _isCacheValid() {
    if (_cacheTimestamp == null || _cachedConfig == null) return false;
    final maxAge =
    Duration(seconds: _cachedConfig!.constraints.configRefreshIntervalSecs);
    return DateTime.now().difference(_cacheTimestamp!) < maxAge;
  }

  Map<String, dynamic> _configToJson(MinfoConfig config) => {
    'configVersion': config.configVersion,
    'featureFlags': {
      'audioqr_enabled': config.featureFlags.audioqrEnabled,
      'verbose_logging': config.featureFlags.verboseLogging,
      'native_checkout': config.featureFlags.nativeCheckout,
      'concurrent_detection': config.featureFlags.concurrentDetection,
      'background_detection': config.featureFlags.backgroundDetection,
      'sandbox_mode': config.featureFlags.sandboxMode,
    },
    'endpoints': {
      'connect': config.endpoints.connect,
      'config': config.endpoints.config,
    },
    'constraints': {
      'signatureMaxAgeSecs': config.constraints.signatureMaxAgeSecs,
      'minConfidenceThreshold': config.constraints.minConfidenceThreshold,
      'configRefreshIntervalSecs':
      config.constraints.configRefreshIntervalSecs,
    },
    'minimumSdkVersion': config.minimumSdkVersion,
  };
}

// src/api_client.dart
// Minfo SDK v2.2.2


abstract class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data) = _ApiSuccess<T>;
  factory ApiResult.failure(Exception error) = _ApiFailure<T>;

  T2 when<T2>({
    required T2 Function(T data) success,
    required T2 Function(Exception error) failure,
  });
}

class _ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const _ApiSuccess(this.data);

  @override
  T2 when<T2>({
    required T2 Function(T data) success,
    required T2 Function(Exception error) failure,
  }) =>
      success(data);
}

class _ApiFailure<T> extends ApiResult<T> {
  final Exception error;
  const _ApiFailure(this.error);

  @override
  T2 when<T2>({
    required T2 Function(T data) success,
    required T2 Function(Exception error) failure,
  }) =>
      failure(error);
}

class MinfoAPIClient {
  final String clientId;
  final String apiKey;
  final String sdkVersion;
  final String baseUrl;
  final MinfoLogger _logger = MinfoLogger();

  // Retry configuration
  static const _maxRetries = 3;
  static const _initialRetryDelayMs = 1000;

  MinfoAPIClient({
    required this.clientId,
    required this.apiKey,
    required this.sdkVersion,
    this.baseUrl = 'https://api.minfo.com',
  });

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'X-Minfo-Client-Id': clientId,
    'X-Minfo-SDK-Version': sdkVersion,
    'X-Minfo-Platform': 'flutter',
    'Content-Type': 'application/json',
  };

  Future<MinfoConfig> fetchConfig() async {
    final url = Uri.parse('$baseUrl/v1/config?clientId=$clientId&sdkVersion=$sdkVersion');
    final response = await _performRequestWithRetry(() => http.get(url, headers: _headers));

    if (response.statusCode != 200) {
      throw Exception('Config fetch failed: ${response.statusCode}');
    }

    return MinfoConfig.fromJson(jsonDecode(response.body));
  }

  Future<ApiResult<ConnectResponse>> connect(ConnectRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/v1/connect');
      final body = jsonEncode(request.toJson());

      final response = await _performRequestWithRetry(
            () => http.post(url, headers: _headers, body: body),
      );

      // Parse response body regardless of status code
      // Outcome is determined from JSON body, NOT HTTP status
      final connectResponse = ConnectResponse.fromJson(jsonDecode(response.body));

      // Log with correlation ID
      _logger.debug('Connect response', {
        'requestId': connectResponse.requestId,
        'httpStatus': response.statusCode.toString(),
        'outcome': connectResponse.outcome.value,
      });

      return ApiResult.success(connectResponse);
    } catch (e) {
      return ApiResult.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<http.Response> _performRequestWithRetry(
      Future<http.Response> Function() request,
      ) async {
    int retryCount = 0;
    while (true) {
      try {
        // Timeout de 10 secondes pour éviter que l'app ne freeze
        return await request().timeout(const Duration(seconds: 10));
      } catch (e) {
        if (retryCount >= _maxRetries) rethrow;

        retryCount++;
        // Calcul du délai : 1s, 2s, 4s...
        final delay = _initialRetryDelayMs * pow(2, retryCount - 1).toInt();

        _logger.warning('Network error, retrying ($retryCount/$_maxRetries) in ${delay}ms');
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }
}

// src/logger.dart
// Minfo SDK v2.2.2


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

// src/secure_storage.dart
// Minfo SDK v2.2.2


class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static Future<void> storeApiKey(String apiKey, String clientId) async {
    await _storage.write(key: 'minfo_api_key_$clientId', value: apiKey);
  }

  static Future<String?> retrieveApiKey(String clientId) async {
    return await _storage.read(key: 'minfo_api_key_$clientId');
  }

  static Future<void> deleteApiKey(String clientId) async {
    await _storage.delete(key: 'minfo_api_key_$clientId');
  }
}
