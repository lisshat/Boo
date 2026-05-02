import 'package:boo/screens/pet_owner/book_appointment_screen.dart';
import 'package:flutter/material.dart';
import '../../models/provider_models.dart';

class ProviderProfileScreen extends StatelessWidget {
  final ProviderModel provider;

  const ProviderProfileScreen({
    super.key,
    required this.provider,
  });

  static const Color booOrange = Color(0xFFF68B1F);
  static const Color bg = Color(0xFFF6F7FB);

  String _providerTypeLabel(ProviderType t) {
    switch (t) {
      case ProviderType.boarding:
        return "Boarding";
      case ProviderType.sitter:
        return "Pet Sitter";
      case ProviderType.groomer:
        return "Groomer";
      case ProviderType.vet:
        return "Vet/Clinic";
    }
  }

  String _ctaLabel(ProviderType t) {
    switch (t) {
      case ProviderType.boarding:
        return "Request Boarding";
      case ProviderType.sitter:
        return "Request Sitting";
      case ProviderType.groomer:
        return "Book Grooming";
      case ProviderType.vet:
        return "Request Appointment";
    }
  }

  IconData _serviceIcon(ProviderType t) {
    switch (t) {
      case ProviderType.boarding:
        return Icons.home_rounded;
      case ProviderType.sitter:
        return Icons.directions_walk_rounded;
      case ProviderType.groomer:
        return Icons.content_cut_rounded;
      case ProviderType.vet:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _providerTypeLabel(provider.type);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          typeLabel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: "Favorite",
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: "Share",
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            ProviderHeaderCard(provider: provider),
            const SizedBox(height: 12),
            TrustBadgesRow(
              badges: provider.trustBadges,
              isVerified: provider.isVerified,
            ),
            const SizedBox(height: 16),
            SectionTitle(title: "About"),
            const SizedBox(height: 8),
            Text(
              provider.about,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(title: "Services & Pricing"),
            const SizedBox(height: 10),
            ...provider.services.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ServiceCard(
                  icon: _serviceIcon(provider.type),
                  service: s,
                  onTap: s.enabled
                      ? () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => BookAppointmentScreen(
                              provider: provider,
                              service: s,
                            ),
                          ));
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(title: "Location"),
            const SizedBox(height: 10),
            LocationCard(
              locationName: provider.locationName,
              addressLine: provider.addressLine,
              onViewMap: () {
                // MVP: open map later
              },
            ),
            const SizedBox(height: 16),
            SectionTitle(
              title: "Reviews",
              trailing: TextButton(
                onPressed: () {},
                child: const Text("See all"),
              ),
            ),
            const SizedBox(height: 8),
            ReviewPreviewCard(provider: provider),
            const SizedBox(height: 8),
          ],
        ),
      ),

      // Sticky CTA
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final first = provider.services
                        .where((s) => s.enabled)
                        .toList();
                    if (first.isEmpty) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(
                        provider: provider,
                        service: first.first,
                      ),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: booOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _ctaLabel(provider.type),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderHeaderCard extends StatelessWidget {
  final ProviderModel provider;

  const ProviderHeaderCard({super.key, required this.provider});

  static const Color booOrange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              provider.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.pets, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (provider.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: booOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "VERIFIED",
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w900,
                            color: booOrange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "(${provider.reviewCount})",
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        provider.locationName,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrustBadgesRow extends StatelessWidget {
  final List<String> badges;
  final bool isVerified;

  const TrustBadgesRow({
    super.key,
    required this.badges,
    required this.isVerified,
  });

  static const Color booOrange = Color(0xFFF68B1F);

  @override
  Widget build(BuildContext context) {
    final all = <String>[
      if (isVerified) "Boo Verified",
      ...badges,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((b) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded,
                  size: 16, color: booOrange.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(
                b,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.service,
    required this.onTap,
  });

  static const Color booOrange = Color(0xFFF68B1F);

  String _durationLabel(int mins) {
    if (mins >= 1440) {
      final days = (mins / 1440).round();
      return "$days day${days == 1 ? "" : "s"}";
    }
    if (mins >= 60) {
      final hours = (mins / 60).round();
      return "$hours hr${hours == 1 ? "" : "s"}";
    }
    return "$mins min";
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !service.enabled;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF9FAFB) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: booOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: booOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: disabled
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.subtitle,
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFFB0B7C3)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.priceLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: disabled ? const Color(0xFFB0B7C3) : booOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _durationLabel(service.durationMins),
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final String locationName;
  final String addressLine;
  final VoidCallback onViewMap;

  const LocationCard({
    super.key,
    required this.locationName,
    required this.addressLine,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.map_rounded, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  addressLine,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewMap,
            child: const Text("View on map"),
          ),
        ],
      ),
    );
  }
}

class ReviewPreviewCard extends StatelessWidget {
  final ProviderModel provider;
  const ReviewPreviewCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasReviews = provider.reviews.isNotEmpty;
    final top = hasReviews ? provider.reviews.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: hasReviews
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      top!.reviewerName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(top.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  top.comment,
                  style:
                      const TextStyle(color: Color(0xFF4B5563), height: 1.35),
                ),
              ],
            )
          : const Text(
              "No reviews yet. Be the first to book and leave feedback.",
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
    );
  }
}
