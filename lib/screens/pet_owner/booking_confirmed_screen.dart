import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingConfirmedScreen {
  static const orange = Color(0xFFF68B1F);
  static const _calendarChannel = MethodChannel('boo/calendar');

  static String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static DateTime _appointmentStart(DateTime date, String time) {
    final parts = time.trim().split(' ');
    final hm = parts.first.split(':');
    var hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);
    final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _googleCalendarDate(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static Uri _googleCalendarUri({
    required ProviderModel provider,
    required ServiceModel service,
    required DateTime start,
    required DateTime end,
  }) {
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': 'Boo: ${service.title} with ${provider.name}',
      'dates': '${_googleCalendarDate(start)}/${_googleCalendarDate(end)}',
      'details':
          'Boo booking for ${service.title} with ${provider.name}. Keep booking coordination inside Boo.',
      'location': provider.locationName,
    });
  }

  static Future<void> _addToCalendar(
    BuildContext context, {
    required ProviderModel provider,
    required ServiceModel service,
    required DateTime date,
    required String time,
  }) async {
    final start = _appointmentStart(date, time);
    final durationMinutes =
        service.durationMins > 0 ? service.durationMins : 60;
    final end = start.add(Duration(minutes: durationMinutes));
    var opened = false;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        opened = await _calendarChannel.invokeMethod<bool>('insertEvent', {
              'title': 'Boo: ${service.title} with ${provider.name}',
              'description':
                  'Boo booking for ${service.title} with ${provider.name}.',
              'location': provider.locationName,
              'startMillis': start.millisecondsSinceEpoch,
              'endMillis': end.millisecondsSinceEpoch,
            }) ??
            false;
      } catch (_) {
        opened = false;
      }
    }

    if (!opened) {
      opened = await launchUrl(
        _googleCalendarUri(
          provider: provider,
          service: service,
          start: start,
          end: end,
        ),
        mode: LaunchMode.externalApplication,
      );
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a calendar app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> show(
    BuildContext context, {
    required ProviderModel provider,
    required ServiceModel service,
    required DateTime date,
    required String time,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Booking Status',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Provider image with badge
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: Image.network(
                      provider.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.pets, color: Color(0xFF9CA3AF), size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "You're all set! We'll notify you when ${provider.name.split(' ').first} confirms.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280), height: 1.4, fontSize: 13),
                ),
              ),

              const SizedBox(height: 20),

              // Appointment details
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APPOINTMENT DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.content_cut_rounded, value: service.title),
                    const SizedBox(height: 10),
                    _DetailRow(icon: Icons.calendar_today_rounded, value: _formatDate(date)),
                    const SizedBox(height: 10),
                    _DetailRow(icon: Icons.access_time_rounded, value: time),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            provider.imageUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const CircleAvatar(
                              radius: 12,
                              backgroundColor: Color(0xFFF3F4F6),
                              child: Icon(Icons.person, size: 14, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const PetOwnerShell(initialIndex: 1)),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View My Bookings',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _addToCalendar(
                  context,
                  provider: provider,
                  service: service,
                  date: date,
                  time: time,
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Add to Calendar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _DetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }
}
