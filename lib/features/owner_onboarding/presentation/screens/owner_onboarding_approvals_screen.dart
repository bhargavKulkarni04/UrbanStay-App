import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen: Tenant Move-In & Onboarding Approval Hub.
/// Strict Design Rules:
/// - Prominent High-Contrast Visual Block for Room Number, Sharing Type, and Bed Label.
/// - Full Editable Controls in Accept Modal so owner can correct/modify room, bed, rent & deposit if entered wrong.
/// - Zero Aadhaar Number (removed completely).
/// - Dual-Tab Architecture: `Pending Requests (2)` vs `Onboarding History (3)`.
/// - Zero Summary Strip.
/// - Side-by-Side [ 📞 Call Tenant ] and [ 💬 WhatsApp ] directly above the Decision Action Row.
/// - 100% Zero Emojis (pure native material vector icons & Google Fonts Outfit typography).
/// - 100% Zero Purple / Vibe-Coded Colors (Strict emerald green, ink, warm gold, and pure white cards).
class OwnerOnboardingApprovalsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerOnboardingApprovalsScreen({super.key, this.onBack});

  @override
  State<OwnerOnboardingApprovalsScreen> createState() => _OwnerOnboardingApprovalsScreenState();
}

class _OwnerOnboardingApprovalsScreenState extends State<OwnerOnboardingApprovalsScreen> {
  int _activeTabIndex = 0; // 0: Pending Requests, 1: Onboarding History
  final TextEditingController _searchController = TextEditingController();

  // Master Pending Onboarding Requests List (Zero Aadhaar numbers)
  final List<Map<String, dynamic>> _pendingList = [
    {
      'id': 'REQ-8821',
      'name': 'Rahul Verma',
      'initials': 'RV',
      'workTitle': 'Software Engineer @ Swiggy',
      'phone': '9876543210',
      'roomNumber': '101',
      'bedLabel': 'Bed B',
      'sharingType': '2-Sharing',
      'floor': '1st Floor',
      'rent': 8500,
      'deposit': 15000,
      'appliedTime': '15 mins ago',
      'moveInDate': '29 Aug 2026',
    },
    {
      'id': 'REQ-8822',
      'name': 'Priya Nair',
      'initials': 'PN',
      'workTitle': 'Product Analyst @ Razorpay',
      'phone': '9845112233',
      'roomNumber': '203',
      'bedLabel': 'Bed A',
      'sharingType': '3-Sharing',
      'floor': '2nd Floor',
      'rent': 7500,
      'deposit': 12000,
      'appliedTime': '1 hour ago',
      'moveInDate': '1 Sep 2026',
    },
  ];

  // Master Onboarding History List
  final List<Map<String, dynamic>> _historyList = [
    {
      'id': 'REQ-8790',
      'name': 'Kunal Sharma',
      'initials': 'KS',
      'workTitle': 'Systems Engineer @ Infosys',
      'phone': '9880199221',
      'roomNumber': '101',
      'bedLabel': 'Bed A',
      'sharingType': '2-Sharing',
      'floor': '1st Floor',
      'rent': 8500,
      'deposit': 15000,
      'status': 'approved', // 'approved', 'rejected'
      'processedDate': '15 Aug 2026',
      'auditNote': 'Approved & Assigned Bed 101-A by Bhargav (Owner)',
    },
    {
      'id': 'REQ-8785',
      'name': 'Ananya Deshmukh',
      'initials': 'AD',
      'workTitle': 'UI Designer @ CRED',
      'phone': '9741200334',
      'roomNumber': '201',
      'bedLabel': 'Bed A',
      'sharingType': '2-Sharing',
      'floor': '2nd Floor',
      'rent': 8500,
      'deposit': 15000,
      'status': 'approved',
      'processedDate': '10 Aug 2026',
      'auditNote': 'Approved & Assigned Bed 201-A by Bhargav (Owner)',
    },
    {
      'id': 'REQ-8772',
      'name': 'Vikas Gupta',
      'initials': 'VG',
      'workTitle': 'Accountant @ Tally',
      'phone': '9611088771',
      'roomNumber': '102',
      'bedLabel': 'Bed C',
      'sharingType': '3-Sharing',
      'floor': '1st Floor',
      'rent': 7500,
      'deposit': 12000,
      'status': 'rejected',
      'processedDate': '04 Aug 2026',
      'auditNote': 'Rejected: Bed already allotted to another resident',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  // ===========================================================================
  // ACCEPT ONBOARDING FLOW WITH INLINE EDIT CAPABILITY
  // ===========================================================================
  void _acceptOnboarding(Map<String, dynamic> req) {
    // Editable state controllers so owner can modify wrong tenant entries
    final roomController = TextEditingController(text: req['roomNumber']);
    final bedController = TextEditingController(text: req['bedLabel']);
    final rentController = TextEditingController(text: (req['rent'] as int).toString());
    final depositController = TextEditingController(text: (req['deposit'] as int).toString());
    String selectedSharing = req['sharingType'] ?? '2-Sharing';
    String depositMode = 'Direct UPI Paid';
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Confirm Resident Onboarding',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Tenant Summary Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              req['initials'] ?? 'RV',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req['name'],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${req['workTitle']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Section Header with "Edit Details" toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Room & Rent Allocation'),
                      InkWell(
                        onTap: () => setModalState(() => isEditing = !isEditing),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isEditing ? AppColors.ink : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEditing ? Icons.check : Icons.edit_outlined,
                                size: 12,
                                color: isEditing ? Colors.white : AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isEditing ? 'Done Editing' : 'Modify Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isEditing ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // If Editing Mode: Show Text Inputs
                  if (isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Room Number'),
                              _buildTextInput(roomController, hint: 'e.g. 101'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Bed Label'),
                              _buildTextInput(bedController, hint: 'e.g. Bed B'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Monthly Rent (₹)'),
                              _buildTextInput(rentController, hint: '₹ Rent', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Deposit (₹)'),
                              _buildTextInput(depositController, hint: '₹ Deposit', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Standard Display Mode: Prominent Visual Block
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ROOM ${roomController.text}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$selectedSharing • ${bedController.text}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${rentController.text}/mo',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Security Deposit: ₹${depositController.text}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 3. Deposit Payment Mode Selector
                  _buildSectionHeader('Deposit Collection Mode'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDepositModeChip(
                          'Direct UPI (Paid)',
                          depositMode == 'Direct UPI Paid',
                          () => setModalState(() => depositMode = 'Direct UPI Paid'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDepositModeChip(
                          'Collect at Check-In',
                          depositMode == 'Collect at Check-In',
                          () => setModalState(() => depositMode = 'Collect at Check-In'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Big Action CTA
                  ElevatedButton(
                    onPressed: () {
                      final assignedRoom = roomController.text.trim();
                      final assignedBed = bedController.text.trim();
                      final finalRent = int.tryParse(rentController.text.replaceAll(',', '').replaceAll('₹', '')) ?? req['rent'];
                      final finalDeposit = int.tryParse(depositController.text.replaceAll(',', '').replaceAll('₹', '')) ?? req['deposit'];

                      Navigator.of(ctx).pop();
                      setState(() {
                        _pendingList.removeWhere((item) => item['id'] == req['id']);
                        _historyList.insert(0, {
                          'id': req['id'],
                          'name': req['name'],
                          'initials': req['initials'],
                          'workTitle': req['workTitle'],
                          'phone': req['phone'],
                          'roomNumber': assignedRoom,
                          'bedLabel': assignedBed,
                          'sharingType': selectedSharing,
                          'floor': req['floor'],
                          'rent': finalRent,
                          'deposit': finalDeposit,
                          'status': 'approved',
                          'processedDate': 'Today',
                          'auditNote': 'Approved & Assigned Room $assignedRoom ($assignedBed) by Bhargav (Owner)',
                        });
                      });
                      _showToast('✓ ${req['name']} Onboarded to Room $assignedRoom ($assignedBed) • App Access Unlocked');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Onboarding & Unlock Resident App',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // REJECT ONBOARDING FLOW
  // ===========================================================================
  void _rejectOnboarding(Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selectedReason = 'Bed already allotted to another resident';

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Reject Move-In Request',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select a reason for denying ${req['name']}\'s onboarding request. The applicant will be notified politely and blocked from accessing PG data.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  _buildReasonTile('Bed already allotted to another resident', selectedReason, (r) => setModalState(() => selectedReason = r)),
                  _buildReasonTile('Profile does not match PG stay preferences', selectedReason, (r) => setModalState(() => selectedReason = r)),
                  _buildReasonTile('Incomplete stay details provided', selectedReason, (r) => setModalState(() => selectedReason = r)),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _pendingList.removeWhere((item) => item['id'] == req['id']);
                        _historyList.insert(0, {
                          'id': req['id'],
                          'name': req['name'],
                          'initials': req['initials'],
                          'workTitle': req['workTitle'],
                          'phone': req['phone'],
                          'roomNumber': req['roomNumber'],
                          'bedLabel': req['bedLabel'],
                          'sharingType': req['sharingType'],
                          'floor': req['floor'],
                          'rent': req['rent'],
                          'deposit': req['deposit'],
                          'status': 'rejected',
                          'processedDate': 'Today',
                          'auditNote': 'Rejected: $selectedReason',
                        });
                      });
                      _showToast('Request Denied for ${req['name']}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Rejection',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();

    final filteredPending = _pendingList.where((item) {
      if (query.isEmpty) return true;
      final name = (item['name'] as String).toLowerCase();
      final room = (item['roomNumber'] as String).toLowerCase();
      final work = (item['workTitle'] as String).toLowerCase();
      return name.contains(query) || room.contains(query) || work.contains(query);
    }).toList();

    final filteredHistory = _historyList.where((item) {
      if (query.isEmpty) return true;
      final name = (item['name'] as String).toLowerCase();
      final room = (item['roomNumber'] as String).toLowerCase();
      return name.contains(query) || room.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Header
            _buildTopHeader(),

            // 2. Dual-Tab Switcher (Pending vs History)
            _buildDualTabSwitcher(),

            // 3. Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: _buildSearchBox(),
            ),

            // 4. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 40.0),
                child: _activeTabIndex == 0
                    ? _buildPendingQueue(filteredPending)
                    : _buildHistoryLedger(filteredHistory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP STICKY HEADER
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move-In Requests',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Greenview PG • Security Gatekeeper',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Pending Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: _pendingList.isNotEmpty ? const Color(0xFFFFFBEB) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: _pendingList.isNotEmpty ? const Color(0xFFFDE68A) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              '${_pendingList.length} Pending',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _pendingList.isNotEmpty ? const Color(0xFF92400E) : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DUAL-TAB SWITCHER
  // ===========================================================================
  Widget _buildDualTabSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('Pending Requests (${_pendingList.length})', 0),
            ),
            Expanded(
              child: _buildTabButton('Onboarding History (${_historyList.length})', 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _activeTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SEARCH BOX
  // ===========================================================================
  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: _activeTabIndex == 0 ? 'Search pending requests...' : 'Search onboarding history...',
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
          suffixIcon: _searchController.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. PENDING ONBOARDING QUEUE (With Prominent Room Block & Zero Aadhaar)
  // ===========================================================================
  Widget _buildPendingQueue(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _buildEmptyState('No pending onboarding requests.\nNew requests from residents will appear here.');
    }

    return Column(
      children: list.map((req) => _buildPendingCard(req)).toList(),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Avatar + Name + Work Info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    req['initials'] ?? 'RV',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req['workTitle'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. PROMINENT HIGH-CONTRAST ROOM & SHARING BLOCK (Visible & Bold)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ROOM ${req['roomNumber']}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${req['sharingType']} • ${req['bedLabel']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${req['floor']} • Applied ${req['appliedTime']}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '₹${(req['rent'] as int).toString()}/mo',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Financial Summary Strip (Deposit agreed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expected Security Deposit',
                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
                Text(
                  '₹${(req['deposit'] as int).toString()}',
                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Contact Buttons (Placed DIRECTLY above Decision Row)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Calling ${req['name']}: +91${req['phone']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text(
                          'Call Tenant',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('WhatsApp opened with ${req['name']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.greenDark),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp Chat',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.greenDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Decision Action Row (Reject vs Accept)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => _rejectOnboarding(req),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Center(
                      child: Text(
                        'Reject',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _acceptOnboarding(req),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Accept & Onboard',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. ONBOARDING HISTORY LEDGER
  // ===========================================================================
  Widget _buildHistoryLedger(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _buildEmptyState('No onboarding history recorded yet.');
    }

    return Column(
      children: list.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final isApproved = item['status'] == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        item['initials'] ?? 'KS',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Room ${item['roomNumber']} (${item['bedLabel']}) • ${item['processedDate']}',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.greenLight : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isApproved ? AppColors.green.withValues(alpha: 0.25) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Text(
                  isApproved ? 'Approved' : 'Rejected',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isApproved ? AppColors.greenDark : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEF0F2)),
          const SizedBox(height: 6),

          Text(
            item['auditNote'] ?? '',
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.person_add_disabled_outlined, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE BOTTOM SHEET HELPERS
  // ===========================================================================
  Widget _buildNativeBottomSheetWrapper({required String title, required Widget child}) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 15, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDepositModeChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTile(String reason, String selectedReason, ValueChanged<String> onSelect) {
    final isSelected = reason == selectedReason;

    return InkWell(
      onTap: () => onSelect(reason),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? const Color(0xFFDC2626) : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFDC2626) : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
