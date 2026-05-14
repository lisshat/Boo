import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/screens/notifications_screen.dart';
import 'package:boo/services/stream_chat_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  static const _orange = Color(0xFFF68B1F);

  int _unreadCount = 0;
  int _messageUnreadCount = 0;
  Timer? _timer;
  StreamSubscription<int>? _messageUnreadSub;

  @override
  void initState() {
    super.initState();
    _loadCount();
    _listenForMessageUnreadCount();
    // Poll every 30 seconds while screen is active
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageUnreadSub?.cancel();
    super.dispose();
  }

  Future<void> _listenForMessageUnreadCount() async {
    final streamService = BooStreamChatService.instance;
    final connected = await streamService.connectFromStoredSession();
    if (!mounted || !connected) return;
    setState(() {
      _messageUnreadCount = streamService.client.state.totalUnreadCount;
    });
    _messageUnreadSub =
        streamService.client.state.totalUnreadCountStream.listen((count) {
      if (mounted) setState(() => _messageUnreadCount = count);
    });
  }

  Future<void> _loadCount() async {
    try {
      final res = await ApiService.instance.get('/notifications/unread-count');
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _unreadCount = (body['count'] as int?) ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _unreadCount + _messageUnreadCount;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        _loadCount(); // refresh badge when returning from screen
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_outlined,
                  size: 20, color: Colors.black54),
            ),
            if (totalUnread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                      color: _orange, shape: BoxShape.circle),
                  child: Text(
                    totalUnread > 9 ? '9+' : '$totalUnread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
