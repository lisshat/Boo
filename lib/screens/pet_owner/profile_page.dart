import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: InkWell(
                onTap: () {
                  // direct proof navigation works
                  Navigator.pushNamed(context, '/login');
                },
                child: const CircleAvatar(
                  backgroundImage:
                      NetworkImage('https://picsum.photos/200?random=5'),
                ),
              ),
              title: const Text('Hi, Imani',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Tap avatar to open Login'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Open Login Screen'),
            )
          ],
        ),
      ),
    );
  }
}
