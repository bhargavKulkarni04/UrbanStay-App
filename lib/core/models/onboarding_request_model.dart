/// ==============================================================================
/// ONBOARDING_REQUEST_MODEL.DART
/// Purpose: Strongly-typed Dart class for Reception Standee QR Check-Ins
/// Matches: public.onboarding_requests table in Supabase
/// Source: supabase/migrations/06_create_tenant_living_and_notices_tables.sql
/// ==============================================================================

class OnboardingRequestModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String name;
  final String phone;
  final String? email;
  final String requestedRoom;
  final String? roomNumber;
  final String requestedBed;
  final String sharingType;
  final double monthlyRent;
  final double depositAmount;
  final String? aadhaarMasked;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final String? selfieUrl;
  final String status;
  final DateTime? createdAt;

  OnboardingRequestModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.name,
    required this.phone,
    this.email,
    required this.requestedRoom,
    this.roomNumber,
    required this.requestedBed,
    this.sharingType = '2-Sharing',
    this.monthlyRent = 0.0,
    this.depositAmount = 0.0,
    this.aadhaarMasked,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.selfieUrl,
    this.status = 'PENDING_APPROVAL',
    this.createdAt,
  });

  bool get isPending => status == 'PENDING_APPROVAL';
  bool get isApproved => status == 'APPROVED';

  factory OnboardingRequestModel.fromJson(Map<String, dynamic> json) {
    final rawRent = json['monthly_rent'];
    final double rent = rawRent is num
        ? rawRent.toDouble()
        : (double.tryParse(rawRent?.toString() ?? '0.0') ?? 0.0);

    final rawDeposit = json['deposit_amount'];
    final double deposit = rawDeposit is num
        ? rawDeposit.toDouble()
        : (double.tryParse(rawDeposit?.toString() ?? '0.0') ?? 0.0);

    return OnboardingRequestModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      name: json['tenant_name']?.toString() ??
          json['name']?.toString() ??
          json['full_name']?.toString() ??
          'Applicant',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      requestedRoom: json['requested_room']?.toString() ?? '',
      roomNumber: json['room_number']?.toString(),
      requestedBed: json['requested_bed']?.toString() ?? '',
      sharingType: json['sharing_type']?.toString() ?? '2-Sharing',
      monthlyRent: rent,
      depositAmount: deposit,
      aadhaarMasked: json['aadhaar_masked']?.toString(),
      aadhaarFrontUrl: json['aadhaar_front_url']?.toString(),
      aadhaarBackUrl: json['aadhaar_back_url']?.toString(),
      selfieUrl: json['selfie_url']?.toString(),
      status: json['status']?.toString() ?? 'PENDING_APPROVAL',
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
      'tenant_name': name,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      'requested_room': requestedRoom,
      if (roomNumber != null) 'room_number': roomNumber,
      'requested_bed': requestedBed,
      'sharing_type': sharingType,
      'monthly_rent': monthlyRent,
      'deposit_amount': depositAmount,
      if (aadhaarMasked != null) 'aadhaar_masked': aadhaarMasked,
      if (aadhaarFrontUrl != null) 'aadhaar_front_url': aadhaarFrontUrl,
      if (aadhaarBackUrl != null) 'aadhaar_back_url': aadhaarBackUrl,
      if (selfieUrl != null) 'selfie_url': selfieUrl,
      'status': status,
    };
  }
}
