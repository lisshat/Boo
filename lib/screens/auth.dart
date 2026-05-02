import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'package:boo/screens/pet_owner_shell.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
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
            fullName: _fullNameCtrl.text.trim(),
            role: widget.role,
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
                          color: Colors.black.withOpacity(0.08),
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
                    widget.role == 'provider' ? 'Provider Access' : 'Pet Owner Access',
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
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _AuthToggle(
                          isLogin: isLogin,
                          onChanged: (val) => setState(() => isLogin = val),
                          activeColor: orange,
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isLogin) ...[
                                _Label("FULL NAME"),
                                const SizedBox(height: 6),
                                _Input(
                                  controller: _fullNameCtrl,
                                  hintText: "e.g. Imani Wanjiku",
                                  keyboardType: TextInputType.name,
                                  validator: (v) {
                                    if ((v ?? '').trim().isEmpty) return 'Full name is required';
                                    return null;
                                  },
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
                                  if (!value.contains("@"))
                                    return "Enter a valid email";
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

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: navigate to forgot password screen
                                  },
                                  child: const Text("Forgot password?"),
                                ),
                              ),

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

                              // Divider text
                              Row(
                                children: const [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      "OR CONTINUE WITH",
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      label: "Google",
                                      icon: Icons
                                          .g_mobiledata, // placeholder icon
                                      onTap: () {
                                        // TODO: Google sign-in flow (Supabase OAuth)
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialButton(
                                      label: "Apple",
                                      icon: Icons.apple,
                                      onTap: () {
                                        // TODO: Apple sign-in flow (if needed)
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              if (widget.role == 'owner')
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Looking to offer your services?",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF6B7280),
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const BooAuthScreen(role: 'provider'),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: orange,
                                          side: const BorderSide(color: orange),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          "Are you a provider? Login here",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 12),

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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111827),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: Colors.white,
      ),
      icon: Icon(icon, size: 18, color: const Color(0xFF111827)),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Routes to the correct shell after a successful login/register,
/// based on the role stored in secure storage.
class _PostAuthRedirect extends StatelessWidget {
  final bool isNewUser;

  const _PostAuthRedirect({this.isNewUser = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.instance.getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data;
        if (isNewUser && role == 'owner') {
          return const OwnerOnboardingStep1();
        }
        if (isNewUser && role == 'provider') {
          return const ProviderOnboardingStep1();
        }
        if (role == 'provider') return const ProviderShell();
        return const PetOwnerShell();
      },
    );
  }
}
