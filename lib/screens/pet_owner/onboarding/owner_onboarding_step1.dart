import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boo/services/auth_service.dart';
import 'owner_onboarding_step2.dart';

class OwnerOnboardingStep1 extends StatefulWidget {
  const OwnerOnboardingStep1({super.key});

  @override
  State<OwnerOnboardingStep1> createState() => _OwnerOnboardingStep1State();
}

class _OwnerOnboardingStep1State extends State<OwnerOnboardingStep1> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  final _petNameController = TextEditingController();
  String _firstName = '';
  bool _loadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchFirstName();
    _petNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFirstName() async {
    try {
      final res = await ApiService.instance.get('/auth/me');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final full = (body['fullName'] as String? ?? '').trim();
        setState(() => _firstName = full.split(' ').first);
      }
    } finally {
      setState(() => _loadingName = false);
    }
  }

  void _goToStep2() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerOnboardingStep2(
          petName: _petNameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _petNameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _TopBar(),
              const SizedBox(height: 32),
              OnboardingProgressDots(current: 0, total: 3),
              const SizedBox(height: 32),
              _loadingName
                  ? const SizedBox(height: 40)
                  : Text(
                      'Hey $_firstName 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 8),
              const Text(
                "Let's set up your Boo account so you can find and book pet care in your neighbourhood.",
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 36),
              const Text(
                "What's your pet's name?",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _petNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Charlie',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canProceed ? _goToStep2 : null,
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
                        "Let's go",
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        const SizedBox(width: 12),
        const Text(
          'Boo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class OnboardingProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingProgressDots({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF68B1F) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

