import 'package:boo/services/booking_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OwnerSpendingScreen extends StatefulWidget {
  const OwnerSpendingScreen({super.key});

  @override
  State<OwnerSpendingScreen> createState() => _OwnerSpendingScreenState();
}

class _OwnerSpendingScreenState extends State<OwnerSpendingScreen> {
  static const orange = Color(0xFFF68B1F);
  static const bg = Color(0xFFF6F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = BookingService.instance.getOwnerSpending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('My Spending',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 52, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 12),
                  const Text('Could not load spending data',
                      style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() => _future = BookingService.instance.getOwnerSpending()),
                    child: const Text('Retry',
                        style: TextStyle(color: orange, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          final data = snap.data!;
          final summary = data['summary'] as Map<String, dynamic>? ?? {};
          final byMonth = (data['byMonth'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          final byCategory = (data['byCategory'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          final recentBookings = (data['recentBookings'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          final totalSpent = (summary['totalSpent'] as num?)?.toDouble() ?? 0;
          final completedCount = summary['completedCount'] as int? ?? 0;
          final upcomingCount = summary['upcomingCount'] as int? ?? 0;

          return RefreshIndicator(
            color: orange,
            onRefresh: () async {
              setState(() => _future = BookingService.instance.getOwnerSpending());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Total spent hero card ────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Spent',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        _formatKsh(totalSpent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeroStat(label: 'Completed', value: '$completedCount bookings'),
                          const SizedBox(width: 24),
                          _HeroStat(label: 'Upcoming', value: '$upcomingCount bookings'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Monthly spending chart ───────────────────────────
                if (byMonth.isNotEmpty) ...[
                  const Text('Monthly Spending',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _MonthlyChart(byMonth: byMonth),
                  const SizedBox(height: 20),
                ],

                // ── Category breakdown ───────────────────────────────
                if (byCategory.isNotEmpty) ...[
                  const Text('By Category',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _CategoryBreakdown(
                    byCategory: byCategory,
                    totalSpent: totalSpent,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Recent bookings ──────────────────────────────────
                const Text('Booking History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (recentBookings.isEmpty)
                  _EmptyCard(
                    icon: Icons.receipt_long_outlined,
                    message: 'No completed bookings yet.',
                  )
                else
                  ...recentBookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookingHistoryCard(booking: booking),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _MonthlyChart({required this.byMonth});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final maxVal = byMonth.fold<double>(
        0, (m, r) => (r['total'] as num).toDouble() > m ? (r['total'] as num).toDouble() : m);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= byMonth.length) return const SizedBox();
                  final month = byMonth[i]['month'] as String;
                  final parts = month.split('-');
                  final label = _shortMonth(int.parse(parts[1]));
                  return Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF)));
                },
                reservedSize: 20,
              ),
            ),
          ),
          barGroups: byMonth.asMap().entries.map((e) {
            final total = (e.value['total'] as num).toDouble();
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: orange,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _shortMonth(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> byCategory;
  final double totalSpent;
  const _CategoryBreakdown(
      {required this.byCategory, required this.totalSpent});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children: byCategory.map((cat) {
          final label = _catLabel(cat['category'] as String? ?? '');
          final amount = (cat['total'] as num).toDouble();
          final pct = totalSpent > 0 ? (amount / totalSpent).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(_formatKsh(amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: orange,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: const AlwaysStoppedAnimation<Color>(orange),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _catLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'grooming':
        return 'Grooming';
      case 'boarding':
        return 'Boarding';
      case 'sitting':
        return 'Pet Sitting';
      case 'veterinary':
        return 'Veterinary';
      case 'training':
        return 'Training';
      default:
        return 'Other';
    }
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingHistoryCard({required this.booking});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final price = (booking['price'] as num?)?.toDouble() ?? 0;
    final status = booking['status'] as String? ?? '';
    final date = _parseDate(booking['date']);
    final isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? orange.withValues(alpha: 0.10)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.schedule_rounded,
              color: isCompleted ? orange : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['service'] as String? ?? 'Service',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  booking['provider'] as String? ?? '',
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 12),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel(date),
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatKsh(price),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: orange,
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  static String _dateLabel(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade600;
      case 'accepted':
        return const Color(0xFFF68B1F);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'accepted':
        return 'Upcoming';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

String _formatKsh(double amount) {
  final p = amount.toInt();
  if (p >= 1000) {
    return 'KSh ${p ~/ 1000},${(p % 1000).toString().padLeft(3, '0')}';
  }
  return 'KSh $p';
}
