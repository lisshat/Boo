import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_provider/provider_chat_page.dart';
import 'package:boo/services/booking_service.dart';
import 'package:boo/services/stream_chat_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ProviderBookingsPage extends StatefulWidget {
  const ProviderBookingsPage({super.key});

  @override
  State<ProviderBookingsPage> createState() => _ProviderBookingsPageState();
}

class _ProviderBookingsPageState extends State<ProviderBookingsPage>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late final TabController _tabController;

  List<ProviderBookingRecord> _all = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await BookingService.instance.getProviderBookings();
      if (mounted)
        setState(() {
          _all = bookings;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Could not load bookings';
          _isLoading = false;
        });
    }
  }

  Future<void> _accept(ProviderBookingRecord booking) async {
    final ok = await BookingService.instance.acceptBooking(booking.id);
    if (!mounted) return;
    if (ok) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking accepted'),
            backgroundColor: _orange,
            duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to accept booking'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _decline(ProviderBookingRecord booking) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _DeclineReasonSheet(),
    );
    if (reason == null || !mounted) return; // User tapped "Go Back"

    final ok = await BookingService.instance
        .declineBooking(booking.id, reason: reason);
    if (!mounted) return;
    if (ok) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking declined'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to decline booking'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        _all.where((b) => b.status == ProviderBookingStatus.pending).toList();
    final upcoming =
        _all.where((b) => b.status == ProviderBookingStatus.accepted).toList();
    final completed = _all
        .where((b) =>
            b.status == ProviderBookingStatus.completed ||
            b.status == ProviderBookingStatus.cancelled ||
            b.status == ProviderBookingStatus.declined ||
            b.status == ProviderBookingStatus.rescheduled)
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Bookings',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _load,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabController,
                    labelColor: _orange,
                    unselectedLabelColor: Colors.black45,
                    indicatorColor: _orange,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: [
                      Tab(
                          text:
                              'Pending${pending.isNotEmpty ? ' (${pending.length})' : ''}'),
                      const Tab(text: 'Upcoming'),
                      const Tab(text: 'Completed'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _orange))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style:
                                      const TextStyle(color: Colors.black45)),
                              TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry',
                                      style: TextStyle(color: _orange))),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _BookingList(
                              bookings: pending,
                              emptyMessage: 'No pending requests',
                              emptySubtext:
                                  'New requests from pet owners will appear here',
                              cardBuilder: (b) => _PendingCard(
                                booking: b,
                                onAccept: () => _accept(b),
                                onDecline: () => _decline(b),
                              ),
                            ),
                            _BookingList(
                              bookings: upcoming,
                              emptyMessage: 'No upcoming bookings',
                              emptySubtext:
                                  'Accepted bookings will appear here',
                              cardBuilder: (b) =>
                                  _BookingCard(booking: b, onComplete: _load),
                            ),
                            _BookingList(
                              bookings: completed,
                              emptyMessage: 'No completed bookings yet',
                              emptySubtext:
                                  'Your booking history will appear here',
                              cardBuilder: (b) =>
                                  _BookingCard(booking: b, muted: true),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<ProviderBookingRecord> bookings;
  final String emptyMessage;
  final String emptySubtext;
  final Widget Function(ProviderBookingRecord) cardBuilder;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptySubtext,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(emptySubtext,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => cardBuilder(bookings[i]),
    );
  }
}

class _BookingCardBase extends StatelessWidget {
  final ProviderBookingRecord booking;
  final Widget? actions;
  final bool muted;

  const _BookingCardBase(
      {required this.booking, this.actions, this.muted = false});

  String _formatDate(DateTime d) {
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
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: muted ? Colors.white.withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color(0xFFF68B1F).withValues(alpha: 0.12),
                child: Text(
                  booking.ownerName.isNotEmpty ? booking.ownerName[0] : '?',
                  style: const TextStyle(
                      color: Color(0xFFF68B1F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(booking.ownerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(booking.priceLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFF68B1F))),
            ],
          ),
          const SizedBox(height: 12),
          if (booking.isRescheduledBooking) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Text('📅', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rescheduled booking — owner changed the time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.content_cut_outlined,
                        size: 15, color: Colors.black45),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(booking.serviceName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500))),
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text('${_formatDate(booking.date)} · ${booking.time}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text('${booking.durationMinutes} mins',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.payments_outlined,
                        size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text('${booking.priceLabel} ${booking.pricingUnit}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (actions != null) ...[const SizedBox(height: 12), actions!],
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final ProviderBookingRecord booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingCard(
      {required this.booking, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return _BookingCardBase(
      booking: booking,
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Decline',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF68B1F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Accept',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final ProviderBookingRecord booking;
  final bool muted;
  final VoidCallback? onComplete;

  const _BookingCard(
      {required this.booking, this.muted = false, this.onComplete});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  static const _orange = Color(0xFFF68B1F);
  bool _completing = false;
  bool _openingChat = false;
  late Timer _timer;

  bool get _canComplete =>
      widget.booking.status == ProviderBookingStatus.accepted &&
      DateTime.now().isAfter(widget.booking.bookingDatetime);

  @override
  void initState() {
    super.initState();
    // Refresh every minute so button appears once booking time passes
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Complete?'),
        content: Text(
            'Confirm that you have completed the service for ${widget.booking.ownerName}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _completing = true);
    final ok = await BookingService.instance.completeBooking(widget.booking.id);
    if (!mounted) return;
    setState(() => _completing = false);
    if (ok) {
      widget.onComplete?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking marked as complete'),
            backgroundColor: _orange,
            duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not complete booking'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _messageOwner() async {
    if (_openingChat) return;
    final ownerId = widget.booking.ownerId;
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messaging is unavailable for this booking.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _openingChat = true);
    try {
      final streamService = BooStreamChatService.instance;
      final connected = await streamService.connectFromStoredSession();
      final providerUserId = streamService.currentUserId;
      if (!connected || providerUserId == null) {
        throw Exception('Chat is unavailable. Please log in again.');
      }

      final channel = await streamService.directMessagingChannel(
        otherUserId: ownerId,
        extraData: {
          'latest_booking_id': widget.booking.id,
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProviderConversationScreen(channel: channel),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BookingCardBase(
      booking: widget.booking,
      muted: widget.muted,
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _openingChat ? null : _messageOwner,
            icon: _openingChat
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text(
              'Message Owner',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: _orange),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_canComplete) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _completing ? null : _markComplete,
              icon: _completing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 16),
              label: const Text(
                'Mark as Complete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Decline Reason Sheet ──────────────────────────────────────────────────────

class _DeclineReasonSheet extends StatefulWidget {
  const _DeclineReasonSheet();

  @override
  State<_DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<_DeclineReasonSheet> {
  static const _orange = Color(0xFFF68B1F);

  static const _presetReasons = [
    'Not available at this time',
    'Service no longer available',
    'Outside my service area',
    'Pet type not supported',
    'Other',
  ];

  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selected == null) return;
    final reason = _selected == 'Other' ? _otherCtrl.text.trim() : _selected!;
    if (reason.isEmpty) return;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you declining?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ..._presetReasons.map((r) => RadioListTile<String>(
                value: r,
                groupValue: _selected,
                activeColor: _orange,
                contentPadding: EdgeInsets.zero,
                title: Text(r, style: const TextStyle(fontSize: 14)),
                onChanged: (v) => setState(() => _selected = v),
              )),
          if (_selected == 'Other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _otherCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Please specify...',
                filled: true,
                fillColor: const Color(0xFFF6F7FB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go Back',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selected != null ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    disabledBackgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline Booking',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
