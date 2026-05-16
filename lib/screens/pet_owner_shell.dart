import 'package:boo/screens/pet_owner/bookings_page.dart';
import 'package:boo/screens/pet_owner/chat_page.dart';
import 'package:boo/screens/pet_owner/home_dashboard.dart';
import 'package:boo/screens/pet_owner/profile_page.dart';
import 'package:boo/services/stream_chat_service.dart';

import 'package:flutter/material.dart';

class PetOwnerShell extends StatefulWidget {
  final int initialIndex;
  const PetOwnerShell({super.key, this.initialIndex = 0});

  @override
  State<PetOwnerShell> createState() => _PetOwnerShellState();
}

class _PetOwnerShellState extends State<PetOwnerShell> {
  late int _index;
  int _bookingsGeneration = 0;
  int _chatGeneration = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDashboardPage(),
      BookingsPage(key: ValueKey(_bookingsGeneration)),
      ChatPage(key: ValueKey(_chatGeneration)),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            if (i == 1 && _index != 1) _bookingsGeneration++;
            if (i == 2 && _index != 2) _chatGeneration++;
            _index = i;
          });
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.book_outlined), label: 'Book'),
          NavigationDestination(
              icon: _UnreadChatIcon(icon: Icons.chat_bubble_outline),
              label: 'Chat'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _UnreadChatIcon extends StatelessWidget {
  final IconData icon;

  const _UnreadChatIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BooStreamChatService.instance.connectFromStoredSession(),
      builder: (context, snapshot) {
        final connected = snapshot.data == true;
        final child = Icon(icon);
        if (!connected) return child;
        return StreamBuilder<int>(
          stream:
              BooStreamChatService.instance.client.state.totalUnreadCountStream,
          initialData:
              BooStreamChatService.instance.client.state.totalUnreadCount,
          builder: (context, unreadSnapshot) {
            final unread = unreadSnapshot.data ?? 0;
            if (unread <= 0) return child;
            return Badge(
              label: Text(unread > 9 ? '9+' : '$unread'),
              backgroundColor: const Color(0xFFF68B1F),
              child: child,
            );
          },
        );
      },
    );
  }
}
