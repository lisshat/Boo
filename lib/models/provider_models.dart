enum ProviderType { boarding, sitter, groomer, vet }

class ProviderModel {
  final String id;
  final String name;
  final ProviderType type;
  final String imageUrl;
  final String about;
  final double rating;
  final int reviewCount;

  /// Example: ["ID verified", "Home boarding", "Emergency contact"]
  final List<String> trustBadges;

  /// Simple location fields for MVP
  final String locationName; // e.g. "Ruiru, Kiambu"
  final String addressLine; // e.g. "Near Spur Mall"

  final bool isVerified;

  final List<ServiceModel> services;
  final List<ReviewModel> reviews;

  const ProviderModel({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.about,
    required this.rating,
    required this.reviewCount,
    required this.trustBadges,
    required this.locationName,
    required this.addressLine,
    required this.isVerified,
    required this.services,
    required this.reviews,
  });
}

class ServiceModel {
  final String id;
  final String title; // "Overnight Boarding"
  final String subtitle; // "Per night • Food included"
  final String priceLabel; // "KSh 1,500"
  final int durationMins; // e.g. 60, 1440 etc
  final bool enabled;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.durationMins,
    this.enabled = true,
  });
}

class ReviewModel {
  final String id;
  final String reviewerName;
  final String comment;
  final double rating;

  const ReviewModel({
    required this.id,
    required this.reviewerName,
    required this.comment,
    required this.rating,
  });
}
