import 'package:boo/models/report_models.dart';
import 'package:boo/services/report_service.dart';
import 'package:flutter/material.dart';

Future<bool?> showReportForm(
  BuildContext context, {
  required String title,
  required Future<void> Function(ReportReason reason, String? description)
      onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ReportFormSheet(title: title, onSubmit: onSubmit),
  );
}

class ReportFormSheet extends StatefulWidget {
  final String title;
  final Future<void> Function(ReportReason reason, String? description)
      onSubmit;

  const ReportFormSheet({
    super.key,
    required this.title,
    required this.onSubmit,
  });

  @override
  State<ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<ReportFormSheet> {
  final _description = TextEditingController();
  ReportReason? _reason;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    final description = _description.text.trim();
    if (reason == null) {
      setState(() => _error = 'Choose a reason for this report.');
      return;
    }
    if (reason == ReportReason.other && description.isEmpty) {
      setState(() => _error = 'Add a short description for Other.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await widget.onSubmit(reason, description.isEmpty ? null : description);
      if (mounted) Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'The report could not be sent. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: const Color(0xFFFFFBF5),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Semantics(
            container: true,
            label: 'Report a safety concern about ${widget.title}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Report a safety concern',
                    style: TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.title,
                    style: const TextStyle(
                        color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Reports are reviewed by Boo’s safety team. Reporting does not automatically block contact. If anyone is in immediate danger, contact local emergency services.',
                  style: TextStyle(color: Color(0xFF5F6368), height: 1.35),
                ),
                const SizedBox(height: 18),
                const Text('What happened?',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...ReportReason.values.map(
                  (reason) => Semantics(
                    label: reason.label,
                    selected: _reason == reason,
                    child: RadioListTile<ReportReason>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      dense: false,
                      activeColor: const Color(0xFFF68B1F),
                      title: Text(reason.label),
                      value: reason,
                      groupValue: _reason,
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _reason = value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  enabled: !_submitting,
                  maxLength: 1000,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Tell Boo what happened',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFB3261E), height: 1.3)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF68B1F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
