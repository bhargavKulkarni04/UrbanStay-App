/// ==============================================================================
/// TENANT_MODEL.DART
/// Purpose: Strongly-typed Dart class for Active PG Residents
/// Matches: public.tenants table in Supabase
/// Source: supabase/migrations/02_create_rooms_and_beds_tables.sql
/// ==============================================================================

class TenantModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String? roomId;
  final String? roomNumber;
  final String? bedId;
  final String? bedLabel;
  final String name;
  final String phone;
  final String? email;
  final String? workplace;
  final double monthlyRent;
  final double securityDeposit;
  final int rentDueDay;
  final bool isAadhaarVerified;
  final String? refundUpiId;
  final String? emergencyContact;
  final String status;
  final DateTime? createdAt;

  TenantModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.roomId,
    this.roomNumber,
    this.bedId,
    this.bedLabel,
    required this.name,
    required this.phone,
    this.email,
    this.workplace,
    this.monthlyRent = 0.0,
    this.securityDeposit = 0.0,
    this.rentDueDay = 5,
    this.isAadhaarVerified = false,
    this.refundUpiId,
    this.emergencyContact,
    this.status = 'Active',
    this.createdAt,
  });

  /// Computed initials for avatar
  String get initials {
    if (name.trim().isEmpty) return 'RS';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isNotice => status.toLowerCase() == 'notice';

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final rawRent = json['monthly_rent'] ?? json['rent'];
    final double rent = rawRent is num
        ? rawRent.toDouble()
        : (double.tryParse(rawRent?.toString() ?? '0.0') ?? 0.0);

    final rawDeposit = json['security_deposit'] ?? json['deposit'];
    final double deposit = rawDeposit is num
        ? rawDeposit.toDouble()
        : (double.tryParse(rawDeposit?.toString() ?? '0.0') ?? 0.0);

    final dueDay = (json['rent_due_day'] as num?)?.toInt() ?? 5;

    return TenantModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      roomId: json['room_id']?.toString(),
      roomNumber: json['room_number']?.toString(),
      bedId: json['bed_id']?.toString(),
      bedLabel: json['bed_label']?.toString(),
      name: json['name']?.toString() ?? json['tenant_name']?.toString() ?? 'Resident',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      workplace: json['workplace']?.toString(),
      monthlyRent: rent,
      securityDeposit: deposit,
      rentDueDay: dueDay,
      isAadhaarVerified: json['is_aadhaar_verified'] == true,
      refundUpiId: json['refund_upi_id']?.toString(),
      emergencyContact: json['emergency_contact']?.toString(),
      status: json['status']?.toString() ?? 'Active',
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
      if (roomId != null) 'room_id': roomId,
      if (roomNumber != null) 'room_number': roomNumber,
      if (bedId != null) 'bed_id': bedId,
      if (bedLabel != null) 'bed_label': bedLabel,
      'name': name,
      'tenant_name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (workplace != null) 'workplace': workplace,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'rent_due_day': rentDueDay,
      'is_aadhaar_verified': isAadhaarVerified,
      if (refundUpiId != null) 'refund_upi_id': refundUpiId,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      'status': status,
    };
  }
}
