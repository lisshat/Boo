import 'package:boo/screens/admin/admin_theme.dart';
import 'package:boo/services/admin_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class AdminVerificationsPage extends StatefulWidget {
  const AdminVerificationsPage({super.key});

  @override
  State<AdminVerificationsPage> createState() => _AdminVerificationsPageState();
}

class _AdminVerificationsPageState extends State<AdminVerificationsPage> {
  String _status = 'all';
  late final TextEditingController _searchCtrl;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() => AdminService.instance.verification(
        status: _status,
        search: _searchCtrl.text,
      );

  void _refresh() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _applyFilters() => _refresh();

  void _resetFilters() {
    _status = 'all';
    _searchCtrl.clear();
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _openDocument(String? fileUrl) async {
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document does not have a file URL'),
          backgroundColor: AdminColors.danger,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document link is invalid'),
          backgroundColor: AdminColors.danger,
        ),
      );
      return;
    }

    if (kIsWeb) {
      html.window.open(fileUrl, '_blank');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open document'),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  Future<void> _review(String docId, String decision) async {
    final notes = decision == 'rejected' ? await _notesDialog() : null;
    if (decision == 'rejected' && notes == null) return;
    await AdminService.instance.reviewVerification(
      docId: docId,
      decision: decision,
      adminNotes: notes,
    );
    _refresh();
  }

  Future<String?> _notesDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showProviderDocuments(Map<String, dynamic> group) {
    final provider = group['provider'] as Map<String, dynamic>? ?? {};
    final documents = (group['documents'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['business_name']?.toString() ??
                              'Provider documents',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Review all submitted verification documents.',
                          style: TextStyle(color: AdminColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final document in documents) ...[
                _DocumentCard(
                  document: document,
                  onView: () => _openDocument(document['file_url']?.toString()),
                  onApprove: document['status'] == 'pending'
                      ? () => _review(document['doc_id'].toString(), 'approved')
                      : null,
                  onReject: document['status'] == 'pending'
                      ? () => _review(document['doc_id'].toString(), 'rejected')
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Verifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              'Review and manage professional credentials for pet care providers.',
              style: TextStyle(color: AdminColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdminCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('verification-status-$_status'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Provider name or email',
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Filters'),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminCard(
                child: SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final rows = snapshot.data ?? const [];
            return AdminCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFFFF2E8)),
                  columns: const [
                    DataColumn(label: Text('Provider')),
                    DataColumn(label: Text('Documents')),
                    DataColumn(label: Text('Latest Upload')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Open')),
                    DataColumn(label: Text('Review')),
                  ],
                  rows: rows.map((raw) {
                    final group = raw as Map<String, dynamic>;
                    final provider =
                        group['provider'] as Map<String, dynamic>? ?? {};
                    final user =
                        provider['user'] as Map<String, dynamic>? ?? {};
                    final documents =
                        (group['documents'] as List<dynamic>? ?? const [])
                            .cast<Map<String, dynamic>>();
                    final firstDocument =
                        documents.isEmpty ? null : documents.first;
                    final status = _groupStatus(documents);

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['business_name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                user['email']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AdminColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${documents.length} submitted')),
                        DataCell(Text(_date(group['latest_uploaded_at']))),
                        DataCell(AdminStatusPill(
                          text: status,
                          color: adminStatusColor(status),
                        )),
                        DataCell(IconButton(
                          tooltip: 'Open first document',
                          icon: const Icon(Icons.description_outlined),
                          onPressed: firstDocument == null
                              ? null
                              : () => _openDocument(
                                    firstDocument['file_url']?.toString(),
                                  ),
                        )),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _showProviderDocuments(group),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.brown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('View Full'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _groupStatus(List<Map<String, dynamic>> documents) {
    if (documents.isEmpty) return _status;
    if (documents.any((doc) => doc['status']?.toString() == 'pending')) {
      return 'pending';
    }
    if (documents.any((doc) => doc['status']?.toString() == 'rejected')) {
      return 'rejected';
    }
    return 'approved';
  }

  String _date(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onView;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _DocumentCard({
    required this.document,
    required this.onView,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = document['status']?.toString() ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _documentTitle(document['document_type']?.toString()),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded ${_relativeDate(document['uploaded_at'])}',
            style: const TextStyle(color: AdminColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AdminStatusPill(text: status, color: adminStatusColor(status)),
              const Spacer(),
              if (onApprove != null) ...[
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.brown,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
              ],
              if (onReject != null)
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _documentTitle(String? value) {
    final text = value ?? 'Document';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _relativeDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }
}
