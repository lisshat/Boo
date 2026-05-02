import 'package:flutter/material.dart';

class _Thread {
  final String id;
  final String ownerName;
  final String lastMessage;
  final String time;
  final int unread;
  final String petName;

  const _Thread({
    required this.id,
    required this.ownerName,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.petName,
  });
}

const _demoThreads = [
  _Thread(
    id: 't1',
    ownerName: 'Amina Osei',
    petName: 'Biscuit',
    lastMessage: "I'll be there 8 minutes early to meet Bella before our walk",
    time: 'Now',
    unread: 2,
  ),
  _Thread(
    id: 't2',
    ownerName: 'Kevin Mwangi',
    petName: 'Luna',
    lastMessage: 'Does Luna need a bath before boarding?',
    time: '10:30 AM',
    unread: 1,
  ),
  _Thread(
    id: 't3',
    ownerName: 'Cynthia Njoroge',
    petName: 'Max',
    lastMessage: 'Thanks! See you tomorrow at 9.',
    time: 'Yesterday',
    unread: 0,
  ),
  _Thread(
    id: 't4',
    ownerName: 'David Kariuki',
    petName: 'Sasha',
    lastMessage: "Sasha's grooming session was great, thank you!",
    time: 'Mon',
    unread: 0,
  ),
];

class ProviderChatPage extends StatelessWidget {
  const ProviderChatPage({super.key});

  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    final unreadCount = _demoThreads.fold(0, (sum, t) => sum + t.unread);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              child: _demoThreads.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _demoThreads.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEAECEF)),
                      itemBuilder: (context, i) =>
                          _ThreadTile(thread: _demoThreads[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            'Conversations with pet owners\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _Thread thread;

  const _ThreadTile({required this.thread});

  static const _orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ProviderConversationScreen(thread: thread),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Avatar(name: thread.ownerName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.ownerName,
                          style: TextStyle(
                            fontWeight: thread.unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        thread.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: thread.unread > 0 ? _orange : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: thread.unread > 0
                                ? const Color(0xFF374151)
                                : const Color(0xFF9CA3AF),
                            fontWeight: thread.unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (thread.unread > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${thread.unread}',
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
                    thread.petName,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

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

// ── Conversation screen ────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const _ChatMessage({required this.text, required this.isMe, required this.time});
}

class _ProviderConversationScreen extends StatefulWidget {
  final _Thread thread;

  const _ProviderConversationScreen({super.key, required this.thread});

  @override
  State<_ProviderConversationScreen> createState() =>
      _ProviderConversationScreenState();
}

class _ProviderConversationScreenState
    extends State<_ProviderConversationScreen> {
  static const _orange = Color(0xFFF68B1F);

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        text: "Hi! I'm reaching out about booking for ${widget.thread.petName}.",
        isMe: false,
        time: '9:00 AM',
      ),
      const _ChatMessage(
        text: "Hello! Great, I'd be happy to help. What service are you looking for?",
        isMe: true,
        time: '9:05 AM',
      ),
      _ChatMessage(
        text: widget.thread.lastMessage,
        isMe: false,
        time: widget.thread.time,
      ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMe: true,
        time: TimeOfDay.now().format(context),
      ));
    });
    _ctrl.clear();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(name: widget.thread.ownerName),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  widget.thread.petName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
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
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _ChatMessage msg;

  const _Bubble({required this.msg});

  static const _orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isMe ? _orange : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                    ),
                    border: msg.isMe
                        ? null
                        : Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isMe ? Colors.white : const Color(0xFF111827),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
