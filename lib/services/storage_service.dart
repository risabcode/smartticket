//import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> save(String key, String value) async =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) async =>
      _storage.read(key: key);

  static Future<void> delete(String key) async =>
      _storage.delete(key: key);
}
