/// ==============================================================================
/// FOOD_MENU_MODEL.DART
/// Purpose: Strongly-typed Dart class for Weekly Multi-Week Rotating Meal Menu
/// Matches: public.food_menus table in Supabase
/// Source: supabase/migrations/13_create_food_menus_table.sql & MASTER_DATABASE_SCHEMA.md
/// ==============================================================================

class FoodMenuModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final int cycleWeeks;
  final int weekNumber;
  final String dayOfWeek;
  final String breakfast;
  final String lunch;
  final String dinner;
  final DateTime? updatedAt;

  FoodMenuModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.cycleWeeks = 2,
    this.weekNumber = 1,
    required this.dayOfWeek,
    this.breakfast = '',
    this.lunch = '',
    this.dinner = '',
    this.updatedAt,
  });

  factory FoodMenuModel.fromJson(Map<String, dynamic> json) {
    return FoodMenuModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      cycleWeeks: json['cycle_weeks'] is int
          ? json['cycle_weeks'] as int
          : int.tryParse(json['cycle_weeks']?.toString() ?? '2') ?? 2,
      weekNumber: json['week_number'] is int
          ? json['week_number'] as int
          : int.tryParse(json['week_number']?.toString() ?? '1') ?? 1,
      dayOfWeek: json['day_of_week']?.toString() ?? 'MON',
      breakfast: json['breakfast']?.toString() ?? '',
      lunch: json['lunch']?.toString() ?? '',
      dinner: json['dinner']?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'cycle_weeks': cycleWeeks,
      'week_number': weekNumber,
      'day_of_week': dayOfWeek,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  FoodMenuModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    int? cycleWeeks,
    int? weekNumber,
    String? dayOfWeek,
    String? breakfast,
    String? lunch,
    String? dinner,
    DateTime? updatedAt,
  }) {
    return FoodMenuModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      cycleWeeks: cycleWeeks ?? this.cycleWeeks,
      weekNumber: weekNumber ?? this.weekNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
