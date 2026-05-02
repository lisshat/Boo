import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/services/auth_service.dart';
import 'owner_onboarding_step1.dart';

class OwnerOnboardingStep3 extends StatefulWidget {
  final String petName;
  final String petType;

  const OwnerOnboardingStep3({
    super.key,
    required this.petName,
    required this.petType,
  });

  @override
  State<OwnerOnboardingStep3> createState() => _OwnerOnboardingStep3State();
}

class _OwnerOnboardingStep3State extends State<OwnerOnboardingStep3> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.instance.post('/pets', {
        'name': widget.petName,
        'species': widget.petType.toLowerCase(),
      });
      if (!mounted) return;
      if (res.statusCode == 201) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PetOwnerShell()),
          (route) => false,
        );
      } else {
        final body = jsonDecode(res.body);
        _showError(body['message']?.toString() ?? 'Something went wrong');
      }
    } catch (_) {
      if (mounted) _showError('Could not connect. Check your connection.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _OnboardingTopBar(),
              const SizedBox(height: 32),
              OnboardingProgressDots(current: 2, total: 3),
              const SizedBox(height: 40),
              const Text(
                'Find care right in your\nneighbourhood',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 12),
              const Text(
                "We'll show you vetted providers — groomers, trainers and boarders near you — so you can find and book via WhatsApp in minutes.",
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
              ),
              const SizedBox(height: 48),
              _FeatureRow(
                icon: Icons.search_rounded,
                label: 'Find providers',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.verified_rounded,
                label: 'Verified & trusted',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.location_on_outlined,
                label: 'Find locations',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.location_searching_rounded,
                label: 'Enable Location',
                highlight: true,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Find providers near me',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Step 3 of 3',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        const SizedBox(width: 12),
        const Text('Boo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _FeatureRow({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFF68B1F) : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlight ? Colors.white : Colors.black54,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            color: highlight ? const Color(0xFFF68B1F) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
