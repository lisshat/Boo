import 'package:boo/services/verification_upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class VerificationUploadScreen extends StatefulWidget {
  const VerificationUploadScreen({super.key});

  @override
  State<VerificationUploadScreen> createState() =>
      _VerificationUploadScreenState();
}

class _VerificationUploadScreenState extends State<VerificationUploadScreen> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late Future<Map<String, dynamic>> _statusFuture;
  PlatformFile? _idFile;
  PlatformFile? _certFile;
  bool _picking = false;
  bool _submitting = false;

  bool get _hasFile => _idFile != null || _certFile != null;

  @override
  void initState() {
    super.initState();
    _statusFuture = VerificationUploadService.instance.getStatus();
  }

  void _refresh() {
    setState(() {
      _statusFuture = VerificationUploadService.instance.getStatus();
    });
  }

  Future<void> _pickFile(String documentType) async {
    setState(() => _picking = true);
    try {
      final file = await VerificationUploadService.instance.pickFile();
      if (file == null) return;
      setState(() {
        if (documentType == 'government_id') {
          _idFile = file;
        } else {
          _certFile = file;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submitAll() async {
    setState(() => _submitting = true);
    final errors = <String>[];
    try {
      if (_idFile != null) {
        try {
          await VerificationUploadService.instance.uploadAndSubmit(
            documentType: 'government_id',
            file: _idFile!,
          );
          if (mounted) setState(() => _idFile = null);
        } catch (e) {
          errors.add('ID: ${e.toString().replaceFirst('Exception: ', '')}');
        }
      }
      if (_certFile != null) {
        try {
          await VerificationUploadService.instance.uploadAndSubmit(
            documentType: 'certificate_or_portfolio',
            file: _certFile!,
          );
          if (mounted) setState(() => _certFile = null);
        } catch (e) {
          errors.add('Certificate: ${e.toString().replaceFirst('Exception: ', '')}');
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    if (!mounted) return;

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents submitted for review'),
          backgroundColor: _orange,
        ),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Colors.red.shade400,
        ),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _picking || _submitting;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statusFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final documents = (data?['documents'] as List<dynamic>? ?? []);
          final status = data?['verificationStatus']?.toString() ?? 'pending';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusCard(status: status, documents: documents.length),
              const SizedBox(height: 16),
              const Text(
                'JPEG, PNG, PDF or DOCX · max 50 MB',
                style: TextStyle(fontSize: 11, color: Colors.black38, letterSpacing: 0.3),
              ),
              const SizedBox(height: 10),
              _UploadTile(
                icon: Icons.badge_outlined,
                title: 'Government ID or Passport',
                subtitle: 'Tap to select — encrypted and secure',
                pickedFile: _idFile,
                busy: busy,
                onTap: () => _pickFile('government_id'),
                onClear: busy ? null : () => setState(() => _idFile = null),
              ),
              const SizedBox(height: 12),
              _UploadTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Training certificate or portfolio',
                subtitle: 'Tap to select your credentials',
                pickedFile: _certFile,
                busy: busy,
                onTap: () => _pickFile('certificate_or_portfolio'),
                onClear: busy ? null : () => setState(() => _certFile = null),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (busy || !_hasFile) ? null : _submitAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit for review',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(color: _orange)),
                )
              else if (documents.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Submitted documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...documents.map(
                  (item) => _DocumentRow(
                    document: item as Map<String, dynamic>,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final int documents;

  const _StatusCard({required this.status, required this.documents});

  Color get _color {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFFF68B1F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(color: _color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$documents document${documents == 1 ? '' : 's'} submitted',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final PlatformFile? pickedFile;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _UploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pickedFile,
    required this.busy,
    required this.onTap,
    this.onClear,
  });

  bool get _picked => pickedFile != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _picked ? const Color(0xFFF68B1F) : const Color(0xFFEAECEF),
            width: _picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _picked
                    ? const Color(0xFFF68B1F).withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _picked ? Icons.check_circle_outline : icon,
                color: _picked ? const Color(0xFFF68B1F) : Colors.black45,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _picked ? pickedFile!.name : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _picked ? const Color(0xFFF68B1F) : Colors.black45,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_picked && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: Colors.black38),
              )
            else
              const Icon(Icons.upload_file_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentRow({required this.document});

  @override
  Widget build(BuildContext context) {
    final status = document['status']?.toString() ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFFF68B1F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              document['document_type']?.toString() ?? 'Document',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            status,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
