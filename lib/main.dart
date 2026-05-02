import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/screens/auth.dart';
import 'package:boo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:boo/screens/pet_provider/provider_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const BooAuthScreen(),
      },
      onGenerateRoute: (settings) {
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
  late Future<bool> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = AuthService.instance.hasValidToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return const PetOwnerShell();
        return const BooAuthScreen();
      },
    );
  }
}
