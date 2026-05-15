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
    defaultValue: '6jtwt7kbqtz2',
  );

  StreamChatClient? _client;
  Future<bool>? _connectFuture;

  bool get isConfigured => _apiKey.isNotEmpty;
  bool get isConnected => _client?.state.currentUser != null;
  String? get currentUserId => _client?.state.currentUser?.id;

  StreamChatClient get client {
    final activeClient = _client;
    if (activeClient == null) {
      throw StateError('Stream Chat is not configured');
    }
    return activeClient;
  }

  Future<Channel> directMessagingChannel({
    required String otherUserId,
    Map<String, Object?> extraData = const {},
  }) async {
    final currentId = currentUserId;
    if (currentId == null) {
      throw StateError('Stream Chat user is not connected');
    }
    if (otherUserId == currentId) {
      throw StateError("You can't message your own profile.");
    }

    final members = [currentId, otherUserId]..sort();
    final channel = client.channel(
      'messaging',
      extraData: {
        ...extraData,
        'members': members,
      },
    );
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

    final token = await _storage.read(key: 'stream_token');
    final userId = await _storage.read(key: 'stream_user_id');
    if (token == null || userId == null) return false;

    _connectFuture = () async {
      _client ??= StreamChatClient(_apiKey);
      await _client!.connectUser(
        User(
          id: userId,
          name: await _storage.read(key: 'stream_user_name'),
          role: await _storage.read(key: 'user_role'),
        ),
        token,
      );
      return true;
    }();
    try {
      return await _connectFuture!;
    } catch (_) {
      return false;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> disconnect() async {
    await _client?.disconnectUser(flushChatPersistence: true);
  }
}
