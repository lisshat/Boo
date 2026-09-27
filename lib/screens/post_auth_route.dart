import 'dart:convert';

import 'package:boo/screens/admin/admin_shell.dart';
import 'package:boo/screens/auth.dart';
import 'package:boo/screens/pet_owner/onboarding/owner_onboarding_step1.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/screens/pet_provider/onboarding/provider_onboarding_step1.dart';
import 'package:boo/screens/pet_provider/provider_shell.dart';
import 'package:boo/services/auth_service.dart';
import 'package:boo/services/stream_chat_service.dart';
import 'package:flutter/material.dart';

enum _Destination {
  login,
  admin,
  owner,
  ownerOnboarding,
  provider,
  providerOnboarding
}

class _RouteError implements Exception {
  const _RouteError(this.message);
  final String message;
}

/// Resolves both fresh authentication and restored sessions from persisted data.
class PostAuthRoute extends StatefulWidget {
  const PostAuthRoute({
    super.key,
    this.isNewUser = false,
    this.restoreSession = false,
    this.loadingWidget,
  });

  final bool isNewUser;
  final bool restoreSession;
  final Widget? loadingWidget;

  @override
  State<PostAuthRoute> createState() => _PostAuthRouteState();
}

class _PostAuthRouteState extends State<PostAuthRoute> {
  late Future<_Destination> _destination;

  @override
  void initState() {
    super.initState();
    _destination = _resolveWithLoadingDelay();
  }

  Future<_Destination> _resolveWithLoadingDelay() async {
    final results = await Future.wait<Object?>([
      _resolve(),
      if (widget.restoreSession)
        Future<void>.delayed(const Duration(milliseconds: 2500)),
    ]);
    return results.first as _Destination;
  }

  Future<_Destination> _resolve() async {
    try {
      if (!await AuthService.instance.hasValidToken())
        return _Destination.login;
      if (widget.restoreSession) {
        await BooStreamChatService.instance.connectFromStoredSession();
      }
      final role = await AuthService.instance.getUserRole();
      if (role == 'admin') return _Destination.admin;
      if (role != 'owner' && role != 'provider') {
        throw const _RouteError(
          'Your account role is missing or unsupported. Please sign in again or contact support.',
        );
      }
      if (widget.isNewUser) {
        return role == 'owner'
            ? _Destination.ownerOnboarding
            : _Destination.providerOnboarding;
      }

      // ApiService performs the existing single refresh/retry on HTTP 401.
      final response = await ApiService.instance.get(
        role == 'owner' ? '/pets/me' : '/providers/me',
      );
      if (response.statusCode == 401) {
        await AuthService.instance.logout();
        return _Destination.login;
      }
      if (role == 'provider' && response.statusCode == 404) {
        return _Destination.providerOnboarding;
      }
      if (response.statusCode != 200) {
        throw _RouteError(
          'Could not load your account setup (HTTP ${response.statusCode}). Please retry.',
        );
      }
      if (role == 'provider') return _Destination.provider;
      final pets = jsonDecode(response.body);
      if (pets is! List) {
        throw const _RouteError(
            'The server returned invalid pet data. Please retry.');
      }
      return pets.isEmpty ? _Destination.ownerOnboarding : _Destination.owner;
    } catch (error) {
      // Failed refresh already clears storage and navigates to Login in ApiService.
      if (!await AuthService.instance.hasValidToken())
        return _Destination.login;
      if (error is _RouteError) rethrow;
      throw const _RouteError(
          'Could not load your account setup. Check your connection and retry.');
    }
  }

  void _retry() {
    setState(() => _destination = _resolveWithLoadingDelay());
  }

  Future<void> _signOut() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Destination>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingWidget ??
              const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          error is _RouteError
                              ? error.message
                              : 'Could not load your account setup. Please retry.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _retry, child: const Text('Retry')),
                      TextButton(
                          onPressed: _signOut, child: const Text('Sign out')),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        switch (snapshot.requireData) {
          case _Destination.login:
            return const BooAuthScreen();
          case _Destination.admin:
            return const AdminShell();
          case _Destination.owner:
            return const PetOwnerShell();
          case _Destination.ownerOnboarding:
            return const OwnerOnboardingStep1();
          case _Destination.provider:
            return const ProviderShell();
          case _Destination.providerOnboarding:
            return const ProviderOnboardingStep1();
        }
      },
    );
  }
}
