import 'package:flutter/foundation.dart';

import 'revenuecat_service.dart';

/// The premium catalogue is intentionally separate from RevenueCat product
/// identifiers. Product configuration can change without changing app policy.
enum PremiumFeature {
  additionalPetProfiles,
  petHealthTimeline,
  healthRecordExport,
  smartCareReminders,
  careLoopRebooking,
  advancedEarningsInsights,
  bookingAnalytics,
  privateClientNotes,
  automatedRebookingSuggestions,
  featuredListing,
}

enum PremiumAccessKind {
  allowed,
  requiresBooPlus,
  requiresBooPro,
  comingSoon,
  unavailable,
  roleMismatch,
  unauthenticated,
}

class PremiumAccessDecision {
  const PremiumAccessDecision(this.kind, {required this.feature});

  final PremiumAccessKind kind;
  final PremiumFeature feature;

  bool get allowed => kind == PremiumAccessKind.allowed;
}

class PremiumFeatureDefinition {
  const PremiumFeatureDefinition({required this.role});

  final String role;
}

class PremiumFeatureCatalogue {
  static const definitions = <PremiumFeature, PremiumFeatureDefinition>{
    PremiumFeature.additionalPetProfiles:
        PremiumFeatureDefinition(role: 'owner'),
    PremiumFeature.petHealthTimeline: PremiumFeatureDefinition(role: 'owner'),
    PremiumFeature.healthRecordExport: PremiumFeatureDefinition(role: 'owner'),
    PremiumFeature.smartCareReminders: PremiumFeatureDefinition(role: 'owner'),
    PremiumFeature.careLoopRebooking: PremiumFeatureDefinition(role: 'owner'),
    PremiumFeature.advancedEarningsInsights:
        PremiumFeatureDefinition(role: 'provider'),
    PremiumFeature.bookingAnalytics: PremiumFeatureDefinition(role: 'provider'),
    PremiumFeature.privateClientNotes:
        PremiumFeatureDefinition(role: 'provider'),
    PremiumFeature.automatedRebookingSuggestions:
        PremiumFeatureDefinition(role: 'provider'),
    PremiumFeature.featuredListing: PremiumFeatureDefinition(role: 'provider'),
  };

  static bool isAvailable(PremiumFeature feature) =>
      feature == PremiumFeature.additionalPetProfiles ||
      feature == PremiumFeature.advancedEarningsInsights;
}

class PremiumAccessEvaluator {
  const PremiumAccessEvaluator();

  PremiumAccessDecision evaluatePetCreation({
    required String? role,
    required MembershipState membership,
    required int petCount,
    bool authenticated = true,
  }) {
    if (!authenticated) {
      return const PremiumAccessDecision(
        PremiumAccessKind.unauthenticated,
        feature: PremiumFeature.additionalPetProfiles,
      );
    }
    if (role?.trim().toLowerCase() != 'owner') {
      return const PremiumAccessDecision(
        PremiumAccessKind.roleMismatch,
        feature: PremiumFeature.additionalPetProfiles,
      );
    }
    if (petCount <= 0) {
      return const PremiumAccessDecision(
        PremiumAccessKind.allowed,
        feature: PremiumFeature.additionalPetProfiles,
      );
    }
    return evaluate(
      role: role,
      membership: membership,
      feature: PremiumFeature.additionalPetProfiles,
      featureReady: true,
    );
  }

  PremiumAccessDecision evaluate({
    required String? role,
    required MembershipState membership,
    required PremiumFeature feature,
    bool authenticated = true,
    bool featureReady = true,
  }) {
    if (!authenticated) {
      return PremiumAccessDecision(PremiumAccessKind.unauthenticated,
          feature: feature);
    }
    final normalizedRole = role?.trim().toLowerCase();
    final definition = PremiumFeatureCatalogue.definitions[feature];
    if (normalizedRole != 'owner' && normalizedRole != 'provider') {
      return PremiumAccessDecision(PremiumAccessKind.roleMismatch,
          feature: feature);
    }
    if (definition == null || definition.role != normalizedRole) {
      return PremiumAccessDecision(PremiumAccessKind.roleMismatch,
          feature: feature);
    }
    if (!featureReady) {
      return PremiumAccessDecision(PremiumAccessKind.comingSoon,
          feature: feature);
    }
    if (membership.kind == MembershipKind.unavailable ||
        membership.kind == MembershipKind.loading ||
        membership.kind == MembershipKind.transientError) {
      return PremiumAccessDecision(PremiumAccessKind.unavailable,
          feature: feature);
    }
    final required = normalizedRole == 'owner'
        ? PremiumAccessKind.requiresBooPlus
        : PremiumAccessKind.requiresBooPro;
    final active = normalizedRole == 'owner'
        ? membership.kind == MembershipKind.booPlus
        : membership.kind == MembershipKind.booPro;
    if (active) {
      return PremiumAccessDecision(PremiumAccessKind.allowed, feature: feature);
    }
    if ((normalizedRole == 'owner' &&
            membership.kind == MembershipKind.booPro) ||
        (normalizedRole == 'provider' &&
            membership.kind == MembershipKind.booPlus)) {
      return PremiumAccessDecision(PremiumAccessKind.roleMismatch,
          feature: feature);
    }
    return PremiumAccessDecision(required, feature: feature);
  }
}

/// Reactive UI access state. It is deliberately not a backend authorization
/// mechanism; future premium APIs must check authoritative server entitlements.
class PremiumAccessController extends ChangeNotifier {
  PremiumAccessController({RevenueCatService? revenueCat})
      : _revenueCat = revenueCat ?? RevenueCatService.instance {
    _revenueCat.addListener(_onMembershipChanged);
  }

  static final instance = PremiumAccessController();

  final RevenueCatService _revenueCat;
  final PremiumAccessEvaluator evaluator = const PremiumAccessEvaluator();
  String? _role;
  bool _authenticated = false;

  String? get role => _role;
  bool get authenticated => _authenticated;
  MembershipState get membership => _authenticated
      ? _revenueCat.state
      : const MembershipState(kind: MembershipKind.unavailable);

  void setAuthenticatedRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    final valid = normalized == 'owner' || normalized == 'provider';
    final nextRole = valid ? normalized : null;
    final nextAuthenticated = nextRole != null;
    if (_role == nextRole && _authenticated == nextAuthenticated) return;
    _role = nextRole;
    _authenticated = nextAuthenticated;
    notifyListeners();
  }

  void clear() {
    if (!_authenticated && _role == null) return;
    _role = null;
    _authenticated = false;
    notifyListeners();
  }

  PremiumAccessDecision evaluate(PremiumFeature feature,
      {bool featureReady = true}) {
    return evaluator.evaluate(
      role: _role,
      membership: membership,
      feature: feature,
      authenticated: _authenticated,
      featureReady: featureReady,
    );
  }

  PremiumAccessDecision evaluatePetCreation(int petCount) =>
      evaluator.evaluatePetCreation(
        role: _role,
        membership: membership,
        petCount: petCount,
        authenticated: _authenticated,
      );

  void _onMembershipChanged() => notifyListeners();

  @override
  void dispose() {
    _revenueCat.removeListener(_onMembershipChanged);
    super.dispose();
  }
}
