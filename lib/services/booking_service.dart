import 'dart:convert';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/auth_service.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  /// Returns the created booking on success, throws [BookingException] on failure.
  Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String serviceId,
    required DateTime date,
    required String time,
    String? petId,
  }) async {
    final bookingDatetime = _buildIso(date, time);
    final body = <String, dynamic>{
      'providerId': providerId,
      'serviceId': serviceId,
      'bookingDatetime': bookingDatetime,
    };
    if (petId != null) body['petId'] = petId;

    try {
      final res = await ApiService.instance.post('/bookings', body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 403) {
        throw BookingException(
            'Your account isn\'t set up to make bookings yet. Try logging out and back in.');
      }
      if (res.statusCode == 409) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw BookingException((body['message'] as String?) ??
            'You already have a booking for this service at this time.');
      }
      if (res.statusCode >= 500) {
        throw BookingException(
            'Our servers are having a moment. Please try again shortly.');
      }
      throw BookingException(
          'Something unexpected happened. Please try again.');
    } on BookingException {
      rethrow;
    } catch (_) {
      throw BookingException(
          'Could not reach the server. Check your connection and try again.');
    }
  }

  Future<Map<String, dynamic>> getProviderEarnings() async {
    final local = await _providerEarningsFromBookings();
    try {
      final res = await ApiService.instance.get('/bookings/provider/earnings');
      if (res.statusCode == 200) {
        final remote = jsonDecode(res.body) as Map<String, dynamic>;
        return local.isEmpty ? remote : {...remote, ...local};
      }
      return local;
    } catch (_) {
      return local;
    }
  }

  Future<Map<String, dynamic>> getOwnerSpending() async {
    final local = await _ownerSpendingFromBookings();
    try {
      final res = await ApiService.instance.get('/bookings/owner/spending');
      if (res.statusCode == 200) {
        final remote = jsonDecode(res.body) as Map<String, dynamic>;
        return local.isEmpty ? remote : {...remote, ...local};
      }
      return local;
    } catch (_) {
      return local;
    }
  }

  Future<List<PetSummary>> getPets() async {
    try {
      final res = await ApiService.instance.get('/pets/me');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => PetSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Returns the authenticated user's bookings list.
  Future<List<BookingRecord>> getBookings() async {
    try {
      final res = await ApiService.instance.get('/bookings');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is List<dynamic>
            ? decoded
            : ((decoded as Map<String, dynamic>)['bookings'] ??
                decoded['data'] ??
                const <dynamic>[]) as List<dynamic>;
        final bookings = <BookingRecord>[];
        for (final item in list) {
          try {
            bookings.add(BookingRecord.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
        return bookings;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await ApiService.instance.patch('/bookings/$bookingId/cancel', {});
  }

  Future<Map<String, dynamic>> rescheduleBooking(
      String bookingId, DateTime newDatetime) async {
    final res = await ApiService.instance.post(
      '/bookings/$bookingId/reschedule',
      {'newDatetime': newDatetime.toUtc().toIso8601String()},
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final msg = body['message'];
    throw Exception((msg is List ? msg.first : msg) as String? ??
        'Could not reschedule booking');
  }

  Future<List<ProviderBookingRecord>> getProviderBookings() async {
    try {
      final res = await ApiService.instance.get('/bookings/provider');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) =>
                ProviderBookingRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    final res =
        await ApiService.instance.patch('/bookings/$bookingId/accept', {});
    return res.statusCode == 200;
  }

  Future<bool> completeBooking(String bookingId) async {
    final res =
        await ApiService.instance.patch('/bookings/$bookingId/complete', {});
    return res.statusCode == 200;
  }

  Future<bool> declineBooking(String bookingId, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final res =
        await ApiService.instance.patch('/bookings/$bookingId/decline', body);
    return res.statusCode == 200;
  }

  Future<List<AvailabilityDay>> getProviderAvailability(
      String profileId) async {
    try {
      final res =
          await ApiService.instance.get('/providers/$profileId/availability');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => AvailabilityDay.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Converts "09:00 AM" + a DateTime into a UTC ISO 8601 string.
  String _buildIso(DateTime date, String time) {
    final parts = time.trim().split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final int minute = int.parse(hm[1]);
    final String period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    final local = DateTime(date.year, date.month, date.day, hour, minute, 0, 0);
    return local.toUtc().toIso8601String();
  }

  Future<Map<String, dynamic>> _providerEarningsFromBookings() async {
    final bookings = await getProviderBookings();
    if (bookings.isEmpty) return {};
    final completed =
        bookings.where((b) => b.status == ProviderBookingStatus.completed);
    final total = completed.fold<double>(0, (sum, b) => sum + b.amount);
    final pendingCount = bookings
        .where((b) =>
            b.status == ProviderBookingStatus.pending ||
            b.status == ProviderBookingStatus.accepted)
        .length;
    return {
      'summary': {
        'totalEarnings': total,
        'completedCount': completed.length,
        'pendingCount': pendingCount,
      },
      'byMonth': _amountsByMonth(completed.map((b) => (b.date, b.amount))),
      'byCategory': _amountsByCategory(
        completed.map((b) => (b.category, b.amount)),
      ),
      'recentBookings': bookings.take(20).map((b) {
        return {
          'price': b.amount,
          'status': _providerStatusValue(b.status),
          'date': b.bookingDatetime.toIso8601String(),
          'service': b.serviceName,
          'owner': b.ownerName,
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _ownerSpendingFromBookings() async {
    final bookings = await getBookings();
    if (bookings.isEmpty) return {};
    final completed =
        bookings.where((b) => b.status == BookingStatus.completed);
    final upcomingCount = bookings
        .where((b) =>
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.upcoming)
        .length;
    final total = completed.fold<double>(0, (sum, b) => sum + b.amount);
    return {
      'summary': {
        'totalSpent': total,
        'completedCount': completed.length,
        'upcomingCount': upcomingCount,
      },
      'byMonth': _amountsByMonth(completed.map((b) => (b.date, b.amount))),
      'byCategory': _amountsByCategory(
        completed.map((b) => (b.category, b.amount)),
      ),
      'recentBookings': bookings.take(20).map((b) {
        return {
          'price': b.amount,
          'status': _bookingStatusValue(b.status),
          'date': b.bookingDatetime.toIso8601String(),
          'service': b.serviceName,
          'provider': b.providerName,
        };
      }).toList(),
    };
  }

  List<Map<String, dynamic>> _amountsByMonth(
    Iterable<(DateTime date, double amount)> rows,
  ) {
    final totals = <String, double>{};
    for (final row in rows) {
      final key =
          '${row.$1.year}-${row.$1.month.toString().padLeft(2, '0')}-01';
      totals[key] = (totals[key] ?? 0) + row.$2;
    }
    return totals.entries
        .map((entry) => {'month': entry.key, 'total': entry.value})
        .toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));
  }

  List<Map<String, dynamic>> _amountsByCategory(
    Iterable<(String category, double amount)> rows,
  ) {
    final totals = <String, double>{};
    for (final row in rows) {
      final key = row.$1.isEmpty ? 'other' : row.$1;
      totals[key] = (totals[key] ?? 0) + row.$2;
    }
    return totals.entries
        .map((entry) => {'category': entry.key, 'total': entry.value})
        .toList()
      ..sort((a, b) =>
          a['category'].toString().compareTo(b['category'].toString()));
  }

  String _bookingStatusValue(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.accepted:
      case BookingStatus.upcoming:
        return 'accepted';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.rescheduled:
        return 'rescheduled';
      case BookingStatus.pendingReschedule:
        return 'pending_reschedule';
      case BookingStatus.reviewPending:
        return 'review_pending';
    }
  }

  String _providerStatusValue(ProviderBookingStatus status) {
    switch (status) {
      case ProviderBookingStatus.accepted:
        return 'accepted';
      case ProviderBookingStatus.declined:
        return 'declined';
      case ProviderBookingStatus.cancelled:
        return 'cancelled';
      case ProviderBookingStatus.completed:
        return 'completed';
      case ProviderBookingStatus.rescheduled:
        return 'rescheduled';
      case ProviderBookingStatus.pending:
        return 'pending';
    }
  }
}

class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => message;
}
