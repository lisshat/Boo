import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'package:boo/screens/pet_provider/provider_shell.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/services/verification_upload_service.dart';
import 'provider_pending_screen.dart';

class ProviderOnboardingStep4 extends StatefulWidget {
  final String providerType;
  final String businessName;
  final String location;
  final String bio;
  final String serviceCategory;
  final String serviceName;
  final String duration;
  final double price;
  final String pricingUnit;

  const ProviderOnboardingStep4({
    super.key,
    required this.providerType,
    required this.businessName,
    required this.location,
    required this.bio,
    required this.serviceCategory,
    required this.serviceName,
    required this.duration,
    required this.price,
    required this.pricingUnit,
  });

  @override
  State<ProviderOnboardingStep4> createState() => _ProviderOnboardingStep4State();
}

class _ProviderOnboardingStep4State extends State<ProviderOnboardingStep4> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  PlatformFile? _idFile;
  PlatformFile? _certFile;
  bool _picking = false;
  bool _submitting = false;

  bool get _hasFile => _idFile != null || _certFile != null;

  static const _categoryMap = {
    'Grooming': 'grooming',
    'Wellness': 'other',
    'Boarding': 'boarding',
    'Training': 'training',
    'Veterinary': 'veterinary',
  };

  static const _durationMap = {
    '30 min': 30,
    '1 hour': 60,
    '1.5 hours': 90,
    '2 hours': 120,
    '3 hours': 180,
    '4 hours': 240,
    'Full day': 480,
  };

  Future<void> _pickDocument(String documentType) async {
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
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() => _doSubmit(withDocuments: true);

  Future<void> _submitLater() => _doSubmit(withDocuments: false);

  Future<void> _doSubmit({required bool withDocuments}) async {
    setState(() => _submitting = true);
    try {
      final currentRole = await AuthService.instance.getUserRole();
      final isUpgrade = currentRole == 'owner';

      final res = await ApiService.instance.post('/providers/onboard', {
        'businessName': widget.businessName,
        'bio': widget.bio,
        'location': widget.location,
        'service': {
          'category': _categoryMap[widget.serviceCategory] ?? 'other',
          'serviceName': widget.serviceName,
          'durationMinutes': _durationMap[widget.duration] ?? 60,
          'price': widget.price,
          'pricingUnit': widget.pricingUnit,
        },
      });
      if (!mounted) return;

      if (res.statusCode == 201) {
        if (withDocuments && !isUpgrade) {
          await _uploadAndSubmitDocuments();
        }
        if (!mounted) return;
        if (isUpgrade) {
          await ApiService.instance.post('/auth/become-provider', {});
          if (!mounted) return;
          _showUpgradeModal();
        } else if (withDocuments) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProviderPendingScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProviderShell()),
            (route) => false,
          );
        }
      } else {
        final body = jsonDecode(res.body);
        _showError(body['message']?.toString() ?? 'Something went wrong');
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _uploadAndSubmitDocuments() async {
    if (_idFile != null) {
      await VerificationUploadService.instance.uploadAndSubmit(
        documentType: 'government_id',
        file: _idFile!,
      );
    }
    if (_certFile != null) {
      await VerificationUploadService.instance.uploadAndSubmit(
        documentType: 'certificate_or_portfolio',
        file: _certFile!,
      );
    }
  }

  void _showUpgradeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "You're now a provider! 🎉",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "Your provider profile has been submitted for review.\n\n"
          "Please log out and log back in to access your provider dashboard. "
          "You can upload verification documents from your provider profile.",
          style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF68B1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log out now',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || _picking;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _ProviderTopBar(),
              const SizedBox(height: 32),
              OnboardingProgressDots(current: 3, total: 4),
              const SizedBox(height: 32),
              const Text(
                'Get the Verified badge ✓',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verified providers appear first in search and get booked more. It only takes a few minutes.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'JPEG, PNG, PDF or DOCX · max 50 MB',
                style: TextStyle(fontSize: 11, color: Colors.black38, letterSpacing: 0.3),
              ),
              const SizedBox(height: 24),
              _UploadTile(
                icon: Icons.badge_outlined,
                title: 'Government ID or Passport',
                subtitle: 'Tap to select — encrypted and secure',
                pickedFile: _idFile,
                busy: busy,
                onTap: () => _pickDocument('government_id'),
                onClear: busy ? null : () => setState(() => _idFile = null),
              ),
              const SizedBox(height: 12),
              _UploadTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Training certificate or portfolio',
                subtitle: 'Tap to select your credentials',
                pickedFile: _certFile,
                busy: busy,
                onTap: () => _pickDocument('certificate_or_portfolio'),
                onClear: busy ? null : () => setState(() => _certFile = null),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Colors.black38),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Your documents are encrypted and only reviewed by our admin team',
                      style: TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (busy || !_hasFile) ? null : _submit,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit for review',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: busy ? null : _submitLater,
                  child: Text(
                    "I'll do this later →",
                    style: TextStyle(
                      fontSize: 13,
                      color: busy ? Colors.grey.shade300 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Step 4 of 4',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
            color: _picked ? const Color(0xFFF68B1F) : Colors.transparent,
            width: 1.5,
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
              const Icon(Icons.attach_file_rounded, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _ProviderTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        const SizedBox(width: 12),
        const Text('Boo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
