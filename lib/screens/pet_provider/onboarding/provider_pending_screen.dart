import 'package:boo/screens/pet_provider/provider_shell.dart';
import 'package:flutter/material.dart';

class ProviderPendingScreen extends StatelessWidget {
  const ProviderPendingScreen({super.key});

  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "You're under review 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Our team will review your documents and get back to you within 24–48 hours. We'll notify you as soon as you're approved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    _StatusRow(label: 'Profile submitted', done: true),
                    SizedBox(height: 12),
                    _StatusRow(label: 'Documents under review', done: false, active: true),
                    SizedBox(height: 12),
                    _StatusRow(label: 'Verification approved', done: false),
                    SizedBox(height: 12),
                    _StatusRow(label: 'Start accepting bookings', done: false),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ProviderShell()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Go to dashboard',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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

class _StatusRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StatusRow({required this.label, required this.done, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFFF68B1F)
                : active
                    ? const Color(0xFFF68B1F).withOpacity(0.15)
                    : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check : Icons.circle,
            size: done ? 14 : 8,
            color: done
                ? Colors.white
                : active
                    ? const Color(0xFFF68B1F)
                    : Colors.grey.shade300,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
            color: active
                ? const Color(0xFFF68B1F)
                : done
                    ? Colors.black87
                    : Colors.black38,
          ),
        ),
      ],
    );
  }
}
