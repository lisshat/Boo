import 'package:boo/screens/admin/admin_shell.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const _orange = Color(0xFFFF8A00);
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    final error = await AuthService.instance.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    final role = await AuthService.instance.getUserRole();
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null || role != 'admin') {
      await AuthService.instance.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Access denied. This portal is for administrators only.',
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EA),
      body: Stack(
        children: [
          Positioned(
            left: -100,
            bottom: -120,
            child: Container(
              width: 540,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(280),
              ),
            ),
          ),
          Positioned(
            right: -90,
            bottom: -140,
            child: Container(
              width: 620,
              height: 310,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(320),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, color: _orange, size: 21),
                      SizedBox(width: 6),
                      Text(
                        'Boo Admin',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF9A5700),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Boo Admin Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This portal is restricted to authorized personnel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A7A6B)),
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    controller: _emailCtrl,
                    label: 'Business Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _passwordCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In to Dashboard'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEBD9CA)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 17,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unauthorized access is monitored and logged.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7C4A17),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'PART OF THE Boo ForBusiness NETWORK',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFFC2A894)),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 28,
            bottom: 24,
            child: Text(
              'Boo\n© 2024 Boo Nairobi. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A5700)),
            ),
          ),
          const Positioned(
            right: 28,
            bottom: 24,
            child: Text(
              'Privacy Policy    Terms of Service    Help Center    Support',
              style: TextStyle(fontSize: 11, color: Color(0xFF9A5700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16),
        suffixIcon: trailing,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFFFCFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEBD9CA)),
        ),
      ),
    );
  }
}
