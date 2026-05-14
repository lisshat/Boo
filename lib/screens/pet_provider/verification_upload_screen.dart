import 'package:boo/services/verification_upload_service.dart';
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
  bool _busy = false;

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

  Future<void> _upload(String documentType) async {
    setState(() => _busy = true);
    try {
      final file = await VerificationUploadService.instance.pickAndUpload(
        documentType: documentType,
      );
      if (file == null) return;
      await VerificationUploadService.instance.submitDocument(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.fileName} submitted for review'),
          backgroundColor: _orange,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _UploadTile(
                icon: Icons.badge_outlined,
                title: 'Government ID or Passport',
                subtitle: 'JPG, PNG, HEIC, PDF, DOC or DOCX',
                busy: _busy,
                onTap: () => _upload('government_id'),
              ),
              const SizedBox(height: 12),
              _UploadTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Training certificate or portfolio',
                subtitle: 'JPG, PNG, HEIC, PDF, DOC or DOCX',
                busy: _busy,
                onTap: () => _upload('certificate_or_portfolio'),
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: _orange))
              else if (documents.isNotEmpty) ...[
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
  final bool busy;
  final VoidCallback onTap;

  const _UploadTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF68B1F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFF68B1F), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded, color: Colors.black38),
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
