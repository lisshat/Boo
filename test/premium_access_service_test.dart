import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:boo/services/premium_access_service.dart';
import 'package:boo/services/revenuecat_service.dart';
import 'package:boo/screens/premium_plan_screen.dart';
import 'package:boo/widgets/premium_feature_gate.dart';

class _FakeAdapter implements RevenueCatAdapter {
  bool configured = true;
  String? activeId;
  CustomerInfoSnapshot info = const CustomerInfoSnapshot(<String>{});
  void Function(CustomerInfoSnapshot)? listener;

  @override
  Future<void> setDebugLogging() async {}

  @override
  Future<bool> isConfigured() async => configured;

  @override
  Future<void> configure(String apiKey) async => configured = true;

  @override
  Future<CustomerInfoSnapshot> logIn(String userId) async {
    activeId = userId;
    return info;
  }

  @override
  Future<String?> getAppUserId() async => activeId;

  @override
  Future<void> logOut() async => activeId = null;

  @override
  Future<CustomerInfoSnapshot> getCustomerInfo() async => info;

  @override
  Future<void> invalidateCustomerInfoCache() async {}

  @override
  Future<MembershipOfferingData> getOfferings() async =>
      const MembershipOfferingData(<String, RevenueCatOfferingData>{});

  @override
  Future<CustomerInfoSnapshot> restorePurchases() async => info;

  @override
  Future<CustomerInfoSnapshot> purchasePackage(
          String offeringIdentifier, String packageIdentifier) async =>
      info;

  @override
  void addCustomerInfoListener(void Function(CustomerInfoSnapshot) value) {
    listener = value;
  }
}

void main() {
  const evaluator = PremiumAccessEvaluator();
  const ownerPlus = MembershipState(kind: MembershipKind.booPlus);
  const providerPro = MembershipState(kind: MembershipKind.booPro);
  const free = MembershipState(kind: MembershipKind.free);
  const unavailable = MembershipState(kind: MembershipKind.unavailable);

  test('free owner retains free functionality and needs Boo Plus for premium',
      () {
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: free,
            feature: PremiumFeature.additionalPetProfiles,
          )
          .kind,
      PremiumAccessKind.requiresBooPlus,
    );
  });

  test('pet creation keeps the first pet free and gates later pets', () {
    expect(
      evaluator
          .evaluatePetCreation(
            role: 'owner',
            membership: free,
            petCount: 0,
          )
          .kind,
      PremiumAccessKind.allowed,
    );
    expect(
      evaluator
          .evaluatePetCreation(
            role: 'owner',
            membership: free,
            petCount: 1,
          )
          .kind,
      PremiumAccessKind.requiresBooPlus,
    );
    expect(
      evaluator
          .evaluatePetCreation(
            role: 'owner',
            membership: ownerPlus,
            petCount: 2,
          )
          .kind,
      PremiumAccessKind.allowed,
    );
  });

  test('only the first two value-slice features are available', () {
    expect(
        PremiumFeatureCatalogue.isAvailable(
            PremiumFeature.additionalPetProfiles),
        isTrue);
    expect(
        PremiumFeatureCatalogue.isAvailable(
            PremiumFeature.advancedEarningsInsights),
        isTrue);
    expect(PremiumFeatureCatalogue.isAvailable(PremiumFeature.bookingAnalytics),
        isFalse);
  });

  test('active Boo Plus owner is allowed owner premium access', () {
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: ownerPlus,
            feature: PremiumFeature.petHealthTimeline,
          )
          .kind,
      PremiumAccessKind.allowed,
    );
  });

  test('Boo Plus cannot unlock provider features', () {
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: ownerPlus,
            feature: PremiumFeature.bookingAnalytics,
          )
          .kind,
      PremiumAccessKind.roleMismatch,
    );
  });

  test('free provider keeps basic statistics and needs Boo Pro for analytics',
      () {
    expect(
      evaluator
          .evaluate(
            role: 'provider',
            membership: free,
            feature: PremiumFeature.bookingAnalytics,
          )
          .kind,
      PremiumAccessKind.requiresBooPro,
    );
  });

  test('active Boo Pro provider is allowed provider premium access', () {
    expect(
      evaluator
          .evaluate(
            role: 'provider',
            membership: providerPro,
            feature: PremiumFeature.privateClientNotes,
          )
          .kind,
      PremiumAccessKind.allowed,
    );
  });

  test('Boo Pro cannot unlock owner features', () {
    expect(
      evaluator
          .evaluate(
            role: 'provider',
            membership: providerPro,
            feature: PremiumFeature.healthRecordExport,
          )
          .kind,
      PremiumAccessKind.roleMismatch,
    );
  });

  test(
      'unavailable membership fails closed and planned features are coming soon',
      () {
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: unavailable,
            feature: PremiumFeature.additionalPetProfiles,
          )
          .kind,
      PremiumAccessKind.unavailable,
    );
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: ownerPlus,
            feature: PremiumFeature.additionalPetProfiles,
            featureReady: false,
          )
          .kind,
      PremiumAccessKind.comingSoon,
    );
  });

  test('unknown and unauthenticated accounts cannot enter premium features',
      () {
    expect(
      evaluator
          .evaluate(
            role: 'unknown',
            membership: ownerPlus,
            feature: PremiumFeature.additionalPetProfiles,
          )
          .kind,
      PremiumAccessKind.roleMismatch,
    );
    expect(
      evaluator
          .evaluate(
            role: 'owner',
            membership: ownerPlus,
            feature: PremiumFeature.additionalPetProfiles,
            authenticated: false,
          )
          .kind,
      PremiumAccessKind.unauthenticated,
    );
  });

  test(
      'controller clears access immediately and ignores stale membership after logout',
      () async {
    final adapter = _FakeAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('owner');
    await service.associateUser(
      'c4187fb8-cc79-4906-ba00-917760c54089',
      role: 'owner',
    );
    expect(controller.authenticated, isTrue);
    controller.clear();
    expect(controller.authenticated, isFalse);
    expect(
      controller.evaluate(PremiumFeature.petHealthTimeline).kind,
      PremiumAccessKind.unauthenticated,
    );
    controller.dispose();
  });

  test('customer-info expiry revokes premium access reactively', () async {
    final adapter = _FakeAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('owner');
    await service.associateUser(
      'c4187fb8-cc79-4906-ba00-917760c54089',
      role: 'owner',
    );
    expect(
      controller.evaluate(PremiumFeature.petHealthTimeline).kind,
      PremiumAccessKind.allowed,
    );
    adapter.listener?.call(const CustomerInfoSnapshot(<String>{}));
    expect(
      controller.evaluate(PremiumFeature.petHealthTimeline).kind,
      PremiumAccessKind.requiresBooPlus,
    );
    controller.dispose();
  });

  testWidgets('purchase state immediately removes the additional-pet gate',
      (tester) async {
    final adapter = _FakeAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('owner');
    await service.associateUser(
      'c4187fb8-cc79-4906-ba00-917760c54089',
      role: 'owner',
    );
    await service.purchasePackage(
      role: 'owner',
      package: const RevenueCatPackage(
        identifier: r'$rc_monthly',
        title: 'Monthly',
        description: 'Test',
        priceString: 'Test price',
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: PremiumFeatureGate(
        controller: controller,
        revenueCat: service,
        feature: PremiumFeature.additionalPetProfiles,
        child: const Text('Add Pet form'),
      ),
    ));
    expect(find.text('Add Pet form'), findsOneWidget);
    expect(find.text('Explore Boo Plus'), findsNothing);
    controller.dispose();
  });

  testWidgets('owner upgrade gate is compact and opens Boo Plus',
      (tester) async {
    final adapter = _FakeAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('owner');
    await service.associateUser(
      'c4187fb8-cc79-4906-ba00-917760c54089',
      role: 'owner',
    );
    await tester.pumpWidget(MaterialApp(
      home: PremiumFeatureGate(
        controller: controller,
        revenueCat: service,
        feature: PremiumFeature.additionalPetProfiles,
        child: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();
    final card = find.byKey(const ValueKey('premium-upgrade-card'));
    expect(tester.getSize(card).height, lessThan(400));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('View Boo Plus'));
    await tester.tap(find.text('View Boo Plus'));
    await tester.pumpAndSettle();
    final planFinder = find.byType(PremiumPlanScreen);
    expect(planFinder, findsOneWidget);
    final plan = tester.widget<PremiumPlanScreen>(planFinder);
    expect(plan.config.role, 'owner');
    expect(plan.config.offeringIdentifier, 'owner_default');
    expect(plan.config.entitlementIdentifier, 'boo_plus');
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('provider upgrade gate opens Boo Pro', (tester) async {
    final adapter = _FakeAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('provider');
    await service.associateUser(
      'c4187fb8-cc79-4906-ba00-917760c54089',
      role: 'provider',
    );
    await tester.pumpWidget(MaterialApp(
      home: PremiumFeatureGate(
        controller: controller,
        revenueCat: service,
        feature: PremiumFeature.advancedEarningsInsights,
        child: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('premium-upgrade-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('View Boo Pro'));
    await tester.tap(find.text('View Boo Pro'));
    await tester.pumpAndSettle();
    final planFinder = find.byType(PremiumPlanScreen);
    expect(planFinder, findsOneWidget);
    final plan = tester.widget<PremiumPlanScreen>(planFinder);
    expect(plan.config.role, 'provider');
    expect(plan.config.offeringIdentifier, 'provider_default');
    expect(plan.config.entitlementIdentifier, 'boo_pro');
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
