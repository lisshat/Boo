import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class BooStreamChatService {
  BooStreamChatService._();
  static final BooStreamChatService instance = BooStreamChatService._();

  static const _apiKey = String.fromEnvironment(
    'STREAM_API_KEY',
    defaultValue: 'zv9s54g7xnv5',
  );

  StreamChatClient? _client;
  Future<bool>? _connectFuture;

  bool get isConfigured => _apiKey.isNotEmpty;
  bool get isConnected => _client?.state.currentUser != null;

  /// Returns the client only while a live user connection exists. UI surfaces
  /// such as unread badges must not touch [client] while reconnecting or when
  /// Stream is unavailable.
  StreamChatClient? get connectedClient => isConnected ? _client : null;
  String? get currentUserId => _client?.state.currentUser?.id;

  StreamChatClient get client {
    final activeClient = _client;
    if (activeClient == null) {
      throw StateError('Stream Chat is not configured');
    }
    return activeClient;
  }

  Future<Channel> openAuthorizedChannel({
    required String channelId,
    String channelType = 'messaging',
  }) async {
    if (channelId.trim().isEmpty || channelType.trim().isEmpty) {
      throw ArgumentError('The authorized chat channel is invalid.');
    }
    final channel = client.channel(channelType, id: channelId);
    await channel.watch();
    return channel;
  }

  Future<void> saveSessionFromAuthPayload(Map<String, dynamic> body) async {
    final user = body['user'] as Map<String, dynamic>?;
    final streamToken = body['stream_token'] as String?;
    final userId = user?['id'] as String?;
    final fullName =
        (user?['full_name'] as String?) ?? (user?['fullName'] as String?);

    if (streamToken != null) {
      await _storage.write(key: 'stream_token', value: streamToken);
    }
    if (userId != null) {
      await _storage.write(key: 'stream_user_id', value: userId);
    }
    if (fullName != null) {
      await _storage.write(key: 'stream_user_name', value: fullName);
    }
  }

  Future<bool> connectFromStoredSession() async {
    if (!isConfigured) return false;
    if (isConnected) return true;
    final inFlight = _connectFuture;
    if (inFlight != null) return inFlight;

    // Assign the shared future before any asynchronous storage read. The
    // shell, notification bell and chat screen can all request connection at
    // the same time; without this single-flight boundary they each call
    // connectUser and Stream rejects the duplicates as "already available".
    final future = _connectStoredSession();
    _connectFuture = future;
    try {
      return await future;
    } catch (_) {
      // A concurrent caller may have completed the connection successfully.
      // Never clear that shared client because one waiter observed an error.
      if (!isConnected) _client = null;
      if (kDebugMode) {
        debugPrint('[auth timing] stream_connect_failed');
      }
      return false;
    } finally {
      if (identical(_connectFuture, future)) _connectFuture = null;
    }
  }

  Future<bool> _connectStoredSession() async {
    final stopwatch = Stopwatch()..start();
    final token = await _storage.read(key: 'stream_token');
    final userId = await _storage.read(key: 'stream_user_id');
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return false;
    }

    final client = _client ??= StreamChatClient(_apiKey);
    try {
      await client
          .connectUser(
            User(
              id: userId,
              name: await _storage.read(key: 'stream_user_name'),
              role: await _storage.read(key: 'user_role'),
            ),
            token,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Stream can report an already-open connection when a previous caller
      // completed just before this attempt observed the shared future. Treat
      // that state as connected instead of converting it into an outage.
      if (!isConnected) rethrow;
    }
    if (kDebugMode) {
      debugPrint(
          '[auth timing] stream_connect ${stopwatch.elapsedMilliseconds}ms');
    }
    return isConnected;
  }

  Future<void> disconnect() async {
    await _client?.disconnectUser(flushChatPersistence: true);
  }
}
