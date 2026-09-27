import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:boo/services/revenuecat_service.dart';
import 'package:boo/services/premium_access_service.dart';

class _FakeRevenueCatAdapter implements RevenueCatAdapter {
  int configureCalls = 0;
  bool configured = false;
  bool debugLogging = false;
  Future<void> Function()? configureImpl;
  Future<bool> Function()? isConfiguredImpl;
  int loginCalls = 0;
  int logoutCalls = 0;
  String? lastLogin;
  String? activeId;
  bool forceMismatchedIdentity = false;
  Future<void> Function()? logoutImpl;
  Future<CustomerInfoSnapshot> Function(String)? loginImpl;
  Future<CustomerInfoSnapshot> Function()? customerInfoImpl;
  Future<CustomerInfoSnapshot> Function(String, String)? purchaseImpl;
  Future<MembershipOfferingData> Function()? offeringsImpl;
  final configuredResponses = <bool>[];
  bool listenerFails = false;
  void Function(CustomerInfoSnapshot)? listener;
  CustomerInfoSnapshot info = const CustomerInfoSnapshot(<String>{});
  MembershipOfferingData offerings = const MembershipOfferingData({});

  @override
  Future<void> setDebugLogging() async => debugLogging = true;

  @override
  Future<void> configure(String apiKey) async {
    configureCalls++;
    final custom = configureImpl;
    if (custom != null) return custom();
    configured = true;
  }

  @override
  Future<bool> isConfigured() async {
    final custom = isConfiguredImpl;
    if (configuredResponses.isNotEmpty) return configuredResponses.removeAt(0);
    return custom == null ? configured : custom();
  }

  @override
  Future<CustomerInfoSnapshot> logIn(String userId) async {
    loginCalls++;
    lastLogin = userId;
    activeId = userId;
    final custom = loginImpl;
    if (custom != null) return custom(userId);
    return info;
  }

  @override
  Future<void> logOut() async {
    logoutCalls++;
    activeId = null;
    final custom = logoutImpl;
    if (custom != null) await custom();
  }

  @override
  Future<CustomerInfoSnapshot> getCustomerInfo() async {
    final custom = customerInfoImpl;
    return custom == null ? info : custom();
  }

  @override
  Future<void> invalidateCustomerInfoCache() async {}

  @override
  Future<String?> getAppUserId() async =>
      forceMismatchedIdentity ? 'anonymous' : activeId;

  @override
  Future<MembershipOfferingData> getOfferings() async {
    final custom = offeringsImpl;
    return custom == null ? offerings : custom();
  }

  @override
  Future<CustomerInfoSnapshot> restorePurchases() async => info;

  @override
  Future<CustomerInfoSnapshot> purchasePackage(
          String offeringIdentifier, String packageIdentifier) async =>
      purchaseImpl == null
          ? info
          : purchaseImpl!(offeringIdentifier, packageIdentifier);

  @override
  void addCustomerInfoListener(void Function(CustomerInfoSnapshot) value) {
    if (listenerFails) throw StateError('listener unavailable');
    listener = value;
  }
}

void main() {
  const userId = 'c4187fb8-cc79-4906-ba00-917760c54089';

  test('missing Test Store key disables membership safely', () async {
    final adapter = _FakeRevenueCatAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: '');
    await service.initialize();
    expect(service.enabled, isFalse);
    expect(adapter.configureCalls, 0);
  });

  test('initialization and UUID identity are idempotent', () async {
    final adapter = _FakeRevenueCatAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await Future.wait([service.initialize(), service.initialize()]);
    await service.associateUser(userId, role: 'owner');
    await service.associateUser(userId, role: 'owner');
    await service.associateUser('owner@example.com', role: 'owner');
    expect(adapter.configureCalls, 1);
    expect(adapter.loginCalls, 1);
    expect(adapter.lastLogin, userId);
  });

  test('already configured SDK is adopted without duplicate configure',
      () async {
    final adapter = _FakeRevenueCatAdapter()..configured = true;
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.initialize();
    expect(adapter.configureCalls, 0);
    expect(service.enabled, isTrue);
  });

  test('configure timeout reconciles when native SDK becomes configured',
      () async {
    final adapter = _FakeRevenueCatAdapter()
      ..configuredResponses.addAll([false, true])
      ..configureImpl = () => Future<void>.error(TimeoutException('slow'));
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.initialize();
    expect(service.enabled, isTrue);
  });

  test('genuine configure failure leaves membership unavailable', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..configureImpl = () => Future<void>.error(StateError('failed'));
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.initialize();
    expect(service.enabled, isFalse);
    expect(service.state.kind, MembershipKind.unavailable);
  });

  test('listener failure does not invalidate native configuration', () async {
    final adapter = _FakeRevenueCatAdapter()..listenerFails = true;
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.initialize();
    expect(service.enabled, isTrue);
  });

  test('customer-info timeout does not undo configured state', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..customerInfoImpl = () => Future<CustomerInfoSnapshot>.error(
            TimeoutException('slow'),
          );
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    await service.refresh();
    expect(service.enabled, isTrue);
  });

  test('offerings timeout does not undo configured state', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..offeringsImpl = () => Future<MembershipOfferingData>.error(
            TimeoutException('slow'),
          );
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    await expectLater(service.loadOffering(role: 'owner'), throwsException);
    expect(service.enabled, isTrue);
  });

  test('maps only the role-valid active entitlement', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus', 'boo_pro'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    expect(service.state.kind, MembershipKind.booPlus);
    adapter.listener!(const CustomerInfoSnapshot({'boo_pro'}));
    expect(service.state.kind, MembershipKind.free);
  });

  test('offering selection is role-specific and requires both packages',
      () async {
    final adapter = _FakeRevenueCatAdapter()
      ..offerings = MembershipOfferingData({
        'owner_default': RevenueCatOfferingData(
          identifier: 'owner_default',
          packages: const [
            RevenueCatPackage(
              identifier: r'$rc_monthly',
              title: 'Monthly',
              description: 'Owner plan',
              priceString: 'Test price',
            ),
            RevenueCatPackage(
              identifier: r'$rc_annual',
              title: 'Annual',
              description: 'Owner plan',
              priceString: 'Test price',
            ),
          ],
        ),
      });
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    final offering = await service.loadOffering(role: 'owner');
    expect(offering.identifier, 'owner_default');
    await expectLater(
      service.loadOffering(role: 'provider'),
      throwsA(isA<StateError>()),
    );
  });

  test('logout clears local membership before SDK cleanup completes', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    await service.clearIdentity();
    expect(service.state.kind, MembershipKind.unavailable);
    expect(adapter.logoutCalls, 1);
  });

  test('anonymous startup can be replaced by owner then provider identity',
      () async {
    final adapter = _FakeRevenueCatAdapter();
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.initialize();
    await service.associateUser(userId, role: 'owner');
    await service.clearIdentity();
    await service.associateUser('7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11',
        role: 'provider');
    expect(adapter.lastLogin, '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11');
    expect(adapter.loginCalls, 2);
  });

  test('delayed owner logout cannot clear a subsequent provider login',
      () async {
    final adapter = _FakeRevenueCatAdapter();
    final logoutStarted = Completer<void>();
    final releaseLogout = Completer<void>();
    adapter.logoutImpl = () async {
      logoutStarted.complete();
      await releaseLogout.future;
    };
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    final logout = service.clearIdentity();
    await logoutStarted.future;
    final providerLogin = service.associateUser(
        '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11',
        role: 'provider');
    releaseLogout.complete();
    await Future.wait([logout, providerLogin]);
    expect(adapter.lastLogin, '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11');
    expect(service.state.kind, MembershipKind.free);
  });

  test('stale association result is discarded after account switch', () async {
    final adapter = _FakeRevenueCatAdapter();
    final ownerLogin = Completer<CustomerInfoSnapshot>();
    adapter.loginImpl = (id) => id == userId
        ? ownerLogin.future
        : Future.value(const CustomerInfoSnapshot({'boo_pro'}));
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final owner = service.associateUser(userId, role: 'owner');
    await Future<void>.delayed(Duration.zero);
    await service.clearIdentity();
    final provider = service.associateUser(
        '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11',
        role: 'provider');
    ownerLogin.complete(const CustomerInfoSnapshot({'boo_plus'}));
    await Future.wait([owner, provider]);
    expect(service.state.kind, MembershipKind.booPro);
    expect(adapter.lastLogin, '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11');
  });

  test('SDK identity mismatch leaves membership unavailable', () async {
    final adapter = _FakeRevenueCatAdapter()..forceMismatchedIdentity = true;
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    expect(service.state.kind, MembershipKind.unavailable);
  });

  test('logout failure does not block the next account identity', () async {
    final adapter = _FakeRevenueCatAdapter();
    adapter.logoutImpl = () async => throw StateError('sdk unavailable');
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    await service.clearIdentity();
    await service.associateUser('7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11',
        role: 'provider');
    expect(adapter.lastLogin, '7db4e1a4-93d4-4a8f-9b1d-9c7f4e9e2c11');
  });

  test('purchase applies owner Boo Plus immediately and refreshes once', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    final controller = PremiumAccessController(revenueCat: service);
    controller.setAuthenticatedRole('owner');
    await service.associateUser(userId, role: 'owner');
    await service.purchasePackage(
      role: 'owner',
      package: const RevenueCatPackage(
        identifier: r'$rc_monthly',
        title: 'Monthly',
        description: 'Test',
        priceString: 'Test price',
      ),
    );
    expect(service.state.kind, MembershipKind.booPlus);
    expect(
      controller.evaluate(PremiumFeature.additionalPetProfiles).kind,
      PremiumAccessKind.allowed,
    );
    controller.dispose();
  });

  test('purchase result is discarded after an account switch', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final purchaseStarted = Completer<void>();
    final releasePurchase = Completer<CustomerInfoSnapshot>();
    adapter.info = const CustomerInfoSnapshot(<String>{});
    adapter.purchaseImpl = (String _, String __) async {
      purchaseStarted.complete();
      return releasePurchase.future;
    };
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    final purchase = service.purchasePackage(
      role: 'owner',
      package: const RevenueCatPackage(
        identifier: r'$rc_monthly',
        title: 'Monthly',
        description: 'Test',
        priceString: 'Test price',
      ),
    );
    await purchaseStarted.future;
    await service.clearIdentity();
    releasePurchase.complete(const CustomerInfoSnapshot({'boo_plus'}));
    await purchase;
    expect(service.state.kind, MembershipKind.unavailable);
  });

  test('cached active entitlement transitions to free at expiration', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = CustomerInfoSnapshot(
        const {'boo_plus'},
        {'boo_plus': DateTime.now().toUtc().add(const Duration(milliseconds: 20))},
      );
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    expect(service.state.kind, MembershipKind.booPlus);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(service.state.kind, MembershipKind.free);
  });

  test('fresh refresh invalidates cached CustomerInfo', () async {
    final adapter = _FakeRevenueCatAdapter()
      ..info = const CustomerInfoSnapshot({'boo_plus'});
    final service = RevenueCatService(adapter: adapter, apiKey: 'test-key');
    await service.associateUser(userId, role: 'owner');
    adapter.info = const CustomerInfoSnapshot(<String>{});
    await service.refreshFresh();
    expect(service.state.kind, MembershipKind.free);
  });
}
