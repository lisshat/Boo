import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:boo/screens/banned_screen.dart';
import 'package:boo/services/stream_chat_service.dart';

/// Web uses localhost; Android emulator uses 10.0.2.2 to reach host localhost.
/// Change to your Render URL for production.
final String _baseUrl =
    kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
final navigatorKey = GlobalKey<NavigatorState>();
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Token storage ──────────────────────────────────────────────

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    String? email,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_role', value: role);
    if (email != null) await _storage.write(key: 'user_email', value: email);
  }

  String? _readString(
      Map<String, dynamic> body, String snakeKey, String camelKey) {
    return (body[snakeKey] as String?) ?? (body[camelKey] as String?);
  }

  String _readRole(Map<String, dynamic> body) {
    final user = body['user'] as Map<String, dynamic>?;
    return (user?['role'] as String?) ?? (body['role'] as String?) ?? 'owner';
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getUserRole() => _storage.read(key: 'user_role');

  Future<String?> getUserEmail() => _storage.read(key: 'user_email');

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Auth calls ─────────────────────────────────────────────────

  /// Returns `null` on success; an error message string on failure.
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 403) {
        await logout();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => BannedScreen(email: email),
          ),
          (route) => false,
        );
        return '__ACCOUNT_SUSPENDED__';
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final accessToken = _readString(body, 'access_token', 'accessToken');
        final refreshToken = _readString(body, 'refresh_token', 'refreshToken');
        if (accessToken == null || refreshToken == null) {
          return 'Login response was missing auth tokens';
        }
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: _readRole(body),
          email: email,
        );
        await BooStreamChatService.instance.saveSessionFromAuthPayload(body);
        await BooStreamChatService.instance.connectFromStoredSession();
        return null;
      }
      return (body['message'] as String?) ?? 'Login failed';
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  /// Returns `null` on success; an error message string on failure.
  Future<String?> register(
    String email,
    String password, {
    String? fullName,
    String role = 'owner',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (fullName != null) 'fullName': fullName,
          'role': role,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final accessToken = _readString(body, 'access_token', 'accessToken');
        final refreshToken = _readString(body, 'refresh_token', 'refreshToken');
        if (accessToken == null || refreshToken == null) {
          return 'Registration response was missing auth tokens';
        }
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: _readRole(body),
          email: email,
        );
        await BooStreamChatService.instance.saveSessionFromAuthPayload(body);
        await BooStreamChatService.instance.connectFromStoredSession();
        return null;
      }
      final msg = body['message'];
      return (msg is List ? msg.first : msg) as String? ??
          'Registration failed';
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return _errorMessageFromResponse(res, 'Could not send reset link');
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return _errorMessageFromResponse(res, 'Could not update password');
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<String?> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return 'No refresh token available';
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final accessToken = _readString(body, 'access_token', 'accessToken');
        final refreshToken = _readString(body, 'refresh_token', 'refreshToken');
        if (accessToken == null || refreshToken == null) {
          return 'Token refresh response was missing auth tokens';
        }
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: _readRole(body),
        );
        return null;
      }
      return (body['message'] as String?) ?? 'Token refresh failed';
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<void> logout() async {
    UserCache.instance.clear();
    await BooStreamChatService.instance.disconnect();
    await clearTokens();
  }
}

String _errorMessageFromResponse(http.Response res, String fallback) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final message = body['message'];
    if (message is List && message.isNotEmpty) return message.first.toString();
    if (message is String && message.isNotEmpty) return message;
  } catch (_) {}
  return fallback;
}
// ── Generic authenticated HTTP client ──────────────────────────────

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Raw calls — no retry logic, no recursion.
  Future<http.Response> _rawGet(String path) async {
    return http
        .get(Uri.parse('$_baseUrl$path'), headers: await _authHeaders())
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> _rawPost(String path, Map<String, dynamic> body) async {
    return http
        .post(Uri.parse('$_baseUrl$path'),
            headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> _rawPatch(
      String path, Map<String, dynamic> body) async {
    return http
        .patch(Uri.parse('$_baseUrl$path'),
            headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> _rawPut(String path, Map<String, dynamic> body) async {
    return http
        .put(Uri.parse('$_baseUrl$path'),
            headers: await _authHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> _rawDelete(String path) async {
    return http
        .delete(Uri.parse('$_baseUrl$path'), headers: await _authHeaders())
        .timeout(const Duration(seconds: 10));
  }

  // One refresh attempt, then force-logout. Never calls itself.
  Future<http.Response> _withRefresh(
      Future<http.Response> Function() call) async {
    final res = await call();
    if (res.statusCode == 403) {
      Map<String, dynamic>? body;
      try { body = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
      if (body?['code'] == 'ACCOUNT_SUSPENDED') {
        await AuthService.instance.logout();
        final email = await AuthService.instance.getUserEmail();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => BannedScreen(email: email ?? '')),
          (route) => false,
        );
        throw Exception('Account suspended');
      }
      return res;
    }
    if (res.statusCode != 401) return res;

    final refreshError = await AuthService.instance.refreshToken();
    if (refreshError != null) {
      await AuthService.instance.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception('Session expired. Please log in again.');
    }

    final retried = await call();
    if (retried.statusCode == 401) {
      await AuthService.instance.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception('Session expired. Please log in again.');
    }
    return retried;
  }

  Future<http.Response> get(String path) => _withRefresh(() => _rawGet(path));

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      _withRefresh(() => _rawPost(path, body));

  Future<http.Response> patch(String path, Map<String, dynamic> body) =>
      _withRefresh(() => _rawPatch(path, body));

  Future<http.Response> put(String path, Map<String, dynamic> body) =>
      _withRefresh(() => _rawPut(path, body));

  Future<http.Response> delete(String path) =>
      _withRefresh(() => _rawDelete(path));
}

// ── In-memory user cache ───────────────────────────────────────────────────────

class UserCache {
  UserCache._();
  static final UserCache instance = UserCache._();

  Map<String, dynamic>? _data;

  Map<String, dynamic>? get data => _data;
  void set(Map<String, dynamic> data) => _data = data;
  void clear() => _data = null;
}
