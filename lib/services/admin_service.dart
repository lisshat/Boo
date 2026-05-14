import 'dart:convert';

import 'package:boo/services/auth_service.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<Map<String, dynamic>> stats() async {
    final res = await ApiService.instance.get('/admin/stats');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load admin stats');
  }

  Future<List<dynamic>> auditLog() async {
    final res = await ApiService.instance.get('/admin/audit-log');
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Could not load audit log');
  }

  Future<List<dynamic>> verification({
    String status = 'pending',
    String? search,
  }) async {
    final query = <String>[];
    if (status != 'all') query.add('status=${Uri.encodeComponent(status)}');
    if (search != null && search.trim().isNotEmpty) {
      query.add('search=${Uri.encodeComponent(search.trim())}');
    }
    final res = await ApiService.instance.get(
      '/admin/verification${query.isEmpty ? '' : '?${query.join('&')}'}',
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Could not load verification queue');
  }

  Future<void> reviewVerification({
    required String docId,
    required String decision,
    String? adminNotes,
  }) async {
    final res = await ApiService.instance.patch('/admin/verification/$docId', {
      'decision': decision,
      if (adminNotes != null && adminNotes.trim().isNotEmpty)
        'adminNotes': adminNotes.trim(),
    });
    if (res.statusCode != 200) throw Exception('Could not update verification');
  }

  Future<List<dynamic>> users({String? role, bool? isBanned}) async {
    final query = <String>[];
    if (role != null && role != 'all') query.add('role=$role');
    if (isBanned != null) query.add('isBanned=$isBanned');
    final path = '/admin/users${query.isEmpty ? '' : '?${query.join('&')}'}';
    final res = await ApiService.instance.get(path);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Could not load users');
  }

  Future<void> setBanned(String userId, bool isBanned) async {
    final res = await ApiService.instance.patch('/admin/users/$userId', {
      'isBanned': isBanned,
    });
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message']?.toString() ?? 'Could not update user');
    }
  }

  Future<Map<String, dynamic>> bookings({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final res = await ApiService.instance
        .get('/admin/bookings?status=$status&page=$page&limit=$limit');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load bookings');
  }

  Future<List<dynamic>> services({String? category, bool? isActive}) async {
    final query = <String>[];
    if (category != null && category != 'all') query.add('category=$category');
    if (isActive != null) query.add('isActive=$isActive');
    final res = await ApiService.instance
        .get('/admin/services${query.isEmpty ? '' : '?${query.join('&')}'}');
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Could not load services');
  }

  Future<Map<String, dynamic>> providerPerformance({
    String? isVerified,
    String? category,
    String minRating = '0',
    String sortBy = 'rating',
  }) async {
    final query = <String>['minRating=$minRating', 'sortBy=$sortBy'];
    if (isVerified != null && isVerified != 'all')
      query.add('isVerified=$isVerified');
    if (category != null && category != 'all') query.add('category=$category');
    final res = await ApiService.instance
        .get('/admin/reports/provider-performance?${query.join('&')}');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load provider performance report');
  }

  Future<Map<String, dynamic>> bookingActivity({
    String groupBy = 'week',
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String>['groupBy=$groupBy'];
    if (status != null && status != 'all') query.add('status=$status');
    if (startDate != null && startDate.isNotEmpty)
      query.add('startDate=$startDate');
    if (endDate != null && endDate.isNotEmpty) query.add('endDate=$endDate');
    final res = await ApiService.instance
        .get('/admin/reports/booking-activity?${query.join('&')}');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load booking activity report');
  }

  Future<Map<String, dynamic>> serviceCatalog({
    String? category,
    String? minPrice,
    String? maxPrice,
    bool? isActive,
  }) async {
    final query = <String>[];
    if (category != null && category != 'all') query.add('category=$category');
    if (minPrice != null && minPrice.isNotEmpty)
      query.add('minPrice=$minPrice');
    if (maxPrice != null && maxPrice.isNotEmpty)
      query.add('maxPrice=$maxPrice');
    if (isActive != null) query.add('isActive=$isActive');
    final res = await ApiService.instance.get(
        '/admin/reports/service-catalog${query.isEmpty ? '' : '?${query.join('&')}'}');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load service catalog report');
  }

  Future<Map<String, dynamic>> trustSafety({
    String minCancellations = '3',
    String? startDate,
    String? endDate,
  }) async {
    final query = <String>['minCancellations=$minCancellations'];
    if (startDate != null && startDate.isNotEmpty)
      query.add('startDate=$startDate');
    if (endDate != null && endDate.isNotEmpty) query.add('endDate=$endDate');
    final res = await ApiService.instance
        .get('/admin/reports/trust-safety?${query.join('&')}');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load trust and safety report');
  }

  Future<Map<String, dynamic>> userSummary({
    String? role,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String>[];
    if (role != null && role != 'all') query.add('role=$role');
    if (startDate != null && startDate.isNotEmpty)
      query.add('startDate=$startDate');
    if (endDate != null && endDate.isNotEmpty) query.add('endDate=$endDate');
    final res = await ApiService.instance.get(
        '/admin/reports/user-summary${query.isEmpty ? '' : '?${query.join('&')}'}');
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Could not load user summary report');
  }

  Future<void> warnUser(String userId) async {
    final res = await ApiService.instance.post('/admin/users/$userId/warn', {});
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Could not warn user');
    }
  }

  Future<List<dynamic>> userBookingHistory(String userId) async {
    final res = await ApiService.instance.get('/admin/users/$userId/bookings');
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Could not load booking history');
  }
}
