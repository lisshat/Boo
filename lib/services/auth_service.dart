import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:boo/screens/banned_screen.dart';
import 'package:boo/services/stream_chat_service.dart';
import 'package:boo/services/push_notification_service.dart';
import 'package:boo/services/revenuecat_service.dart';
import 'package:boo/services/premium_access_service.dart';

/// Override with --dart-define=API_BASE_URL=... when required.
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://boo-backend.onrender.com',
);

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
final navigatorKey = GlobalKey<NavigatorState>();

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  Future<void>? _invalidSessionCleanup;

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
    return (user?['role'] as String?) ?? (body['role'] as String?) ?? '';
  }

  Future<String?> _saveAuthenticationResponse(
    Map<String, dynamic> body, {
    String? email,
    bool initializeStream = true,
  }) async {
    final accessToken = _readString(body, 'access_token', 'accessToken');
    final refreshToken = _readString(body, 'refresh_token', 'refreshToken');
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      return 'Authentication response was missing valid auth tokens';
    }
    var user = body['user'] as Map<String, dynamic>?;
    if (user == null ||
        user['id']?.toString().trim().isEmpty == true ||
        user['role']?.toString().trim().isEmpty == true) {
      final resolved = await _resolveAuthenticatedUser(accessToken);
      if (resolved != null) user = resolved;
    }
    final storedRole = await getUserRole();
    final role =
        _readRole(body).trim().isEmpty ? (storedRole ?? '') : _readRole(body);
    await _saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
      email: email ?? user?['email'] as String?,
    );
    // Never reuse a previous account's cached UUID when an authentication
    // response omits identity data. The authenticated identity must come from
    // this response or the authoritative /auth/me lookup above.
    final userId = user?['id'] as String?;
    final fullName = _readString(user ?? {}, 'full_name', 'fullName');
    if (userId != null) {
      await _storage.write(key: 'user_id', value: userId);
    } else {
      await _storage.delete(key: 'user_id');
      PremiumAccessController.instance.clear();
    }
    if (fullName != null)
      await _storage.write(key: 'user_full_name', value: fullName);
    if (initializeStream) {
      // Stream is optional during authentication. Keep failures contained so
      // login/registration can route to the shell without waiting for chat.
      unawaited(_initializeStreamSession(body));
    }
    // Push identity is optional and must never delay authentication routing.
    unawaited(PushNotificationService.instance.associateUser(userId));
    // Membership identity is optional and must never delay authentication.
    if (userId != null) {
      PremiumAccessController.instance.setAuthenticatedRole(role);
    } else {
      PremiumAccessController.instance.clear();
    }
    unawaited(RevenueCatService.instance.associateUser(
      userId,
      role: role,
    ));
    return null;
  }

  Future<Map<String, dynamic>?> _resolveAuthenticatedUser(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final nested = decoded['user'];
      return nested is Map<String, dynamic> ? nested : decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<void> clearInvalidSession() {
    return _invalidSessionCleanup ??= _clearInvalidSession();
  }

  Future<void> _clearInvalidSession() async {
    UserCache.instance.clear();
    // Invalidate pending push navigation synchronously before optional SDK
    // cleanup can complete.
    final pushCleanup = PushNotificationService.instance.clearIdentity();
    final revenueCatCleanup = RevenueCatService.instance.clearIdentity();
    PremiumAccessController.instance.clear();
    try {
      await BooStreamChatService.instance
          .disconnect()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // A failed optional chat disconnect must not preserve invalid auth.
    } finally {
      await clearTokens();
      await Future.wait([pushCleanup, revenueCatCleanup]);
    }
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getUserRole() => _storage.read(key: 'user_role');

  Future<String?> getUserEmail() => _storage.read(key: 'user_email');

  Future<String?> getUserId() => _storage.read(key: 'user_id');

  Future<void> associateStoredPushIdentity() async {
    var userId = await getUserId();
    if (userId == null || userId.trim().isEmpty) {
      try {
        final response = await ApiService.instance.get('/auth/me');
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final currentUser = body['user'] is Map<String, dynamic>
                ? body['user'] as Map<String, dynamic>
                : body;
            userId = currentUser['id']?.toString();
            if (userId != null && userId.trim().isNotEmpty) {
              await _storage.write(key: 'user_id', value: userId);
            }
            final role = currentUser['role']?.toString();
            if (role != null && role.trim().isNotEmpty) {
              await _storage.write(key: 'user_role', value: role);
              PremiumAccessController.instance.setAuthenticatedRole(role);
            }
          }
        }
      } catch (_) {
        // Push association is optional during session restoration.
      }
    }
    PremiumAccessController.instance.setAuthenticatedRole(
      await getUserRole(),
    );
    await PushNotificationService.instance.associateUser(userId);
    await RevenueCatService.instance.associateUser(
      userId,
      role: await getUserRole(),
    );
  }

  Future<Map<String, dynamic>> getEmailVerificationStatus() async {
    final response =
        await ApiService.instance.get('/auth/email-verification/status');
    return _verificationResponse(
        response, 'Could not load email confirmation status');
  }

  Future<Map<String, dynamic>> sendEmailVerificationCode() async {
    final response =
        await ApiService.instance.post('/auth/email-verification/send', {});
    return _verificationResponse(
        response, 'Could not send a confirmation code');
  }

  Future<Map<String, dynamic>> confirmEmailVerificationCode(String code) async {
    final response = await ApiService.instance.post(
      '/auth/email-verification/confirm',
      {'code': code},
    );
    return _verificationResponse(response, 'Could not confirm your email');
  }

  Map<String, dynamic> _verificationResponse(
    http.Response response,
    String fallback,
  ) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body != null) {
      return body;
    }
    final rawMessage = body?['message'];
    final message = rawMessage is List
        ? (rawMessage.isEmpty ? null : rawMessage.first.toString())
        : rawMessage?.toString();
    throw EmailVerificationException(
      code: body?['code']?.toString(),
      retryAfterSeconds: (body?['retryAfterSeconds'] as num?)?.toInt(),
      message: message == null || message.trim().isEmpty ? fallback : message,
    );
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.trim().isNotEmpty;
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
        return await _saveAuthenticationResponse(body, email: email);
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
        return await _saveAuthenticationResponse(body, email: email);
      }
      final msg = body['message'];
      return (msg is List ? msg.first : msg) as String? ??
          'Registration failed';
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<void> _initializeStreamSession(Map<String, dynamic> body) async {
    try {
      await BooStreamChatService.instance.saveSessionFromAuthPayload(body);
      final streamToken = body['stream_token'];
      if (streamToken is String && streamToken.isNotEmpty) {
        await BooStreamChatService.instance.connectFromStoredSession();
      }
    } catch (_) {
      // Chat is optional; a successful Boo authentication remains valid.
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/password-reset/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return _safePasswordResetError(res, 'Could not send reset code');
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<String?> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/password-reset/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'code': code,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return _safePasswordResetError(res, 'Could not update password');
    } catch (_) {
      return 'Could not reach server. Check your connection.';
    }
  }

  Future<String?> forgotPassword(String email) => requestPasswordReset(email);

  String _safePasswordResetError(http.Response response, String fallback) {
    if (response.statusCode >= 500)
      return 'The service is temporarily unavailable. Please try again.';
    final message = _errorMessageFromResponse(response, fallback);
    if (message.contains('password_reset') || message.contains('QueryFailed'))
      return fallback;
    return message;
  }

  Future<RefreshResult> refreshToken() async {
    final stopwatch = Stopwatch()..start();
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _logTiming('refresh', stopwatch);
        return const RefreshResult.rejected('No refresh token available');
      }
      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401 || res.statusCode == 403) {
        await clearInvalidSession();
        _logTiming('refresh_rejected', stopwatch);
        return const RefreshResult.rejected(
            'Session expired. Please sign in again.');
      }
      Map<String, dynamic> body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! Map<String, dynamic>) {
          _logTiming('refresh_malformed', stopwatch);
          return const RefreshResult.malformed();
        }
        body = decoded;
      } catch (_) {
        _logTiming('refresh_malformed', stopwatch);
        return const RefreshResult.malformed();
      }
      if (res.statusCode == 200 || res.statusCode == 201) {
        final error = await _saveAuthenticationResponse(
          body,
          initializeStream: false,
        );
        _logTiming('refresh_success', stopwatch);
        return error == null
            ? const RefreshResult.success()
            : const RefreshResult.malformed();
      }
      _logTiming('refresh_transient_failure', stopwatch);
      return const RefreshResult.transientFailure();
    } on TimeoutException {
      _logTiming('refresh_timeout', stopwatch);
      return const RefreshResult.transientFailure();
    } on http.ClientException {
      _logTiming('refresh_network_failure', stopwatch);
      return const RefreshResult.transientFailure();
    } catch (_) {
      _logTiming('refresh_failure', stopwatch);
      return const RefreshResult.transientFailure();
    }
  }

  void _logTiming(String operation, Stopwatch stopwatch) {
    if (kDebugMode) {
      debugPrint('[auth timing] $operation ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  Future<void> logout() async {
    UserCache.instance.clear();
    final pushCleanup = PushNotificationService.instance.clearIdentity();
    final revenueCatCleanup = RevenueCatService.instance.clearIdentity();
    PremiumAccessController.instance.clear();
    final streamCleanup = BooStreamChatService.instance.disconnect();
    await clearTokens();
    // Local logout is complete even if the native push SDK is unavailable.
    await Future.wait([streamCleanup, pushCleanup, revenueCatCleanup]);
    _invalidSessionCleanup = null;
  }
}

enum RefreshResultKind { success, rejected, transientFailure, malformed }

class RefreshResult {
  final RefreshResultKind kind;
  final String? message;

  const RefreshResult._(this.kind, [this.message]);
  const RefreshResult.success() : this._(RefreshResultKind.success);
  const RefreshResult.rejected(String message)
      : this._(RefreshResultKind.rejected, message);
  const RefreshResult.transientFailure()
      : this._(RefreshResultKind.transientFailure);
  const RefreshResult.malformed() : this._(RefreshResultKind.malformed);

  bool get isSuccess => kind == RefreshResultKind.success;
}

class EmailVerificationException implements Exception {
  final String? code;
  final int? retryAfterSeconds;
  final String message;

  const EmailVerificationException({
    required this.message,
    this.code,
    this.retryAfterSeconds,
  });

  @override
  String toString() => message;
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
  Future<RefreshResult>? _refreshInFlight;
  Future<void>? _sessionRoute;

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
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
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

    final refreshResult = await _refreshOnce();
    if (!refreshResult.isSuccess) {
      if (refreshResult.kind == RefreshResultKind.rejected) {
        await _routeToLoginOnce();
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception('Could not refresh your session. Check your connection.');
    }

    final retried = await call();
    if (retried.statusCode == 401) {
      await AuthService.instance.clearInvalidSession();
      await _routeToLoginOnce();
      throw Exception('Session expired. Please log in again.');
    }
    return retried;
  }

  Future<RefreshResult> _refreshOnce() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = AuthService.instance.refreshToken();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<void> _routeToLoginOnce() {
    final inFlight = _sessionRoute;
    if (inFlight != null) return inFlight;
    final future = () async {
      await AuthService.instance.clearInvalidSession();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
    }();
    _sessionRoute = future;
    return future.whenComplete(() => _sessionRoute = null);
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
