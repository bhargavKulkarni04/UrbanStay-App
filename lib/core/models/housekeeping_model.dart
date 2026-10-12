/// ==============================================================================
/// HOUSEKEEPING_MODEL.DART
/// Purpose: Strongly-typed Dart class for Daily Room Cleaning & Housekeeping Requests
/// Matches: public.housekeeping_requests table in Supabase
/// Source: supabase/migrations/06_create_tenant_living_and_notices_tables.sql
/// ==============================================================================

class HousekeepingModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String roomNumber;
  final String tenantName;
  final String serviceType;
  final String timeSlot;
  final String status;
  final DateTime? createdAt;

  HousekeepingModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.roomNumber,
    this.tenantName = '',
    this.serviceType = 'Room Cleaning',
    this.timeSlot = 'Morning (9 AM - 12 PM)',
    this.status = 'PENDING',
    this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory HousekeepingModel.fromJson(Map<String, dynamic> json) {
    return HousekeepingModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'Room Cleaning',
      timeSlot: json['time_slot']?.toString() ?? 'Morning (9 AM - 12 PM)',
      status: json['status']?.toString() ?? 'PENDING',
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
      'room_number': roomNumber,
      if (tenantName.isNotEmpty) 'tenant_name': tenantName,
      'service_type': serviceType,
      'time_slot': timeSlot,
      'status': status,
    };
  }
}
