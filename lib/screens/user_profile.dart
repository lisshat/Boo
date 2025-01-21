import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage:
                      NetworkImage('https://picsum.photos/250?image=11'),
                ),
                title: const Text(
                  'Hi, Kristin Watson',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('watson_kristy@gmail.com'),
              ),
            ),
            const SizedBox(height: 20.0),

            // Your Pets Section
            _buildSectionHeader(context, 'Your pets', () {}),
            const SizedBox(height: 10.0),
            _buildPetsSection(),
            const SizedBox(height: 20.0),

            // Pet Care Nearby Section
            _buildSectionHeader(context, 'Pet Care Nearby', () {}),
            const SizedBox(height: 10.0),
            _buildPetCareNearby(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('See all'),
        ),
      ],
    );
  }

  // Pets Section
  Widget _buildPetsSection() {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://picsum.photos/250?image=8'),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Charlie',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'American Pit Bull Terrier',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://picsum.photos/250?image=7'),
                  ),
                  SizedBox(height: 8.0),
                  Text('Roxy', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Norwegian Forest cat'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Pet Care Nearby Section
  Widget _buildPetCareNearby() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage:
                      NetworkImage('https://picsum.photos/250?image=6'),
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Animal Pet Care',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16.0, color: Colors.grey),
                          Text('1.3 km', style: TextStyle(color: Colors.grey)),
                          SizedBox(width: 10.0),
                          Icon(Icons.star, size: 16.0, color: Colors.amber),
                          Text('4.2', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              children: const [
                Chip(label: Text('Bathing')),
                SizedBox(width: 8.0),
                Chip(label: Text('Nail')),
                SizedBox(width: 8.0),
                Chip(label: Text('Teeth')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
