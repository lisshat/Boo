import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../models/navigation_intent.dart';

/// Small adapter boundary around the native OneSignal singleton.
abstract class PushNotificationAdapter {
  Future<void> initialize(String appId);
  Future<void> login(String externalId);
  Future<void> logout();
  void addClickListener(void Function(Map<String, dynamic>) listener);
  Future<PushPermissionSnapshot> readPermissionState();
  Future<bool> requestPermission();
  Future<bool> openSettings();
}

enum PushPermissionState {
  unavailable,
  notRequested,
  enabled,
  deniedRequestable,
  settingsRequired,
}

class PushPermissionSnapshot {
  const PushPermissionSnapshot({
    required this.osPermissionGranted,
    required this.canRequest,
    required this.optedIn,
    this.state,
  });

  final bool osPermissionGranted;
  final bool canRequest;
  final bool? optedIn;
  final PushPermissionState? state;
}

class OneSignalPushNotificationAdapter implements PushNotificationAdapter {
  @override
  Future<void> initialize(String appId) => OneSignal.initialize(appId);

  @override
  Future<void> login(String externalId) => OneSignal.login(externalId);

  @override
  Future<void> logout() => OneSignal.logout();

  @override
  void addClickListener(void Function(Map<String, dynamic>) listener) {
    OneSignal.Notifications.addClickListener((event) {
      listener(event.notification.additionalData ?? const {});
    });
  }

  @override
  Future<PushPermissionSnapshot> readPermissionState() async {
    final permission = OneSignal.Notifications.permission;
    final canRequest = await OneSignal.Notifications.canRequest();
    return PushPermissionSnapshot(
      osPermissionGranted: permission,
      canRequest: canRequest,
      optedIn: OneSignal.User.pushSubscription.optedIn,
    );
  }

  @override
  Future<bool> requestPermission() =>
      OneSignal.Notifications.requestPermission(false);

  @override
  Future<bool> openSettings() =>
      OneSignal.Notifications.requestPermission(true);
}

class PushNotificationService {
  PushNotificationService({PushNotificationAdapter? adapter, String? appId})
      : _adapter = adapter ?? OneSignalPushNotificationAdapter(),
        _appId = appId ?? const String.fromEnvironment('ONESIGNAL_APP_ID');

  static final instance = PushNotificationService();

  static final _bookingIdPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final PushNotificationAdapter _adapter;
  final String _appId;
  Future<void>? _initialization;
  bool _listenerRegistered = false;
  bool _enabled = false;
  ReviewBookingIntent? _pendingIntent;
  final _intentListeners = <VoidCallback>[];
  String? _associatedUserId;
  Future<bool>? _permissionRequest;
  int _identityEpoch = 0;

  bool get enabled => _enabled;
  int get identityEpoch => _identityEpoch;

  void addPendingIntentListener(VoidCallback listener) {
    if (!_intentListeners.contains(listener)) _intentListeners.add(listener);
  }

  void removePendingIntentListener(VoidCallback listener) {
    _intentListeners.remove(listener);
  }

  Future<PushPermissionSnapshot> readPermissionState() async {
    if (_appId.trim().isEmpty) {
      return const PushPermissionSnapshot(
        osPermissionGranted: false,
        canRequest: false,
        optedIn: false,
        state: PushPermissionState.unavailable,
      );
    }
    await initialize();
    if (!_enabled) {
      return const PushPermissionSnapshot(
        osPermissionGranted: false,
        canRequest: false,
        optedIn: false,
        state: PushPermissionState.unavailable,
      );
    }
    try {
      final raw = await _adapter
          .readPermissionState()
          .timeout(const Duration(seconds: 3));
      final state = raw.osPermissionGranted && raw.optedIn == true
          ? PushPermissionState.enabled
          : raw.canRequest
              ? (raw.optedIn == false
                  ? PushPermissionState.deniedRequestable
                  : PushPermissionState.notRequested)
              : PushPermissionState.settingsRequired;
      return PushPermissionSnapshot(
        osPermissionGranted: raw.osPermissionGranted,
        canRequest: raw.canRequest,
        optedIn: raw.optedIn,
        state: state,
      );
    } catch (_) {
      _debug('permission_state_failed');
      return const PushPermissionSnapshot(
        osPermissionGranted: false,
        canRequest: false,
        optedIn: false,
        state: PushPermissionState.unavailable,
      );
    }
  }

  Future<bool> requestPermission() {
    final existing = _permissionRequest;
    if (existing != null) return existing;
    final request = _requestPermissionOnce();
    _permissionRequest = request;
    unawaited(request.then(
      (_) {
        if (identical(_permissionRequest, request)) _permissionRequest = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_permissionRequest, request)) _permissionRequest = null;
      },
    ));
    return request;
  }

  Future<bool> _requestPermissionOnce() async {
    await initialize();
    if (!_enabled) return false;
    try {
      await _adapter.requestPermission().timeout(const Duration(seconds: 10));
      final state = await readPermissionState();
      return state.state == PushPermissionState.enabled;
    } catch (_) {
      _debug('permission_request_failed');
      return false;
    }
  }

  Future<bool> openNotificationSettings() async {
    await initialize();
    if (!_enabled) return false;
    try {
      await _adapter.openSettings().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      _debug('permission_settings_failed');
      return false;
    }
  }

  Future<void> initialize() {
    final existing = _initialization;
    if (existing != null) return existing;
    if (_appId.trim().isEmpty) {
      _debug('disabled_no_app_id');
      _initialization = Future<void>.value();
      return _initialization!;
    }
    final initialization = _initializeOnce();
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initializeOnce() async {
    try {
      await _adapter.initialize(_appId).timeout(const Duration(seconds: 4));
      _enabled = true;
      if (!_listenerRegistered) {
        _adapter.addClickListener(_handleClickPayload);
        _listenerRegistered = true;
      }
      _debug('initialized');
    } on TimeoutException {
      _debug('initialize_timeout');
    } catch (_) {
      _debug('initialize_failed');
    }
  }

  Future<void> associateUser(String? userUuid) async {
    final id = userUuid?.trim();
    if (id == null || !_isUuid(id)) return;
    await initialize();
    if (!_enabled || _associatedUserId == id) return;
    if (_associatedUserId != null && _associatedUserId != id) {
      _identityEpoch++;
      _pendingIntent = null;
      try {
        await _adapter.logout().timeout(const Duration(seconds: 2));
      } catch (_) {
        _debug('identity_switch_cleanup_failed');
      }
    }
    try {
      await _adapter.login(id).timeout(const Duration(seconds: 4));
      _associatedUserId = id;
      _debug('identity_associated');
    } on TimeoutException {
      _debug('identity_timeout');
    } catch (_) {
      _debug('identity_failed');
    }
  }

  Future<void> clearIdentity() async {
    _identityEpoch++;
    _associatedUserId = null;
    _pendingIntent = null;
    if (!_enabled) return;
    try {
      await _adapter.logout().timeout(const Duration(seconds: 2));
      _debug('identity_cleared');
    } on TimeoutException {
      _debug('identity_clear_timeout');
    } catch (_) {
      _debug('identity_clear_failed');
    }
  }

  ReviewBookingIntent? takePendingIntent() {
    final pending = _pendingIntent;
    _pendingIntent = null;
    return pending;
  }

  @visibleForTesting
  void retainPendingIntent(ReviewBookingIntent intent) {
    _pendingIntent ??= intent;
  }

  void _handleClickPayload(Map<String, dynamic> payload) {
    final type = payload['type']?.toString();
    final bookingId = payload['bookingId']?.toString().trim();
    if (type != ReviewBookingIntent.type ||
        bookingId == null ||
        !_isUuid(bookingId)) {
      _debug(type == ReviewBookingIntent.type
          ? 'intent_rejected_invalid_booking'
          : 'intent_rejected_unknown_type');
      return;
    }
    _pendingIntent = ReviewBookingIntent(bookingId: bookingId);
    for (final listener in List<VoidCallback>.from(_intentListeners)) {
      listener();
    }
    _debug('intent_accepted_review_booking');
  }

  bool _isUuid(String value) => _bookingIdPattern.hasMatch(value);

  void _debug(String event) {
    if (kDebugMode) debugPrint('[push] $event');
  }
}
