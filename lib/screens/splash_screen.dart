import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  final Stopwatch _duration = Stopwatch();
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _duration.start();
    _ctrl.addStatusListener(_handleAnimationStatus);
    _ctrl.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _routeToNext();
  }

  void _routeToNext() {
    if (!mounted || _routed) return;
    _routed = true;
    if (kDebugMode) {
      debugPrint(
          '[auth timing] splash_route ${_duration.elapsedMilliseconds}ms');
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_handleAnimationStatus);
    _duration.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: AnimatedBuilder(
            animation: _slideUp,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  Center(
                    child: SvgPicture.asset(
                      'assets/images/boo_logo.svg',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Tagline
                  const Text(
                    'Connecting you with\nthe best care for\nyour buddy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Expert vetting, seamless booking,\nand absolute peace of mind.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 3),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
