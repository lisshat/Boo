import 'package:boo/services/cloudinary_upload_service.dart';
import 'package:flutter/material.dart';
import 'owner_onboarding_step1.dart';
import 'owner_onboarding_step3.dart';

class OwnerOnboardingStep2 extends StatefulWidget {
  final String petName;

  const OwnerOnboardingStep2({super.key, required this.petName});

  @override
  State<OwnerOnboardingStep2> createState() => _OwnerOnboardingStep2State();
}

class _OwnerOnboardingStep2State extends State<OwnerOnboardingStep2> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  late final TextEditingController _nameController;
  String _selectedType = 'Dog';
  String? _petPhotoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.petName);
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await CloudinaryUploadService.instance.pickAndUploadImage(
        folder: 'boo/pets',
      );
      if (url != null && mounted) {
        setState(() => _petPhotoUrl = url);
      }
    } on ImageUploadValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload photo. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _goToStep3() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerOnboardingStep3(
          petName: _nameController.text.trim(),
          petType: _selectedType,
          petPhotoUrl: _petPhotoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _nameController.text.trim().isNotEmpty;

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
              OnboardingProgressDots(current: 1, total: 3),
              const SizedBox(height: 32),
              Text(
                '${widget.petName} deserves the best care 🐾',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about ${widget.petName} so we can match you with the right providers.',
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 28),
              _PhotoPicker(
                photoUrl: _petPhotoUrl,
                uploading: _uploadingPhoto,
                onTap: _pickAndUploadPhoto,
              ),
              const SizedBox(height: 28),
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              _PetTypeChips(
                selected: _selectedType,
                onSelect: (type) => setState(() => _selectedType = type),
              ),
              const SizedBox(height: 24),
              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
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
                  onPressed: canProceed ? _goToStep3 : null,
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
              const SizedBox(height: 32),
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

class _PhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _PhotoPicker({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: uploading ? null : onTap,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: uploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF68B1F),
                          ),
                        )
                      : photoUrl != null
                          ? Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.pets, size: 40, color: Colors.black26),
                            )
                          : const Icon(Icons.pets, size: 40, color: Colors.black26),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF68B1F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          photoUrl != null
              ? 'Tap to change photo'
              : "Add a photo so providers know who they're meeting",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}

class _PetTypeChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _PetTypeChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'].map((type) {
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF68B1F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFFF68B1F) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
