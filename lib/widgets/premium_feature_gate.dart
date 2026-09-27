import 'package:flutter/material.dart';

import '../screens/premium_plan_screen.dart';
import '../services/premium_access_service.dart';
import '../services/revenuecat_service.dart';

class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.controller,
    this.featureReady,
    this.onRetry,
    this.onSignIn,
    this.revenueCat,
  });

  final PremiumFeature feature;
  final Widget child;
  final PremiumAccessController? controller;
  final bool? featureReady;
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;
  final RevenueCatService? revenueCat;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? PremiumAccessController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final decision = controller.evaluate(
          feature,
          featureReady: featureReady ??
              PremiumFeatureCatalogue.isAvailable(feature),
        );
        switch (decision.kind) {
          case PremiumAccessKind.allowed:
            return child;
          case PremiumAccessKind.requiresBooPlus:
            return _UpgradeCard(
              product: 'Boo Plus',
              title: feature == PremiumFeature.additionalPetProfiles
                  ? 'Add more pets'
                  : 'Unlock Boo Plus',
              message: feature == PremiumFeature.additionalPetProfiles
                  ? 'Your first pet profile is free. Upgrade to Boo Plus to create and manage additional pet profiles.'
                  : 'Upgrade to Boo Plus to unlock this owner feature.',
              onTap: () => _openPlan(context, 'owner'),
            );
          case PremiumAccessKind.requiresBooPro:
            return _UpgradeCard(
              product: 'Boo Pro',
              title: feature == PremiumFeature.advancedEarningsInsights
                  ? 'Unlock advanced earnings'
                  : 'Unlock Boo Pro',
              message: feature == PremiumFeature.advancedEarningsInsights
                  ? 'Explore recorded earnings, completed paid services, trends and category insights with Boo Pro.'
                  : 'Upgrade to Boo Pro to unlock this provider feature.',
              onTap: () => _openPlan(context, 'provider'),
            );
          case PremiumAccessKind.comingSoon:
            return const _StatusCard(
              icon: Icons.auto_awesome_outlined,
              title: 'Coming soon',
              message: 'This Boo membership feature is not available yet.',
            );
          case PremiumAccessKind.unavailable:
            return _StatusCard(
              icon: Icons.cloud_off_outlined,
              title: 'Membership status unavailable',
              message: 'Try again when membership status is available.',
              action: onRetry == null
                  ? null
                  : TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
            );
          case PremiumAccessKind.roleMismatch:
            return const _StatusCard(
              icon: Icons.lock_outline,
              title: 'Not available for this account',
              message: 'This membership feature is for a different Boo role.',
            );
          case PremiumAccessKind.unauthenticated:
            return _StatusCard(
              icon: Icons.lock_outline,
              title: 'Sign in required',
              message: 'Sign in to view membership features.',
              action: onSignIn == null
                  ? null
                  : TextButton(
                      onPressed: onSignIn,
                      child: const Text('Sign in'),
                    ),
            );
        }
      },
    );
  }

  void _openPlan(BuildContext context, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumPlanScreen.forRole(
          role,
          revenueCat: revenueCat,
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.product,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String product;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _StatusCard(
        surfaceKey: const ValueKey('premium-upgrade-card'),
        icon: product == 'Boo Pro'
            ? Icons.insights_rounded
            : Icons.pets_rounded,
        title: title,
        message: message,
        action: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            child: Text('View $product'),
          ),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.surfaceKey,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              key: surfaceKey,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(icon,
                            color: const Color(0xFFFF8A00), size: 28),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(message,
                        style: const TextStyle(
                            color: Colors.black54, height: 1.35)),
                    if (action != null) ...[
                      const SizedBox(height: 16),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
