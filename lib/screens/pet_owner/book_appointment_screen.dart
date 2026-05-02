import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_owner/booking_confirmed_screen.dart';
import 'package:boo/screens/pet_owner/booking_failed_screen.dart';
import 'package:boo/services/booking_service.dart';
import 'package:flutter/material.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ProviderModel provider;
  final ServiceModel service;

  const BookAppointmentScreen({
    super.key,
    required this.provider,
    required this.service,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const orange = Color(0xFFF68B1F);
  static const bg = Color(0xFFF6F7FB);

  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _loading = false;

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _prevMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  String _monthLabel(DateTime dt) {
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${m[dt.month - 1]} ${dt.year}';
  }

  String _shortMonth(DateTime dt) => _monthLabel(dt).split(' ').first.substring(0, 3);

  String _dayName(DateTime dt) {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[dt.weekday - 1];
  }

  List<DateTime?> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final startPad = (first.weekday - 1) % 7;
    final days = List<DateTime?>.filled(startPad, null, growable: true);
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    return days;
  }

  bool _isPast(DateTime dt) {
    final today = DateTime.now();
    return dt.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isSelected(DateTime dt) =>
      _selectedDate != null &&
      dt.year == _selectedDate!.year &&
      dt.month == _selectedDate!.month &&
      dt.day == _selectedDate!.day;

  String _summaryLine() {
    if (_selectedDate == null || _selectedTime == null) return 'Select a date & time';
    return '${_dayName(_selectedDate!)}, ${_selectedDate!.day} ${_shortMonth(_selectedDate!)} · $_selectedTime';
  }

  Future<void> _confirmBooking() async {
    setState(() => _loading = true);

    String? errorMessage;

    try {
      await BookingService.instance.createBooking(
        providerId: widget.provider.id,
        providerName: widget.provider.name,
        serviceTitle: widget.service.title,
        servicePrice: widget.service.price,
        date: _selectedDate!,
        time: _selectedTime!,
      );
    } on BookingException catch (e) {
      errorMessage = e.message;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (errorMessage == null) {
      await BookingConfirmedScreen.show(
        context,
        provider: widget.provider,
        service: widget.service,
        date: _selectedDate!,
        time: _selectedTime!,
      );
    } else {
      await BookingFailedScreen.show(
        context,
        provider: widget.provider,
        service: widget.service,
        reason: errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(_focusedMonth);
    final canBook = _selectedDate != null && _selectedTime != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Book Appointment',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _ProviderMiniHeader(provider: widget.provider),
            const SizedBox(height: 14),
            _ServiceSelectedCard(service: widget.service),
            const SizedBox(height: 18),

            // Calendar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: Column(
                children: [
                  // Month nav
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel(_focusedMonth),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Day headers
                  Row(
                    children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                        .map((d) => Expanded(
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Days grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final dt = days[i];
                      if (dt == null) return const SizedBox();
                      final past = _isPast(dt);
                      final selected = _isSelected(dt);
                      final today = _isToday(dt);
                      return GestureDetector(
                        onTap: past ? null : () => setState(() => _selectedDate = dt),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? orange
                                : today
                                    ? orange.withOpacity(0.12)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${dt.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : past
                                      ? const Color(0xFFD1D5DB)
                                      : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Time slots
            const Text('Available Time',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((t) {
                final sel = _selectedTime == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? orange : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? orange : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _summaryLine(),
                      style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    widget.service.priceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: orange,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (canBook && !_loading) ? _confirmBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('BOOK SERVICE',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderMiniHeader extends StatelessWidget {
  final ProviderModel provider;
  const _ProviderMiniHeader({required this.provider});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              provider.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
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
                Text(provider.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${provider.rating.toStringAsFixed(1)}  ·  ${provider.locationName}',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (provider.isVerified)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('VERIFIED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: orange)),
            ),
        ],
      ),
    );
  }
}

class _ServiceSelectedCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceSelectedCard({required this.service});

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SERVICE SELECTED',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(service.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 2),
                Text(service.subtitle,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(service.priceLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: orange,
                      fontSize: 16)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Change',
                    style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
