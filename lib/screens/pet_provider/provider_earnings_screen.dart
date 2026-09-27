import 'package:boo/services/booking_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProviderEarningsScreen extends StatefulWidget {
  const ProviderEarningsScreen({super.key});

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen> {
  static const orange = Color(0xFFF68B1F);
  static const bg = Color(0xFFF6F7FB);

  late Future<Map<String, dynamic>> _future;
  String? _updatingBookingId;

  @override
  void initState() {
    super.initState();
    _future = BookingService.instance.getProviderEarnings();
  }

  Future<void> _updatePayment({
    required String bookingId,
    required bool received,
    String? paymentMethod,
  }) async {
    if (_updatingBookingId != null) return;
    if (!mounted) return;
    setState(() => _updatingBookingId = bookingId);

    try {
      await BookingService.instance.recordPayment(
        bookingId,
        received: received,
        paymentMethod: paymentMethod,
      );
    } on BookingException catch (error) {
      if (!mounted) return;
      setState(() => _updatingBookingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    try {
      final refreshed = await BookingService.instance.getProviderEarnings(
        allowFallback: false,
      );
      if (!mounted) return;
      setState(() {
        _future = Future.value(refreshed);
        _updatingBookingId = null;
      });
    } on BookingException catch (error) {
      if (!mounted) return;
      setState(() => _updatingBookingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Service Payments',
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
                  const Icon(Icons.savings_outlined,
                      size: 52, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 12),
                  const Text('Could not load earnings data',
                      style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _future =
                        BookingService.instance.getProviderEarnings()),
                    child: const Text('Retry',
                        style: TextStyle(
                            color: orange, fontWeight: FontWeight.w700)),
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
          final recentBookings =
              (data['recentBookings'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

          final totalEarnings =
              (summary['totalEarnings'] as num?)?.toDouble() ?? 0;
          final completedCount = summary['completedCount'] as int? ?? 0;
          final pendingCount = summary['pendingCount'] as int? ?? 0;
          final completedServiceValue =
              (data['completedServiceValue'] as num?)?.toDouble() ??
                  (summary['completedServiceValue'] as num?)?.toDouble() ??
                  0;
          final completedUnrecordedCount =
              (data['completedUnrecordedCount'] as num?)?.toInt() ??
                  (summary['completedUnrecordedCount'] as num?)?.toInt() ??
                  0;

          return RefreshIndicator(
            color: orange,
            onRefresh: () async {
              setState(() =>
                  _future = BookingService.instance.getProviderEarnings());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // â”€â”€ Total earnings hero card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recorded earnings',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        _formatKsh(totalEarnings),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeroStat(
                              label: 'Completed',
                              value: '$completedCount bookings'),
                          const SizedBox(width: 24),
                          _HeroStat(
                              label: 'Upcoming',
                              value: '$pendingCount bookings'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _SupportStat(
                        label: 'Completed service value',
                        value: _formatKsh(completedServiceValue),
                        color: const Color(0xFF374151),
                      ),
                      _SupportStat(
                        label: 'Payments not recorded',
                        value: '$completedUnrecordedCount',
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // â”€â”€ Monthly earnings chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (byMonth.isNotEmpty) ...[
                  const Text('Monthly recorded earnings',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _MonthlyChart(byMonth: byMonth),
                  const SizedBox(height: 20),
                ],

                // â”€â”€ Category breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (byCategory.isNotEmpty) ...[
                  const Text('By Service Category',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _CategoryBreakdown(
                    byCategory: byCategory,
                    total: totalEarnings,
                  ),
                  const SizedBox(height: 20),
                ],
                if (byCategory.isEmpty &&
                    totalEarnings == 0 &&
                    completedCount > 0) ...[
                  const Text('By Service Category',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const _EmptyCard(
                    icon: Icons.payments_outlined,
                    message: 'No recorded payments by category yet.',
                  ),
                  const SizedBox(height: 20),
                ],

                // â”€â”€ Booking history â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                const Text('Booking History',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
                      child: _BookingEarningsCard(
                        booking: booking,
                        updating: _updatingBookingId == booking['id'],
                        onPaymentAction: _updatePayment,
                      ),
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
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ],
    );
  }
}

class _SupportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SupportStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> byMonth;
  const _MonthlyChart({required this.byMonth});

  @override
  Widget build(BuildContext context) {
    final maxVal = byMonth.fold<double>(
        0,
        (m, r) => (r['total'] as num).toDouble() > m
            ? (r['total'] as num).toDouble()
            : m);

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
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= byMonth.length) return const SizedBox();
                  final parts = (byMonth[i]['month'] as String).split('-');
                  return Text(_shortMonth(int.parse(parts[1])),
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
                  color: Colors.green.shade500,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> byCategory;
  final double total;
  const _CategoryBreakdown({required this.byCategory, required this.total});

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
          final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
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
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade600,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.green.shade500),
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

class _BookingEarningsCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool updating;
  final Future<void> Function({
    required String bookingId,
    required bool received,
    String? paymentMethod,
  }) onPaymentAction;

  const _BookingEarningsCard({
    required this.booking,
    required this.updating,
    required this.onPaymentAction,
  });

  @override
  Widget build(BuildContext context) {
    final price = (booking['price'] as num?)?.toDouble() ?? 0;
    final status = booking['status'] as String? ?? '';
    final date =
        DateTime.tryParse(booking['date']?.toString() ?? '')?.toLocal();
    final isCompleted = status == 'completed';
    final paymentStatus =
        booking['paymentStatus']?.toString() ?? 'not_recorded';
    final paymentMethod = booking['paymentMethod']?.toString();
    final recorded = paymentStatus == 'provider_recorded_received';

    Future<void> beginPaymentAction() async {
      final bookingId = booking['id']?.toString().trim() ?? '';
      final validBookingId = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(bookingId);
      if (!validBookingId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This booking reference is unavailable. Please refresh.'),
          ),
        );
        return;
      }
      if (recorded) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Undo payment record?'),
            content: const Text(
                'This removes the booking from recorded earnings. Boo has not verified or processed the payment.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Undo'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await onPaymentAction(bookingId: bookingId, received: false);
        }
        return;
      }
      final method = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'This records an off-platform payment. Boo has not verified or processed it.'),
              ),
              for (final option in const {
                'cash': 'Cash',
                'mpesa': 'M-Pesa',
                'bank_transfer': 'Bank transfer',
                'other': 'Other',
              }.entries)
                ListTile(
                  title: Text(option.value),
                  onTap: () => Navigator.pop(context, option.key),
                ),
            ],
          ),
        ),
      );
      if (method != null) {
        await onPaymentAction(
          bookingId: bookingId,
          received: true,
          paymentMethod: method,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.shade50
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline_rounded
                      : Icons.schedule_rounded,
                  color: isCompleted
                      ? Colors.green.shade600
                      : const Color(0xFF9CA3AF),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking['owner'] as String? ?? '',
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
              const SizedBox(width: 8),
              Text(
                _formatKsh(price),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade600,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (recorded ? Colors.green : const Color(0xFF6B7280))
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isCompleted && recorded
                  ? 'Payment recorded by provider'
                  : isCompleted
                      ? 'Payment not recorded'
                      : _statusLabel(status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    recorded ? Colors.green.shade600 : const Color(0xFF6B7280),
              ),
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 4),
            if (recorded && paymentMethod != null)
              Text(
                'Method: ${paymentMethod.replaceAll('_', ' ')}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: updating ? null : beginPaymentAction,
                icon: updating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF68B1F),
                        ),
                      )
                    : Icon(recorded
                        ? Icons.undo_rounded
                        : Icons.payments_outlined),
                label: Text(
                  updating
                      ? recorded
                          ? 'Updating payment…'
                          : 'Recording payment…'
                      : recorded
                          ? 'Undo payment record'
                          : 'Mark payment received',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: recorded
                      ? const Color(0xFF6B7280)
                      : const Color(0xFFF68B1F),
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _statusLabel(String status) {
    switch (status) {
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
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
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
