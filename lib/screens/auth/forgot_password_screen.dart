import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _bg = Color(0xFFF6F7FB);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final email = _emailCtrl.text.trim();
    setState(() => _loading = true);
    final error = await AuthService.instance.forgotPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _sentEmail = email);
  }

  @override
  Widget build(BuildContext context) {
    final sentEmail = _sentEmail;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: sentEmail == null
                  ? _ForgotPasswordForm(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      loading: _loading,
                      onSubmit: _send,
                    )
                  : _EmailSentConfirmation(email: sentEmail),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSubmit;

  const _ForgotPasswordForm({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your email and we'll send you a reset link",
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          const _Label('EMAIL'),
          const SizedBox(height: 6),
          _AuthInput(
            controller: emailCtrl,
            hintText: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 18),
          _OrangeButton(
            label: 'Send Reset Link',
            loading: loading,
            onPressed: loading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _EmailSentConfirmation extends StatelessWidget {
  final String email;

  const _EmailSentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF047857),
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Check your email!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A reset link has been sent to $email',
          style: const TextStyle(fontSize: 15, color: Color(0xFF047857)),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (_) => false,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF68B1F),
            side: const BorderSide(color: Color(0xFFF68B1F)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Back to Login',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  String? get _token => Uri.base.queryParameters['token'];

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      _showError('Invalid or expired reset link');
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _loading = true);
    final error = await AuthService.instance.resetPassword(
      token: token,
      newPassword: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated! Please log in.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF68B1F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create new password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _Label('NEW PASSWORD'),
                    const SizedBox(height: 6),
                    _AuthInput(
                      controller: _passwordCtrl,
                      hintText: 'At least 6 characters',
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _Label('CONFIRM PASSWORD'),
                    const SizedBox(height: 6),
                    _AuthInput(
                      controller: _confirmCtrl,
                      hintText: 'Confirm password',
                      obscureText: _obscureConfirm,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '') != _passwordCtrl.text) {
                          return 'Passwords must match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _OrangeButton(
                      label: 'Update Password',
                      loading: _loading,
                      onPressed: _loading ? null : _updatePassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Email is required';
  final parts = email.split('@');
  if (parts.length != 2 || parts[0].isEmpty || !parts[1].contains('.')) {
    return 'Enter a valid email';
  }
  return null;
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

class _AuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthInput({
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
        fillColor: Colors.white,
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

class _OrangeButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _OrangeButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF68B1F),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFF68B1F).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
