import 'package:boo/screens/homepage.dart';
import 'package:flutter/material.dart';

class ServiceListPage extends StatelessWidget {
  final String serviceType;
  const ServiceListPage({Key? key, required this.serviceType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20.0),
        const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Chip(label: Text('Nearby')),
            Chip(label: Text('Popular')),
            Chip(label: Text('Last Visited')),
          ],
        ),
        const SizedBox(height: 20.0),
        ListTile(
          leading: Image.network('https://picsum.photos/250?image=5'),
          title: Text('$serviceType 1'),
          subtitle: const Text('Open 8AM - 9PM\nDistance: 2.3 km'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ServiceDetailsPage(serviceType: serviceType)),
            );
          },
        ),
        ListTile(
          leading: Image.network('https://picsum.photos/250?image=3'),
          title: Text('$serviceType 2'),
          subtitle: const Text('Open 8AM - 9PM\nDistance: 3.7 km'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ServiceDetailsPage(serviceType: serviceType)),
            );
          },
        ),
      ],
    );
  }
}