import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'cms_jwt_token';
  static const _keyUser = 'cms_user_json';

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> deleteToken() => _storage.delete(key: _keyToken);

  // ── User ───────────────────────────────────────────────────────────────────

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _keyUser, value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() => _storage.delete(key: _keyUser);

  // ── Clear all ──────────────────────────────────────────────────────────────

  static Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
