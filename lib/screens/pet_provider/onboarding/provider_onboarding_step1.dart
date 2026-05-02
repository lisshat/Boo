import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'provider_onboarding_step2.dart';

class ProviderOnboardingStep1 extends StatefulWidget {
  const ProviderOnboardingStep1({super.key});

  @override
  State<ProviderOnboardingStep1> createState() => _ProviderOnboardingStep1State();
}

class _ProviderOnboardingStep1State extends State<ProviderOnboardingStep1> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  String _firstName = '';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchFirstName();
  }

  Future<void> _fetchFirstName() async {
    try {
      final res = await ApiService.instance.get('/auth/me');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final full = (body['fullName'] as String? ?? '').trim();
        setState(() => _firstName = full.split(' ').first);
      }
    } catch (_) {}
  }

  void _goToStep2() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderOnboardingStep2(providerType: _selectedType!),
      ),
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
              _ProviderTopBar(),
              const SizedBox(height: 32),
              OnboardingProgressDots(current: 0, total: 4),
              const SizedBox(height: 32),
              Text(
                _firstName.isEmpty ? 'Welcome 👋' : 'Welcome, $_firstName 👋',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "What kind of pet care do you offer? We'll personalise your experience.",
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: _providerTypes.map((type) {
                    final selected = _selectedType == type.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? _orange : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected
                                    ? _orange.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                type.icon,
                                color: selected ? _orange : Colors.black54,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: selected ? _orange : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle, color: _orange, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedType != null ? _goToStep2 : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'This is me',
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
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Step 1 of 4',
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

class _ProviderType {
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  const _ProviderType(this.value, this.label, this.subtitle, this.icon);
}

const _providerTypes = [
  _ProviderType(
    'vet',
    'Veterinary Professional',
    'Reach pet owners who need trusted medical care',
    Icons.medical_services_outlined,
  ),
  _ProviderType(
    'groomer',
    'Groomer',
    'Fill your schedule with local grooming clients',
    Icons.content_cut_outlined,
  ),
  _ProviderType(
    'trainer',
    'Trainer',
    'Connect with owners who want results',
    Icons.fitness_center_outlined,
  ),
  _ProviderType(
    'boarder',
    'Boarder / Pet Sitter',
    'Give pets a home away from home',
    Icons.home_outlined,
  ),
];

class _ProviderTopBar extends StatelessWidget {
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
