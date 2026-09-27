import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:boo/models/navigation_intent.dart';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/push_navigation_coordinator.dart';
import 'package:boo/services/push_notification_service.dart';

class _Adapter implements PushNotificationAdapter {
  void Function(Map<String, dynamic>)? onClick;

  @override
  Future<void> initialize(String appId) async {}

  @override
  Future<void> login(String externalId) async {}

  @override
  Future<void> logout() async {}

  @override
  void addClickListener(void Function(Map<String, dynamic>) listener) {
    onClick = listener;
  }

  @override
  Future<PushPermissionSnapshot> readPermissionState() async =>
      const PushPermissionSnapshot(
        osPermissionGranted: false,
        canRequest: true,
        optedIn: null,
      );

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> openSettings() async => false;
}

BookingRecord _booking({bool hasReview = false}) => BookingRecord(
      id: '5a9326fa-3d78-4296-8b41-6e574361a066',
      providerId: 'c4187fb8-cc79-4906-ba00-917760c54089',
      providerName: 'Boo Provider',
      providerImageUrl: '',
      serviceName: 'Consultation',
      priceLabel: 'KSh 500',
      amount: 500,
      basePrice: 500,
      pricingUnit: 'per session',
      durationMinutes: 60,
      category: 'Vet',
      date: DateTime(2026, 9, 18),
      time: '9:00 AM',
      bookingDatetime: DateTime(2026, 9, 18, 9),
      status: BookingStatus.completed,
      hasReview: hasReview,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const bookingId = '5a9326fa-3d78-4296-8b41-6e574361a066';

  PushNavigationCoordinator makeCoordinator({
    required PushNotificationService service,
    required ReviewBookingResolver resolver,
    required ReviewBookingOpener opener,
  }) =>
      PushNavigationCoordinator.test(
        pushService: service,
        resolver: resolver,
        opener: opener,
      );

  test('eligible booking opens once and repeated readiness does not replay',
      () async {
    final adapter = _Adapter();
    final push = PushNotificationService(adapter: adapter, appId: 'app');
    await push.initialize();
    var opens = 0;
    final coordinator = makeCoordinator(
      service: push,
      resolver: (_) async => ReviewBookingResolution(booking: _booking()),
      opener: (_) async => opens++,
    );
    coordinator.setAuthenticatedRole('owner');
    adapter.onClick!({'type': 'review_booking', 'bookingId': bookingId});

    await coordinator.processPendingIntent();
    await coordinator.processPendingIntent();

    expect(opens, 1);
  });

  test('provider role does not process a review intent', () async {
    final adapter = _Adapter();
    final push = PushNotificationService(adapter: adapter, appId: 'app');
    await push.initialize();
    var opens = 0;
    final coordinator = makeCoordinator(
      service: push,
      resolver: (_) async => ReviewBookingResolution(booking: _booking()),
      opener: (_) async => opens++,
    );
    coordinator.setAuthenticatedRole('provider');
    adapter.onClick!({'type': 'review_booking', 'bookingId': bookingId});
    await coordinator.processPendingIntent();

    expect(opens, 0);
  });

  test('account switch invalidates an in-flight resolver before navigation',
      () async {
    final adapter = _Adapter();
    final push = PushNotificationService(adapter: adapter, appId: 'app');
    await push.initialize();
    final gate = Completer<ReviewBookingResolution>();
    var opens = 0;
    final coordinator = makeCoordinator(
      service: push,
      resolver: (_) => gate.future,
      opener: (_) async => opens++,
    );
    coordinator.setAuthenticatedRole('owner');
    adapter.onClick!({'type': 'review_booking', 'bookingId': bookingId});
    final processing = coordinator.processPendingIntent();
    await Future<void>.delayed(Duration.zero);
    await push.clearIdentity();
    gate.complete(ReviewBookingResolution(booking: _booking()));
    await processing;

    expect(opens, 0);
  });

  test('already-reviewed and unavailable resolutions do not open the form',
      () async {
    for (final resolution in const [
      ReviewBookingResolution(alreadyReviewed: true),
      ReviewBookingResolution(),
    ]) {
      final adapter = _Adapter();
      final push = PushNotificationService(adapter: adapter, appId: 'app');
      await push.initialize();
      var opens = 0;
      final coordinator = makeCoordinator(
        service: push,
        resolver: (_) async => resolution,
        opener: (_) async => opens++,
      );
      coordinator.setAuthenticatedRole('owner');
      adapter.onClick!({'type': 'review_booking', 'bookingId': bookingId});
      await coordinator.processPendingIntent();
      expect(opens, 0);
    }
  });
}
