import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen 14: Tenant Digital Check-In Wizard.
/// 100% exact translation of `ProductionCode/tenant_checkin.html`
/// using the verified UI components from `owner_setup_screen.dart`:
/// - Animated `_FloatingInput` (labels float up in emerald green on tap).
/// - Tactile `_buildInteractiveCard` with zero pre-selection.
/// - Exact room generation logic from JavaScript (Ground G-01..G-04, 1st 101..104, etc. + Custom).
/// - Strict input validations matching `handleContinue()` in `tenant_checkin.html`.
class TenantCheckinScreen extends StatefulWidget {
  final String? initialPgCode;
  final String? initialPhoneOrEmail;
  final String? initialName;

  const TenantCheckinScreen({
    super.key,
    this.initialPgCode,
    this.initialPhoneOrEmail,
    this.initialName,
  });

  @override
  State<TenantCheckinScreen> createState() => _TenantCheckinScreenState();
}

class _TenantCheckinScreenState extends State<TenantCheckinScreen> {
  int _currentStep = 1; // 1 = Details, 2 = Work/Study, 3 = Room/Stay, 4 = Digital Pass

  // --- Step 1 Controllers & State ---
  late String _pgCode;
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
  final TextEditingController _tenantAadhaarController = TextEditingController();

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
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  String? _selectedFloor; // Ground, 1st, 2nd, 3rd, 4th, 5+
  String? _selectedRoom; // e.g. "101", "102"
  final TextEditingController _bedIdentifierController = TextEditingController();

  // Exact room lists per floor from tenant_checkin.html lines 970-983
  List<String> _getRoomsForFloor(String floor) {
    if (floor == 'Ground') return ['G-01', 'G-02', 'G-03', 'G-04'];
    if (floor == '1st') return ['101', '102', '103', '104'];
    if (floor == '2nd') return ['201', '202', '203', '204'];
    if (floor == '3rd') return ['301', '302', '303', '304'];
    if (floor == '4th') return ['401', '402', '403', '404'];
    if (floor == '5+') return ['501', '502', '503', '504'];
    return [];
  }

  void _selectSharing(String type, {required String defaultRent, required String defaultDeposit}) {
    setState(() {
      _sharingType = type;
      if (_rentController.text.trim().isEmpty) {
        _rentController.text = defaultRent;
      }
      if (_depositController.text.trim().isEmpty) {
        _depositController.text = defaultDeposit;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pgCode = widget.initialPgCode?.trim().toUpperCase() ?? 'AR-101';
    if (_pgCode.isEmpty) _pgCode = 'AR-101';

    _tenantNameController = TextEditingController(text: widget.initialName ?? '');

    final phone = widget.initialPhoneOrEmail != null && !widget.initialPhoneOrEmail!.contains('@')
        ? widget.initialPhoneOrEmail!
        : '';
    final email = widget.initialPhoneOrEmail != null && widget.initialPhoneOrEmail!.contains('@')
        ? widget.initialPhoneOrEmail!
        : '';

    _tenantPhoneController = TextEditingController(text: phone);
    _tenantEmailController = TextEditingController(text: email);

    // Default move-in date to today (matching line 939 of tenant_checkin.html)
    final now = DateTime.now();
    _moveInDate = now;
    _moveInDateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
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
  void _handleContinue() {
    if (_currentStep == 1) {
      final name = _tenantNameController.text.trim();
      final phone = _tenantPhoneController.text.trim();
      final aadhaarDigits = _tenantAadhaarController.text.replaceAll(RegExp(r'\s'), '');

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
      if (_sharingType == null) {
        _showError('Please select your Sharing Type.');
        return;
      }
      if (_rentController.text.trim().isEmpty) {
        _showError('Please enter your Monthly Rent (₹).');
        return;
      }
      if (_selectedFloor == null) {
        _showError('Please select which floor your room is on.');
        return;
      }
      if (_selectedRoom == null || _selectedRoom!.isEmpty) {
        _showError('Please select your Room Number.');
        return;
      }

      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to your stay hub!'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
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
    final limited = digitsOnly.length > 12 ? digitsOnly.substring(0, 12) : digitsOnly;
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
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
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
        _moveInDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
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
        _buildHeader('User Details', 'Enter your details to register with your PG property.'),
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
                onTap: () => setState(() => _aadhaarFrontDone = !_aadhaarFrontDone),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildUploadPillButton(
                title: _aadhaarBackDone ? '✓ Attached' : 'Back Photo',
                isAttached: _aadhaarBackDone,
                onTap: () => setState(() => _aadhaarBackDone = !_aadhaarBackDone),
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
        _buildHeader('Work & Study', 'Tell us about your current occupation or college.'),
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
    final floorRooms = _selectedFloor != null ? _getRoomsForFloor(_selectedFloor!) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('Room & Stay Details', 'Select your sharing type, floor, and pick your allocated room number.'),
        const SizedBox(height: 16),

        // 1. Sharing Selection (6 cards: 2 rows of 3)
        _buildSectionLabel('Sharing Type'),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: '1-Share',
                sub: 'Single Room',
                isSelected: _sharingType == '1-Share',
                onTap: () => _selectSharing('1-Share', defaultRent: '12000', defaultDeposit: '24000'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '2-Share',
                sub: 'Double Bed',
                isSelected: _sharingType == '2-Share',
                onTap: () => _selectSharing('2-Share', defaultRent: '8500', defaultDeposit: '17000'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '3-Share',
                sub: 'Triple Bed',
                isSelected: _sharingType == '3-Share',
                onTap: () => _selectSharing('3-Share', defaultRent: '6500', defaultDeposit: '13000'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: '4-Share',
                sub: '4 Beds',
                isSelected: _sharingType == '4-Share',
                onTap: () => _selectSharing('4-Share', defaultRent: '5500', defaultDeposit: '11000'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '5-Share',
                sub: '5 Beds',
                isSelected: _sharingType == '5-Share',
                onTap: () => _selectSharing('5-Share', defaultRent: '4800', defaultDeposit: '9600'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '6-Share',
                sub: '6 Beds',
                isSelected: _sharingType == '6-Share',
                onTap: () => _selectSharing('6-Share', defaultRent: '4200', defaultDeposit: '8400'),
              ),
            ),
          ],
        ),

        // Dynamic Monthly Rent & Deposit Card (Pops up when sharing is selected, matching owner setup UI)
        if (_sharingType != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
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
                    Text(
                      '$_sharingType Bed',
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Per Bed',
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FloatingInput(
                        controller: _rentController,
                        label: 'Monthly Rent (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FloatingInput(
                        controller: _depositController,
                        label: 'Deposit (₹)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        _buildDivider(),

        // 2. Floor Selection (6 cards: 2 rows of 3)
        _buildSectionLabel('Which Floor is your Room on?'),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: 'Ground',
                sub: 'Floor',
                isSelected: _selectedFloor == 'Ground',
                onTap: () => setState(() {
                  _selectedFloor = 'Ground';
                  _selectedRoom = null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '1st',
                sub: 'Floor',
                isSelected: _selectedFloor == '1st',
                onTap: () => setState(() {
                  _selectedFloor = '1st';
                  _selectedRoom = null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '2nd',
                sub: 'Floor',
                isSelected: _selectedFloor == '2nd',
                onTap: () => setState(() {
                  _selectedFloor = '2nd';
                  _selectedRoom = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveCard(
                title: '3rd',
                sub: 'Floor',
                isSelected: _selectedFloor == '3rd',
                onTap: () => setState(() {
                  _selectedFloor = '3rd';
                  _selectedRoom = null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '4th',
                sub: 'Floor',
                isSelected: _selectedFloor == '4th',
                onTap: () => setState(() {
                  _selectedFloor = '4th';
                  _selectedRoom = null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildInteractiveCard(
                title: '5+',
                sub: 'Floor',
                isSelected: _selectedFloor == '5+',
                onTap: () => setState(() {
                  _selectedFloor = '5+';
                  _selectedRoom = null;
                }),
              ),
            ),
          ],
        ),
        _buildDivider(),

        // 3. Dynamic Floor-Wise Room Selector (Clean 4-column row, zero + Custom button)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Select Room Number'),
            const Text(
              'Click room to select',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.muted),
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
            child: const Center(
              child: Text(
                'Select a floor above to view available rooms.',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.muted),
              ),
            ),
          )
        else
          Row(
            children: [
              for (int i = 0; i < floorRooms.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _buildInteractiveCard(
                    title: floorRooms[i],
                    sub: 'Room',
                    isSelected: _selectedRoom == floorRooms[i],
                    onTap: () => setState(() => _selectedRoom = floorRooms[i]),
                  ),
                ),
              ],
            ],
          ),

        _buildDivider(),

        // 4. Bed / Identifier Input (Optional)
        _FloatingInput(
          controller: _bedIdentifierController,
          label: 'Bed / Allocation (e.g. Bed A, Bed B, or Window Bed)',
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4: INSTANT DIGITAL RESIDENT PASS (Lines 878-922 of HTML)
  // ===========================================================================
  Widget _buildStep4View() {
    final finalRoom = _selectedRoom ?? '102';
    final sharingDisplay = _sharingType ?? '2-Share';
    final floorDisplay = _selectedFloor != null ? '$_selectedFloor Floor' : '1st Floor';
    final bedDisplay = _bedIdentifierController.text.trim().isNotEmpty ? _bedIdentifierController.text.trim() : 'Bed A';
    final rentDisplay = _rentController.text.trim().isNotEmpty ? '₹${_rentController.text.trim()}/mo' : '₹8,500/mo';
    final tenantNameDisplay = _tenantNameController.text.trim().isNotEmpty ? _tenantNameController.text.trim() : 'Resident';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('Welcome to Your Stay!', 'Your resident profile is registered and ready.'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        const Text(
                          'Assigned Room',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          finalRoom.startsWith('Room') ? finalRoom : 'Room $finalRoom',
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
                        const Text(
                          'Sharing Type',
                          style: TextStyle(
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
                    _buildPassInfoBox('Bed Identifier', bedDisplay),
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
                    const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Verified at PG Reception Desk • $_pgCode',
                      style: AppTypography.captionSmall.copyWith(fontSize: 11, color: AppColors.muted),
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
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppColors.green.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
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
            color: isAttached ? AppColors.green.withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
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
                isAttached ? Icons.check_circle_rounded : Icons.file_upload_outlined,
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
            color: isAttached ? AppColors.green.withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
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
