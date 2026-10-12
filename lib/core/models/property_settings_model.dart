/// ==============================================================================
/// PROPERTY_SETTINGS_MODEL.DART
/// Purpose: Strongly-typed Dart class for Property House Rules & Amenities
/// Matches: public.property_settings table in Supabase
/// Source: supabase/migrations/05_create_billing_and_settings_tables.sql & 15
/// ==============================================================================

class PropertySettingsModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String gateClosingTime;
  final bool visitorAllowed;
  final bool alcoholSmokingAllowed;
  final String wifiSsid;
  final String wifiPassword;
  final String emergencyPhone;
  final Map<String, dynamic>? tenantControls;
  final DateTime? createdAt;

  PropertySettingsModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.gateClosingTime = '10:30 PM',
    this.visitorAllowed = false,
    this.alcoholSmokingAllowed = false,
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.emergencyPhone = '',
    this.tenantControls,
    this.createdAt,
  });

  factory PropertySettingsModel.fromJson(Map<String, dynamic> json) {
    return PropertySettingsModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      gateClosingTime: json['gate_closing_time']?.toString() ?? '10:30 PM',
      visitorAllowed: json['visitor_allowed'] == true ||
          json['visitor_allowed']?.toString().toLowerCase() == 'true',
      alcoholSmokingAllowed: json['alcohol_smoking_allowed'] == true ||
          json['alcohol_smoking_allowed']?.toString().toLowerCase() == 'true',
      wifiSsid: json['wifi_ssid']?.toString() ?? '',
      wifiPassword: json['wifi_password']?.toString() ?? '',
      emergencyPhone: json['emergency_phone']?.toString() ?? '',
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
      'visitor_allowed': visitorAllowed,
      'alcohol_smoking_allowed': alcoholSmokingAllowed,
      if (wifiSsid.isNotEmpty) 'wifi_ssid': wifiSsid,
      if (wifiPassword.isNotEmpty) 'wifi_password': wifiPassword,
      if (emergencyPhone.isNotEmpty) 'emergency_phone': emergencyPhone,
      if (tenantControls != null) 'tenant_controls': tenantControls,
    };
  }

  PropertySettingsModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? gateClosingTime,
    bool? visitorAllowed,
    bool? alcoholSmokingAllowed,
    String? wifiSsid,
    String? wifiPassword,
    String? emergencyPhone,
    DateTime? createdAt,
  }) {
    return PropertySettingsModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      gateClosingTime: gateClosingTime ?? this.gateClosingTime,
      visitorAllowed: visitorAllowed ?? this.visitorAllowed,
      alcoholSmokingAllowed:
          alcoholSmokingAllowed ?? this.alcoholSmokingAllowed,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
