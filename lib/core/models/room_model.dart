/// ==============================================================================
/// ROOM_MODEL.DART
/// Purpose: Strongly-typed Dart class for Physical Rooms & Floors
/// Matches: public.rooms table in Supabase
/// Source: supabase/migrations/02_create_rooms_and_beds_tables.sql
/// ==============================================================================

import 'bed_model.dart';

class RoomModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final int floorNumber;
  final String floorLabel;
  final String roomNumber;
  final String sharingType;
  final int totalBeds;
  final double rentPerBed;
  final double depositPerBed;
  final double refundableDeposit;
  final List<BedModel> beds;
  final DateTime? createdAt;

  RoomModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    this.floorNumber = 1,
    this.floorLabel = '1st Floor',
    required this.roomNumber,
    this.sharingType = '2-Sharing',
    this.totalBeds = 2,
    this.rentPerBed = 0.0,
    this.depositPerBed = 0.0,
    this.refundableDeposit = 0.0,
    this.beds = const [],
    this.createdAt,
  });

  /// Computed occupancy stats
  int get occupiedBedCount => beds.where((b) => b.isOccupied).length;
  int get vacantBedCount => beds.where((b) => b.isVacant).length;
  bool get isFull => occupiedBedCount >= totalBeds;

  /// Deserializer from Supabase JSON
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final rawRent = json['rent_per_bed'];
    final double rent = rawRent is num
        ? rawRent.toDouble()
        : (double.tryParse(rawRent?.toString() ?? '0.0') ?? 0.0);

    final rawDeposit = json['deposit_per_bed'];
    final double deposit = rawDeposit is num
        ? rawDeposit.toDouble()
        : (double.tryParse(rawDeposit?.toString() ?? '0.0') ?? 0.0);

    final rawRefundable = json['refundable_deposit'];
    final double refundable = rawRefundable is num
        ? rawRefundable.toDouble()
        : (double.tryParse(rawRefundable?.toString() ?? '') ?? deposit);

    List<BedModel> parsedBeds = [];
    if (json['beds'] != null && json['beds'] is List) {
      parsedBeds = (json['beds'] as List)
          .map((b) => BedModel.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    }

    return RoomModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      floorNumber: json['floor_number'] is int
          ? json['floor_number']
          : (int.tryParse(json['floor_number']?.toString() ?? '1') ?? 1),
      floorLabel: json['floor_label']?.toString() ?? '1st Floor',
      roomNumber: json['room_number']?.toString() ?? '101',
      sharingType: json['sharing_type']?.toString() ?? '2-Sharing',
      totalBeds: json['total_beds'] is int
          ? json['total_beds']
          : (int.tryParse(json['total_beds']?.toString() ?? '2') ?? 2),
      rentPerBed: rent,
      depositPerBed: deposit,
      refundableDeposit: refundable,
      beds: parsedBeds,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializer to Supabase JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'floor_number': floorNumber,
      'floor_label': floorLabel,
      'room_number': roomNumber,
      'sharing_type': sharingType,
      'total_beds': totalBeds,
      'rent_per_bed': rentPerBed,
      'deposit_per_bed': depositPerBed,
      'refundable_deposit': refundableDeposit,
    };
  }
}
