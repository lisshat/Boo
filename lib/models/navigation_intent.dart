/// Structured navigation intents shared by in-app and future push handling.
class ReviewBookingIntent {
  static const type = 'review_booking';

  final String bookingId;

  const ReviewBookingIntent({required this.bookingId});
}
