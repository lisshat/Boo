import 'package:flutter/material.dart';

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

  // Stub data — replace with API calls when backend is ready
  // TODO: GET /bookings?providerId=:id&status=pending
  // TODO: GET /bookings?providerId=:id&status=accepted
  // TODO: GET /bookings?providerId=:id&status=completed
  final List<_ProviderBooking> _pending = _demoPending;
  final List<_ProviderBooking> _upcoming = _demoUpcoming;
  final List<_ProviderBooking> _completed = _demoCompleted;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept(_ProviderBooking booking) async {
    // TODO: PATCH /bookings/${booking.id} { status: 'accepted' }
    setState(() {
      _pending.remove(booking);
      _upcoming.insert(0, booking.copyWith(status: _BookingStatus.accepted));
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking accepted'),
        backgroundColor: Color(0xFFF68B1F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _decline(_ProviderBooking booking) async {
    // TODO: PATCH /bookings/${booking.id} { status: 'declined' }
    setState(() => _pending.remove(booking));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking declined'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Bookings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: _orange,
                    unselectedLabelColor: Colors.black45,
                    indicatorColor: _orange,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: [
                      Tab(text: 'Pending${_pending.isNotEmpty ? ' (${_pending.length})' : ''}'),
                      const Tab(text: 'Upcoming'),
                      const Tab(text: 'Completed'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookingList(
                    bookings: _pending,
                    emptyMessage: 'No pending requests',
                    emptySubtext: 'New requests from pet owners will appear here',
                    cardBuilder: (b) => _PendingCard(
                      booking: b,
                      onAccept: () => _accept(b),
                      onDecline: () => _decline(b),
                    ),
                  ),
                  _BookingList(
                    bookings: _upcoming,
                    emptyMessage: 'No upcoming bookings',
                    emptySubtext: 'Accepted bookings will appear here',
                    cardBuilder: (b) => _BookingCard(booking: b),
                  ),
                  _BookingList(
                    bookings: _completed,
                    emptyMessage: 'No completed bookings yet',
                    emptySubtext: 'Your booking history will appear here',
                    cardBuilder: (b) => _BookingCard(booking: b, muted: true),
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

// ── Data model ────────────────────────────────────────────────────────────────

enum _BookingStatus { pending, accepted, completed }

class _ProviderBooking {
  final String id;
  final String ownerName;
  final String petName;
  final String petType;
  final String serviceName;
  final String priceLabel;
  final DateTime date;
  final String time;
  final _BookingStatus status;

  const _ProviderBooking({
    required this.id,
    required this.ownerName,
    required this.petName,
    required this.petType,
    required this.serviceName,
    required this.priceLabel,
    required this.date,
    required this.time,
    required this.status,
  });

  _ProviderBooking copyWith({_BookingStatus? status}) {
    return _ProviderBooking(
      id: id,
      ownerName: ownerName,
      petName: petName,
      petType: petType,
      serviceName: serviceName,
      priceLabel: priceLabel,
      date: date,
      time: time,
      status: status ?? this.status,
    );
  }
}

// ── Stub data ─────────────────────────────────────────────────────────────────

final _demoPending = <_ProviderBooking>[
  _ProviderBooking(
    id: 'b1',
    ownerName: 'Amina Osei',
    petName: 'Biscuit',
    petType: 'Dog',
    serviceName: 'Full Puppy Groom',
    priceLabel: 'KSh 1,500',
    date: DateTime.now().add(const Duration(days: 2)),
    time: '10:00 AM',
    status: _BookingStatus.pending,
  ),
  _ProviderBooking(
    id: 'b2',
    ownerName: 'Kevin Mwangi',
    petName: 'Luna',
    petType: 'Cat',
    serviceName: 'Bath & Dry',
    priceLabel: 'KSh 800',
    date: DateTime.now().add(const Duration(days: 3)),
    time: '2:00 PM',
    status: _BookingStatus.pending,
  ),
];

final _demoUpcoming = <_ProviderBooking>[
  _ProviderBooking(
    id: 'b3',
    ownerName: 'Cynthia Njoroge',
    petName: 'Max',
    petType: 'Dog',
    serviceName: 'Overnight Boarding',
    priceLabel: 'KSh 2,000',
    date: DateTime.now().add(const Duration(days: 1)),
    time: '9:00 AM',
    status: _BookingStatus.accepted,
  ),
];

final _demoCompleted = <_ProviderBooking>[
  _ProviderBooking(
    id: 'b4',
    ownerName: 'David Kariuki',
    petName: 'Sasha',
    petType: 'Dog',
    serviceName: 'Full Puppy Groom',
    priceLabel: 'KSh 1,500',
    date: DateTime.now().subtract(const Duration(days: 3)),
    time: '11:00 AM',
    status: _BookingStatus.completed,
  ),
];

// ── Widgets ───────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<_ProviderBooking> bookings;
  final String emptyMessage;
  final String emptySubtext;
  final Widget Function(_ProviderBooking) cardBuilder;

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
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              emptySubtext,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
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
  final _ProviderBooking booking;
  final Widget? actions;
  final bool muted;

  const _BookingCardBase({
    required this.booking,
    this.actions,
    this.muted = false,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF68B1F).withValues(alpha: 0.12),
                child: Text(
                  booking.ownerName.isNotEmpty ? booking.ownerName[0] : '?',
                  style: const TextStyle(
                    color: Color(0xFFF68B1F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.ownerName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      '${booking.petName} · ${booking.petType}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                booking.priceLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFF68B1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.content_cut_outlined, size: 15, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(booking.date)} · ${booking.time}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(height: 12),
            actions!,
          ],
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final _ProviderBooking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingCard({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final _ProviderBooking booking;
  final bool muted;

  const _BookingCard({required this.booking, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return _BookingCardBase(booking: booking, muted: muted);
  }
}
