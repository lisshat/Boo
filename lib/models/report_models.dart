enum ReportReason {
  harassment,
  threats,
  scam,
  spam,
  inappropriateContent,
  unsafeConduct,
  discrimination,
  other,
}

extension ReportReasonLabels on ReportReason {
  String get apiValue {
    switch (this) {
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.threats:
        return 'threats';
      case ReportReason.scam:
        return 'scam';
      case ReportReason.spam:
        return 'spam';
      case ReportReason.inappropriateContent:
        return 'inappropriate_content';
      case ReportReason.unsafeConduct:
        return 'unsafe_conduct';
      case ReportReason.discrimination:
        return 'discrimination';
      case ReportReason.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.threats:
        return 'Threats';
      case ReportReason.scam:
        return 'Scam or fraud';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Inappropriate content';
      case ReportReason.unsafeConduct:
        return 'Unsafe conduct';
      case ReportReason.discrimination:
        return 'Discrimination';
      case ReportReason.other:
        return 'Other';
    }
  }
}

enum ReportStatus { submitted, reviewing, resolved, dismissed }

extension ReportStatusLabels on ReportStatus {
  String get apiValue => name;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

ReportReason? reportReasonFromApi(String? value) {
  for (final reason in ReportReason.values) {
    if (reason.apiValue == value) return reason;
  }
  return null;
}

ReportStatus? reportStatusFromApi(String? value) {
  for (final status in ReportStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

class ReportRecord {
  final String id;
  final String? reporterUserId;
  final String? reportedUserId;
  final String? providerProfileId;
  final String? bookingId;
  final String? streamChannelType;
  final String? streamChannelId;
  final ReportReason? reason;
  final String? description;
  final ReportStatus? status;
  final String? assignedAdminId;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ModerationUser? reporter;
  final ModerationUser? reportedAccount;
  final ModerationUser? assignedAdmin;
  final ProviderModerationContext? provider;
  final BookingModerationContext? booking;
  final ModerationHistory? history;

  const ReportRecord({
    required this.id,
    this.reporterUserId,
    this.reportedUserId,
    this.providerProfileId,
    this.bookingId,
    this.streamChannelType,
    this.streamChannelId,
    this.reason,
    this.description,
    this.status,
    this.assignedAdminId,
    this.resolutionNotes,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.reporter,
    this.reportedAccount,
    this.assignedAdmin,
    this.provider,
    this.booking,
    this.history,
  });

  factory ReportRecord.fromJson(Map<String, dynamic> json) => ReportRecord(
        id: json['reportId']?.toString() ?? json['report_id']?.toString() ?? '',
        reporterUserId: json['reporterUserId']?.toString(),
        reportedUserId: json['reportedUserId']?.toString(),
        providerProfileId: json['providerProfileId']?.toString(),
        bookingId: json['bookingId']?.toString(),
        streamChannelType: json['streamChannelType']?.toString(),
        streamChannelId: json['streamChannelId']?.toString(),
        reason: reportReasonFromApi(json['reason']?.toString()),
        description: json['description']?.toString(),
        status: reportStatusFromApi(json['status']?.toString()),
        assignedAdminId: json['assignedAdminId']?.toString(),
        resolutionNotes: json['resolutionNotes']?.toString(),
        resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
        reporter: ModerationUser.fromJson(json['reporter']),
        reportedAccount: ModerationUser.fromJson(json['reportedAccount']),
        assignedAdmin: ModerationUser.fromJson(json['assignedAdmin']),
        provider: ProviderModerationContext.fromJson(json['provider']),
        booking: BookingModerationContext.fromJson(json['booking']),
        history: ModerationHistory.fromJson(json['history']),
      );
}

class ModerationUser {
  final String? id;
  final String displayName;
  final String role;
  final bool isBanned;

  const ModerationUser({
    this.id,
    required this.displayName,
    required this.role,
    required this.isBanned,
  });

  static ModerationUser? fromJson(dynamic value) {
    if (value is! Map) return null;
    return ModerationUser(
      id: value['id']?.toString(),
      displayName: value['displayName']?.toString() ?? 'Boo user',
      role: value['role']?.toString() ?? 'user',
      isBanned: value['isBanned'] == true,
    );
  }
}

class ProviderModerationContext {
  final String? profileId;
  final String businessName;
  final String verificationStatus;
  final List<String> serviceCategories;

  const ProviderModerationContext({
    this.profileId,
    required this.businessName,
    required this.verificationStatus,
    required this.serviceCategories,
  });

  static ProviderModerationContext? fromJson(dynamic value) {
    if (value is! Map) return null;
    return ProviderModerationContext(
      profileId: value['profileId']?.toString(),
      businessName: value['businessName']?.toString() ?? 'Provider',
      verificationStatus:
          value['verificationStatus']?.toString() ?? 'unsubmitted',
      serviceCategories:
          (value['serviceCategories'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class BookingModerationContext {
  final String? bookingId;
  final String status;
  final DateTime? bookingDatetime;
  final String? serviceName;
  final String? serviceCategory;
  final String ownerName;
  final String providerName;

  const BookingModerationContext({
    this.bookingId,
    required this.status,
    this.bookingDatetime,
    this.serviceName,
    this.serviceCategory,
    required this.ownerName,
    required this.providerName,
  });

  static BookingModerationContext? fromJson(dynamic value) {
    if (value is! Map) return null;
    return BookingModerationContext(
      bookingId: value['bookingId']?.toString(),
      status: value['status']?.toString() ?? 'unknown',
      bookingDatetime:
          DateTime.tryParse(value['bookingDatetime']?.toString() ?? ''),
      serviceName: value['serviceName']?.toString(),
      serviceCategory: value['serviceCategory']?.toString(),
      ownerName: value['ownerName']?.toString() ?? 'Boo owner',
      providerName: value['providerName']?.toString() ?? 'Boo provider',
    );
  }
}

class ModerationHistory {
  final Map<String, int> previousReports;
  final List<ModerationAction> moderationActions;

  const ModerationHistory({
    required this.previousReports,
    required this.moderationActions,
  });

  static ModerationHistory? fromJson(dynamic value) {
    if (value is! Map) return null;
    final rawReports = value['previousReports'];
    final reports = <String, int>{};
    if (rawReports is Map) {
      for (final entry in rawReports.entries) {
        reports[entry.key.toString()] =
            int.tryParse(entry.value.toString()) ?? 0;
      }
    }
    final actions = (value['moderationActions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(ModerationAction.fromJson)
        .toList();
    return ModerationHistory(
        previousReports: reports, moderationActions: actions);
  }
}

class ModerationAction {
  final String action;
  final DateTime? performedAt;

  const ModerationAction({required this.action, this.performedAt});

  static ModerationAction fromJson(Map value) => ModerationAction(
        action: value['action']?.toString() ?? 'admin action',
        performedAt: DateTime.tryParse(value['performedAt']?.toString() ?? ''),
      );
}

class ConversationEvidenceMessage {
  final String id;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime? createdAt;

  const ConversationEvidenceMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  factory ConversationEvidenceMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? const {};
    return ConversationEvidenceMessage(
      id: json['id']?.toString() ?? '',
      senderName: sender['displayName']?.toString() ?? 'Boo user',
      senderRole: sender['role']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class ReportPage {
  final List<ReportRecord> items;
  final int page;
  final int limit;
  final int total;

  const ReportPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ReportPage.fromJson(Map<String, dynamic> json) => ReportPage(
        items: (json['data'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ReportRecord.fromJson)
            .toList(),
        page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
        limit: int.tryParse(json['limit']?.toString() ?? '') ?? 20,
        total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      );
}
