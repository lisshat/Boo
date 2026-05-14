import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.stats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Welcome back. Here's what's happening at Boo Pet Care today.",
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(label: 'Total Users', value: _v(stats, ['users', 'total']), icon: Icons.people_outline),
                _MetricCard(label: 'Verified Providers', value: _v(stats, ['verification', 'approved']), icon: Icons.verified_outlined),
                _MetricCard(label: 'Pending Reviews', value: _v(stats, ['verification', 'pending']), icon: Icons.rate_review_outlined),
                _MetricCard(label: 'Active Bookings', value: _v(stats, ['bookings', 'accepted']), icon: Icons.calendar_today_outlined),
                _MetricCard(label: 'Total Reviews', value: _v(stats, ['reviews', 'total']), icon: Icons.star_outline),
                _MetricCard(label: 'Flagged Users', value: '${stats?['flaggedUsers'] ?? 0}', icon: Icons.warning_amber_rounded, danger: true),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _BookingsStatusCard(stats: stats)),
                const SizedBox(width: 18),
                Expanded(child: _RecentActivityCard()),
              ],
            ),
          ],
        );
      },
    );
  }

  String _v(Map<String, dynamic>? data, List<String> path) {
    dynamic value = data;
    for (final key in path) {
      if (value is! Map<String, dynamic>) return '0';
      value = value[key];
    }
    return '${value ?? 0}';
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: danger ? AdminColors.danger : AdminColors.orange),
                const Spacer(),
                Text(danger ? 'Alert' : 'Live', style: TextStyle(fontSize: 10, color: danger ? AdminColors.danger : Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _BookingsStatusCard extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _BookingsStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bookings = stats?['bookings'] as Map<String, dynamic>? ?? {};
    final total = (bookings['total'] as num?)?.toDouble() ?? 1;
    final rows = ['pending', 'accepted', 'completed', 'cancelled', 'declined'];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bookings by Status', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          for (final row in rows) ...[
            Row(
              children: [
                SizedBox(width: 90, child: Text(row, style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ((bookings[row] as num?)?.toDouble() ?? 0) / total,
                    color: row == 'completed' ? AdminColors.blue : AdminColors.orange,
                    backgroundColor: const Color(0xFFF4E2D4),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(width: 10),
                Text('${bookings[row] ?? 0}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: FutureBuilder<List<dynamic>>(
        future: AdminService.instance.auditLog(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Latest administrator actions',
                style: TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
              const SizedBox(height: 16),
              for (final row in rows.take(5))
                _RecentActivityRow(row: row as Map<String, dynamic>),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('No recent activity')),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final Map<String, dynamic> row;

  const _RecentActivityRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final admin = row['admin'] as Map<String, dynamic>?;
    final adminName = admin?['full_name']?.toString() ??
        row['admin_name']?.toString() ??
        'Admin';
    final action = row['action']?.toString().replaceAll('_', ' ') ?? 'admin action';
    final targetType = row['target_type']?.toString();
    final performedAt = row['performed_at']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFFFE0C2),
            child: Icon(Icons.manage_accounts_outlined, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  targetType == null ? action : '$action - $targetType',
                  style: const TextStyle(fontSize: 11, color: AdminColors.muted),
                ),
              ],
            ),
          ),
          if (performedAt != null)
            Text(
              _shortTime(performedAt),
              style: const TextStyle(fontSize: 10, color: AdminColors.muted),
            ),
        ],
      ),
    );
  }

  String _shortTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}
