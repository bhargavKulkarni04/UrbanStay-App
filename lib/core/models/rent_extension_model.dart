/// ==============================================================================
/// RENT_EXTENSION_MODEL.DART
/// Purpose: Strongly-typed Dart class for Delayed Salary / Rent Extension Requests
/// Matches: public.rent_extensions table in Supabase
/// Source: supabase/migrations/03_create_rent_and_approvals_tables.sql
/// ==============================================================================

class RentExtensionModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final String? ledgerId;
  final DateTime requestedDueDate;
  final String reason;
  final String status;
  final DateTime? createdAt;

  RentExtensionModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    this.ledgerId,
    required this.requestedDueDate,
    required this.reason,
    this.status = 'pending',
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';

  factory RentExtensionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['requested_due_date'] != null) {
      parsedDate = DateTime.tryParse(json['requested_due_date'].toString()) ??
          DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return RentExtensionModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      ledgerId: json['ledger_id']?.toString(),
      requestedDueDate: parsedDate,
      reason: json['reason']?.toString() ?? 'Salary delay',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
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
      if (roomNumber.isNotEmpty) 'room_number': roomNumber,
      if (ledgerId != null) 'ledger_id': ledgerId,
      'requested_due_date':
          '${requestedDueDate.year}-${requestedDueDate.month.toString().padLeft(2, '0')}-${requestedDueDate.day.toString().padLeft(2, '0')}',
      'reason': reason,
      'status': status,
    };
  }
}
