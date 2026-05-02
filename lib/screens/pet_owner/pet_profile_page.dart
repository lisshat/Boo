import 'package:flutter/material.dart';

class PetProfilePage extends StatefulWidget {
  const PetProfilePage({super.key});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  static const orange = Color(0xFFF68B1F);
  static const bg = Color(0xFFF6F7FB);

  final _nameCtrl = TextEditingController(text: 'Charlie');
  final _breedCtrl = TextEditingController(text: 'Golden Retriever');
  String _petType = 'Dog';
  int _ageYears = 3;
  bool _saving = false;

  final _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  final _recentHistory = [
    {'icon': Icons.content_cut, 'label': 'Grooming', 'sub': 'Paws & Whiskers', 'date': 'Feb 12, 2026'},
    {'icon': Icons.medical_services_outlined, 'label': 'Checkup', 'sub': 'Dr. Sarah Jenkins', 'date': 'Jan 5, 2026'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pet profile saved!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('My Pet Profile',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // Pet avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: orange, width: 2.5),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://picsum.photos/200?random=77',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.pets,
                              color: Color(0xFF9CA3AF), size: 40),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _nameCtrl.text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Center(
              child: Text(
                '$_petType · $_ageYears years old',
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),

            const SizedBox(height: 24),

            // Form card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('FULL NAME'),
                  const SizedBox(height: 6),
                  _BooInput(controller: _nameCtrl, hint: "Pet's name"),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('TYPE'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _petType,
                                  isExpanded: true,
                                  items: _petTypes
                                      .map((t) => DropdownMenuItem(
                                          value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _petType = v!),
                                  style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('AGE (years)'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_ageYears > 0) {
                                        setState(() => _ageYears--);
                                      }
                                    },
                                    child: const Icon(Icons.remove,
                                        size: 18,
                                        color: Color(0xFF6B7280)),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$_ageYears',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _ageYears++),
                                    child: const Icon(Icons.add,
                                        size: 18,
                                        color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _FieldLabel('BREED'),
                  const SizedBox(height: 6),
                  _BooInput(controller: _breedCtrl, hint: 'e.g. Golden Retriever'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent history
            Row(
              children: [
                const Expanded(
                  child: Text('Recent History',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All',
                      style: TextStyle(color: orange)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._recentHistory.map((h) => _HistoryTile(item: h)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w800)),
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
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5));
  }
}

class _BooInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _BooInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
              const BorderSide(color: Color(0xFFF68B1F), width: 1.2),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF68B1F).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item['icon'] as IconData,
                color: const Color(0xFFF68B1F), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(item['sub'] as String,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ),
          Text(item['date'] as String,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 12)),
        ],
      ),
    );
  }
}
