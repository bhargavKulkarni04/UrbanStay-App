/// ==============================================================================
/// PAYMENT_APPROVAL_MODEL.DART
/// Purpose: Strongly-typed Dart class for 0% Direct UPI Approvals (UTR & Screenshots)
/// Matches: public.payment_approvals table in Supabase
/// Source: supabase/migrations/03_create_rent_and_approvals_tables.sql
/// ==============================================================================

class PaymentApprovalModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final String? ledgerId;
  final double amount;
  final String utrNumber;
  final String paymentApp;
  final String? phone;
  final String? proofImageUrl;
  final String status;
  final String? approvedBy;
  final DateTime? createdAt;

  PaymentApprovalModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    this.phone,
    this.ledgerId,
    required this.amount,
    required this.utrNumber,
    this.paymentApp = 'Google Pay',
    this.proofImageUrl,
    this.status = 'pending',
    this.approvedBy,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory PaymentApprovalModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0);

    return PaymentApprovalModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ??
          json['name']?.toString() ??
          'Resident',
      roomNumber: json['room_number']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['tenant_phone']?.toString(),
      ledgerId: json['ledger_id']?.toString(),
      amount: amount,
      utrNumber: json['utr_number']?.toString() ?? json['utr']?.toString() ?? '',
      paymentApp: json['payment_app']?.toString() ?? 'Google Pay',
      proofImageUrl: json['proof_image_url']?.toString() ??
          json['screenshot_url']?.toString(),
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      approvedBy: json['approved_by']?.toString(),
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
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (ledgerId != null) 'ledger_id': ledgerId,
      'amount': amount,
      'utr_number': utrNumber,
      'payment_app': paymentApp,
      if (proofImageUrl != null) 'proof_image_url': proofImageUrl,
      'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
    };
  }
}
