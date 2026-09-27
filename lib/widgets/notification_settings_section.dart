import 'package:flutter/material.dart';

import '../services/push_notification_service.dart';

class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key, this.service});

  final PushNotificationService? service;

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  static const _orange = Color(0xFFF68B1F);
  late final PushNotificationService _service =
      widget.service ?? PushNotificationService.instance;
  PushPermissionSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    final snapshot = await _service.readPermissionState();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _explainAndRequest() async {
    if (_loading) return;
    final allow = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Stay updated with Boo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Get notified about booking requests, confirmations, service updates, reviews and important account activity.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Allow notifications'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
    if (allow != true || !mounted) return;
    await _refreshWithRequest();
  }

  Future<void> _refreshWithRequest() async {
    setState(() => _loading = true);
    await _service.requestPermission();
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openSettings() async {
    if (_loading) return;
    setState(() => _loading = true);
    await _service.openNotificationSettings();
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final state = snapshot?.state;
    final action = switch (state) {
      PushPermissionState.notRequested => 'Enable notifications',
      PushPermissionState.deniedRequestable => 'Try again',
      PushPermissionState.settingsRequired => 'Open settings',
      _ => null,
    };
    final subtitle = switch (state) {
      PushPermissionState.enabled => 'Notifications are enabled.',
      PushPermissionState.notRequested =>
        'Get booking and account updates even when Boo is closed.',
      PushPermissionState.deniedRequestable =>
        'Notifications are currently off.',
      PushPermissionState.settingsRequired =>
        'Notifications are disabled in your device settings.',
      PushPermissionState.unavailable =>
        'Push notifications are unavailable right now.',
      null => 'Checking notification settings…',
    };

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEAECEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_none_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle),
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : state == PushPermissionState.settingsRequired
                                ? _openSettings
                                : _explainAndRequest,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(action),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
