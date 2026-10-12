/// ==============================================================================
/// RENT_LEDGER_MODEL.DART
/// Purpose: Strongly-typed Dart class for Monthly Rent Billing Cycles & Ledgers
/// Matches: public.rent_ledgers table in Supabase
/// Source: supabase/migrations/03_create_rent_and_approvals_tables.sql
/// ==============================================================================

class RentLedgerModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final String? bedNumber;
  final String? phone;
  final String cycleMonth;
  final double rentAmount;
  final DateTime dueDate;
  final String status;
  final DateTime? paidDate;
  final String paymentMode;
  final DateTime? createdAt;

  RentLedgerModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    this.bedNumber,
    this.phone,
    required this.cycleMonth,
    required this.rentAmount,
    required this.dueDate,
    this.status = 'PENDING',
    this.paidDate,
    this.paymentMode = 'UPI',
    this.createdAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  factory RentLedgerModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['rent_amount'] ?? json['due_amount'] ?? json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0);

    DateTime parsedDueDate;
    if (json['due_date'] != null) {
      parsedDueDate =
          DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now();
    } else {
      parsedDueDate = DateTime.now();
    }

    final tenant = json['tenants'] is Map ? json['tenants'] as Map : null;
    final tenantName = tenant?['full_name']?.toString() ??
        tenant?['name']?.toString() ??
        json['tenant_name']?.toString() ??
        '';
    final roomNumber = tenant?['room_number']?.toString() ??
        json['room_number']?.toString() ??
        '';
    final bedNumber = tenant?['bed_number']?.toString() ??
        json['bed_number']?.toString();
    final phone = tenant?['phone']?.toString() ??
        json['phone']?.toString();

    return RentLedgerModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: tenantName,
      roomNumber: roomNumber,
      bedNumber: bedNumber,
      phone: phone,
      cycleMonth: json['billing_month']?.toString() ??
          json['cycle_month']?.toString() ??
          'Current Month',
      rentAmount: amount,
      dueDate: parsedDueDate,
      status: json['status']?.toString() ?? 'PENDING',
      paidDate: json['paid_date'] != null
          ? DateTime.tryParse(json['paid_date'].toString())
          : null,
      paymentMode: json['payment_mode']?.toString() ?? 'UPI',
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
      'cycle_month': cycleMonth,
      'rent_amount': rentAmount,
      'due_date':
          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      'status': status,
      if (paidDate != null)
        'paid_date': paidDate!.toIso8601String(),
      'payment_mode': paymentMode,
    };
  }
}
