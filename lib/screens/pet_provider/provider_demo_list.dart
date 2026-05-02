import 'package:flutter/material.dart';
import '../../models/provider_models.dart';
import 'provider_profile_screen.dart';

class ProviderDemoList extends StatelessWidget {
  const ProviderDemoList({super.key});

  List<ProviderModel> demoProviders() {
    return [
      ProviderModel(
        id: "1aec8c16-daa0-4b4b-b92d-a250f07724ae",
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
            id: "d065406d-111b-4763-80d8-c1b07446b03a",
            title: "Overnight Boarding",
            subtitle: "Per night • Food included",
            priceLabel: "KSh 1,500",
            price: 1500,
            durationMins: 1440,
          ),
          ServiceModel(
            id: "53d6d24a-2633-437b-86e5-6bc059fcf726",
            title: "Day Boarding",
            subtitle: "Per day • Pickup optional",
            priceLabel: "KSh 800",
            price: 800,
            durationMins: 480,
          ),
          ServiceModel(
            id: "6850c4d3-6a4f-47a7-94af-aff6e1d88a85",
            title: "Medication Add-on",
            subtitle: "Administer meds as instructed",
            priceLabel: "KSh 200",
            price: 200,
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
        id: "b6ce914a-245d-4951-9470-fb7df8e642fe",
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
            id: "b5f656b6-c9ff-4934-bb17-ea71598d0f8f",
            title: "Full Grooming",
            subtitle: "Bath • trim • ear clean",
            priceLabel: "KSh 1,200",
            price: 1200,
            durationMins: 90,
          ),
          ServiceModel(
            id: "1f71149e-79b8-489d-b559-a5e1451a86a6",
            title: "Nail Trim",
            subtitle: "Quick clean trim",
            priceLabel: "KSh 300",
            price: 300,
            durationMins: 15,
          ),
        ],
        reviews: const [],
      ),
      ProviderModel(
        id: "0b61ffe2-c262-4b18-ba02-6be7044155f4",
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
            id: "305c58e6-d566-4d1a-87a7-fb5ee2b5754e",
            title: "Drop-in Visit",
            subtitle: "Feed • clean • playtime",
            priceLabel: "KSh 500",
            price: 500,
            durationMins: 30,
          ),
          ServiceModel(
            id: "28914644-3d3f-4a40-86be-880d5d0a54cc",
            title: "House Sitting",
            subtitle: "Overnight presence",
            priceLabel: "KSh 2,000",
            price: 2000,
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
