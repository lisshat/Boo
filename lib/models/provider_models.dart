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
  final double price; // numeric value for API calls
  final int durationMins; // e.g. 60, 1440 etc
  final bool enabled;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.price,
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

enum BookingStatus { upcoming, completed, cancelled, pendingReschedule, reviewPending }

class BookingRecord {
  final String id;
  final String providerName;
  final String providerImageUrl;
  final String serviceName;
  final String priceLabel;
  final DateTime date;
  final String time;
  final BookingStatus status;

  const BookingRecord({
    required this.id,
    required this.providerName,
    required this.providerImageUrl,
    required this.serviceName,
    required this.priceLabel,
    required this.date,
    required this.time,
    required this.status,
  });

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    return BookingRecord(
      id: json['id'] as String,
      providerName: (json['providerName'] as String?) ?? '',
      providerImageUrl: '',
      serviceName: json['serviceName'] as String,
      priceLabel: _formatPrice((json['priceKsh'] as num).toDouble()),
      date: date,
      time: json['time'] as String,
      status: _parseStatus(json['status'] as String),
    );
  }

  static String _formatPrice(double price) {
    final p = price.toInt();
    if (p >= 1000) {
      return 'KSh ${p ~/ 1000},${(p % 1000).toString().padLeft(3, '0')}';
    }
    return 'KSh $p';
  }

  static BookingStatus _parseStatus(String s) {
    switch (s) {
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending_reschedule':
        return BookingStatus.pendingReschedule;
      case 'review_pending':
        return BookingStatus.reviewPending;
      default:
        return BookingStatus.upcoming;
    }
  }
}
