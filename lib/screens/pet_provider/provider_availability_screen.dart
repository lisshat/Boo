import 'dart:convert';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  const ProviderAvailabilityScreen({super.key});

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends State<ProviderAvailabilityScreen> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  static const _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  // Index = dayOfWeek (0=Sun ... 6=Sat)
  late List<bool> _available;
  late List<TimeOfDay> _startTimes;
  late List<TimeOfDay> _endTimes;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default: Mon–Fri available 9am–5pm, Sat–Sun closed
    _available = [false, true, true, true, true, true, false];
    _startTimes = List.filled(7, const TimeOfDay(hour: 9, minute: 0));
    _endTimes = List.filled(7, const TimeOfDay(hour: 17, minute: 0));
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get('/providers/me/availability');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          for (final item in list) {
            final day = AvailabilityDay.fromJson(item as Map<String, dynamic>);
            final i = day.dayOfWeek;
            _available[i] = day.isAvailable;
            _startTimes[i] = _parseTime(day.startTime);
            _endTimes[i] = _parseTime(day.endTime);
          }
        }
      }
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay _parseTime(String t) {
    // "09:00:00" or "09:00"
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeForApi(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeDisplay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period.name.toUpperCase()}';
  }

  Future<void> _pickTime(int dayIndex, bool isStart) async {
    final initial = isStart ? _startTimes[dayIndex] : _endTimes[dayIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTimes[dayIndex] = picked;
        // Ensure end is always after start
        if (_toMinutes(picked) >= _toMinutes(_endTimes[dayIndex])) {
          _endTimes[dayIndex] = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      } else {
        if (_toMinutes(picked) > _toMinutes(_startTimes[dayIndex])) {
          _endTimes[dayIndex] = picked;
        }
      }
    });
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final days = List.generate(7, (i) => {
        'dayOfWeek': i,
        'startTime': _formatTimeForApi(_startTimes[i]),
        'endTime': _formatTimeForApi(_endTimes[i]),
        'isAvailable': _available[i],
      });
      final res = await ApiService.instance.put('/providers/me/availability', {'days': days});
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours saved'),
            backgroundColor: _orange,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save working hours'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Working Hours',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Set the days and times you are available for bookings. Owners will only see slots within these hours.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(7, (i) => _DayRow(
                  dayName: _dayNames[i],
                  isAvailable: _available[i],
                  startTime: _formatTimeDisplay(_startTimes[i]),
                  endTime: _formatTimeDisplay(_endTimes[i]),
                  onToggle: (val) => setState(() => _available[i] = val),
                  onTapStart: () => _pickTime(i, true),
                  onTapEnd: () => _pickTime(i, false),
                )),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: _orange.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Working Hours',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String dayName;
  final bool isAvailable;
  final String startTime;
  final String endTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  const _DayRow({
    required this.dayName,
    required this.isAvailable,
    required this.startTime,
    required this.endTime,
    required this.onToggle,
    required this.onTapStart,
    required this.onTapEnd,
  });

  static const _orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isAvailable ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Switch(
                value: isAvailable,
                activeColor: _orange,
                onChanged: onToggle,
              ),
            ],
          ),
          if (isAvailable) ...[
            const Divider(height: 12),
            Row(
              children: [
                const Text('From', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(width: 8),
                _TimePill(time: startTime, onTap: onTapStart),
                const SizedBox(width: 12),
                const Text('To', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(width: 8),
                _TimePill(time: endTime, onTap: onTapEnd),
              ],
            ),
          ] else ...[
            const SizedBox(height: 2),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Closed', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimePill({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
