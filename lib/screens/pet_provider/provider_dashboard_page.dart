import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/widgets/notification_bell.dart';

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
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _providerFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = _fetchMe();
    _statsFuture = _fetchStats();
    _providerFuture = _fetchProviderProfile();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    final res = await ApiService.instance.get('/auth/me');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load profile');
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final res = await ApiService.instance.get('/bookings/provider/stats');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load stats');
  }

  Future<Map<String, dynamic>> _fetchProviderProfile() async {
    final res = await ApiService.instance.get('/providers/me');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    return const <String, dynamic>{};
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
              onRefresh: () async => setState(() {
                _meFuture = _fetchMe();
                _statsFuture = _fetchStats();
                _providerFuture = _fetchProviderProfile();
              }),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _Header(greeting: _greeting(), name: name),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _providerFuture,
                    builder: (context, providerSnap) {
                      if (providerSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final status =
                          providerSnap.data?['verificationStatus'] as String?;
                      if (status == 'approved') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _VerificationNudge(
                          onTap: () => widget.onSwitchTab(3),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _statsFuture,
                    builder: (context, statsSnap) {
                      final stats = statsSnap.data;
                      return Column(
                        children: [
                          _StatsRow(stats: stats),
                          const SizedBox(height: 24),
                          _QuickActions(onSwitchTab: widget.onSwitchTab),
                          const SizedBox(height: 28),
                          _UpcomingSection(stats: stats),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerificationNudge extends StatelessWidget {
  final VoidCallback onTap;

  const _VerificationNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF68B1F).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boost Your Bookings!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are currently appearing lower in search results. Complete your ID and Background Check to get the Verified Badge and appear at the top of pet owners\' searches.',
            style:
                TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF7C2D12)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFF68B1F),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Get Verified Now',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's on today",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const NotificationBell(),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _StatsRow({this.stats});

  @override
  Widget build(BuildContext context) {
    final todayCount = stats?['todayCount'] as int? ?? 0;
    final pendingCount = stats?['pendingCount'] as int? ?? 0;
    final totalCompleted = stats?['totalCompleted'] as int? ?? 0;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's jobs",
            value: todayCount.toString(),
            icon: Icons.work_outline_rounded,
            iconColor: const Color(0xFFF68B1F),
            bgColor: const Color(0xFFFFF3E0),
            compact: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: pendingCount.toString(),
            icon: Icons.pending_actions_outlined,
            iconColor: Colors.blue.shade600,
            bgColor: Colors.blue.shade50,
            compact: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Clients served',
            value: totalCompleted.toString(),
            icon: Icons.people_outline_rounded,
            iconColor: Colors.green.shade600,
            bgColor: Colors.green.shade50,
            compact: true,
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
  final bool compact;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 16.0;
    final iconSize = compact ? 32.0 : 38.0;
    final numSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(pad),
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
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: compact ? 16 : 20),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: labelSize, color: Colors.grey.shade500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                onTap: () => onSwitchTab(3),
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

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

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
  final Map<String, dynamic>? stats;
  const _UpcomingSection({this.stats});

  String _formatTime(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final raw = stats?['todayBookings'] as List<dynamic>? ?? [];
    final bookings = raw.cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's schedule",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          _EmptySchedule()
        else
          ...bookings.map((b) {
            final service = b['service'] as Map<String, dynamic>?;
            final owner = b['owner'] as Map<String, dynamic>?;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(b['bookingDatetime'] as String? ?? ''),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF68B1F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?['serviceName'] as String? ?? 'Service',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          owner?['fullName'] as String? ?? 'Owner',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final status = b['status'] as String? ?? '';
                    final isAccepted = status == 'accepted';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAccepted
                            ? Colors.green.shade50
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAccepted ? 'Confirmed' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isAccepted
                              ? Colors.green.shade700
                              : const Color(0xFFF68B1F),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
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
          Icon(Icons.event_available_outlined,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No bookings today',
            style: TextStyle(
                color: Colors.grey.shade400, fontWeight: FontWeight.w500),
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
