import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:boo/utils/pricing_utils.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final stats = await AdminService.instance.stats();
    try {
      final bookings = await AdminService.instance.bookings(limit: 1000);
      final rows = bookings['data'] as List<dynamic>? ?? const [];
      final completedValue = rows.fold<double>(0, (sum, raw) {
        final row = raw as Map<String, dynamic>;
        if (row['status']?.toString() != 'completed') return sum;
        final service = row['service'] as Map<String, dynamic>? ?? {};
        final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
        final duration = (service['durationMinutes'] as int?) ??
            (service['duration_minutes'] as int?) ??
            0;
        return sum +
            bookingTotalAmount(
              price: price,
              pricingUnit: (service['pricingUnit'] ?? service['pricing_unit'])
                  ?.toString(),
              durationMinutes: duration,
            );
      });
      return {...stats, 'completedBookingValue': completedValue};
    } catch (_) {
      return stats;
    }
  }

  Future<void> _exportReport(Map<String, dynamic> stats) async {
    setState(() => _exporting = true);
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final bookings = stats['bookings'] as Map<String, dynamic>? ?? {};
      final orange = PdfColor.fromHex('F68B1F');

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Boo Pet Care',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: orange,
                        ),
                      ),
                      pw.Text(
                        'Dashboard Report',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: $dateStr',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(color: orange, thickness: 1.5),
              pw.SizedBox(height: 20),

              // Platform Overview
              pw.Text(
                'Platform Overview',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _pdfHeaderRow(['Metric', 'Value'], orange),
                  _pdfDataRow('Total Users', _v(stats, ['users', 'total'])),
                  _pdfDataRow('Verified Providers',
                      _v(stats, ['verification', 'approved'])),
                  _pdfDataRow('Pending Verifications',
                      _v(stats, ['verification', 'pending'])),
                  _pdfDataRow(
                      'Active Bookings', _v(stats, ['bookings', 'accepted'])),
                  _pdfDataRow('Total Reviews', _v(stats, ['reviews', 'total'])),
                  _pdfDataRow('Flagged Users', '${stats['flaggedUsers'] ?? 0}'),
                ],
              ),
              pw.SizedBox(height: 24),

              // Bookings by Status
              pw.Text(
                'Bookings by Status',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  _pdfHeaderRow(['Status', 'Count'], orange),
                  for (final s in [
                    'pending',
                    'accepted',
                    'completed',
                    'cancelled',
                    'declined'
                  ])
                    _pdfDataRow(
                      s[0].toUpperCase() + s.substring(1),
                      '${bookings[s] ?? 0}',
                    ),
                  _pdfDataRow('Total', '${bookings['total'] ?? 0}'),
                ],
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'Boo Pet Care Platform · support@boo.co.ke',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'boo-report-$dateStr.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.TableRow _pdfHeaderRow(List<String> labels, PdfColor bg) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: labels
          .map(
            (l) => pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(
                l,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.TableRow _pdfDataRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  String _v(Map<String, dynamic>? data, List<String> path) {
    dynamic value = data;
    for (final key in path) {
      if (value is! Map<String, dynamic>) return '0';
      value = value[key];
    }
    return '${value ?? 0}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Welcome back. Here's what's happening at Boo Pet Care today.",
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (stats == null || _exporting)
                      ? null
                      : () => _exportReport(stats),
                  icon: _exporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, size: 16),
                  label: Text(_exporting ? 'Exporting...' : 'Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AdminColors.orange.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(
                    label: 'Total Users',
                    value: _v(stats, ['users', 'total']),
                    icon: Icons.people_outline),
                _MetricCard(
                    label: 'Verified Providers',
                    value: _v(stats, ['verification', 'approved']),
                    icon: Icons.verified_outlined),
                _MetricCard(
                    label: 'Pending Reviews',
                    value: _v(stats, ['verification', 'pending']),
                    icon: Icons.rate_review_outlined),
                _MetricCard(
                    label: 'Active Bookings',
                    value: _v(stats, ['bookings', 'accepted']),
                    icon: Icons.calendar_today_outlined),
                _MetricCard(
                    label: 'Completed Value',
                    value: formatKsh(stats?['completedBookingValue'] ?? 0),
                    icon: Icons.payments_outlined),
                _MetricCard(
                    label: 'Total Reviews',
                    value: _v(stats, ['reviews', 'total']),
                    icon: Icons.star_outline),
                _MetricCard(
                    label: 'Flagged Users',
                    value: '${stats?['flaggedUsers'] ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    danger: true),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _BookingsStatusCard(stats: stats)),
                const SizedBox(width: 18),
                Expanded(child: _RecentActivityCard()),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: danger ? AdminColors.danger : AdminColors.orange),
                const Spacer(),
                Text(danger ? 'Alert' : 'Live',
                    style: TextStyle(
                        fontSize: 10,
                        color: danger ? AdminColors.danger : Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _BookingsStatusCard extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const _BookingsStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bookings = stats?['bookings'] as Map<String, dynamic>? ?? {};
    final total = (bookings['total'] as num?)?.toDouble() ?? 1;
    final rows = ['pending', 'accepted', 'completed', 'cancelled', 'declined'];
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bookings by Status',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          for (final row in rows) ...[
            Row(
              children: [
                SizedBox(
                    width: 90,
                    child: Text(row, style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ((bookings[row] as num?)?.toDouble() ?? 0) / total,
                    color: row == 'completed'
                        ? AdminColors.blue
                        : AdminColors.orange,
                    backgroundColor: const Color(0xFFF4E2D4),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(width: 10),
                Text('${bookings[row] ?? 0}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: FutureBuilder<List<dynamic>>(
        future: AdminService.instance.auditLog(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Latest administrator actions',
                style: TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
              const SizedBox(height: 16),
              for (final row in rows.take(5))
                _RecentActivityRow(row: row as Map<String, dynamic>),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('No recent activity')),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final Map<String, dynamic> row;

  const _RecentActivityRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final admin = row['admin'] as Map<String, dynamic>?;
    final adminName = admin?['full_name']?.toString() ??
        row['admin_name']?.toString() ??
        'Admin';
    final action =
        row['action']?.toString().replaceAll('_', ' ') ?? 'admin action';
    final targetType = row['target_type']?.toString();
    final performedAt = row['performed_at']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFFFE0C2),
            child: Icon(Icons.manage_accounts_outlined, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  targetType == null ? action : '$action - $targetType',
                  style:
                      const TextStyle(fontSize: 11, color: AdminColors.muted),
                ),
              ],
            ),
          ),
          if (performedAt != null)
            Text(
              _shortTime(performedAt),
              style: const TextStyle(fontSize: 10, color: AdminColors.muted),
            ),
        ],
      ),
    );
  }

  String _shortTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}
