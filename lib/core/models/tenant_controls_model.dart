/// ==============================================================================
/// URBANSTAY CORE ENTERPRISE DATA MODEL
/// Pillar 7: Resident App Feature Toggles / Controls
/// Table: public.tenant_controls
/// ==============================================================================

class TenantControlsModel {
  final String? id;
  final String propertyId;
  final bool payViaUpi;
  final bool paidViaCash;
  final bool raiseTicket;
  final bool ticketStatus;
  final bool bedsheetChange;
  final bool rentAgreement;
  final DateTime? updatedAt;

  const TenantControlsModel({
    this.id,
    required this.propertyId,
    this.payViaUpi = true,
    this.paidViaCash = true,
    this.raiseTicket = true,
    this.ticketStatus = true,
    this.bedsheetChange = true,
    this.rentAgreement = true,
    this.updatedAt,
  });

  factory TenantControlsModel.defaultControls(String propertyId) {
    return TenantControlsModel(
      propertyId: propertyId,
      payViaUpi: true,
      paidViaCash: true,
      raiseTicket: true,
      ticketStatus: true,
      bedsheetChange: true,
      rentAgreement: true,
    );
  }

  factory TenantControlsModel.fromJson(Map<String, dynamic> json) {
    return TenantControlsModel(
      id: json['id']?.toString(),
      propertyId: json['property_id']?.toString() ?? '',
      payViaUpi: json['pay_via_upi'] as bool? ?? true,
      paidViaCash: json['paid_via_cash'] as bool? ?? true,
      raiseTicket: json['raise_ticket'] as bool? ?? true,
      ticketStatus: json['ticket_status'] as bool? ?? true,
      bedsheetChange: json['bedsheet_change'] as bool? ?? true,
      rentAgreement: json['rent_agreement'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'pay_via_upi': payViaUpi,
      'paid_via_cash': paidViaCash,
      'raise_ticket': raiseTicket,
      'ticket_status': ticketStatus,
      'bedsheet_change': bedsheetChange,
      'rent_agreement': rentAgreement,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  TenantControlsModel copyWith({
    String? id,
    String? propertyId,
    bool? payViaUpi,
    bool? paidViaCash,
    bool? raiseTicket,
    bool? ticketStatus,
    bool? bedsheetChange,
    bool? rentAgreement,
    DateTime? updatedAt,
  }) {
    return TenantControlsModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      payViaUpi: payViaUpi ?? this.payViaUpi,
      paidViaCash: paidViaCash ?? this.paidViaCash,
      raiseTicket: raiseTicket ?? this.raiseTicket,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      bedsheetChange: bedsheetChange ?? this.bedsheetChange,
      rentAgreement: rentAgreement ?? this.rentAgreement,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
