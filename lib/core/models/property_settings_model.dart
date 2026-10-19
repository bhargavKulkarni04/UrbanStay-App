/// ==============================================================================
/// PROPERTY_SETTINGS_MODEL.DART
/// Purpose: Strongly-typed Dart class for Property House Rules, Business & Settings
/// Matches: public.property_settings table in Supabase
/// Source: supabase/migrations/05_create_billing_and_settings_tables.sql & 17
/// ==============================================================================

class PropertySettingsModel {
  final String id;
  final String propertyId;
  final String propertyName;

  // Curfew & Timings
  final String gateClosingTime;
  final String morningGateOpenTime;

  // House Rules & Amenities
  final bool visitorAllowed;
  final bool alcoholSmokingAllowed;
  final String wifiSsid;
  final String wifiPassword;
  final String emergencyPhone;

  // Business & Tax Details
  final String legalEntityName;
  final String gstNumber;
  final String cinNumber;
  final String bbmpLicenseNumber;

  // Direct Bank Account
  final String bankAccountNumber;
  final String ifscCode;

  // Stay & Contract Policies
  final String lockinPeriod;
  final String agreementDuration;
  final String receiptTerms;

  // Dynamic Sharing Tariffs (1, 2, 3, 4 sharing rents & deposits)
  final List<dynamic> sharingTariffs;
  final int sharing1Rent;
  final int sharing1Deposit;
  final int sharing2Rent;
  final int sharing2Deposit;
  final int sharing3Rent;
  final int sharing3Deposit;
  final int sharing4Rent;
  final int sharing4Deposit;

  // Rent & Dues Automation Switches
  final bool allowOnlineUpi;
  final bool dailyLateFineEnabled;
  final bool acceptPartialPayments;
  final bool autoSendWhatsappReceipts;
  final bool autoDuesReminders;

  // Onboarding & KYC Automation Switches
  final bool autoWelcomeWhatsapp;
  final bool autoApproveBookings;
  final bool sendDepositReminders;
  final bool lockProfileAfterMovein;
  final bool mandatoryTenantKyc;
  final bool requireComplaintPhoto;
  final String kycApplicableTo;
  final String stampBusinessName;
  final String authorizedSignatory;
  // Custom Identity & Document Proofs
  final String ownerFatherName;
  final String ownerPanNumber;
  final String gstDocUrl;
  final String tradeLicenseDocUrl;
  final String appLanguage;

  final Map<String, dynamic>? tenantControls;
  final DateTime? createdAt;

  PropertySettingsModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.gateClosingTime = '10:30 PM',
    this.morningGateOpenTime = '05:30 AM',
    this.visitorAllowed = false,
    this.alcoholSmokingAllowed = false,
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.emergencyPhone = '',
    this.legalEntityName = '',
    this.gstNumber = '',
    this.cinNumber = '',
    this.bbmpLicenseNumber = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.lockinPeriod = '3 Months',
    this.agreementDuration = '11 Months',
    this.receiptTerms = '',
    this.sharingTariffs = const [],
    this.sharing1Rent = 0,
    this.sharing1Deposit = 0,
    this.sharing2Rent = 0,
    this.sharing2Deposit = 0,
    this.sharing3Rent = 0,
    this.sharing3Deposit = 0,
    this.sharing4Rent = 0,
    this.sharing4Deposit = 0,
    this.allowOnlineUpi = true,
    this.dailyLateFineEnabled = false,
    this.acceptPartialPayments = true,
    this.autoSendWhatsappReceipts = true,
    this.autoDuesReminders = true,
    this.autoWelcomeWhatsapp = true,
    this.autoApproveBookings = false,
    this.sendDepositReminders = true,
    this.lockProfileAfterMovein = true,
    this.mandatoryTenantKyc = true,
    this.requireComplaintPhoto = true,
    this.kycApplicableTo = 'All Residents',
    this.stampBusinessName = '',
    this.authorizedSignatory = '',
    this.ownerFatherName = '',
    this.ownerPanNumber = '',
    this.gstDocUrl = '',
    this.tradeLicenseDocUrl = '',
    this.appLanguage = 'English',
    this.tenantControls,
    this.createdAt,
  });

  factory PropertySettingsModel.fromJson(Map<String, dynamic> json) {
    return PropertySettingsModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      gateClosingTime: json['gate_closing_time']?.toString() ?? '10:30 PM',
      morningGateOpenTime:
          json['morning_gate_open_time']?.toString() ?? '05:30 AM',
      visitorAllowed: json['visitor_allowed'] == true ||
          json['visitor_allowed']?.toString().toLowerCase() == 'true',
      alcoholSmokingAllowed: json['alcohol_smoking_allowed'] == true ||
          json['alcohol_smoking_allowed']?.toString().toLowerCase() == 'true',
      wifiSsid: json['wifi_ssid']?.toString() ?? '',
      wifiPassword: json['wifi_password']?.toString() ?? '',
      emergencyPhone: json['emergency_phone']?.toString() ?? '',
      legalEntityName: json['legal_entity_name']?.toString() ?? '',
      gstNumber: json['gst_number']?.toString() ?? '',
      cinNumber: json['cin_number']?.toString() ?? '',
      bbmpLicenseNumber: json['bbmp_license_number']?.toString() ?? '',
      bankAccountNumber: json['bank_account_number']?.toString() ?? '',
      ifscCode: json['ifsc_code']?.toString() ?? '',
      lockinPeriod: json['lockin_period']?.toString() ?? '3 Months',
      agreementDuration: json['agreement_duration']?.toString() ?? '11 Months',
      receiptTerms: json['receipt_terms']?.toString() ?? '',
      sharingTariffs: json['sharing_tariffs'] is List
          ? (json['sharing_tariffs'] as List<dynamic>)
          : const [],
      sharing1Rent: json['sharing_1_rent'] is int
          ? json['sharing_1_rent']
          : (int.tryParse(json['sharing_1_rent']?.toString() ?? '0') ?? 0),
      sharing1Deposit: json['sharing_1_deposit'] is int
          ? json['sharing_1_deposit']
          : (int.tryParse(json['sharing_1_deposit']?.toString() ?? '0') ?? 0),
      sharing2Rent: json['sharing_2_rent'] is int
          ? json['sharing_2_rent']
          : (int.tryParse(json['sharing_2_rent']?.toString() ?? '0') ?? 0),
      sharing2Deposit: json['sharing_2_deposit'] is int
          ? json['sharing_2_deposit']
          : (int.tryParse(json['sharing_2_deposit']?.toString() ?? '0') ?? 0),
      sharing3Rent: json['sharing_3_rent'] is int
          ? json['sharing_3_rent']
          : (int.tryParse(json['sharing_3_rent']?.toString() ?? '0') ?? 0),
      sharing3Deposit: json['sharing_3_deposit'] is int
          ? json['sharing_3_deposit']
          : (int.tryParse(json['sharing_3_deposit']?.toString() ?? '0') ?? 0),
      sharing4Rent: json['sharing_4_rent'] is int
          ? json['sharing_4_rent']
          : (int.tryParse(json['sharing_4_rent']?.toString() ?? '0') ?? 0),
      sharing4Deposit: json['sharing_4_deposit'] is int
          ? json['sharing_4_deposit']
          : (int.tryParse(json['sharing_4_deposit']?.toString() ?? '0') ?? 0),
      allowOnlineUpi: json['allow_online_upi'] == null ||
          json['allow_online_upi'] == true ||
          json['allow_online_upi']?.toString().toLowerCase() == 'true',
      dailyLateFineEnabled: json['daily_late_fine_enabled'] == true ||
          json['daily_late_fine_enabled']?.toString().toLowerCase() == 'true',
      acceptPartialPayments: json['accept_partial_payments'] == null ||
          json['accept_partial_payments'] == true ||
          json['accept_partial_payments']?.toString().toLowerCase() == 'true',
      autoSendWhatsappReceipts: json['auto_send_whatsapp_receipts'] == null ||
          json['auto_send_whatsapp_receipts'] == true ||
          json['auto_send_whatsapp_receipts']?.toString().toLowerCase() ==
              'true',
      autoDuesReminders: json['auto_dues_reminders'] == null ||
          json['auto_dues_reminders'] == true ||
          json['auto_dues_reminders']?.toString().toLowerCase() == 'true',
      autoWelcomeWhatsapp: json['auto_welcome_whatsapp'] == null ||
          json['auto_welcome_whatsapp'] == true ||
          json['auto_welcome_whatsapp']?.toString().toLowerCase() == 'true',
      autoApproveBookings: json['auto_approve_bookings'] == true ||
          json['auto_approve_bookings']?.toString().toLowerCase() == 'true',
      sendDepositReminders: json['send_deposit_reminders'] == null ||
          json['send_deposit_reminders'] == true ||
          json['send_deposit_reminders']?.toString().toLowerCase() == 'true',
      lockProfileAfterMovein: json['lock_profile_after_movein'] == null ||
          json['lock_profile_after_movein'] == true ||
          json['lock_profile_after_movein']?.toString().toLowerCase() ==
              'true',
      mandatoryTenantKyc: json['mandatory_tenant_kyc'] == null ||
          json['mandatory_tenant_kyc'] == true ||
          json['mandatory_tenant_kyc']?.toString().toLowerCase() == 'true',
      requireComplaintPhoto: json['require_complaint_photo'] == null ||
          json['require_complaint_photo'] == true ||
          json['require_complaint_photo']?.toString().toLowerCase() == 'true',
      kycApplicableTo:
          json['kyc_applicable_to']?.toString() ?? 'All Residents',
      stampBusinessName: json['stamp_business_name']?.toString() ?? '',
      authorizedSignatory: json['authorized_signatory']?.toString() ?? '',
      ownerFatherName: json['owner_father_name']?.toString() ?? '',
      ownerPanNumber: json['owner_pan_number']?.toString() ?? '',
      gstDocUrl: json['gst_doc_url']?.toString() ?? '',
      tradeLicenseDocUrl: json['trade_license_doc_url']?.toString() ?? '',
      appLanguage: json['app_language']?.toString() ?? 'English',
      tenantControls: json['tenant_controls'] is Map
          ? Map<String, dynamic>.from(json['tenant_controls'])
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
      'gate_closing_time': gateClosingTime,
      'morning_gate_open_time': morningGateOpenTime,
      'visitor_allowed': visitorAllowed,
      'alcohol_smoking_allowed': alcoholSmokingAllowed,
      if (wifiSsid.isNotEmpty) 'wifi_ssid': wifiSsid,
      if (wifiPassword.isNotEmpty) 'wifi_password': wifiPassword,
      if (emergencyPhone.isNotEmpty) 'emergency_phone': emergencyPhone,
      if (legalEntityName.isNotEmpty) 'legal_entity_name': legalEntityName,
      if (gstNumber.isNotEmpty) 'gst_number': gstNumber,
      if (cinNumber.isNotEmpty) 'cin_number': cinNumber,
      if (bbmpLicenseNumber.isNotEmpty)
        'bbmp_license_number': bbmpLicenseNumber,
      if (bankAccountNumber.isNotEmpty)
        'bank_account_number': bankAccountNumber,
      if (ifscCode.isNotEmpty) 'ifsc_code': ifscCode,
      'lockin_period': lockinPeriod,
      'agreement_duration': agreementDuration,
      if (receiptTerms.isNotEmpty) 'receipt_terms': receiptTerms,
      'sharing_tariffs': sharingTariffs,
      'sharing_1_rent': sharing1Rent,
      'sharing_1_deposit': sharing1Deposit,
      'sharing_2_rent': sharing2Rent,
      'sharing_2_deposit': sharing2Deposit,
      'sharing_3_rent': sharing3Rent,
      'sharing_3_deposit': sharing3Deposit,
      'sharing_4_rent': sharing4Rent,
      'sharing_4_deposit': sharing4Deposit,
      'allow_online_upi': allowOnlineUpi,
      'daily_late_fine_enabled': dailyLateFineEnabled,
      'accept_partial_payments': acceptPartialPayments,
      'auto_send_whatsapp_receipts': autoSendWhatsappReceipts,
      'auto_dues_reminders': autoDuesReminders,
      'auto_welcome_whatsapp': autoWelcomeWhatsapp,
      'auto_approve_bookings': autoApproveBookings,
      'send_deposit_reminders': sendDepositReminders,
      'lock_profile_after_movein': lockProfileAfterMovein,
      'mandatory_tenant_kyc': mandatoryTenantKyc,
      'require_complaint_photo': requireComplaintPhoto,
      'kyc_applicable_to': kycApplicableTo,
      if (stampBusinessName.isNotEmpty)
        'stamp_business_name': stampBusinessName,
      if (authorizedSignatory.isNotEmpty)
        'authorized_signatory': authorizedSignatory,
      if (ownerFatherName.isNotEmpty) 'owner_father_name': ownerFatherName,
      if (ownerPanNumber.isNotEmpty) 'owner_pan_number': ownerPanNumber,
      if (gstDocUrl.isNotEmpty) 'gst_doc_url': gstDocUrl,
      if (tradeLicenseDocUrl.isNotEmpty)
        'trade_license_doc_url': tradeLicenseDocUrl,
      'app_language': appLanguage,
      if (tenantControls != null) 'tenant_controls': tenantControls,
    };
  }
}
