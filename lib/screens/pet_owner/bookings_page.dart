import 'package:boo/models/provider_models.dart';
import 'package:boo/services/booking_service.dart';
import 'package:boo/services/reviews_service.dart';
import 'package:boo/screens/pet_owner/leave_review_screen.dart';
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
  Set<String> _reviewedBookingIds = {};
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
      final results = await Future.wait([
        BookingService.instance.getBookings(),
        ReviewsService.instance.getMyReviewedBookingIds(),
      ]);
      if (mounted) {
        setState(() {
          _bookings = results[0] as List<BookingRecord>;
          _reviewedBookingIds = results[1] as Set<String>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load bookings'; _isLoading = false; });
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await BookingService.instance.cancelBooking(bookingId);
      _loadBookings();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel booking'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings.where(_isUpcomingBooking).toList()
      ..sort((a, b) => a.bookingDatetime.compareTo(b.bookingDatetime));
    final past = _bookings.where(_isPastBooking).toList()
      ..sort((a, b) => b.bookingDatetime.compareTo(a.bookingDatetime));

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
                          _BookingList(
                            bookings: upcoming,
                            emptyLabel: 'No upcoming bookings',
                            onCancel: _cancelBooking,
                            onRefresh: _loadBookings,
                            reviewedIds: _reviewedBookingIds,
                            onReviewSubmitted: _loadBookings,
                          ),
                          _BookingList(
                            bookings: past,
                            emptyLabel: 'No past bookings',
                            onCancel: _cancelBooking,
                            onRefresh: _loadBookings,
                            reviewedIds: _reviewedBookingIds,
                            onReviewSubmitted: _loadBookings,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  bool _isUpcomingBooking(BookingRecord booking) {
    if (_isTerminalStatus(booking.status)) return false;
    return booking.bookingDatetime.isAfter(DateTime.now());
  }

  bool _isPastBooking(BookingRecord booking) {
    return !_isUpcomingBooking(booking);
  }

  bool _isTerminalStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.declined:
      case BookingStatus.rescheduled:
      case BookingStatus.reviewPending:
        return true;
      case BookingStatus.pending:
      case BookingStatus.accepted:
      case BookingStatus.upcoming:
      case BookingStatus.pendingReschedule:
        return false;
    }
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingRecord> bookings;
  final String emptyLabel;
  final Future<void> Function(String bookingId) onCancel;
  final VoidCallback onRefresh;
  final Set<String> reviewedIds;
  final VoidCallback onReviewSubmitted;

  const _BookingList({
    required this.bookings,
    required this.emptyLabel,
    required this.onCancel,
    required this.onRefresh,
    required this.reviewedIds,
    required this.onReviewSubmitted,
  });

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
      itemBuilder: (_, i) => _BookingCard(
        booking: bookings[i],
        onCancel: onCancel,
        onRefresh: onRefresh,
        alreadyReviewed: reviewedIds.contains(bookings[i].id),
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final BookingRecord booking;
  final Future<void> Function(String bookingId) onCancel;
  final VoidCallback onRefresh;
  final bool alreadyReviewed;
  final VoidCallback onReviewSubmitted;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onRefresh,
    required this.alreadyReviewed,
    required this.onReviewSubmitted,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _cancelling = false;
  bool _rescheduling = false;

  static const orange = Color(0xFFF68B1F);

  bool get _isStale =>
      _isActiveBookingStatus(widget.booking.status) &&
      widget.booking.bookingDatetime
          .isBefore(DateTime.now());

  bool get _canAct =>
      _isActiveBookingStatus(widget.booking.status) && !_isStale;

  bool _isActiveBookingStatus(BookingStatus status) {
    return status == BookingStatus.pending ||
        status == BookingStatus.accepted ||
        status == BookingStatus.upcoming;
  }

  void _showDeclineDetails(BuildContext context, BookingRecord booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 8),
                const Text('Booking Declined',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Provider', value: booking.providerName),
            const SizedBox(height: 10),
            _DetailRow(label: 'Service', value: booking.serviceName),
            const SizedBox(height: 10),
            _DetailRow(label: 'Date & time', value: '${_formatDate(booking.date)} · ${booking.time}'),
            const SizedBox(height: 10),
            _DetailRow(label: 'Amount', value: booking.priceLabel),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason for declining',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                  const SizedBox(height: 6),
                  Text(
                    booking.declineReason ?? 'The provider did not provide a reason.',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Color _statusColor(BookingStatus s) {
    if (_isStale) return const Color(0xFF9CA3AF);
    switch (s) {
      case BookingStatus.pending:
        return const Color(0xFFF59E0B);
      case BookingStatus.accepted:
        return const Color(0xFF10B981);
      case BookingStatus.upcoming:
        return const Color(0xFF10B981);
      case BookingStatus.completed:
        return const Color(0xFF6366F1);
      case BookingStatus.cancelled:
        return const Color(0xFFEF4444);
      case BookingStatus.declined:
        return const Color(0xFFEF4444);
      case BookingStatus.rescheduled:
        return const Color(0xFF9CA3AF);
      case BookingStatus.pendingReschedule:
        return const Color(0xFFF59E0B);
      case BookingStatus.reviewPending:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(BookingStatus s) {
    if (_isStale) return 'Expired';
    switch (s) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
      case BookingStatus.pendingReschedule:
        return 'Reschedule Pending';
      case BookingStatus.reviewPending:
        return 'Under Review';
    }
  }

  Future<void> _doCancel() async {
    setState(() => _cancelling = true);
    await widget.onCancel(widget.booking.id);
    if (mounted) setState(() => _cancelling = false);
  }

  Future<void> _doReschedule() async {
    // Step 1: pick date
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: orange),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    // Step 2: pick time
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: orange),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final newDatetime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    // Step 3: confirmation sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RescheduleConfirmSheet(
        booking: widget.booking,
        newDatetime: newDatetime,
      ),
    );
    if (confirmed != true || !mounted) return;

    // Step 4: call API
    setState(() => _rescheduling = true);
    try {
      await BookingService.instance
          .rescheduleBooking(widget.booking.id, newDatetime);
      if (!mounted) return;
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Rescheduled! Waiting for the provider to confirm the new time.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final busy = _cancelling || _rescheduling;

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
          if (booking.status == BookingStatus.declined) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This booking was declined',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                  const SizedBox(height: 4),
                  Text(
                    booking.declineReason != null
                        ? 'Reason: ${booking.declineReason}'
                        : 'The provider did not provide a reason.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ── Action buttons ──────────────────────────────────────────
          if (_canAct) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : _doReschedule,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _rescheduling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: orange),
                          )
                        : const Text('Reschedule',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : _doCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _cancelling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFEF4444)),
                          )
                        : const Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == BookingStatus.declined)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDeclineDetails(context, booking),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            )
          else if (booking.status == BookingStatus.completed &&
              !widget.alreadyReviewed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final submitted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeaveReviewScreen(
                        bookingId: booking.id,
                        providerName: booking.providerName,
                        serviceName: booking.serviceName,
                      ),
                    ),
                  );
                  if (submitted == true) widget.onReviewSubmitted();
                },
                icon: const Icon(Icons.star_rounded, size: 15),
                label: const Text('Leave a Review',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
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
    );
  }
}

// ── Reschedule confirmation sheet ─────────────────────────────────────────────

class _RescheduleConfirmSheet extends StatelessWidget {
  final BookingRecord booking;
  final DateTime newDatetime;

  const _RescheduleConfirmSheet(
      {required this.booking, required this.newDatetime});

  String _fmt(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF68B1F).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_repeat_rounded,
                color: Color(0xFFF68B1F), size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reschedule this booking?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'The provider will need to accept the new time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, height: 1.4),
          ),
          const SizedBox(height: 24),
          _TimeRow(
              label: 'Current', datetime: booking.bookingDatetime, fmt: _fmt),
          const SizedBox(height: 10),
          _TimeRow(
              label: 'New',
              datetime: newDatetime,
              fmt: _fmt,
              isNew: true),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF68B1F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Confirm Reschedule',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Go Back',
              style: TextStyle(
                  color: Colors.black45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final DateTime datetime;
  final String Function(DateTime) fmt;
  final bool isNew;

  const _TimeRow({
    required this.label,
    required this.datetime,
    required this.fmt,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(color: Colors.black45, fontSize: 13)),
        ),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isNew
                  ? const Color(0xFFF68B1F).withOpacity(0.08)
                  : const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(10),
              border: isNew
                  ? Border.all(
                      color: const Color(0xFFF68B1F).withOpacity(0.4))
                  : null,
            ),
            child: Text(
              fmt(datetime),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isNew
                    ? const Color(0xFFF68B1F)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
        ),
      ],
    );
  }
}
