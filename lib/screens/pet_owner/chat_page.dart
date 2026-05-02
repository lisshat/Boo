import 'package:flutter/material.dart';

// Demo chat thread data
class _Thread {
  final String id;
  final String providerName;
  final String providerImage;
  final String lastMessage;
  final String time;
  final int unread;

  const _Thread({
    required this.id,
    required this.providerName,
    required this.providerImage,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}

const _threads = [
  _Thread(
    id: 't1',
    providerName: 'Dr. Sarah Jenkins',
    providerImage: 'https://picsum.photos/200?random=11',
    lastMessage: "It was amazing! Thank you for choosing Charlie...",
    time: 'Today',
    unread: 2,
  ),
  _Thread(
    id: 't2',
    providerName: 'Kipepeo Grooming Studio',
    providerImage: 'https://picsum.photos/200?random=22',
    lastMessage: "Charlie's appointment is confirmed for Friday!",
    time: 'Yesterday',
    unread: 0,
  ),
  _Thread(
    id: 't3',
    providerName: "Nia Pet Sitting",
    providerImage: 'https://picsum.photos/200?random=44',
    lastMessage: "Sure, I can do a drop-in on Saturday at 10am.",
    time: 'Mon',
    unread: 0,
  ),
];

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

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
                  child: Text('Messages',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_square),
                  tooltip: 'New message',
                ),
              ],
            ),
          ),
          // Search bar
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
                  Text('Search conversations',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _threads.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEAECEF)),
              itemBuilder: (context, i) =>
                  _ThreadTile(thread: _threads[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _Thread thread;
  const _ThreadTile({required this.thread});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _ChatConversationScreen(thread: thread),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.network(
                    thread.providerImage,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.person,
                          color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                // Online dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
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
                          thread.providerName,
                          style: TextStyle(
                            fontWeight: thread.unread > 0
                                ? FontWeight.w900
                                : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(thread.time,
                          style: TextStyle(
                              fontSize: 12,
                              color: thread.unread > 0
                                  ? orange
                                  : const Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                          ),
                        ),
                      ),
                      if (thread.unread > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${thread.unread}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
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
  }
}

// ── Conversation screen ──────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const _ChatMessage(
      {required this.text, required this.isMe, required this.time});
}

class _ChatConversationScreen extends StatefulWidget {
  final _Thread thread;
  const _ChatConversationScreen({super.key, required this.thread});

  @override
  State<_ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends State<_ChatConversationScreen> {
  static const orange = Color(0xFFF68B1F);
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
        text: "Hi! I just attended Charlie's grooming session today. It was amazing! Thank you for choosing Charlie for our service.",
        isMe: false,
        time: '10:02 AM'),
    const _ChatMessage(
        text: "It was such a goodbye today 🐾",
        isMe: false,
        time: '10:03 AM'),
    const _ChatMessage(
        text: "Thank you Sarah! Charlie really enjoyed it. See you next month!",
        isMe: true,
        time: '10:15 AM'),
  ];

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
          time: TimeOfDay.now().format(context)));
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
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.thread.providerImage,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.person, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.thread.providerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF111827))),
                const Text('Online',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Colors.black.withOpacity(0.06))),
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
                            horizontal: 16, vertical: 10),
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
                          color: orange, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
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

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isMe ? orange : Colors.white,
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
                      color:
                          msg.isMe ? Colors.white : const Color(0xFF111827),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(msg.time,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
