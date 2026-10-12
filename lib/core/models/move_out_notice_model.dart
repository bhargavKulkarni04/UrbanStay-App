/// ==============================================================================
/// MOVE_OUT_NOTICE_MODEL.DART
/// Purpose: Strongly-typed Dart class for 30-Day Notice Period & Vacating Pipeline
/// Matches: public.move_out_notices table in Supabase
/// Source: supabase/migrations/06_create_tenant_living_and_notices_tables.sql
/// ==============================================================================

class MoveOutNoticeModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final String bedIdentifier;
  final DateTime vacateDate;
  final int noticeDays;
  final String reason;
  final String refundUpiId;
  final String status;
  final DateTime? createdAt;

  MoveOutNoticeModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    required this.roomNumber,
    required this.bedIdentifier,
    required this.vacateDate,
    this.noticeDays = 30,
    required this.reason,
    required this.refundUpiId,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  /// Computed days remaining until checkout
  int get daysRemaining {
    final diff = vacateDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory MoveOutNoticeModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['vacate_date'] != null) {
      parsedDate =
          DateTime.tryParse(json['vacate_date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return MoveOutNoticeModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      bedIdentifier: json['bed_identifier']?.toString() ?? '',
      vacateDate: parsedDate,
      noticeDays: json['notice_days'] is int
          ? json['notice_days']
          : (int.tryParse(json['notice_days']?.toString() ?? '30') ?? 30),
      reason: json['reason']?.toString() ?? 'Relocation',
      refundUpiId: json['refund_upi_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'tenant_id': tenantId,
      if (tenantName.isNotEmpty) 'tenant_name': tenantName,
      'room_number': roomNumber,
      'bed_identifier': bedIdentifier,
      'vacate_date':
          '${vacateDate.year}-${vacateDate.month.toString().padLeft(2, '0')}-${vacateDate.day.toString().padLeft(2, '0')}',
      'notice_days': noticeDays,
      'reason': reason,
      'refund_upi_id': refundUpiId,
      'status': status,
    };
  }
}
