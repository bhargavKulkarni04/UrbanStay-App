/// ==============================================================================
/// PROFILE_MODEL.DART
/// Purpose: Strongly-typed Dart class for User Profiles & Supabase Auth Mapping
/// Matches: public.profiles table in Supabase
/// Source: supabase/migrations/08_create_profiles_table.sql
/// ==============================================================================

class ProfileModel {
  final String id;
  final String phone;
  final String? fullName;
  final String role; // 'owner' or 'tenant'
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.phone,
    this.fullName,
    this.role = 'owner',
    this.createdAt,
  });

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isTenant => role.toLowerCase() == 'tenant';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      role: json['role']?.toString() ?? 'owner',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'phone': phone,
      if (fullName != null) 'full_name': fullName,
      'role': role,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
