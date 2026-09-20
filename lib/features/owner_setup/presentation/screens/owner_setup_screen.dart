import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../owner_dashboard/presentation/screens/owner_dashboard_screen.dart';

/// Screen 4: 4-Step PG Owner Onboarding & Property Setup Wizard.
/// 1-to-1 exact translation of `ProductionCode/owner_setup.html`.
/// Features:
/// 1. Top Navigation with Back Button & 4-Segment Progress Bar.
/// 2. Clean Floating Label Input Fields (Google Outfit font, green floating label, zero cursor collision).
/// 3. Step 1: Owner Details (Legal Name, Father Name, WhatsApp, Email, Aadhaar, Photo Uploads).
/// 4. Step 2: Property Details (Brand Name, Gender Grid, Structure, Ownership, Address, Lift, Backup).
/// 5. Step 3: Rooms, Dynamic Rent & Collection Rules (Ground floor toggle, Dynamic Floor pills, Sharing pills, Dynamic rent/deposit cards, Due day, Grace, Late fee, Notice period).
/// 6. Step 4: Bank & Payout Account (Trust Card, Account Holder, Bank Name, UPI ID, Phone, QR Upload).
/// 7. Post-Setup Celebration Modal: Frosted Glass Blur Backdrop, Unique Property Code Generator (e.g. US-MARU-8849), 1-Tap Copy, WhatsApp Tenant Invite Share, and Command Center Launch.
class OwnerSetupScreen extends StatefulWidget {
  final bool isScaleMode;
  final int initialStep;
  final VoidCallback? onBack;
  final Function(int newTotalBeds, int newTotalRooms, int newFloors)? onCapacityUpdated;

  const OwnerSetupScreen({
    super.key,
    this.isScaleMode = false,
    this.initialStep = 1,
    this.onBack,
    this.onCapacityUpdated,
  });

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _addressController = TextEditingController();
  bool _frontPhotoAttached = false;
  bool _backPhotoAttached = false;

  // Custom Floor State
  bool _showCustomFloor = false;
  final _customFloorController = TextEditingController();
  final Map<String, List<String>> _sharingAssignedRooms = {};

  // Step 2 Controllers & State (Zero pre-selected defaults)
  final _pgBrandNameController = TextEditingController();
  String? _genderCategory;
  String? _propertyStructure;
  String? _ownershipType;
  final _streetAddressController = TextEditingController();
  final _areaLocalityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityStateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  bool _pincodeResolved = false;
  String? _liftCount;
  String? _powerBackup;

  // Step 3 Controllers & State (Zero pre-selected defaults)
  bool? _groundFloorHasRooms;
  final _gfRoomsCountController = TextEditingController();
  String? _floorCount;
  final _roomsEachFloorController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final Map<String, TextEditingController> _floorRoomsControllers = {};
  String? _namingFormat;

  // Apartment Units Flat Mapping & Occupancy State
  final Map<String, List<String>> _bhkAssignedFlats = {
    '1 BHK': [],
    '2 BHK': [],
    '3 BHK': [],
  };
  String _selectedBhkTab = '1 BHK';
  final Map<String, Map<String, int>> _bhkOccupancy = {
    '1 BHK': {
      'Hall (3-Sharing)': 0,
      'Bedroom (2-Sharing)': 0,
      'Master Room': 0,
    },
    '2 BHK': {
      'Hall (3-Sharing)': 0,
      'Bedroom (2-Sharing)': 0,
      'Master Room': 0,
    },
    '3 BHK': {
      'Hall (3-Sharing)': 0,
      'Bedroom (2-Sharing)': 0,
      'Master Room': 0,
    },
  };
  bool _showAddCustomBhk = false;
  final _customBhkController = TextEditingController();

  final List<String> _selectedSharings = [];
  final Map<String, TextEditingController> _rentControllers = {};
  final Map<String, TextEditingController> _depositControllers = {};
  bool _showCustomSharingInput = false;
  final _customSharingController = TextEditingController();

  String? _dueDay;
  bool _showCustomDueDay = false;
  final _customDueDayController = TextEditingController();

  String? _gracePeriod;
  String? _lateFee;
  bool _showCustomLateFee = false;
  final _customLateFeeController = TextEditingController();

  String? _noticePeriod;

  // Step 4 Controllers & State
  final _bankHolderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _creditingPhoneController = TextEditingController();
  bool _qrAttached = false;

  // Post-Setup Welcome & Celebration Modal State
  bool _showCelebrationModal = false;
  String _generatedPropertyCode = '';
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    if (widget.isScaleMode) {
      _currentStep = 3;
      _groundFloorHasRooms = true;
      _gfRoomsCountController.text = '2';
      _floorCount = '4';
      _roomsEachFloorController.text = '4';
      _propertyStructure = 'Standard PG';
      _selectedSharings.addAll(['1-Share', '2-Share', '3-Share']);
      for (final sh in ['1-Share', '2-Share', '3-Share']) {
        _sharingAssignedRooms.putIfAbsent(sh, () => []);
        _rentControllers.putIfAbsent(sh, () => TextEditingController(text: sh.startsWith('1') ? '12000' : (sh.startsWith('2') ? '8500' : '7000')));
        _depositControllers.putIfAbsent(sh, () => TextEditingController(text: sh.startsWith('1') ? '20000' : (sh.startsWith('2') ? '15000' : '12000')));
      }
    } else {
      _currentStep = widget.initialStep;
    }

    _pincodeController.addListener(() {
      final code = _pincodeController.text.trim();
      setState(() {
        _pincodeResolved = code.length == 6;
      });
    });
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _fatherNameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _aadhaarController.dispose();
    _addressController.dispose();

    _pgBrandNameController.dispose();
    _streetAddressController.dispose();
    _areaLocalityController.dispose();
    _landmarkController.dispose();
    _cityStateController.dispose();
    _pincodeController.dispose();
    _mapsUrlController.dispose();

    _gfRoomsCountController.dispose();
    _roomsEachFloorController.dispose();
    _totalRoomsController.dispose();
    _customBhkController.dispose();
    _customSharingController.dispose();
    _customDueDayController.dispose();
    _customLateFeeController.dispose();

    _bankHolderNameController.dispose();
    _bankNameController.dispose();
    _upiIdController.dispose();
    _creditingPhoneController.dispose();

    for (var c in _floorRoomsControllers.values) {
      c.dispose();
    }
    for (var c in _rentControllers.values) {
      c.dispose();
    }
    for (var c in _depositControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _getFloorNames() {
    final hasGround = _groundFloorHasRooms == true;
    int upperCount = 0;

    if (_floorCount != null) {
      final customDigits = RegExp(r'\d+').firstMatch(_floorCount!);
      if (customDigits != null) {
        upperCount = int.tryParse(customDigits.group(0)!) ?? 0;
      }
      if (_floorCount!.contains('1st') || _floorCount!.startsWith('1 ')) {
        upperCount = 1;
      }
    }

    final List<String> floors = [];
    if (hasGround) {
      floors.add('Ground Floor');
    }
    for (int i = 1; i <= upperCount; i++) {
      if (i == 1) {
        floors.add('1st Floor');
      } else if (i == 2) {
        floors.add('2nd Floor');
      } else if (i == 3) {
        floors.add('3rd Floor');
      } else {
        floors.add('${i}th Floor');
      }
    }
    return floors;
  }

  int _calculateTotalRooms() {
    final floors = _getFloorNames();
    int sum = 0;
    for (final f in floors) {
      final text = _floorRoomsControllers[f]?.text.trim() ?? '';
      sum += int.tryParse(text) ?? 0;
    }
    return sum;
  }

  String _getBreakdownText() {
    final floors = _getFloorNames();
    final parts = <String>[];
    for (final f in floors) {
      final val =
          int.tryParse(_floorRoomsControllers[f]?.text.trim() ?? '') ?? 0;
      parts.add('$val');
    }
    final total = _calculateTotalRooms();
    if (parts.isEmpty) return '0 Rooms';
    return '${parts.join(' + ')} = $total Rooms';
  }

  Map<String, List<String>> _getFlatsPerFloor() {
    final Map<String, List<String>> result = {};
    final floors = _getFloorNames();
    final isAlpha = _namingFormat == 'A-1, A-2, B-1...';

    for (int fIndex = 0; fIndex < floors.length; fIndex++) {
      final floorName = floors[fIndex];
      final count =
          int.tryParse(_floorRoomsControllers[floorName]?.text.trim() ?? '') ??
              0;
      final List<String> flats = [];

      for (int r = 1; r <= count; r++) {
        if (isAlpha) {
          final letter = String.fromCharCode(65 + fIndex);
          flats.add('$letter-$r');
        } else {
          if (floorName == 'Ground Floor') {
            flats.add('G-${r.toString().padLeft(2, '0')}');
          } else {
            final floorNumMatch = RegExp(r'\d+').firstMatch(floorName);
            final floorNum = floorNumMatch != null
                ? int.parse(floorNumMatch.group(0)!)
                : (fIndex + 1);
            flats.add('${floorNum}${r.toString().padLeft(2, '0')}');
          }
        }
      }
      result[floorName] = flats;
    }
    return result;
  }

  Widget _buildOccupancyRow({
    required String title,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    bool isMaster = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (isMaster) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Higher Rent',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Max $count People',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.remove, size: 15, color: AppColors.ink),
              ),
            ),
            SizedBox(
              width: 34,
              child: Center(
                child: Text(
                  '$count',
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.green),
                ),
                child: const Icon(Icons.add, size: 15, color: AppColors.green),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleBack() {
    if (_showCelebrationModal) {
      setState(() => _showCelebrationModal = false);
      return;
    }
    if (widget.isScaleMode) {
      if (_currentStep == 2) {
        setState(() => _currentStep = 3);
        return;
      }
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleContinue() {
    if (widget.isScaleMode && _currentStep == 3) {
      final calcRooms = _calculateTotalRooms();
      int calcBeds = 0;
      if (_propertyStructure == 'Apartment Units') {
        _bhkAssignedFlats.forEach((bhk, flats) {
          final occ = _bhkOccupancy[bhk] ?? {};
          final bedsInFlat = ((occ['Hall (3-Sharing)'] ?? 0) * 3) +
              ((occ['Bedroom (2-Sharing)'] ?? 0) * 2) +
              ((occ['Master Room'] ?? 0) * 1);
          calcBeds += (bedsInFlat * flats.length);
        });
        if (calcBeds == 0) calcBeds = calcRooms * 2;
      } else {
        _sharingAssignedRooms.forEach((sharing, rooms) {
          int mult = 2;
          if (sharing.startsWith('1')) mult = 1;
          else if (sharing.startsWith('2')) mult = 2;
          else if (sharing.startsWith('3')) mult = 3;
          else if (sharing.startsWith('4')) mult = 4;
          else if (sharing.startsWith('5')) mult = 5;
          else if (sharing.startsWith('6')) mult = 6;
          calcBeds += (rooms.length * mult);
        });
        if (calcBeds == 0) calcBeds = calcRooms * 2;
      }

      if (widget.onCapacityUpdated != null) {
        widget.onCapacityUpdated!(
          calcBeds,
          calcRooms,
          int.tryParse(_floorCount ?? '4') ?? 4,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Building capacity updated successfully to $calcBeds Beds ($calcRooms Rooms)!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop();
      return;
    }

    if (_currentStep == 1) {
      if (_legalNameController.text.trim().isEmpty) {
        _showSnackBar('Please enter your full legal name.');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_pgBrandNameController.text.trim().isEmpty) {
        _showSnackBar('Please enter your PG / Property name.');
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      if (_bankHolderNameController.text.trim().isEmpty ||
          _upiIdController.text.trim().isEmpty) {
        _showSnackBar('Please enter your Bank Account Name and UPI ID.');
        return;
      }
      _triggerCelebrationLaunch();
    }
  }

  void _handleSkip() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _triggerCelebrationLaunch();
    }
  }

  void _triggerCelebrationLaunch() {
    // Generate human-readable property code e.g. US-MARU-8849
    final brand = _pgBrandNameController.text
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toUpperCase();
    final prefix = brand.length >= 4
        ? brand.substring(0, 4)
        : (brand.isNotEmpty ? brand : 'MARU');
    final randomSuffix =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

    setState(() {
      _generatedPropertyCode = 'US-$prefix-$randomSuffix';
      _showCelebrationModal = true;
    });
  }

  void _copyPropertyCode() {
    Clipboard.setData(ClipboardData(text: _generatedPropertyCode));
    setState(() => _codeCopied = true);
    _showSnackBar('🔑 Property Code copied: $_generatedPropertyCode');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _shareOnWhatsApp() {
    final pgName = _pgBrandNameController.text.trim().isNotEmpty
        ? _pgBrandNameController.text.trim()
        : 'Our PG';
    final ownerName = _legalNameController.text.trim().isNotEmpty
        ? _legalNameController.text.trim()
        : 'Owner';

    final inviteMessage = '🏠 *$pgName is now digital on UrbanStay!*\n\n'
        'Dear Residents,\n'
        'Please use our official Property Code to complete your 1-minute digital check-in and get your 0% UPI rent receipts:\n\n'
        '🔑 *Property Code:* `$_generatedPropertyCode`\n'
        '📲 *Digital Check-in:* https://urbanstay.living/join/$_generatedPropertyCode\n\n'
        '— Managed digitally by $ownerName via UrbanStay';

    Clipboard.setData(ClipboardData(text: inviteMessage));
    _showSnackBar(
        '💬 WhatsApp invite message copied to clipboard! Ready to share.');
  }

  void _launchDashboard() {
    setState(() => _showCelebrationModal = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OwnerDashboardScreen(),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Navigation & Segmented Progress Track
                _buildTopNav(),

                // Scrollable Step Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.responsiveHorizontalPadding,
                      4.0,
                      context.responsiveHorizontalPadding,
                      20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentStep == 1) _buildStep1(),
                        if (_currentStep == 2) _buildStep2(),
                        if (_currentStep == 3) _buildStep3(),
                        if (_currentStep == 4) _buildStep4(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Post-Setup Frosted Glass Celebration Modal
            if (_showCelebrationModal) _buildCelebrationModal(),
          ],
        ),
      ),
    );
  }

  /// Post-Setup Welcome & Celebration Modal with Frosted Glass Blur
  Widget _buildCelebrationModal() {
    final pgName = _pgBrandNameController.text.trim().isNotEmpty
        ? _pgBrandNameController.text.trim()
        : 'Shree Maruthi Luxury PG';
    final ownerName = _legalNameController.text.trim().isNotEmpty
        ? _legalNameController.text.trim()
        : 'Owner';
    final location = _areaLocalityController.text.trim().isNotEmpty
        ? _areaLocalityController.text.trim()
        : 'Bengaluru';

    return Positioned.fill(
      child: Stack(
        children: [
          // Frosted Glass Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),

          // Centered Celebration Pass Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Verified Vector Shield Badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_rounded,
                          size: 32,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Your PG is Officially Live',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading1.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Congratulations, $ownerName! Your property is registered and ready for operations.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyRegular.copyWith(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Property Pass Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 18,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pgName,
                                  style: AppTypography.bodySemiBold.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$location • 0% Direct Bank Settlement',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Color(0xFFE5E7EB), height: 1),
                          ),

                          Text(
                            'OFFICIAL PROPERTY CODE',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Property Code Display with 1-Tap Copy
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.green
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _generatedPropertyCode,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _copyPropertyCode,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: _codeCopied
                                        ? AppColors.greenLight
                                        : const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _codeCopied
                                            ? Icons.check_rounded
                                            : Icons.copy_rounded,
                                        size: 15,
                                        color: _codeCopied
                                            ? AppColors.green
                                            : AppColors.ink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _codeCopied ? 'Copied' : 'Copy',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _codeCopied
                                              ? AppColors.green
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // WhatsApp Share Invite Button
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _shareOnWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_rounded,
                                size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Share Tenant Invite on WhatsApp',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Open Dashboard CTA (White Background with Deep Black Text)
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _launchDashboard,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                              color: AppColors.ink, width: 1.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Enter Command Center',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: AppColors.ink),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Navigation Bar with Step Number and 4 Segmented Progress Capsules
  Widget _buildTopNav() {
    if (widget.isScaleMode) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          16.0,
          context.responsiveHorizontalPadding,
          14.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _handleBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.ink,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
            Row(
              children: [
                if (_currentStep == 3)
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Structure: ${_propertyStructure ?? "PG"}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upgrade_rounded, size: 14, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Scale Capacity Mode',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        16.0,
        context.responsiveHorizontalPadding,
        14.0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _handleBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.ink,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
              Text(
                'Step $_currentStep of 4',
                style: AppTypography.bodySemiBold.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 4-Segment Progress Bar
          Row(
            children: List.generate(4, (index) {
              final isActive = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 3.5,
                  margin: EdgeInsets.only(
                    right: index < 3 ? 6.0 : 0.0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.green : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Step 1: Owner Details (Identity & KYC)
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          'Owner Details',
          'This will be used to generate your official tenant agreements and police records.',
        ),
        const SizedBox(height: 18),

        _FloatingInput(
          controller: _legalNameController,
          label: 'Full Legal Name (as per Aadhaar)',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _fatherNameController,
          label: 'Father / Husband Name',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // WhatsApp Phone with Country Pill
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                controller: _whatsappController,
                label: 'WhatsApp Mobile Number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _emailController,
          label: 'Email Address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        _FloatingInput(
          controller: _aadhaarController,
          label: '12-digit Aadhaar Number',
          keyboardType: TextInputType.number,
          maxLength: 14,
          onChanged: (val) {
            final digits = val.replaceAll(RegExp(r'\D'), '');
            if (digits.length <= 12) {
              final formatted = digits
                  .replaceAllMapped(
                    RegExp(r'.{1,4}'),
                    (m) => '${m.group(0)} ',
                  )
                  .trim();
              if (formatted != val) {
                _aadhaarController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            }
          },
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _addressController,
          label: 'Permanent Home Address',
          keyboardType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 14),

        // Aadhaar Photo Upload Row
        Text(
          'Aadhaar Card Photo',
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _UploadPill(
                isDone: _frontPhotoAttached,
                label: _frontPhotoAttached ? '✓ Attached' : 'Front Photo',
                onTap: () =>
                    setState(() => _frontPhotoAttached = !_frontPhotoAttached),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UploadPill(
                isDone: _backPhotoAttached,
                label: _backPhotoAttached ? '✓ Attached' : 'Back Photo',
                onTap: () =>
                    setState(() => _backPhotoAttached = !_backPhotoAttached),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 2: Property Details (Profile & Address)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          'Property Details',
          'Configure your building type and address for automatic tenant room mapping.',
        ),
        const SizedBox(height: 18),

        _FloatingInput(
          controller: _pgBrandNameController,
          label: 'PG / Property Name (e.g. Green Nest Luxury)',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Gender Category (Zero Pre-selected)
        _buildSectionLabel('Gender Category'),
        Row(
          children: [
            _buildInteractiveCard(
              title: 'Gents',
              sub: 'Male Only',
              isSelected: _genderCategory == 'Gents',
              onTap: () => setState(() => _genderCategory = 'Gents'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'Ladies',
              sub: 'Female Only',
              isSelected: _genderCategory == 'Ladies',
              onTap: () => setState(() => _genderCategory = 'Ladies'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'Co-Living',
              sub: 'Unisex / All',
              isSelected: _genderCategory == 'Co-Living',
              onTap: () => setState(() => _genderCategory = 'Co-Living'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Property Structure (Zero Pre-selected)
        _buildSectionLabel('Property Structure'),
        Row(
          children: [
            _buildInteractiveCard(
              title: 'Standard PG',
              sub: 'Rooms & Beds',
              isSelected: _propertyStructure == 'Standard PG',
              onTap: () => setState(() => _propertyStructure = 'Standard PG'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'Apartment Units',
              sub: '1BHK / 2BHK / 3BHK',
              isSelected: _propertyStructure == 'Apartment Units',
              onTap: () =>
                  setState(() => _propertyStructure = 'Apartment Units'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Ownership Type (Zero Pre-selected)
        _buildSectionLabel('Ownership Type'),
        Row(
          children: [
            _buildInteractiveCard(
              title: 'Owned Building',
              sub: 'Sole Owner',
              isSelected: _ownershipType == 'Owned Building',
              onTap: () => setState(() => _ownershipType = 'Owned Building'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'Leased Property',
              sub: 'On Lease',
              isSelected: _ownershipType == 'Leased Property',
              onTap: () => setState(() => _ownershipType = 'Leased Property'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // PG Address with Pincode badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PG Address',
              style: AppTypography.heading3.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (_pincodeResolved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '✓ Bengaluru Verified',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _streetAddressController,
          label: 'Street Address (Door No, Cross, Main Road)',
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _areaLocalityController,
          label: 'Area / Locality (e.g. Koramangala 5th Block)',
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _landmarkController,
          label: 'Nearest Landmark (e.g. Near Sony World Signal)',
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _cityStateController,
          label: 'City & State',
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _pincodeController,
          label: '6-Digit Pincode (e.g. 560034)',
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _mapsUrlController,
          label: 'Google Maps Link / GPS Pin (Optional)',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Elevator / Lift (Zero Pre-selected)
        _buildSectionLabel('Elevator / Lift'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '0',
              sub: 'No Lift',
              isSelected: _liftCount == '0',
              onTap: () => setState(() => _liftCount = '0'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '1',
              sub: 'Lift',
              isSelected: _liftCount == '1',
              onTap: () => setState(() => _liftCount = '1'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '2',
              sub: 'Lifts',
              isSelected: _liftCount == '2',
              onTap: () => setState(() => _liftCount = '2'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '3+',
              sub: 'Lifts',
              isSelected: _liftCount == '3+',
              onTap: () => setState(() => _liftCount = '3+'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Power Backup (Zero Pre-selected)
        _buildSectionLabel('Power Backup Facility'),
        Row(
          children: [
            _buildInteractiveCard(
              title: 'Full Backup',
              sub: 'Generator / Inverter',
              isSelected: _powerBackup == 'Full Backup',
              onTap: () => setState(() => _powerBackup = 'Full Backup'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'No Backup',
              sub: 'Standard Line',
              isSelected: _powerBackup == 'No Backup',
              onTap: () => setState(() => _powerBackup = 'No Backup'),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 3: Rooms, Dynamic Rent & Collection Rules
  Widget _buildStep3() {
    final isGroundNo = _groundFloorHasRooms == false;

    // Floor options mapped 1-to-1 from owner_setup.html
    final floorOptions = isGroundNo
        ? [
            {'title': '1st Floor', 'sub': '1 Floor'},
            {'title': '2 Floors', 'sub': '2 Floors'},
            {'title': '3 Floors', 'sub': '3 Floors'},
            {'title': '4 Floors', 'sub': '4 Floors'},
            {'title': '5+ Floors', 'sub': '5+ Floors'},
          ]
        : [
            {'title': 'G + 1', 'sub': '2 Floors'},
            {'title': 'G + 2', 'sub': '3 Floors'},
            {'title': 'G + 3', 'sub': '4 Floors'},
            {'title': 'G + 4', 'sub': '5 Floors'},
            {'title': 'G + 5+', 'sub': '6+ Floors'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          'Rooms & Rent Rules',
          'Configure your room inventory, rent matrix, and automated collection rules.',
        ),
        const SizedBox(height: 18),

        // 1. Ground floor rooms question
        _buildSectionLabel('Does your Ground Floor have rooms for rent?'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInteractiveCard(
              title: 'Yes',
              sub: 'Has Rent Rooms',
              isSelected: _groundFloorHasRooms == true,
              onTap: () => setState(() {
                _groundFloorHasRooms = true;
              }),
            ),
            const SizedBox(width: 8),
            _buildInteractiveCard(
              title: 'No',
              sub: 'Parking / Reception',
              isSelected: _groundFloorHasRooms == false,
              onTap: () => setState(() {
                _groundFloorHasRooms = false;
              }),
            ),
          ],
        ),

        const SizedBox(height: 14),
        _buildDivider(),
        const SizedBox(height: 14),

        // 2. Floor Count Selector (Dynamic based on Ground Floor answer)
        _buildSectionLabel(
          isGroundNo
              ? 'Upper Floors Count (Excluding Ground Floor)'
              : 'Building Floor Count (Including Ground Floor)',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...floorOptions.take(3).map((opt) {
              final isSelected = _floorCount == opt['title'] && !_showCustomFloor;
              return _buildInteractiveCard(
                title: opt['title']!,
                sub: opt['sub']!,
                isSelected: isSelected,
                onTap: () => setState(() {
                  _floorCount = opt['title']!;
                  _showCustomFloor = false;
                }),
              );
            }).expand((w) => [w, const SizedBox(width: 6)]).toList(),
            _buildCustomFloorCard(isSelected: _showCustomFloor),
          ],
        ),

        const SizedBox(height: 14),
        _buildDivider(),
        const SizedBox(height: 14),

        // 3. Rooms on Each Floor (For all property structures)
        _buildSectionLabel(
          _propertyStructure == 'Apartment Units'
              ? 'Flats on Each Floor'
              : 'Rooms on Each Floor',
        ),
        const SizedBox(height: 8),
        if (_getFloorNames().isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(
                'Select building floor count above to configure rooms on each floor.',
                style: AppTypography.bodyRegular.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: _getFloorNames().asMap().entries.map((entry) {
                final idx = entry.key;
                final floorName = entry.value;
                final floorsList = _getFloorNames();
                final ctrl = _floorRoomsControllers.putIfAbsent(
                  floorName,
                  () => TextEditingController(),
                );
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: idx < floorsList.length - 1
                        ? const Border(
                            bottom: BorderSide(color: Color(0xFFF0F0F0)))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        floorName,
                        style: AppTypography.bodySemiBold.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 38,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySemiBold.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: AppColors.muted.withValues(alpha: 0.4),
                                  fontSize: 13,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.green, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _propertyStructure == 'Apartment Units'
                                ? 'Flats'
                                : 'Rooms',
                            style: AppTypography.bodyRegular.copyWith(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ${_propertyStructure == "Apartment Units" ? "Flats" : "Rooms"}: ${_calculateTotalRooms()}',
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getBreakdownText(),
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _buildDivider(),
        const SizedBox(height: 14),

        // 4. Room Numbering Format
        _buildSectionLabel('Room Numbering Format'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '101, 102, 201...',
              sub: 'Floor-Wise Numeric',
              isSelected: _namingFormat == '101, 102, 201...',
              onTap: () => setState(() => _namingFormat = '101, 102, 201...'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: 'A-1, A-2, B-1...',
              sub: 'Block-Wise Alphabetical',
              isSelected: _namingFormat == 'A-1, A-2, B-1...',
              onTap: () => setState(() => _namingFormat = 'A-1, A-2, B-1...'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // 5. Flat Mapping & Occupancy for Apartment Units OR Sharing Pills for Standard PG
        if (_propertyStructure == 'Apartment Units') ...[
          _buildSectionLabel('1. Assign Flats by Type'),
          Text(
            'Tap the flats on each floor that belong to each category.',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          ..._bhkAssignedFlats.keys.map((bhk) {
            final flatsPerFloor = _getFlatsPerFloor();
            final count = _bhkAssignedFlats[bhk]?.length ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        '$bhk Flats',
                        style: AppTypography.bodySemiBold.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count Flats',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...flatsPerFloor.entries.map((floorEntry) {
                    final floorName = floorEntry.key;
                    final flats = floorEntry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            floorName,
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: flats.map((flat) {
                              final isThisSelected =
                                  _bhkAssignedFlats[bhk]?.contains(flat) ??
                                      false;
                              final isOtherAssigned =
                                  _bhkAssignedFlats.entries.any(
                                (e) => e.key != bhk && e.value.contains(flat),
                              );
                              final otherBhk = isOtherAssigned
                                  ? _bhkAssignedFlats.entries
                                      .firstWhere((e) => e.value.contains(flat))
                                      .key
                                  : null;

                              return GestureDetector(
                                onTap: isOtherAssigned
                                    ? null
                                    : () {
                                        setState(() {
                                          final list = _bhkAssignedFlats[bhk]!;
                                          if (isThisSelected) {
                                            list.remove(flat);
                                          } else {
                                            list.add(flat);
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isThisSelected
                                        ? AppColors.green
                                            .withValues(alpha: 0.08)
                                        : (isOtherAssigned
                                            ? const Color(0xFFF3F4F6)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isThisSelected
                                          ? AppColors.green
                                          : (isOtherAssigned
                                              ? const Color(0xFFE5E7EB)
                                              : const Color(0xFFD1D5DB)),
                                      width: isThisSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        flat,
                                        style:
                                            AppTypography.bodySemiBold.copyWith(
                                          fontSize: 12.5,
                                          fontWeight: isThisSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isThisSelected
                                              ? AppColors.green
                                              : (isOtherAssigned
                                                  ? const Color(0xFF9CA3AF)
                                                  : AppColors.ink),
                                        ),
                                      ),
                                      if (isOtherAssigned) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '($otherBhk)',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // Button to add custom BHK
          if (!_showAddCustomBhk) ...[
            GestureDetector(
              onTap: () => setState(() => _showAddCustomBhk = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+ Other (4 BHK / Custom)',
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _FloatingInput(
                      controller: _customBhkController,
                      label: 'Flat Type Name (e.g. 4 BHK)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = _customBhkController.text.trim();
                      if (name.isNotEmpty &&
                          !_bhkAssignedFlats.containsKey(name)) {
                        setState(() {
                          _bhkAssignedFlats[name] = [];
                          _bhkOccupancy[name] = {
                            'Hall (3-Sharing)': 0,
                            'Bedroom (2-Sharing)': 0,
                            'Master Room': 0,
                          };
                          _customBhkController.clear();
                          _showAddCustomBhk = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    child: const Text('Add',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          _buildDivider(),

          // 2. Standard Occupancy Per Flat
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Standard Occupancy Per Flat',
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                // Tabs container
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: _bhkOccupancy.keys.map((bhk) {
                      final isActive = _selectedBhkTab == bhk;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedBhkTab = bhk),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  isActive ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                isActive ? '$bhk (Active)' : bhk,
                                style: AppTypography.bodySemiBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isActive
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                // Row 1: Hall (3-Sharing)
                _buildOccupancyRow(
                  title: 'Hall (3-Sharing)',
                  count: _bhkOccupancy[_selectedBhkTab]?['Hall (3-Sharing)'] ?? 0,
                  onDecrement: () {
                    final cur =
                        _bhkOccupancy[_selectedBhkTab]?['Hall (3-Sharing)'] ?? 0;
                    if (cur > 0) {
                      setState(() =>
                          _bhkOccupancy[_selectedBhkTab]!['Hall (3-Sharing)'] =
                              cur - 1);
                    }
                  },
                  onIncrement: () {
                    final cur =
                        _bhkOccupancy[_selectedBhkTab]?['Hall (3-Sharing)'] ?? 0;
                    setState(() =>
                        _bhkOccupancy[_selectedBhkTab]!['Hall (3-Sharing)'] =
                            cur + 1);
                  },
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                // Row 2: Bedroom (2-Sharing)
                _buildOccupancyRow(
                  title: 'Bedroom (2-Sharing)',
                  count: _bhkOccupancy[_selectedBhkTab]
                          ?['Bedroom (2-Sharing)'] ??
                      0,
                  onDecrement: () {
                    final cur = _bhkOccupancy[_selectedBhkTab]
                            ?['Bedroom (2-Sharing)'] ??
                        0;
                    if (cur > 0) {
                      setState(() =>
                          _bhkOccupancy[_selectedBhkTab]![
                              'Bedroom (2-Sharing)'] = cur - 1);
                    }
                  },
                  onIncrement: () {
                    final cur = _bhkOccupancy[_selectedBhkTab]
                            ?['Bedroom (2-Sharing)'] ??
                        0;
                    setState(() =>
                        _bhkOccupancy[_selectedBhkTab]![
                            'Bedroom (2-Sharing)'] = cur + 1);
                  },
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                // Row 3: Master Room
                _buildOccupancyRow(
                  title: 'Master Room',
                  isMaster: true,
                  count:
                      _bhkOccupancy[_selectedBhkTab]?['Master Room'] ?? 0,
                  onDecrement: () {
                    final cur =
                        _bhkOccupancy[_selectedBhkTab]?['Master Room'] ?? 0;
                    if (cur > 0) {
                      setState(() =>
                          _bhkOccupancy[_selectedBhkTab]!['Master Room'] =
                              cur - 1);
                    }
                  },
                  onIncrement: () {
                    final cur =
                        _bhkOccupancy[_selectedBhkTab]?['Master Room'] ?? 0;
                    setState(() =>
                        _bhkOccupancy[_selectedBhkTab]!['Master Room'] =
                            cur + 1);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          _buildDivider(),
          const SizedBox(height: 14),

          // 3. Monthly Rent & Deposit (Apartment Units)
          Text(
            'Monthly Rent & Deposit',
            style: AppTypography.heading3.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          ...[
            {'name': 'Master Room', 'tag': 'Higher Rent'},
            {'name': 'Bedroom (2-Sharing)', 'tag': 'Per Bed'},
            {'name': 'Hall (3-Sharing)', 'tag': 'Per Bed'},
          ].map((item) {
            final name = item['name']!;
            final tag = item['tag']!;
            final rentCtrl = _rentControllers.putIfAbsent(
              name,
              () => TextEditingController(),
            );
            final depCtrl = _depositControllers.putIfAbsent(
              name,
              () => TextEditingController(),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                        name,
                        style: AppTypography.bodySemiBold.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
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
                          controller: rentCtrl,
                          label: 'Monthly Rent (₹)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FloatingInput(
                          controller: depCtrl,
                          label: 'Deposit (₹)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ] else if (_calculateTotalRooms() > 0) ...[
          // 5. Sharing Types Multi-Select Pills (Standard PG)
          // Only shown after at least 1 room is entered across any floor
          _buildSectionLabel('Sharing Types Available'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...[
                '1-Share',
                '2-Share',
                '3-Share',
                '4-Share',
                '5-Share',
                '6-Share',
                'Master Room Sharing',
              ].map((type) {
                final isSelected = _selectedSharings.contains(type);
                return _buildSharingPill(
                  label: type,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSharings.remove(type);
                        _sharingAssignedRooms.remove(type);
                      } else {
                        _selectedSharings.add(type);
                        _sharingAssignedRooms.putIfAbsent(type, () => []);
                        _rentControllers.putIfAbsent(
                            type, () => TextEditingController());
                        _depositControllers.putIfAbsent(
                            type, () => TextEditingController());
                      }
                    });
                  },
                );
              }),
              _buildSharingPill(
                label: '+ Type Sharing',
                isSelected: _showCustomSharingInput,
                onTap: () {
                  setState(() {
                    _showCustomSharingInput = !_showCustomSharingInput;
                  });
                },
              ),
            ],
          ),

          if (_showCustomSharingInput) ...[
            const SizedBox(height: 8),
            _FloatingInput(
              controller: _customSharingController,
              label: 'Enter Custom Sharing (e.g. 7 or 8-Share)',
              keyboardType: TextInputType.number,
              onSubmitted: (val) {
                final num = int.tryParse(val);
                if (num != null && num >= 1) {
                  final key = '$num-Share';
                  if (!_selectedSharings.contains(key)) {
                    setState(() {
                      _selectedSharings.add(key);
                      _sharingAssignedRooms.putIfAbsent(key, () => []);
                      _rentControllers.putIfAbsent(
                          key, () => TextEditingController());
                      _depositControllers.putIfAbsent(
                          key, () => TextEditingController());
                      _showCustomSharingInput = false;
                      _customSharingController.clear();
                    });
                  }
                }
              },
            ),
          ],

          // 6. Assign Rooms by Sharing Type (Interactive Floor-by-Floor Cards)
          if (_selectedSharings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionLabel('Assign Rooms by Sharing Type'),
            Text(
              'Tap the rooms on each floor that belong to each category.',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            ..._selectedSharings.map((sharing) {
              final flatsPerFloor = _getFlatsPerFloor();
              final count = _sharingAssignedRooms[sharing]?.length ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                          '$sharing Rooms',
                          style: AppTypography.bodySemiBold.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count Rooms',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...flatsPerFloor.entries.map((floorEntry) {
                      final floorName = floorEntry.key;
                      final rooms = floorEntry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              floorName,
                              style: AppTypography.captionSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: rooms.map((room) {
                                final isThisSelected =
                                    _sharingAssignedRooms[sharing]?.contains(room) ??
                                        false;
                                final isOtherAssigned =
                                    _sharingAssignedRooms.entries.any(
                                  (e) => e.key != sharing && e.value.contains(room),
                                );
                                final otherSharing = isOtherAssigned
                                    ? _sharingAssignedRooms.entries
                                        .firstWhere((e) => e.value.contains(room))
                                        .key
                                    : null;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isThisSelected) {
                                        _sharingAssignedRooms[sharing]?.remove(room);
                                      } else {
                                        for (final list in _sharingAssignedRooms.values) {
                                          list.remove(room);
                                        }
                                        _sharingAssignedRooms
                                            .putIfAbsent(sharing, () => [])
                                            .add(room);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isThisSelected
                                          ? AppColors.green
                                              .withValues(alpha: 0.08)
                                          : (isOtherAssigned
                                              ? const Color(0xFFF3F4F6)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isThisSelected
                                            ? AppColors.green
                                            : (isOtherAssigned
                                                ? const Color(0xFFE5E7EB)
                                                : const Color(0xFFD1D5DB)),
                                        width: isThisSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          room,
                                          style:
                                              AppTypography.bodySemiBold.copyWith(
                                            fontSize: 12.5,
                                            fontWeight: isThisSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isThisSelected
                                                ? AppColors.green
                                                : (isOtherAssigned
                                                    ? const Color(0xFF9CA3AF)
                                                    : AppColors.ink),
                                          ),
                                        ),
                                        if (isOtherAssigned) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '($otherSharing)',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 6),
          _buildDivider(),

          // 6. Monthly Rent & Deposit per Bed (Standard PG)
          Text(
            'Monthly Rent & Deposit per Bed',
            style: AppTypography.heading3.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          if (_selectedSharings.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  'Select sharing types above to configure rent & deposit pricing.',
                  style: AppTypography.bodyRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            ..._selectedSharings.map((sharing) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                          '$sharing Bed',
                          style: AppTypography.bodySemiBold.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                            controller: _rentControllers[sharing] ??
                                TextEditingController(),
                            label: 'Monthly Rent (₹)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FloatingInput(
                            controller: _depositControllers[sharing] ??
                                TextEditingController(),
                            label: 'Deposit (₹)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],

        const SizedBox(height: 6),
        _buildDivider(),

        // 7. Automated Collection Rules (Zero Pre-selected)
        Text(
          'Automated Rent Collection Rules',
          style: AppTypography.heading3.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),

        _buildSectionLabel('Monthly Rent Due Day'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '1st',
              sub: 'of Month',
              isSelected: _dueDay == '1st',
              onTap: () => setState(() {
                _dueDay = '1st';
                _showCustomDueDay = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '5th',
              sub: 'Default',
              isSelected: _dueDay == '5th',
              onTap: () => setState(() {
                _dueDay = '5th';
                _showCustomDueDay = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '10th',
              sub: 'of Month',
              isSelected: _dueDay == '10th',
              onTap: () => setState(() {
                _dueDay = '10th';
                _showCustomDueDay = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '+ Day',
              sub: 'Custom',
              isSelected: _showCustomDueDay,
              onTap: () => setState(() => _showCustomDueDay = true),
            ),
          ],
        ),

        if (_showCustomDueDay) ...[
          const SizedBox(height: 8),
          _FloatingInput(
            controller: _customDueDayController,
            label: 'Enter Custom Due Day (1 to 28 of every month)',
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 6),
        _buildDivider(),

        // 8. Grace Period Days (Zero Pre-selected)
        _buildSectionLabel('Grace Period Days'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '2 Days',
              sub: 'Till 7th',
              isSelected: _gracePeriod == '2 Days',
              onTap: () => setState(() => _gracePeriod = '2 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '3 Days',
              sub: 'Default',
              isSelected: _gracePeriod == '3 Days',
              onTap: () => setState(() => _gracePeriod = '3 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '5 Days',
              sub: 'Till 10th',
              isSelected: _gracePeriod == '5 Days',
              onTap: () => setState(() => _gracePeriod = '5 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '7 Days',
              sub: '1 Week',
              isSelected: _gracePeriod == '7 Days',
              onTap: () => setState(() => _gracePeriod = '7 Days'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // 9. Late Payment Penalty (Zero Pre-selected)
        _buildSectionLabel('Late Payment Penalty'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '₹50',
              sub: 'per day',
              isSelected: _lateFee == '₹50',
              onTap: () => setState(() {
                _lateFee = '₹50';
                _showCustomLateFee = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '₹100',
              sub: 'per day',
              isSelected: _lateFee == '₹100',
              onTap: () => setState(() {
                _lateFee = '₹100';
                _showCustomLateFee = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '₹0',
              sub: 'No Late Fee',
              isSelected: _lateFee == '₹0',
              onTap: () => setState(() {
                _lateFee = '₹0';
                _showCustomLateFee = false;
              }),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '+ Custom',
              sub: 'Enter ₹',
              isSelected: _showCustomLateFee,
              onTap: () => setState(() => _showCustomLateFee = true),
            ),
          ],
        ),

        if (_showCustomLateFee) ...[
          const SizedBox(height: 8),
          _FloatingInput(
            controller: _customLateFeeController,
            label: 'Enter Custom Daily Late Fee (₹ / day)',
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 6),
        _buildDivider(),

        // 10. Move-out Notice Period (Zero Pre-selected)
        _buildSectionLabel('Move-out Notice Period'),
        Row(
          children: [
            _buildInteractiveCard(
              title: '15 Days',
              sub: 'Half Month',
              isSelected: _noticePeriod == '15 Days',
              onTap: () => setState(() => _noticePeriod = '15 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '30 Days',
              sub: 'Default',
              isSelected: _noticePeriod == '30 Days',
              onTap: () => setState(() => _noticePeriod = '30 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '45 Days',
              sub: 'Standard',
              isSelected: _noticePeriod == '45 Days',
              onTap: () => setState(() => _noticePeriod = '45 Days'),
            ),
            const SizedBox(width: 6),
            _buildInteractiveCard(
              title: '60 Days',
              sub: '2 Months',
              isSelected: _noticePeriod == '60 Days',
              onTap: () => setState(() => _noticePeriod = '60 Days'),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 4: Bank & Payout Account (Direct Bank Settlement)
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          'Bank & Payout Account',
          'Where your tenant monthly rent payments will be directly credited.',
        ),
        const SizedBox(height: 14),

        // Direct Settlement Trust Callout Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: AppColors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct Bank Settlement (0% Commission)',
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tenant payments flow 100% directly into your personal bank account. UrbanStay has zero fee deduction and zero holding period.',
                      style: AppTypography.bodyRegular.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _FloatingInput(
          controller: _bankHolderNameController,
          label: 'Bank Account Holder Name (as per Passbook)',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 10),

        _FloatingInput(
          controller: _bankNameController,
          label: 'Bank Name (e.g. HDFC Bank, SBI, ICICI, Canara)',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        _FloatingInput(
          controller: _upiIdController,
          label: 'Primary UPI ID / VPA (e.g. yourname@hdfcbank)',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        // UPI Linked Phone
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                controller: _creditingPhoneController,
                label: 'UPI Linked Phone Number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildDivider(),

        // Bank QR Code Upload Button
        Text(
          'Bank QR Code Photo (Optional)',
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _qrAttached = !_qrAttached),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _qrAttached
                    ? AppColors.green.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _qrAttached ? AppColors.green : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _qrAttached
                        ? Icons.check_circle_rounded
                        : Icons.qr_code_scanner_rounded,
                    size: 18,
                    color: _qrAttached ? AppColors.green : AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _qrAttached
                        ? '✓ QR Code Attached'
                        : 'Upload Bank UPI QR Code',
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 13.5,
                      fontWeight:
                          _qrAttached ? FontWeight.w700 : FontWeight.w600,
                      color: _qrAttached ? AppColors.green : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Sticky Action Bar
  Widget _buildBottomBar() {
    final continueLabel = widget.isScaleMode
        ? 'Save & Update Bed Capacity'
        : (_currentStep == 4 ? 'Complete Setup & Launch Dashboard' : 'Continue');

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          10.0,
          context.responsiveHorizontalPadding,
          16.0,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF4F4F5))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.green.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    continueLabel,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.isScaleMode) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _handleSkip,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F4F5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Skip for now',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Divider(color: Color(0xFFF0F0F0), thickness: 1),
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
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
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFloorCard({required bool isSelected}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _showCustomFloor = true;
              if (_customFloorController.text.trim().isNotEmpty) {
                final n = int.tryParse(_customFloorController.text.trim());
                if (n != null && n > 0) {
                  _floorCount = '$n Floors';
                }
              }
            });
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
            child: _showCustomFloor
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        child: TextField(
                          controller: _customFloorController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          style: AppTypography.bodySemiBold.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                          decoration: InputDecoration(
                            hintText: '4',
                            hintStyle: TextStyle(
                              color: AppColors.green.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final n = int.tryParse(val.trim());
                            if (n != null && n > 0) {
                              setState(() {
                                _floorCount = '$n Floors';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Floors',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+ Custom',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySemiBold.copyWith(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color:
                              isSelected ? AppColors.greenDark : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Floors',
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
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingPill({
    required String label,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          child: Text(
            label,
            style: AppTypography.bodySemiBold.copyWith(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.greenDark : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Smart Floating Label Input Field
/// Uses standard OutlineInputBorder with floatingLabelBehavior.auto:
/// - Label floats up smoothly into the top padding in Emerald Green (#08A63F) with 700 bold weight.
/// - Cursor and typed text are positioned below the label with comfortable breathing room.
/// - ZERO text clipping, ZERO overlap with the cursor.
class _FloatingInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _FloatingInput({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
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
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
      ),
    );
  }
}

/// Dashed Upload Pill Button
class _UploadPill extends StatelessWidget {
  final bool isDone;
  final String label;
  final VoidCallback onTap;

  const _UploadPill({
    required this.isDone,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isDone ? AppColors.green.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone ? AppColors.green : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                size: 16,
                color: isDone ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
                    color: isDone ? AppColors.green : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
