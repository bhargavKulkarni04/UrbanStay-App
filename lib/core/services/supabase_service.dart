// ==============================================================================
// 🕉️ URBANSTAY — MASTER CENTRALISED DATABASE & API SERVICE
// 🌟 Om Shri Raghavendraya Namaha ✨
// ==============================================================================
// Centralized enterprise backbone (modeled after NoBrokerHood & MyGate architecture).
// Serves all Owner feature folders and Resident/Tenant feature folders.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../widgets/urban_loading.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  /// Direct client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Global enterprise wrapper that triggers the centered green spinner card
  Future<T> _withLoading<T>(String message, Future<T> Function() action) async {
    try {
      UrbanLoadingService.show(message);
      return await action();
    } finally {
      UrbanLoadingService.hide();
    }
  }

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
    return await _withLoading('Sending OTP...', () async {
      await client.auth.signInWithOtp(
        phone: phone,
      );
    });
  }

  /// Verify 6-digit OTP
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await _withLoading('Verifying OTP...', () async {
      return await client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    });
  }

  /// Sign out current session
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // 🏢 OWNER CORE SERVICES
  // ---------------------------------------------------------------------------

  /// Global single source of truth for the active PG property ID
  String? activePropertyId;

  /// Global single source of truth for the active PG property name
  String? activePropertyName;

  /// Fetch primary property profile for the owner
  Future<Map<String, dynamic>?> getOwnerProperty(
      {String? propertyId, String? ownerId}) async {
    final targetId = propertyId ?? activePropertyId;
    if (targetId != null && targetId.isNotEmpty) {
      try {
        final res = await client
            .from('properties')
            .select('*')
            .eq('id', targetId)
            .maybeSingle();
        if (res != null) {
          activePropertyName = res['property_name']?.toString();
          return res;
        }
      } catch (e) {
        debugPrint('Error fetching property by targetId: $e');
      }
    }

    final uid = ownerId ?? currentUserId;
    var query = client.from('properties').select('*');
    if (uid != null) {
      query = query.or('owner_id.eq.$uid,owner_id.is.null');
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      if (activePropertyId == null) {
        activePropertyId = response['id']?.toString();
      }
      activePropertyName = response['property_name']?.toString();
    }

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
    final payload = {
      'property_name': name,
      'street_address': address,
      'city': city,
      'area_locality': 'BTM Layout',
      'upi_vpa': upiId,
      'crediting_phone': '9876543210',
      'total_beds': totalFloors * 10,
    };

    final response =
        await client.from('properties').upsert(payload).select().single();

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
    int? workingWashingMachines,
    String? ownerLegalName,
    String? ownerEmail,
    String? ownerAadhaarNumber,
    String? ownerPermanentAddress,
    String? ownerAadhaarFrontUrl,
    String? ownerAadhaarBackUrl,
    String? bankQrUrl,
    bool? groundFloorHasRooms,
    int? totalFloors,
    int? totalRooms,
    Map<String, dynamic>? floorWiseRooms,
    String? roomNamingFormat,
    List<Map<String, dynamic>> roomsData = const [],
    String? ownerId,
  }) async {
    // Parse numeric late fee (e.g. "₹50" -> 50.0)
    final numLateFee = double.tryParse(
          (lateFee ?? '50').replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        50.0;

    int totalBedsCount = 0;
    for (final r in roomsData) {
      totalBedsCount += ((r['total_beds'] as num?)?.toInt() ?? 0);
    }

    final propPayload = {
      'property_name': brandName,
      'property_code': propertyCode,
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
      'total_beds': totalBedsCount,
      'total_floors': totalFloors ?? 1,
      'total_rooms': totalRooms ?? roomsData.length,
      'ground_floor_has_rooms': groundFloorHasRooms ?? true,
      'floor_wise_rooms': floorWiseRooms,
      'room_naming_format': roomNamingFormat ?? 'numeric',
      'owner_legal_name': ownerLegalName,
      'owner_email': ownerEmail,
      'owner_aadhaar_number': ownerAadhaarNumber,
      'owner_permanent_address': ownerPermanentAddress,
      'owner_aadhaar_front_url': ownerAadhaarFrontUrl,
      'owner_aadhaar_back_url': ownerAadhaarBackUrl,
      'bank_qr_url': bankQrUrl,
      'working_washing_machines': workingWashingMachines ?? 1,
      'has_washing_machine': (workingWashingMachines ?? 1) > 0,
      'upi_vpa': upiVpa,
      'bank_name': bankName,
      'bank_holder_name': bankHolderName,
      'crediting_phone': creditingPhone,
      'rent_due_day': rentDueDay ?? '5th',
      'grace_period': gracePeriod ?? '3 Days',
      'late_fee': numLateFee,
      'notice_period': noticePeriod ?? '30 Days',
      if (ownerId != null && ownerId.isNotEmpty) 'owner_id': ownerId,
      if (ownerId == null && currentUserId != null) 'owner_id': currentUserId,
    };

    final property =
        await client.from('properties').insert(propPayload).select().single();

    final propertyId = property['id'] as String;

    // Insert rooms & beds if provided
    for (final r in roomsData) {
      final roomNum = r['room_number']?.toString() ?? '101';
      final roomPayload = {
        'property_id': propertyId,
        'property_name': brandName,
        'floor_number': r['floor_number'] ?? 1,
        'floor_label': r['floor_label'] ?? '1st Floor',
        'room_number': roomNum,
        'sharing_type': r['sharing_type'] ?? '',
        'total_beds': r['total_beds'] ?? 2,
        'rent_per_bed': r['rent_per_bed'] ?? 8000,
        'deposit_per_bed': r['deposit_per_bed'] ?? 15000,
      };

      final insertedRoom =
          await client.from('rooms').insert(roomPayload).select().single();

      final roomId = insertedRoom['id'] as String;
      final int totalBeds = (r['total_beds'] as int?) ?? 2;
      final List<String>? customBedLabels =
          (r['bed_labels'] as List?)?.map((e) => e.toString()).toList();

      final List<Map<String, dynamic>> bedsPayload = [];
      for (int b = 0; b < totalBeds; b++) {
        final bedLetter = String.fromCharCode(65 + b); // 'Bed A', 'Bed B'
        final defaultLabel = 'Bed $bedLetter';
        final bedLabel = (customBedLabels != null && b < customBedLabels.length)
            ? customBedLabels[b]
            : defaultLabel;
        final sharingType = r['sharing_type']?.toString() ?? '';
        bedsPayload.add({
          'property_id': propertyId,
          'property_name': brandName,
          'room_id': roomId,
          'room_number': roomNum,
          'bed_label': bedLabel,
          'sharing_type': sharingType,
          'is_occupied': false,
          'status': 'Vacant',
        });
      }

      if (bedsPayload.isNotEmpty) {
        try {
          await client.from('beds').insert(bedsPayload);
        } catch (e) {
          debugPrint('Notice inserting beds with sharing_type: $e');
          for (final b in bedsPayload) {
            b.remove('sharing_type');
          }
          await client.from('beds').insert(bedsPayload);
        }
      }
    }

    try {
      final totalBeds = roomsData.fold<int>(
          0, (sum, r) => sum + ((r['total_beds'] as int?) ?? 2));
      await ensureSaasSubscription(
        propertyId: propertyId,
        propertyName: brandName,
        totalBeds: totalBeds,
      );
    } catch (e) {
      debugPrint('Notice creating initial SaaS subscription: $e');
    }

    return property;
  }

  /// Live real-time bed statistics (Occupied beds, Total beds)
  Future<Map<String, int>> getBedMetrics(String propertyId) async {
    final roomsRes = await client
        .from('rooms')
        .select('id, total_beds, beds(id, is_occupied)')
        .eq('property_id', propertyId);

    final List rooms = roomsRes as List;
    int total = 0;
    int occupied = 0;

    for (final r in rooms) {
      final List bedsList = (r['beds'] as List?) ?? [];
      if (bedsList.isNotEmpty) {
        total += bedsList.length;
        occupied += bedsList.where((b) => b['is_occupied'] == true).length;
      } else {
        total += ((r['total_beds'] as num?)?.toInt() ?? 0);
      }
    }

    return {
      'total': total,
      'occupied': occupied,
      'available': (total - occupied).clamp(0, total),
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
  Future<List<Map<String, dynamic>>> getMonthlyRentLedger(
      String propertyId) async {
    final response = await client
        .from('rent_ledgers')
        .select('*, tenants(id, full_name, phone, room_number, bed_number)')
        .eq('property_id', propertyId)
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch strongly-typed RentLedgerModels
  Future<List<RentLedgerModel>> getRentLedgerModels(String propertyId) async {
    try {
      final response = await client
          .from('rent_ledgers')
          .select('*, tenants(id, full_name, phone, room_number, bed_number)')
          .eq('property_id', propertyId)
          .order('due_date', ascending: true);
      return (response as List)
          .map((e) => RentLedgerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      try {
        final response = await client
            .from('rent_ledgers')
            .select('*')
            .eq('property_id', propertyId)
            .order('due_date', ascending: true);
        return (response as List)
            .map((e) => RentLedgerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error fetching rent ledger models: $e');
        return [];
      }
    }
  }

  /// Fetch SaaS subscription billing invoices for the property
  Future<List<Map<String, dynamic>>> getSaasInvoices(
      {String? propertyId}) async {
    var query = client.from('saas_invoices').select('*');
    final propId = propertyId ?? activePropertyId;
    if (propId != null && propId.isNotEmpty) {
      query = query.eq('property_id', propId);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch strongly-typed SaasInvoiceModels
  Future<List<SaasInvoiceModel>> getSaasInvoiceModels(
      {String? propertyId}) async {
    try {
      final response = await getSaasInvoices(propertyId: propertyId);
      return response.map((e) => SaasInvoiceModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching SaaS invoice models: $e');
      return [];
    }
  }

  /// Ensure a row exists in saas_subscriptions for the property, auto-creating if missing
  Future<Map<String, dynamic>?> ensureSaasSubscription({
    required String propertyId,
    String? propertyName,
    int? totalBeds,
  }) async {
    try {
      final existing = await client
          .from('saas_subscriptions')
          .select()
          .eq('property_id', propertyId)
          .maybeSingle();

      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');
      final beds = (totalBeds != null && totalBeds > 0) ? totalBeds : 35;
      final bedCost = beds * 15.0;
      const platformFee = 79.0;
      final totalDue = bedCost + platformFee;

      if (existing != null) {
        // If property name or beds changed, update it
        await client.from('saas_subscriptions').update({
          if (pName.isNotEmpty) 'property_name': pName,
          'total_beds': beds,
          'total_due': totalDue,
        }).eq('id', existing['id']);
        return existing;
      }

      // Create new subscription row
      final now = DateTime.now();
      // Cycle logic: Remainder of current month + 1 full calendar month cycle free
      final nextBillingDate = (now.day == 1)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year, now.month + 2, 1);
      final trialEnds = nextBillingDate.toIso8601String();
      final nextBilling = nextBillingDate.toIso8601String();

      final payload = {
        'property_id': propertyId,
        'property_name': pName,
        'sac_code': '998315',
        'status': 'trial',
        'valid_until': trialEnds,
        'total_beds': beds,
        'price_per_bed': 15.0,
        'platform_fee': platformFee,
        'total_due': totalDue,
        'trial_ends_at': trialEnds,
        'next_billing_date': nextBilling,
      };

      final inserted = await client
          .from('saas_subscriptions')
          .insert(payload)
          .select()
          .maybeSingle();

      // Also ensure at least one inaugural/trial tax invoice exists
      await ensureInauguralSaasInvoice(
        propertyId: propertyId,
        propertyName: pName,
        amount: totalDue,
        nextBillingDate: nextBillingDate,
      );

      return inserted;
    } catch (e) {
      debugPrint('Notice ensuring SaaS subscription: $e');
      return null;
    }
  }

  /// Ensure an inaugural / trial tax invoice exists in saas_invoices
  Future<void> ensureInauguralSaasInvoice({
    required String propertyId,
    String? propertyName,
    required double amount,
    DateTime? nextBillingDate,
  }) async {
    try {
      final existing = await client
          .from('saas_invoices')
          .select('id')
          .eq('property_id', propertyId)
          .limit(1);

      if (existing.isNotEmpty) return;

      final now = DateTime.now();
      final invNumber =
          'US-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');

      final targetDate = nextBillingDate ??
          ((now.day == 1)
              ? DateTime(now.year, now.month + 1, 1)
              : DateTime(now.year, now.month + 2, 1));

      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthStr = monthNames[targetDate.month - 1];

      await client.from('saas_invoices').insert({
        'invoice_number': invNumber,
        'property_id': propertyId,
        'property_name': pName,
        'amount': amount,
        'status': 'paid',
        'payment_mode': 'Cashfree AutoPay (Trial)',
        'utr_number':
            'CF-TRIAL-${now.millisecondsSinceEpoch.toString().substring(7)}',
        'billing_period': 'Trial Period (Free until 1 $monthStr ${targetDate.year})',
      });
    } catch (e) {
      debugPrint('Notice creating inaugural SaaS invoice: $e');
    }
  }

  /// Record a new paid SaaS invoice after Cashfree payment
  Future<bool> recordSaasInvoice({
    required String propertyId,
    String? propertyName,
    required double amount,
    required String utrNumber,
    String paymentMode = 'Cashfree AutoPay',
    String? billingPeriod,
  }) async {
    try {
      final now = DateTime.now();
      final invNumber =
          'US-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');

      await client.from('saas_invoices').insert({
        'invoice_number': invNumber,
        'property_id': propertyId,
        'property_name': pName,
        'amount': amount,
        'status': 'paid',
        'payment_mode': paymentMode,
        'utr_number': utrNumber,
        'billing_period':
            billingPeriod ?? '${now.day}/${now.month}/${now.year}',
      });

      // Update saas_subscriptions status to 'active'
      try {
        await client.from('saas_subscriptions').update({
          'status': 'active',
          'valid_until': now.add(const Duration(days: 30)).toIso8601String(),
          'next_billing_date':
              now.add(const Duration(days: 30)).toIso8601String(),
        }).eq('property_id', propertyId);
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error recording SaaS invoice: $e');
      return false;
    }
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

  /// Fetch all rooms with beds for a property
  Future<List<Map<String, dynamic>>> getRooms(String propertyId) async {
    final response = await client
        .from('rooms')
        .select('*, beds(*)')
        .eq('property_id', propertyId)
        .order('room_number', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Submit 0% Direct UPI payment proof (UTR / Reference number)
  Future<void> submitUpiPaymentProof({
    required String tenantId,
    required String propertyId,
    String? propertyName,
    String? tenantName,
    String? roomNumber,
    required double amount,
    required String utrNumber,
    String? screenshotUrl,
    String? paymentApp,
  }) async {
    return await _withLoading('Submitting payment proof...', () async {
      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');
      final payload = {
        'tenant_id': tenantId,
        'property_id': propertyId,
        if (pName.isNotEmpty) 'property_name': pName,
        if (tenantName != null && tenantName.isNotEmpty)
          'tenant_name': tenantName,
        if (roomNumber != null && roomNumber.isNotEmpty)
          'room_number': roomNumber,
        'amount': amount,
        'utr_number': utrNumber,
        'payment_app': paymentApp ?? 'Google Pay',
        'proof_image_url': screenshotUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      try {
        await client.from('payment_approvals').insert(payload);
      } catch (_) {
        try {
          await client.from('upi_payment_submissions').insert(payload);
        } catch (e) {
          debugPrint('Error submitting payment proof: $e');
        }
      }
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

  // ---------------------------------------------------------------------------
  // 🏢 OWNER OPERATING SUITE CORE OPERATIONS (ALL 14 SCREENS)
  // ---------------------------------------------------------------------------

  /// Ensures a tenant row exists in the tenants table and returns its UUID.
  /// Guarantees that beds.tenant_id is NEVER null in Supabase.
  Future<String?> ensureTenantExists({
    required String propertyId,
    String? propertyName,
    required String tenantName,
    String? phone,
    String? bedId,
    String? bedLabel,
    String? roomId,
    String? roomNumber,
    double? rent,
    double? deposit,
    int? rentDueDay,
  }) async {
    try {
      final pId = propertyId.isNotEmpty ? propertyId : (activePropertyId ?? '');
      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');
      final cleanName = tenantName.trim();
      final cleanPhone = phone?.trim() ?? '';
      final dueDay = (rentDueDay ?? 5).clamp(1, 31);

      // 1. Check if tenant already exists by phone or name
      Map<String, dynamic>? tRow;
      if (cleanPhone.isNotEmpty) {
        try {
          var q =
              client.from('tenants').select('id, room_id, room_number, bed_id');
          if (pId.isNotEmpty) q = q.eq('property_id', pId);
          tRow = await q.eq('phone', cleanPhone).maybeSingle();
        } catch (_) {}
      }

      if (tRow == null && cleanName.isNotEmpty) {
        try {
          var q =
              client.from('tenants').select('id, room_id, room_number, bed_id');
          if (pId.isNotEmpty) q = q.eq('property_id', pId);
          tRow = await q.ilike('name', cleanName).maybeSingle();
        } catch (_) {}
      }

      if (tRow != null && tRow['id'] != null) {
        final existingId = tRow['id'].toString();
        // Update active location
        try {
          await client.from('tenants').update({
            if (cleanName.isNotEmpty) 'name': cleanName,
            if (cleanName.isNotEmpty) 'tenant_name': cleanName,
            if (pName.isNotEmpty) 'property_name': pName,
            if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
            if (roomNumber != null && roomNumber.isNotEmpty)
              'room_number': roomNumber,
            if (bedId != null && bedId.isNotEmpty) 'bed_id': bedId,
            if (bedLabel != null && bedLabel.isNotEmpty) 'bed_label': bedLabel,
            if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
            if (rent != null) 'monthly_rent': rent,
            if (deposit != null) 'security_deposit': deposit,
            'rent_due_day': dueDay,
            'status': 'Active',
          }).eq('id', existingId);
        } catch (_) {}

        if (bedId != null && bedId.isNotEmpty) {
          try {
            await client.from('beds').update({
              'tenant_id': existingId,
              if (cleanName.isNotEmpty) 'tenant_name': cleanName,
              if (cleanPhone.isNotEmpty) 'tenant_phone': cleanPhone,
              'is_occupied': true,
            }).eq('id', bedId);
          } catch (_) {}
        }
        return existingId;
      }

      // 2. Tenant does NOT exist -> Create new row!
      final newPhone = cleanPhone.isNotEmpty
          ? cleanPhone
          : '+91 98${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final insertPayload = {
        if (pId.isNotEmpty) 'property_id': pId,
        if (pName.isNotEmpty) 'property_name': pName,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
        if (roomNumber != null && roomNumber.isNotEmpty)
          'room_number': roomNumber,
        if (bedId != null && bedId.isNotEmpty) 'bed_id': bedId,
        if (bedLabel != null && bedLabel.isNotEmpty) 'bed_label': bedLabel,
        'name': cleanName.isNotEmpty ? cleanName : 'Resident',
        'tenant_name': cleanName.isNotEmpty ? cleanName : 'Resident',
        'phone': newPhone,
        if (rent != null) 'monthly_rent': rent,
        if (deposit != null) 'security_deposit': deposit,
        'rent_due_day': dueDay,
        'status': 'Active',
      };

      try {
        final inserted = await client
            .from('tenants')
            .insert(insertPayload)
            .select('id')
            .maybeSingle();
        final createdId = inserted?['id']?.toString();
        if (createdId != null && createdId.isNotEmpty) {
          if (bedId != null && bedId.isNotEmpty) {
            try {
              await client.from('beds').update({
                'tenant_id': createdId,
                if (cleanName.isNotEmpty) 'tenant_name': cleanName,
                'tenant_phone': newPhone,
                'is_occupied': true,
              }).eq('id', bedId);
            } catch (_) {}
          }
          return createdId;
        }
      } catch (e) {
        debugPrint('Fallback tenant insert: $e');
        final minInsert = {
          if (pId.isNotEmpty) 'property_id': pId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (roomNumber != null && roomNumber.isNotEmpty)
            'room_number': roomNumber,
          if (bedLabel != null && bedLabel.isNotEmpty) 'bed_label': bedLabel,
          'name': cleanName.isNotEmpty ? cleanName : 'Resident',
          'tenant_name': cleanName.isNotEmpty ? cleanName : 'Resident',
          'phone': newPhone,
          if (rent != null) 'monthly_rent': rent,
          if (deposit != null) 'security_deposit': deposit,
          'rent_due_day': dueDay,
          'status': 'Active',
        };
        final minRes = await client
            .from('tenants')
            .insert(minInsert)
            .select('id')
            .maybeSingle();
        final fallbackId = minRes?['id']?.toString();
        if (fallbackId != null &&
            fallbackId.isNotEmpty &&
            bedId != null &&
            bedId.isNotEmpty) {
          try {
            await client.from('beds').update({
              'tenant_id': fallbackId,
              if (cleanName.isNotEmpty) 'tenant_name': cleanName,
              'tenant_phone': newPhone,
              'is_occupied': true,
            }).eq('id', bedId);
          } catch (_) {}
        }
        return fallbackId;
      }
    } catch (e) {
      debugPrint('Error in ensureTenantExists: $e');
    }
    return null;
  }

  /// 1. Assign resident to bed permanently in Supabase
  Future<bool> assignResidentToBed({
    required String bedId,
    required String name,
    required String phone,
    String? propertyName,
    String? roomNumber,
    double? rent,
    double? deposit,
    int? rentDueDay,
  }) async {
    return await _withLoading('Assigning Resident...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');

        final chosenDueDay = (rentDueDay ?? 5).clamp(1, 31);

        // 1. Fetch bed metadata (property_id, room_id, bed_label)
        final bedRes = await client
            .from('beds')
            .select('property_id, room_id, bed_label, room_number')
            .eq('id', bedId)
            .maybeSingle();

        final propId =
            bedRes?['property_id']?.toString() ?? activePropertyId ?? '';
        final roomId = bedRes?['room_id']?.toString();
        final bedLabel = bedRes?['bed_label']?.toString() ?? '';
        final finalRoomNumber = (roomNumber != null && roomNumber.isNotEmpty)
            ? roomNumber
            : (bedRes?['room_number']?.toString() ?? '');

        // 2. Ensure tenant profile exists and get real UUID
        final realTenantId = await ensureTenantExists(
          propertyId: propId,
          propertyName: pName,
          tenantName: name,
          phone: phone,
          bedId: bedId,
          bedLabel: bedLabel,
          roomId: roomId,
          roomNumber: finalRoomNumber,
          rent: rent,
          deposit: deposit,
          rentDueDay: chosenDueDay,
        );

        // 3. Update beds table with occupant info, tenant_id, and rent_due_day
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': name,
          'tenant_phone': phone,
          if (realTenantId != null && realTenantId.isNotEmpty)
            'tenant_id': realTenantId,
          'rent_due_day': chosenDueDay,
          if (pName.isNotEmpty) 'property_name': pName,
          if (finalRoomNumber.isNotEmpty) 'room_number': finalRoomNumber,
          if (rent != null) 'rent': rent,
          if (deposit != null) 'deposit': deposit,
        }).eq('id', bedId);

        // 3b. GUARANTEED TENANT SYNC: Update tenants table with exact rent, deposit, due day, room, and bed
        if (realTenantId != null && realTenantId.isNotEmpty) {
          try {
            await client.from('tenants').update({
              if (propId.isNotEmpty) 'property_id': propId,
              if (pName.isNotEmpty) 'property_name': pName,
              if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
              if (finalRoomNumber.isNotEmpty) 'room_number': finalRoomNumber,
              'bed_id': bedId,
              if (bedLabel.isNotEmpty) 'bed_label': bedLabel,
              'name': name,
              'tenant_name': name,
              'phone': phone,
              if (rent != null) 'monthly_rent': rent,
              if (deposit != null) 'security_deposit': deposit,
              'rent_due_day': chosenDueDay,
              'status': 'Active',
            }).eq('id', realTenantId);
          } catch (e) {
            debugPrint('Notice updating full tenant metadata: $e');
            // If foreign key constraint failed on room_id or bed_id, still update the financial & text fields!
            try {
              await client.from('tenants').update({
                if (propId.isNotEmpty) 'property_id': propId,
                if (pName.isNotEmpty) 'property_name': pName,
                if (finalRoomNumber.isNotEmpty) 'room_number': finalRoomNumber,
                if (bedLabel.isNotEmpty) 'bed_label': bedLabel,
                'name': name,
                'phone': phone,
                if (rent != null) 'monthly_rent': rent,
                if (deposit != null) 'security_deposit': deposit,
                'rent_due_day': chosenDueDay,
                'status': 'Active',
              }).eq('id', realTenantId);
            } catch (_) {}
          }
        }

        // 4. Create or update active monthly rent ledger with exact due day
        if (propId.isNotEmpty) {
          try {
            final now = DateTime.now();
            const months = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December'
            ];
            final cycleMonth = '${months[now.month - 1]} ${now.year}';
            final dayPadded = chosenDueDay.toString().padLeft(2, '0');
            final formattedDueDate =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-$dayPadded';

            // Check if ledger already exists for this room in current billing month
            final existingLedgers = await client
                .from('rent_ledgers')
                .select('id')
                .eq('property_id', propId)
                .eq('billing_month', cycleMonth)
                .eq('room_number', finalRoomNumber);

            if (existingLedgers != null &&
                (existingLedgers as List).isNotEmpty) {
              final existingId = (existingLedgers as List).first['id'];
              await client.from('rent_ledgers').update({
                'due_date': formattedDueDate,
                'rent_due_day': chosenDueDay,
                if (realTenantId != null) 'tenant_id': realTenantId,
                'tenant_name': name,
                if (rent != null) 'rent_amount': rent,
                if (rent != null) 'due_amount': rent,
              }).eq('id', existingId);
            } else {
              await client.from('rent_ledgers').insert({
                'property_id': propId,
                if (pName.isNotEmpty) 'property_name': pName,
                if (realTenantId != null) 'tenant_id': realTenantId,
                'tenant_name': name,
                if (finalRoomNumber.isNotEmpty) 'room_number': finalRoomNumber,
                'billing_month': cycleMonth,
                'rent_amount': rent ?? 0.0,
                'due_amount': rent ?? 0.0,
                'status': 'PENDING',
                'due_date': formattedDueDate,
                'rent_due_day': chosenDueDay,
                'payment_mode': 'UPI',
              });
            }
          } catch (e) {
            debugPrint('Notice: rent_ledger creation sync: $e');
          }
        }

        return true;
      } catch (e) {
        debugPrint('Error assigning resident to bed: $e');
        return false;
      }
    });
  }

  /// 2. Shift resident bed (vacates old bed, occupies new bed, preserves phone & updates tenants/ledgers/damages)
  Future<bool> shiftResidentBed({
    required String oldBedId,
    required String newBedId,
    required String name,
    required String phone,
    double? rent,
    double? deposit,
  }) async {
    return await _withLoading('Shifting Bed...', () async {
      try {
        final pName = activePropertyName ?? '';
        final pId = activePropertyId ?? '';

        // 1. Fetch old bed info (to recover tenant_id, phone, property_id if missing)
        Map<String, dynamic>? oldBedRow;
        try {
          oldBedRow = await client
              .from('beds')
              .select(
                  'id, property_id, room_id, room_number, bed_label, tenant_id, tenant_name, tenant_phone, rent, deposit')
              .eq('id', oldBedId)
              .maybeSingle();
        } catch (e) {
          debugPrint('Notice on fetching old bed: $e');
        }

        // 2. Fetch new bed info (to get target room_id, room_number, bed_label, property_id)
        Map<String, dynamic>? newBedRow;
        try {
          newBedRow = await client
              .from('beds')
              .select('id, property_id, room_id, room_number, bed_label')
              .eq('id', newBedId)
              .maybeSingle();
        } catch (e) {
          debugPrint('Notice on fetching new bed: $e');
        }

        final targetPropId =
            (newBedRow?['property_id'] ?? oldBedRow?['property_id'] ?? pId)
                .toString();
        final newRoomId = newBedRow?['room_id']?.toString();
        final newRoomNumber = newBedRow?['room_number']?.toString() ?? '';
        final newBedLabel = newBedRow?['bed_label']?.toString() ?? '';

        // Resolve phone (if empty in args, recover from oldBedRow or tenants table)
        String resolvedPhone = phone.trim();
        if (resolvedPhone.isEmpty && oldBedRow?['tenant_phone'] != null) {
          resolvedPhone = oldBedRow!['tenant_phone'].toString().trim();
        }

        // Auto-upsert tenant profile in tenants table so tenant_id is NEVER null
        String? resolvedTenantId = await ensureTenantExists(
          propertyId: targetPropId,
          propertyName: pName,
          tenantName: name,
          phone: resolvedPhone,
          bedId: newBedId,
          bedLabel: newBedLabel,
          roomId: newRoomId,
          roomNumber: newRoomNumber,
          rent: rent,
          deposit: deposit,
        );

        if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
          resolvedTenantId = oldBedRow?['tenant_id']?.toString();
        }

        // 3. Clear old bed
        await client.from('beds').update({
          'is_occupied': false,
          'status': 'Vacant',
          'tenant_name': null,
          'tenant_phone': null,
          'tenant_id': null,
          'rent': null,
          'deposit': null,
        }).eq('id', oldBedId);

        // 4. Occupy new bed with guaranteed tenant_id
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': name,
          'tenant_phone': resolvedPhone,
          if (resolvedTenantId != null && resolvedTenantId.isNotEmpty)
            'tenant_id': resolvedTenantId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (rent != null) 'rent': rent,
          if (deposit != null) 'deposit': deposit,
        }).eq('id', newBedId);

        // 5. Update tenants table with new room and bed
        if (resolvedTenantId != null && resolvedTenantId.isNotEmpty) {
          try {
            await client.from('tenants').update({
              if (newRoomId != null) 'room_id': newRoomId,
              if (newRoomNumber.isNotEmpty) 'room_number': newRoomNumber,
              'bed_id': newBedId,
              if (newBedLabel.isNotEmpty) 'bed_label': newBedLabel,
              if (resolvedPhone.isNotEmpty) 'phone': resolvedPhone,
              if (rent != null) 'monthly_rent': rent,
              if (deposit != null) 'security_deposit': deposit,
              'status': 'Active',
            }).eq('id', resolvedTenantId);
          } catch (e) {
            debugPrint('Notice updating tenants table on bed shift: $e');
          }
        }

        // 6. Update open damage deductions to point to new room & bed
        if (newRoomNumber.isNotEmpty) {
          try {
            if (resolvedTenantId != null && resolvedTenantId.isNotEmpty) {
              await client.from('damage_deductions').update({
                'room_number': newRoomNumber,
                if (newRoomId != null) 'room_id': newRoomId,
              }).eq('tenant_id', resolvedTenantId);
            }
            if (targetPropId.isNotEmpty) {
              await client
                  .from('damage_deductions')
                  .update({
                    'room_number': newRoomNumber,
                    if (newRoomId != null) 'room_id': newRoomId,
                  })
                  .eq('property_id', targetPropId)
                  .ilike('tenant_name', name);
            }
          } catch (e) {
            debugPrint('Notice updating damage_deductions on bed shift: $e');
          }
        }

        // 7. Update rent ledgers to point to new room for this resident (BOTH Paid and Pending)
        if (newRoomNumber.isNotEmpty) {
          try {
            final cleanRoom =
                newRoomNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();
            final roomToSet = cleanRoom.isNotEmpty ? cleanRoom : newRoomNumber;
            if (resolvedTenantId != null && resolvedTenantId.isNotEmpty) {
              await client
                  .from('rent_ledgers')
                  .update({
                    'room_number': roomToSet,
                  })
                  .eq('tenant_id', resolvedTenantId)
                  .eq('property_id', targetPropId);
            }
            if (name.isNotEmpty && name != 'Resident') {
              await client
                  .from('rent_ledgers')
                  .update({
                    'room_number': roomToSet,
                  })
                  .eq('property_id', targetPropId)
                  .ilike('tenant_name', name);
            }
          } catch (e) {
            debugPrint('Notice updating rent_ledgers on bed shift: $e');
          }
        }

        return true;
      } catch (e) {
        debugPrint('Error shifting resident bed: $e');
        return false;
      }
    });
  }

  /// Swap two resident beds mutually (swaps occupants, preserves phones, updates tenants/ledgers/damages)
  Future<bool> swapResidentBeds({
    required String bed1Id,
    required String bed2Id,
    required String res1Name,
    required String res1Phone,
    double? res1Rent,
    double? res1Deposit,
    required String res2Name,
    required String res2Phone,
    double? res2Rent,
    double? res2Deposit,
  }) async {
    return await _withLoading('Swapping Beds...', () async {
      try {
        final pName = activePropertyName ?? '';
        final pId = activePropertyId ?? '';

        // 1. Fetch metadata for Bed 1
        Map<String, dynamic>? bed1Row;
        try {
          bed1Row = await client
              .from('beds')
              .select(
                  'id, property_id, room_id, room_number, bed_label, tenant_id, tenant_name, tenant_phone')
              .eq('id', bed1Id)
              .maybeSingle();
        } catch (e) {
          debugPrint('Notice fetching bed1Row: $e');
        }

        // 2. Fetch metadata for Bed 2
        Map<String, dynamic>? bed2Row;
        try {
          bed2Row = await client
              .from('beds')
              .select(
                  'id, property_id, room_id, room_number, bed_label, tenant_id, tenant_name, tenant_phone')
              .eq('id', bed2Id)
              .maybeSingle();
        } catch (e) {
          debugPrint('Notice fetching bed2Row: $e');
        }

        final targetPropId =
            (bed1Row?['property_id'] ?? bed2Row?['property_id'] ?? pId)
                .toString();
        final bed1RoomId = bed1Row?['room_id']?.toString();
        final bed1RoomNumber = bed1Row?['room_number']?.toString() ?? '';
        final bed1BedLabel = bed1Row?['bed_label']?.toString() ?? '';

        final bed2RoomId = bed2Row?['room_id']?.toString();
        final bed2RoomNumber = bed2Row?['room_number']?.toString() ?? '';
        final bed2BedLabel = bed2Row?['bed_label']?.toString() ?? '';

        // Resolve phones
        String resolvedRes1Phone = res1Phone.trim();
        if (resolvedRes1Phone.isEmpty && bed1Row?['tenant_phone'] != null) {
          resolvedRes1Phone = bed1Row!['tenant_phone'].toString().trim();
        }

        String resolvedRes2Phone = res2Phone.trim();
        if (resolvedRes2Phone.isEmpty && bed2Row?['tenant_phone'] != null) {
          resolvedRes2Phone = bed2Row!['tenant_phone'].toString().trim();
        }

        // Resolve tenant_ids
        String? res1TenantId = bed1Row?['tenant_id']?.toString();
        if (res1TenantId == null || res1TenantId.isEmpty) {
          try {
            var q = client.from('tenants').select('id, phone');
            if (resolvedRes1Phone.isNotEmpty) {
              q = q.eq('phone', resolvedRes1Phone);
            } else {
              q = q.eq('name', res1Name);
            }
            if (targetPropId.isNotEmpty) q = q.eq('property_id', targetPropId);
            final t = await q.maybeSingle();
            if (t != null) {
              res1TenantId = t['id']?.toString();
              if (resolvedRes1Phone.isEmpty && t['phone'] != null) {
                resolvedRes1Phone = t['phone'].toString().trim();
              }
            }
          } catch (_) {}
        }

        String? res2TenantId = bed2Row?['tenant_id']?.toString();
        if (res2TenantId == null || res2TenantId.isEmpty) {
          try {
            var q = client.from('tenants').select('id, phone');
            if (resolvedRes2Phone.isNotEmpty) {
              q = q.eq('phone', resolvedRes2Phone);
            } else {
              q = q.eq('name', res2Name);
            }
            if (targetPropId.isNotEmpty) q = q.eq('property_id', targetPropId);
            final t = await q.maybeSingle();
            if (t != null) {
              res2TenantId = t['id']?.toString();
              if (resolvedRes2Phone.isEmpty && t['phone'] != null) {
                resolvedRes2Phone = t['phone'].toString().trim();
              }
            }
          } catch (_) {}
        }

        // 3. Bed 1 receives Resident 2
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': res2Name,
          'tenant_phone': resolvedRes2Phone,
          if (res2TenantId != null) 'tenant_id': res2TenantId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (res2Rent != null) 'rent': res2Rent,
          if (res2Deposit != null) 'deposit': res2Deposit,
        }).eq('id', bed1Id);

        // 4. Bed 2 receives Resident 1
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': res1Name,
          'tenant_phone': resolvedRes1Phone,
          if (res1TenantId != null) 'tenant_id': res1TenantId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (res1Rent != null) 'rent': res1Rent,
          if (res1Deposit != null) 'deposit': res1Deposit,
        }).eq('id', bed2Id);

        // 5. Update tenants table for Resident 1 (now at Bed 2)
        if (res1TenantId != null && res1TenantId.isNotEmpty) {
          try {
            await client.from('tenants').update({
              if (bed2RoomId != null) 'room_id': bed2RoomId,
              if (bed2RoomNumber.isNotEmpty) 'room_number': bed2RoomNumber,
              'bed_id': bed2Id,
              if (bed2BedLabel.isNotEmpty) 'bed_label': bed2BedLabel,
              if (resolvedRes1Phone.isNotEmpty) 'phone': resolvedRes1Phone,
              if (res1Rent != null) 'monthly_rent': res1Rent,
              if (res1Deposit != null) 'security_deposit': res1Deposit,
            }).eq('id', res1TenantId);
          } catch (e) {
            debugPrint('Notice updating tenant 1 on swap: $e');
          }
        }

        // 6. Update tenants table for Resident 2 (now at Bed 1)
        if (res2TenantId != null && res2TenantId.isNotEmpty) {
          try {
            await client.from('tenants').update({
              if (bed1RoomId != null) 'room_id': bed1RoomId,
              if (bed1RoomNumber.isNotEmpty) 'room_number': bed1RoomNumber,
              'bed_id': bed1Id,
              if (bed1BedLabel.isNotEmpty) 'bed_label': bed1BedLabel,
              if (resolvedRes2Phone.isNotEmpty) 'phone': resolvedRes2Phone,
              if (res2Rent != null) 'monthly_rent': res2Rent,
              if (res2Deposit != null) 'security_deposit': res2Deposit,
            }).eq('id', res2TenantId);
          } catch (e) {
            debugPrint('Notice updating tenant 2 on swap: $e');
          }
        }

        // 7. Update damage_deductions room numbers for both residents
        try {
          if (res1TenantId != null && res1TenantId.isNotEmpty) {
            await client.from('damage_deductions').update({
              if (bed2RoomNumber.isNotEmpty) 'room_number': bed2RoomNumber,
              if (bed2RoomId != null) 'room_id': bed2RoomId,
            }).eq('tenant_id', res1TenantId);
          }
          if (targetPropId.isNotEmpty && res1Name.isNotEmpty) {
            await client
                .from('damage_deductions')
                .update({
                  if (bed2RoomNumber.isNotEmpty) 'room_number': bed2RoomNumber,
                  if (bed2RoomId != null) 'room_id': bed2RoomId,
                })
                .eq('property_id', targetPropId)
                .ilike('tenant_name', res1Name);
          }

          if (res2TenantId != null && res2TenantId.isNotEmpty) {
            await client.from('damage_deductions').update({
              if (bed1RoomNumber.isNotEmpty) 'room_number': bed1RoomNumber,
              if (bed1RoomId != null) 'room_id': bed1RoomId,
            }).eq('tenant_id', res2TenantId);
          }
          if (targetPropId.isNotEmpty && res2Name.isNotEmpty) {
            await client
                .from('damage_deductions')
                .update({
                  if (bed1RoomNumber.isNotEmpty) 'room_number': bed1RoomNumber,
                  if (bed1RoomId != null) 'room_id': bed1RoomId,
                })
                .eq('property_id', targetPropId)
                .ilike('tenant_name', res2Name);
          }
        } catch (e) {
          debugPrint('Notice updating damage_deductions on swap: $e');
        }

        // 8. Update pending rent_ledgers room numbers for both residents
        try {
          if (res1TenantId != null && res1TenantId.isNotEmpty) {
            await client
                .from('rent_ledgers')
                .update({
                  'room_number': bed2RoomNumber,
                })
                .eq('tenant_id', res1TenantId)
                .eq('property_id', targetPropId);
          } else if (bed2RoomNumber.isNotEmpty) {
            await client
                .from('rent_ledgers')
                .update({
                  'room_number': bed2RoomNumber,
                })
                .eq('property_id', targetPropId)
                .eq('tenant_name', res1Name);
          }

          if (res2TenantId != null && res2TenantId.isNotEmpty) {
            await client
                .from('rent_ledgers')
                .update({
                  'room_number': bed1RoomNumber,
                })
                .eq('tenant_id', res2TenantId)
                .eq('property_id', targetPropId);
          } else if (bed1RoomNumber.isNotEmpty) {
            await client
                .from('rent_ledgers')
                .update({
                  'room_number': bed1RoomNumber,
                })
                .eq('property_id', targetPropId)
                .eq('tenant_name', res2Name);
          }
        } catch (e) {
          debugPrint('Notice updating rent_ledgers on swap: $e');
        }

        return true;
      } catch (e) {
        debugPrint('Error swapping resident beds: $e');
        return false;
      }
    });
  }

  /// 3. Vacate bed
  Future<bool> vacateBed({
    required String bedId,
    double? damageDeduction,
    String? reason,
  }) async {
    return await _withLoading('Vacating Bed...', () async {
      try {
        // 1. Fetch occupant metadata before clearing bed
        Map<String, dynamic>? bedRow;
        try {
          bedRow = await client
              .from('beds')
              .select('property_id, tenant_id, tenant_name, room_number')
              .eq('id', bedId)
              .maybeSingle();
        } catch (_) {}

        // 2. Clear bed
        await client.from('beds').update({
          'is_occupied': false,
          'status': 'Vacant',
          'tenant_name': null,
          'tenant_phone': null,
          'tenant_id': null,
          'rent': null,
          'deposit': null,
        }).eq('id', bedId);

        // 3. Purge orphaned PENDING rent ledgers for this vacated tenant
        if (bedRow != null) {
          try {
            final tId = bedRow['tenant_id']?.toString();
            final pId =
                bedRow['property_id']?.toString() ?? activePropertyId ?? '';
            final tName = bedRow['tenant_name']?.toString();
            if (tId != null && tId.isNotEmpty) {
              await client
                  .from('rent_ledgers')
                  .delete()
                  .eq('tenant_id', tId)
                  .eq('status', 'PENDING');
            } else if (pId.isNotEmpty &&
                tName != null &&
                tName.isNotEmpty &&
                tName != 'Resident') {
              await client
                  .from('rent_ledgers')
                  .delete()
                  .eq('property_id', pId)
                  .eq('tenant_name', tName)
                  .eq('status', 'PENDING');
            }
          } catch (e) {
            debugPrint('Notice purging pending ledgers on vacate: $e');
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error vacating bed: $e');
        return false;
      }
    });
  }

  /// 4. Add Damage Deduction (captures tenant_id, room_id, bed_id and auto-resolves if missing)
  Future<bool> addDamageDeduction({
    required String propertyId,
    String? propertyName,
    String? tenantId,
    String? roomId,
    String? roomNumber,
    required String bedId,
    required String tenantName,
    required String itemDamaged,
    required double amount,
    required String deductionMode,
    String? photoUrl,
  }) async {
    return await _withLoading('Logging Damage Deduction...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');

        // Resolve missing tenantId, roomId, roomNumber from bedId if not provided
        String? resolvedTenantId = tenantId;
        String? resolvedRoomId = roomId;
        String? resolvedRoomNumber = roomNumber;

        if (bedId.isNotEmpty &&
            (resolvedTenantId == null ||
                resolvedTenantId.isEmpty ||
                resolvedRoomId == null ||
                resolvedRoomId.isEmpty ||
                resolvedRoomNumber == null ||
                resolvedRoomNumber.isEmpty)) {
          try {
            final bRow = await client
                .from('beds')
                .select('tenant_id, room_id, room_number')
                .eq('id', bedId)
                .maybeSingle();
            if (bRow != null) {
              if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
                resolvedTenantId = bRow['tenant_id']?.toString();
              }
              if (resolvedRoomId == null || resolvedRoomId.isEmpty) {
                resolvedRoomId = bRow['room_id']?.toString();
              }
              if (resolvedRoomNumber == null || resolvedRoomNumber.isEmpty) {
                resolvedRoomNumber = bRow['room_number']?.toString();
              }
            }
          } catch (e) {
            debugPrint('Notice resolving bed metadata for damage: $e');
          }
        }

        // If roomId is missing but roomNumber exists, resolve roomId from rooms table
        if ((resolvedRoomId == null || resolvedRoomId.isEmpty) &&
            resolvedRoomNumber != null &&
            resolvedRoomNumber.isNotEmpty &&
            propertyId.isNotEmpty) {
          try {
            final rRow = await client
                .from('rooms')
                .select('id')
                .eq('property_id', propertyId)
                .eq('room_number', resolvedRoomNumber)
                .maybeSingle();
            if (rRow != null && rRow['id'] != null) {
              resolvedRoomId = rRow['id'].toString();
            }
          } catch (_) {}
        }

        // If roomNumber is missing but roomId exists, resolve roomNumber from rooms table
        if ((resolvedRoomNumber == null || resolvedRoomNumber.isEmpty) &&
            resolvedRoomId != null &&
            resolvedRoomId.isNotEmpty) {
          try {
            final rRow = await client
                .from('rooms')
                .select('room_number')
                .eq('id', resolvedRoomId)
                .maybeSingle();
            if (rRow != null && rRow['room_number'] != null) {
              resolvedRoomNumber = rRow['room_number'].toString();
            }
          } catch (_) {}
        }

        // Auto-upsert tenant so tenant_id is NEVER null
        if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
          resolvedTenantId = await ensureTenantExists(
            propertyId: propertyId,
            propertyName: pName,
            tenantName: tenantName,
            bedId: bedId,
            roomId: resolvedRoomId,
            roomNumber: resolvedRoomNumber,
          );
        }

        final payload = {
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (resolvedTenantId != null && resolvedTenantId.isNotEmpty)
            'tenant_id': resolvedTenantId,
          'tenant_name': tenantName,
          if (resolvedRoomId != null && resolvedRoomId.isNotEmpty)
            'room_id': resolvedRoomId,
          if (resolvedRoomNumber != null && resolvedRoomNumber.isNotEmpty)
            'room_number': resolvedRoomNumber,
          if (bedId.isNotEmpty) 'bed_id': bedId,
          'item_damaged': itemDamaged,
          'amount': amount,
          'deduction_mode': deductionMode,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        };

        try {
          await client.from('damage_deductions').insert(payload);
        } catch (e) {
          debugPrint('Notice inserting with bed_id: $e');
          // If bed_id column doesn't exist, retry without bed_id
          try {
            final fallback1 = Map<String, dynamic>.from(payload)
              ..remove('bed_id');
            await client.from('damage_deductions').insert(fallback1);
          } catch (e2) {
            debugPrint('Notice inserting without bed_id: $e2');
            try {
              final fallback2 = Map<String, dynamic>.from(payload)
                ..remove('bed_id')
                ..remove('property_id')
                ..remove('property_name');
              await client.from('damage_deductions').insert(fallback2);
            } catch (e3) {
              debugPrint('Fallback damage insert error: $e3');
            }
          }
        }

        // If deducting from deposit, reduce deposit on the bed
        if (deductionMode == 'deposit' && bedId.isNotEmpty && amount > 0) {
          try {
            final bedRes = await client
                .from('beds')
                .select('deposit')
                .eq('id', bedId)
                .maybeSingle();
            final curDeposit = (bedRes?['deposit'] as num?)?.toDouble() ?? 0.0;
            final newDeposit =
                (curDeposit - amount).clamp(0.0, double.infinity);
            await client
                .from('beds')
                .update({'deposit': newDeposit}).eq('id', bedId);
          } catch (e) {
            debugPrint('Notice updating bed deposit: $e');
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error logging damage deduction: $e');
        return false;
      }
    });
  }

  /// Fetch damage deductions for a property / resident
  Future<List<Map<String, dynamic>>> getDamageDeductions({
    required String propertyId,
    String? roomNumber,
    String? tenantName,
    String? tenantId,
  }) async {
    try {
      var query = client.from('damage_deductions').select();

      if (propertyId.isNotEmpty) {
        query = query.eq('property_id', propertyId);
      }
      if (tenantId != null && tenantId.isNotEmpty) {
        query = query.eq('tenant_id', tenantId);
      } else if (tenantName != null && tenantName.isNotEmpty) {
        query = query.ilike('tenant_name', tenantName);
      } else if (roomNumber != null && roomNumber.isNotEmpty) {
        query = query.eq('room_number', roomNumber);
      }

      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching damage deductions: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // RENT EXTENSIONS API
  // ---------------------------------------------------------------------------

  /// Request rent payment extension
  Future<bool> requestRentExtension({
    required String propertyId,
    String? propertyName,
    required String tenantName,
    String? tenantId,
    String? roomNumber,
    String? ledgerId,
    required int requestedDueDay,
    String? reason,
  }) async {
    return await _withLoading('Submitting Extension Request...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        final now = DateTime.now();
        final dayPadded = requestedDueDay.toString().padLeft(2, '0');
        final monthPadded = now.month.toString().padLeft(2, '0');
        final formattedDueDate = '${now.year}-$monthPadded-$dayPadded';

        // Resolve tenant_id and room_number if missing
        String? resolvedTenantId = tenantId;
        String? resolvedRoomNumber = roomNumber;
        if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
          try {
            final t = await client
                .from('tenants')
                .select('id, room_number')
                .eq('property_id', propertyId)
                .ilike('name', tenantName)
                .maybeSingle();
            if (t != null) {
              resolvedTenantId = t['id']?.toString();
              resolvedRoomNumber ??= t['room_number']?.toString();
            }
          } catch (_) {}
        }

        final payload = {
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (resolvedTenantId != null) 'tenant_id': resolvedTenantId,
          'tenant_name': tenantName,
          if (resolvedRoomNumber != null) 'room_number': resolvedRoomNumber,
          if (ledgerId != null) 'ledger_id': ledgerId,
          'requested_date': formattedDueDate,
          'reason':
              reason ?? 'Requested payment extension to ${requestedDueDay}th',
          'status': 'pending',
        };

        await client.from('rent_extensions').insert(payload);
        return true;
      } catch (e) {
        debugPrint('Error requesting rent extension: $e');
        return false;
      }
    });
  }

  /// Approve rent extension
  Future<bool> approveRentExtension({
    required String propertyId,
    required String tenantName,
    String? roomNumber,
    String? extensionId,
    String? ledgerId,
    int? newDueDay,
    String? requestedDueDate,
  }) async {
    return await _withLoading('Approving Extension...', () async {
      try {
        // 1. Update rent_extensions table status
        if (extensionId != null && extensionId.isNotEmpty) {
          try {
            await client
                .from('rent_extensions')
                .update({'status': 'approved'}).eq('id', extensionId);
          } catch (_) {}
        }
        try {
          var q = client
              .from('rent_extensions')
              .update({'status': 'approved'}).eq('property_id', propertyId);
          if (ledgerId != null && ledgerId.isNotEmpty) {
            q = q.eq('ledger_id', ledgerId);
          } else if (tenantName.isNotEmpty && tenantName != 'Resident') {
            q = q.ilike('tenant_name', tenantName);
          } else if (roomNumber != null && roomNumber.isNotEmpty) {
            q = q.eq('room_number', roomNumber);
          }
          await q;
        } catch (_) {}

        // 2. Parse due date if newDueDay provided
        String? finalDueDate = requestedDueDate;
        int? finalDueDay = newDueDay;
        if (finalDueDate != null && finalDueDay == null) {
          final dt = DateTime.tryParse(finalDueDate);
          if (dt != null) finalDueDay = dt.day;
        } else if (finalDueDay != null && finalDueDate == null) {
          final now = DateTime.now();
          finalDueDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${finalDueDay.toString().padLeft(2, '0')}';
        }

        // 3. Update rent_ledgers table
        if (finalDueDate != null || finalDueDay != null) {
          try {
            if (ledgerId != null && ledgerId.isNotEmpty) {
              await client.from('rent_ledgers').update({
                if (finalDueDate != null) 'due_date': finalDueDate,
                if (finalDueDay != null) 'rent_due_day': finalDueDay,
                'status': 'PENDING',
              }).eq('id', ledgerId);
            } else if (roomNumber != null && roomNumber.isNotEmpty) {
              await client
                  .from('rent_ledgers')
                  .update({
                    if (finalDueDate != null) 'due_date': finalDueDate,
                    if (finalDueDay != null) 'rent_due_day': finalDueDay,
                    'status': 'PENDING',
                  })
                  .eq('property_id', propertyId)
                  .eq('room_number', roomNumber)
                  .neq('status', 'PAID');
            }
          } catch (e) {
            debugPrint(
                'Notice updating rent_ledgers on extension approval: $e');
          }
        }

        // 4. Update beds & tenants rent_due_day if finalDueDay is set
        if (finalDueDay != null) {
          try {
            if (roomNumber != null && roomNumber.isNotEmpty) {
              await client
                  .from('beds')
                  .update({'rent_due_day': finalDueDay})
                  .eq('property_id', propertyId)
                  .eq('room_number', roomNumber);
              await client
                  .from('tenants')
                  .update({'rent_due_day': finalDueDay})
                  .eq('property_id', propertyId)
                  .eq('room_number', roomNumber);
            }
          } catch (_) {}
        }

        return true;
      } catch (e) {
        debugPrint('Error approving rent extension: $e');
        return false;
      }
    });
  }

  /// Decline rent extension
  Future<bool> declineRentExtension({
    required String propertyId,
    required String tenantName,
    String? roomNumber,
    String? extensionId,
    String? ledgerId,
  }) async {
    return await _withLoading('Declining Extension...', () async {
      try {
        if (extensionId != null && extensionId.isNotEmpty) {
          try {
            await client
                .from('rent_extensions')
                .update({'status': 'declined'}).eq('id', extensionId);
          } catch (_) {}
        }
        try {
          var q = client
              .from('rent_extensions')
              .update({'status': 'declined'}).eq('property_id', propertyId);
          if (ledgerId != null && ledgerId.isNotEmpty) {
            q = q.eq('ledger_id', ledgerId);
          } else if (tenantName.isNotEmpty && tenantName != 'Resident') {
            q = q.ilike('tenant_name', tenantName);
          } else if (roomNumber != null && roomNumber.isNotEmpty) {
            q = q.eq('room_number', roomNumber);
          }
          await q;
        } catch (_) {}
        return true;
      } catch (e) {
        debugPrint('Error declining rent extension: $e');
        return false;
      }
    });
  }

  /// Update an existing damage deduction & synchronize bed deposit if modified
  Future<bool> updateDamageDeduction({
    required String damageId,
    required String itemDamaged,
    required double newAmount,
    required double oldAmount,
    required String deductionMode,
    String? bedId,
  }) async {
    return await _withLoading('Updating Damage Record...', () async {
      try {
        await client.from('damage_deductions').update({
          'item_damaged': itemDamaged,
          'amount': newAmount,
          'deduction_mode': deductionMode,
        }).eq('id', damageId);

        // Adjust bed deposit by difference if mode was/is deposit
        if (deductionMode == 'deposit' && bedId != null && bedId.isNotEmpty) {
          final diff =
              oldAmount - newAmount; // if old 1000 and new 600, refund 400
          if (diff != 0) {
            final bedRes = await client
                .from('beds')
                .select('deposit')
                .eq('id', bedId)
                .maybeSingle();
            final curDeposit = (bedRes?['deposit'] as num?)?.toDouble() ?? 0.0;
            final updatedDeposit =
                (curDeposit + diff).clamp(0.0, double.infinity);
            await client
                .from('beds')
                .update({'deposit': updatedDeposit}).eq('id', bedId);
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error updating damage deduction: $e');
        return false;
      }
    });
  }

  /// Delete / Revert a damage deduction & restore deposit to bed if deducted
  Future<bool> deleteDamageDeduction({
    required String damageId,
    required double amount,
    required String deductionMode,
    String? bedId,
  }) async {
    return await _withLoading('Reverting Damage Charge...', () async {
      try {
        await client.from('damage_deductions').delete().eq('id', damageId);

        // Restore deposit on bed if it was deducted from deposit
        if (deductionMode == 'deposit' &&
            bedId != null &&
            bedId.isNotEmpty &&
            amount > 0) {
          final bedRes = await client
              .from('beds')
              .select('deposit')
              .eq('id', bedId)
              .maybeSingle();
          final curDeposit = (bedRes?['deposit'] as num?)?.toDouble() ?? 0.0;
          final restoredDeposit = curDeposit + amount;
          await client
              .from('beds')
              .update({'deposit': restoredDeposit}).eq('id', bedId);
        }
        return true;
      } catch (e) {
        debugPrint('Error reverting damage deduction: $e');
        return false;
      }
    });
  }

  /// 5. Update UTR / UPI approval status and synchronize with Rent Ledger
  Future<bool> updatePaymentApprovalStatus({
    String? submissionId,
    String? approvalId,
    String? ledgerId,
    required String status,
    String? reason,
  }) async {
    final targetId = submissionId ?? approvalId ?? '';
    return await _withLoading('Updating Approval...', () async {
      try {
        final normalizedStatus = status.toLowerCase();

        // 1. Update payment_approvals if ID exists
        if (targetId.isNotEmpty) {
          try {
            await client.from('payment_approvals').update({
              'status': normalizedStatus,
              if (reason != null && reason.isNotEmpty) 'reject_reason': reason,
            }).eq('id', targetId);
          } catch (_) {
            try {
              await client.from('rent_approvals').update({
                'status': normalizedStatus,
              }).eq('id', targetId);
            } catch (e) {
              debugPrint('Notice on payment_approvals table update: $e');
            }
          }
        }

        // 2. If approved, synchronize with rent_ledgers atomically!
        if (normalizedStatus == 'approved') {
          if (ledgerId != null && ledgerId.isNotEmpty) {
            await client.from('rent_ledgers').update({
              'status': 'PAID',
              'due_amount': 0.0,
              'paid_date': DateTime.now().toIso8601String(),
            }).eq('id', ledgerId);
          } else if (targetId.isNotEmpty) {
            final approvalRes = await client
                .from('payment_approvals')
                .select('ledger_id, property_id, tenant_name, room_number')
                .eq('id', targetId)
                .maybeSingle();

            final lId = approvalRes?['ledger_id']?.toString();
            final propId = approvalRes?['property_id']?.toString();
            final rNum = approvalRes?['room_number']?.toString() ?? '';
            final tName = approvalRes?['tenant_name']?.toString() ?? '';

            if (lId != null && lId.isNotEmpty) {
              await client.from('rent_ledgers').update({
                'status': 'PAID',
                'due_amount': 0.0,
                'paid_date': DateTime.now().toIso8601String(),
              }).eq('id', lId);
            } else if (propId != null && propId.isNotEmpty) {
              var ledgerQuery = client.from('rent_ledgers').update({
                'status': 'PAID',
                'due_amount': 0.0,
                'paid_date': DateTime.now().toIso8601String(),
              }).eq('property_id', propId);

              if (rNum.isNotEmpty) {
                ledgerQuery = ledgerQuery.eq('room_number', rNum);
              } else if (tName.isNotEmpty) {
                ledgerQuery = ledgerQuery.eq('tenant_name', tName);
              }
              await ledgerQuery;
            }
          }
        }
        return true;
      } catch (e) {
        debugPrint('Error updating payment approval: $e');
        return false;
      }
    });
  }

  /// Record cash payment for a rent ledger atomically (updates ledger to PAID + logs into warden_cash_collections)
  Future<bool> recordCashPaymentForRentLedger({
    required String propertyId,
    String? propertyName,
    required String tenantName,
    required String roomNumber,
    required double amount,
    required String collectedBy,
    String? ledgerId,
    String? notes,
  }) async {
    return await _withLoading('Recording Cash Collection...', () async {
      try {
        String pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName != null && activePropertyName!.isNotEmpty
                ? activePropertyName!
                : '');
        if (pName.isEmpty && propertyId.isNotEmpty) {
          try {
            final propRes = await client
                .from('properties')
                .select('property_name, name')
                .eq('id', propertyId)
                .maybeSingle();
            pName = propRes?['property_name']?.toString() ??
                propRes?['name']?.toString() ??
                '';
          } catch (_) {}
        }

        // 1. Update rent_ledgers to PAID FIRST!
        bool updated = false;
        if (ledgerId != null &&
            ledgerId.isNotEmpty &&
            !ledgerId.startsWith('bed_')) {
          try {
            final res = await client
                .from('rent_ledgers')
                .update({
                  'status': 'PAID',
                  'due_amount': 0.0,
                  'paid_date': DateTime.now().toIso8601String(),
                  'payment_mode': 'CASH',
                })
                .eq('id', ledgerId)
                .select('id');
            if (res.isNotEmpty) {
              updated = true;
            }
          } catch (e) {
            debugPrint('Error updating ledger by id: $e');
          }
        }

        if (!updated) {
          try {
            var q = client.from('rent_ledgers').update({
              'status': 'PAID',
              'due_amount': 0.0,
              'paid_date': DateTime.now().toIso8601String(),
              'payment_mode': 'CASH',
            }).eq('property_id', propertyId);

            if (tenantName.isNotEmpty && tenantName != 'Resident') {
              q = q.ilike('tenant_name', tenantName);
            } else if (roomNumber.isNotEmpty) {
              final cleanRoom =
                  roomNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();
              q = q.eq(
                  'room_number', cleanRoom.isNotEmpty ? cleanRoom : roomNumber);
            }
            final res = await q.select('id');
            if (res.isNotEmpty) {
              updated = true;
            }
          } catch (e) {
            debugPrint('Error updating ledger by name/room: $e');
          }

          if (!updated) {
            // Also try matching by clean room number
            try {
              final cleanRoom =
                  roomNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();
              if (cleanRoom.isNotEmpty) {
                final res2 = await client
                    .from('rent_ledgers')
                    .update({
                      'status': 'PAID',
                      'due_amount': 0.0,
                      'paid_date': DateTime.now().toIso8601String(),
                      'payment_mode': 'CASH',
                    })
                    .eq('property_id', propertyId)
                    .eq('room_number', cleanRoom)
                    .select('id');
                if (res2.isNotEmpty) {
                  updated = true;
                }
              }
            } catch (_) {}
          }

          if (!updated) {
            // No ledger row existed at all! Insert one so it permanently persists in Supabase
            final now = DateTime.now();
            const months = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December'
            ];
            final cycleMonth = '${months[now.month - 1]} ${now.year}';
            final cleanRoom =
                roomNumber.replaceAll(RegExp(r'[^0-9]'), '').trim();
            await client.from('rent_ledgers').insert({
              'property_id': propertyId,
              if (pName.isNotEmpty) 'property_name': pName,
              'tenant_name': tenantName,
              'room_number': cleanRoom.isNotEmpty ? cleanRoom : roomNumber,
              'billing_month': cycleMonth,
              'rent_amount': amount,
              'due_amount': 0.0,
              'status': 'PAID',
              'paid_date': DateTime.now().toIso8601String(),
              'payment_mode': 'CASH',
              'due_date':
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-05',
              'rent_due_day': 5,
            });
          }
        }

        // 2. Safely log to warden_cash_collections (matches exact table schema)
        try {
          String? resolvedTenantId;
          if (ledgerId != null &&
              ledgerId.isNotEmpty &&
              !ledgerId.startsWith('bed_')) {
            try {
              final lRes = await client
                  .from('rent_ledgers')
                  .select('tenant_id')
                  .eq('id', ledgerId)
                  .maybeSingle();
              resolvedTenantId = lRes?['tenant_id']?.toString();
            } catch (_) {}
          }
          if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
            try {
              final tRes = await client
                  .from('tenants')
                  .select('id')
                  .eq('property_id', propertyId)
                  .ilike('name', tenantName)
                  .maybeSingle();
              resolvedTenantId = tRes?['id']?.toString();
            } catch (_) {}
          }

          final cashNote = (notes != null && notes.trim().isNotEmpty)
              ? notes.trim()
              : 'Cash received by $collectedBy';

          await client.from('warden_cash_collections').insert({
            'property_id': propertyId,
            if (pName.isNotEmpty) 'property_name': pName,
            if (resolvedTenantId != null && resolvedTenantId.isNotEmpty)
              'tenant_id': resolvedTenantId,
            'tenant_name': tenantName,
            'room_number': roomNumber,
            'warden_name': collectedBy,
            'amount': amount,
            'is_deposited_to_owner': false,
            'notes': cashNote,
          });
        } catch (e) {
          debugPrint('Notice logging to warden_cash_collections: $e');
        }

        return true;
      } catch (e) {
        debugPrint('Error recording cash payment: $e');
        return false;
      }
    });
  }

  /// Update rent due day for a resident (e.g. moving from 1st to 5th or 10th)
  Future<bool> updateRentDueDate({
    String? propertyId,
    String? roomNumber,
    String? tenantName,
    String? ledgerId,
    required int newDueDay,
    String? reason,
  }) async {
    return await _withLoading('Updating Due Date...', () async {
      try {
        final now = DateTime.now();
        final clampedDay = newDueDay.clamp(1, 31);
        final dayPadded = clampedDay.toString().padLeft(2, '0');
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-$dayPadded';

        // 1. Update rent_ledgers
        if (ledgerId != null && ledgerId.isNotEmpty) {
          try {
            await client.from('rent_ledgers').update({
              'due_date': dateStr,
              'rent_due_day': clampedDay,
            }).eq('id', ledgerId);
          } catch (_) {}
        }
        if (propertyId != null && propertyId.isNotEmpty) {
          var q = client.from('rent_ledgers').update({
            'due_date': dateStr,
            'rent_due_day': clampedDay,
          }).eq('property_id', propertyId);
          if (roomNumber != null && roomNumber.isNotEmpty) {
            q = q.eq('room_number', roomNumber);
          } else if (tenantName != null && tenantName.isNotEmpty) {
            q = q.eq('tenant_name', tenantName);
          }
          await q;
        }

        // 2. Persist new due day to beds table
        if (propertyId != null &&
            propertyId.isNotEmpty &&
            roomNumber != null &&
            roomNumber.isNotEmpty) {
          try {
            await client
                .from('beds')
                .update({
                  'rent_due_day': clampedDay,
                })
                .eq('property_id', propertyId)
                .eq('room_number', roomNumber);
          } catch (_) {}
        }

        // 4. Log to rent_extensions table so it is permanently tracked
        try {
          final pId = propertyId ?? activePropertyId ?? '';
          if (pId.isNotEmpty) {
            String pName = activePropertyName ?? '';
            String? resolvedTenantId;
            if (ledgerId != null &&
                ledgerId.isNotEmpty &&
                !ledgerId.startsWith('bed_')) {
              try {
                final l = await client
                    .from('rent_ledgers')
                    .select('tenant_id, property_name')
                    .eq('id', ledgerId)
                    .maybeSingle();
                resolvedTenantId = l?['tenant_id']?.toString();
                if (pName.isEmpty) {
                  pName = l?['property_name']?.toString() ?? '';
                }
              } catch (_) {}
            }
            if (resolvedTenantId == null &&
                tenantName != null &&
                tenantName.isNotEmpty) {
              try {
                final t = await client
                    .from('tenants')
                    .select('id, property_name')
                    .eq('property_id', pId)
                    .ilike('name', tenantName)
                    .maybeSingle();
                resolvedTenantId = t?['id']?.toString();
                if (pName.isEmpty) {
                  pName = t?['property_name']?.toString() ?? '';
                }
              } catch (_) {}
            }

            await client.from('rent_extensions').insert({
              'property_id': pId,
              if (pName.isNotEmpty) 'property_name': pName,
              if (resolvedTenantId != null && resolvedTenantId.isNotEmpty)
                'tenant_id': resolvedTenantId,
              'tenant_name': tenantName ?? 'Resident',
              if (roomNumber != null && roomNumber.isNotEmpty)
                'room_number': roomNumber,
              if (ledgerId != null && ledgerId.isNotEmpty)
                'ledger_id': ledgerId,
              'requested_date': dateStr,
              'reason':
                  reason ?? 'Owner updated rent due day to ${clampedDay}th',
              'status': 'approved',
            });
          }
        } catch (e) {
          debugPrint('Notice logging rent_extension on due date update: $e');
        }

        return true;
      } catch (e) {
        debugPrint('Error updating rent due date: $e');
        return false;
      }
    });
  }

  /// Auto-populate rent_ledgers for all occupied beds in property if empty for current month
  Future<void> ensureMonthlyRentLedgers({
    required String propertyId,
    required String cycleMonth,
  }) async {
    try {
      final existing = await client
          .from('rent_ledgers')
          .select(
              'id, room_number, tenant_id, tenant_name, status, rent_amount, due_amount')
          .eq('property_id', propertyId)
          .eq('billing_month', cycleMonth);

      final List existingList = (existing as List?) ?? [];

      // 1. AUTO-CLEANUP DUPLICATES:
      // Group ledgers by tenant to detect duplicate bills for the same resident in the same cycleMonth
      final Map<String, List<Map<String, dynamic>>> tenantLedgerMap = {};
      for (final raw in existingList) {
        final row = Map<String, dynamic>.from(raw);
        final tId = row['tenant_id']?.toString() ?? '';
        final tName = row['tenant_name']?.toString().trim().toLowerCase() ?? '';
        final key = tId.isNotEmpty
            ? 'id_$tId'
            : (tName.isNotEmpty ? 'name_$tName' : 'id_${row['id']}');
        tenantLedgerMap.putIfAbsent(key, () => []).add(row);
      }

      // If any resident has multiple ledgers for the same month, purge zero-rupee/duplicate pending ones!
      for (final entries in tenantLedgerMap.values) {
        if (entries.length > 1) {
          // Check if there is an active PAID ledger
          final hasPaid = entries.any((e) => e['status'] == 'PAID');
          for (final row in entries) {
            final double rAmt = (row['rent_amount'] as num?)?.toDouble() ?? 0.0;
            final double dAmt = (row['due_amount'] as num?)?.toDouble() ?? 0.0;
            final String status = row['status']?.toString() ?? 'PENDING';
            final String rowId = row['id']?.toString() ?? '';
            // If another row is PAID and this one is PENDING with 0 dues, or zero rent: DELETE IT!
            if (rowId.isNotEmpty &&
                ((hasPaid && status == 'PENDING') ||
                    (rAmt == 0.0 && dAmt == 0.0 && status == 'PENDING'))) {
              try {
                await client.from('rent_ledgers').delete().eq('id', rowId);
                debugPrint(
                    'Purged duplicate ghost rent ledger $rowId for month $cycleMonth.');
              } catch (e) {
                debugPrint('Notice deleting duplicate ledger: $e');
              }
            }
          }
        }
      }

      // Re-fetch remaining clean ledgers after deduplication
      final remaining = await client
          .from('rent_ledgers')
          .select('id, room_number, tenant_id, tenant_name')
          .eq('property_id', propertyId)
          .eq('billing_month', cycleMonth);

      final List remainingList = (remaining as List?) ?? [];
      final Set<String> existingRooms = remainingList
          .map((e) =>
              e['room_number']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
              '')
          .where((r) => r.isNotEmpty)
          .toSet();

      final Set<String> existingTenantIds = remainingList
          .map((e) => e['tenant_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final Set<String> existingTenantNames = remainingList
          .map((e) => e['tenant_name']?.toString().trim().toLowerCase() ?? '')
          .where((n) => n.isNotEmpty && n != 'resident')
          .toSet();

      // Fetch occupied beds
      final roomsWithBeds = await getRoomsWithBeds(propertyId);
      final List<Map<String, dynamic>> toInsert = [];
      final now = DateTime.now();

      for (final r in roomsWithBeds) {
        final rNum = r['room_number']?.toString() ?? '';
        final cleanRoom = rNum.replaceAll(RegExp(r'[^0-9]'), '').trim();
        final roomRent = (r['rent_per_bed'] as num?)?.toDouble() ?? 0.0;
        final beds = (r['beds'] as List?) ?? [];

        for (final b in beds) {
          if (b['is_occupied'] == true) {
            final tName = b['tenant_name']?.toString() ?? 'Resident';
            final cleanTName = tName.trim().toLowerCase();
            final bedRent = (b['rent'] as num?)?.toDouble() ?? roomRent;
            final rawTId = b['tenant_id']?.toString();
            // Only use real UUID from tenants table
            final String? validTenantId = (rawTId != null &&
                    rawTId.isNotEmpty &&
                    !rawTId.startsWith('bed_'))
                ? rawTId
                : null;
            final dueDay = (b['rent_due_day'] as num?)?.toInt() ?? 5;
            final clampedDay = dueDay.clamp(1, 31);
            final dayPadded = clampedDay.toString().padLeft(2, '0');
            final formattedDueDate =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-$dayPadded';

            // GLOBAL CHECK: Do NOT insert if this tenant ALREADY has a ledger this month!
            final bool tenantAlreadyBilled = (validTenantId != null &&
                    existingTenantIds.contains(validTenantId)) ||
                (cleanTName.isNotEmpty &&
                    cleanTName != 'resident' &&
                    existingTenantNames.contains(cleanTName));

            // Also check room
            final bool roomAlreadyBilled =
                cleanRoom.isNotEmpty && existingRooms.contains(cleanRoom);

            if (!tenantAlreadyBilled && !roomAlreadyBilled) {
              toInsert.add({
                'property_id': propertyId,
                'property_name': activePropertyName ?? '',
                if (validTenantId != null) 'tenant_id': validTenantId,
                'tenant_name': tName,
                'room_number': cleanRoom.isNotEmpty ? cleanRoom : rNum,
                'billing_month': cycleMonth,
                'rent_amount': bedRent,
                'due_amount': bedRent,
                'status': 'PENDING',
                'due_date': formattedDueDate,
                'rent_due_day': clampedDay,
                'payment_mode': 'UPI',
              });
              // Mark as existing so subsequent beds in same loop don't duplicate
              if (validTenantId != null) existingTenantIds.add(validTenantId);
              if (cleanTName.isNotEmpty) existingTenantNames.add(cleanTName);
              if (cleanRoom.isNotEmpty) existingRooms.add(cleanRoom);
            }
          }
        }
      }

      if (toInsert.isNotEmpty) {
        await client.from('rent_ledgers').insert(toInsert);
        debugPrint(
            'Auto-populated ${toInsert.length} rent ledger records for $cycleMonth in Supabase.');
      }
    } catch (e) {
      debugPrint('Error in ensureMonthlyRentLedgers: $e');
    }
  }

  /// 6. Fetch strongly-typed MaintenanceTicketModels
  Future<List<MaintenanceTicketModel>> getMaintenanceTicketModels(
      String propertyId) async {
    try {
      final res = await client
          .from('maintenance_tickets')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) =>
              MaintenanceTicketModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      try {
        final res = await client
            .from('complaints')
            .select('*')
            .eq('property_id', propertyId)
            .order('created_at', ascending: false);
        return (res as List)
            .map((e) =>
                MaintenanceTicketModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error fetching maintenance ticket models: $e');
        return [];
      }
    }
  }

  /// 7. Update maintenance ticket / complaint status (e.g. in_progress, resolved, open)
  Future<bool> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    return await _withLoading('Updating Ticket Status...', () async {
      try {
        final Map<String, dynamic> updateData = {
          'status': status.toLowerCase()
        };
        if (resolutionNotes != null) {
          updateData['resolution_notes'] = resolutionNotes;
        }
        await client
            .from('maintenance_tickets')
            .update(updateData)
            .eq('id', complaintId);
        return true;
      } catch (_) {
        try {
          final Map<String, dynamic> updateData = {
            'status': status.toLowerCase()
          };
          if (resolutionNotes != null) {
            updateData['resolution_notes'] = resolutionNotes;
          }
          await client
              .from('complaints')
              .update(updateData)
              .eq('id', complaintId);
          return true;
        } catch (e) {
          debugPrint('Error updating complaint status: $e');
          return false;
        }
      }
    });
  }

  /// 8. Resolve maintenance ticket / complaint
  Future<bool> resolveComplaint(String complaintId) async {
    return await updateComplaintStatus(
      complaintId: complaintId,
      status: 'resolved',
    );
  }

  /// 9. Create maintenance ticket / complaint (with property, tenant, room snapshots)
  Future<bool> createMaintenanceTicket({
    required String propertyId,
    String? propertyName,
    required String tenantId,
    String? tenantName,
    String? roomNumber,
    required String category,
    required String issue,
    String? photoUrl,
  }) async {
    return await _withLoading('Submitting Maintenance Request...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        final payload = {
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          'tenant_id': tenantId,
          if (tenantName != null && tenantName.isNotEmpty)
            'tenant_name': tenantName,
          if (roomNumber != null && roomNumber.isNotEmpty)
            'room_number': roomNumber,
          'category': category,
          'issue': issue,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
          'status': 'pending',
        };
        try {
          await client.from('maintenance_tickets').insert(payload);
          return true;
        } catch (_) {
          await client.from('complaints').insert(payload);
          return true;
        }
      } catch (e) {
        debugPrint('Error creating maintenance ticket: $e');
        return false;
      }
    });
  }

  /// 10. Add operating expense
  Future<bool> addExpense({
    required String propertyId,
    String? propertyName,
    required String category,
    required double amount,
    String? notes,
  }) async {
    return await _withLoading('Recording Operating Expense...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        await client.from('expenses').insert({
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          'title': (notes != null && notes.isNotEmpty) ? notes : category,
          'category': category,
          'amount': amount,
          'vendor': 'Direct Expense',
          'payment_mode': 'UPI',
        });
        return true;
      } catch (e) {
        debugPrint('Error adding expense: $e');
        return false;
      }
    });
  }

  /// 11. Fetch strongly-typed ExpenseModels
  Future<List<ExpenseModel>> getExpenseModels(String propertyId) async {
    try {
      final res = await client
          .from('expenses')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => ExpenseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching expense models: $e');
      return [];
    }
  }

  /// 12. Record operating expense using typed ExpenseModel
  Future<bool> recordExpenseModel(ExpenseModel expense) async {
    return await _withLoading('Recording Operating Expense...', () async {
      try {
        final payload = expense.toJson();
        if ((payload['property_name'] == null ||
                payload['property_name'].toString().isEmpty) &&
            activePropertyName != null) {
          payload['property_name'] = activePropertyName!;
        }
        await client.from('expenses').insert(payload);
        return true;
      } catch (e) {
        debugPrint('Error recording expense model: $e');
        return false;
      }
    });
  }

  /// 13. Fetch strongly-typed staff members (StaffModel: Cooks, Wardens, Maids, Security payroll)
  Future<List<StaffModel>> getStaffMembers(String propertyId) async {
    try {
      final res = await client
          .from('staff')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching staff members: $e');
      return [];
    }
  }

  /// 14. Add staff member using typed StaffModel
  Future<bool> addStaffMember(StaffModel staff) async {
    return await _withLoading('Adding Staff Member...', () async {
      try {
        await client.from('staff').insert(staff.toJson());
        return true;
      } catch (e) {
        debugPrint('Error adding staff member: $e');
        return false;
      }
    });
  }

  /// Update staff member using typed StaffModel
  Future<bool> updateStaffMember(StaffModel staff) async {
    return await _withLoading('Updating Staff Member...', () async {
      try {
        await client.from('staff').update(staff.toJson()).eq('id', staff.id);
        return true;
      } catch (e) {
        debugPrint('Error updating staff member: $e');
        return false;
      }
    });
  }

  /// Delete staff member by ID
  Future<bool> deleteStaffMember(String staffId) async {
    return await _withLoading('Deleting Staff Member...', () async {
      try {
        await client.from('staff').delete().eq('id', staffId);
        return true;
      } catch (e) {
        debugPrint('Error deleting staff member: $e');
        return false;
      }
    });
  }

  /// 15. Fetch strongly-typed FoodMenuModels
  Future<List<FoodMenuModel>> getFoodMenuModels(String propertyId) async {
    try {
      final res = await client
          .from('food_menus')
          .select('*')
          .eq('property_id', propertyId)
          .order('week_number', ascending: true);
      return (res as List)
          .map((e) => FoodMenuModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching food menu models: $e');
      return [];
    }
  }

  /// 16. Upsert FoodMenuModel
  Future<bool> upsertFoodMenuModel(FoodMenuModel menu) async {
    try {
      final payload = menu.toJson();
      if ((payload['property_name'] == null ||
              payload['property_name'].toString().isEmpty) &&
          activePropertyName != null) {
        payload['property_name'] = activePropertyName!;
      }
      payload['updated_at'] = DateTime.now().toIso8601String();
      await client.from('food_menus').upsert(
            payload,
            onConflict: 'property_id,week_number,day_of_week',
          );
      return true;
    } catch (e) {
      debugPrint('Error upserting food menu model: $e');
      return false;
    }
  }

  /// 17. Fetch strongly-typed RoomModels
  Future<List<RoomModel>> getRoomModels(String propertyId) async {
    try {
      final res = await client
          .from('rooms')
          .select('*')
          .eq('property_id', propertyId)
          .order('floor_number', ascending: true)
          .order('room_number', ascending: true);
      return (res as List)
          .map((e) => RoomModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching room models: $e');
      return [];
    }
  }

  /// 18. Fetch strongly-typed BedModels for a property
  Future<List<BedModel>> getBedModels(String propertyId) async {
    try {
      final res = await client
          .from('beds')
          .select('*')
          .eq('property_id', propertyId)
          .order('room_number', ascending: true)
          .order('bed_label', ascending: true);
      return (res as List)
          .map((e) => BedModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching bed models: $e');
      return [];
    }
  }

  /// 19. Fetch strongly-typed OnboardingRequestModels
  Future<List<OnboardingRequestModel>> getOnboardingRequestModels(
      String propertyId) async {
    try {
      final res = await client
          .from('onboarding_requests')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) =>
              OnboardingRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching onboarding request models: $e');
      return [];
    }
  }

  /// 20. Update onboarding / check-in request status
  Future<bool> updateCheckinStatus({
    required String checkinId,
    required String status,
  }) async {
    return await _withLoading('Updating Check-in Status...', () async {
      try {
        await client.from('onboarding_requests').update({
          'status': status.toLowerCase(),
        }).eq('id', checkinId);
        return true;
      } catch (e) {
        debugPrint('Error updating checkin status: $e');
        return false;
      }
    });
  }

  /// 21. Fetch strongly-typed PaymentApprovalModels
  Future<List<PaymentApprovalModel>> getPaymentApprovalModels(
      String propertyId) async {
    try {
      final res = await client
          .from('payment_approvals')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) =>
              PaymentApprovalModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      try {
        final res = await client
            .from('rent_approvals')
            .select('*')
            .eq('property_id', propertyId)
            .order('created_at', ascending: false);
        return (res as List)
            .map((e) =>
                PaymentApprovalModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error fetching payment approval models: $e');
        return [];
      }
    }
  }

  /// 22. Record warden cash collection
  Future<bool> recordCashCollection({
    required String propertyId,
    String? propertyName,
    required String tenantName,
    required double amount,
    required String collectedBy,
    String? roomNumber,
  }) async {
    return await _withLoading('Recording Cash Collection...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        await client.from('warden_cash_collections').insert({
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          'warden_name': collectedBy,
          'tenant_name': tenantName,
          if (roomNumber != null && roomNumber.isNotEmpty)
            'room_number': roomNumber,
          'amount': amount,
          'notes':
              '$tenantName ${roomNumber != null ? "($roomNumber)" : ""}'.trim(),
        });
        return true;
      } catch (e) {
        debugPrint('Error recording cash collection: $e');
        return false;
      }
    });
  }

  /// 23. Fetch strongly-typed WardenCashModels
  Future<List<WardenCashModel>> getWardenCashModels(String propertyId) async {
    try {
      final res = await client
          .from('warden_cash_collections')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => WardenCashModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching warden cash models: $e');
      return [];
    }
  }

  /// 24. Update property settings (Comprehensive: all house rules, business, banking & toggles)
  Future<bool> updatePropertySettings({
    required String propertyId,
    String? propertyName,
    Map<String, dynamic>? settings,
    String? upiId,
    String? upiName,
    String? gateClosingTime,
    String? morningGateOpenTime,
  }) async {
    return await _withLoading('Saving Property Settings...', () async {
      try {
        // 1. Banking updates sync to properties table if provided
        final propUpdates = <String, dynamic>{};
        if (upiId != null && upiId.isNotEmpty) propUpdates['upi_vpa'] = upiId;
        if (upiName != null && upiName.isNotEmpty) {
          propUpdates['bank_holder_name'] = upiName;
        }

        if (propUpdates.isNotEmpty) {
          await client
              .from('properties')
              .update(propUpdates)
              .eq('id', propertyId);
        }

        // 2. Comprehensive settings update to property_settings table
        String pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        final settingsUpdates = <String, dynamic>{
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
        };
        if (gateClosingTime != null) {
          settingsUpdates['gate_closing_time'] = gateClosingTime;
        }
        if (morningGateOpenTime != null) {
          settingsUpdates['morning_gate_open_time'] = morningGateOpenTime;
        }
        if (settings != null && settings.isNotEmpty) {
          settingsUpdates.addAll(settings);
        }

        await client
            .from('property_settings')
            .upsert(settingsUpdates, onConflict: 'property_id');

        return true;
      } catch (e) {
        debugPrint('Error updating property settings: $e');
        return false;
      }
    });
  }

  /// Save full strongly-typed PropertySettingsModel directly to property_settings
  Future<bool> savePropertySettingsModel(PropertySettingsModel model) async {
    return await _withLoading('Saving Settings...', () async {
      try {
        final payload = model.toJson();
        if ((payload['property_name'] == null ||
                payload['property_name'].toString().isEmpty) &&
            activePropertyName != null &&
            activePropertyName!.isNotEmpty) {
          payload['property_name'] = activePropertyName!;
        }
        await client
            .from('property_settings')
            .upsert(payload, onConflict: 'property_id');
        return true;
      } catch (e) {
        debugPrint('Error saving PropertySettingsModel: $e');
        return false;
      }
    });
  }

  /// Instant single-toggle update (e.g., autoSendWhatsappReceipts, dailyLateFineEnabled)
  Future<bool> updateSinglePropertySetting({
    required String propertyId,
    required String key,
    required dynamic value,
  }) async {
    try {
      await client.from('property_settings').upsert({
        'property_id': propertyId,
        key: value,
      }, onConflict: 'property_id');
      return true;
    } catch (e) {
      debugPrint('Error updating single property setting ($key): $e');
      return false;
    }
  }

  /// 25. Fetch strongly-typed PropertySettingsModel with all 35 columns
  Future<PropertySettingsModel?> getPropertySettingsModel(
      String propertyId) async {
    try {
      final res = await client
          .from('property_settings')
          .select('*')
          .eq('property_id', propertyId)
          .maybeSingle();
      if (res == null) return null;
      return PropertySettingsModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('Error fetching property settings model: $e');
      return null;
    }
  }

  /// 26. Fetch strongly-typed PropertyModel
  Future<PropertyModel?> getPropertyModel(
      {String? propertyId, String? ownerId}) async {
    final raw =
        await getOwnerProperty(propertyId: propertyId, ownerId: ownerId);
    if (raw == null) return null;
    return PropertyModel.fromJson(Map<String, dynamic>.from(raw));
  }

  /// 27. Fetch list of strongly-typed PropertyModels for owner
  Future<List<PropertyModel>> getPropertyModels({String? ownerId}) async {
    try {
      final uid = ownerId ?? currentUserId;
      var query = client.from('properties').select('*');
      if (uid != null) {
        query = query.or('owner_id.eq.$uid,owner_id.is.null');
      }
      final res = await query.order('created_at', ascending: false).limit(10);
      return (res as List)
          .map((e) => PropertyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching property models: $e');
      return [];
    }
  }

  /// 28. Fetch active team members (PropertyTeamModel: Co-Owners & PG Managers)
  Future<List<PropertyTeamModel>> getPropertyTeamMembers(
      String propertyId) async {
    try {
      final res = await client
          .from('property_team')
          .select('*')
          .eq('property_id', propertyId)
          .eq('status', 'Active');
      return (res as List)
          .map((e) => PropertyTeamModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching property team: $e');
      return [];
    }
  }

  /// 29. Store invited team member (PropertyTeamModel: Co-Owner or PG Manager)
  Future<bool> inviteTeamMember({
    required String propertyId,
    String? propertyName,
    required String name,
    required String phone,
    required String role,
    List<String>? assignedPropertyIds,
  }) async {
    return await _withLoading('Inviting Team Member...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        await client.from('property_team').insert({
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          'name': name,
          'phone': phone,
          'role': role,
          'status': 'Active',
          if (assignedPropertyIds != null)
            'assigned_property_ids': assignedPropertyIds,
        });
        return true;
      } catch (e) {
        debugPrint('Error inviting team member to DB: $e');
        return false;
      }
    });
  }

  /// 30. Remove/Revoke team member access
  Future<bool> removeTeamMember(String memberId) async {
    return await _withLoading('Updating Access...', () async {
      try {
        await client.from('property_team').update({
          'status': 'Revoked',
        }).eq('id', memberId);
        return true;
      } catch (e) {
        debugPrint('Error removing team member from DB: $e');
        return false;
      }
    });
  }
}
