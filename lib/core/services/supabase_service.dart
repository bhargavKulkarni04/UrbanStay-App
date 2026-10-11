// ==============================================================================
// 🕉️ URBANSTAY — MASTER CENTRALISED DATABASE & API SERVICE
// 🌟 Om Shri Raghavendraya Namaha ✨
// ==============================================================================
// Centralized enterprise backbone (modeled after NoBrokerHood & MyGate architecture).
// Serves all Owner feature folders and Resident/Tenant feature folders.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      query = query.eq('owner_id', uid);
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
        'sharing_type': r['sharing_type'] ?? '2-Sharing',
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
        bedsPayload.add({
          'property_id': propertyId,
          'property_name': brandName,
          'room_id': roomId,
          'room_number': roomNum,
          'bed_label': bedLabel,
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

  /// Fetch SaaS subscription billing invoices for the owner / property
  Future<List<Map<String, dynamic>>> getSaasInvoices(
      {String? propertyId, String? ownerId}) async {
    var query = client.from('saas_invoices').select('*');
    if (propertyId != null && propertyId.isNotEmpty) {
      query = query.eq('property_id', propertyId);
    }
    final uid = ownerId ?? currentUserId;
    if (uid != null) {
      query = query.eq('owner_id', uid);
    }

    final response = await query.order('created_at', ascending: false);
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
    final pName = (propertyName != null && propertyName.isNotEmpty)
        ? propertyName
        : (activePropertyName ?? '');
    final payload = {
      'tenant_id': tenantId,
      'property_id': propertyId,
      if (pName.isNotEmpty) 'property_name': pName,
      if (tenantName != null && tenantName.isNotEmpty) 'tenant_name': tenantName,
      if (roomNumber != null && roomNumber.isNotEmpty) 'room_number': roomNumber,
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

  /// 1. Assign resident to bed permanently in Supabase
  Future<bool> assignResidentToBed({
    required String bedId,
    required String name,
    required String phone,
    String? propertyName,
    String? roomNumber,
    double? rent,
    double? deposit,
  }) async {
    return await _withLoading('Assigning Resident...', () async {
      try {
        final pName = (propertyName != null && propertyName.isNotEmpty)
            ? propertyName
            : (activePropertyName ?? '');
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': name,
          'tenant_phone': phone,
          if (pName.isNotEmpty) 'property_name': pName,
          if (roomNumber != null && roomNumber.isNotEmpty)
            'room_number': roomNumber,
          if (rent != null) 'rent': rent,
          if (deposit != null) 'deposit': deposit,
        }).eq('id', bedId);
        return true;
      } catch (e) {
        debugPrint('Error assigning resident to bed: $e');
        return false;
      }
    });
  }

  /// 2. Shift resident bed (vacates old bed, occupies new bed)
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
        // Free old bed
        await client.from('beds').update({
          'is_occupied': false,
          'status': 'Vacant',
          'tenant_name': null,
          'tenant_phone': null,
          'rent': null,
          'deposit': null,
        }).eq('id', oldBedId);

        final pName = activePropertyName ?? '';
        // Occupy new bed
        await client.from('beds').update({
          'is_occupied': true,
          'status': 'Active',
          'tenant_name': name,
          'tenant_phone': phone,
          if (pName.isNotEmpty) 'property_name': pName,
          if (rent != null) 'rent': rent,
          if (deposit != null) 'deposit': deposit,
        }).eq('id', newBedId);
        return true;
      } catch (e) {
        debugPrint('Error shifting resident bed: $e');
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
        await client.from('beds').update({
          'is_occupied': false,
          'status': 'Vacant',
          'tenant_name': null,
          'tenant_phone': null,
          'rent': null,
          'deposit': null,
        }).eq('id', bedId);
        return true;
      } catch (e) {
        debugPrint('Error vacating bed: $e');
        return false;
      }
    });
  }

  /// 3b. Add Damage Deduction (with 8-pillar loader)
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
        final payload = {
          'property_id': propertyId,
          if (pName.isNotEmpty) 'property_name': pName,
          if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
          'tenant_name': tenantName,
          if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
          if (roomNumber != null && roomNumber.isNotEmpty) 'room_number': roomNumber,
          'item_damaged': itemDamaged,
          'amount': amount,
          'deduction_mode': deductionMode,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        };

        try {
          await client.from('damage_deductions').insert(payload);
        } catch (e) {
          debugPrint('Error inserting into damage_deductions: $e');
          // If property_id column isn't in DB yet, fallback without it
          try {
            final fallback = Map<String, dynamic>.from(payload)
              ..remove('property_id')
              ..remove('property_name');
            await client.from('damage_deductions').insert(fallback);
          } catch (e2) {
            debugPrint('Fallback damage insert error: $e2');
          }
        }

        // If deducting from deposit, reduce deposit on the bed
        if (deductionMode == 'deposit' && bedId.isNotEmpty && amount > 0) {
          final bedRes = await client
              .from('beds')
              .select('deposit')
              .eq('id', bedId)
              .maybeSingle();
          final curDeposit = (bedRes?['deposit'] as num?)?.toDouble() ?? 0.0;
          final newDeposit = (curDeposit - amount).clamp(0.0, double.infinity);
          await client
              .from('beds')
              .update({'deposit': newDeposit}).eq('id', bedId);
        }
        return true;
      } catch (e) {
        debugPrint('Error logging damage deduction: $e');
        return false;
      }
    });
  }

  /// 4. Update UTR / UPI approval status
  Future<bool> updatePaymentApprovalStatus({
    required String submissionId,
    required String status,
  }) async {
    return await _withLoading('Updating Approval...', () async {
      try {
        await client.from('payment_approvals').update({
          'status': status.toLowerCase(),
        }).eq('id', submissionId);
        return true;
      } catch (_) {
        try {
          await client.from('rent_approvals').update({
            'status': status.toLowerCase(),
          }).eq('id', submissionId);
          return true;
        } catch (e) {
          debugPrint('Error updating payment approval: $e');
          return false;
        }
      }
    });
  }

  /// 5. Fetch live complaints / maintenance tickets
  Future<List<Map<String, dynamic>>> getComplaints(String propertyId) async {
    try {
      final res = await client
          .from('maintenance_tickets')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        final res = await client
            .from('complaints')
            .select('*')
            .eq('property_id', propertyId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('Error fetching maintenance tickets/complaints: $e');
        return [];
      }
    }
  }

  /// 4b. Fetch payment approvals (0% Direct UPI)
  Future<List<Map<String, dynamic>>> getPaymentApprovals(
      String propertyId) async {
    try {
      final res = await client
          .from('payment_approvals')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        final res = await client
            .from('rent_approvals')
            .select('*')
            .eq('property_id', propertyId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('Error fetching payment approvals: $e');
        return [];
      }
    }
  }

  /// 5B. Update maintenance ticket / complaint status (e.g. in_progress, resolved, open)
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

  /// 5C. Resolve maintenance ticket / complaint
  Future<bool> resolveComplaint(String complaintId) async {
    return await updateComplaintStatus(
      complaintId: complaintId,
      status: 'resolved',
    );
  }

  /// 5D. Create maintenance ticket / complaint (with property, tenant, room snapshots)
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

  /// 6. Add operating expense
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

  /// 7. Fetch operating expenses
  Future<List<Map<String, dynamic>>> getExpenses(String propertyId) async {
    try {
      final res = await client
          .from('expenses')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
      return [];
    }
  }

  /// 8. Fetch staff members
  Future<List<Map<String, dynamic>>> getStaff(String propertyId) async {
    try {
      final res = await client
          .from('property_team')
          .select('*')
          .eq('property_id', propertyId);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        final res = await client
            .from('staff')
            .select('*')
            .eq('property_id', propertyId);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        debugPrint('Error fetching staff/team: $e');
        return [];
      }
    }
  }

  /// 9. Add or update staff member
  Future<bool> addStaff({
    required String propertyId,
    String? propertyName,
    required String name,
    required String role,
    required String phone,
    double? salary,
  }) async {
    return await _withLoading('Adding Staff Member...', () async {
      final pName = (propertyName != null && propertyName.isNotEmpty)
          ? propertyName
          : (activePropertyName ?? '');
      final payload = {
        'property_id': propertyId,
        if (pName.isNotEmpty) 'property_name': pName,
        'name': name,
        'role': role.toLowerCase(),
        'phone': phone,
        if (salary != null) 'monthly_salary': salary,
      };
      try {
        await client.from('property_team').insert(payload);
        return true;
      } catch (_) {
        try {
          await client.from('staff').insert(payload);
          return true;
        } catch (e) {
          debugPrint('Error adding staff: $e');
          return false;
        }
      }
    });
  }

  /// 10. Fetch food menu
  Future<List<Map<String, dynamic>>> getFoodMenu(String propertyId) async {
    try {
      final res = await client
          .from('food_menus')
          .select('*')
          .eq('property_id', propertyId);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching food menu: $e');
      return [];
    }
  }

  /// 11. Save/Update food menu for a day in a specific week cycle
  Future<bool> saveFoodMenu({
    required String propertyId,
    required String dayOfWeek,
    required String breakfast,
    required String lunch,
    required String dinner,
    int weekNumber = 1,
    int cycleWeeks = 2,
    String? propertyName,
  }) async {
    return await _withLoading('Saving Meal Menu...', () async {
      try {
        await client.from('food_menus').upsert({
          'property_id': propertyId,
          if (propertyName != null && propertyName.isNotEmpty)
            'property_name': propertyName,
          'cycle_weeks': cycleWeeks,
          'week_number': weekNumber,
          'day_of_week': dayOfWeek,
          'breakfast': breakfast,
          'lunch': lunch,
          'dinner': dinner,
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      } catch (e) {
        debugPrint('Error saving food menu: $e');
        return false;
      }
    });
  }

  /// 12. Fetch check-in requests from QR standee
  Future<List<Map<String, dynamic>>> getTenantCheckins(
      String propertyId) async {
    try {
      final res = await client
          .from('onboarding_requests')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching tenant checkins: $e');
      return [];
    }
  }

  /// 13. Update onboarding / check-in request status
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

  /// 14. Record warden cash collection
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

  /// 15. Fetch day collections
  Future<List<Map<String, dynamic>>> getDayCollections(
      String propertyId) async {
    try {
      final res = await client
          .from('warden_cash_collections')
          .select('*')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching day collections: $e');
      return [];
    }
  }

  /// 16. Update property settings (UPI VPA, Rules, Gate timings)
  Future<bool> updatePropertySettings({
    required String propertyId,
    Map<String, dynamic>? settings,
    String? upiId,
    String? upiName,
    String? gateClosingTime,
  }) async {
    return await _withLoading('Saving Property Settings...', () async {
      try {
        // 1. Banking updates go to properties table (upi_vpa, bank_holder_name)
        final propUpdates = <String, dynamic>{};
        if (upiId != null) propUpdates['upi_vpa'] = upiId;
        if (upiName != null) propUpdates['bank_holder_name'] = upiName;

        if (propUpdates.isNotEmpty) {
          await client
              .from('properties')
              .update(propUpdates)
              .eq('id', propertyId);
        }

        // 2. House rules & curfew go to property_settings table
        final settingsUpdates = <String, dynamic>{};
        if (gateClosingTime != null) {
          settingsUpdates['gate_closing_time'] = gateClosingTime;
        }
        if (settings != null) {
          settingsUpdates.addAll(settings);
        }

        if (settingsUpdates.isNotEmpty) {
          settingsUpdates['property_id'] = propertyId;
          await client
              .from('property_settings')
              .upsert(settingsUpdates, onConflict: 'property_id');
        }

        return true;
      } catch (e) {
        debugPrint('Error updating property settings: $e');
        return false;
      }
    });
  }

  /// 16B. Fetch property settings & house rules
  Future<Map<String, dynamic>?> getPropertySettings(String propertyId) async {
    try {
      final res = await client
          .from('property_settings')
          .select('*')
          .eq('property_id', propertyId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error fetching property settings: $e');
      return null;
    }
  }

  /// 17. Fetch active team members (Co-Owners & PG Managers)
  Future<List<Map<String, dynamic>>> getPropertyTeam(String propertyId) async {
    try {
      final res = await client
          .from('property_team')
          .select('*')
          .eq('property_id', propertyId)
          .eq('status', 'Active');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching property team: $e');
      return [];
    }
  }

  /// 18. Store invited team member (Co-Owner or PG Manager)
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

  /// 19. Remove/Revoke team member access
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
