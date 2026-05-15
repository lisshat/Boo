import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class BannedScreen extends StatelessWidget {
  final String email;

  const BannedScreen({super.key, required this.email});

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:support@boo.co.ke'
      '?subject=Account Suspension Appeal&body=My email: $email',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/banned_cat.svg',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Suspended',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your Boo account has been suspended due to a violation of our community guidelines.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If you believe this is a mistake, please contact our support team.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _contactSupport(context),
                icon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFFF8C00),
                ),
                label: const Text(
                  'Contact Support',
                  style: TextStyle(color: Color(0xFFFF8C00)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF8C00)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account: $email',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _signOut(context),
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
