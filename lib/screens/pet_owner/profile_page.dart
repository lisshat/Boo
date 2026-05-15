import 'dart:convert';

import 'package:boo/screens/pet_owner/favorite_providers_screen.dart';
import 'package:boo/screens/pet_owner/owner_spending_screen.dart';
import 'package:boo/screens/pet_owner/pet_profile_page.dart';
import 'package:boo/screens/pet_provider/onboarding/provider_onboarding_step1.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/services/cloudinary_upload_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const orange = Color(0xFFF68B1F);

  late Future<Map<String, dynamic>> _profileFuture;
  late Future<Map<String, dynamic>> _ownerProfileFuture;
  late Future<List<dynamic>> _petsFuture;
  bool _uploadingProfilePhoto = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchMe();
    _ownerProfileFuture = _fetchOwnerProfile();
    _petsFuture = _fetchPets();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    if (UserCache.instance.data != null) return UserCache.instance.data!;
    final res = await ApiService.instance.get('/auth/me');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      UserCache.instance.set(data);
      return data;
    }
    throw Exception('Failed to load profile (${res.statusCode})');
  }

  Future<List<dynamic>> _fetchPets() async {
    final res = await ApiService.instance.get('/pets/me');
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load pets (${res.statusCode})');
  }

  Future<Map<String, dynamic>> _fetchOwnerProfile() async {
    final res = await ApiService.instance.get('/owners/me');
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load owner profile (${res.statusCode})');
  }

  void _refreshProfile() {
    UserCache.instance.clear();
    setState(() {
      _profileFuture = _fetchMe();
      _ownerProfileFuture = _fetchOwnerProfile();
    });
  }

  void _refreshOwnerProfile() {
    setState(() {
      _ownerProfileFuture = _fetchOwnerProfile();
    });
  }

  void _refreshPets() {
    setState(() {
      _petsFuture = _fetchPets();
    });
  }

  Future<void> _uploadOwnerProfilePhoto() async {
    if (_uploadingProfilePhoto) return;
    setState(() => _uploadingProfilePhoto = true);
    try {
      final url = await CloudinaryUploadService.instance.pickAndUploadImage(
        folder: 'boo/owners',
      );
      if (url == null) return;

      final res = await ApiService.instance.patch('/owners/me', {
        'profilePhotoUrl': url,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        _refreshOwnerProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploadingProfilePhoto = false);
    }
  }

  // ── Edit profile sheet ──────────────────────────────────────────
  void _showEditProfileSheet(Map<String, dynamic> userData) {
    final nameCtrl =
        TextEditingController(text: userData['fullName'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, ss) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Profile',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _SheetLabel('FULL NAME'),
                const SizedBox(height: 6),
                _SheetInput(controller: nameCtrl, hint: 'Your full name'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            ss(() => saving = true);
                            final res = await ApiService.instance.patch(
                                '/auth/me', {'fullName': nameCtrl.text.trim()});
                            if (!ctx.mounted) return;
                            if (res.statusCode == 200) {
                              Navigator.pop(ctx);
                              _refreshProfile();
                            } else {
                              ss(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Update failed'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          },
                    style: _btnStyle,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Location sheet ──────────────────────────────────────────────
  void _showLocationSheet(String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, ss) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Location',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Used to find providers near you.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                _SheetLabel('NEIGHBOURHOOD / AREA'),
                const SizedBox(height: 6),
                _SheetInput(controller: ctrl, hint: 'e.g. Westlands, Nairobi'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            ss(() => saving = true);
                            final res = await ApiService.instance.patch(
                                '/auth/me', {'location': ctrl.text.trim()});
                            if (!ctx.mounted) return;
                            if (res.statusCode == 200) {
                              Navigator.pop(ctx);
                              _refreshProfile();
                            } else {
                              ss(() => saving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Update failed'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          },
                    style: _btnStyle,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Add pet sheet ───────────────────────────────────────────────
  void _showAddPetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddPetSheet(
        onAdded: () {
          if (mounted) _refreshPets();
        },
      ),
    );
  }

  // ── Simple info dialogs ─────────────────────────────────────────
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Push notification preferences are coming soon. '
            'You will be able to control booking alerts, reminders, and promotions here.',
            style: TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: orange, fontWeight: FontWeight.w700)))
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Password change and account deletion are coming soon.',
            style: TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: orange, fontWeight: FontWeight.w700)))
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Help & Support',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For support, reach us at:',
                style: TextStyle(color: Color(0xFF6B7280))),
            SizedBox(height: 8),
            Text('support@boo.co.ke',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('WhatsApp: +254 700 000 000',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: orange, fontWeight: FontWeight.w700)))
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('About Boo',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Boo connects pet owners with trusted sitters, groomers, boarders, '
            'and vets across Nairobi.\n\nVersion 1.0.0 (MVP)',
            style: TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: orange, fontWeight: FontWeight.w700)))
        ],
      ),
    );
  }

  ButtonStyle get _btnStyle => ElevatedButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  Future<void> _onRefresh() async {
    UserCache.instance.clear();
    setState(() {
      _profileFuture = _fetchMe();
      _ownerProfileFuture = _fetchOwnerProfile();
      _petsFuture = _fetchPets();
    });
    await Future.wait([
      _profileFuture,
      _ownerProfileFuture.catchError((_) => <String, dynamic>{}),
      _petsFuture.catchError((_) => <dynamic>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: orange,
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text('My Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),

            // ── User card ─────────────────────────────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load profile.',
                          style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: _refreshProfile,
                        child: const Text('Retry',
                            style: TextStyle(color: orange)),
                      ),
                    ],
                  );
                }
                final user = snap.data!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _ownerProfileFuture,
                        builder: (context, ownerSnap) {
                          final ownerProfile = ownerSnap.data;
                          return _OwnerProfileAvatar(
                            fullName:
                                user['fullName'] as String? ?? 'Boo owner',
                            photoUrl:
                                ownerProfile?['profilePhotoUrl'] as String?,
                            uploading: _uploadingProfilePhoto,
                            onTap: _uploadOwnerProfilePhoto,
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['fullName'] as String? ?? 'Name not set',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['email'] as String? ?? '',
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 13),
                            ),
                            if ((user['location'] as String?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 2),
                                  Text(
                                    user['location'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFF9CA3AF), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditProfileSheet(user),
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── My Pets ───────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text('My Pets',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
                TextButton.icon(
                  onPressed: _showAddPetSheet,
                  icon: const Icon(Icons.add, size: 16, color: orange),
                  label: const Text('Add pet',
                      style: TextStyle(
                          color: orange, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<dynamic>>(
              future: _petsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load pets.',
                            style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: _refreshPets,
                          child: const Text('Retry',
                              style: TextStyle(color: orange)),
                        ),
                      ],
                    ),
                  );
                }
                final pets = snap.data!;
                if (pets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.pets,
                              color: Color(0xFFD1D5DB), size: 36),
                          const SizedBox(height: 8),
                          const Text('No pets yet',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Tap + Add pet to get started.',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: pets.map((p) {
                    final pet = p as Map<String, dynamic>;
                    final name = pet['name'] as String? ?? 'Pet';
                    final species = pet['species'] as String? ?? '';
                    final breed = pet['breed'] as String?;
                    final age = pet['age'] as int?;
                    final photoUrl = pet['photoUrl'] as String?;
                    final subtitle = [
                      if (species.isNotEmpty) species,
                      if (age != null) '$age yr${age == 1 ? '' : 's'}',
                      if (breed != null && breed.isNotEmpty) breed,
                    ].join(' · ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) => PetProfilePage(pet: pet),
                          ))
                              .then((saved) {
                            if (saved == true) _refreshPets();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: photoUrl != null && photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.pets,
                                                color: Color(0xFF9CA3AF)),
                                      )
                                    : const Icon(Icons.pets,
                                        color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15)),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(subtitle,
                                          style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Settings ──────────────────────────────────────────
            const Text('Settings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),

            FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snap) {
                final location = snap.data?['location'] as String?;
                return _SettingsGroup(items: [
                  _SettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'My Spending',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OwnerSpendingScreen()),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorite Providers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavoriteProvidersScreen()),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: _showNotificationsDialog,
                  ),
                  _SettingsItem(
                    icon: Icons.location_on_outlined,
                    label: location?.isNotEmpty == true
                        ? 'Location · $location'
                        : 'Location',
                    onTap: () => _showLocationSheet(location),
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy & Security',
                    onTap: _showPrivacyDialog,
                  ),
                ]);
              },
            ),

            const SizedBox(height: 12),

            _SettingsGroup(items: [
              _SettingsItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: _showHelpDialog,
              ),
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                label: 'About Boo',
                onTap: _showAboutDialog,
              ),
            ]),

            const SizedBox(height: 12),

            // ── Become a Provider ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      color: orange, size: 18),
                ),
                title: const Text('Become a Service Provider',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Offer grooming, boarding & more',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProviderOnboardingStep1()),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Log Out ───────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAECEF)),
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
          ],
        ),
      ),
    );
  }
}

// ── Add pet sheet (StatefulWidget — survives keyboard rebuilds) ───────────────

class _OwnerProfileAvatar extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _OwnerProfileAvatar({
    required this.fullName,
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  String get _initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _ProfilePageState.orange, width: 2),
            ),
            child: ClipOval(
              child: uploading
                  ? const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _InitialsAvatar(initials: _initials),
                        )
                      : _InitialsAvatar(initials: _initials),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _ProfilePageState.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: _ProfilePageState.orange,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AddPetSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddPetSheet({required this.onAdded});

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  static const orange = Color(0xFFF68B1F);
  static const _species = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  String _selectedSpecies = 'Dog';
  int _age = 1;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pet name')),
      );
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': name,
      'species': _selectedSpecies,
      'age': _age,
    };
    if (_breedCtrl.text.isNotEmpty) body['breed'] = _breedCtrl.text.trim();

    final res = await ApiService.instance.post('/pets', body);
    if (!mounted) return;
    if (res.statusCode == 201) {
      Navigator.pop(context);
      widget.onAdded();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not add pet'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a Pet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _SheetLabel('PET NAME'),
          const SizedBox(height: 6),
          _SheetInput(controller: _nameCtrl, hint: "Pet's name"),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetLabel('SPECIES'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSpecies,
                          isExpanded: true,
                          items: _species
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedSpecies = v!),
                          style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetLabel('AGE (years)'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_age > 0) setState(() => _age--);
                            },
                            child: const Icon(Icons.remove,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                          Expanded(
                            child: Text('$_age',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _age++),
                            child: const Icon(Icons.add,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SheetLabel('BREED (optional)'),
          const SizedBox(height: 6),
          _SheetInput(controller: _breedCtrl, hint: 'e.g. Golden Retriever'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add Pet',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sheet widgets ──────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5));
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SheetInput({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF68B1F), width: 1.2),
          ),
        ),
      );
}

// ── Settings widgets ──────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(i == 0 ? 16 : 0),
                    topRight: Radius.circular(i == 0 ? 16 : 0),
                    bottomLeft: Radius.circular(i == items.length - 1 ? 16 : 0),
                    bottomRight:
                        Radius.circular(i == items.length - 1 ? 16 : 0),
                  ),
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF68B1F).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(item.icon, color: const Color(0xFFF68B1F), size: 18),
                ),
                title: Text(item.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF)),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFEAECEF)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsItem(
      {required this.icon, required this.label, required this.onTap});
}
