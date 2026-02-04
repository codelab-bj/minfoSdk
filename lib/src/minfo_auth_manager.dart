class MinfoAuthManager {
  static String? _publicKey;
  static String? _privateKey;
  static bool _isInitialized = false;

  static void initialize(String publicKey, {String? privateKey}) {
    _publicKey = publicKey;
    _privateKey = privateKey;
    _isInitialized = true;
  }

  static void ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('MinfoAuthManager not initialized. Call initialize() first.');
    }
  }

  static String? get publicKey => _publicKey;
  static String? get privateKey => _privateKey;
  static bool get isInitialized => _isInitialized;

  static Map<String, String> get authHeaders {
    ensureInitialized();
    final headers = <String, String>{};
    
    if (_publicKey != null) {
      headers['X-API-Key'] = _publicKey!;
    }
    
    if (_privateKey != null) {
      headers['X-API-Secret'] = _privateKey!;
    }
    
    return headers;
  }
}
