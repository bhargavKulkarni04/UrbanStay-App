import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../tenant_dashboard/presentation/screens/tenant_dashboard_screen.dart';

/// Screen 14: Tenant Digital Check-In Wizard.
/// 100% exact translation of `ProductionCode/tenant_checkin.html`
/// using the verified UI components from `owner_setup_screen.dart`:
/// - Animated `_FloatingInput` (labels float up in emerald green on tap).
/// - Tactile `_buildInteractiveCard` with zero pre-selection.
/// - Exact room generation logic from JavaScript (Ground G-01..G-04, 1st 101..104, etc. + Custom).
/// - Strict input validations matching `handleContinue()` in `tenant_checkin.html`.
class TenantCheckinScreen extends StatefulWidget {
  final String? propertyId;
  final String? initialPgCode;
  final String? initialPhoneOrEmail;
  final String? initialName;

  const TenantCheckinScreen({
    super.key,
    this.propertyId,
    this.initialPgCode,
    this.initialPhoneOrEmail,
    this.initialName,
  });

  @override
  State<TenantCheckinScreen> createState() => _TenantCheckinScreenState();
}

class _TenantCheckinScreenState extends State<TenantCheckinScreen> {
  int _currentStep =
      1; // 1 = Details, 2 = Work/Study, 3 = Room/Stay, 4 = Digital Pass

  // --- Step 1 Controllers & State ---
  late String _pgCode;
  String? _propertyId;
  String _propertyName = '';
  String _propertyStructure = 'Standard PG';
  bool _isLoadingProperty = true;
  bool _isSubmitting = false;

  late final TextEditingController _tenantNameController;
  String? _gender; // Zero pre-selected: Male, Female, Other
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _moveInDateController = TextEditingController();
  late final TextEditingController _tenantPhoneController;
  late final TextEditingController _tenantEmailController;
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _permAddressController = TextEditingController();
  final TextEditingController _permCityController = TextEditingController();
  final TextEditingController _permPincodeController = TextEditingController();
  final TextEditingController _tenantAadhaarController =
      TextEditingController();

  DateTime? _dobDate;
  DateTime? _moveInDate;
  bool _aadhaarFrontDone = false;
  bool _aadhaarBackDone = false;
  bool _selfieDone = false;

  // --- Step 2 Controllers & State ---
  String? _occupation; // Zero pre-selected: Professional, Student, Job Seeker
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  bool _workIdDone = false;

  // --- Step 3 Controllers & State ---
  String? _sharingType; // 1-Share, 2-Share, 3-Share, 4-Share, 5-Share, 6-Share
  String? _selectedSpace; // Hall, Bedroom, Master Bedroom (for Apartment Units)
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  String? _selectedFloor; // Ground, 1st, 2nd, 3rd, 4th, 5+
  String? _selectedRoom; // e.g. "101", "102"
  final TextEditingController _bedIdentifierController =
      TextEditingController();

  // Strongly-typed Room list (populated from live PG property)
  List<RoomModel> _rooms = [];

  List<String> get _availableFloors {
    final list = _rooms.toList()
      ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
    return list.map((r) => r.floorLabel).toSet().toList();
  }

  List<String> get _availableSharings {
    return _rooms
        .map((r) => r.sharingType)
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _getRoomsForFloor(String floor) {
    final list = _rooms
        .where((r) => r.floorLabel == floor)
        .map((r) => r.roomNumber)
        .toSet()
        .toList();
    list.sort((a, b) {
      final intA = int.tryParse(a);
      final intB = int.tryParse(b);
      if (intA != null && intB != null) return intA.compareTo(intB);
      return a.compareTo(b);
    });
    return list;
  }

  String _extractSpaceFromBed(String bedLabel) {
    final match = RegExp(r'\((.*?)\)').firstMatch(bedLabel);
    if (match != null && match.group(1) != null) {
      final inside = match.group(1)!.trim();
      if (inside.isNotEmpty) return inside;
    }
    final lower = bedLabel.toLowerCase();
    if (lower.contains('hall')) return 'Hall';
    if (lower.contains('master')) return 'Master Bedroom';
    if (lower.contains('bedroom')) return 'Bedroom';
    return 'Room Space';
  }

  List<String> _getSpacesForFlat(RoomModel flat) {
    final spaces = <String>{};
    for (final b in flat.beds) {
      final s = _extractSpaceFromBed(b.bedLabel);
      if (s.isNotEmpty) spaces.add(s);
    }
    return spaces.toList();
  }

  void _selectSpace(String space, RoomModel flat) {
    setState(() {
      _selectedSpace = space;
      _bedIdentifierController.clear();
      _sharingType = space;

      final spaceBeds = flat.beds
          .where((b) => _extractSpaceFromBed(b.bedLabel) == space)
          .toList();
      final pricedBed =
          spaceBeds.where((b) => b.rent != null && b.rent! > 0).firstOrNull;
      if (pricedBed != null && pricedBed.rent != null && pricedBed.rent! > 0) {
        _rentController.text = pricedBed.rent!.toInt().toString();
        if (pricedBed.deposit != null && pricedBed.deposit! > 0) {
          _depositController.text = pricedBed.deposit!.toInt().toString();
        } else if (flat.depositPerBed > 0) {
          _depositController.text = flat.depositPerBed.toInt().toString();
        }
      } else {
        if (flat.rentPerBed > 0) {
          _rentController.text = flat.rentPerBed.toInt().toString();
        }
        if (flat.depositPerBed > 0) {
          _depositController.text = flat.depositPerBed.toInt().toString();
        }
      }

      final firstVacant = spaceBeds.where((b) => b.isVacant).firstOrNull;
      if (firstVacant != null) {
        _bedIdentifierController.text = firstVacant.bedLabel;
      }
    });
  }

  void _selectRoom(String roomNum) {
    setState(() {
      _selectedRoom = roomNum;
      _selectedSpace = null;
      _bedIdentifierController.clear();
      final matchingRoom = _rooms
          .where((r) =>
              r.roomNumber == roomNum &&
              (_selectedFloor == null || r.floorLabel == _selectedFloor))
          .firstOrNull;
      if (matchingRoom != null) {
        final isApartment = _propertyStructure == 'Apartment Units';
        if (isApartment) {
          final spaces = _getSpacesForFlat(matchingRoom);
          if (spaces.length == 1) {
            _selectSpace(spaces.first, matchingRoom);
          } else {
            _sharingType = matchingRoom.sharingType;
            if (matchingRoom.rentPerBed > 0) {
              _rentController.text = matchingRoom.rentPerBed.toInt().toString();
            }
            if (matchingRoom.depositPerBed > 0) {
              _depositController.text =
                  matchingRoom.depositPerBed.toInt().toString();
            }
          }
        } else {
          _sharingType = matchingRoom.sharingType;
          if (matchingRoom.rentPerBed > 0) {
            _rentController.text = matchingRoom.rentPerBed.toInt().toString();
          }
          if (matchingRoom.depositPerBed > 0) {
            _depositController.text =
                matchingRoom.depositPerBed.toInt().toString();
          }
        }
      }
    });
  }

  void _selectSharing(String type) {
    setState(() {
      _sharingType = type;
      // Auto-fill rent and deposit from the owner's rooms configured with this sharing
      final matchingRoom =
          _rooms.where((r) => r.sharingType == type).firstOrNull;
      if (matchingRoom != null) {
        if (matchingRoom.rentPerBed > 0) {
          _rentController.text = matchingRoom.rentPerBed.toInt().toString();
        }
        if (matchingRoom.depositPerBed > 0) {
          _depositController.text =
              matchingRoom.depositPerBed.toInt().toString();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _propertyId =
        widget.propertyId ?? SupabaseService.instance.activePropertyId;
    _pgCode = widget.initialPgCode?.trim().toUpperCase() ?? '';

    _tenantNameController =
        TextEditingController(text: widget.initialName ?? '');

    final phone = widget.initialPhoneOrEmail != null &&
            !widget.initialPhoneOrEmail!.contains('@')
        ? widget.initialPhoneOrEmail!
        : '';
    final email = widget.initialPhoneOrEmail != null &&
            widget.initialPhoneOrEmail!.contains('@')
        ? widget.initialPhoneOrEmail!
        : '';

    _tenantPhoneController = TextEditingController(text: phone);
    _tenantEmailController = TextEditingController(text: email);

    // Default move-in date to today
    final now = DateTime.now();
    _moveInDate = now;
    _moveInDateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    _loadPropertyAndRooms();
  }

  /// 1. Fetch Property Info and Rooms using Property UUID
  Future<void> _loadPropertyAndRooms() async {
    setState(() => _isLoadingProperty = true);
    try {
      final client = SupabaseService.instance.client;

      // Resolve Property UUID
      String? targetPropId = _propertyId;
      if ((targetPropId == null || targetPropId.isEmpty) &&
          _pgCode.isNotEmpty) {
        final propLookup = await client
            .from('properties')
            .select('id')
            .eq('property_code', _pgCode)
            .maybeSingle();
        if (propLookup != null) {
          targetPropId = propLookup['id']?.toString();
        }
      }

      if (targetPropId == null || targetPropId.isEmpty) {
        if (mounted) setState(() => _isLoadingProperty = false);
        return;
      }

      _propertyId = targetPropId;

      // Fetch Property Info using Property UUID
      final propData = await client
          .from('properties')
          .select('*')
          .eq('id', _propertyId!)
          .maybeSingle();

      if (propData != null) {
        _propertyName = (propData['property_name'] ??
                propData['brand_name'] ??
                propData['name'] ??
                '')
            .toString();
        _propertyStructure =
            propData['property_structure']?.toString() ?? 'Standard PG';
      }

      // Fetch Rooms and Beds using Property UUID
      List<dynamic> roomsData = [];
      try {
        roomsData = await client
            .from('rooms')
            .select('*, beds(*)')
            .eq('property_id', _propertyId!)
            .order('floor_number')
            .order('room_number');
      } catch (_) {
        roomsData = await client
            .from('rooms')
            .select('*')
            .eq('property_id', _propertyId!)
            .order('floor_number')
            .order('room_number');
      }

      final List<RoomModel> loadedRooms = (roomsData as List)
          .map((e) => RoomModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (mounted) {
        setState(() {
          _rooms = loadedRooms;
          _isLoadingProperty = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading property and rooms: $e');
      if (mounted) {
        setState(() => _isLoadingProperty = false);
      }
    }
  }

  /// 2. Submit Check-in to onboarding_requests under this Property UUID
  Future<void> _submitCheckin() async {
    if (_isSubmitting) return;

    if (_propertyId == null || _propertyId!.isEmpty) {
      _showError('Property reference missing. Unable to submit check-in.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = SupabaseService.instance.client;
      final rent = double.tryParse(_rentController.text.trim()) ?? 0.0;
      final deposit = double.tryParse(_depositController.text.trim()) ?? 0.0;
      final room = _selectedRoom ?? '';
      final sharing = _sharingType ?? 'Standard';
      final bed = _bedIdentifierController.text.trim().isNotEmpty
          ? _bedIdentifierController.text.trim()
          : 'Any Available';
      final name = _tenantNameController.text.trim();
      final phone = _tenantPhoneController.text.trim();
      final email = _tenantEmailController.text.trim();
      final aadhaar = _tenantAadhaarController.text.trim();

      final requestPayload = {
        'property_id': _propertyId!,
        'property_name': _propertyName,
        'tenant_name': name,
        'phone': phone,
        if (_gender != null) 'gender': _gender!,
        if (_occupation != null) 'occupation': _occupation!,
        if (_companyNameController.text.trim().isNotEmpty)
          'company': _companyNameController.text.trim(),
        'requested_room': room,
        'requested_bed': bed,
        'sharing_type': sharing,
        'monthly_rent': rent,
        'deposit_amount': deposit,
        if (aadhaar.isNotEmpty)
          'aadhaar_masked': aadhaar.length >= 4
              ? 'XXXX-XXXX-${aadhaar.substring(aadhaar.length - 4)}'
              : aadhaar,
        'status': 'PENDING_APPROVAL',
      };

      await client.from('onboarding_requests').insert(requestPayload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in submitted! Awaiting owner confirmation.'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TenantDashboardScreen(
              tenantName: name,
              roomNumber: room,
              bedId: bed,
              pgName: _propertyName ?? '',
              propertyId: _propertyId,
              monthlyRent: rent,
              securityDeposit: deposit,
              tenantPhone: phone,
              sharingType: sharing,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error submitting checkin request: $e');
      if (mounted) {
        _showError('Submission error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _dobController.dispose();
    _moveInDateController.dispose();
    _tenantPhoneController.dispose();
    _tenantEmailController.dispose();
    _guardianNameController.dispose();
    _permAddressController.dispose();
    _permCityController.dispose();
    _permPincodeController.dispose();
    _tenantAadhaarController.dispose();
    _companyNameController.dispose();
    _workLocationController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _bedIdentifierController.dispose();
    super.dispose();
  }

  // --- STRICT VALIDATION & STEP LOGIC (Exact match with handleContinue() in tenant_checkin.html) ---
  Future<void> _handleContinue() async {
    if (_currentStep == 1) {
      final name = _tenantNameController.text.trim();
      final phone = _tenantPhoneController.text.trim();
      final aadhaarDigits =
          _tenantAadhaarController.text.replaceAll(RegExp(r'\s'), '');

      if (name.isEmpty) {
        _showError('Please enter your full legal name.');
        return;
      }
      if (_gender == null) {
        _showError('Please select your Gender.');
        return;
      }
      if (phone.isEmpty || phone.length < 10) {
        _showError('Please enter a valid 10-digit WhatsApp number.');
        return;
      }
      if (aadhaarDigits.length != 12) {
        _showError('Please enter your complete 12-digit Aadhaar number.');
        return;
      }

      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_occupation == null) {
        _showError('Please select your Occupation Type.');
        return;
      }

      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      final isApartment = _propertyStructure == 'Apartment Units';
      if (_selectedFloor == null) {
        _showError(isApartment
            ? 'Please select which floor your flat is on.'
            : 'Please select which floor your room is on.');
        return;
      }
      if (_selectedRoom == null || _selectedRoom!.isEmpty) {
        _showError(isApartment
            ? 'Please select your Flat Number.'
            : 'Please select your Room Number.');
        return;
      }
      if (isApartment) {
        final matchingRoom = _rooms
            .where((r) =>
                r.roomNumber == _selectedRoom &&
                (_selectedFloor == null || r.floorLabel == _selectedFloor))
            .firstOrNull;
        if (matchingRoom != null) {
          final spaces = _getSpacesForFlat(matchingRoom);
          if (spaces.isNotEmpty &&
              (_selectedSpace == null || _selectedSpace!.isEmpty)) {
            _showError('Please select which space in the flat you are staying in.');
            return;
          }
        }
      }
      if (_sharingType == null || _sharingType!.isEmpty) {
        _showError('Sharing or space type could not be determined. Please reselect.');
        return;
      }
      if (_rentController.text.trim().isEmpty) {
        _showError('Please enter your Monthly Rent (₹).');
        return;
      }

      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      await _submitCheckin();
    }
  }

  void _handleSkip() {
    // Line 1096-1104
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _handleBack() {
    // Line 1084-1094
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Aadhaar auto-space formatter XXXX XXXX XXXX (Line 942-947)
  void _onAadhaarChanged(String val) {
    final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
    final limited =
        digitsOnly.length > 12 ? digitsOnly.substring(0, 12) : digitsOnly;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    if (formatted != val) {
      _tenantAadhaarController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // Date Pickers
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dobDate ?? DateTime(now.year - 23, 1, 1),
      firstDate: DateTime(now.year - 70),
      lastDate: DateTime(now.year - 15),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.green,
            onPrimary: Colors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickMoveInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? now,
      firstDate: DateTime(now.year, now.month - 1),
      lastDate: DateTime(now.year, now.month + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.green,
            onPrimary: Colors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _moveInDate = picked;
        _moveInDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation (Hidden on Step 4 matching line 1118 of HTML)
            if (_currentStep < 4) _buildTopNavigation(),

            // Scrollable Step View
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 1) _buildStep1View(),
                    if (_currentStep == 2) _buildStep2View(),
                    if (_currentStep == 3) _buildStep3View(),
                    if (_currentStep == 4) _buildStep4View(),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Action Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP NAVIGATION (Exact match: back button + "Step X of 3" + segmented bar)
  // ===========================================================================
  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 20.0, 8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.ink),
                onPressed: _handleBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                'Step $_currentStep of 3',
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3-Segment Progress Bar Track
          Row(
            children: [
              _buildProgressSegment(isActive: _currentStep >= 1),
              const SizedBox(width: 6),
              _buildProgressSegment(isActive: _currentStep >= 2),
              const SizedBox(width: 6),
              _buildProgressSegment(isActive: _currentStep >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? AppColors.green : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1: USER DETAILS (Lines 575-709 of HTML)
  // ===========================================================================
  Widget _buildStep1View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('User Details',
            'Enter your details to register with your PG property.'),
        const SizedBox(height: 16),

        // Full Legal Name
        _FloatingInput(
          controller: _tenantNameController,
          label: 'Full Legal Name (as per Aadhaar)',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),

        // Gender Selection (Zero Pre-selected)
        _buildSectionLabel('Gender'),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: 'Male',
                isSelected: _gender == 'Male',
                onTap: () => setState(() => _gender = 'Male'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: 'Female',
                isSelected: _gender == 'Female',
                onTap: () => setState(() => _gender = 'Female'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: 'Other',
                isSelected: _gender == 'Other',
                onTap: () => setState(() => _gender = 'Other'),
              ),
            ),
          ],
        ),
        _buildDivider(),

        // Date of Birth & Move-in Date (2-column layout)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: _FloatingInput(
                    controller: _dobController,
                    label: 'Date of Birth',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _pickMoveInDate,
                child: AbsorbPointer(
                  child: _FloatingInput(
                    controller: _moveInDateController,
                    label: 'Move-In Date',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // WhatsApp Mobile Number with 🇮🇳 +91 country pill
        Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '+91',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FloatingInput(
                controller: _tenantPhoneController,
                label: 'WhatsApp Mobile Number',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Email Address
        _FloatingInput(
          controller: _tenantEmailController,
          label: 'Email Address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        // Father / Husband / Guardian Name
        _FloatingInput(
          controller: _guardianNameController,
          label: 'Father / Husband / Guardian Name',
          textCapitalization: TextCapitalization.words,
        ),
        _buildDivider(),

        // Permanent Home Address (Optional Subheading Row)
        _buildSubheadingWithBadge('Permanent Home Address', 'Optional'),
        const SizedBox(height: 8),

        // Street Address / House No (as per Aadhaar)
        _FloatingInput(
          controller: _permAddressController,
          label: 'Street Address / House No (as per Aadhaar)',
        ),
        const SizedBox(height: 10),

        // City / District & Pincode (2-column layout)
        Row(
          children: [
            Expanded(
              child: _FloatingInput(
                controller: _permCityController,
                label: 'City / District',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FloatingInput(
                controller: _permPincodeController,
                label: 'Pincode',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLength: 6,
              ),
            ),
          ],
        ),
        _buildDivider(),

        // Aadhaar & Photo Verification
        _buildSectionLabel('Aadhaar & Photo Verification'),
        const SizedBox(height: 8),

        // 12-digit Aadhaar Number
        _FloatingInput(
          controller: _tenantAadhaarController,
          label: '12-digit Aadhaar Number',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            LengthLimitingTextInputFormatter(14),
          ],
          maxLength: 14,
          onChanged: _onAadhaarChanged,
        ),
        const SizedBox(height: 10),

        // Aadhaar Card Photos (Front & Back pill buttons)
        Row(
          children: [
            Expanded(
              child: _buildUploadPillButton(
                title: _aadhaarFrontDone ? '✓ Attached' : 'Front Photo',
                isAttached: _aadhaarFrontDone,
                onTap: () =>
                    setState(() => _aadhaarFrontDone = !_aadhaarFrontDone),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildUploadPillButton(
                title: _aadhaarBackDone ? '✓ Attached' : 'Back Photo',
                isAttached: _aadhaarBackDone,
                onTap: () =>
                    setState(() => _aadhaarBackDone = !_aadhaarBackDone),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tenant Live Photo / Selfie
        _buildUploadSingleButton(
          title: _selfieDone ? '✓ Attached' : 'Take Live Selfie / Upload Photo',
          icon: Icons.camera_alt_outlined,
          isAttached: _selfieDone,
          onTap: () => setState(() => _selfieDone = !_selfieDone),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: WORK & STUDY (Lines 712-767 of HTML)
  // ===========================================================================
  Widget _buildStep2View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('Work & Study',
            'Tell us about your current occupation or college.'),
        const SizedBox(height: 16),

        // Mandatory Occupation Type (Zero Pre-selected)
        _buildSectionLabel('Occupation Type *'),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: 'Professional',
                sub: 'Working',
                isSelected: _occupation == 'Professional',
                onTap: () => setState(() => _occupation = 'Professional'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: 'Student',
                sub: 'College / Univ',
                isSelected: _occupation == 'Student',
                onTap: () => setState(() => _occupation = 'Student'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: 'Job Seeker',
                sub: 'Intern / Other',
                isSelected: _occupation == 'Job Seeker',
                onTap: () => setState(() => _occupation = 'Job Seeker'),
              ),
            ),
          ],
        ),
        _buildDivider(),

        // Optional Company / College Name
        _FloatingInput(
          controller: _companyNameController,
          label: 'Company / College Name (Optional)',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),

        // Optional Workplace / Campus Location
        _FloatingInput(
          controller: _workLocationController,
          label: 'Office / Campus Location (Optional)',
          textCapitalization: TextCapitalization.words,
        ),
        _buildDivider(),

        // Optional Work / Student ID Upload
        _buildSectionLabel('Work / Student ID Card (Optional)'),
        const SizedBox(height: 6),
        _buildUploadSingleButton(
          title: _workIdDone ? '✓ Attached' : 'Upload Work / Student ID',
          icon: Icons.badge_outlined,
          isAttached: _workIdDone,
          onTap: () => setState(() => _workIdDone = !_workIdDone),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: ROOM & STAY DETAILS (Lines 770-873 of HTML)
  // ===========================================================================
  Widget _buildStep3View() {
    final floorRooms = _selectedFloor != null
        ? _getRoomsForFloor(_selectedFloor!)
        : <String>[];

    final isApartment = _propertyStructure == 'Apartment Units';
    final matchingRoom = _rooms
        .where((r) =>
            r.roomNumber == _selectedRoom &&
            (_selectedFloor == null || r.floorLabel == _selectedFloor))
        .firstOrNull;
    final flatSpaces =
        matchingRoom != null ? _getSpacesForFlat(matchingRoom) : <String>[];
    final bool showFinancials = (!isApartment && _selectedRoom != null) ||
        (isApartment &&
            _selectedRoom != null &&
            (_selectedSpace != null || flatSpaces.isEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          isApartment ? 'Flat & Stay Details' : 'Room & Stay Details',
          isApartment
              ? 'Select your floor, flat number, and confirm your stay details.'
              : 'Select your floor, pick your allocated room, and confirm your stay details.',
        ),
        const SizedBox(height: 16),

        // 1. Floor Selection (Dynamic from _availableFloors, naturally sorted)
        _buildSectionLabel(isApartment
            ? 'Which Floor is your Flat on?'
            : 'Which Floor is your Room on?'),
        if (_isLoadingProperty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.green,
                ),
              ),
            ),
          )
        else if (_availableFloors.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(
                isApartment
                    ? 'No floors or flats available for this property.'
                    : 'No floors or rooms available for this property.',
                style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 13, color: AppColors.muted),
              ),
            ),
          )
        else
          for (int rIdx = 0;
              rIdx < (_availableFloors.length / 3).ceil();
              rIdx++) ...[
            if (rIdx > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (int cIdx = 0; cIdx < 3; cIdx++) ...[
                  if (cIdx > 0) const SizedBox(width: 6),
                  if (rIdx * 3 + cIdx < _availableFloors.length)
                    Expanded(
                      child: _buildInteractiveCard(
                        title: _availableFloors[rIdx * 3 + cIdx]
                                .replaceAll(
                                    RegExp(r'\s*Floor', caseSensitive: false),
                                    '')
                                .trim()
                                .isNotEmpty
                            ? _availableFloors[rIdx * 3 + cIdx]
                                .replaceAll(
                                    RegExp(r'\s*Floor', caseSensitive: false),
                                    '')
                                .trim()
                            : _availableFloors[rIdx * 3 + cIdx],
                        sub: 'Floor',
                        isSelected:
                            _selectedFloor == _availableFloors[rIdx * 3 + cIdx],
                        onTap: () => setState(() {
                          _selectedFloor = _availableFloors[rIdx * 3 + cIdx];
                          _selectedRoom = null;
                          _selectedSpace = null;
                          _sharingType = null;
                          _bedIdentifierController.clear();
                        }),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        _buildDivider(),

        // 2. Dynamic Floor-Wise Room / Flat Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel(
                isApartment ? 'Select Flat Number' : 'Select Room Number'),
            Text(
              isApartment ? 'Click flat to select' : 'Click room to select',
              style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (_selectedFloor == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(
                isApartment
                    ? 'Select a floor above to view available flats.'
                    : 'Select a floor above to view available rooms.',
                style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 13, color: AppColors.muted),
              ),
            ),
          )
        else if (floorRooms.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(
                isApartment
                    ? 'No flats available on this floor.'
                    : 'No rooms available on this floor.',
                style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 13, color: AppColors.muted),
              ),
            ),
          )
        else
          for (int rIdx = 0; rIdx < (floorRooms.length / 4).ceil(); rIdx++) ...[
            if (rIdx > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (int cIdx = 0; cIdx < 4; cIdx++) ...[
                  if (cIdx > 0) const SizedBox(width: 6),
                  if (rIdx * 4 + cIdx < floorRooms.length)
                    Expanded(
                      child: _buildInteractiveCard(
                        title: floorRooms[rIdx * 4 + cIdx],
                        sub: isApartment ? 'Flat' : 'Room',
                        isSelected:
                            _selectedRoom == floorRooms[rIdx * 4 + cIdx],
                        onTap: () => _selectRoom(floorRooms[rIdx * 4 + cIdx]),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],

        // 3. Space Selection for Apartment Flats (Hall, Bedroom, Master Bedroom)
        if (isApartment && _selectedRoom != null) ...[
          _buildDivider(),
          Builder(builder: (context) {
            final matchingRoom = _rooms
                .where((r) =>
                    r.roomNumber == _selectedRoom &&
                    (_selectedFloor == null || r.floorLabel == _selectedFloor))
                .firstOrNull;
            if (matchingRoom == null) return const SizedBox.shrink();

            final spaces = _getSpacesForFlat(matchingRoom);
            if (spaces.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel('Select Space in Flat'),
                    const Text(
                      'Tap space to choose',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (int rIdx = 0;
                    rIdx < (spaces.length / 2).ceil();
                    rIdx++) ...[
                  if (rIdx > 0) const SizedBox(height: 6),
                  Row(
                    children: [
                      for (int cIdx = 0; cIdx < 2; cIdx++) ...[
                        if (cIdx > 0) const SizedBox(width: 6),
                        if (rIdx * 2 + cIdx < spaces.length)
                          Expanded(
                            child: Builder(builder: (context) {
                              final sp = spaces[rIdx * 2 + cIdx];
                              final spaceBeds = matchingRoom.beds
                                  .where((b) =>
                                      _extractSpaceFromBed(b.bedLabel) == sp)
                                  .toList();
                              final vacantCount =
                                  spaceBeds.where((b) => b.isVacant).length;
                              final isSelected = _selectedSpace == sp;
                              return _buildInteractiveCard(
                                title: sp,
                                sub: '$vacantCount Vacant',
                                isSelected: isSelected,
                                onTap: () => _selectSpace(sp, matchingRoom),
                              );
                            }),
                          )
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    ],
                  ),
                ],
              ],
            );
          }),
        ],

        // 4. Dynamic Financials & Details (Auto-Locks to selected room or space)
        if (showFinancials) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          isApartment
                              ? 'Flat $_selectedRoom'
                              : 'Room $_selectedRoom',
                          style: AppTypography.bodySemiBold.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedSpace != null || _sharingType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedSpace ?? _sharingType!,
                              style: AppTypography.captionSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'Auto-Locked',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FloatingInput(
                        controller: _rentController,
                        label: 'Monthly Rent (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FloatingInput(
                        controller: _depositController,
                        label: 'Deposit (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // 5. Bed Allocation for Studio Room or Apartment Space
        if (_selectedRoom != null && (!isApartment || _selectedSpace != null)) ...[
          _buildDivider(),
          Builder(builder: (context) {
            final matchingRoom = _rooms
                .where((r) =>
                    r.roomNumber == _selectedRoom &&
                    (_selectedFloor == null || r.floorLabel == _selectedFloor))
                .firstOrNull;
            final beds = matchingRoom?.beds.where((b) {
                  if (isApartment && _selectedSpace != null) {
                    return _extractSpaceFromBed(b.bedLabel) == _selectedSpace;
                  }
                  return true;
                }).toList() ??
                [];
            if (beds.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(isApartment
                      ? 'Allocated Bed in $_selectedSpace (Optional)'
                      : 'Allocated Bed (Optional)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: beds.map((b) {
                      final isSelected =
                          _bedIdentifierController.text == b.bedLabel;
                      final isOccupied = b.isOccupied;
                      return ChoiceChip(
                        label: Text(
                          b.bedLabel + (isOccupied ? ' (Occupied)' : ''),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isOccupied
                                    ? AppColors.muted
                                    : AppColors.ink),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.green,
                        backgroundColor: const Color(0xFFF9FAFB),
                        disabledColor: const Color(0xFFF3F4F6),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.green
                              : const Color(0xFFE5E7EB),
                        ),
                        onSelected: isOccupied
                            ? null
                            : (selected) {
                                setState(() {
                                  _bedIdentifierController.text =
                                      selected ? b.bedLabel : '';
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          _FloatingInput(
            controller: _bedIdentifierController,
            label: isApartment
                ? 'Bed / Allocation in Flat (Optional)'
                : 'Bed / Allocation (Optional)',
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // STEP 4: INSTANT DIGITAL RESIDENT PASS (Lines 878-922 of HTML)
  // ===========================================================================
  Widget _buildStep4View() {
    final isApartment = _propertyStructure == 'Apartment Units';
    final finalRoom = _selectedRoom ?? '—';
    final sharingDisplay = _sharingType ?? '—';
    final floorDisplay = _selectedFloor != null
        ? (_selectedFloor!.toLowerCase().contains('floor')
            ? _selectedFloor!
            : '$_selectedFloor Floor')
        : '—';
    final bedDisplay = _bedIdentifierController.text.trim().isNotEmpty
        ? _bedIdentifierController.text.trim()
        : '—';
    final rentDisplay = _rentController.text.trim().isNotEmpty
        ? '₹${_rentController.text.trim()}/mo'
        : '—';
    final tenantNameDisplay = _tenantNameController.text.trim().isNotEmpty
        ? _tenantNameController.text.trim()
        : 'Resident';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('Welcome to Your Stay!',
            'Your resident profile is registered and ready.'),
        const SizedBox(height: 16),

        // Live Digital Stay Pass Card (Lines 886-921 of HTML)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pass Header Banner (pass-header)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Digital Resident Pass',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.green, width: 0.8),
                      ),
                      child: const Text(
                        'Active Resident',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Room & Sharing Row (pass-main-row)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isApartment ? 'Assigned Flat' : 'Assigned Room',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          finalRoom == '—'
                              ? '—'
                              : (finalRoom.startsWith('Room') ||
                                      finalRoom.startsWith('Flat')
                                  ? finalRoom
                                  : (isApartment
                                      ? 'Flat $finalRoom'
                                      : 'Room $finalRoom')),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isApartment ? 'Allocated Space' : 'Sharing Type',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sharingDisplay,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFF3F4F6), height: 1, thickness: 1),

              // Pass Info Grid (pass-info-grid: Floor, Bed, Monthly Rent, Resident Name)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    _buildPassInfoBox('Floor', floorDisplay),
                    _buildPassInfoBox(
                        isApartment ? 'Bed / Space' : 'Bed Identifier',
                        bedDisplay),
                    _buildPassInfoBox('Monthly Rent', rentDisplay),
                    _buildPassInfoBox('Resident Name', tenantNameDisplay),
                  ],
                ),
              ),

              // Reception Verification Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Verified at Reception Desk${_propertyName.isNotEmpty ? ' • $_propertyName' : (_pgCode.isNotEmpty ? ' • $_pgCode' : '')}',
                      style: AppTypography.captionSmall
                          .copyWith(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM STICKY ACTION BAR (Lines 925-929 & 1119-1155 of HTML)
  // ===========================================================================
  Widget _buildBottomBar() {
    final continueLabel = _currentStep == 4
        ? 'Go to Resident Hub'
        : _currentStep == 3
            ? 'Complete Check-In'
            : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.green.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      continueLabel,
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
          if (_currentStep < 4) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: TextButton(
                onPressed: _handleSkip,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F4F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save & Continue Later',
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // UI HELPER WIDGETS (From owner_setup_screen.dart)
  // ===========================================================================
  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading1.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            height: 1.15,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodyRegular.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: AppTypography.bodySemiBold.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildSubheadingWithBadge(String label, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0),
      child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    String? sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 50,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.green.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 1),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPillButton({
    required String title,
    required bool isAttached,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: isAttached
                ? AppColors.green.withValues(alpha: 0.08)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAttached ? AppColors.green : const Color(0xFFE5E7EB),
              width: isAttached ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAttached
                    ? Icons.check_circle_rounded
                    : Icons.file_upload_outlined,
                size: 16,
                color: isAttached ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  fontWeight: isAttached ? FontWeight.w700 : FontWeight.w600,
                  color: isAttached ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSingleButton({
    required String title,
    required IconData icon,
    required bool isAttached,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isAttached
                ? AppColors.green.withValues(alpha: 0.08)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAttached ? AppColors.green : const Color(0xFFE5E7EB),
              width: isAttached ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAttached ? Icons.check_circle_rounded : icon,
                size: 18,
                color: isAttached ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: isAttached ? FontWeight.w700 : FontWeight.w600,
                  color: isAttached ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SMART FLOATING LABEL INPUT (Exact 1-to-1 component from owner_setup_screen.dart)
// =============================================================================
class _FloatingInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _FloatingInput({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF),
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.green,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
