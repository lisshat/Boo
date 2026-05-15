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
          Expanded(child: _pages[_index],
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

