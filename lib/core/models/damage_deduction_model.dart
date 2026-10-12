/// ==============================================================================
/// DAMAGE_DEDUCTION_MODEL.DART
/// Purpose: Strongly-typed Dart class for Security Deposit Damage Deductions
/// Matches: public.damage_deductions table in Supabase
/// Source: supabase/migrations/14_create_damage_deductions_table.sql
/// ==============================================================================

class DamageDeductionModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String? roomId;
  final String roomNumber;
  final String itemDamaged;
  final double amount;
  final String deductionMode;
  final String? photoUrl;
  final DateTime? createdAt;

  DamageDeductionModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    this.roomId,
    this.roomNumber = '',
    required this.itemDamaged,
    required this.amount,
    this.deductionMode = 'deposit',
    this.photoUrl,
    this.createdAt,
  });

  factory DamageDeductionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '500.0') ?? 500.0);

    return DamageDeductionModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      roomId: json['room_id']?.toString(),
      roomNumber: json['room_number']?.toString() ?? '',
      itemDamaged: json['item_damaged']?.toString() ?? 'Damaged item',
      amount: amount,
      deductionMode: json['deduction_mode']?.toString() ?? 'deposit',
      photoUrl: json['photo_url']?.toString(),
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
      if (roomId != null) 'room_id': roomId,
      if (roomNumber.isNotEmpty) 'room_number': roomNumber,
      'item_damaged': itemDamaged,
      'amount': amount,
      'deduction_mode': deductionMode,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}
