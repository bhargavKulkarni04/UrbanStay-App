import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen: Tenant Move-In & Onboarding Approval Hub.
/// Strict Design Rules:
/// - Clean Text Layout for Room Number and Sharing Type (no heavy black pills).
/// - Full Editable Controls in Accept Modal so owner can correct room, sharing, rent & deposit if needed.
/// - Zero Aadhaar Number & Zero Bed Labels.
/// - Dual-Tab Architecture: `Pending Requests (2)` vs `Onboarding History (3)`.
/// - Icon-only buttons for Call & WhatsApp in brand green style.
/// - 100% Zero Emojis (pure native vector icons & Google Fonts Outfit typography).
/// - 100% Zero Purple / Vibe-Coded Colors (Strict emerald green, ink, and pure white cards).
class OwnerOnboardingApprovalsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerOnboardingApprovalsScreen({super.key, this.onBack});

  @override
  State<OwnerOnboardingApprovalsScreen> createState() => _OwnerOnboardingApprovalsScreenState();
}

class _OwnerOnboardingApprovalsScreenState extends State<OwnerOnboardingApprovalsScreen> {
  int _activeTabIndex = 0; // 0: Pending Requests, 1: Onboarding History
  final TextEditingController _searchController = TextEditingController();

  // Master Pending Onboarding Requests List
  final List<Map<String, dynamic>> _pendingList = [
    {
      'id': 'REQ-8821',
      'name': 'Rahul Verma',
      'initials': 'RV',
      'phone': '9876543210',
      'roomNumber': '101',
      'sharingType': '2 Sharing',
      'rent': 8500,
      'deposit': 15000,
      'appliedTime': '11:15 AM',
      'moveInDate': '29 Aug 2026',
    },
    {
      'id': 'REQ-8822',
      'name': 'Priya Nair',
      'initials': 'PN',
      'phone': '9845112233',
      'roomNumber': '203',
      'sharingType': '3 Sharing',
      'rent': 7500,
      'deposit': 12000,
      'appliedTime': '02:34 PM',
      'moveInDate': '1 Sep 2026',
    },
  ];

  // Master Onboarding History List
  final List<Map<String, dynamic>> _historyList = [
    {
      'id': 'REQ-8790',
      'name': 'Kunal Sharma',
      'initials': 'KS',
      'phone': '9880199221',
      'roomNumber': '101',
      'sharingType': '2 Sharing',
      'rent': 8500,
      'deposit': 15000,
      'status': 'approved', // 'approved', 'rejected'
      'processedDate': '15 Aug 2026',
      'auditNote': 'Approved & Assigned Room 101 by Bhargav (Owner)',
    },
    {
      'id': 'REQ-8785',
      'name': 'Ananya Deshmukh',
      'initials': 'AD',
      'phone': '9741200334',
      'roomNumber': '201',
      'sharingType': '2 Sharing',
      'rent': 8500,
      'deposit': 15000,
      'status': 'approved',
      'processedDate': '10 Aug 2026',
      'auditNote': 'Approved & Assigned Room 201 by Bhargav (Owner)',
    },
    {
      'id': 'REQ-8772',
      'name': 'Vikas Gupta',
      'initials': 'VG',
      'phone': '9611088771',
      'roomNumber': '102',
      'sharingType': '3 Sharing',
      'rent': 7500,
      'deposit': 12000,
      'status': 'rejected',
      'processedDate': '04 Aug 2026',
      'auditNote': 'Rejected: Room already allotted to another resident',
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
    // Editable state controllers so owner can modify room, sharing, rent & deposit
    final roomController = TextEditingController(text: req['roomNumber']);
    final sharingController = TextEditingController(text: req['sharingType'] ?? '2 Sharing');
    final rentController = TextEditingController(text: (req['rent'] as int).toString());
    final depositController = TextEditingController(text: (req['deposit'] as int).toString());
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Confirm Resident Onboarding',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Resident Summary Header (Zero job/company subtitle)
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
                              const SizedBox(height: 2),
                              Text(
                                'Applied at ${req['appliedTime'] ?? '11:15 AM'}',
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

                  // 2. Section Header with "Modify Details" toggle
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
                  const SizedBox(height: 8),

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
                              _buildFormLabel('Sharing Type'),
                              _buildTextInput(sharingController, hint: 'e.g. 2 Sharing'),
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
                    // Standard Display Mode: Clean layout without black pills, no bed, plain green rent text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room - ${roomController.text}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Sharing - ${sharingController.text}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${rentController.text}',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Security Deposit: ₹${depositController.text}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 3. Confirm Onboarding Action Button (Concise text, smoothly reachable)
                  ElevatedButton(
                    onPressed: () {
                      final assignedRoom = roomController.text.trim();
                      final assignedSharing = sharingController.text.trim();
                      final finalRent = int.tryParse(rentController.text.replaceAll(',', '').replaceAll('₹', '')) ?? req['rent'];
                      final finalDeposit = int.tryParse(depositController.text.replaceAll(',', '').replaceAll('₹', '')) ?? req['deposit'];

                      Navigator.of(ctx).pop();
                      setState(() {
                        _pendingList.removeWhere((item) => item['id'] == req['id']);
                        _historyList.insert(0, {
                          'id': req['id'],
                          'name': req['name'],
                          'initials': req['initials'],
                          'phone': req['phone'],
                          'roomNumber': assignedRoom,
                          'sharingType': assignedSharing,
                          'rent': finalRent,
                          'deposit': finalDeposit,
                          'status': 'approved',
                          'processedDate': 'Today',
                          'auditNote': 'Approved & Assigned Room $assignedRoom by Bhargav (Owner)',
                        });
                      });
                      _showToast('✓ ${req['name']} Onboarded to Room $assignedRoom');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Onboarding',
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800),
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
                          'phone': req['phone'],
                          'roomNumber': req['roomNumber'],
                          'sharingType': req['sharingType'],
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
      final name = (item['name'] as String? ?? '').toLowerCase();
      final room = (item['roomNumber'] as String? ?? '').toLowerCase();
      return name.contains(query) || room.contains(query);
    }).toList();

    final filteredHistory = _historyList.where((item) {
      if (query.isEmpty) return true;
      final name = (item['name'] as String? ?? '').toLowerCase();
      final room = (item['roomNumber'] as String? ?? '').toLowerCase();
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
          // 1. Top Row: Avatar + Name + Applied Time (No swiggy / software subtitle)
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
                      'Applied at ${req['appliedTime'] ?? '11:15 AM'}',
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

          // 2. ROOM & SHARING BLOCK (Clean text layout, no black pill, no bed, plain green text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room - ${req['roomNumber']}',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sharing - ${req['sharingType']}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${(req['rent'] as int).toString()}',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: AppColors.greenDark,
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

          // 4. Contact Buttons (Icons only, no text)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Calling ${req['name']}: +91${req['phone']}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/phone.svg',
                        width: 17,
                        height: 17,
                        colorFilter: const ColorFilter.mode(AppColors.greenDark, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('WhatsApp opened with ${req['name']}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/whatsapp.svg',
                        width: 17,
                        height: 17,
                      ),
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
                        'Room - ${item['roomNumber']} • ${item['sharingType'] ?? '2 Sharing'} • ${item['processedDate']}',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset > 0 ? bottomInset + 10 : (bottomPadding > 0 ? bottomPadding : 16),
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
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
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
