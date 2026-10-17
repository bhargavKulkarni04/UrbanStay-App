/// ==============================================================================
/// WARDEN_CASH_MODEL.DART
/// Purpose: Strongly-typed Dart class for Warden Cash Collections & Theft Prevention Audit
/// Matches: public.warden_cash_collections table in Supabase
/// Source: supabase/migrations/03_create_rent_and_approvals_tables.sql
/// ==============================================================================

class WardenCashModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final double amount;
  final String collectedBy;
  final String status;
  final String? notes;
  final bool isDepositedToOwner;
  final DateTime? depositDate;
  final DateTime? createdAt;

  WardenCashModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    required this.amount,
    required this.collectedBy,
    this.status = 'with_warden',
    this.notes,
    this.isDepositedToOwner = false,
    this.depositDate,
    this.createdAt,
  });

  bool get isWithWarden => !isDepositedToOwner && status.toLowerCase() == 'with_warden';
  bool get isDeposited => isDepositedToOwner || status.toLowerCase() == 'deposited_to_bank';

  factory WardenCashModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0);

    final bool deposited = json['is_deposited_to_owner'] == true ||
        (json['status']?.toString().toLowerCase() == 'deposited_to_bank');

    return WardenCashModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      amount: amount,
      collectedBy: json['warden_name']?.toString() ??
          json['collected_by']?.toString() ??
          'Warden',
      status: deposited ? 'deposited_to_bank' : (json['status']?.toString() ?? 'with_warden').toLowerCase(),
      notes: json['notes']?.toString(),
      isDepositedToOwner: deposited,
      depositDate: json['deposit_date'] != null
          ? DateTime.tryParse(json['deposit_date'].toString())
          : null,
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
      'amount': amount,
      'warden_name': collectedBy,
      'is_deposited_to_owner': isDepositedToOwner,
      if (notes != null) 'notes': notes,
      if (depositDate != null)
        'deposit_date': depositDate!.toIso8601String(),
    };
  }
}
