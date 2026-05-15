enum ProviderType { boarding, sitter, groomer, vet }

class PetSummary {
  final String id;
  final String name;
  final String species;
  final String? photoUrl;

  const PetSummary({
    required this.id,
    required this.name,
    required this.species,
    this.photoUrl,
  });

  factory PetSummary.fromJson(Map<String, dynamic> json) => PetSummary(
        id: json['petId'] as String,
        name: json['name'] as String? ?? 'Pet',
        species: json['species'] as String? ?? 'other',
        photoUrl: json['photoUrl'] as String?,
      );
}

class ProviderModel {
  final String id;
  final String userId;
  final String name;
  final ProviderType type;
  final String imageUrl;
  final String about;
  final double rating;
  final int reviewCount;
  final List<String> trustBadges;
  final String locationName;
  final String addressLine;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final List<ServiceModel> services;
  final List<ReviewModel> reviews;

  const ProviderModel({
    required this.id,
    required this.userId,
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
    this.latitude,
    this.longitude,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List<dynamic>? ?? [])
        .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final firstCategory = services.isNotEmpty ? services.first.category : null;
    final user = json['user'] as Map<String, dynamic>?;

    return ProviderModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ??
          json['providerUserId'] as String? ??
          json['user_id'] as String? ??
          json['provider_user_id'] as String? ??
          user?['id'] as String? ??
          user?['userId'] as String? ??
          '',
      name: json['businessName'] as String? ?? 'Provider',
      type: _categoryToType(firstCategory),
      imageUrl: json['profilePhotoUrl'] as String? ??
          'https://picsum.photos/seed/${json['id']}/400/200',
      about: json['bio'] as String? ?? '',
      rating: double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      reviewCount: (json['totalReviews'] as int?) ?? 0,
      trustBadges:
          (json['isVerified'] as bool? ?? false) ? ['ID Verified'] : [],
      locationName: json['location'] as String? ?? 'Nairobi',
      addressLine: '',
      isVerified: json['isVerified'] as bool? ?? false,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      services: services,
      reviews: const [],
    );
  }

  static ProviderType _categoryToType(String? category) {
    switch (category) {
      case 'grooming':
        return ProviderType.groomer;
      case 'boarding':
        return ProviderType.boarding;
      case 'sitting':
        return ProviderType.sitter;
      case 'veterinary':
        return ProviderType.vet;
      default:
        return ProviderType.sitter;
    }
  }
}

class ServiceModel {
  final String id;
  final String title;
  final String subtitle;
  final String priceLabel;
  final double price;
  final int durationMins;
  final bool enabled;
  final String category;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.price,
    required this.durationMins,
    this.enabled = true,
    this.category = '',
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final price = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    final duration = (json['durationMinutes'] as int?) ?? 60;
    final category = json['category'] as String? ?? '';
    return ServiceModel(
      id: json['serviceId'] as String,
      title: json['serviceName'] as String? ?? 'Service',
      subtitle: '${_catLabel(category)} • $duration min',
      priceLabel: _fmtPrice(price),
      price: price,
      durationMins: duration,
      enabled: json['isActive'] as bool? ?? true,
      category: category,
    );
  }

  static String _catLabel(String cat) {
    switch (cat) {
      case 'grooming':
        return 'Grooming';
      case 'boarding':
        return 'Boarding';
      case 'sitting':
        return 'Sitting';
      case 'veterinary':
        return 'Veterinary';
      case 'training':
        return 'Training';
      default:
        return 'Service';
    }
  }

  static String _fmtPrice(double price) {
    final p = price.toInt();
    if (p >= 1000) {
      return 'KSh ${p ~/ 1000},${(p % 1000).toString().padLeft(3, '0')}';
    }
    return 'KSh $p';
  }
}

class ReviewModel {
  final String id;
  final String bookingId;
  final String ownerId;
  final String ownerName;
  final int rating;
  final String? text;
  final String? providerReply;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.ownerId,
    required this.ownerName,
    required this.rating,
    required this.createdAt,
    this.text,
    this.providerReply,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    return ReviewModel(
      id: json['reviewId'] as String,
      bookingId: json['bookingId'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: owner['fullName'] as String? ?? 'Pet owner',
      rating: json['rating'] as int,
      text: json['text'] as String?,
      providerReply: json['providerReply'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class AvailabilityDay {
  final int dayOfWeek; // 0=Sun, 1=Mon ... 6=Sat
  final String startTime; // "09:00:00"
  final String endTime; // "17:00:00"
  final bool isAvailable;

  const AvailabilityDay({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory AvailabilityDay.fromJson(Map<String, dynamic> json) =>
      AvailabilityDay(
        dayOfWeek: json['dayOfWeek'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': isAvailable,
      };
}

enum BookingStatus {
  pending,
  accepted,
  upcoming,
  completed,
  cancelled,
  rescheduled,
  pendingReschedule,
  reviewPending,
  declined
}

class BookingRecord {
  final String id;
  final String providerName;
  final String providerImageUrl;
  final String serviceName;
  final String priceLabel;
  final DateTime date;
  final String time;
  final DateTime bookingDatetime;
  final BookingStatus status;
  final String? declineReason;
  final String? rescheduledFrom;

  const BookingRecord({
    required this.id,
    required this.providerName,
    required this.providerImageUrl,
    required this.serviceName,
    required this.priceLabel,
    required this.date,
    required this.time,
    required this.bookingDatetime,
    required this.status,
    this.declineReason,
    this.rescheduledFrom,
  });

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    final rawDatetime = json['bookingDatetime'] ?? json['booking_datetime'];
    final dt = DateTime.parse(rawDatetime.toString()).toLocal();
    final provider = json['provider'] as Map<String, dynamic>? ?? {};
    final service = json['service'] as Map<String, dynamic>? ?? {};
    final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
    return BookingRecord(
      id: (json['bookingId'] ?? json['booking_id'] ?? json['id']).toString(),
      providerName: (provider['businessName'] as String?) ??
          (provider['business_name'] as String?) ??
          'Unknown provider',
      providerImageUrl: '',
      serviceName: (service['serviceName'] as String?) ??
          (service['service_name'] as String?) ??
          'Service',
      priceLabel: _formatPrice(price),
      date: DateTime(dt.year, dt.month, dt.day),
      time: _formatTime(dt),
      bookingDatetime: dt,
      status: _parseStatus(json['status']?.toString() ?? 'pending'),
      declineReason:
          (json['declineReason'] ?? json['decline_reason']) as String?,
      rescheduledFrom:
          (json['rescheduledFrom'] ?? json['rescheduled_from']) as String?,
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
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
      case 'pending':
        return BookingStatus.pending;
      case 'accepted':
        return BookingStatus.accepted;
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'declined':
        return BookingStatus.declined;
      case 'rescheduled':
        return BookingStatus.rescheduled;
      case 'pending_reschedule':
        return BookingStatus.pendingReschedule;
      case 'review_pending':
        return BookingStatus.reviewPending;
      default:
        return BookingStatus.upcoming;
    }
  }
}

enum ProviderBookingStatus { pending, accepted, declined, cancelled, completed, rescheduled }

class ProviderBookingRecord {
  final String id;
  final String ownerId;
  final String ownerName;
  final String serviceName;
  final String priceLabel;
  final String pricingUnit;
  final int durationMinutes;
  final DateTime date;
  final String time;
  final DateTime bookingDatetime;
  final ProviderBookingStatus status;
  final String? rescheduledFrom;

  const ProviderBookingRecord({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.serviceName,
    required this.priceLabel,
    required this.pricingUnit,
    required this.durationMinutes,
    required this.date,
    required this.time,
    required this.bookingDatetime,
    required this.status,
    this.rescheduledFrom,
  });

  bool get isRescheduledBooking => rescheduledFrom != null;

  factory ProviderBookingRecord.fromJson(Map<String, dynamic> json) {
    final dt = DateTime.parse(json['bookingDatetime'] as String).toLocal();
    final service = json['service'] as Map<String, dynamic>? ?? {};
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
    return ProviderBookingRecord(
      id: json['bookingId'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: (owner['fullName'] as String?) ?? 'Pet owner',
      serviceName: (service['serviceName'] as String?) ?? 'Service',
      priceLabel: _formatPrice(price),
      pricingUnit: _pricingUnitLabel(service['pricingUnit'] as String?),
      durationMinutes: (service['durationMinutes'] as int?) ?? 0,
      date: DateTime(dt.year, dt.month, dt.day),
      time: _formatTime(dt),
      bookingDatetime: dt,
      status: _parseStatus(json['status'] as String),
      rescheduledFrom: json['rescheduledFrom'] as String?,
    );
  }

  static String _formatPrice(double price) {
    final p = price.toInt();
    if (p >= 1000)
      return 'KSh ${p ~/ 1000},${(p % 1000).toString().padLeft(3, '0')}';
    return 'KSh $p';
  }

  static String _pricingUnitLabel(String? value) {
    switch (value) {
      case 'per_hour':
      case 'per hour':
        return 'per hour';
      case 'per_night':
      case 'per night':
        return 'per night';
      case 'per_day':
      case 'per day':
        return 'per day';
      case 'per_session':
      case 'per session':
        return 'per session';
      default:
        return 'per session';
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  static ProviderBookingStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted':
        return ProviderBookingStatus.accepted;
      case 'declined':
        return ProviderBookingStatus.declined;
      case 'cancelled':
        return ProviderBookingStatus.cancelled;
      case 'completed':
        return ProviderBookingStatus.completed;
      case 'rescheduled':
        return ProviderBookingStatus.rescheduled;
      default:
        return ProviderBookingStatus.pending;
    }
  }
}
