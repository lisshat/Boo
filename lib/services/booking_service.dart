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
  }) async {
    final bookingDatetime = _buildIso(date, time);

    try {
      final res = await ApiService.instance.post('/bookings', {
        'providerId': providerId,
        'serviceId': serviceId,
        'bookingDatetime': bookingDatetime,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 403) {
        throw BookingException(
            'Your account isn\'t set up to make bookings yet. Try logging out and back in.');
      }
      if (res.statusCode == 409) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw BookingException(
            (body['message'] as String?) ??
            'You already have a booking for this service at this time.');
      }
      if (res.statusCode >= 500) {
        throw BookingException(
            'Our servers are having a moment. Please try again shortly.');
      }
      throw BookingException('Something unexpected happened. Please try again.');
    } on BookingException {
      rethrow;
    } catch (_) {
      throw BookingException(
          'Could not reach the server. Check your connection and try again.');
    }
  }

  /// Returns the authenticated user's bookings list.
  Future<List<BookingRecord>> getBookings() async {
    try {
      final res = await ApiService.instance.get('/bookings');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => BookingRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await ApiService.instance.patch('/bookings/$bookingId/cancel', {});
  }

  Future<List<ProviderBookingRecord>> getProviderBookings() async {
    try {
      final res = await ApiService.instance.get('/bookings/provider');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => ProviderBookingRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    final res = await ApiService.instance.patch('/bookings/$bookingId/accept', {});
    return res.statusCode == 200;
  }

  Future<bool> completeBooking(String bookingId) async {
    final res = await ApiService.instance.patch('/bookings/$bookingId/complete', {});
    return res.statusCode == 200;
  }

  Future<bool> declineBooking(String bookingId, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    final res = await ApiService.instance.patch('/bookings/$bookingId/decline', body);
    return res.statusCode == 200;
  }

  Future<List<AvailabilityDay>> getProviderAvailability(String profileId) async {
    try {
      final res = await ApiService.instance.get('/providers/$profileId/availability');
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
}

class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => message;
}
