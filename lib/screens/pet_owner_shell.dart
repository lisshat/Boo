import 'package:boo/screens/pet_owner/bookings_page.dart';
import 'package:boo/screens/pet_owner/chat_page.dart';
import 'package:boo/screens/pet_owner/home_dashboard.dart';
import 'package:boo/screens/pet_owner/profile_page.dart';

import 'package:flutter/material.dart';


class PetOwnerShell extends StatefulWidget {
  const PetOwnerShell({super.key});

  @override
  State<PetOwnerShell> createState() => _PetOwnerShellState();
}

class _PetOwnerShellState extends State<PetOwnerShell> {
  int _index = 0;

  final _pages = const [
    HomeDashboardPage(),
    BookingsPage(),
    ChatPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Book'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
