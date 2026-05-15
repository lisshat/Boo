import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/services/cloudinary_upload_service.dart';
import 'provider_availability_screen.dart';
import 'provider_earnings_screen.dart';
import 'provider_reviews_screen.dart';
import 'provider_services_page.dart';
import 'verification_upload_screen.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final res = await ApiService.instance.get('/providers/me');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('HTTP ${res.statusCode}');
  }

  void _refresh() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _orange));
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade300, size: 40),
                    const SizedBox(height: 12),
                    Text('Could not load profile (${snap.error})'),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              );
            }
            final profile = snap.data!;
            return _ProfileBody(profile: profile, onEditSaved: _refresh);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditSaved;

  const _ProfileBody({required this.profile, required this.onEditSaved});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  static const _orange = Color(0xFFF68B1F);
  bool _uploadingPhoto = false;

  String _verificationLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Under review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not verified';
    }
  }

  Color _verificationColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _uploadBusinessPhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await CloudinaryUploadService.instance.pickAndUploadImage(
        folder: 'boo/providers',
      );
      if (url == null) return;

      final res = await ApiService.instance.patch('/providers/me', {
        'profilePhotoUrl': url,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business photo updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onEditSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'We uploaded the photo, but could not save it to your profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ImageUploadValidationException
          ? e.message
          : 'Could not upload your photo. Check your connection and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final verificationStatus = profile['verificationStatus'] as String?;
    final services = (profile['services'] as List<dynamic>?) ?? [];
    final photoUrl = profile['profilePhotoUrl'] as String?;

    return RefreshIndicator(
      color: _orange,
      onRefresh: () async => widget.onEditSaved(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Row(
            children: [
              const Text(
                'My Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _openEditSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Photo + name + verification
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploadBusinessPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: ClipOval(
                          child: _uploadingPhoto
                              ? const ColoredBox(
                                  color: Colors.white,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : photoUrl != null && photoUrl.isNotEmpty
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const _BusinessPhotoFallback(),
                                    )
                                  : const _BusinessPhotoFallback(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: _orange, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile['businessName'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                _VerificationBadge(
                  label: _verificationLabel(verificationStatus),
                  color: _verificationColor(verificationStatus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Bio
          _SectionCard(
            title: 'Professional Bio',
            child: Text(
              (profile['bio'] as String?)?.isNotEmpty == true
                  ? profile['bio'] as String
                  : 'No bio added yet.',
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),

          // Location
          _SectionCard(
            title: 'Location',
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: _orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (profile['location'] as String?)?.isNotEmpty == true
                        ? profile['location'] as String
                        : 'No location set.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Services
          _SectionCard(
            title: 'Services',
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProviderServicesPage()),
              ),
              child: const Text('Manage',
                  style: TextStyle(color: _orange, fontSize: 13)),
            ),
            child: services.isEmpty
                ? const Text(
                    'No services added yet.',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  )
                : Column(
                    children: services.take(3).map<Widget>((s) {
                      final svc = s as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF68B1F)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.content_cut_outlined,
                                  size: 16, color: _orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    svc['serviceName'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'KSh ${svc['price']} ${_pricingUnitLabel(svc['pricingUnit'] as String?)} · ${svc['durationMinutes']} min',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (svc['isActive'] as bool? ?? true)
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (svc['isActive'] as bool? ?? true)
                                    ? 'Active'
                                    : 'Off',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (svc['isActive'] as bool? ?? true)
                                      ? Colors.green.shade700
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Stats
          _SectionCard(
            title: 'Stats',
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: '${profile['totalReviews'] ?? 0}',
                    label: 'Reviews',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '${profile['averageRating'] ?? '0.0'}',
                    label: 'Avg rating',
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Verification Documents
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: _orange, size: 18),
              ),
              title: const Text('Verification Documents',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Upload ID, certificates or portfolio',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const VerificationUploadScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // My Earnings
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.savings_outlined,
                    color: Colors.green.shade600, size: 18),
              ),
              title: const Text('My Earnings',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('View your income breakdown',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProviderEarningsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // My Reviews
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 18),
              ),
              title: const Text('My Reviews',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('See what pet owners say',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProviderReviewsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Working Hours
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: _orange, size: 18),
              ),
              title: const Text('Working Hours',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Set your availability',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProviderAvailabilityScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Log Out
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 18),
              ),
              title: const Text('Log Out',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
              onTap: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        profile: widget.profile,
        onSaved: widget.onEditSaved,
      ),
    );
  }
}

class _BusinessPhotoFallback extends StatelessWidget {
  const _BusinessPhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Icon(
        Icons.storefront_outlined,
        size: 44,
        color: Colors.black26,
      ),
    );
  }
}

String _pricingUnitLabel(String? value) {
  switch (value) {
    case 'per_hour':
    case 'per hour':
      return 'per hour';
    case 'per_night':
    case 'per night':
      return 'per night';
    case 'per_day':
    case 'per day':
      return 'per day';
    case 'per_session':
    case 'per session':
      return 'per session';
    default:
      return 'per session';
  }
}

class _VerificationBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _VerificationBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatItem(
      {required this.value, required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4)
            ],
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}

// ── Edit Sheet ─────────────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.profile, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static const _orange = Color(0xFFF68B1F);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.profile['businessName'] as String? ?? '');
    _bioCtrl =
        TextEditingController(text: widget.profile['bio'] as String? ?? '');
    _locationCtrl = TextEditingController(
        text: widget.profile['location'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.instance.patch('/providers/me', {
        'businessName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not save changes'),
              backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Connection error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _Field(label: 'Business Name', controller: _nameCtrl),
          const SizedBox(height: 14),
          _Field(label: 'Bio', controller: _bioCtrl, maxLines: 3),
          const SizedBox(height: 14),
          _Field(label: 'Location', controller: _locationCtrl),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: _orange.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field(
      {required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
