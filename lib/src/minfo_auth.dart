import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils.dart'; // Importe ton logger

class MinfoAuth {
  final _storage = const FlutterSecureStorage();
  final _logger = MinfoLogger();

  Future<void> storeApiKeys(String public, String private) async {
    await _storage.write(key: 'minfo_public_key', value: public);
    await _storage.write(key: 'minfo_private_key', value: private);
    _logger.info("Keys stored successfully");
  }

  Future<Map<String, String>?> getStoredApiKeys() async {
    final pub = await _storage.read(key: 'minfo_public_key');
    final priv = await _storage.read(key: 'minfo_private_key');

    if (pub == null || priv == null) {
      _logger.warning("Attempted to retrieve keys but they are missing");
      return null;
    }
    return {'public_key': pub, 'private_key': priv};
  }
}