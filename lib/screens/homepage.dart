import 'package:flutter/material.dart';
import 'dart:math';

import 'services/sitters.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> petCareTips = [
      "Ensure your pet gets plenty of water daily.",
      "Regular grooming keeps your pet healthy and happy.",
      "Daily exercise is essential for your pet's wellbeing.",
      "Keep up with your pet's vaccinations and checkups.",
    ];

    List<String> petFacts = [
      "Cats spend 70% of their lives sleeping.",
      "Dogs can learn over 1000 words.",
      "Goldfish have a memory span of months, not seconds.",
      "Rabbits can see nearly 360 degrees around them."
    ];

    String randomTip = petCareTips[Random().nextInt(petCareTips.length)];
    String randomFact = petFacts[Random().nextInt(petFacts.length)];

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Pet Care Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage('https://picsum.photos/250?image=7'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('My Pets'),
              onTap: () {},
            ),
            ExpansionTile(
              title: const Text('Services'),
              children: [
                ListTile(
                  title: const Text('Vets/Clinics'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ClinicPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Groomers'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroomerPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Sitters'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SitterPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back, [User Name]!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Your Pets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage('https://picsum.photos/250?image=6'),
                            radius: 30,
                          ),
                          SizedBox(height: 10.0),
                          Text('Bella',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Dog - Golden Retriever'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Card(
                    color: Colors.green[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage('https://picsum.photos/250?image=8'),
                            radius: 30,
                          ),
                          SizedBox(height: 10.0),
                          Text('Milo',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Cat - Siamese'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Upcoming Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Grooming - Bella'),
              subtitle: const Text('Today at 3:00 PM'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Vet Checkup - Milo'),
              subtitle: const Text('Tomorrow at 10:00 AM'),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Pet Care Tip of the Day',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Card(
              color: Colors.orange[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  randomTip,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Did You Know?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Card(
              color: Colors.purple[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  randomFact,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }
}

class ClinicPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Clinic')),
      body: const Center(
          child: Text('Clinic Page')), // Replace with your desired layout
    );
  }
}

class GroomerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Groomer')),
      body: const Center(
          child: Text('Groomer Page')), // Replace with your desired layout
    );
  }
}


class ServiceDetailsPage extends StatelessWidget {
  final String serviceType;
  const ServiceDetailsPage({Key? key, required this.serviceType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$serviceType Details')),
      body: const Center(child: Text('Service Details Page')),
    );
  }
}
