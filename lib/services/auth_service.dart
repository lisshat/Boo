import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Base URL of the NestJS backend.
/// Android emulator: use 10.0.2.2 to reach host machine localhost.
/// Change to your Render URL for production.
const String _baseUrl = 'http://10.0.2.2:3000';

const _storage = FlutterSecureStorage();
final navigatorKey = GlobalKey<NavigatorState>();

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Token storage ──────────────────────────────────────────────

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_role', value: role);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getUserRole() => _storage.read(key: 'user_role');

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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _saveTokens(
          accessToken: body['accessToken'] as String,
          refreshToken: body['refreshToken'] as String,
          role: body['role'] as String,
        );
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
        await _saveTokens(
          accessToken: body['accessToken'] as String,
          refreshToken: body['refreshToken'] as String,
          role: body['role'] as String,
        );
        return null;
      }
      final msg = body['message'];
      return (msg is List ? msg.first : msg) as String? ?? 'Registration failed';
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
        await _saveTokens(
          accessToken: body['accessToken'] as String,
          refreshToken: body['refreshToken'] as String,
          role: body['role'] as String,
        );
        return null;
      }
      return (body['message'] as String?) ?? 'Token refresh failed';
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }

  }

  Future<void> logout() => clearTokens();

}
// ── Generic authenticated HTTP client ──────────────────────────────

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<http.Response> get(String path) async {
    final token = await AuthService.instance.getAccessToken();
    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if(res.statusCode == 401) {
      // Handle token expiration, e.g., by trying to refresh the token
      // and retrying the request. This is a simplified example.
     await AuthService.instance.refreshToken();
      final retried = await get(path); // Retry the request after refreshing the token

      if(retried.statusCode == 401) {
        // If it still fails, log out the user
        await AuthService.instance.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Session expired. Please log in again.');
      }
    
    return retried;
  }
   return res;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await AuthService.instance.getAccessToken();
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshToken();
      final retried = await post(path, body);
      if (retried.statusCode == 401) {
        await AuthService.instance.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Session expired. Please log in again.');
      }
      return retried;
    }
    return res;
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final token = await AuthService.instance.getAccessToken();
    final res = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshToken();
      final retried = await patch(path, body);
      if (retried.statusCode == 401) {
        await AuthService.instance.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Session expired. Please log in again.');
      }
      return retried;
    }
    return res;
  }

  Future<http.Response> delete(String path) async {
    final token = await AuthService.instance.getAccessToken();
    final res = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshToken();
      final retried = await delete(path);
      if (retried.statusCode == 401) {
        await AuthService.instance.logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('Session expired. Please log in again.');
      }
      return retried;
    }
    return res;
  }


}
