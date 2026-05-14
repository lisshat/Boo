import 'package:flutter/material.dart';
import 'package:boo/services/stream_chat_service.dart';
import 'provider_dashboard_page.dart';
import 'provider_bookings_page.dart';
import 'provider_chat_page.dart';
import 'provider_profile_page.dart';

class ProviderShell extends StatefulWidget {
  final int initialIndex;
  const ProviderShell({super.key, this.initialIndex = 0});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  late int _index;
  late final List<Widget> _pages;

  // Tab indices: 0=Dashboard, 1=Bookings, 2=Chat, 3=Profile
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = [
      ProviderDashboardPage(onSwitchTab: (i) => setState(() => _index = i)),
      const ProviderBookingsPage(),
      const ProviderChatPage(),
      const ProviderProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: const Color(0xFFF68B1F).withValues(alpha: 0.15),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFF68B1F)),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFFF68B1F)),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: _UnreadChatIcon(icon: Icons.chat_bubble_outline_rounded),
            selectedIcon: _UnreadChatIcon(
                icon: Icons.chat_bubble_rounded, selected: true),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFF68B1F)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _UnreadChatIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _UnreadChatIcon({required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BooStreamChatService.instance.connectFromStoredSession(),
      builder: (context, snapshot) {
        final connected = snapshot.data == true;
        final child = Icon(
          icon,
          color: selected ? const Color(0xFFF68B1F) : null,
        );
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
