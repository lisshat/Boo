import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

enum MembershipKind {
  unavailable,
  loading,
  free,
  booPlus,
  booPro,
  transientError
}

class MembershipState {
  const MembershipState({required this.kind, this.offering, this.message});

  final MembershipKind kind;
  final MembershipOffering? offering;
  final String? message;
}

class MembershipOffering {
  const MembershipOffering({
    required this.identifier,
    required this.monthlyPackage,
    required this.annualPackage,
  });

  final String identifier;
  final RevenueCatPackage monthlyPackage;
  final RevenueCatPackage annualPackage;
}

class RevenueCatPackage {
  const RevenueCatPackage({
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    this.subscriptionPeriod,
  });

  final String identifier;
  final String title;
  final String description;
  final String priceString;
  final String? subscriptionPeriod;
}

class CustomerInfoSnapshot {
  const CustomerInfoSnapshot(this.activeEntitlements,
      [this.expirationDates = const {}]);
  final Set<String> activeEntitlements;
  final Map<String, DateTime?> expirationDates;

  bool hasActive(String identifier, DateTime now) {
    if (!activeEntitlements.contains(identifier)) return false;
    // Adapter-backed snapshots always include this key. The empty-map
    // fallback keeps older unit-test adapters source-compatible.
    if (!expirationDates.containsKey(identifier)) return true;
    final expiry = expirationDates[identifier];
    return expiry != null && expiry.isAfter(now.toUtc());
  }
}

abstract class RevenueCatAdapter {
  Future<void> setDebugLogging();
  Future<bool> isConfigured();
  Future<void> configure(String apiKey);
  Future<CustomerInfoSnapshot> logIn(String userId);
  Future<String?> getAppUserId();
  Future<void> logOut();
  Future<CustomerInfoSnapshot> getCustomerInfo();
  Future<void> invalidateCustomerInfoCache();
  Future<MembershipOfferingData> getOfferings();
  Future<CustomerInfoSnapshot> restorePurchases();
  Future<CustomerInfoSnapshot> purchasePackage(
      String offeringIdentifier, String packageIdentifier);
  void addCustomerInfoListener(void Function(CustomerInfoSnapshot) listener);
}

class MembershipOfferingData {
  const MembershipOfferingData(this.offerings);
  final Map<String, RevenueCatOfferingData> offerings;
}

class RevenueCatOfferingData {
  const RevenueCatOfferingData(
      {required this.identifier, required this.packages});
  final String identifier;
  final List<RevenueCatPackage> packages;
}

class PurchasesRevenueCatAdapter implements RevenueCatAdapter {
  @override
  Future<void> setDebugLogging() => rc.Purchases.setLogLevel(rc.LogLevel.debug);

  @override
  Future<bool> isConfigured() => rc.Purchases.isConfigured;

  @override
  Future<void> configure(String apiKey) async {
    await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
  }

  CustomerInfoSnapshot _customerInfo(rc.CustomerInfo info) =>
      CustomerInfoSnapshot(
        info.entitlements.active.keys.toSet(),
        {
          for (final entry in info.entitlements.active.entries)
            entry.key: entry.value.expirationDate == null
                ? null
                : DateTime.tryParse(entry.value.expirationDate!)?.toUtc(),
        },
      );

  @override
  Future<CustomerInfoSnapshot> logIn(String userId) async {
    final result = await rc.Purchases.logIn(userId);
    return _customerInfo(result.customerInfo);
  }

  @override
  Future<String?> getAppUserId() => rc.Purchases.appUserID;

  @override
  Future<void> logOut() => rc.Purchases.logOut();

  @override
  Future<CustomerInfoSnapshot> getCustomerInfo() async =>
      _customerInfo(await rc.Purchases.getCustomerInfo());

  @override
  Future<void> invalidateCustomerInfoCache() =>
      rc.Purchases.invalidateCustomerInfoCache();

  RevenueCatPackage _package(rc.Package package) {
    final product = package.storeProduct;
    return RevenueCatPackage(
      identifier: package.identifier,
      title: product.title,
      description: product.description,
      priceString: product.priceString,
      subscriptionPeriod: product.subscriptionPeriod,
    );
  }

  @override
  Future<MembershipOfferingData> getOfferings() async {
    final offerings = await rc.Purchases.getOfferings();
    return MembershipOfferingData({
      for (final entry in offerings.all.entries)
        entry.key: RevenueCatOfferingData(
          identifier: entry.value.identifier,
          packages: entry.value.availablePackages.map(_package).toList(),
        ),
    });
  }

  @override
  Future<CustomerInfoSnapshot> restorePurchases() async =>
      _customerInfo(await rc.Purchases.restorePurchases());

  @override
  Future<CustomerInfoSnapshot> purchasePackage(
      String offeringIdentifier, String packageIdentifier) async {
    final offerings = await rc.Purchases.getOfferings();
    final offering = offerings.all[offeringIdentifier];
    if (offering == null) throw StateError('Membership offering unavailable');
    final package = offering.availablePackages.firstWhere(
      (candidate) => candidate.identifier == packageIdentifier,
      orElse: () => throw StateError('Membership package unavailable'),
    );
    final result = await rc.Purchases.purchase(
      rc.PurchaseParams.package(package),
    );
    return _customerInfo(result.customerInfo);
  }

  @override
  void addCustomerInfoListener(void Function(CustomerInfoSnapshot) listener) {
    rc.Purchases.addCustomerInfoUpdateListener(
      (info) => listener(_customerInfo(info)),
    );
  }
}

class RevenueCatService {
  RevenueCatService({RevenueCatAdapter? adapter, String? apiKey})
      : _adapter = adapter ?? PurchasesRevenueCatAdapter(),
        // This is intentionally a public Test Store SDK key. Never reuse it
        // for a production-store build or place a RevenueCat secret in Flutter.
        _apiKey = apiKey ??
            const String.fromEnvironment('REVENUECAT_TEST_STORE_API_KEY');

  static final instance = RevenueCatService();

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final RevenueCatAdapter _adapter;
  final String _apiKey;
  Future<void>? _initialization;
  Future<void> _identityQueue = Future<void>.value();
  bool _enabled = false;
  bool _listenerRegistered = false;
  String? _userId;
  String? _role;
  String? _sdkUserId;
  int _identityEpoch = 0;
  bool _acceptCustomerUpdates = false;
  Future<void>? _purchaseInFlight;
  Timer? _expiryTimer;
  int? _expiryEpoch;
  String? _expiryRole;
  String? _expiryEntitlement;
  DateTime? _expiryInstant;
  DateTime? _currentEntitlementExpiry;
  MembershipState _state =
      const MembershipState(kind: MembershipKind.unavailable);
  final _listeners = <VoidCallback>[];

  MembershipState get state => _state;
  bool get enabled => _enabled;

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  Future<void> initialize() {
    if (_initialization != null) return _initialization!;
    if (_apiKey.trim().isEmpty) {
      _debug('disabled_no_test_store_key');
      _initialization = Future<void>.value();
      return _initialization!;
    }
    final future = _initializeOnce();
    _initialization = future;
    return future;
  }

  Future<void> _initializeOnce() async {
    _debug('initialize_requested');
    if (kDebugMode) {
      try {
        await _adapter.setDebugLogging().timeout(const Duration(seconds: 2));
      } catch (_) {
        _debug('debug_logging_unavailable');
      }
    }

    var configured = false;
    try {
      configured =
          await _adapter.isConfigured().timeout(const Duration(seconds: 3));
      _debug('configuration_presence_checked');
    } on TimeoutException {
      _debug('configuration_presence_timeout');
    } catch (_) {
      _debug('configuration_presence_failed');
    }

    if (!configured) {
      _debug('configuration_started');
      try {
        // A cold Android emulator can take several seconds to initialize the
        // native SDK. This remains bounded and is never awaited by routing.
        await _adapter.configure(_apiKey).timeout(const Duration(seconds: 15));
        configured = true;
        _debug('configuration_completed');
      } on TimeoutException {
        _debug('configuration_timeout');
        // Configure may have completed natively after Dart's timeout. Recheck
        // once; never blindly issue a second native configure call.
        try {
          configured =
              await _adapter.isConfigured().timeout(const Duration(seconds: 3));
          if (configured) _debug('configuration_reconciled');
        } catch (_) {
          _debug('configuration_reconcile_failed');
        }
      } on rc.PurchasesError {
        _debug('configuration_failed');
      } catch (_) {
        _debug('configuration_failed');
      }
    }

    if (!configured) return;
    _enabled = true;
    _debug('listener_registration_started');
    if (!_listenerRegistered) {
      try {
        _adapter.addCustomerInfoListener(_onCustomerInfo);
        _listenerRegistered = true;
      } catch (_) {
        _debug('listener_registration_failed');
      }
    }
    _debug('listener_registration_completed');
    _debug('initialization_completed');
  }

  Future<void> associateUser(String? userId, {required String? role}) {
    final id = userId?.trim();
    final normalizedRole = role?.trim().toLowerCase();
    if (id == null ||
        !_uuid.hasMatch(id) ||
        (normalizedRole != 'owner' && normalizedRole != 'provider')) {
      _debug('identity_rejected');
      return Future<void>.value();
    }
    if (_userId == id && _role == normalizedRole) return Future<void>.value();
    final epoch = ++_identityEpoch;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _clearExpiryMetadata();
    _currentEntitlementExpiry = null;
    _userId = id;
    _role = normalizedRole;
    _acceptCustomerUpdates = false;
    _state = const MembershipState(kind: MembershipKind.loading);
    _notify();
    return _enqueueIdentity(() => _associateQueued(id, normalizedRole, epoch));
  }

  Future<void> _associateQueued(String id, String? role, int epoch) async {
    await initialize();
    if (!_enabled) {
      if (epoch == _identityEpoch) {
        _state = const MembershipState(kind: MembershipKind.unavailable);
        _notify();
      }
      return;
    }
    if (epoch != _identityEpoch || _userId != id) return;
    try {
      if (_sdkUserId != null && _sdkUserId != id) {
        await _adapter.logOut().timeout(const Duration(seconds: 3));
        _sdkUserId = null;
      }
      _debug('initial_customer_info_started');
      final info = await _adapter.logIn(id).timeout(const Duration(seconds: 8));
      _debug('initial_customer_info_completed');
      if (epoch != _identityEpoch || _userId != id) {
        try {
          await _adapter.logOut().timeout(const Duration(seconds: 3));
        } catch (_) {}
        _sdkUserId = null;
        return;
      }
      final activeId =
          await _adapter.getAppUserId().timeout(const Duration(seconds: 3));
      if (activeId != id) {
        _acceptCustomerUpdates = false;
        _state = const MembershipState(kind: MembershipKind.unavailable);
        _notify();
        _debug('identity_mismatch');
        return;
      }
      _sdkUserId = id;
      _acceptCustomerUpdates = true;
        _applyCustomerInfo(info, role);
      _debug('identity_associated');
    } catch (_) {
      if (epoch == _identityEpoch) {
        _state = const MembershipState(kind: MembershipKind.transientError);
        _notify();
        _debug('identity_failed');
      }
    }
  }

  Future<MembershipOffering> loadOffering({required String role}) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'owner' && normalizedRole != 'provider') {
      throw const FormatException('Unsupported membership role');
    }
    await initialize();
    if (!_enabled || _userId == null || _role != normalizedRole) {
      throw StateError('RevenueCat identity is not ready');
    }
    final data =
        await _adapter.getOfferings().timeout(const Duration(seconds: 8));
    final identifier =
        normalizedRole == 'owner' ? 'owner_default' : 'provider_default';
    final offering = data.offerings[identifier];
    if (offering == null) throw StateError('Membership offering unavailable');
    RevenueCatPackage? find(String id) {
      for (final package in offering.packages) {
        if (package.identifier == id) return package;
      }
      return null;
    }

    final monthly = find(r'$rc_monthly');
    final annual = find(r'$rc_annual');
    if (monthly == null || annual == null) {
      throw StateError('Membership packages unavailable');
    }
    return MembershipOffering(
      identifier: offering.identifier,
      monthlyPackage: monthly,
      annualPackage: annual,
    );
  }

  Future<void> refresh() async {
    if (!_enabled || _userId == null || _role == null) return;
    final epoch = _identityEpoch;
    try {
      final info =
          await _adapter.getCustomerInfo().timeout(const Duration(seconds: 8));
      if (epoch == _identityEpoch) _applyCustomerInfo(info, _role);
    } catch (_) {
      if (epoch == _identityEpoch) {
        _state = const MembershipState(kind: MembershipKind.transientError);
        _notify();
      }
    }
  }

  Future<void> refreshFresh() async {
    if (!_enabled || _userId == null || _role == null) return;
    final epoch = _identityEpoch;
    try {
      await _adapter.invalidateCustomerInfoCache().timeout(
            const Duration(seconds: 3),
          );
      final info = await _adapter
          .getCustomerInfo()
          .timeout(const Duration(seconds: 8));
      if (epoch == _identityEpoch && _userId != null) {
        _applyCustomerInfo(info, _role);
        _debug('customer_info_refreshed');
      }
    } catch (_) {
      // Keep the last known state during a transient refresh failure.
    }
  }

  Future<void> restorePurchases() async {
    if (!_enabled || _userId == null || _role == null) {
      throw StateError('Sign in before restoring memberships');
    }
    final epoch = _identityEpoch;
    final info =
        await _adapter.restorePurchases().timeout(const Duration(seconds: 10));
    if (epoch == _identityEpoch) _applyCustomerInfo(info, _role);
  }

  Future<void> purchasePackage({
    required String role,
    required RevenueCatPackage package,
  }) async {
    final activePurchase = _purchaseInFlight;
    if (activePurchase != null) return activePurchase;
    final operation = _purchasePackage(role: role, package: package);
    _purchaseInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_purchaseInFlight, operation)) _purchaseInFlight = null;
    }
  }

  Future<void> _purchasePackage({
    required String role,
    required RevenueCatPackage package,
  }) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'owner' && normalizedRole != 'provider') {
      throw const FormatException('Unsupported membership role');
    }
    if (!_enabled || _userId == null || _role != normalizedRole) {
      throw StateError('Sign in before purchasing a membership');
    }
    final offeringIdentifier =
        normalizedRole == 'owner' ? 'owner_default' : 'provider_default';
    final epoch = _identityEpoch;
    _debug('purchase_started');
    try {
      final info = await _adapter
          .purchasePackage(offeringIdentifier, package.identifier)
          .timeout(const Duration(seconds: 30));
      if (epoch != _identityEpoch || _userId == null) {
        _debug('purchase_result_discarded');
        return;
      }

      // Apply the purchase result before any identity verification or network
      // refresh so the paywall and feature gates update immediately.
      _applyCustomerInfo(info, normalizedRole);
      _debug('customer_info_applied');
      if (_isActiveMembershipForRole(normalizedRole)) {
        _debug('entitlement_activated');
      }
      _debug('purchase_completed');
      // Reconcile listener/network lag once without keeping the purchase
      // button in a loading state after the native purchase already succeeded.
      unawaited(_reconcileAfterPurchase(epoch, normalizedRole));
    } on TimeoutException {
      _debug('purchase_timeout');
      rethrow;
    } on rc.PurchasesError catch (error) {
      final category = error.code.toString().toLowerCase().contains('cancel')
          ? 'purchase_cancelled'
          : 'purchase_failed';
      _debug(category);
      rethrow;
    } catch (_) {
      _debug('purchase_failed');
      rethrow;
    }
  }

  Future<void> _reconcileAfterPurchase(int epoch, String role) async {
    try {
      final activeId = await _adapter
          .getAppUserId()
          .timeout(const Duration(seconds: 3));
      if (activeId != _userId || epoch != _identityEpoch) {
        if (epoch == _identityEpoch) {
          _state = const MembershipState(kind: MembershipKind.unavailable);
          _notify();
        }
        _debug('identity_mismatch');
        return;
      }
    } catch (_) {
      // The purchase result is still useful; a failed identity read must not
      // erase it after it has already been applied.
    }

    try {
      final refreshed = await _adapter
          .getCustomerInfo()
          .timeout(const Duration(seconds: 8));
      if (epoch == _identityEpoch && _userId != null) {
        final roleEntitlement = role == 'owner' ? 'boo_plus' : 'boo_pro';
        // A delayed refresh can briefly return the pre-purchase snapshot.
        // Never downgrade the just-applied purchase because of that stale
        // response; a later listener update remains authoritative for expiry.
        if (refreshed.hasActive(roleEntitlement, DateTime.now().toUtc()) ||
            !_isActiveMembershipForRole(role)) {
          _applyCustomerInfo(refreshed, role);
          _debug('customer_info_applied');
        } else {
          _debug('backend_projection_pending');
        }
      } else {
        _debug('purchase_result_discarded');
      }
    } on TimeoutException {
      _debug('backend_projection_pending');
    } catch (_) {
      _debug('backend_projection_pending');
    }
  }

  Future<void> clearIdentity() {
    ++_identityEpoch;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _clearExpiryMetadata();
    _userId = null;
    _role = null;
    _sdkUserId = null;
    _acceptCustomerUpdates = false;
    _state = const MembershipState(kind: MembershipKind.unavailable);
    _notify();
    return _enqueueIdentity(_clearSdkIdentity);
  }

  Future<void> _clearSdkIdentity() async {
    await initialize();
    if (!_enabled) return;
    try {
      await _adapter.logOut().timeout(const Duration(seconds: 3));
      _sdkUserId = null;
      _debug('identity_cleared');
    } catch (_) {
      _debug('identity_clear_failed');
    }
  }

  Future<void> _enqueueIdentity(Future<void> Function() operation) {
    final next = _identityQueue.then((_) => operation());
    _identityQueue = next.catchError((_) {});
    return next;
  }

  void _onCustomerInfo(CustomerInfoSnapshot info) {
    if (!_acceptCustomerUpdates || _userId == null || _role == null) return;
    _applyCustomerInfo(info, _role);
  }

  void _applyCustomerInfo(CustomerInfoSnapshot info, String? role) {
    final wasActive = _isActiveMembershipForRole(role);
    final valid = role == 'owner' ? 'boo_plus' : 'boo_pro';
    final other = role == 'owner' ? 'boo_pro' : 'boo_plus';
    if (info.activeEntitlements.contains(other))
      _debug('entitlement_role_mismatch');
    final incomingExpiry = info.expirationDates.containsKey(valid)
        ? info.expirationDates[valid]
        : null;
    final now = DateTime.now().toUtc();
    // Ignore an older active snapshot for the same identity. This prevents a
    // delayed monthly response from replacing a newer annual entitlement.
    if (_currentEntitlementExpiry != null &&
        incomingExpiry != null &&
        incomingExpiry.isBefore(_currentEntitlementExpiry!) &&
        _currentEntitlementExpiry!.isAfter(now)) {
      _debug('customer_info_stale');
      return;
    }
    // An empty cached snapshot must not remove a currently active entitlement.
    // The expiry timer or a fresh response after expiration performs removal.
    if (_currentEntitlementExpiry != null &&
        _currentEntitlementExpiry!.isAfter(now) &&
        !info.activeEntitlements.contains(valid)) {
      _debug('customer_info_stale');
      return;
    }
    final active = info.hasActive(valid, now);
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _clearExpiryMetadata();
    _currentEntitlementExpiry = active ? incomingExpiry : null;
    _state = MembershipState(
      kind: active
          ? (role == 'owner' ? MembershipKind.booPlus : MembershipKind.booPro)
          : MembershipKind.free,
    );
    if (active) _scheduleExpiry(info.expirationDates[valid], role);
    if (role == 'owner' && _state.kind == MembershipKind.booPlus) {
      _debug('membership_plus');
    } else if (role == 'provider' && _state.kind == MembershipKind.booPro) {
      _debug('membership_pro');
    } else if (info.activeEntitlements.contains(other)) {
      _debug('role_mismatch');
    } else if (wasActive) {
      _debug('entitlement_expired');
    } else {
      _debug('membership_free');
    }
    if (wasActive && !_isActiveMembershipForRole(role)) {
      _debug('entitlement_expired');
    }
    _notify();
  }

  void _scheduleExpiry(DateTime? expiry, String? role) {
    if (expiry == null || _userId == null || role == null) return;
    final epoch = _identityEpoch;
    final entitlement = role == 'owner' ? 'boo_plus' : 'boo_pro';
    _expiryEpoch = epoch;
    _expiryRole = role;
    _expiryEntitlement = entitlement;
    _expiryInstant = expiry;
    final delay = expiry.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) return;
    _expiryTimer = Timer(delay, () {
      if (epoch != _identityEpoch ||
          _userId == null ||
          _role != role ||
          _expiryEpoch != epoch ||
          _expiryRole != role ||
          _expiryEntitlement != entitlement ||
          _expiryInstant != expiry ||
          _currentEntitlementExpiry != expiry) {
        return;
      }
      _expiryTimer = null;
      _clearExpiryMetadata();
      _currentEntitlementExpiry = null;
      _state = const MembershipState(kind: MembershipKind.free);
      _notify();
      _debug('entitlement_expired');
      unawaited(refreshFresh());
    });
  }

  void _clearExpiryMetadata() {
    _expiryEpoch = null;
    _expiryRole = null;
    _expiryEntitlement = null;
    _expiryInstant = null;
  }

  bool _isActiveMembershipForRole(String? role) {
    return role == 'owner'
        ? _state.kind == MembershipKind.booPlus
        : role == 'provider' && _state.kind == MembershipKind.booPro;
  }

  void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _listeners.clear();
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) listener();
  }

  void _debug(String event) {
    if (kDebugMode) debugPrint('[revenuecat] $event');
  }
}
