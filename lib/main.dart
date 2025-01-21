
import 'package:flutter/material.dart';

import 'screens/homepage.dart';
import 'screens/services/utilities/sittersdetails.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/sitter-details': (context) => SitterDetailsPage(),
      },
      title: 'Boo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      
    );
  }
}

