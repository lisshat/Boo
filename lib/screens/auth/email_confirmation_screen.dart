import 'dart:async';

import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String? actionLabel;

  const EmailConfirmationScreen({super.key, this.actionLabel});

  static Future<bool?> show(
    BuildContext context, {
    String? actionLabel,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EmailConfirmationScreen(actionLabel: actionLabel),
      ),
    );
  }

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

enum _ConfirmationStep { required, send, code, success }

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFFFF8F3);

  final _codeController = TextEditingController();
  _ConfirmationStep _step = _ConfirmationStep.required;
  String _maskedEmail = 'your email address';
  bool _loading = false;
  String? _error;
  Timer? _timer;
  int _resendSeconds = 0;
  int _expiresSeconds = 600;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await AuthService.instance.getEmailVerificationStatus();
      if (!mounted) return;
      setState(() {
        _maskedEmail = status['maskedEmail']?.toString() ?? _maskedEmail;
        if (status['emailVerified'] == true) _step = _ConfirmationStep.success;
      });
    } on EmailVerificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not load confirmation status. Try again.');
      }
    }
  }

  Future<void> _sendCode() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthService.instance.sendEmailVerificationCode();
      if (!mounted) return;
      if (result['alreadyVerified'] == true) {
        setState(() => _step = _ConfirmationStep.success);
        return;
      }
      setState(() {
        _maskedEmail = result['maskedEmail']?.toString() ?? _maskedEmail;
        _expiresSeconds = (result['expiresInSeconds'] as num?)?.toInt() ?? 600;
        _step = _ConfirmationStep.code;
      });
      _startCountdown(
          (result['resendAvailableInSeconds'] as num?)?.toInt() ?? 60);
    } on EmailVerificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
      if (error.retryAfterSeconds != null) {
        _startCountdown(error.retryAfterSeconds!);
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not send the code. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    final boundedSeconds = seconds.clamp(0, 3600).toInt();
    if (mounted) setState(() => _resendSeconds = boundedSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _confirm() async {
    if (_loading) return;
    final code = _codeController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.confirmEmailVerificationCode(code);
      if (mounted) setState(() => _step = _ConfirmationStep.success);
    } on EmailVerificationException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        if (error.code == 'EMAIL_VERIFICATION_COOLDOWN' &&
            error.retryAfterSeconds != null) {
          _startCountdown(error.retryAfterSeconds!);
        }
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not confirm your email. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interruption = _step == _ConfirmationStep.required;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: interruption
            ? null
            : const Text(
                'Confirm email',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
        leading: IconButton(
          tooltip: interruption ? 'Close' : 'Back',
          onPressed: () => Navigator.maybePop(context, false),
          icon: Icon(interruption ? Icons.close_rounded : Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF3E5DC)),
                ),
                child: _body(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _ConfirmationStep.required:
        return _requiredStep();
      case _ConfirmationStep.send:
        return _sendStep();
      case _ConfirmationStep.code:
        return _codeStep();
      case _ConfirmationStep.success:
        return _successStep();
    }
  }

  Widget _illustration(IconData icon, {required String label}) {
    return Semantics(
      label: label,
      child: Container(
        width: 104,
        height: 104,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: _orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(icon, size: 48, color: _orange),
      ),
    );
  }

  Widget _requiredStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _illustration(Icons.mark_email_unread_outlined,
            label: 'Email confirmation illustration placeholder'),
        const Text('Uh-oh! Confirm your email first',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(
          widget.actionLabel == null
              ? 'We need to confirm your email before you can continue.'
              : 'We need to confirm your email before you can continue with ${widget.actionLabel}.',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
        ),
        const SizedBox(height: 24),
        _errorText(),
        FilledButton(
          onPressed: _loading
              ? null
              : () => setState(() => _step = _ConfirmationStep.send),
          style: _primaryStyle(),
          child: const Text('Confirm email'),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
      ],
    );
  }

  Widget _sendStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _illustration(Icons.mail_outline_rounded,
            label: 'Email confirmation illustration placeholder'),
        const Text('Confirm your email',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text('We will send a six-digit code to $_maskedEmail.',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
        const SizedBox(height: 12),
        const Text(
          'Email address incorrect? Get help. Email changes are not available yet.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        const SizedBox(height: 24),
        _errorText(),
        FilledButton(
          onPressed: _loading ? null : _sendCode,
          style: _primaryStyle(),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Send code'),
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _illustration(Icons.pin_outlined,
            label: 'Email confirmation code illustration placeholder'),
        const Text('Enter your code',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text('Enter the code sent to $_maskedEmail.',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
        const SizedBox(height: 6),
        Text('The code expires in ${(_expiresSeconds / 60).ceil()} minutes.',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        const SizedBox(height: 18),
        TextField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          onSubmitted: (_) => _confirm(),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 25, letterSpacing: 8, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        _errorText(),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          style: _primaryStyle(),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Confirm email'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_loading || _resendSeconds > 0) ? null : _sendCode,
          child: Text(_resendSeconds > 0
              ? 'Resend code in ${_resendSeconds}s'
              : 'Resend code'),
        ),
      ],
    );
  }

  Widget _successStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _illustration(Icons.check_circle_outline_rounded,
            label: 'Email confirmation success illustration placeholder'),
        const Text('Email confirmed!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Your email is confirmed. You can continue using Boo.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: _primaryStyle(),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _errorText() {
    final error = _error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(error, style: const TextStyle(color: Color(0xFFB42318))),
    );
  }

  ButtonStyle _primaryStyle() => FilledButton.styleFrom(
        backgroundColor: _orange,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
