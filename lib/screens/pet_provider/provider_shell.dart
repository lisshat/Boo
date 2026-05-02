import 'package:flutter/material.dart';
import 'provider_dashboard_page.dart';
import 'provider_bookings_page.dart';
import 'provider_chat_page.dart';
import 'provider_services_page.dart';
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

  // Tab indices: 0=Dashboard, 1=Bookings, 2=Chat, 3=Services, 4=Profile
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = [
      ProviderDashboardPage(onSwitchTab: (i) => setState(() => _index = i)),
      const ProviderBookingsPage(),
      const ProviderChatPage(),
      const ProviderServicesPage(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFF68B1F)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFFF68B1F)),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFFF68B1F)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon: Icon(Icons.design_services, color: Color(0xFFF68B1F)),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFF68B1F)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
