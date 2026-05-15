import 'dart:convert';

import 'package:boo/services/auth_service.dart';
import 'package:boo/services/stream_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Future<Stream<List<Channel>>?> _channelsFuture;
  final Set<String> _hiddenChannelKeys = {};

  @override
  void initState() {
    super.initState();
    _channelsFuture = _loadChannels();
  }

  Future<Stream<List<Channel>>?> _loadChannels() async {
    final streamService = BooStreamChatService.instance;
    final connected = await streamService.connectFromStoredSession();
    final userId = streamService.currentUserId;
    if (!connected || userId == null) return null;

    return streamService.client.queryChannels(
      filter: Filter.in_('members', [userId]),
      channelStateSort: const [
        SortOption<ChannelState>.desc('last_message_at'),
      ],
      paginationParams: const PaginationParams(limit: 30),
      messageLimit: 30,
      watch: true,
      state: true,
    );
  }

  Future<bool> _hideChannel(Channel channel) async {
    try {
      await channel.hide();
      if (mounted) {
        setState(() => _hiddenChannelKeys.add(_channelKey(channel)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat deleted')),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_square),
                  tooltip: 'New message',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Search conversations',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Stream<List<Channel>>?>(
              future: _channelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final channelStream = snapshot.data;
                if (channelStream == null) {
                  return const _EmptyState(
                    title: 'Chat unavailable',
                    message: 'Log in again after Stream is configured.',
                  );
                }
                return StreamBuilder<List<Channel>>(
                  stream: channelStream,
                  builder: (context, channelSnapshot) {
                    final channels = channelSnapshot.data ?? const <Channel>[];
                    if (channelSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        channels.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final visibleChannels = channels
                        .where((c) =>
                            !_isSelfChannel(c) &&
                            !_hiddenChannelKeys.contains(_channelKey(c)))
                        .toList();
                    if (visibleChannels.isEmpty) {
                      return const _EmptyState(
                        title: 'No messages yet',
                        message:
                            'Conversations with providers will appear here.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: visibleChannels.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEAECEF)),
                      itemBuilder: (context, i) {
                        final channel = visibleChannels[i];
                        return _DismissibleThread(
                          channel: channel,
                          onDelete: () => _hideChannel(channel),
                          child: _ThreadTile(
                            channel: channel,
                            onReadChanged: () => setState(() {}),
                            onSelfChannel: () {
                              setState(
                                () => _hiddenChannelKeys
                                    .add(_channelKey(channel)),
                              );
                              channel.hide().catchError((_) {});
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleThread extends StatelessWidget {
  final Channel channel;
  final Widget child;
  final Future<bool> Function() onDelete;

  const _DismissibleThread({
    required this.channel,
    required this.child,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(_channelKey(channel)),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: child,
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onReadChanged;
  final VoidCallback? onSelfChannel;

  const _ThreadTile({
    required this.channel,
    required this.onReadChanged,
    this.onSelfChannel,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    if (channel.state == null) {
      return FutureBuilder<void>(
        future: channel.watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 76);
          }
          if (snapshot.hasError) return const SizedBox.shrink();
          return _ThreadTile(
            channel: channel,
            onReadChanged: onReadChanged,
            onSelfChannel: onSelfChannel,
          );
        },
      );
    }

    final otherUser = _otherUser(channel);
    if (otherUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onSelfChannel?.call());
      return const SizedBox.shrink();
    }

    final lastMessage = _lastMessage(channel);

    return StreamBuilder<int>(
      stream: channel.state?.unreadCountStream,
      initialData: channel.state?.unreadCount ?? 0,
      builder: (context, unreadSnapshot) {
        final unread = unreadSnapshot.data ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await _markChannelRead(channel);
            onReadChanged();
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatConversationScreen(channel: channel),
            ));
            await _markChannelRead(channel);
            onReadChanged();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    _AvatarImage(user: otherUser, size: 52),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: otherUser?.online == true
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _conversationName(channel, otherUser),
                              style: TextStyle(
                                fontWeight: unread > 0
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _relativeTime(lastMessage?.createdAt ??
                                _lastMessageAt(channel)),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  unread > 0 ? orange : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (lastMessage?.text?.trim().isNotEmpty ?? false)
                                  ? lastMessage!.text!
                                  : 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: unread > 0
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: orange,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _markChannelRead(Channel channel) async {
  try {
    await channel.markRead();
  } finally {
    channel.state?.unreadCount = 0;
  }
}

class ChatConversationScreen extends StatefulWidget {
  final Channel channel;
  const ChatConversationScreen({super.key, required this.channel});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  static const orange = Color(0xFFF68B1F);
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final Future<void> _watchFuture;
  late final Future<bool> _providerVerifiedFuture;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _watchFuture = _watchChannel();
    _providerVerifiedFuture = _loadProviderVerification();
  }

  Future<void> _watchChannel() async {
    await widget.channel.watch(
      messagesPagination: const PaginationParams(limit: 40),
    );
    await _markRead();
  }

  Future<void> _markRead() async {
    final messages = widget.channel.state?.messages ?? const <Message>[];
    final lastId = messages.isNotEmpty ? messages.last.id : null;
    if (_lastMarkedMessageId == lastId) return;
    _lastMarkedMessageId = lastId;
    await _markChannelRead(widget.channel);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await widget.channel.sendMessage(Message(text: text));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = _otherUser(widget.channel);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _AvatarImage(user: otherUser, size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversationName(widget.channel, otherUser),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  otherUser?.online == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: otherUser?.online == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: FutureBuilder<void>(
        future: _watchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<bool>(
            future: _providerVerifiedFuture,
            builder: (context, verificationSnapshot) {
              final verificationReady =
                  verificationSnapshot.connectionState == ConnectionState.done;
              final isVerifiedProvider = verificationSnapshot.data ?? false;
              return Column(
                children: [
                  if (otherUser != null) ...[
                    if (verificationReady) ...[
                      _SafetyCheckBanner(isVerified: isVerifiedProvider),
                      if (!isVerifiedProvider) const _UnverifiedProviderWarning(),
                    ] else
                      const _SafetyCheckLoadingBanner(),
                  ],
                  Expanded(
                    child: StreamBuilder<List<Message>>(
                      stream: widget.channel.state?.messagesStream,
                      initialData: widget.channel.state?.messages,
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? const <Message>[];
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _markRead();
                        });
                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _Bubble(message: messages[i]),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.black.withOpacity(0.06)),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _send,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _loadProviderVerification() async {
    final channelExtra = widget.channel.extraData;
    final directVerification = channelExtra['provider_is_verified'];
    if (directVerification is bool) return directVerification;

    final directStatus = channelExtra['provider_verification_status'] ??
        channelExtra['providerVerificationStatus'];
    if (directStatus is String && directStatus.isNotEmpty) {
      final normalized = directStatus.toLowerCase();
      if (normalized == 'verified' || normalized == 'approved') return true;
      if (normalized == 'unverified' || normalized == 'pending') return false;
    }

    final providerId = widget.channel.extraData['provider_id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      return _isVerifiedProvider(widget.channel, _otherUser(widget.channel));
    }

    try {
      final res = await ApiService.instance.get('/providers/$providerId');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['isVerified'] as bool? ?? false;
      }
    } catch (_) {
      // Fall back to any Stream metadata if the provider lookup fails.
    }
    return _isVerifiedProvider(widget.channel, _otherUser(widget.channel));
  }
}

class _SafetyCheckBanner extends StatelessWidget {
  final bool isVerified;

  const _SafetyCheckBanner({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        'Safety Check\nYou are chatting with a ${isVerified ? 'Verified' : 'Unverified'} provider.\n1. Meet in a public space before sharing your home address.\n2. If unverified, ask for an ID copy or pet-care reference.\n3. Share your vet contact before service starts.\n4. Keep coordination in this chat for your protection.',
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnverifiedProviderWarning extends StatelessWidget {
  const _UnverifiedProviderWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Text(
        'Identity Not Verified\nThis provider has not completed our security check. For your pet\'s safety, request a video call and meet in a public park before booking.',
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF7C2D12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SafetyCheckLoadingBanner extends StatelessWidget {
  const _SafetyCheckLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Safety Check\nChecking provider verification status...',
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  const _Bubble({required this.message});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.user?.id == BooStreamChatService.instance.currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? orange : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: Text(
                    message.text ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF111827),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clockTime(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final User? user;
  final double size;

  const _AvatarImage({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final image = user?.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: image != null
          ? Image.network(
              image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _AvatarFallback(user: user, size: size),
            )
          : _AvatarFallback(user: user, size: size),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final User? user;
  final double size;

  const _AvatarFallback({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '?';
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFF68B1F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

User? _otherUser(Channel channel) {
  final currentUserId = BooStreamChatService.instance.currentUserId;
  final members = channel.state?.members ?? const <Member>[];
  for (final member in members) {
    final user = member.user;
    if (user != null && user.id != currentUserId) return user;
  }
  return null;
}

// A channel is a self-channel if members are loaded AND none of them is someone else.
bool _isSelfChannel(Channel channel) {
  final members = channel.state?.members;
  if (members == null || members.isEmpty) return false;
  return _otherUser(channel) == null;
}

String _channelKey(Channel channel) {
  return channel.cid ?? '${channel.type}:${channel.id ?? channel.hashCode}';
}

Message? _lastMessage(Channel channel) {
  final messages = channel.state?.messages ?? const <Message>[];
  if (messages.isEmpty) return null;
  return messages.last;
}

DateTime? _lastMessageAt(Channel channel) {
  return channel.state?.channelState.channel?.lastMessageAt;
}

String _conversationName(Channel channel, User? otherUser) {
  return channel.name ?? otherUser?.name ?? 'Conversation';
}

bool _isVerifiedProvider(Channel channel, User? otherUser) {
  final userExtra = otherUser?.extraData ?? const <String, Object?>{};
  final channelExtra = channel.extraData;
  final values = [
    userExtra['isVerified'],
    userExtra['is_verified'],
    userExtra['verificationStatus'],
    userExtra['verification_status'],
    channelExtra['provider_is_verified'],
    channelExtra['providerVerificationStatus'],
    channelExtra['provider_verification_status'],
  ];
  return values.any(
      (value) => value == true || value == 'approved' || value == 'verified');
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  if (date == today) return 'Today';
  if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${local.month}/${local.day}';
}

String _clockTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
