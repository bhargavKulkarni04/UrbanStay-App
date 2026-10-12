/// ==============================================================================
/// PROPERTY_TEAM_MODEL.DART
/// Purpose: Strongly-typed Dart class for Co-Owners & PG Managers Team
/// Matches: public.property_team table in Supabase
/// Source: supabase/migrations/12_create_property_team_table.sql
/// ==============================================================================

class PropertyTeamModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String name;
  final String phone;
  final String role;
  final String status;
  final List<String> assignedPropertyIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyTeamModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.name,
    required this.phone,
    this.role = 'manager',
    this.status = 'Active',
    this.assignedPropertyIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Computed initials for avatar
  String get initials {
    if (name.trim().isEmpty) return 'TM';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Whether member is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Deserializer from Supabase JSON
  factory PropertyTeamModel.fromJson(Map<String, dynamic> json) {
    List<String> assignedIds = [];
    if (json['assigned_property_ids'] != null) {
      assignedIds = (json['assigned_property_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return PropertyTeamModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Team Member',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'manager',
      status: json['status']?.toString() ?? 'Active',
      assignedPropertyIds: assignedIds,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Serializer to Supabase JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      if (assignedPropertyIds.isNotEmpty)
        'assigned_property_ids': assignedPropertyIds,
    };
  }

  /// CopyWith helper
  PropertyTeamModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? name,
    String? phone,
    String? role,
    String? status,
    List<String>? assignedPropertyIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyTeamModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      assignedPropertyIds: assignedPropertyIds ?? this.assignedPropertyIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
