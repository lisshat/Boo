import 'package:boo/screens/pet_provider/provider_demo_list.dart';
import 'package:boo/screens/pet_provider/recommended_provider_card.dart';
import 'package:flutter/material.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static const orange = Color(0xFFF68B1F);
  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello, Imani 👋',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to pamper your pet?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 18,
                backgroundImage:
                    NetworkImage('https://picsum.photos/200?random=21'),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAECEF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Find vet, groomer, etc.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune, color: orange, size: 18),
                )
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Services row
          const Text(
            'Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ServiceChip(
                  icon: Icons.medical_services_outlined,
                  label: 'Vet',
                  onTap: () {},
                ),
                _ServiceChip(
                  icon: Icons.content_cut,
                  label: 'Groom',
                  onTap: () {},
                ),
                _ServiceChip(
                  icon: Icons.home_outlined,
                  label: 'Board',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Recommended header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recommended Near You',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All', style: TextStyle(color: orange)),
              )
            ],
          ),

          // Recommended Card
        ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ProviderDemoList().demoProviders().length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return RecommendedProviderCard(provider: ProviderDemoList().demoProviders()[index]);
            },
          )

        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAECEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: orange, size: 18),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final double rating;
  final VoidCallback onBook;

  const _RecommendedCard({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.onBook,
  });

  static const orange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=1200&auto=format&fit=crop',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('$rating',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      )
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Book',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
