import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get('/notifications');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _notifications = raw.cast<Map<String, dynamic>>();
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() { _isLoading = false; _error = 'Could not load notifications'; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _error = 'Connection error'; });
    }
  }

  Future<void> _markRead(int index) async {
    final n = _notifications[index];
    if (n['isRead'] == true) return;
    final id = n['notificationId'] as String;
    setState(() => _notifications[index] = {...n, 'isRead': true});
    await ApiService.instance.patch('/notifications/$id/read', {});
  }

  Future<void> _markAllRead() async {
    await ApiService.instance.patch('/notifications/read-all', {});
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((n) => {...n, 'isRead': true})
          .toList();
    });
  }

  Future<void> _delete(int index) async {
    final n = _notifications[index];
    final id = n['notificationId'] as String;
    setState(() => _notifications.removeAt(index));
    try {
      await ApiService.instance.delete('/notifications/$id');
    } catch (_) {
      // Optimistic delete — if it fails, reload to restore
      _load();
    }
  }

  void _onTap(int index) async {
    await _markRead(index);
    if (!mounted) return;
    final n = _notifications[index];
    final type = n['type'] as String? ?? '';

    // For booking events, pop back to the shell so user can navigate to bookings
    final bookingTypes = {
      'booking_request',
      'booking_accepted',
      'booking_declined',
      'booking_cancelled',
      'booking_completed',
    };
    if (bookingTypes.contains(type)) {
      if (mounted) Navigator.pop(context);
    }
    // verification and system: stay on screen (notification is the info)
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.event_available_outlined;
      case 'booking_accepted':
        return Icons.check_circle_outline_rounded;
      case 'booking_declined':
        return Icons.cancel_outlined;
      case 'booking_cancelled':
        return Icons.event_busy_outlined;
      case 'booking_completed':
        return Icons.task_alt_rounded;
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      case 'verification_approved':
        return Icons.verified_outlined;
      case 'verification_rejected':
        return Icons.gpp_bad_outlined;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type, bool isRead) {
    if (isRead) return Colors.grey.shade400;
    switch (type) {
      case 'booking_accepted':
      case 'booking_completed':
      case 'verification_approved':
        return Colors.green.shade500;
      case 'booking_declined':
      case 'booking_cancelled':
      case 'verification_rejected':
        return Colors.red.shade400;
      case 'booking_request':
        return _orange;
      case 'new_message':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['isRead'] == false);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: _orange, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.black45)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry', style: TextStyle(color: _orange)),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You're all caught up",
                            style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _orange,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          final isRead = n['isRead'] == true;
                          final type = n['type'] as String? ?? '';
                          final icon = _iconFor(type);
                          final color = _colorFor(type, isRead);

                          return Dismissible(
                            key: ValueKey(n['notificationId']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            onDismissed: (_) => _delete(i),
                            child: GestureDetector(
                              onTap: () => _onTap(i),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white : const Color(0xFFFFF8F0),
                                    border: Border(
                                      left: BorderSide(
                                        color: isRead ? Colors.transparent : _orange,
                                        width: 4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? Colors.grey.shade100
                                              : color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, size: 18, color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n['title'] as String? ?? '',
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if ((n['message'] as String?)?.isNotEmpty == true) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                n['message'] as String,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    height: 1.4),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              _timeAgo(n['createdAt'] as String?),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(top: 4, left: 8),
                                          decoration: const BoxDecoration(
                                            color: _orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
