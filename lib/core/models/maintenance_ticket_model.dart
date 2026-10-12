/// ==============================================================================
/// MAINTENANCE_TICKET_MODEL.DART
/// Purpose: Strongly-typed Dart class for Maintenance Ticketing & Complaints
/// Matches: public.maintenance_tickets table in Supabase
/// Source: supabase/migrations/04_create_operations_and_staff_tables.sql
/// ==============================================================================

class MaintenanceTicketModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String? tenantId;
  final String tenantName;
  final String roomNumber;
  final String category;
  final String issue;
  final String? photoUrl;
  final String status;
  final String? assignedStaff;
  final String? progressNote;
  final DateTime? createdAt;

  MaintenanceTicketModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    this.category = 'Other',
    required this.issue,
    this.photoUrl,
    this.status = 'pending',
    this.assignedStaff,
    this.progressNote,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isResolved => status.toLowerCase() == 'resolved';

  factory MaintenanceTicketModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceTicketModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      tenantName: json['tenant_name']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      issue: json['issue']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      assignedStaff: json['assigned_staff']?.toString(),
      progressNote: json['progress_note']?.toString(),
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
      if (tenantId != null) 'tenant_id': tenantId,
      if (tenantName.isNotEmpty) 'tenant_name': tenantName,
      if (roomNumber.isNotEmpty) 'room_number': roomNumber,
      'category': category,
      'issue': issue,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status': status,
      if (assignedStaff != null) 'assigned_staff': assignedStaff,
      if (progressNote != null) 'progress_note': progressNote,
    };
  }
}
