import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'provider_services_page.dart';

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
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load profile');
  }

  void _refresh() => setState(() => _profileFuture = _fetchProfile());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _orange));
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
                    const SizedBox(height: 12),
                    const Text('Could not load profile'),
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

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditSaved;

  const _ProfileBody({required this.profile, required this.onEditSaved});

  static const _orange = Color(0xFFF68B1F);

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

  @override
  Widget build(BuildContext context) {
    final verificationStatus = profile['verificationStatus'] as String?;
    final services = (profile['services'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      color: _orange,
      onRefresh: () async => onEditSaved(),
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
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: const Icon(Icons.person_outline, size: 44, color: Colors.black26),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  profile['businessName'] as String? ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),

          // Location
          _SectionCard(
            title: 'Location',
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: _orange),
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
              child: const Text('Manage', style: TextStyle(color: _orange, fontSize: 13)),
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
                                color: const Color(0xFFF68B1F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.content_cut_outlined, size: 16, color: _orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    svc['serviceName'] as String? ?? '',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'KSh ${svc['price']} · ${svc['durationMinutes']} min',
                                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (svc['isActive'] as bool? ?? true)
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (svc['isActive'] as bool? ?? true) ? 'Active' : 'Off',
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
          const SizedBox(height: 32),
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
      builder: (_) => _EditProfileSheet(profile: profile, onSaved: onEditSaved),
    );
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
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
            color: Colors.black.withOpacity(0.04),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
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

  const _StatItem({required this.value, required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: iconColor), const SizedBox(width: 4)],
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
    _nameCtrl = TextEditingController(text: widget.profile['businessName'] as String? ?? '');
    _bioCtrl = TextEditingController(text: widget.profile['bio'] as String? ?? '');
    _locationCtrl = TextEditingController(text: widget.profile['location'] as String? ?? '');
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
          const SnackBar(content: Text('Could not save changes'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red),
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
          const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                disabledBackgroundColor: _orange.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
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

  const _Field({required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
