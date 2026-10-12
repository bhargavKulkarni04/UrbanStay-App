/// ==============================================================================
/// SAAS_SUBSCRIPTION_MODEL.DART
/// Purpose: Strongly-typed Dart class for B2B Bed Licensing Subscriptions
/// Matches: public.saas_subscriptions table in Supabase
/// Source: supabase/migrations/05_create_billing_and_settings_tables.sql & 15
/// ==============================================================================

class SaasSubscriptionModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final int totalBeds;
  final double pricePerBed;
  final double platformFee;
  final double totalDue;
  final String sacCode;
  final String status; // 'active', 'past_due', 'trial'
  final DateTime? trialEndsAt;
  final DateTime? nextBillingDate;
  final DateTime? createdAt;

  SaasSubscriptionModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.totalBeds = 35,
    this.pricePerBed = 15.0,
    this.platformFee = 79.0,
    this.totalDue = 604.0,
    this.sacCode = '998315',
    this.status = 'active',
    this.trialEndsAt,
    this.nextBillingDate,
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isTrial => status.toLowerCase() == 'trial';
  bool get isPastDue => status.toLowerCase() == 'past_due';

  factory SaasSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SaasSubscriptionModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      totalBeds: json['total_beds'] is int
          ? json['total_beds'] as int
          : int.tryParse(json['total_beds']?.toString() ?? '') ?? 35,
      pricePerBed: (json['price_per_bed'] as num?)?.toDouble() ??
          double.tryParse(json['price_per_bed']?.toString() ?? '') ??
          15.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ??
          double.tryParse(json['platform_fee']?.toString() ?? '') ??
          79.0,
      totalDue: (json['total_due'] as num?)?.toDouble() ??
          double.tryParse(json['total_due']?.toString() ?? '') ??
          604.0,
      sacCode: json['sac_code']?.toString() ?? '998315',
      status: json['status']?.toString() ?? 'active',
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at'].toString())
          : null,
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.tryParse(json['next_billing_date'].toString())
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
      'total_beds': totalBeds,
      'price_per_bed': pricePerBed,
      'platform_fee': platformFee,
      'total_due': totalDue,
      'sac_code': sacCode,
      'status': status,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt!.toIso8601String(),
      if (nextBillingDate != null)
        'next_billing_date': nextBillingDate!.toIso8601String(),
    };
  }

  SaasSubscriptionModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    int? totalBeds,
    double? pricePerBed,
    double? platformFee,
    double? totalDue,
    String? sacCode,
    String? status,
    DateTime? trialEndsAt,
    DateTime? nextBillingDate,
    DateTime? createdAt,
  }) {
    return SaasSubscriptionModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      totalBeds: totalBeds ?? this.totalBeds,
      pricePerBed: pricePerBed ?? this.pricePerBed,
      platformFee: platformFee ?? this.platformFee,
      totalDue: totalDue ?? this.totalDue,
      sacCode: sacCode ?? this.sacCode,
      status: status ?? this.status,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
