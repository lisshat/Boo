import 'package:boo/services/stream_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ProviderChatPage extends StatefulWidget {
  const ProviderChatPage({super.key});

  @override
  State<ProviderChatPage> createState() => _ProviderChatPageState();
}

class _ProviderChatPageState extends State<ProviderChatPage> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late final Future<Stream<List<Channel>>?> _channelsFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Stream<List<Channel>>?>(
          future: _channelsFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final channelStream = snapshot.data;

            return StreamBuilder<List<Channel>>(
              stream: channelStream,
              builder: (context, channelSnapshot) {
                final channels = channelSnapshot.data ?? const <Channel>[];
                final unreadCount = channels.fold<int>(
                  0,
                  (sum, channel) => sum + (channel.state?.unreadCount ?? 0),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unreadCount unread',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Color(0xFF9CA3AF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Search conversations',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildListBody(
                        loading: loading ||
                            channelSnapshot.connectionState ==
                                ConnectionState.waiting,
                        unavailable: !loading && channelStream == null,
                        channels: channels,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildListBody({
    required bool loading,
    required bool unavailable,
    required List<Channel> channels,
  }) {
    if (loading && channels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (unavailable) {
      return const _EmptyState(
        title: 'Chat unavailable',
        message: 'Log in again after Stream is configured.',
      );
    }
    if (channels.isEmpty) {
      return const _EmptyState(
        title: 'No messages yet',
        message: 'Conversations with pet owners will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: channels.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEAECEF)),
      itemBuilder: (context, i) => _ThreadTile(
        channel: channels[i],
        onReadChanged: () => setState(() {}),
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

class _ThreadTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onReadChanged;

  const _ThreadTile({required this.channel, required this.onReadChanged});

  static const _orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final otherUser = _otherUser(channel);
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProviderConversationScreen(channel: channel),
              ),
            );
            await _markChannelRead(channel);
            onReadChanged();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _Avatar(user: otherUser),
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
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _relativeTime(lastMessage?.createdAt ??
                                channel.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0
                                  ? _orange
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
                                fontWeight: unread > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: _orange,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        channel.name ?? 'Boo chat',
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

class _Avatar extends StatelessWidget {
  final User? user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final image = user?.image;
    if (image != null) {
      return ClipOval(
        child: Image.network(
          image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(name: user?.name ?? '?'),
        ),
      );
    }
    return _InitialAvatar(name: user?.name ?? '?');
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF68B1F).withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFF68B1F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class ProviderConversationScreen extends StatefulWidget {
  final Channel channel;

  const ProviderConversationScreen({super.key, required this.channel});

  @override
  State<ProviderConversationScreen> createState() =>
      _ProviderConversationScreenState();
}

class _ProviderConversationScreenState
    extends State<ProviderConversationScreen> {
  static const _orange = Color(0xFFF68B1F);

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final Future<void> _watchFuture;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    _watchFuture = _watchChannel();
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(user: otherUser),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversationName(widget.channel, otherUser),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  widget.channel.name ?? 'Boo chat',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.black54),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _watchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
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
                            hintStyle:
                                const TextStyle(color: Color(0xFF9CA3AF)),
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
                            color: _orange,
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
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;

  const _Bubble({required this.message});

  static const _orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.user?.id == BooStreamChatService.instance.currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    color: isMe ? _orange : Colors.white,
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

User? _otherUser(Channel channel) {
  final currentUserId = BooStreamChatService.instance.currentUserId;
  final members = channel.state?.members ?? const <Member>[];
  for (final member in members) {
    final user = member.user;
    if (user != null && user.id != currentUserId) return user;
  }
  return members.isNotEmpty ? members.first.user : null;
}

Message? _lastMessage(Channel channel) {
  final messages = channel.state?.messages ?? const <Message>[];
  if (messages.isEmpty) return null;
  return messages.last;
}

String _conversationName(Channel channel, User? otherUser) {
  return otherUser?.name ?? channel.name ?? 'Conversation';
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  if (date == today) return 'Now';
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
