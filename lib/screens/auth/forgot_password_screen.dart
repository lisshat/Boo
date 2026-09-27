import 'dart:async';

import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ResetStep { email, code, password, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  _ResetStep _step = _ResetStep.email;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_emailForm.currentState?.validate() ?? false) || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error =
        await AuthService.instance.requestPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _startCooldown(60);
    setState(() => _step = _ResetStep.code);
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_loading || _resendSeconds > 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error =
        await AuthService.instance.requestPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _startCooldown(60);
  }

  void _continueToPassword() {
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _error = null;
      _step = _ResetStep.password;
    });
  }

  void _useDifferentEmail() {
    _code.clear();
    _password.clear();
    _confirm.clear();
    _timer?.cancel();
    setState(() {
      _resendSeconds = 0;
      _error = null;
      _step = _ResetStep.email;
    });
  }

  Future<void> _confirmReset() async {
    if (!(_passwordForm.currentState?.validate() ?? false) || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await AuthService.instance.confirmPasswordReset(
      email: _email.text.trim(),
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await AuthService.instance.clearTokens();
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = _ResetStep.success);
  }

  void _goBack() {
    if (_loading) return;
    if (_step == _ResetStep.email) {
      Navigator.maybePop(context);
    } else if (_step == _ResetStep.code) {
      _useDifferentEmail();
    } else if (_step == _ResetStep.password) {
      setState(() {
        _error = null;
        _step = _ResetStep.code;
      });
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _step != _ResetStep.success;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: showBack
            ? IconButton(
                tooltip: 'Back',
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text(
          'Reset password',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case _ResetStep.email:
        return _emailView();
      case _ResetStep.code:
        return _codeView();
      case _ResetStep.password:
        return _passwordView();
      case _ResetStep.success:
        return _successView();
    }
  }

  Widget _shell({
    required String title,
    required String body,
    required Widget child,
    int? step,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step != null) ...[
          Center(child: _stepPill(step)),
          const SizedBox(height: 18),
        ],
        Center(child: _artworkPlaceholder()),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: _muted,
          ),
        ),
        const SizedBox(height: 22),
        if (_error != null) ...[
          _errorBanner(_error!),
          const SizedBox(height: 14),
        ],
        child,
      ],
    );
  }

  Widget _emailView() {
    return _shell(
      title: 'Forgot your password?',
      body:
          'Enter your Boo account email and we’ll send you a 6-digit reset code.',
      child: Form(
        key: _emailForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input(
              _email,
              'Account email',
              icon: Icons.mail_outline_rounded,
              keyboard: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              validator: _emailValidator,
            ),
            const SizedBox(height: 18),
            _button('Send reset code', _requestCode),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.maybePop(context),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeView() {
    return _shell(
      step: 2,
      title: 'Check your email',
      body:
          'If a Boo account exists for this email, we’ve sent a 6-digit reset code.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _emailCard(),
          const SizedBox(height: 20),
          const Text(
            'Enter 6-digit reset code',
            style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 9),
          _codeField(),
          const SizedBox(height: 10),
          const Text(
            'This code expires in 10 minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 16),
          _button('Continue', _continueToPassword),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _loading ? null : _useDifferentEmail,
            child: const Text('Use a different email'),
          ),
          TextButton(
            onPressed: _resendSeconds == 0 && !_loading ? _resend : null,
            child: Text(
              _resendSeconds == 0
                  ? 'Resend code'
                  : 'Resend available in ${_resendSeconds}s',
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordView() {
    final mismatch =
        _confirm.text.isNotEmpty && _confirm.text != _password.text;
    return _shell(
      step: 3,
      title: 'Create a new password',
      body: 'Choose a strong password for your Boo account.',
      child: Form(
        key: _passwordForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input(
              _password,
              'New password',
              icon: Icons.lock_outline_rounded,
              obscure: !_showPassword,
              suffix: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              validator: _passwordValidator,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _input(
              _confirm,
              'Confirm new password',
              icon: Icons.lock_outline_rounded,
              obscure: !_showConfirm,
              suffix: IconButton(
                tooltip: _showConfirm ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
                icon: Icon(
                  _showConfirm ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
              onChanged: (_) => setState(() {}),
            ),
            if (mismatch) ...[
              const SizedBox(height: 10),
              _errorBanner('Passwords do not match.'),
            ],
            const SizedBox(height: 16),
            _requirementsCard(),
            const SizedBox(height: 18),
            _button('Update password', _confirmReset),
          ],
        ),
      ),
    );
  }

  Widget _successView() {
    return _shell(
      title: 'Password updated',
      body: 'Your password has been changed. Sign in again to continue.',
      child: _button(
        'Back to sign in',
        () => Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
        ),
      ),
    );
  }

  Widget _stepPill(int step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7D2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'Step $step of 3',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _orangeDark,
        ),
      ),
    );
  }

  // TODO(Boo artwork): Replace this placeholder with the approved password-recovery pixel-dog SVG.
  Widget _artworkPlaceholder() {
    final icon = _step == _ResetStep.success
        ? Icons.check_rounded
        : _step == _ResetStep.password
            ? Icons.key_rounded
            : Icons.mark_email_unread_outlined;
    final isSuccess = _step == _ResetStep.success;
    return Semantics(
      label: isSuccess
          ? 'Password updated'
          : 'Password recovery illustration placeholder',
      image: true,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFFDDF7EA) : const Color(0xFFFFE7D2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 38,
          color: isSuccess ? _success : _orange,
        ),
      ),
    );
  }

  Widget _emailCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E4DC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: _orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _maskedEmail(_email.text.trim()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeField() {
    return Semantics(
      textField: true,
      label: 'Six digit password reset code',
      hint: 'Enter the code from your email',
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final value = _code.text;
                return Container(
                  width: 43,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index < value.length
                          ? _orange
                          : const Color(0xFFE6DAD2),
                      width: index < value.length ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    index < value.length ? value[index] : '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
                  ),
                );
              }),
            ),
          ),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            cursorColor: _orange,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3DFCF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: _orangeDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Password must be between 6 and 72 characters.',
              style: TextStyle(height: 1.35, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2B8AE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 20, color: _errorColor),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: const TextStyle(color: _errorColor, height: 1.35))),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    IconData? icon,
    TextInputType? keyboard,
    List<String>? autofill,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      autofillHints: autofill,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, color: _muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE6DAD2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE6DAD2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _orange, width: 1.8),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback action) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _orange.withValues(alpha: 0.55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen();
}

String _maskedEmail(String email) {
  final pieces = email.split('@');
  if (pieces.length != 2 || pieces.first.isEmpty) return email;
  final local = pieces.first;
  final visible = local.length <= 2 ? local[0] : local.substring(0, 2);
  final maskLength =
      local.length > 2 ? (local.length - 2).clamp(2, 8).toInt() : 2;
  return '$visible${'•' * maskLength}@${pieces.last}';
}

String? _emailValidator(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}

String? _passwordValidator(String? value) {
  final length = (value ?? '').length;
  if (length < 6) return 'Use at least 6 characters';
  if (length > 72) return 'Use no more than 72 characters';
  return null;
}

const _orange = Color(0xFFF68B1F);
const _orangeDark = Color(0xFFB95E0A);
const _ink = Color(0xFF27211D);
const _muted = Color(0xFF6E625B);
const _success = Color(0xFF11834B);
const _errorColor = Color(0xFF9B2C2C);
