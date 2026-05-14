import 'package:boo/screens/admin/admin_bookings_page.dart';
import 'package:boo/screens/admin/admin_dashboard_page.dart';
import 'package:boo/screens/admin/admin_reports_page.dart';
import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/screens/admin/admin_users_page.dart';
import 'package:boo/screens/admin/admin_verifications_page.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  late final _pages = [
    const AdminDashboardPage(),
    const AdminVerificationsPage(),
    const AdminBookingsPage(),
    const AdminUsersPage(),
    const AdminReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Row(
        children: [
          _Sidebar(
            selected: _index,
            onSelected: (i) => setState(() => _index = i),
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _Sidebar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.verified_user_outlined, 'Verifications'),
      (Icons.calendar_today_outlined, 'Bookings'),
      (Icons.people_outline, 'Users'),
      (Icons.analytics_outlined, 'Reports'),
    ];

    return Container(
      width: 220,
      color: const Color(0xFFFFF4EC),
      padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boo Pet Care',
            style: TextStyle(
              color: AdminColors.brown,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text('AdminPortal', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 48),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(i),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected == i ? AdminColors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i].$1,
                        size: 17,
                        color: selected == i ? Colors.white : AdminColors.ink,
                      ),
                      const SizedBox(width: 11),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected == i ? Colors.white : AdminColors.ink,
                          fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          const Divider(color: AdminColors.line),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AdminColors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text('Admin User', style: TextStyle(fontSize: 12)),
            subtitle: const Text('System Manager', style: TextStyle(fontSize: 10)),
            onTap: () async {
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/admin-login', (_) => false);
            },
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.panel,
        border: Border(bottom: BorderSide(color: AdminColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 360,
            height: 34,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bookings, providers, or users...',
                prefixIcon: const Icon(Icons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFFF1E8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          const SizedBox(width: 12),
          const Text('Kenya\nPortal', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 16)),
        ],
      ),
    );
  }
}
