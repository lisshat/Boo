import 'package:boo/screens/auth/email_confirmation_screen.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';

class EmailVerificationCoordinator {
  EmailVerificationCoordinator._();

  static Future<bool> ensureConfirmed(
    BuildContext context, {
    String? actionLabel,
  }) async {
    try {
      final status = await AuthService.instance.getEmailVerificationStatus();
      if (status['emailVerified'] == true) return true;
    } on EmailVerificationException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not check email confirmation. Try again.')),
        );
      }
      return false;
    }

    if (!context.mounted) return false;
    return await EmailConfirmationScreen.show(
          context,
          actionLabel: actionLabel,
        ) ==
        true;
  }

  static bool isRequiredError(Object error) {
    return error is EmailVerificationException &&
        error.code == 'EMAIL_VERIFICATION_REQUIRED';
  }
}
