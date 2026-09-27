import 'dart:convert';

import 'package:boo/models/report_models.dart';
import 'package:boo/services/auth_service.dart';

class ReportApiException implements Exception {
  final int? statusCode;
  final String message;

  const ReportApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<ReportRecord> submit({
    String? providerProfileId,
    String? bookingId,
    String? streamChannelType,
    String? streamChannelId,
    required ReportReason reason,
    String? description,
  }) async {
    final body = <String, dynamic>{
      if (providerProfileId != null) 'providerProfileId': providerProfileId,
      if (bookingId != null) 'bookingId': bookingId,
      if (streamChannelType != null) 'streamChannelType': streamChannelType,
      if (streamChannelId != null) 'streamChannelId': streamChannelId,
      'reason': reason.apiValue,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final response = await ApiService.instance.post('/reports', body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReportRecord.fromJson(_map(response.body));
    }
    throw _fromResponse(response.statusCode, response.body);
  }

  Future<ReportPage> mine({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
    ReportReason? reason,
  }) async {
    final query = <String>['page=$page', 'limit=$limit'];
    if (status != null) query.add('status=${status.apiValue}');
    if (reason != null) query.add('reason=${reason.apiValue}');
    final response = await ApiService.instance.get(
      '/reports/mine?${query.join('&')}',
    );
    if (response.statusCode == 200)
      return ReportPage.fromJson(_map(response.body));
    throw _fromResponse(response.statusCode, response.body);
  }

  Future<ReportPage> adminList({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
    ReportReason? reason,
  }) async {
    final query = <String>['page=$page', 'limit=$limit'];
    if (status != null) query.add('status=${status.apiValue}');
    if (reason != null) query.add('reason=${reason.apiValue}');
    final response = await ApiService.instance.get(
      '/admin/reports?${query.join('&')}',
    );
    if (response.statusCode == 200)
      return ReportPage.fromJson(_map(response.body));
    throw _fromResponse(response.statusCode, response.body);
  }

  Future<ReportRecord> adminDetail(String reportId) async {
    final response = await ApiService.instance.get('/admin/reports/$reportId');
    if (response.statusCode == 200) {
      return ReportRecord.fromJson(_map(response.body));
    }
    throw _fromResponse(response.statusCode, response.body);
  }

  Future<List<ConversationEvidenceMessage>> adminConversationContext(
      String reportId) async {
    final response = await ApiService.instance.get(
      '/admin/reports/$reportId/conversation-context',
    );
    if (response.statusCode == 200) {
      final decoded = _map(response.body);
      return (decoded['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ConversationEvidenceMessage.fromJson)
          .toList();
    }
    if (response.statusCode == 404) {
      throw const ReportApiException(
        'Conversation evidence is unavailable.',
        statusCode: 404,
      );
    }
    throw _fromResponse(response.statusCode, response.body);
  }

  Future<ReportRecord> updateStatus(
    String reportId, {
    ReportStatus? status,
    String? assignedAdminId,
    String? resolutionNotes,
  }) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status.apiValue,
      if (assignedAdminId != null) 'assignedAdminId': assignedAdminId,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes.trim(),
    };
    final response = await ApiService.instance.patch(
      '/admin/reports/$reportId/status',
      body,
    );
    if (response.statusCode == 200) {
      return ReportRecord.fromJson(_map(response.body));
    }
    if (response.statusCode == 409) {
      throw const ReportApiException(
        'This report changed while you were viewing it. Refresh and try again.',
        statusCode: 409,
      );
    }
    throw _fromResponse(response.statusCode, response.body);
  }

  Map<String, dynamic> _map(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ReportApiException('The report response was invalid.');
    }
    return decoded;
  }

  ReportApiException _fromResponse(int status, String body) {
    switch (status) {
      case 400:
        return const ReportApiException('Please check the report details.',
            statusCode: 400);
      case 403:
        return const ReportApiException(
            'You are not permitted to report this context.',
            statusCode: 403);
      case 404:
        return const ReportApiException(
            'That provider, booking or conversation is unavailable.',
            statusCode: 404);
      case 409:
        return const ReportApiException(
            'You recently submitted this report. Boo’s team will review it.',
            statusCode: 409);
      default:
        if (status >= 500) {
          return ReportApiException(
              'Boo could not process the report. Please try again.',
              statusCode: status);
        }
        return ReportApiException('The report could not be submitted.',
            statusCode: status);
    }
  }
}
