/// ==============================================================================
/// SAAS_INVOICE_MODEL.DART
/// Purpose: Strongly-typed Dart class for UrbanStay B2B SaaS Invoices & Tax Receipts
/// Matches: public.saas_invoices table in Supabase
/// Source: supabase/migrations/05_create_billing_and_settings_tables.sql & 15
/// ==============================================================================

class SaasInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String propertyId;
  final String propertyName;
  final double amount;
  final String status; // 'paid', 'pending'
  final String paymentMode;
  final String? utrNumber;
  final String? billingPeriod;
  final DateTime? createdAt;

  SaasInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.propertyId,
    this.propertyName = '',
    required this.amount,
    this.status = 'paid',
    this.paymentMode = 'UPI AutoPay',
    this.utrNumber,
    this.billingPeriod,
    this.createdAt,
  });

  bool get isPaid => status.toLowerCase() == 'paid';

  factory SaasInvoiceModel.fromJson(Map<String, dynamic> json) {
    return SaasInvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ??
          double.tryParse(json['amount']?.toString() ?? '') ??
          0.0,
      status: json['status']?.toString() ?? 'paid',
      paymentMode: json['payment_mode']?.toString() ?? 'UPI AutoPay',
      utrNumber: json['utr_number']?.toString(),
      billingPeriod: json['billing_period']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'invoice_number': invoiceNumber,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'amount': amount,
      'status': status,
      'payment_mode': paymentMode,
      if (utrNumber != null) 'utr_number': utrNumber,
      if (billingPeriod != null) 'billing_period': billingPeriod,
    };
  }

  SaasInvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? propertyId,
    String? propertyName,
    double? amount,
    String? status,
    String? paymentMode,
    String? utrNumber,
    String? billingPeriod,
    DateTime? createdAt,
  }) {
    return SaasInvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      utrNumber: utrNumber ?? this.utrNumber,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
