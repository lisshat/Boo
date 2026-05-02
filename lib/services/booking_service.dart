import 'dart:convert';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/auth_service.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  /// Returns the created booking on success, throws [BookingException] on failure.
  Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String providerName,
    required String serviceTitle,
    required double servicePrice,
    required DateTime date,
    required String time,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final res = await ApiService.instance.post('/bookings', {
        'providerId': providerId,
        'providerName': providerName,
        'serviceName': serviceTitle,
        'priceKsh': servicePrice.round(),
        'date': dateStr,
        'time': time,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 403) {
        throw BookingException(
            'Your account isn\'t set up to make bookings yet. Try logging out and back in.');
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
}

class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => message;
}
