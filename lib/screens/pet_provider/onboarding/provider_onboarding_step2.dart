import 'package:flutter/material.dart';
import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'provider_onboarding_step3.dart';

class ProviderOnboardingStep2 extends StatefulWidget {
  final String providerType;

  const ProviderOnboardingStep2({super.key, required this.providerType});

  @override
  State<ProviderOnboardingStep2> createState() => _ProviderOnboardingStep2State();
}

class _ProviderOnboardingStep2State extends State<ProviderOnboardingStep2> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  final _businessNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _businessNameCtrl.addListener(() => setState(() {}));
    _locationCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _businessNameCtrl.text.trim().isNotEmpty &&
      _locationCtrl.text.trim().isNotEmpty;

  void _goToStep3() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderOnboardingStep3(
          providerType: widget.providerType,
          businessName: _businessNameCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _ProviderTopBar(),
              const SizedBox(height: 32),
              OnboardingProgressDots(current: 1, total: 4),
              const SizedBox(height: 32),
              const Text(
                "Let's build your profile",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  children: [
                    TextSpan(text: 'Owners read your profile before booking. '),
                    TextSpan(
                      text: 'A complete profile gets 3× more requests.',
                      style: TextStyle(
                        color: Color(0xFFF68B1F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _FieldLabel('Business Name'),
              const SizedBox(height: 8),
              _InputField(
                controller: _businessNameCtrl,
                hint: 'e.g. Paws & Relax Sanctuary',
              ),
              const SizedBox(height: 20),
              _FieldLabel('Location / Area'),
              const SizedBox(height: 8),
              _InputField(
                controller: _locationCtrl,
                hint: 'e.g. Westlands, Nairobi',
                prefix: const Icon(Icons.location_on_outlined, size: 18, color: Colors.black38),
              ),
              const SizedBox(height: 20),
              _FieldLabel('Professional Bio'),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                  '$currentLength / $maxLength',
                  style: TextStyle(
                    fontSize: 11,
                    color: currentLength > 450 ? const Color(0xFFF68B1F) : Colors.black38,
                  ),
                ),
                decoration: InputDecoration(
                  hintText: 'Tell owners why they should trust you with their pet...',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canProceed ? _goToStep3 : null,
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
                        'Looking good',
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
                  'Step 2 of 4',
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefix;

  const _InputField({required this.controller, required this.hint, this.prefix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: prefix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

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
