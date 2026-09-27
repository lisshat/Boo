import 'dart:async';

import 'package:flutter/material.dart';

import '../services/revenuecat_service.dart';
import '../services/premium_access_service.dart';

enum PremiumBenefitState { freeToday, available, planned }

class PremiumBenefit {
  const PremiumBenefit(this.label, this.state);

  final String label;
  final PremiumBenefitState state;
}

class PremiumPlanConfig {
  const PremiumPlanConfig({
    required this.role,
    required this.productName,
    required this.offeringIdentifier,
    required this.entitlementIdentifier,
    required this.headline,
    required this.benefits,
  });

  final String role;
  final String productName;
  final String offeringIdentifier;
  final String entitlementIdentifier;
  final String headline;
  final List<PremiumBenefit> benefits;

  static const owner = PremiumPlanConfig(
    role: 'owner',
    productName: 'Boo Plus',
    offeringIdentifier: 'owner_default',
    entitlementIdentifier: 'boo_plus',
    headline: 'Upgrade to Boo Plus',
    benefits: [
      PremiumBenefit('Additional pet profiles', PremiumBenefitState.available),
      PremiumBenefit(
          'Organized pet health timelines', PremiumBenefitState.planned),
      PremiumBenefit('Health-record export', PremiumBenefitState.planned),
      PremiumBenefit('Smart care reminders', PremiumBenefitState.planned),
      PremiumBenefit('Easier CareLoop rebooking', PremiumBenefitState.planned),
    ],
  );

  static const provider = PremiumPlanConfig(
    role: 'provider',
    productName: 'Boo Pro',
    offeringIdentifier: 'provider_default',
    entitlementIdentifier: 'boo_pro',
    headline: 'Grow with Boo Pro',
    benefits: [
      PremiumBenefit(
          'Advanced earnings insights', PremiumBenefitState.available),
      PremiumBenefit('Booking analytics', PremiumBenefitState.planned),
      PremiumBenefit('Private client notes', PremiumBenefitState.planned),
      PremiumBenefit(
          'Automated rebooking suggestions', PremiumBenefitState.planned),
      PremiumBenefit('Featured listing', PremiumBenefitState.planned),
    ],
  );
}

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({
    super.key,
    required this.config,
    this.revenueCat,
  });

  final PremiumPlanConfig config;
  final RevenueCatService? revenueCat;

  static PremiumPlanScreen forRole(
    String role, {
    RevenueCatService? revenueCat,
  }) {
    return PremiumPlanScreen(
      config: role.trim().toLowerCase() == 'provider'
          ? PremiumPlanConfig.provider
          : PremiumPlanConfig.owner,
      revenueCat: revenueCat,
    );
  }

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  static const _orange = Color(0xFFFF8A00);
  static const _cream = Color(0xFFFFF9F2);
  static const _ink = Color(0xFF26211D);
  late Future<MembershipOffering> _offering;
  String _selected = 'monthly';
  bool _busy = false;
  bool _restoring = false;
  String? _error;

  RevenueCatService get _service =>
      widget.revenueCat ?? RevenueCatService.instance;
  PremiumAccessController get _access => PremiumAccessController.instance;

  @override
  void initState() {
    super.initState();
    _offering = _loadOffering();
    unawaited(_service.refreshFresh());
  }

  Future<MembershipOffering> _loadOffering() async {
    try {
      final offering = await _service.loadOffering(role: widget.config.role);
      if (offering.identifier != widget.config.offeringIdentifier) {
        throw StateError('Membership offering unavailable');
      }
      return offering;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _purchase(MembershipOffering offering) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final package = _selected == 'annual'
        ? offering.annualPackage
        : offering.monthlyPackage;
    try {
      await _service.purchasePackage(
          role: widget.config.role, package: package);
      if (!mounted) return;
      final active = _service.state.kind == MembershipKind.booPlus ||
          _service.state.kind == MembershipKind.booPro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active
              ? '${widget.config.productName} is active in Test Store.'
              : 'Membership status is still updating. Please refresh shortly.'),
        ),
      );
      setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Boo could not complete this membership request. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      await _service.restorePurchases();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Boo could not restore memberships right now. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(widget.config.productName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _access,
          builder: (context, _) => FutureBuilder<MembershipOffering>(
            future: _offering,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: _orange));
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: () {
                  setState(() {
                    _error = null;
                    _offering = _loadOffering();
                  });
                });
              }
              return _content(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(MembershipOffering offering) {
    final membership = _access.membership;
    final active = widget.config.role == 'owner'
        ? membership.kind == MembershipKind.booPlus
        : membership.kind == MembershipKind.booPro;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(
              productName: widget.config.productName,
              headline: widget.config.headline),
          const SizedBox(height: 14),
          _MembershipStatus(
            productName: widget.config.productName,
            active: active,
            membership: membership,
          ),
          const SizedBox(height: 22),
          _SectionTitle('What you get'),
          const SizedBox(height: 10),
          ...widget.config.benefits.map(_benefitCard),
          const SizedBox(height: 18),
          if (widget.config.benefits
              .any((b) => b.state == PremiumBenefitState.planned))
            const Text(
              'Some benefits are planned for a future Boo release. They are shown here for product preview and are not currently enabled by the membership.',
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
          const SizedBox(height: 20),
          _SectionTitle('Choose your plan'),
          const SizedBox(height: 10),
          _PlanChoice(
            title: 'Monthly',
            package: offering.monthlyPackage,
            selected: _selected == 'monthly',
            onTap: _busy ? null : () => setState(() => _selected = 'monthly'),
          ),
          const SizedBox(height: 10),
          _PlanChoice(
            title: 'Annual',
            package: offering.annualPackage,
            selected: _selected == 'annual',
            onTap: _busy ? null : () => setState(() => _selected = 'annual'),
          ),
          const SizedBox(height: 16),
          if (_error != null) _ErrorBanner(_error!),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || active ? null : () => _purchase(offering),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    active ? '${widget.config.productName} active' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Boo memberships are optional. Core bookings, safety tools and existing service obligations remain available without a membership.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _restoring ? null : _restore,
            child: Text(_restoring ? 'Restoring…' : 'Restore purchases'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test Store memberships are for development testing. Purchase availability and localized prices come from RevenueCat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _benefitCard(PremiumBenefit benefit) {
    final free = benefit.state == PremiumBenefitState.freeToday;
    final available = benefit.state == PremiumBenefitState.available;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E6DA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(free || available
                  ? Icons.check_circle_outline
                  : Icons.auto_awesome_outlined,
              color: free || available ? const Color(0xFF4E8A54) : _orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.label,
                    style: const TextStyle(
                        color: _ink, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                    free
                        ? 'Available in Boo today'
                        : available
                            ? 'Available with membership'
                            : 'Coming soon',
                    style: TextStyle(
                        color: free || available
                            ? const Color(0xFF4E8A54)
                            : Colors.black54,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipStatus extends StatelessWidget {
  const _MembershipStatus({
    required this.productName,
    required this.active,
    required this.membership,
  });

  final String productName;
  final bool active;
  final MembershipState membership;

  @override
  Widget build(BuildContext context) {
    final label = active
        ? '$productName is active'
        : membership.kind == MembershipKind.free
            ? 'Free Boo account'
            : 'Membership status unavailable';
    final color = active ? const Color(0xFF4E8A54) : Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF6EC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DED1)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle_outline : Icons.info_outline,
              size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.productName, required this.headline});
  final String productName;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8D1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.workspace_premium_outlined,
              color: Color(0xFFFF8A00), size: 38),
        ),
        const SizedBox(height: 16),
        Text(headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF26211D),
                fontSize: 27,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Select a ${productName} plan that fits your Boo journey.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.35)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFF26211D), fontSize: 17, fontWeight: FontWeight.w800));
}

class _PlanChoice extends StatelessWidget {
  const _PlanChoice({
    required this.title,
    required this.package,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final RevenueCatPackage package;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, ${package.priceString}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
                color: selected
                    ? const Color(0xFFFF8A00)
                    : const Color(0xFFE6DDD2),
                width: selected ? 2.2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? const Color(0xFFFF8A00) : Colors.black38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(package.subscriptionPeriod ?? package.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(package.priceString,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.card_membership_outlined,
                size: 42, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Membership plans are unavailable right now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFE8E4),
            borderRadius: BorderRadius.circular(12)),
        child: Text(message,
            style: const TextStyle(color: Color(0xFF8D2E20), height: 1.3)),
      );
}
