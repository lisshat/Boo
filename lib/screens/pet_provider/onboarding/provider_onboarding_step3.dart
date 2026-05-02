import 'package:flutter/material.dart';
import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'provider_onboarding_step4.dart';

class ProviderOnboardingStep3 extends StatefulWidget {
  final String providerType;
  final String businessName;
  final String location;
  final String bio;

  const ProviderOnboardingStep3({
    super.key,
    required this.providerType,
    required this.businessName,
    required this.location,
    required this.bio,
  });

  @override
  State<ProviderOnboardingStep3> createState() => _ProviderOnboardingStep3State();
}

class _ProviderOnboardingStep3State extends State<ProviderOnboardingStep3> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  final _serviceNameCtrl = TextEditingController();
  String _selectedCategory = 'Grooming';
  String _selectedDuration = '1 hour';

  final _priceCtrl = TextEditingController();

  static const _categories = ['Grooming', 'Wellness', 'Boarding', 'Training', 'Veterinary'];
  static const _durations = ['30 min', '1 hour', '1.5 hours', '2 hours', '3 hours', '4 hours', 'Full day'];

  @override
  void initState() {
    super.initState();
    _serviceNameCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
    _selectedCategory = _defaultCategory();
  }

  @override
  void dispose() {
    _serviceNameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String _defaultCategory() {
    switch (widget.providerType) {
      case 'groomer':
        return 'Grooming';
      case 'trainer':
        return 'Training';
      case 'boarder':
        return 'Boarding';
      case 'vet':
        return 'Veterinary';
      default:
        return 'Grooming';
    }
  }

  bool get _canProceed =>
      _serviceNameCtrl.text.trim().isNotEmpty &&
      _priceCtrl.text.trim().isNotEmpty;

  void _goToStep4() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderOnboardingStep4(
          providerType: widget.providerType,
          businessName: widget.businessName,
          location: widget.location,
          bio: widget.bio,
          serviceCategory: _selectedCategory,
          serviceName: _serviceNameCtrl.text.trim(),
          duration: _selectedDuration,
          price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
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
              OnboardingProgressDots(current: 2, total: 4),
              const SizedBox(height: 32),
              const Text(
                "What's your first service?",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'No more negotiating prices over WhatsApp. Set it once, clients see it clearly.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 28),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? _orange : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _orange : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Service name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _serviceNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Full Puppy Groom',
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
              const SizedBox(height: 20),
              const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDuration,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _durations.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuration = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Price (KSh)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixText: 'KSh  ',
                  prefixStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can add more services later',
                style: TextStyle(fontSize: 12, color: Colors.black38),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canProceed ? _goToStep4 : null,
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
                        'Next',
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
                  'Step 3 of 4',
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
