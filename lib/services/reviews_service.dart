import 'dart:convert';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/auth_service.dart';

class ReviewsService {
  ReviewsService._();
  static final ReviewsService instance = ReviewsService._();

  Future<bool> createReview({
    required String bookingId,
    required int rating,
    String? text,
  }) async {
    final body = <String, dynamic>{'bookingId': bookingId, 'rating': rating};
    if (text != null && text.isNotEmpty) body['text'] = text;
    final res = await ApiService.instance.post('/reviews', body);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Returns Set of bookingIds the owner has already reviewed.
  Future<Set<String>> getMyReviewedBookingIds() async {
    try {
      final res = await ApiService.instance.get('/reviews/me');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => (e as Map<String, dynamic>)['bookingId'] as String)
            .toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<List<ReviewModel>> getProviderReviews(String profileId) async {
    try {
      final res = await ApiService.instance.get('/reviews/provider/$profileId');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ReviewModel>> getMyProviderReviews() async {
    try {
      final res = await ApiService.instance.get('/reviews/provider/me');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> replyToReview(String reviewId, String reply) async {
    final res = await ApiService.instance.patch('/reviews/$reviewId/reply', {'reply': reply});
    return res.statusCode == 200;
  }
}
