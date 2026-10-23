/// ==============================================================================
/// BED_MODEL.DART
/// Purpose: Strongly-typed Dart class for Beds & Live Occupancy Matrix
/// Matches: public.beds table in Supabase
/// Source: supabase/migrations/02_create_rooms_and_beds_tables.sql
/// ==============================================================================

class BedModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String roomId;
  final String? roomNumber;
  final String bedLabel;
  final String? bedCode;
  final bool isOccupied;
  final String status;
  final String? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final double? rent;
  final double? deposit;
  final double? refundableDeposit;
  final DateTime? createdAt;

  BedModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.roomId,
    this.roomNumber,
    required this.bedLabel,
    this.bedCode,
    this.isOccupied = false,
    this.status = 'Vacant',
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.rent,
    this.deposit,
    this.refundableDeposit,
    this.createdAt,
  });

  /// Computed initials for resident in this bed
  String get tenantInitials {
    final tName = tenantName?.trim() ?? '';
    if (tName.isEmpty) return 'US';
    final parts = tName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return tName.substring(0, tName.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Bed status helpers
  bool get isVacant => !isOccupied || status.toLowerCase() == 'vacant';
  bool get isNotice => status.toLowerCase() == 'notice';
  bool get isActive => isOccupied && status.toLowerCase() == 'active';

  /// Deserializer from Supabase JSON
  factory BedModel.fromJson(Map<String, dynamic> json) {
    final rawRent = json['rent'];
    final double? rent = rawRent is num
        ? rawRent.toDouble()
        : (rawRent != null ? double.tryParse(rawRent.toString()) : null);

    final rawDeposit = json['deposit'];
    final double? deposit = rawDeposit is num
        ? rawDeposit.toDouble()
        : (rawDeposit != null ? double.tryParse(rawDeposit.toString()) : null);

    final rawRefundable = json['refundable_deposit'];
    final double? refundable = rawRefundable is num
        ? rawRefundable.toDouble()
        : (rawRefundable != null ? double.tryParse(rawRefundable.toString()) : deposit);

    final label = json['bed_label']?.toString() ??
        json['bed_number']?.toString() ??
        json['bed_code']?.toString() ??
        'Bed';

    return BedModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      roomNumber: json['room_number']?.toString(),
      bedLabel: label,
      bedCode: json['bed_code']?.toString(),
      isOccupied: json['is_occupied'] == true,
      status: json['status']?.toString() ?? (json['is_occupied'] == true ? 'Active' : 'Vacant'),
      tenantId: json['tenant_id']?.toString(),
      tenantName: json['tenant_name']?.toString(),
      tenantPhone: json['tenant_phone']?.toString(),
      rent: rent,
      deposit: deposit,
      refundableDeposit: refundable,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializer to Supabase JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'room_id': roomId,
      if (roomNumber != null && roomNumber!.isNotEmpty) 'room_number': roomNumber,
      'bed_label': bedLabel,
      if (bedCode != null) 'bed_code': bedCode,
      'is_occupied': isOccupied,
      'status': status,
      if (tenantId != null && tenantId!.isNotEmpty) 'tenant_id': tenantId,
      if (tenantName != null) 'tenant_name': tenantName,
      if (refundableDeposit != null) 'refundable_deposit': refundableDeposit,
      if (tenantPhone != null) 'tenant_phone': tenantPhone,
      if (rent != null) 'rent': rent,
      if (deposit != null) 'deposit': deposit,
    };
  }

  /// CopyWith helper
  BedModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? roomId,
    String? roomNumber,
    String? bedLabel,
    String? bedCode,
    bool? isOccupied,
    String? status,
    String? tenantId,
    String? tenantName,
    String? tenantPhone,
    double? rent,
    double? deposit,
    DateTime? createdAt,
  }) {
    return BedModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      bedLabel: bedLabel ?? this.bedLabel,
      bedCode: bedCode ?? this.bedCode,
      isOccupied: isOccupied ?? this.isOccupied,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      rent: rent ?? this.rent,
      deposit: deposit ?? this.deposit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
