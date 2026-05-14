import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/screens/admin/admin_shell.dart';
import 'package:boo/screens/pet_provider/onboarding/provider_onboarding_step1.dart';
import 'package:boo/screens/pet_provider/provider_shell.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class BooAuthScreen extends StatefulWidget {
  final String role;

  const BooAuthScreen({super.key, this.role = 'owner'});

  @override
  State<BooAuthScreen> createState() => _BooAuthScreenState();
}

class _BooAuthScreenState extends State<BooAuthScreen> {
  bool isLogin = true;
  late String _selectedRole;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  void _clearForm() {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final error = isLogin
        ? await AuthService.instance.login(email, password)
        : await AuthService.instance.register(
            email,
            password,
            fullName:
                '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
                    .trim(),
            role: _selectedRole,
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Replace the AuthGate so it re-checks the stored token
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _PostAuthRedirect(isNewUser: !isLogin)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF68B1F); // warm Boo orange
    const bg = Color(0xFFF6F7FB);
    const cardRadius = 18.0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.pets, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Boo",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF121826),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLogin
                        ? 'Welcome back'
                        : (_selectedRole == 'provider'
                            ? 'Service Provider Account'
                            : 'Pet Owner Account'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                  ),

                  const SizedBox(height: 18),

                  // Card container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _AuthToggle(
                          isLogin: isLogin,
                          onChanged: (val) => setState(() {
                            isLogin = val;
                            _clearForm();
                          }),
                          activeColor: orange,
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isLogin) ...[
                                // Role selector
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _TogglePill(
                                          label: "Pet Owner 🐾",
                                          active: _selectedRole == 'owner',
                                          activeColor: orange,
                                          onTap: () => setState(() {
                                            _selectedRole = 'owner';
                                            _clearForm();
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: _TogglePill(
                                          label: "Provider 🛠️",
                                          active: _selectedRole == 'provider',
                                          activeColor: orange,
                                          onTap: () => setState(() {
                                            _selectedRole = 'provider';
                                            _clearForm();
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _Label("FIRST NAME"),
                                          const SizedBox(height: 6),
                                          _Input(
                                            controller: _firstNameCtrl,
                                            hintText: "First",
                                            keyboardType: TextInputType.name,
                                            validator: (v) {
                                              if ((v ?? '').trim().isEmpty)
                                                return 'Required';
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _Label("LAST NAME"),
                                          const SizedBox(height: 6),
                                          _Input(
                                            controller: _lastNameCtrl,
                                            hintText: "Last",
                                            keyboardType: TextInputType.name,
                                            validator: (v) {
                                              if ((v ?? '').trim().isEmpty)
                                                return 'Required';
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              _Label("EMAIL"),
                              const SizedBox(height: 6),
                              _Input(
                                controller: _emailCtrl,
                                hintText: "name@example.com",
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final value = (v ?? "").trim();
                                  if (value.isEmpty) return "Email is required";
                                  final parts = value.split('@');
                                  if (parts.length != 2 ||
                                      parts[0].isEmpty ||
                                      !parts[1].contains('.')) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              _Label("PASSWORD"),
                              const SizedBox(height: 6),
                              _Input(
                                controller: _passwordCtrl,
                                hintText: "Required",
                                obscureText: _obscure,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 20,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                                validator: (v) {
                                  final value = (v ?? "");
                                  if (value.isEmpty)
                                    return "Password is required";
                                  if (value.length < 6)
                                    return "Password must be at least 6 characters";
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),

                              if (isLogin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed('/forgot-password'),
                                    child: const Text("Forgot password?"),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 2),

                              // Main CTA
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(
                                        isLogin ? "Log In" : "Sign Up",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),

                              const SizedBox(height: 14),

                              // Terms
                              Text(
                                "By continuing you agree to the Terms of Service and Privacy Policy",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF9CA3AF),
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _AuthToggle({
    required this.isLogin,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: "Log In",
              active: isLogin,
              activeColor: activeColor,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TogglePill(
              label: "Sign Up",
              active: !isLogin,
              activeColor: activeColor,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: const Color(0xFFE5E7EB)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.6,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Input({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
}

enum _Destination {
  adminShell,
  ownerShell,
  ownerOnboarding,
  providerShell,
  providerOnboarding
}

/// Routes to the correct shell after a successful login/register.
/// For returning providers, verifies that a provider profile actually exists
/// before sending to ProviderShell — re-routes to onboarding if it doesn't.
class _PostAuthRedirect extends StatelessWidget {
  final bool isNewUser;

  const _PostAuthRedirect({this.isNewUser = false});

  Future<_Destination> _decide() async {
    final role = await AuthService.instance.getUserRole();
    if (role == 'admin') return _Destination.adminShell;
    if (role == 'owner') {
      return isNewUser ? _Destination.ownerOnboarding : _Destination.ownerShell;
    }
    if (role == 'provider') {
      if (isNewUser) return _Destination.providerOnboarding;
      final res = await ApiService.instance.get('/providers/me');
      return res.statusCode == 200
          ? _Destination.providerShell
          : _Destination.providerOnboarding;
    }
    return _Destination.ownerShell;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Destination>(
      future: _decide(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        switch (snapshot.data!) {
          case _Destination.adminShell:
            return const AdminShell();
          case _Destination.ownerShell:
            return const PetOwnerShell();
          case _Destination.ownerOnboarding:
            return const OwnerOnboardingStep1();
          case _Destination.providerShell:
            return const ProviderShell();
          case _Destination.providerOnboarding:
            return const ProviderOnboardingStep1();
        }
      },
    );
  }
}
