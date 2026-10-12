/// ==============================================================================
/// LEAD_MODEL.DART
/// Purpose: Strongly-typed Dart class for Website & Reception Marketing Inquiries
/// Matches: public.leads table in Supabase
/// Source: supabase/migrations/15_add_all_missing_audit_columns_and_leads.sql
/// ==============================================================================

class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String city;
  final String source;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.city = 'Bengaluru',
    this.source = 'Website',
    this.status = 'New',
    this.notes,
    this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      city: json['city']?.toString() ?? 'Bengaluru',
      source: json['source']?.toString() ?? 'Website',
      status: json['status']?.toString() ?? 'New',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      'city': city,
      'source': source,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  LeadModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? city,
    String? source,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
