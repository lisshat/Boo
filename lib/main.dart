import 'package:boo/models/provider_models.dart';
import 'package:boo/screens/pet_owner_shell.dart';
import 'package:boo/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boo/screens/pet_provider/provider_profile_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://jvbssufhqujjxbjaaxyi.supabase.co',
    anonKey: 'sb_publishable_uE20DPTN76U_EvIX1Z7RcQ_EHJXgZqf',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const PetOwnerShell(),
        '/login': (context) => const BooAuthScreen(),
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
      title: 'Boo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
