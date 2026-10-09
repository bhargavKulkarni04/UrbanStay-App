// ==============================================================================
// 🕉️ URBANSTAY — MASTER CENTRALISED DATABASE & API SERVICE
// 🌟 Om Shri Raghavendraya Namaha ✨
// ==============================================================================
// Centralized enterprise backbone (modeled after NoBrokerHood & MyGate architecture).
// Serves all Owner feature folders and Resident/Tenant feature folders.
// ==============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  /// Direct client instance
  SupabaseClient get client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & SESSION HELPERS
  // ---------------------------------------------------------------------------

  /// Currently logged in user (null if guest/unauthenticated)
  User? get currentUser => client.auth.currentUser;

  /// Current user unique ID
  String? get currentUserId => client.auth.currentUser?.id;

  /// Whether a session is active
  bool get isAuthenticated => currentUser != null;

  /// Phone number authentication (OTP dispatch)
  Future<void> sendOtp({required String phone}) async {
    await client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Verify 6-digit OTP
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign out current session
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // 🏢 OWNER CORE SERVICES
  // ---------------------------------------------------------------------------

  /// Fetch primary property profile for the logged in owner
  Future<Map<String, dynamic>?> getOwnerProperty({String? ownerId}) async {
    final uid = ownerId ?? currentUserId;
    if (uid == null) return null;

    final response = await client
        .from('properties')
        .select('*')
        .eq('owner_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Create or update property details from onboarding setup
  Future<Map<String, dynamic>> saveProperty({
    required String name,
    required String address,
    required String city,
    required String upiId,
    required int totalFloors,
    String? ownerId,
  }) async {
    final uid = ownerId ?? currentUserId;
    final payload = {
      'owner_id': uid,
      'name': name,
      'address': address,
      'city': city,
      'upi_id': upiId,
      'total_floors': totalFloors,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('properties')
        .upsert(payload)
        .select()
        .single();

    return response;
  }

  /// Create full onboarding property with rooms and beds in Supabase
  Future<Map<String, dynamic>> createFullProperty({
    required String brandName,
    required String propertyCode,
    required String genderCategory,
    required String propertyStructure,
    required String streetAddress,
    required String areaLocality,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    String? mapsUrl,
    String? liftCount,
    String? powerBackup,
    required String upiVpa,
    required String bankName,
    required String bankHolderName,
    String? creditingPhone,
    String? rentDueDay,
    String? gracePeriod,
    String? lateFee,
    String? noticePeriod,
    List<Map<String, dynamic>> roomsData = const [],
    String? ownerId,
  }) async {
    final uid = ownerId ?? currentUserId;
    final propPayload = {
      if (uid != null) 'owner_id': uid,
      'property_code': propertyCode,
      'brand_name': brandName,
      'gender_category': genderCategory,
      'property_structure': propertyStructure,
      'street_address': streetAddress,
      'area_locality': areaLocality,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'maps_url': mapsUrl,
      'lift_count': liftCount,
      'power_backup': powerBackup,
      'upi_vpa': upiVpa,
      'bank_name': bankName,
      'bank_holder_name': bankHolderName,
      'crediting_phone': creditingPhone,
      'rent_due_day': rentDueDay ?? '5th',
      'grace_period': gracePeriod ?? '3 Days',
      'late_fee': lateFee ?? '₹50',
      'notice_period': noticePeriod ?? '30 Days',
    };

    final property = await client
        .from('properties')
        .insert(propPayload)
        .select()
        .single();

    final propertyId = property['id'] as String;

    // Insert rooms & beds if provided
    for (final r in roomsData) {
      final roomPayload = {
        'property_id': propertyId,
        'floor_number': r['floor_number'] ?? 1,
        'floor_label': r['floor_label'] ?? '1st Floor',
        'room_number': r['room_number'] ?? '101',
        'sharing_type': r['sharing_type'] ?? '2-Sharing',
        'total_beds': r['total_beds'] ?? 2,
        'rent_per_bed': r['rent_per_bed'] ?? 8000,
        'deposit_per_bed': r['deposit_per_bed'] ?? 15000,
      };

      final insertedRoom = await client
          .from('rooms')
          .insert(roomPayload)
          .select()
          .single();

      final roomId = insertedRoom['id'] as String;
      final int totalBeds = (r['total_beds'] as int?) ?? 2;

      final List<Map<String, dynamic>> bedsPayload = [];
      for (int b = 0; b < totalBeds; b++) {
        final bedLetter = String.fromCharCode(65 + b); // 'Bed A', 'Bed B'
        bedsPayload.add({
          'room_id': roomId,
          'bed_code': 'Bed $bedLetter',
          'is_occupied': false,
          'status': 'Vacant',
        });
      }

      if (bedsPayload.isNotEmpty) {
        await client.from('beds').insert(bedsPayload);
      }
    }

    return property;
  }

  /// Live real-time bed statistics (Occupied beds, Total beds)
  Future<Map<String, int>> getBedMetrics(String propertyId) async {
    final totalBedsRes = await client
        .from('beds')
        .select('id, is_occupied')
        .eq('property_id', propertyId);

    final List beds = totalBedsRes as List;
    final int total = beds.length;
    final int occupied = beds.where((b) => b['is_occupied'] == true).length;

    return {
      'total': total,
      'occupied': occupied,
      'available': total - occupied,
    };
  }

  /// Fetch all rooms and their beds for matrix view
  Future<List<Map<String, dynamic>>> getRoomsWithBeds(String propertyId) async {
    final response = await client
        .from('rooms')
        .select('*, beds(*)')
        .eq('property_id', propertyId)
        .order('floor_number', ascending: true)
        .order('room_number', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch live rent collection dues & status for the month
  Future<List<Map<String, dynamic>>> getMonthlyRentLedger(String propertyId) async {
    final response = await client
        .from('rent_ledgers')
        .select('*, tenants(id, full_name, phone, room_number, bed_number)')
        .eq('property_id', propertyId)
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch SaaS subscription billing invoices for the owner
  Future<List<Map<String, dynamic>>> getSaasInvoices({String? ownerId}) async {
    final uid = ownerId ?? currentUserId;
    if (uid == null) return [];

    final response = await client
        .from('saas_invoices')
        .select('*')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // 👤 RESIDENT / TENANT SERVICES
  // ---------------------------------------------------------------------------

  /// Fetch tenant profile & current stay details
  Future<Map<String, dynamic>?> getTenantProfile({String? tenantId}) async {
    final uid = tenantId ?? currentUserId;
    if (uid == null) return null;

    final response = await client
        .from('tenants')
        .select('*, properties(id, name, address, upi_id)')
        .eq('user_id', uid)
        .maybeSingle();

    return response;
  }

  /// Fetch pending rent dues for resident
  Future<List<Map<String, dynamic>>> getTenantDues(String tenantId) async {
    final response = await client
        .from('rent_ledgers')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('status', 'PENDING')
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Submit 0% Direct UPI payment proof (UTR / Reference number)
  Future<void> submitUpiPaymentProof({
    required String tenantId,
    required String propertyId,
    required double amount,
    required String utrNumber,
    String? screenshotUrl,
  }) async {
    await client.from('upi_payment_submissions').insert({
      'tenant_id': tenantId,
      'property_id': propertyId,
      'amount': amount,
      'utr_number': utrNumber,
      'screenshot_url': screenshotUrl,
      'status': 'PENDING_APPROVAL',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch paid receipts for tenant rent payments
  Future<List<Map<String, dynamic>>> getTenantReceipts(String tenantId) async {
    final response = await client
        .from('rent_receipts')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
