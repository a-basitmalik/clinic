import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/api_response_model.dart';
import 'storage_service.dart';

class ApiService {
  ApiService._();

  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await StorageService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static ApiResponse<T> _parse<T>(
    http.Response res,
    T Function(dynamic)? fromData,
  ) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      _handleUnauthorized();
      throw const ApiException(message: 'Session expired. Please log in again.', statusCode: 401);
    }
    if (body == null) {
      throw ApiException(
        message: 'Server returned an invalid response.',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        message: body['message'] as String? ?? 'Request failed.',
        statusCode: res.statusCode,
        errors: body['errors'] as Map<String, dynamic>?,
      );
    }
    return ApiResponse<T>.fromJson(body as Map<String, dynamic>, fromData);
  }

  static void Function()? _onUnauthorized;

  static void setUnauthorizedCallback(void Function() cb) {
    _onUnauthorized = cb;
  }

  static void _handleUnauthorized() {
    StorageService.clear();
    _onUnauthorized?.call();
  }

  // ── GET ───────────────────────────────────────────────────────────────────

  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromData,
    bool auth = true,
  }) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
      }
      final res = await http
          .get(uri, headers: await _headers(auth: auth))
          .timeout(_timeout);
      return _parse<T>(res, fromData);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'No internet connection.', statusCode: 0);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────

  static Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _parse<T>(res, fromData);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'No internet connection.', statusCode: 0);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── PUT ───────────────────────────────────────────────────────────────────

  static Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
    bool auth = true,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _parse<T>(res, fromData);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'No internet connection.', statusCode: 0);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromData,
    bool auth = true,
  }) async {
    try {
      final res = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
          )
          .timeout(_timeout);
      return _parse<T>(res, fromData);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'No internet connection.', statusCode: 0);
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }
}
