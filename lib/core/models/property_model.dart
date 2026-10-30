/// ==============================================================================
/// PROPERTY_MODEL.DART
/// Purpose: Strongly-typed Dart class for PG Property Building Profile
/// Matches: public.properties table in Supabase
/// Source: supabase/migrations/01_create_properties_table.sql
/// ==============================================================================

class PropertyModel {
  final String id;
  final String propertyName;
  final String propertyCode;
  final String genderCategory;
  final String propertyStructure;
  final String? streetAddress;
  final String? areaLocality;
  final String? landmark;
  final String city;
  final String state;
  final String? pincode;
  final String? mapsUrl;
  final String liftCount;
  final String powerBackup;
  final String washingMachineCount;
  final int totalBeds;
  final String rentDueDay;
  final String gracePeriod;
  final double lateFee;
  final String noticePeriod;
  final String? ownerLegalName;
  final String? ownerEmail;
  final String? bankHolderName;
  final String? bankName;
  final String? upiVpa;
  final String? creditingPhone;
  final String? ownerPhone;
  final String? bankQrUrl;
  final String? ownerAadhaarNumber;
  final int totalFloors;
  final int totalRooms;
  final bool groundFloorHasRooms;
  final String? ownerId;
  final DateTime? createdAt;

  PropertyModel({
    required this.id,
    required this.propertyName,
    required this.propertyCode,
    this.genderCategory = 'Coliving',
    this.propertyStructure = 'Independent Building',
    this.streetAddress,
    this.areaLocality,
    this.landmark,
    this.city = 'Bengaluru',
    this.state = 'Karnataka',
    this.pincode,
    this.mapsUrl,
    this.liftCount = 'None',
    this.powerBackup = 'None',
    this.washingMachineCount = 'None',
    this.totalBeds = 0,
    this.rentDueDay = '5th',
    this.gracePeriod = '5 Days',
    this.lateFee = 200.0,
    this.noticePeriod = '30 Days',
    this.ownerLegalName,
    this.ownerEmail,
    this.bankHolderName,
    this.bankName,
    this.upiVpa,
    this.creditingPhone,
    this.ownerPhone,
    this.bankQrUrl,
    this.ownerAadhaarNumber,
    this.totalFloors = 1,
    this.totalRooms = 0,
    this.groundFloorHasRooms = true,
    this.ownerId,
    this.createdAt,
  });

  /// Computed full address
  String get fullAddress {
    final parts = [
      if (streetAddress != null && streetAddress!.isNotEmpty) streetAddress,
      if (areaLocality != null && areaLocality!.isNotEmpty) areaLocality,
      if (landmark != null && landmark!.isNotEmpty) landmark,
      city,
      if (pincode != null && pincode!.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }

  /// Deserializer from Supabase JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final rawLateFee = json['late_fee'];
    final double lateFee = rawLateFee is num
        ? rawLateFee.toDouble()
        : (double.tryParse(rawLateFee?.toString() ?? '200.0') ?? 200.0);

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      propertyName:
          json['property_name']?.toString() ?? json['name']?.toString() ?? '',
      propertyCode: json['property_code']?.toString() ?? 'URBAN-101',
      genderCategory: json['gender_category']?.toString() ?? 'Coliving',
      propertyStructure:
          json['property_structure']?.toString() ?? 'Independent Building',
      streetAddress:
          json['street_address']?.toString() ?? json['address']?.toString(),
      areaLocality: json['area_locality']?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString() ?? 'Bengaluru',
      state: json['state']?.toString() ?? 'Karnataka',
      pincode: json['pincode']?.toString(),
      mapsUrl: json['maps_url']?.toString(),
      liftCount: json['lift_count']?.toString() ?? 'None',
      powerBackup: json['power_backup']?.toString() ?? 'None',
      washingMachineCount: json['washing_machine_count']?.toString() ?? 'None',
      totalBeds: json['total_beds'] is int
          ? json['total_beds']
          : (int.tryParse(json['total_beds']?.toString() ?? '0') ?? 0),
      rentDueDay: json['rent_due_day']?.toString() ?? '5th',
      gracePeriod: json['grace_period']?.toString() ?? '5 Days',
      lateFee: lateFee,
      noticePeriod: json['notice_period']?.toString() ?? '30 Days',
      ownerLegalName: json['owner_legal_name']?.toString() ??
          json['owner_name']?.toString(),
      ownerEmail: json['owner_email']?.toString(),
      bankHolderName: json['bank_holder_name']?.toString(),
      bankName: json['bank_name']?.toString(),
      upiVpa: json['upi_vpa']?.toString() ?? json['upi_id']?.toString(),
      creditingPhone: json['crediting_phone']?.toString(),
      ownerPhone:
          json['owner_phone']?.toString() ?? json['owner_whatsapp']?.toString(),
      bankQrUrl: json['bank_qr_url']?.toString(),
      ownerAadhaarNumber: json['owner_aadhaar_number']?.toString(),
      totalFloors: json['total_floors'] is int
          ? json['total_floors']
          : (int.tryParse(json['total_floors']?.toString() ?? '1') ?? 1),
      totalRooms: json['total_rooms'] is int
          ? json['total_rooms']
          : (int.tryParse(json['total_rooms']?.toString() ?? '0') ?? 0),
      groundFloorHasRooms: json['ground_floor_has_rooms'] is bool
          ? json['ground_floor_has_rooms'] as bool
          : (json['ground_floor_has_rooms'] == null
              ? true
              : (json['ground_floor_has_rooms'].toString().toLowerCase() ==
                  'true')),
      ownerId: json['owner_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializer to Supabase JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_name': propertyName,
      'property_code': propertyCode,
      'gender_category': genderCategory,
      'property_structure': propertyStructure,
      if (streetAddress != null) 'street_address': streetAddress,
      if (areaLocality != null) 'area_locality': areaLocality,
      if (landmark != null) 'landmark': landmark,
      'city': city,
      'state': state,
      if (pincode != null) 'pincode': pincode,
      if (mapsUrl != null) 'maps_url': mapsUrl,
      'lift_count': liftCount,
      'power_backup': powerBackup,
      'washing_machine_count': washingMachineCount,
      'total_beds': totalBeds,
      'rent_due_day': rentDueDay,
      'grace_period': gracePeriod,
      'late_fee': lateFee,
      'notice_period': noticePeriod,
      if (ownerLegalName != null) 'owner_legal_name': ownerLegalName,
      if (ownerEmail != null) 'owner_email': ownerEmail,
      if (bankHolderName != null) 'bank_holder_name': bankHolderName,
      if (bankName != null) 'bank_name': bankName,
      if (upiVpa != null) 'upi_vpa': upiVpa,
      if (creditingPhone != null) 'crediting_phone': creditingPhone,
      if (ownerPhone != null) 'owner_phone': ownerPhone,
      if (bankQrUrl != null) 'bank_qr_url': bankQrUrl,
      if (ownerAadhaarNumber != null)
        'owner_aadhaar_number': ownerAadhaarNumber,
      'total_floors': totalFloors,
      'total_rooms': totalRooms,
      'ground_floor_has_rooms': groundFloorHasRooms,
      if (ownerId != null) 'owner_id': ownerId,
    };
  }
}
