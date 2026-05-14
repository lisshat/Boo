import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:boo/services/report_pdf_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'User\nSummary',
      'Provider\nPerformance',
      'Booking\nActivity',
      'Service\nCatalog',
      'Trust &\nSafety',
    ];
    final pages = [
      const _UserSummaryReport(),
      const _ProviderPerformanceReport(),
      const _BookingActivityReport(),
      const _ServiceCatalogReport(),
      const _TrustSafetyReport(),
    ];

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              'Admin reporting for verification, bookings, catalog, and trust operations.',
              style: TextStyle(color: AdminColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdminCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tabs.length; i++)
                ChoiceChip(
                  selected: _tab == i,
                  label: Text(tabs[i], textAlign: TextAlign.center),
                  onSelected: (_) => setState(() => _tab = i),
                  selectedColor: const Color(0xFFFFE2C5),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        pages[_tab],
      ],
    );
  }
}

class _UserSummaryReport extends StatefulWidget {
  const _UserSummaryReport();

  @override
  State<_UserSummaryReport> createState() => _UserSummaryReportState();
}

class _UserSummaryReportState extends State<_UserSummaryReport> {
  String _role = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => AdminService.instance.userSummary(
        role: _role,
        startDate: _apiDate(_startDate),
        endDate: _apiDate(_endDate),
      );

  void _apply() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _reset() {
    setState(() {
      _role = 'all';
      _startDate = null;
      _endDate = null;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(
          children: [
            _Drop(
              label: 'Role',
              value: _role,
              values: const {
                'all': 'All Roles',
                'owner': 'Owners',
                'provider': 'Providers',
                'admin': 'Admins',
              },
              onChanged: (v) => setState(() => _role = v),
            ),
            _DateButton(
              label: 'Start Date',
              value: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
            _DateButton(
              label: 'End Date',
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            _ApplyResetButtons(onApply: _apply, onReset: _reset),
          ],
        ),
        const SizedBox(height: 16),
        _ReportFuture(
          future: _future,
          builder: (data) {
            final rows = (data['data'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            final tableRows = _userSummaryRows(rows);
            final totalUsers = tableRows.fold<int>(
                0, (sum, row) => sum + _toInt(row['total']));
            final totalOwners = _toInt(tableRows
                .where((row) => row['role'] == 'owner')
                .fold<int>(0, (sum, row) => sum + _toInt(row['total'])));
            final totalProviders = _toInt(tableRows
                .where((row) => row['role'] == 'provider')
                .fold<int>(0, (sum, row) => sum + _toInt(row['total'])));
            final bannedUsers = tableRows.fold<int>(
                0, (sum, row) => sum + _toInt(row['banned']));
            final columns = [
              'Role',
              'Total',
              'Active',
              'Banned',
              'New This Month',
            ];
            final exportRows = tableRows
                .map((row) => [
                      _title(row['role']),
                      '${row['total']}',
                      '${row['active']}',
                      '${row['banned']}',
                      '${row['newThisMonth']}',
                    ])
                .toList();

            return Column(
              children: [
                _KpiRow(cards: [
                  _KpiData('Total Users', '$totalUsers'),
                  _KpiData('Total Owners', '$totalOwners'),
                  _KpiData('Total Providers', '$totalProviders'),
                  _KpiData('Banned Users', '$bannedUsers'),
                ]),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Users by Role',
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          value: totalOwners.toDouble(),
                          title: 'Owners',
                          color: AdminColors.orange,
                          radius: 72,
                        ),
                        PieChartSectionData(
                          value: totalProviders.toDouble(),
                          title: 'Providers',
                          color: Colors.green.shade600,
                          radius: 72,
                        ),
                        PieChartSectionData(
                          value: tableRows
                              .where((row) => row['role'] == 'admin')
                              .fold<int>(
                                  0, (sum, row) => sum + _toInt(row['total']))
                              .toDouble(),
                          title: 'Admins',
                          color: AdminColors.blue,
                          radius: 72,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ReportTable(
                  columns: columns,
                  rows: exportRows,
                  numericColumns: const {1, 2, 3, 4},
                ),
                const SizedBox(height: 16),
                _ExportRow(
                  onPdf: () => ReportPdfService.exportToPdf(
                    reportTitle: 'User Summary Report',
                    columns: columns,
                    rows: exportRows,
                    appliedFilters:
                        'Role: ${_roleLabel(_role)} | Date: ${_rangeLabel(_startDate, _endDate)}',
                    summaryData: {
                      'Total Users': totalUsers,
                      'Owners': totalOwners,
                      'Providers': totalProviders,
                      'Banned': bannedUsers,
                    },
                  ),
                  onCsv: () => ReportPdfService.exportToCsv(
                    reportTitle: 'User Summary Report',
                    columns: columns,
                    rows: exportRows,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProviderPerformanceReport extends StatefulWidget {
  const _ProviderPerformanceReport();

  @override
  State<_ProviderPerformanceReport> createState() =>
      _ProviderPerformanceReportState();
}

class _ProviderPerformanceReportState
    extends State<_ProviderPerformanceReport> {
  String _verified = 'all';
  String _category = 'all';
  String _minRating = '4.0';
  String _sortBy = 'rating';
  late final TextEditingController _minRatingCtrl;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _minRatingCtrl = TextEditingController(text: _minRating);
    _future = _load();
  }

  @override
  void dispose() {
    _minRatingCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() =>
      AdminService.instance.providerPerformance(
        isVerified: _verified,
        category: _category,
        minRating: _minRating,
        sortBy: _sortBy,
      );

  void _apply() {
    _minRating =
        _minRatingCtrl.text.trim().isEmpty ? '0' : _minRatingCtrl.text.trim();
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _reset() {
    setState(() {
      _verified = 'all';
      _category = 'all';
      _minRating = '4.0';
      _sortBy = 'rating';
      _minRatingCtrl.text = _minRating;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(
          children: [
            _Drop(
              label: 'Verification Status',
              value: _verified,
              values: const {
                'all': 'All Statuses',
                'true': 'Verified',
                'false': 'Unverified',
              },
              onChanged: (v) => setState(() => _verified = v),
            ),
            _Drop(
              label: 'Category',
              value: _category,
              values: _categoryOptions,
              onChanged: (v) => setState(() => _category = v),
            ),
            SizedBox(
              width: 130,
              child: TextField(
                controller: _minRatingCtrl,
                decoration: const InputDecoration(
                  labelText: 'Min Rating',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            _Drop(
              label: 'Sort By',
              value: _sortBy,
              values: const {
                'rating': 'Highest Rating',
                'bookings': 'Bookings',
                'reviews': 'Reviews',
              },
              onChanged: (v) => setState(() => _sortBy = v),
            ),
            _ApplyResetButtons(onApply: _apply, onReset: _reset),
          ],
        ),
        const SizedBox(height: 16),
        _ReportFuture(
          future: _future,
          builder: (data) {
            final summary = data['summary'] as Map<String, dynamic>? ?? {};
            final rows = (data['data'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            final columns = [
              'Provider',
              'Category',
              'Verified',
              'Rating',
              'Bookings',
              'Completion Rate',
            ];
            final exportRows = rows
                .map((row) => [
                      row['business_name']?.toString() ?? '',
                      _title(row['category']),
                      row['is_verified'] == true ? 'Yes' : 'No',
                      '${_toDouble(row['average_rating']).toStringAsFixed(1)}',
                      '${_toInt(row['total_bookings'])}',
                      '${_toDouble(row['completion_rate']).toStringAsFixed(1)}%',
                    ])
                .toList();
            final verified = _toInt(summary['verified']);
            final totalProviders = _toInt(summary['totalProviders']);
            final avgRating = rows.isEmpty
                ? 0.0
                : rows.fold<double>(
                      0,
                      (sum, row) => sum + _toDouble(row['average_rating']),
                    ) /
                    rows.length;

            return Column(
              children: [
                _KpiRow(cards: [
                  _KpiData('Providers', '$totalProviders'),
                  _KpiData(
                    'Priority Verification',
                    '${summary['recommendedForVerification'] ?? 0}',
                  ),
                  _KpiData('Verified', '$verified'),
                  _KpiData('Unverified', '${summary['unverified'] ?? 0}'),
                ]),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Bookings by Provider',
                  child: _BarChart(
                    labels: rows
                        .take(8)
                        .map((row) => _shortLabel(row['business_name']))
                        .toList(),
                    values: rows
                        .take(8)
                        .map((row) => _toDouble(row['total_bookings']))
                        .toList(),
                    colors: List<Color>.filled(8, AdminColors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                _ReportTable(
                  columns: columns,
                  rows: exportRows,
                  numericColumns: const {3, 4, 5},
                ),
                const SizedBox(height: 16),
                _ExportRow(
                  onPdf: () => ReportPdfService.exportToPdf(
                    reportTitle: 'Provider Performance Report',
                    columns: columns,
                    rows: exportRows,
                    appliedFilters:
                        'Status: ${_verifiedLabel(_verified)} | Category: ${_categoryLabel(_category)} | Min Rating: $_minRating | Sort: $_sortBy',
                    summaryData: {
                      'Total Providers': totalProviders,
                      'Verified': verified,
                      'Avg Rating': avgRating.round(),
                    },
                  ),
                  onCsv: () => ReportPdfService.exportToCsv(
                    reportTitle: 'Provider Performance Report',
                    columns: columns,
                    rows: exportRows,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BookingActivityReport extends StatefulWidget {
  const _BookingActivityReport();

  @override
  State<_BookingActivityReport> createState() => _BookingActivityReportState();
}

class _BookingActivityReportState extends State<_BookingActivityReport> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'all';
  String _groupBy = 'week';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => AdminService.instance.bookingActivity(
        groupBy: _groupBy,
        status: _status,
        startDate: _apiDate(_startDate),
        endDate: _apiDate(_endDate),
      );

  void _apply() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _status = 'all';
      _groupBy = 'week';
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(
          children: [
            _DateButton(
              label: 'Start Date',
              value: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
            _DateButton(
              label: 'End Date',
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            _Drop(
              label: 'Status',
              value: _status,
              values: const {
                'all': 'All Statuses',
                'pending': 'Pending',
                'accepted': 'Accepted',
                'completed': 'Completed',
                'cancelled': 'Cancelled',
                'declined': 'Declined',
              },
              onChanged: (v) => setState(() => _status = v),
            ),
            _Drop(
              label: 'Group By',
              value: _groupBy,
              values: const {'week': 'Week', 'month': 'Month'},
              onChanged: (v) => setState(() => _groupBy = v),
            ),
            _ApplyResetButtons(onApply: _apply, onReset: _reset),
          ],
        ),
        const SizedBox(height: 16),
        _ReportFuture(
          future: _future,
          builder: (data) {
            final summary = data['summary'] as Map<String, dynamic>? ?? {};
            final rows = (data['data'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            final total = _toInt(summary['total']);
            final completed = _toInt(summary['completed']);
            final cancelled = _toInt(summary['cancelled']);
            final completionRate =
                total == 0 ? 0 : ((completed / total) * 100).round();
            final columns = [
              'Period',
              'Total',
              'Completed',
              'Cancelled',
              'Declined',
              'Completion Rate %',
              'Revenue Potential (KSh)',
            ];
            final exportRows = rows
                .map((row) => [
                      _periodLabel(row['period'], _groupBy),
                      '${row['total'] ?? 0}',
                      '${row['completed'] ?? 0}',
                      '${row['cancelled'] ?? 0}',
                      '${row['declined'] ?? 0}',
                      '${_completionRate(row)}%',
                      _money(row['revenue_potential']),
                    ])
                .toList();

            return Column(
              children: [
                _KpiRow(cards: [
                  _KpiData('Total Bookings', '$total'),
                  _KpiData('Completed', '$completed'),
                  _KpiData('Cancelled', '$cancelled'),
                  _KpiData('Completion Rate', '$completionRate%'),
                ]),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Booking Outcomes by Period',
                  child: _GroupedBarChart(rows: rows),
                ),
                const SizedBox(height: 16),
                _ReportTable(
                  columns: columns,
                  rows: exportRows,
                  numericColumns: const {1, 2, 3, 4, 5, 6},
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '* Revenue potential is indicative only. Boo does not process payments.',
                    style: TextStyle(fontSize: 12, color: AdminColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                _ExportRow(
                  onPdf: () => ReportPdfService.exportToPdf(
                    reportTitle: 'Booking Activity Report',
                    columns: columns,
                    rows: exportRows,
                    appliedFilters:
                        'Status: ${_title(_status)} | Group By: ${_title(_groupBy)} | Date: ${_rangeLabel(_startDate, _endDate)}',
                    summaryData: {
                      'Total': total,
                      'Completed': completed,
                      'Cancelled': cancelled,
                      'Completion %': completionRate,
                    },
                  ),
                  onCsv: () => ReportPdfService.exportToCsv(
                    reportTitle: 'Booking Activity Report',
                    columns: columns,
                    rows: exportRows,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCatalogReport extends StatefulWidget {
  const _ServiceCatalogReport();

  @override
  State<_ServiceCatalogReport> createState() => _ServiceCatalogReportState();
}

class _ServiceCatalogReportState extends State<_ServiceCatalogReport> {
  String _category = 'all';
  String _active = 'all';
  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _minPriceCtrl = TextEditingController();
    _maxPriceCtrl = TextEditingController();
    _future = _load();
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() => AdminService.instance.serviceCatalog(
        category: _category,
        isActive: _active == 'all' ? null : _active == 'active',
        minPrice: _minPriceCtrl.text.trim(),
        maxPrice: _maxPriceCtrl.text.trim(),
      );

  void _apply() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _reset() {
    setState(() {
      _category = 'all';
      _active = 'all';
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(
          children: [
            _Drop(
              label: 'Category',
              value: _category,
              values: _categoryOptions,
              onChanged: (v) => setState(() => _category = v),
            ),
            _Drop(
              label: 'Status',
              value: _active,
              values: const {
                'all': 'All Services',
                'active': 'Active',
                'inactive': 'Inactive',
              },
              onChanged: (v) => setState(() => _active = v),
            ),
            _NumberInput(controller: _minPriceCtrl, label: 'Min Price'),
            _NumberInput(controller: _maxPriceCtrl, label: 'Max Price'),
            _ApplyResetButtons(onApply: _apply, onReset: _reset),
          ],
        ),
        const SizedBox(height: 16),
        _ReportFuture(
          future: _future,
          builder: (data) {
            final rows = (data['data'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            final categoryRows = _serviceCategoryRows(rows);
            final totalServices = rows.length;
            final activeServices =
                rows.where((row) => row['is_active'] == true).length;
            final categoriesCount = categoryRows.length;
            final avgPrice = rows.isEmpty
                ? 0
                : (rows.fold<double>(
                          0,
                          (sum, row) => sum + _toDouble(row['price']),
                        ) /
                        rows.length)
                    .round();
            final columns = [
              'Category',
              'Total Services',
              'Active',
              'Avg Price (KSh)',
              'Min Price',
              'Max Price',
              'Providers Offering',
            ];
            final exportRows = categoryRows
                .map((row) => [
                      _title(row.category),
                      '${row.total}',
                      '${row.active}',
                      _money(row.avgPrice),
                      _money(row.minPrice),
                      _money(row.maxPrice),
                      '${row.providers}',
                    ])
                .toList();

            return Column(
              children: [
                _KpiRow(cards: [
                  _KpiData('Total Services', '$totalServices'),
                  _KpiData('Active Services', '$activeServices'),
                  _KpiData('Categories Count', '$categoriesCount'),
                  _KpiData('Avg Price (KSh)', _money(avgPrice)),
                ]),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Services by Category',
                  child: _BarChart(
                    labels: categoryRows
                        .map((row) => _shortLabel(_title(row.category)))
                        .toList(),
                    values: categoryRows
                        .map((row) => row.total.toDouble())
                        .toList(),
                    colors: List<Color>.filled(
                        categoryRows.length, AdminColors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                _ReportTable(
                  columns: columns,
                  rows: exportRows,
                  numericColumns: const {1, 2, 3, 4, 5, 6},
                ),
                const SizedBox(height: 16),
                _ExportRow(
                  onPdf: () => ReportPdfService.exportToPdf(
                    reportTitle: 'Service Catalog Report',
                    columns: columns,
                    rows: exportRows,
                    appliedFilters:
                        'Category: ${_categoryLabel(_category)} | Status: ${_title(_active)} | Price: ${_minPriceCtrl.text.isEmpty ? 'Any' : _minPriceCtrl.text} - ${_maxPriceCtrl.text.isEmpty ? 'Any' : _maxPriceCtrl.text}',
                    summaryData: {
                      'Total Services': totalServices,
                      'Active': activeServices,
                      'Categories': categoriesCount,
                      'Avg Price': avgPrice,
                    },
                  ),
                  onCsv: () => ReportPdfService.exportToCsv(
                    reportTitle: 'Service Catalog Report',
                    columns: columns,
                    rows: exportRows,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TrustSafetyReport extends StatefulWidget {
  const _TrustSafetyReport();

  @override
  State<_TrustSafetyReport> createState() => _TrustSafetyReportState();
}

class _TrustSafetyReportState extends State<_TrustSafetyReport> {
  double _minCancellations = 3;
  DateTime? _startDate;
  DateTime? _endDate;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => AdminService.instance.trustSafety(
        minCancellations: _minCancellations.round().toString(),
        startDate: _apiDate(_startDate),
        endDate: _apiDate(_endDate),
      );

  void _apply() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _reset() {
    setState(() {
      _minCancellations = 3;
      _startDate = null;
      _endDate = null;
      _future = _load();
    });
  }

  Future<void> _warn(Map<String, dynamic> row) async {
    try {
      await AdminService.instance.warnUser(row['owner_id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Warning sent to ${row['full_name']}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send warning'),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  Future<void> _ban(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban user?'),
        content: Text(
          'This will suspend ${row['full_name']} and notify them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.danger,
              side: const BorderSide(color: AdminColors.danger),
            ),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AdminService.instance.setBanned(row['owner_id'].toString(), true);
      _apply();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not ban user'),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  Future<void> _viewHistory(Map<String, dynamic> row) async {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${row['full_name']} booking history'),
        content: SizedBox(
          width: 720,
          child: FutureBuilder<List<dynamic>>(
            future: AdminService.instance
                .userBookingHistory(row['owner_id'].toString()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final bookings = snapshot.data ?? const [];
              if (bookings.isEmpty) {
                return const Text('No booking history found.');
              }
              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Service')),
                    DataColumn(label: Text('Provider')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: bookings.map((raw) {
                    final item = raw as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(_date(item['created_at']))),
                      DataCell(Text(
                          item['service']?['service_name']?.toString() ?? '')),
                      DataCell(Text(
                          item['provider']?['business_name']?.toString() ??
                              '')),
                      DataCell(Text(_title(item['status']))),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(
          children: [
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Cancellations: ${_minCancellations.round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminColors.muted,
                    ),
                  ),
                  Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: _minCancellations,
                    activeColor: AdminColors.orange,
                    onChanged: (v) => setState(() => _minCancellations = v),
                  ),
                ],
              ),
            ),
            _DateButton(
              label: 'Start Date',
              value: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
            _DateButton(
              label: 'End Date',
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            _ApplyResetButtons(onApply: _apply, onReset: _reset),
          ],
        ),
        const SizedBox(height: 16),
        _ReportFuture(
          future: _future,
          builder: (data) {
            final summary = data['summary'] as Map<String, dynamic>? ?? {};
            final rows = (data['flaggedOwners'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>();
            final flagged = _toInt(summary['flaggedOwners']);
            final totalCancellations = _toInt(summary['totalCancellations']);
            final mostCategory =
                summary['mostCancelledCategory']?.toString() ?? 'None';
            final avgRate =
                _toDouble(summary['averageCancellationRate']).round();
            final columns = [
              'Owner Name',
              'Total Bookings',
              'Cancellations',
              'Rate %',
              'Status',
            ];
            final exportRows = rows
                .map((row) => [
                      row['full_name']?.toString() ?? '',
                      '${row['total_bookings'] ?? 0}',
                      '${row['cancel_count'] ?? 0}',
                      '${_toDouble(row['cancellation_rate']).toStringAsFixed(1)}%',
                      row['is_banned'] == true ? 'Banned' : 'Active',
                    ])
                .toList();

            return Column(
              children: [
                _KpiRow(cards: [
                  _KpiData('Flagged Users', '$flagged'),
                  _KpiData('Total Cancellations', '$totalCancellations'),
                  _KpiData('Most Cancelled Category', _title(mostCategory)),
                  _KpiData('Avg Cancellation Rate', '$avgRate%'),
                ]),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Flagged Users by Cancellation Count',
                  child: _BarChart(
                    labels: [
                      for (var i = 0; i < rows.take(8).length; i++)
                        'User #${i + 1}',
                    ],
                    values: rows
                        .take(8)
                        .map((row) => _toDouble(row['cancel_count']))
                        .toList(),
                    colors: rows
                        .take(8)
                        .map((row) => row['is_banned'] == true
                            ? AdminColors.danger
                            : AdminColors.orange)
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _TrustSafetyTable(
                  rows: rows,
                  onWarn: _warn,
                  onBan: _ban,
                  onView: _viewHistory,
                ),
                const SizedBox(height: 16),
                _ExportRow(
                  onPdf: () => ReportPdfService.exportToPdf(
                    reportTitle: 'Trust Safety Report',
                    columns: columns,
                    rows: exportRows,
                    appliedFilters:
                        'Min Cancellations: ${_minCancellations.round()} | Date: ${_rangeLabel(_startDate, _endDate)}',
                    summaryData: {
                      'Flagged Users': flagged,
                      'Cancellations': totalCancellations,
                      'Avg Rate %': avgRate,
                    },
                  ),
                  onCsv: () => ReportPdfService.exportToCsv(
                    reportTitle: 'Trust Safety Report',
                    columns: columns,
                    rows: exportRows,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReportFuture extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic> data) builder;

  const _ReportFuture({required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminCard(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return AdminCard(
            child: Text(
              'Could not load report: ${snapshot.error}',
              style: const TextStyle(color: AdminColors.danger),
            ),
          );
        }
        return builder(snapshot.data ?? const {});
      },
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final List<Widget> children;

  const _FiltersCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _ApplyResetButtons extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _ApplyResetButtons({required this.onApply, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Filters'),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _ExportRow extends StatelessWidget {
  final Future<void> Function() onPdf;
  final VoidCallback onCsv;

  const _ExportRow({required this.onPdf, required this.onCsv});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: onPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onCsv,
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;

  const _KpiData(this.title, this.value);
}

class _KpiRow extends StatelessWidget {
  final List<_KpiData> cards;

  const _KpiRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _Kpi(title: cards[i].title, value: cards[i].value)),
          if (i != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title;
  final String value;

  const _Kpi({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AdminColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          SizedBox(height: 250, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;

  const _BarChart({
    required this.labels,
    required this.values,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const Center(child: Text('No chart data'));
    final maxY = values.fold<double>(0, (max, v) => v > max ? v : max);
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.25,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 38),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: colors.length > i ? colors[i] : AdminColors.orange,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GroupedBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _GroupedBarChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Center(child: Text('No chart data'));
    final visible = rows.take(8).toList();
    final maxY = visible.fold<double>(
      0,
      (max, row) => [
        _toDouble(row['completed']),
        _toDouble(row['cancelled']),
        _toDouble(row['declined']),
      ].fold(max, (innerMax, v) => v > innerMax ? v : innerMax),
    );
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.25,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 38),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= visible.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('P${index + 1}',
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < visible.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: _toDouble(visible[i]['completed']),
                  color: Colors.green.shade600,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: _toDouble(visible[i]['cancelled']),
                  color: AdminColors.orange,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: _toDouble(visible[i]['declined']),
                  color: AdminColors.danger,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatefulWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final Set<int> numericColumns;

  const _ReportTable({
    required this.columns,
    required this.rows,
    this.numericColumns = const {},
  });

  @override
  State<_ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<_ReportTable> {
  int _page = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  static const _pageSize = 10;

  List<List<String>> get _sortedRows {
    final rows = [...widget.rows];
    final sortIndex = _sortColumnIndex;
    if (sortIndex == null) return rows;
    rows.sort((a, b) {
      final left = a[sortIndex];
      final right = b[sortIndex];
      final result = widget.numericColumns.contains(sortIndex)
          ? _numFromText(left).compareTo(_numFromText(right))
          : left.toLowerCase().compareTo(right.toLowerCase());
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  @override
  void didUpdateWidget(covariant _ReportTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sortedRows;
    final start = _page * _pageSize;
    final visible = rows.skip(start).take(_pageSize).toList();
    final maxPage = rows.isEmpty ? 0 : ((rows.length - 1) / _pageSize).floor();

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF2E8)),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                for (var i = 0; i < widget.columns.length; i++)
                  DataColumn(
                    numeric: widget.numericColumns.contains(i),
                    label: Text(widget.columns[i]),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
              ],
              rows: visible.asMap().entries.map((entry) {
                final index = start + entry.key;
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? Colors.white : const Color(0xFFFFFBF7),
                  ),
                  cells:
                      entry.value.map((cell) => DataCell(Text(cell))).toList(),
                );
              }).toList(),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No report data')),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  rows.isEmpty
                      ? '0 rows'
                      : '${start + 1}-${start + visible.length} of ${rows.length}',
                  style: const TextStyle(color: AdminColors.muted),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _page == 0 ? null : () => setState(() => _page--),
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed:
                      _page >= maxPage ? null : () => setState(() => _page++),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustSafetyTable extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final Future<void> Function(Map<String, dynamic> row) onWarn;
  final Future<void> Function(Map<String, dynamic> row) onBan;
  final Future<void> Function(Map<String, dynamic> row) onView;

  const _TrustSafetyTable({
    required this.rows,
    required this.onWarn,
    required this.onBan,
    required this.onView,
  });

  @override
  State<_TrustSafetyTable> createState() => _TrustSafetyTableState();
}

class _TrustSafetyTableState extends State<_TrustSafetyTable> {
  int _page = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  static const _pageSize = 10;

  List<Map<String, dynamic>> get _sortedRows {
    final rows = [...widget.rows];
    final sortIndex = _sortColumnIndex;
    if (sortIndex == null) return rows;
    rows.sort((a, b) {
      final result = switch (sortIndex) {
        0 => (a['full_name']?.toString() ?? '')
            .compareTo(b['full_name']?.toString() ?? ''),
        1 => _toInt(a['total_bookings']).compareTo(_toInt(b['total_bookings'])),
        2 => _toInt(a['cancel_count']).compareTo(_toInt(b['cancel_count'])),
        3 => _toDouble(a['cancellation_rate'])
            .compareTo(_toDouble(b['cancellation_rate'])),
        4 => (a['is_banned'] == true ? 'Banned' : 'Active')
            .compareTo(b['is_banned'] == true ? 'Banned' : 'Active'),
        _ => 0,
      };
      return _sortAscending ? result : -result;
    });
    return rows;
  }

  @override
  void didUpdateWidget(covariant _TrustSafetyTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sortedRows;
    final start = _page * _pageSize;
    final visible = rows.skip(start).take(_pageSize).toList();
    final maxPage = rows.isEmpty ? 0 : ((rows.length - 1) / _pageSize).floor();

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF2E8)),
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                _trustColumn(0, 'Owner Name'),
                _trustColumn(1, 'Total Bookings', numeric: true),
                _trustColumn(2, 'Cancellations', numeric: true),
                _trustColumn(3, 'Rate %', numeric: true),
                _trustColumn(4, 'Status'),
                const DataColumn(label: Text('Actions')),
              ],
              rows: visible.asMap().entries.map((entry) {
                final row = entry.value;
                final isBanned = row['is_banned'] == true;
                final index = start + entry.key;
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? Colors.white : const Color(0xFFFFFBF7),
                  ),
                  cells: [
                    DataCell(Text(row['full_name']?.toString() ?? 'Unknown')),
                    DataCell(Text('${row['total_bookings'] ?? 0}')),
                    DataCell(Text('${row['cancel_count'] ?? 0}')),
                    DataCell(Text(
                        '${_toDouble(row['cancellation_rate']).toStringAsFixed(1)}%')),
                    DataCell(AdminStatusPill(
                      text: isBanned ? 'Banned' : 'Active',
                      color:
                          isBanned ? AdminColors.danger : Colors.green.shade700,
                    )),
                    DataCell(
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => widget.onWarn(row),
                            child: const Text('Warn'),
                          ),
                          OutlinedButton(
                            onPressed:
                                isBanned ? null : () => widget.onBan(row),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.danger,
                              side: const BorderSide(color: AdminColors.danger),
                            ),
                            child: const Text('Ban'),
                          ),
                          IconButton(
                            tooltip: 'View booking history',
                            onPressed: () => widget.onView(row),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No report data')),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  rows.isEmpty
                      ? '0 rows'
                      : '${start + 1}-${start + visible.length} of ${rows.length}',
                  style: const TextStyle(color: AdminColors.muted),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _page == 0 ? null : () => setState(() => _page--),
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed:
                      _page >= maxPage ? null : () => setState(() => _page++),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _trustColumn(int index, String label, {bool numeric = false}) {
    return DataColumn(
      label: Text(label),
      numeric: numeric,
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
    );
  }
}

class _Drop extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  const _Drop({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: values.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        icon: const Icon(Icons.calendar_today_outlined, size: 16),
        label: Text(value == null ? label : _apiDate(value)!),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumberInput({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
        keyboardType: TextInputType.number,
      ),
    );
  }
}

class _ServiceCategoryRow {
  final String category;
  final int total;
  final int active;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final int providers;

  const _ServiceCategoryRow({
    required this.category,
    required this.total,
    required this.active,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.providers,
  });
}

List<Map<String, dynamic>> _userSummaryRows(List<Map<String, dynamic>> rows) {
  final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final grouped = <String, Map<String, dynamic>>{};
  for (final row in rows) {
    final role = row['role']?.toString() ?? 'unknown';
    final target = grouped.putIfAbsent(
      role,
      () => {'role': role, 'total': 0, 'banned': 0, 'newThisMonth': 0},
    );
    target['total'] = _toInt(target['total']) + _toInt(row['total']);
    target['banned'] = _toInt(target['banned']) + _toInt(row['banned']);
    final month = DateTime.tryParse(row['month']?.toString() ?? '');
    if (month != null &&
        month.year == currentMonth.year &&
        month.month == currentMonth.month) {
      target['newThisMonth'] =
          _toInt(target['newThisMonth']) + _toInt(row['total']);
    }
  }
  for (final row in grouped.values) {
    row['active'] = _toInt(row['total']) - _toInt(row['banned']);
  }
  return grouped.values.toList()
    ..sort((a, b) => a['role'].toString().compareTo(b['role'].toString()));
}

List<_ServiceCategoryRow> _serviceCategoryRows(
    List<Map<String, dynamic>> rows) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    final category = row['category']?.toString() ?? 'other';
    grouped.putIfAbsent(category, () => []).add(row);
  }
  return grouped.entries.map((entry) {
    final prices = entry.value.map((row) => _toDouble(row['price'])).toList();
    final providers = entry.value
        .map((row) => row['business_name']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    return _ServiceCategoryRow(
      category: entry.key,
      total: entry.value.length,
      active: entry.value.where((row) => row['is_active'] == true).length,
      avgPrice:
          prices.isEmpty ? 0 : prices.reduce((a, b) => a + b) / prices.length,
      minPrice: prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b),
      maxPrice: prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b),
      providers: providers,
    );
  }).toList()
    ..sort((a, b) => a.category.compareTo(b.category));
}

String? _apiDate(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _rangeLabel(DateTime? start, DateTime? end) {
  return '${_apiDate(start) ?? 'Any'} to ${_apiDate(end) ?? 'Any'}';
}

String _date(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return '';
  return '${parsed.month}/${parsed.day}/${parsed.year}';
}

String _periodLabel(dynamic value, String groupBy) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return value?.toString() ?? '';
  if (groupBy == 'month') return '${parsed.month}/${parsed.year}';
  return 'Week ${_weekOfYear(parsed)}';
}

int _weekOfYear(DateTime date) {
  final firstDay = DateTime(date.year, 1, 1);
  return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
}

String _title(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return 'N/A';
  return text
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _shortLabel(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length <= 10) return text;
  return '${text.substring(0, 9)}…';
}

String _money(dynamic value) {
  final number = _toDouble(value);
  return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2);
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll('%', '') ?? '') ?? 0;
}

double _numFromText(String value) {
  return double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
}

int _completionRate(Map<String, dynamic> row) {
  final total = _toInt(row['total']);
  if (total == 0) return 0;
  return ((_toInt(row['completed']) / total) * 100).round();
}

String _roleLabel(String role) => role == 'all' ? 'All Roles' : _title(role);

String _verifiedLabel(String status) {
  switch (status) {
    case 'true':
      return 'Verified';
    case 'false':
      return 'Unverified';
    default:
      return 'All Statuses';
  }
}

String _categoryLabel(String category) {
  return _categoryOptions[category] ?? _title(category);
}

const _categoryOptions = {
  'all': 'All Categories',
  'veterinary': 'Veterinary',
  'grooming': 'Grooming',
  'boarding': 'Boarding',
  'sitting': 'Pet Sitting',
  'training': 'Training',
  'other': 'Other',
};
