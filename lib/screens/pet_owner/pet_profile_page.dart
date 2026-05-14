import 'package:boo/services/auth_service.dart';
import 'package:boo/services/cloudinary_upload_service.dart';
import 'package:flutter/material.dart';

class PetProfilePage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  static const orange = Color(0xFFF68B1F);
  static const bg = Color(0xFFF6F7FB);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late String _petType;
  late int _ageYears;
  String? _photoUrl;
  bool _saving = false;
  bool _uploadingPhoto = false;

  static const _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  String _normalizeSpecies(String? s) {
    if (s == null || s.isEmpty) return 'Dog';
    final cap = s[0].toUpperCase() + s.substring(1).toLowerCase();
    return _petTypes.contains(cap) ? cap : 'Other';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.pet['name'] as String? ?? '');
    _breedCtrl =
        TextEditingController(text: widget.pet['breed'] as String? ?? '');
    _petType = _normalizeSpecies(widget.pet['species'] as String?);
    _ageYears = (widget.pet['age'] as int?) ?? 1;
    _photoUrl = widget.pet['photoUrl'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet name cannot be empty')),
      );
      return;
    }
    setState(() => _saving = true);
    final petId = widget.pet['petId'] as String;
    final body = <String, dynamic>{
      'name': name,
      'species': _petType,
      'age': _ageYears,
    };
    if (_breedCtrl.text.isNotEmpty) body['breed'] = _breedCtrl.text.trim();
    if (_photoUrl != null && _photoUrl!.isNotEmpty)
      body['photoUrl'] = _photoUrl;

    final res = await ApiService.instance.patch('/pets/$petId', body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet profile saved!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save changes'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await CloudinaryUploadService.instance.pickAndUploadImage(
        folder: 'boo/pets',
      );
      if (url == null) return;
      final petId = widget.pet['petId'] as String;
      final res = await ApiService.instance.patch('/pets/$petId', {
        'photoUrl': url,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _photoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet photo updated'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save pet photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ImageUploadValidationException
          ? e.message
          : 'Could not upload pet photo. Check your connection and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Widget _petPhotoFallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.pets, color: Color(0xFF9CA3AF), size: 40),
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
              child: GestureDetector(
                onTap: _uploadPhoto,
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
                        child: _uploadingPhoto
                            ? const ColoredBox(
                                color: Color(0xFFF3F4F6),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _petPhotoFallback(),
                                  )
                                : _petPhotoFallback(),
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
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _nameCtrl.text,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Center(
              child: Text(
                '$_petType · $_ageYears years old',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
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
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
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
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
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
                                        size: 18, color: Color(0xFF6B7280)),
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
                                    onTap: () => setState(() => _ageYears++),
                                    child: const Icon(Icons.add,
                                        size: 18, color: Color(0xFF6B7280)),
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
                  _BooInput(
                      controller: _breedCtrl, hint: 'e.g. Golden Retriever'),
                ],
              ),
            ),
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
          borderSide: const BorderSide(color: Color(0xFFF68B1F), width: 1.2),
        ),
      ),
    );
  }
}
