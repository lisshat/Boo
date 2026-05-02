import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';

class ProviderDashboardPage extends StatefulWidget {
  final void Function(int tabIndex) onSwitchTab;

  const ProviderDashboardPage({super.key, required this.onSwitchTab});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late Future<Map<String, dynamic>> _meFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    final res = await ApiService.instance.get('/auth/me');
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load profile');
  }

  String _firstName(Map<String, dynamic> me) {
    final full = (me['fullName'] as String? ?? '').trim();
    return full.split(' ').first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _meFuture,
          builder: (context, snap) {
            final name = snap.hasData ? _firstName(snap.data!) : '';
            return RefreshIndicator(
              color: _orange,
              onRefresh: () async => setState(() => _meFuture = _fetchMe()),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _Header(greeting: _greeting(), name: name),
                  const SizedBox(height: 24),
                  _StatsRow(),
                  const SizedBox(height: 24),
                  _QuickActions(onSwitchTab: widget.onSwitchTab),
                  const SizedBox(height: 28),
                  _UpcomingSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String name;

  const _Header({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? '$greeting 👋' : '$greeting, $name 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's on today",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.black54),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's jobs",
            // TODO: replace with real count from GET /bookings?date=today
            value: '0',
            icon: Icons.work_outline_rounded,
            iconColor: const Color(0xFFF68B1F),
            bgColor: const Color(0xFFFFF3E0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending requests',
            // TODO: replace with real count from GET /bookings?status=pending
            value: '0',
            icon: Icons.pending_actions_outlined,
            iconColor: Colors.blue.shade600,
            bgColor: Colors.blue.shade50,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final void Function(int) onSwitchTab;

  const _QuickActions({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_today_outlined,
                label: 'View Bookings',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => onSwitchTab(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFFF68B1F)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's schedule",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        // TODO: replace with real bookings from GET /bookings?date=today&status=accepted
        _EmptySchedule(),
      ],
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No bookings today',
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'New requests will appear here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
