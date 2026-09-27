import 'package:boo/models/report_models.dart';
import 'package:boo/services/admin_service.dart';
import 'package:boo/services/report_service.dart';
import 'package:flutter/material.dart';

class AdminModerationReportsPage extends StatefulWidget {
  const AdminModerationReportsPage({super.key});

  @override
  State<AdminModerationReportsPage> createState() =>
      _AdminModerationReportsPageState();
}

class _AdminModerationReportsPageState
    extends State<AdminModerationReportsPage> {
  ReportStatus? _status;
  ReportReason? _reason;
  ReportPage? _page;
  Object? _error;
  bool _loading = true;
  int _pageNumber = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) _pageNumber = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ReportService.instance.adminList(
        page: _pageNumber,
        limit: 20,
        status: _status,
        reason: _reason,
      );
      if (mounted) setState(() => _page = page);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ReportRecord report) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminReportDetailDialog(report: report),
    );
    if (changed == true && mounted) _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return SizedBox(
      height: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Moderation queue',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                tooltip: 'Refresh moderation queue',
                onPressed: _loading ? null : () => _load(refresh: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Filter<ReportStatus>(
                label: 'Status',
                value: _status,
                values: ReportStatus.values,
                valueLabel: (value) => value.label,
                onChanged: (value) {
                  setState(() => _status = value);
                  _load(refresh: true);
                },
              ),
              _Filter<ReportReason>(
                label: 'Reason',
                value: _reason,
                values: ReportReason.values,
                valueLabel: (value) => value.label,
                onChanged: (value) {
                  setState(() => _reason = value);
                  _load(refresh: true);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading && page == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null && page == null
                    ? _ErrorState(onRetry: () => _load(refresh: true))
                    : RefreshIndicator(
                        onRefresh: () => _load(refresh: true),
                        child: page == null || page.items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('No moderation reports')),
                                ],
                              )
                            : ListView.separated(
                                itemCount: page.items.length + 1,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  if (index == page.items.length) {
                                    return _Pager(
                                      page: page,
                                      onPrevious: _pageNumber > 1
                                          ? () {
                                              _pageNumber--;
                                              _load();
                                            }
                                          : null,
                                      onNext:
                                          _pageNumber * page.limit < page.total
                                              ? () {
                                                  _pageNumber++;
                                                  _load();
                                                }
                                              : null,
                                    );
                                  }
                                  final report = page.items[index];
                                  return _ReportCard(
                                    report: report,
                                    onTap: () => _open(report),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportRecord report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  String get _context {
    if (report.providerProfileId != null) return 'Provider profile';
    if (report.bookingId != null) return 'Booking';
    if (report.streamChannelId != null) return 'Conversation';
    return 'Report';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(report.reason?.label ?? 'Report'),
        subtitle: Text(
          '$_context · ${_formatDate(report.createdAt)}\n'
          '${report.description?.trim().isNotEmpty == true ? report.description!.trim() : 'No description provided'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Chip(label: Text(report.status?.label ?? 'Unknown')),
      ),
    );
  }
}

class _AdminReportDetailDialog extends StatefulWidget {
  final ReportRecord report;

  const _AdminReportDetailDialog({required this.report});

  @override
  State<_AdminReportDetailDialog> createState() =>
      _AdminReportDetailDialogState();
}

class _AdminReportDetailDialogState extends State<_AdminReportDetailDialog> {
  late Future<ReportRecord> _future;
  ReportRecord? _detail;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = ReportService.instance.adminDetail(widget.report.id);
  }

  Future<void> _transition(ReportStatus status) async {
    String? notes;
    if (status == ReportStatus.resolved || status == ReportStatus.dismissed) {
      notes = await _notes();
      if (notes == null) return;
    }
    setState(() => _busy = true);
    try {
      await ReportService.instance.updateStatus(
        widget.report.id,
        status: status,
        resolutionNotes: notes,
      );
      if (mounted) {
        _future = ReportService.instance.adminDetail(widget.report.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated.')),
        );
      }
    } on ReportApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        _future = ReportService.instance.adminDetail(widget.report.id);
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not update this report. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _moderationMessage({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1000,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 3) Navigator.pop(dialogContext, value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _warn(ReportRecord report) async {
    final message = await _moderationMessage(
      title: 'Warn account',
      label: 'Warning message',
    );
    if (message == null || report.reportedAccount?.id == null) return;
    setState(() => _busy = true);
    try {
      await AdminService.instance.warnUser(
        report.reportedAccount!.id!,
        message: message,
        reportId: report.id,
      );
      _showActionResult('Warning sent.');
    } catch (_) {
      _showActionResult('Could not warn this account. Try again.');
    } finally {
      if (mounted) {
        _future = ReportService.instance.adminDetail(widget.report.id);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setSuspended(ReportRecord report, bool suspended) async {
    if (report.reportedAccount?.id == null) return;
    final reason = suspended
        ? await _moderationMessage(
            title: 'Suspend account', label: 'Suspension reason')
        : null;
    if (suspended && reason == null) return;
    if (!suspended) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reinstate account?'),
          content: const Text('This account will be active again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reinstate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    try {
      await AdminService.instance.toggleBan(
        userId: report.reportedAccount!.id!,
        isBanned: suspended,
        reason: reason,
        reportId: report.id,
      );
      _showActionResult(suspended
          ? 'Account suspended until reinstated by Boo.'
          : 'Account reinstated.');
    } catch (_) {
      _showActionResult('Could not update this account. Try again.');
    } finally {
      if (mounted) {
        _future = ReportService.instance.adminDetail(widget.report.id);
        setState(() => _busy = false);
      }
    }
  }

  void _showActionResult(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _conversationEvidence() async {
    try {
      final messages = await ReportService.instance
          .adminConversationContext(widget.report.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Private moderation evidence'),
          content: SizedBox(
            width: 560,
            height: 420,
            child: messages.isEmpty
                ? const Center(child: Text('No messages are available.'))
                : ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final message = messages[index];
                      return ListTile(
                        title: Text(
                            '${message.senderName} (${message.senderRole})'),
                        subtitle: Text(message.text),
                        trailing: Text(_formatDate(message.createdAt)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );
    } on ReportApiException catch (error) {
      _showActionResult(error.message);
    } catch (_) {
      _showActionResult('Conversation evidence is unavailable.');
    }
  }

  Future<String?> _notes() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolution notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Required',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report details'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<ReportRecord>(
          future: _future,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const Text('Could not load report details.');
            }
            final report = snapshot.data!;
            _detail = report;
            final reported = report.reportedAccount;
            final reporter = report.reporter;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reporter != null)
                    _Detail(
                        label: 'Reporter',
                        value: '${reporter.displayName} (${reporter.role})'),
                  if (reported != null)
                    _Detail(
                        label: 'Reported account',
                        value:
                            '${reported.displayName} (${reported.role}) · ${reported.isBanned ? 'Suspended' : 'Active'}'),
                  _Detail(
                      label: 'Reason',
                      value: report.reason?.label ?? 'Unknown'),
                  _Detail(
                      label: 'Status',
                      value: report.status?.label ?? 'Unknown'),
                  _Detail(label: 'Context', value: _contextLabel(report)),
                  _Detail(
                      label: 'Submitted', value: _formatDate(report.createdAt)),
                  if (report.provider != null) ...[
                    _Detail(
                        label: 'Provider',
                        value: report.provider!.businessName),
                    _Detail(
                        label: 'Verification',
                        value: report.provider!.verificationStatus),
                    if (report.provider!.serviceCategories.isNotEmpty)
                      _Detail(
                          label: 'Services',
                          value: report.provider!.serviceCategories.join(', ')),
                  ],
                  if (report.booking != null)
                    _Detail(
                        label: 'Booking',
                        value:
                            '${report.booking!.serviceName ?? 'Service'} · ${report.booking!.status} · ${_formatDate(report.booking!.bookingDatetime)}'),
                  if (report.description?.trim().isNotEmpty == true)
                    _Detail(
                        label: 'Description',
                        value: report.description!.trim()),
                  if (report.assignedAdminId != null)
                    _Detail(
                        label: 'Assigned admin',
                        value: report.assignedAdminId!),
                  if (report.resolutionNotes?.trim().isNotEmpty == true)
                    _Detail(
                        label: 'Resolution notes',
                        value: report.resolutionNotes!.trim()),
                  if (report.history != null) ...[
                    _Detail(
                        label: 'Previous reports',
                        value: report.history!.previousReports.entries
                            .map((entry) => '${entry.key}: ${entry.value}')
                            .join(' · ')),
                    _Detail(
                        label: 'Moderation history',
                        value: report.history!.moderationActions.isEmpty
                            ? 'None recorded'
                            : report.history!.moderationActions
                                .map((action) =>
                                    '${action.action.replaceAll('_', ' ')} (${_formatDate(action.performedAt)})')
                                .join('\n')),
                  ],
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Technical details'),
                    children: [
                      if (report.providerProfileId != null)
                        _Detail(
                            label: 'Provider profile ID',
                            value: report.providerProfileId!),
                      if (report.bookingId != null)
                        _Detail(label: 'Booking ID', value: report.bookingId!),
                      if (report.streamChannelId != null)
                        _Detail(
                            label: 'Channel ID',
                            value: report.streamChannelId!),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Close')),
        if (_detail?.streamChannelId != null)
          TextButton(
            onPressed: _busy ? null : _conversationEvidence,
            child: const Text('Review conversation'),
          ),
        if (_detail?.reportedAccount?.id != null &&
            _detail?.reportedAccount?.role != 'admin')
          TextButton(
            onPressed: _busy || _detail == null ? null : () => _warn(_detail!),
            child: const Text('Warn user'),
          ),
        if (_detail?.reportedAccount?.id != null &&
            _detail?.reportedAccount?.role != 'admin' &&
            _detail?.reportedAccount?.isBanned != true)
          TextButton(
            onPressed: _busy || _detail == null
                ? null
                : () => _setSuspended(_detail!, true),
            child: const Text('Suspend account'),
          ),
        if (_detail?.reportedAccount?.isBanned == true)
          TextButton(
            onPressed: _busy || _detail == null
                ? null
                : () => _setSuspended(_detail!, false),
            child: const Text('Reinstate account'),
          ),
        if (_detail?.status == ReportStatus.submitted)
          TextButton(
              onPressed:
                  _busy ? null : () => _transition(ReportStatus.reviewing),
              child: const Text('Start review')),
        if (_detail?.status == ReportStatus.submitted ||
            _detail?.status == ReportStatus.reviewing) ...[
          TextButton(
              onPressed:
                  _busy ? null : () => _transition(ReportStatus.dismissed),
              child: const Text('Dismiss')),
          if (_detail?.status == ReportStatus.reviewing)
            FilledButton(
                onPressed:
                    _busy ? null : () => _transition(ReportStatus.resolved),
                child: const Text('Resolve')),
        ],
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}

class _Filter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) valueLabel;
  final ValueChanged<T?> onChanged;

  const _Filter(
      {required this.label,
      required this.value,
      required this.values,
      required this.valueLabel,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 190,
        child: DropdownButtonFormField<T?>(
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            DropdownMenuItem<T?>(value: null, child: const Text('All')),
            ...values.map((item) => DropdownMenuItem<T?>(
                value: item, child: Text(valueLabel(item)))),
          ],
          onChanged: onChanged,
        ),
      );
}

class _Pager extends StatelessWidget {
  final ReportPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  const _Pager(
      {required this.page, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('${page.page} · ${page.total} total'),
            const SizedBox(width: 8),
            IconButton(
                tooltip: 'Previous page',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left)),
            IconButton(
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load moderation reports.'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

String _contextLabel(ReportRecord report) {
  if (report.providerProfileId != null) return 'Provider profile';
  if (report.bookingId != null) return 'Booking';
  if (report.streamChannelId != null) return 'Conversation';
  return 'Report';
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Unknown date';
  return '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
