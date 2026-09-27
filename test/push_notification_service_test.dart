import 'package:flutter_test/flutter_test.dart';
import 'package:boo/services/push_notification_service.dart';

class _FakePushAdapter implements PushNotificationAdapter {
  int initializeCalls = 0;
  final loginIds = <String>[];
  int logoutCalls = 0;
  int permissionRequests = 0;
  int settingsRequests = 0;
  PushPermissionSnapshot permissionSnapshot = const PushPermissionSnapshot(
    osPermissionGranted: false,
    canRequest: true,
    optedIn: null,
  );
  void Function(Map<String, dynamic>)? clickListener;

  @override
  Future<void> initialize(String appId) async {
    initializeCalls++;
  }

  @override
  Future<void> login(String externalId) async {
    loginIds.add(externalId);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  void addClickListener(void Function(Map<String, dynamic>) listener) {
    clickListener = listener;
  }

  @override
  Future<PushPermissionSnapshot> readPermissionState() async =>
      permissionSnapshot;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    permissionSnapshot = const PushPermissionSnapshot(
      osPermissionGranted: true,
      canRequest: false,
      optedIn: true,
    );
    return true;
  }

  @override
  Future<bool> openSettings() async {
    settingsRequests++;
    return true;
  }
}

void main() {
  const userId = 'c4187fb8-cc79-4906-ba00-917760c54089';
  const bookingId = '5a9326fa-3d78-4296-8b41-6e574361a066';

  test('missing App ID disables push without initializing the adapter',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: '');

    await service.initialize();

    expect(service.enabled, isFalse);
    expect(adapter.initializeCalls, 0);
  });

  test('initialization is idempotent and associates only the Boo UUID',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: 'app-id');

    await Future.wait([service.initialize(), service.initialize()]);
    await service.associateUser(userId);
    await service.associateUser(userId);
    await service.associateUser('owner@example.com');

    expect(adapter.initializeCalls, 1);
    expect(adapter.loginIds, [userId]);
  });

  test('valid review intent is retained and malformed intent is rejected',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: 'app-id');
    await service.initialize();

    adapter.clickListener!({'type': 'review_booking', 'bookingId': bookingId});
    expect(service.takePendingIntent()?.bookingId, bookingId);
    expect(service.takePendingIntent(), isNull);

    adapter.clickListener!({'type': 'unknown', 'bookingId': bookingId});
    adapter.clickListener!({'type': 'review_booking', 'bookingId': 'bad'});
    expect(service.takePendingIntent(), isNull);
  });

  test('logout cleanup delegates to the adapter and clears pending identity',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: 'app-id');
    await service.initialize();
    await service.associateUser(userId);
    adapter.clickListener!({'type': 'review_booking', 'bookingId': bookingId});

    await service.clearIdentity();

    expect(adapter.logoutCalls, 1);
    expect(service.takePendingIntent(), isNull);
  });

  test('permission request is serialized and refreshes granted state',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: 'app-id');

    final results = await Future.wait([
      service.requestPermission(),
      service.requestPermission(),
    ]);

    expect(results, [true, true]);
    expect(adapter.permissionRequests, 1);
    expect(
      (await service.readPermissionState()).state,
      PushPermissionState.enabled,
    );
  });

  test('permission state distinguishes requestable and settings-required',
      () async {
    final adapter = _FakePushAdapter();
    final service = PushNotificationService(adapter: adapter, appId: 'app-id');
    await service.initialize();

    expect(
      (await service.readPermissionState()).state,
      PushPermissionState.notRequested,
    );
    adapter.permissionSnapshot = const PushPermissionSnapshot(
      osPermissionGranted: false,
      canRequest: false,
      optedIn: false,
    );
    expect(
      (await service.readPermissionState()).state,
      PushPermissionState.settingsRequired,
    );
  });
}
