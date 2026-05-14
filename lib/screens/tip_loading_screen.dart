import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TipLoadingScreen extends StatefulWidget {
  const TipLoadingScreen({super.key});

  @override
  State<TipLoadingScreen> createState() => _TipLoadingScreenState();
}

class _TipLoadingScreenState extends State<TipLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFF68B1F);

  static const _tips = [
    'Regular brushing reduces shedding and keeps your pet\'s coat healthy and shiny.',
    'Pets need fresh water changed daily — hydration keeps their kidneys and skin healthy.',
    'Short daily walks are better for dogs than one long weekly walk.',
    'Cats sleep up to 16 hours a day — it\'s completely normal and healthy!',
    'Regular vet check-ups catch health issues early, saving time, money, and stress.',
    'Positive reinforcement works better than punishment for all pets.',
    'Dental hygiene matters — brush your pet\'s teeth a few times a week.',
    'A consistent routine for meals and walks reduces anxiety in dogs.',
    'Never give your pet human painkillers — many are toxic to animals.',
    'Socialising pets early makes them calmer and friendlier for life.',
  ];

  int _tipIndex = 0;
  late Timer _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tipIndex = DateTime.now().millisecond % _tips.length;

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
        _fadeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Paw avatar circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/boo_logo.svg',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFFE5E7EB),
                  color: _orange,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SETTING THINGS UP...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 28),

              // Tip card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: _orange),
                        SizedBox(width: 6),
                        Text(
                          'Did you know?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        _tips[_tipIndex],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dot indicators
                    Row(
                      children: List.generate(_tips.length, (i) {
                        final active = i == _tipIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 4),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? _orange : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Bottom logo
              SvgPicture.asset(
                'assets/images/boo_logo.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(Color(0xFFD1D5DB), BlendMode.srcIn),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
