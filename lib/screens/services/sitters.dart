import 'package:flutter/material.dart';

class SitterPage extends StatelessWidget {
  const SitterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return const SitterFilterPanel();
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SitterCard(
            name: 'Suzi Hill',
            description: 'I like sweety pet',
            distance: '1.4 km away',
            price: '\$20/hour',
            rating: '5.5',
            verified: true,
            imageUrl: 'https://picsum.photos/250?image=2',
            onTap: () {
              Navigator.pushNamed(context, '/sitter-details');
            },
          ),
          SitterCard(
            name: 'Amanda Ly',
            description: 'Professional pet lover',
            distance: '1.7 km away',
            price: '\$22/hour',
            rating: '5.5',
            verified: true,
            imageUrl: 'https://picsum.photos/250?image=3',
            onTap: () {
            },
          ),
          SitterCard(
            name: 'Merry An',
            description: 'I like sweety pet',
            distance: '2.6 km away',
            price: '\$25/hour',
            rating: '5.5',
            verified: false,
            imageUrl: 'https://picsum.photos/250?image=4',
            onTap: () {
            },
          ),
          SitterCard(
            name: 'Harry Samit',
            description: 'I like sweety pet',
            distance: '3.7 km away',
            price: '\$30/hour',
            rating: '4.6',
            verified: true,
            imageUrl: 'https://picsum.photos/250?image=13',
            onTap: () {
            },
          ),
        ],
      ),
    );
  }
}

class SitterCard extends StatelessWidget {
  final String name;
  final String description;
  final String distance;
  final String price;
  final String rating;
  final bool verified;
  final String imageUrl;
  final VoidCallback onTap;

  const SitterCard({
    Key? key,
    required this.name,
    required this.description,
    required this.distance,
    required this.price,
    required this.rating,
    required this.verified,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          radius: 30,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text(distance),
            Row(
              children: [
                if (verified)
                  const Icon(Icons.verified, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(rating, style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ],
        ),
        trailing:
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }
}

class SitterFilterPanel extends StatelessWidget {
  const SitterFilterPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pets', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(label: const Text('All'), onSelected: (value) {}),
              FilterChip(label: const Text('Dog'), onSelected: (value) {}),
              FilterChip(label: const Text('Cat'), onSelected: (value) {}),
              FilterChip(label: const Text('Fish'), onSelected: (value) {}),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(label: const Text('All'), onSelected: (value) {}),
              FilterChip(label: const Text('Pup'), onSelected: (value) {}),
              FilterChip(label: const Text('Young'), onSelected: (value) {}),
              FilterChip(label: const Text('Adult'), onSelected: (value) {}),
              FilterChip(label: const Text('Senior'), onSelected: (value) {}),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text('Search radius',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: 10.0,
            min: 0.0,
            max: 50.0,
            divisions: 10,
            label: '10 km',
            onChanged: (value) {},
          ),
          const SizedBox(height: 16.0),
          const Text('Price radius',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: 20.0,
            min: 0.0,
            max: 100.0,
            divisions: 10,
            label: '\$20/hour',
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
