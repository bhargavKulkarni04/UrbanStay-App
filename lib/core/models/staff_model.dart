/// ==============================================================================
/// STAFF_MODEL.DART
/// Purpose: Strongly-typed Dart class for UrbanStay Staff Directory & Payroll
/// Matches: public.staff table in Supabase
/// Source: supabase/migrations/04_create_operations_and_staff_tables.sql
/// ==============================================================================

class StaffModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String name;
  final String role;
  final String? workTitle;
  final String phone;
  final double monthlySalary;
  final String salaryStatus;
  final DateTime? createdAt;

  StaffModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.name,
    required this.role,
    this.workTitle,
    required this.phone,
    required this.monthlySalary,
    this.salaryStatus = 'pending',
    this.createdAt,
  });

  /// Initials computed from name (e.g. 'Ramesh Kumar' -> 'RK')
  String get initials {
    if (name.trim().isEmpty) return 'ST';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Display title: prefer workTitle if available, fallback to role
  String get displayWorkTitle {
    if (workTitle != null && workTitle!.trim().isNotEmpty) {
      return workTitle!.trim();
    }
    return role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : 'Staff';
  }

  /// Whether salary is marked as paid
  bool get isPaid => salaryStatus.toLowerCase() == 'paid';

  /// Backward compatible alias for monthlySalary
  double get salary => monthlySalary;

  /// Backward compatible alias for isPaid
  bool get isSalaryPaid => isPaid;

  /// Factory deserializer from Supabase JSON map
  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final rawSalary = json['monthly_salary'] ?? json['salary'];
    final double salary = rawSalary is num
        ? rawSalary.toDouble()
        : (double.tryParse(rawSalary?.toString() ?? '0.0') ?? 0.0);

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString());
    }

    return StaffModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Staff Member',
      role: (json['role']?.toString() ?? 'warden').toLowerCase(),
      workTitle: json['work_title']?.toString(),
      phone: json['phone']?.toString() ?? '',
      monthlySalary: salary,
      salaryStatus: (json['salary_status'] ?? json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: parsedCreatedAt,
    );
  }

  /// Serializer to Supabase JSON payload
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'name': name,
      'role': role.toLowerCase(),
      if (workTitle != null && workTitle!.trim().isNotEmpty)
        'work_title': workTitle!.trim(),
      'phone': phone,
      'monthly_salary': monthlySalary,
      'salary_status': salaryStatus,
    };
  }

  /// CopyWith helper for state updates
  StaffModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? name,
    String? role,
    String? workTitle,
    String? phone,
    double? monthlySalary,
    String? salaryStatus,
    DateTime? createdAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      name: name ?? this.name,
      role: role ?? this.role,
      workTitle: workTitle ?? this.workTitle,
      phone: phone ?? this.phone,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      salaryStatus: salaryStatus ?? this.salaryStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
