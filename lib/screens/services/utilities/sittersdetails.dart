import 'package:boo/screens/services/utilities/calendar.dart';
import 'package:flutter/material.dart';

class SitterDetailsPage extends StatelessWidget {
  const SitterDetailsPage({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sitter Details'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    'https://picsum.photos/250?image=6',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16.0,
                    right: 16.0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Suzi Hill',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('I like sweety pet'),
                          ],
                        ),
                        Column(
                          children: const [
                            Icon(Icons.star, color: Colors.amber),
                            Text('5.5'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.orange),
                          const SizedBox(width: 8.0),
                          const Expanded(
                            child: Text(
                                'Verified pet sitter\nShe is experienced and trustworthy.'),
                          ),
                          Image.network(
                            'https://picsum.photos/250?image=7',
                            width: 60,
                            height: 60,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const TabBarSection(),
                    const SizedBox(height: 16.0),
                    const PricingSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Send Request - \$20/hour'),
          ),
        ),
      ),
    );
  }
}

class TabBarSection extends StatelessWidget {
  const TabBarSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Availability'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                const OverviewTab(),
                const AvailabilityTab(),
                const ReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Features', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          leading: Icon(Icons.location_on),
          title: Text('1.7 km Distance'),
        ),
        ListTile(
          leading: Icon(Icons.timer),
          title: Text('3 years Experience'),
        ),
        ListTile(
          leading: Icon(Icons.pets),
          title: Text('245 Pets handled'),
        ),
        Text('Who am I', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Hi, my name is Suzi Hill. I am a professional pet sitter...'),
      ],
    );
  }
}

class AvailabilityTab extends StatelessWidget {
  const AvailabilityTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       
        AvailabilityCalendar(),
       
        
      ],
    );
  }
}

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://picsum.photos/250?image=11'),
          ),
          title: Text('Lucy'),
          subtitle: Text('It is a long established fact...'),
          trailing: Icon(Icons.star, color: Colors.amber),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://picsum.photos/250?image=12'),
          ),
          title: Text('White Snow'),
          subtitle: Text('Reader will be distracted...'),
          trailing: Icon(Icons.star, color: Colors.amber),
        ),
      ],
    );
  }
}

class PricingSection extends StatelessWidget {
  const PricingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More Services',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.nightlight_round),
          title: const Text('Night Sitting'),
          subtitle: const Text('\$22/day'),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('One Home Visit'),
          subtitle: const Text('\$16/night'),
        ),
        ListTile(
          leading: const Icon(Icons.cut),
          title: const Text('Grooming'),
          subtitle: const Text('\$14/hour'),
        ),
      ],
    );
  }
}
