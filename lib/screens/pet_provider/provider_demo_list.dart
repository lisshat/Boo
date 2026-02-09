import 'package:flutter/material.dart';
import '../../models/provider_models.dart';
import 'provider_profile_screen.dart';

class ProviderDemoList extends StatelessWidget {
  const ProviderDemoList({super.key});

  List<ProviderModel> demoProviders() {
    return [
      ProviderModel(
        id: "p1",
        name: "Paws & Whiskers Boarding",
        type: ProviderType.boarding,
        imageUrl: "https://picsum.photos/200?random=31",
        about:
            "Safe home-based boarding with daily updates, flexible drop-off times, and a calm environment. Ideal for weekend stays and travel.",
        rating: 4.8,
        reviewCount: 124,
        trustBadges: const ["ID verified", "Home boarding", "Daily updates"],
        locationName: "Ruiru, Kiambu",
        addressLine: "Near Spur Mall",
        isVerified: true,
        services: const [
          ServiceModel(
            id: "s1",
            title: "Overnight Boarding",
            subtitle: "Per night • Food included",
            priceLabel: "KSh 1,500",
            durationMins: 1440,
          ),
          ServiceModel(
            id: "s2",
            title: "Day Boarding",
            subtitle: "Per day • Pickup optional",
            priceLabel: "KSh 800",
            durationMins: 480,
          ),
          ServiceModel(
            id: "s3",
            title: "Medication Add-on",
            subtitle: "Administer meds as instructed",
            priceLabel: "KSh 200",
            durationMins: 15,
          ),
        ],
        reviews: const [
          ReviewModel(
            id: "r1",
            reviewerName: "Amina",
            comment:
                "My dog settled in quickly. I got updates and photos daily. Would book again!",
            rating: 4.9,
          ),
        ],
      ),
      ProviderModel(
        id: "p2",
        name: "Kipepeo Grooming Studio",
        type: ProviderType.groomer,
        imageUrl: "https://picsum.photos/200?random=22",
        about:
            "Gentle grooming for dogs and cats. Clean tools, calm handling, and styling options based on coat type.",
        rating: 4.6,
        reviewCount: 63,
        trustBadges: const ["Credentials uploaded", "7+ years experience"],
        locationName: "Kasarani, Nairobi",
        addressLine: "Next to Total Station",
        isVerified: false,
        services: const [
          ServiceModel(
            id: "g1",
            title: "Full Grooming",
            subtitle: "Bath • trim • ear clean",
            priceLabel: "KSh 1,200",
            durationMins: 90,
          ),
          ServiceModel(
            id: "g2",
            title: "Nail Trim",
            subtitle: "Quick clean trim",
            priceLabel: "KSh 300",
            durationMins: 15,
          ),
        ],
        reviews: const [],
      ),
      ProviderModel(
        id: "p3",
        name: "Nia Pet Sitting",
        type: ProviderType.sitter,
        imageUrl: "https://picsum.photos/200?random=44",
        about:
            "Drop-in visits and feeding help for cats and small dogs. Great for busy schedules and short trips.",
        rating: 4.7,
        reviewCount: 41,
        trustBadges: const ["ID verified", "Cats & small dogs"],
        locationName: "Lang'ata, Nairobi",
        addressLine: "Near Bomas",
        isVerified: true,
        services: const [
          ServiceModel(
            id: "ps1",
            title: "Drop-in Visit",
            subtitle: "Feed • clean • playtime",
            priceLabel: "KSh 500",
            durationMins: 30,
          ),
          ServiceModel(
            id: "ps2",
            title: "House Sitting",
            subtitle: "Overnight presence",
            priceLabel: "KSh 2,000",
            durationMins: 1440,
          ),
        ],
        reviews: const [
          ReviewModel(
            id: "r2",
            reviewerName: "Kevin",
            comment:
                "Very reliable. My cats were calm and fed properly. Easy communication.",
            rating: 4.8,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final providers = demoProviders();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Providers (Demo)"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = providers[i];
          return ListTile(
            tileColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.imageUrl,
                  width: 44, height: 44, fit: BoxFit.cover),
            ),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle:
                Text("${p.locationName} • ${p.rating.toStringAsFixed(1)}"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfileScreen(provider: p),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
