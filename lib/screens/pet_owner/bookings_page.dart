import 'package:boo/models/provider_models.dart';
import 'package:boo/services/booking_service.dart';
import 'package:flutter/material.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<BookingRecord> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final bookings = await BookingService.instance.getBookings();
      if (mounted) setState(() { _bookings = bookings; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load bookings'; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings
        .where((b) =>
            b.status == BookingStatus.upcoming ||
            b.status == BookingStatus.pendingReschedule ||
            b.status == BookingStatus.reviewPending)
        .toList();
    final past = _bookings
        .where((b) =>
            b.status == BookingStatus.completed ||
            b.status == BookingStatus.cancelled)
        .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Bookings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: _loadBookings,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tab,
            labelColor: const Color(0xFFF68B1F),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFFF68B1F),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF68B1F)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: Color(0xFF9CA3AF))),
                            const SizedBox(height: 12),
                            TextButton(onPressed: _loadBookings, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _BookingList(bookings: upcoming, emptyLabel: 'No upcoming bookings'),
                          _BookingList(bookings: past, emptyLabel: 'No past bookings'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingRecord> bookings;
  final String emptyLabel;

  const _BookingList({required this.bookings, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(emptyLabel,
            style: const TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRecord booking;
  const _BookingCard({required this.booking});

  static const orange = Color(0xFFF68B1F);

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.upcoming:
        return const Color(0xFF10B981);
      case BookingStatus.completed:
        return const Color(0xFF6366F1);
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
      case BookingStatus.pendingReschedule:
        return const Color(0xFFF59E0B);
      case BookingStatus.reviewPending:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.pendingReschedule:
        return 'Reschedule Pending';
      case BookingStatus.reviewPending:
        return 'Under Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  booking.providerImageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.pets, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(booking.serviceName,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(booking.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(booking.date)}  ·  ${booking.time}',
                style: const TextStyle(
                    color: Color(0xFF374151), fontSize: 13),
              ),
              const Spacer(),
              Text(booking.priceLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: orange,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (booking.status == BookingStatus.upcoming) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Manage',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ] else
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
