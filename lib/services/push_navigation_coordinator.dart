import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/navigation_intent.dart';
import '../models/provider_models.dart';
import '../screens/pet_owner/leave_review_screen.dart';
import 'auth_service.dart';
import 'booking_service.dart';
import 'push_notification_service.dart';

typedef ReviewBookingResolver = Future<ReviewBookingResolution> Function(
    ReviewBookingIntent intent);
typedef ReviewBookingOpener = Future<void> Function(BookingRecord booking);

/// Resolves validated push clicks against current authenticated API state.
/// Push metadata is only a navigation hint; it is never authorization.
class PushNavigationCoordinator {
  PushNavigationCoordinator._({
    PushNotificationService? pushService,
    ReviewBookingResolver? resolver,
    ReviewBookingOpener? opener,
  })  : _pushService = pushService ?? PushNotificationService.instance,
        _resolver = resolver,
        _opener = opener;

  static final instance = PushNavigationCoordinator._();

  @visibleForTesting
  PushNavigationCoordinator.test({
    required PushNotificationService pushService,
    required ReviewBookingResolver resolver,
    required ReviewBookingOpener opener,
  }) : this._(pushService: pushService, resolver: resolver, opener: opener);

  Future<void>? _processing;
  bool _listenerAttached = false;
  String? _activeRole;
  final PushNotificationService _pushService;
  final ReviewBookingResolver? _resolver;
  final ReviewBookingOpener? _opener;

  void attach() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    _pushService.addPendingIntentListener(_onIntentReady);
  }

  void detach() {
    if (!_listenerAttached) return;
    _listenerAttached = false;
    _pushService.removePendingIntentListener(_onIntentReady);
  }

  void setAuthenticatedRole(String? role) {
    _activeRole = role;
    if (role == 'owner') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onIntentReady());
    }
  }

  void clearAuthentication() {
    _activeRole = null;
  }

  Future<void> processPendingIntent() async {
    _onIntentReady();
    await _processing;
  }

  void _onIntentReady() {
    if (_activeRole != 'owner') return;
    if (_opener == null && navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onIntentReady());
      return;
    }
    final existing = _processing;
    if (existing != null) {
      // A second callback for the same click must not queue a second screen.
      _pushService.takePendingIntent();
      return;
    }
    final work = _process();
    _processing = work;
    unawaited(work.whenComplete(() {
      if (identical(_processing, work)) _processing = null;
    }));
  }

  Future<void> _process() async {
    final service = _pushService;
    final processingEpoch = service.identityEpoch;
    final intent = service.takePendingIntent();
    if (intent == null) return;
    final navigator = navigatorKey.currentState;
    if (_opener == null && navigator == null) {
      // AuthGate can announce readiness during the same frame that creates
      // the shell. Leave the intent pending until the navigator exists.
      _pushService.retainPendingIntent(intent);
      WidgetsBinding.instance.addPostFrameCallback((_) => _onIntentReady());
      return;
    }

    try {
      final resolution = await (_resolver ?? _loadEligibleBooking)(intent);
      if (service.identityEpoch != processingEpoch || _activeRole != 'owner') {
        _debug('intent_invalidated');
        return;
      }
      if (resolution.alreadyReviewed) {
        _showMessage('You have already reviewed this booking.');
        return;
      }
      final booking = resolution.booking;
      if (booking == null) {
        _showMessage('This review request is no longer available.');
        return;
      }
      if (_activeRole != 'owner') return;
      _debug('intent_navigation_started');
      if (_opener != null) {
        await _opener(booking);
      } else if (navigator!.mounted) {
        await navigator.push<bool>(MaterialPageRoute(
          builder: (_) => LeaveReviewScreen(
            bookingId: booking.id,
            providerName: booking.providerName,
            serviceName: booking.serviceName,
          ),
        ));
      } else {
        return;
      }
      if (service.identityEpoch != processingEpoch) {
        _debug('intent_invalidated');
        return;
      }
      // Re-read authoritative state after returning. Existing screens own
      // their refresh; this prevents a stale push click from being replayed.
      await BookingService.instance.getBookings();
      _debug('intent_consumed');
    } on TimeoutException {
      if (service.identityEpoch != processingEpoch || _activeRole != 'owner') {
        return;
      }
      _showMessage('Could not load this review request. Please try again.');
      _debug('intent_failed_transiently');
    } catch (_) {
      if (service.identityEpoch != processingEpoch || _activeRole != 'owner') {
        return;
      }
      _showMessage('Could not load this review request. Please try again.');
      _debug('intent_failed_transiently');
    }
  }

  Future<ReviewBookingResolution> _loadEligibleBooking(
    ReviewBookingIntent intent,
  ) async {
    final response = await ApiService.instance
        .get('/bookings')
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const ReviewBookingResolution();
    final decoded = jsonDecode(response.body);
    final raw = decoded is List<dynamic>
        ? decoded
        : ((decoded as Map<String, dynamic>)['bookings'] ??
            decoded['data'] ??
            const <dynamic>[]) as List<dynamic>;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final id =
          (item['bookingId'] ?? item['booking_id'] ?? item['id'])?.toString();
      if (id != intent.bookingId) continue;
      final booking = BookingRecord.fromJson(item);
      if (booking.hasReview) {
        return const ReviewBookingResolution(alreadyReviewed: true);
      }
      if (booking.status != BookingStatus.completed) {
        return const ReviewBookingResolution();
      }
      if (booking.providerName.trim().isEmpty ||
          booking.serviceName.trim().isEmpty) {
        return const ReviewBookingResolution();
      }
      return ReviewBookingResolution(booking: booking);
    }
    return const ReviewBookingResolution();
  }

  void _showMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _debug(String event) {
    if (kDebugMode) debugPrint('[push] $event');
  }
}

class ReviewBookingResolution {
  const ReviewBookingResolution({this.booking, this.alreadyReviewed = false});

  final BookingRecord? booking;
  final bool alreadyReviewed;
}
