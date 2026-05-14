import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:flutter/material.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  String _status = 'all';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => AdminService.instance.bookings(status: _status);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bookings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('Operational booking activity without customer contact details.', style: TextStyle(color: AdminColors.muted)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                DropdownMenuItem(value: 'declined', child: Text('Declined')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _status = v;
                  _future = _load();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final rows = snapshot.data?['data'] as List<dynamic>? ?? const [];
            return AdminCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF2E8)),
                  columns: const [
                    DataColumn(label: Text('Owner')),
                    DataColumn(label: Text('Provider')),
                    DataColumn(label: Text('Service')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Reason')),
                  ],
                  rows: rows.map((raw) {
                    final row = raw as Map<String, dynamic>;
                    final owner = row['owner'] as Map<String, dynamic>? ?? {};
                    final provider = row['provider'] as Map<String, dynamic>? ?? {};
                    final service = row['service'] as Map<String, dynamic>? ?? {};
                    final status = row['status']?.toString() ?? '';
                    return DataRow(cells: [
                      DataCell(Text(owner['full_name']?.toString() ?? '')),
                      DataCell(Text(provider['business_name']?.toString() ?? '')),
                      DataCell(Text(service['service_name']?.toString() ?? '')),
                      DataCell(Text(_date(row['booking_datetime']))),
                      DataCell(AdminStatusPill(text: status, color: adminStatusColor(status))),
                      DataCell(Text(row['decline_reason']?.toString() ?? '')),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }
}
