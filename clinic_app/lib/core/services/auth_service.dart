import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import '../../models/api_response_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  String?   _token;
  bool      _initialized = false;
  bool      _loading     = false;

  UserModel? get currentUser    => _user;
  String?    get token          => _token;
  bool       get isLoggedIn     => _token != null && _user != null;
  bool       get initialized    => _initialized;
  bool       get loading        => _loading;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    try {
      _token = await StorageService.getToken();
      if (_token == null) return;

      final cached = await StorageService.getUser();
      if (cached != null) _user = UserModel.fromJson(cached);

      // Validate token against /me and get fresh user data
      final res = await ApiService.get<Map<String, dynamic>>(
        ApiConstants.me,
        fromData: (d) => d as Map<String, dynamic>,
      );
      if (res.success && res.data != null) {
        _user = UserModel.fromJson(res.data!);
        await StorageService.saveUser(_user!.toJson());
      } else {
        await _clearSession();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _clearSession();
    } catch (_) {
      // Network error on startup — keep cached credentials
    } finally {
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.post<Map<String, dynamic>>(
        ApiConstants.login,
        body: {'email': email, 'password': password},
        fromData: (d) => d as Map<String, dynamic>,
        auth: false,
      );

      if (!res.success || res.data == null) {
        throw ApiException(message: res.message, statusCode: 400);
      }

      final data  = res.data!;
      final token = data['token'] as String?;
      final user  = data['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw const ApiException(message: 'Invalid server response.', statusCode: 500);
      }

      _token = token;
      _user  = UserModel.fromJson(user);

      await StorageService.saveToken(token);
      await StorageService.saveUser(_user!.toJson());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await ApiService.post<void>(ApiConstants.logout);
    } catch (_) {
      // Ignore — server-side logout is best-effort
    }
    await _clearSession();
  }

  // ── Change password ───────────────────────────────────────────────────────

  Future<void> changePassword(String current, String newPass) async {
    final res = await ApiService.post<void>(
      ApiConstants.changePassword,
      body: {'current_password': current, 'new_password': newPass},
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);

    // Clear must_change_password flag locally
    if (_user != null) {
      _user = _user!.copyWith(mustChangePassword: false);
      await StorageService.saveUser(_user!.toJson());
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _clearSession() async {
    _token = null;
    _user  = null;
    await StorageService.clear();
    notifyListeners();
  }
}
