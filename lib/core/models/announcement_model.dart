/// ==============================================================================
/// ANNOUNCEMENT_MODEL.DART
/// Purpose: Strongly-typed Dart class for Digital Notice Board & PG Broadcasts
/// Matches: public.announcements table in Supabase
/// Source: supabase/migrations/06_create_tenant_living_and_notices_tables.sql
/// ==============================================================================

class AnnouncementModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String title;
  final String message;
  final String priority;
  final DateTime postedAt;
  final DateTime? createdAt;

  AnnouncementModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.title,
    required this.message,
    this.priority = 'NORMAL',
    required this.postedAt,
    this.createdAt,
  });

  bool get isUrgent => priority.toUpperCase() == 'URGENT';

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedPostedAt;
    if (json['posted_at'] != null) {
      parsedPostedAt =
          DateTime.tryParse(json['posted_at'].toString()) ?? DateTime.now();
    } else {
      parsedPostedAt = DateTime.now();
    }

    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notice',
      message: json['message']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'NORMAL',
      postedAt: parsedPostedAt,
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
      'title': title,
      'message': message,
      'priority': priority,
      'posted_at': postedAt.toIso8601String(),
    };
  }
}
