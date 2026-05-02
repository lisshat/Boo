import 'package:boo/screens/pet_owner/pet_profile_page.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const orange = Color(0xFFF68B1F);

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchMe();
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    final res = await ApiService.instance.get('/auth/me');
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load profile (${res.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('My Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),

          // User card
          FutureBuilder(
            future: _profileFuture,
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (asyncSnapshot.hasError) {
                return Center(child: Text('Error: ${asyncSnapshot.error}'));
              }
              final currentuserData = asyncSnapshot.data!;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAECEF)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: orange, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://picsum.photos/200?random=21',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.person,
                                    color: Color(0xFF9CA3AF), size: 28),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentuserData['fullName'] ?? 'Name not available',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(currentuserData['email'] ?? 'Email not available',
                              style: TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.edit_outlined, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            }
          ),

          const SizedBox(height: 20),

          // My Pets section
          Row(
            children: [
              const Expanded(
                child: Text('My Pets',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16, color: orange),
                label: const Text('Add pet',
                    style:
                        TextStyle(color: orange, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pet card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PetProfilePage()),
              );
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://picsum.photos/200?random=77',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.pets, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Charlie',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Dog · 3 years · Golden Retriever',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Settings section
          const Text('Settings',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          _SettingsGroup(items: [
            _SettingsItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.location_on_outlined,
              label: 'Location',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy & Security',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 12),

          _SettingsGroup(items: [
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              label: 'About Boo',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 12),

          // Logout
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
    );
  }
}

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
                    color: const Color(0xFFF68B1F).withOpacity(0.10),
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

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
