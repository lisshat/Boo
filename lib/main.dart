import 'dart:async';

import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/auth.dart';
import 'package:boo/screens/auth/forgot_password_screen.dart';
import 'package:boo/screens/admin/admin_login_screen.dart';
import 'package:boo/screens/admin/admin_shell.dart';
import 'package:boo/screens/splash_screen.dart';
import 'package:boo/screens/tip_loading_screen.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:boo/screens/pet_provider/provider_profile_screen.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/screens/pet_provider/provider_shell.dart';
import 'package:boo/services/favorites_service.dart';
import 'package:boo/services/push_notification_service.dart';
import 'package:boo/services/push_navigation_coordinator.dart';
import 'package:boo/services/revenuecat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesManager.instance.load();
  runApp(const MyApp());
  // Push setup is optional and intentionally does not block startup routing.
  unawaited(PushNotificationService.instance.initialize());
  // RevenueCat Test Store setup is optional and never blocks authentication.
  unawaited(RevenueCatService.instance.initialize());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boo',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: kIsWeb
          ? const AdminLoginScreen()
          : const SplashScreen(next: _AuthGate()),
      routes: {
        '/login': (_) => const BooAuthScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/admin-login': (_) => const AdminLoginScreen(),
        '/admin': (_) => const AdminShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/reset-password') == true) {
          return MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
            settings: settings,
          );
        }
        if (settings.name == '/provider-profile') {
          final provider = settings.arguments as ProviderModel;
          return MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(provider: provider),
          );
        }
        return null;
      },
    );
  }
}

/// Checks secure storage for a JWT on startup and routes accordingly.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _getRole();
    PushNavigationCoordinator.instance.attach();
  }

  @override
  void dispose() {
    PushNavigationCoordinator.instance.detach();
    PushNavigationCoordinator.instance.clearAuthentication();
    super.dispose();
  }

  Future<String?> _getRole() async {
    final stopwatch = Stopwatch()..start();
    // Startup only reads local session metadata. Network restoration happens
    // lazily in the shell, so a transient network issue must not be treated
    // as invalid credentials here.
    final role = await _checkAuth();
    if (kDebugMode) {
      debugPrint(
          '[auth timing] route_ready ${stopwatch.elapsedMilliseconds}ms');
    }
    return role;
  }

  Future<String?> _checkAuth() async {
    final stopwatch = Stopwatch()..start();
    final hasToken = await AuthService.instance.hasValidToken();
    if (kDebugMode) {
      debugPrint(
          '[auth timing] stored_session_read ${stopwatch.elapsedMilliseconds}ms');
    }
    if (!hasToken) return null;
    unawaited(AuthService.instance.associateStoredPushIdentity());
    // Chat is optional during routing. Chat screens retry their own bounded
    // connection when opened, so a slow Stream service cannot hold the shell.
    return AuthService.instance.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const AdminLoginScreen();
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const TipLoadingScreen();
        }
        final role = snapshot.data;
        PushNavigationCoordinator.instance.setAuthenticatedRole(role);
        if (role == 'admin') return const AdminShell();
        if (role == 'provider') return const ProviderShell();
        if (role == 'owner') return const PetOwnerShell();
        return const BooAuthScreen();
      },
    );
  }
}
