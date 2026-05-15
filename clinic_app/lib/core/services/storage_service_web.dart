// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

class StorageService {
  StorageService._();

  static const _keyToken = 'cms_jwt_token';
  static const _keyUser = 'cms_user_json';

  static html.Storage get _storage => html.window.localStorage;

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    _storage[_keyToken] = token;
  }

  static Future<String?> getToken() async {
    return _storage[_keyToken];
  }

  static Future<void> deleteToken() async {
    _storage.remove(_keyToken);
  }

  // ── User ───────────────────────────────────────────────────────────────────

  static Future<void> saveUser(Map<String, dynamic> user) async {
    _storage[_keyUser] = jsonEncode(user);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = _storage[_keyUser];
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    _storage.remove(_keyUser);
  }

  // ── Clear all ──────────────────────────────────────────────────────────────

  static Future<void> clear() async {
    _storage.remove(_keyToken);
    _storage.remove(_keyUser);
  }
}
