import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../owner_rooms/presentation/screens/owner_rooms_screen.dart';
import '../../../owner_rent/presentation/screens/owner_rent_collection_screen.dart';
import '../../../owner_approvals/presentation/screens/owner_approvals_screen.dart';
import '../../../owner_complaints/presentation/screens/owner_complaints_screen.dart';
import '../../../owner_expenses/presentation/screens/owner_expenses_screen.dart';
import '../../../owner_staff/presentation/screens/owner_staff_screen.dart';
import '../../../owner_settings/presentation/screens/owner_settings_screen.dart';
import '../../../owner_onboarding/presentation/screens/owner_onboarding_approvals_screen.dart';
import '../../../owner_reports/presentation/screens/owner_reports_screen.dart';
import '../../../owner_billing/presentation/screens/owner_saas_billing_screen.dart';
import '../../../owner_rent/presentation/screens/owner_day_collection_screen.dart';

/// Screen 5: Owner Command Center Dashboard.
/// 1-to-1 exact translation of `ProductionCode/owner_dashboard.html`.
/// Design Tokens & Geometry:
/// - Typography: Real Google Font 'Outfit' (`GoogleFonts.outfit(...)`) matching web HTML exactly.
/// - Palette: Ink #111111, Green #08A63F, GreenDark #068237, GreenLight #EBF8EE, Muted #6B7280, Border #EEF0F2 / #E5E7EB, Bg #F4F6F9.
/// - Layouts:
///   1. Unified Top White Header Banner with Property Tagline, Live Pill, Greeting headline, Notification Bell, and BK Avatar.
///   2. Property Hero Card (2-column layout, zero overflow across all device DPIs).
///   3. Monthly Collection Health Card (Count-based: 25 Paid, 6 Pending, 0 Overdue with Month dropdown).
///   4. Quick Actions 4x2 Grid (8 compact square-curved tiles with 24px clean vector icons).
///   5. Announcements Notice Board (+ New Announcement button, active cards, delivered badge, message box & delete action).
///   6. Bottom Fixed Navigation Bar (4 tabs: Dashboard, Rooms, Approvals [badge 2], Plan / Pay).
///   7. 8 Fully Integrated Action Modals (Approval Queue, Rent Dues, Expense, Police KYC, Notice, Complaints, Staff, New Announcement).
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _activeNavIndex = 0; // 0: Dashboard, 1: Rooms, 2: Approvals, 3: Plan / Pay
  String _activeSubScreen = 'dashboard'; // 'dashboard', 'rooms', 'rent'

  // Multi-PG Properties State
  int _activePropertyIndex = 0;
  final List<Map<String, dynamic>> _properties = [
    {
      'id': 'prop_1',
      'name': 'Greenview PG',
      'location': 'Koramangala, Bengaluru',
      'occupiedBeds': 31,
      'totalBeds': 35,
      'occupancyPct': '88% Full',
      'vacantBeds': 4,
      'noticeBeds': 3,
      'monthlyCollected': '₹2,63,500',
      'collectedRatio': '25/31 Collected',
      'paidCount': 25,
      'pendingCount': 6,
      'staffCount': 4,
    },
    {
      'id': 'prop_2',
      'name': 'UrbanStay Luxury PG',
      'location': 'HSR Sector 2, Bengaluru',
      'occupiedBeds': 48,
      'totalBeds': 50,
      'occupancyPct': '96% Full',
      'vacantBeds': 2,
      'noticeBeds': 1,
      'monthlyCollected': '₹4,12,000',
      'collectedRatio': '42/48 Collected',
      'paidCount': 42,
      'pendingCount': 6,
      'staffCount': 6,
    },
    {
      'id': 'prop_3',
      'name': 'UrbanStay Coliving Hub',
      'location': 'BTM 2nd Stage, Bengaluru',
      'occupiedBeds': 22,
      'totalBeds': 25,
      'occupancyPct': '88% Full',
      'vacantBeds': 3,
      'noticeBeds': 2,
      'monthlyCollected': '₹1,98,000',
      'collectedRatio': '20/22 Collected',
      'paidCount': 20,
      'pendingCount': 2,
      'staffCount': 3,
    },
  ];

  // Active Approvals State
  final List<Map<String, String>> _approvalItems = [
    {
      'id': 'appr_1',
      'name': 'Rahul Sharma (Room 101-A)',
      'sub': 'Direct GPay to HDFC Bank • UTR: 423189765412',
      'amount': '₹8,500',
      'proof': 'gpay_payment_screenshot.jpg',
    },
    {
      'id': 'appr_2',
      'name': 'Amit Verma (Room 101-B)',
      'sub': 'PhonePe Transfer • UTR: 889123450912',
      'amount': '₹8,500',
      'proof': 'phonepe_receipt_proof.png',
    },
  ];

  // Active Announcements State
  final List<Map<String, String>> _announcements = [
    {
      'id': 'ann_1',
      'title': 'Water Tank Cleaning Tomorrow',
      'target': 'All Residents (31)',
      'time': 'Today, 5:30 PM',
      'msg':
          'Water supply will be paused tomorrow between 10:00 AM – 2:00 PM for overhead tank sanitization. Kindly store sufficient water in advance.',
      'status': 'Delivered',
    },
  ];

  // Modals Controller State
  bool _showApprovalModal = false;
  bool _showRentModal = false;
  bool _showExpenseModal = false;
  bool _showPoliceModal = false;
  bool _showNoticeModal = false;
  bool _showComplaintsModal = false;
  bool _showStaffModal = false;
  bool _showAnnouncementModal = false;

  // Announcement Form Controllers
  String _annTarget = 'All Residents (31)';
  final _annTitleController = TextEditingController();
  final _annMsgController = TextEditingController();

  // Expense Form Controllers
  final _expenseAmountController = TextEditingController();
  final _expenseCategoryController = TextEditingController();

  @override
  void dispose() {
    _annTitleController.dispose();
    _annMsgController.dispose();
    _expenseAmountController.dispose();
    _expenseCategoryController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17) return 'Good evening';
    return 'Good morning';
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _approvePayment(String id, String name, String amount) {
    setState(() {
      _approvalItems.removeWhere((item) => item['id'] == id);
      if (_approvalItems.isEmpty) {
        _showApprovalModal = false;
      }
    });
    _showToast('$amount Approved! $name marked Paid & PDF Receipt Sent ✓');
  }

  void _rejectPayment(String id, String name) {
    setState(() {
      _approvalItems.removeWhere((item) => item['id'] == id);
      if (_approvalItems.isEmpty) {
        _showApprovalModal = false;
      }
    });
    _showToast('Payment for $name rejected. Tenant notified.');
  }

  void _broadcastAnnouncement() {
    final title = _annTitleController.text.trim();
    final msg = _annMsgController.text.trim();
    if (title.isEmpty || msg.isEmpty) {
      _showToast('Please enter both title and message');
      return;
    }

    setState(() {
      _announcements.insert(0, {
        'id': 'ann_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'target': _annTarget,
        'time': 'Just Now',
        'msg': msg,
        'status': 'Delivered',
      });
      _annTitleController.clear();
      _annMsgController.clear();
      _showAnnouncementModal = false;
    });
    _showToast('App Notification sent to $_annTarget ✓');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_activeSubScreen == 'rent')
              OwnerRentCollectionScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeNavIndex == 1 || _activeSubScreen == 'rooms')
              OwnerRoomsScreen(
                onBack: () => setState(() {
                  _activeNavIndex = 0;
                  _activeSubScreen = 'dashboard';
                }),
              )
            else if (_activeNavIndex == 2 || _activeSubScreen == 'approvals')
              OwnerApprovalsScreen(
                onBack: () => setState(() {
                  _activeNavIndex = 0;
                  _activeSubScreen = 'dashboard';
                }),
              )
            else if (_activeSubScreen == 'complaints')
              OwnerComplaintsScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'expenses')
              OwnerExpensesScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'staff')
              OwnerStaffScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'settings')
              OwnerSettingsScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'onboarding')
              OwnerOnboardingApprovalsScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'reports')
              OwnerReportsScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeSubScreen == 'day_collection')
              OwnerDayCollectionScreen(
                onBack: () => setState(() => _activeSubScreen = 'dashboard'),
              )
            else if (_activeNavIndex == 3 || _activeSubScreen == 'billing')
              OwnerSaaSBillingScreen(
                onBack: () => setState(() {
                  _activeNavIndex = 0;
                  _activeSubScreen = 'dashboard';
                }),
              )
            else
              Column(
                children: [
                  // Top Unified White Header Banner
                  _buildTopBrandHeader(),

                  // Scrollable Dashboard Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 96.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Property & Bed Occupancy Hero Card (Apple-Style Circular Radial Arc)
                          _buildPropertyHeroCard(),
                          const SizedBox(height: 16),

                          // 2. Monthly Collection Health Card (Bigger, Eye-Catching Inside Blocks)
                          _buildCollectionHealthCard(),
                          const SizedBox(height: 16),

                          // 3. UPI Payment Approvals Card (Submitted, Approved, Pending)
                          _buildPaymentApprovalsCard(),
                          const SizedBox(height: 16),

                          // 4. Quick Actions 4x2 Grid (8 Modules)
                          _buildQuickActionsSection(),
                          const SizedBox(height: 16),

                          // 5. Announcements & Notice Board Section
                          _buildAnnouncementsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Bottom Navigation Bar (Fixed 4 Tabs)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavbar(),
            ),

            // Active Interactive Modals
            if (_showApprovalModal) _buildApprovalModalSheet(),
            if (_showRentModal) _buildRentModalSheet(),
            if (_showExpenseModal) _buildExpenseModalSheet(),
            if (_showPoliceModal) _buildPoliceModalSheet(),
            if (_showNoticeModal) _buildNoticeModalSheet(),
            if (_showComplaintsModal) _buildComplaintsModalSheet(),
            if (_showStaffModal) _buildStaffModalSheet(),
            if (_showAnnouncementModal) _buildAnnouncementModalSheet(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. ELEVATED SOLID WHITE HEADER BANNER CONTAINER
  // ===========================================================================
  Widget _buildTopBrandHeader() {
    final prop = _properties[_activePropertyIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Time Greeting & Notification + Profile Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _getTimeGreeting().toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),

              Row(
                children: [
                  // Notification Bell with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () => _showToast('3 Pending Notifications'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 19,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '3',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Owner Profile Avatar Button
                  InkWell(
                    onTap: () => setState(() => _activeSubScreen = 'settings'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green, width: 1.4),
                      ),
                      child: Center(
                        child: Text(
                          'BK',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Row 2: BIG BOLD OWNER HEADLINE
          Text(
            'Bhargav S Kulkarni',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Prominent Interactive Property Switcher Card (Clean, NO Live pill!)
          InkWell(
            onTap: _showPropertySwitcherModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.apartment_rounded, size: 15, color: AppColors.greenDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prop['name'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.ink),
                    ],
                  ),
                  Text(
                    '${prop['occupiedBeds']}/${prop['totalBeds']} Beds',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PROPERTY & BED OCCUPANCY HERO CARD (Apple-Style Circular Radial Arc)
  // ===========================================================================
  Widget _buildPropertyHeroCard() {
    final prop = _properties[_activePropertyIndex];
    final occPct = ((prop['occupiedBeds'] as int) / (prop['totalBeds'] as int));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row: PG Name & Location + Live Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 20,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prop['name'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Text(
                            prop['location'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Live % Full Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      prop['occupancyPct'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hairline Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
            margin: const EdgeInsets.symmetric(vertical: 14),
          ),

          // Middle Section: Left Circular Radial Arc + Right Minimalist Stat Rows
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Circular Radial Arc Gauge
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(108, 108),
                      painter: RadialArcPainter(
                        percentage: occPct,
                        primaryColor: AppColors.green,
                        trackColor: const Color(0xFFF3F4F6),
                        strokeWidth: 8.5,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${prop['occupiedBeds']}',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: AppColors.ink,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/ ${prop['totalBeds']} Beds',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (prop['occupancyPct'] as String).toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical Hairline Divider
              Container(
                width: 1,
                height: 100,
                color: const Color(0xFFF3F4F6),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),

              // Right: 4 Elegant Minimalist Stat Rows
              Expanded(
                child: Column(
                  children: [
                    _buildMinimalStatRow(Icons.bed_outlined, 'Total Capacity', '${prop['totalBeds']} Beds', AppColors.ink),
                    const SizedBox(height: 7),
                    _buildMinimalStatRow(Icons.people_alt_outlined, 'Occupied Beds', '${prop['occupiedBeds']} Beds', AppColors.ink),
                    const SizedBox(height: 7),
                    _buildMinimalStatRow(Icons.single_bed_outlined, 'Vacant Beds', '${prop['vacantBeds']} Beds', AppColors.ink),
                    const SizedBox(height: 7),
                    _buildMinimalStatRow(Icons.badge_outlined, 'Active Staff', '${prop['staffCount']} Staff', AppColors.ink),
                  ],
                ),
              ),
            ],
          ),

          // Hairline Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
            margin: const EdgeInsets.only(top: 14, bottom: 10),
          ),

          // Bottom Strip: Notice + 1-Tap Add Room Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    '${prop['vacantBeds']} Vacant Beds Ready to Book',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _activeNavIndex = 1),
                child: Row(
                  children: [
                    Text(
                      '+ Add Room / Bed',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL: PROPERTY SWITCHER BOTTOM SHEET
  // ===========================================================================
  void _showPropertySwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Active Property',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Switch telemetry, beds & staff directory',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
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

              // Properties List
              ...List.generate(_properties.length, (idx) {
                final prop = _properties[idx];
                final isSelected = idx == _activePropertyIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _activePropertyIndex = idx);
                      Navigator.of(ctx).pop();
                      _showToast('Switched to ${prop['name']} (${prop['location']})');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.greenLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      prop['name'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AppColors.greenDark : AppColors.ink,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${prop['location']} • ${prop['occupiedBeds']}/${prop['totalBeds']} Beds • ${prop['staffCount']} Staff',
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.green)
                          else
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),

              // Onboard New PG Building CTA
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Opening 4-Step PG Onboarding Wizard...');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_business_outlined, size: 16, color: AppColors.ink),
                    const SizedBox(width: 8),
                    Text(
                      '+ Onboard New PG Building',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL: INVITE CO-OWNER / PG MANAGER BOTTOM SHEET
  // ===========================================================================
  void _showInviteManagerModal() {
    String selectedRole = 'manager'; // 'manager', 'co_owner'
    int selectedPropIdx = _activePropertyIndex;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite Co-Owner / Manager',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Assign property-level operational access',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
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
                    const SizedBox(height: 18),

                    // Full Name Field
                    Text('Full Name', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Ramesh Kumar',
                        hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number Field
                    Text('Mobile Number (WhatsApp Enabled)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                      decoration: InputDecoration(
                        prefixText: '+91 ',
                        prefixStyle: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        hintText: '98451 22334',
                        hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Selector Cards
                    Text('Select Access Level', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedRole = 'manager'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedRole == 'manager' ? AppColors.greenLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedRole == 'manager' ? AppColors.green : const Color(0xFFE5E7EB),
                                  width: selectedRole == 'manager' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'PG Manager',
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                                      ),
                                      if (selectedRole == 'manager')
                                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check-ins, UTRs & issues. Bank details hidden.',
                                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedRole = 'co_owner'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedRole == 'co_owner' ? AppColors.greenLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedRole == 'co_owner' ? AppColors.green : const Color(0xFFE5E7EB),
                                  width: selectedRole == 'co_owner' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Co-Owner',
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                                      ),
                                      if (selectedRole == 'co_owner')
                                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Full operations & CA statements access.',
                                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property Scope Selector
                    Text('Assigned Building', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedPropIdx,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink, size: 18),
                          items: List.generate(_properties.length, (idx) {
                            return DropdownMenuItem<int>(
                              value: idx,
                              child: Text(
                                '${_properties[idx]['name']} (${_properties[idx]['location']})',
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPropIdx = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CTA: Send WhatsApp Invite
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          _showToast('Please enter both Name and Mobile Number');
                          return;
                        }
                        Navigator.of(ctx).pop();
                        final propName = _properties[selectedPropIdx]['name'];
                        _showToast('WhatsApp Invitation sent to $name (+91 $phone) for $propName ✓');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Send WhatsApp Invitation Link',
                            style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimalStatRow(IconData icon, String label, String value, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valColor,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. MONTHLY COLLECTION HEALTH CARD (Centered, Pure White Aesthetics)
  // ===========================================================================
  Widget _buildCollectionHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Collection Health + 81% Badge
          Row(
            children: [
              Text(
                'Collection Health',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '81% Collected',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Linear Visual Progress Meter (81% Completed)
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 6,
              color: const Color(0xFFF3F4F6),
              child: Row(
                children: [
                  Expanded(
                    flex: 81,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 19,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Tactile Inside Blocks (Pure White Background, All Green Numbers)
          Row(
            children: [
              // Block 1: Paid Beds
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Paid Beds',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '25',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'of 31 Occupied',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Block 2: Pending Dues
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            'Pending',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '6',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'This Month',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Block 3: Defaulters
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 13, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            'Defaulters',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'Zero Overdue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1-Tap Action Button: Send WhatsApp Payment Links
          InkWell(
            onTap: () => setState(() => _activeSubScreen = 'rent'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Send WhatsApp Payment Links to 6 Pending',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. UPI PAYMENT APPROVALS CARD (Pure Executive Green/Ink, Centered)
  // ===========================================================================
  Widget _buildPaymentApprovalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title + Clean Green Pending Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Approvals',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),

              // Clean White Pending Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions_outlined, size: 12, color: AppColors.greenDark),
                    const SizedBox(width: 4),
                    Text(
                      '${_approvalItems.length} Pending Action',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Tactile Inside Blocks (Pure White Background, All Green Numbers)
          Row(
            children: [
              // Block 1: Submitted
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 13, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '25',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'Payment Forms',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Block 2: Approved
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Approved',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '23',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'Receipts Sent',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Block 3: Pending
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pending_actions_outlined, size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Pending',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_approvalItems.length}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.green,
                        ),
                      ),
                      Text(
                        'Action Needed',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1-Tap Action Button: Review & Approve
          InkWell(
            onTap: () => setState(() => _activeNavIndex = 2),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 14, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Review & Approve ${_approvalItems.length} Payments (UTR Queue)',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. QUICK ACTIONS 4x2 GRID (8 Compact Square-Curved Modules)
  // ===========================================================================
  Widget _buildQuickActionsSection() {
    final List<Map<String, dynamic>> actions = [
      {'title': 'Day-Wise Rent', 'icon': Icons.calendar_month_outlined, 'onTap': () => setState(() => _activeSubScreen = 'day_collection')},
      {'title': 'Rent Collection', 'icon': Icons.account_balance_wallet_outlined, 'onTap': () => setState(() => _activeSubScreen = 'rent')},
      {'title': 'Expenses & P&L', 'icon': Icons.receipt_long_outlined, 'onTap': () => setState(() => _activeSubScreen = 'expenses')},
      {'title': 'Add Room / Bed', 'icon': Icons.add_home_outlined, 'onTap': () => setState(() => _activeNavIndex = 1)},
      {'title': 'Notice Periods', 'icon': Icons.event_note_outlined, 'onTap': () => setState(() => _showNoticeModal = true)},
      {'title': 'Complaints', 'icon': Icons.handyman_outlined, 'onTap': () => setState(() => _activeSubScreen = 'complaints')},
      {'title': 'Move-In KYC', 'icon': Icons.how_to_reg_outlined, 'onTap': () => setState(() => _activeSubScreen = 'onboarding')},
      {'title': 'Staff & Warden', 'icon': Icons.badge_outlined, 'onTap': () => setState(() => _activeSubScreen = 'staff')},
      {'title': 'Invite Manager', 'icon': Icons.person_add_alt_1_outlined, 'onTap': _showInviteManagerModal},
      {'title': 'Reports & P&L', 'icon': Icons.insights_outlined, 'onTap': () => setState(() => _activeSubScreen = 'reports')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.98,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final a = actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: a['onTap'],
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEF0F2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          a['icon'],
                          size: 22,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['title'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. ANNOUNCEMENTS & NOTICE BOARD SECTION
  // ===========================================================================
  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),

            // + New Announcement Button
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAnnouncementModal = true),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text(
                'New Announcement',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Center(
              child: Text(
                'No active announcements. Tap "+ New Announcement" to post.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
            ),
          )
        else
          ..._announcements.map((ann) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Delivered Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ann['title']!,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ann['target']} • ${ann['time']}',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          ann['status']!,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Message Body Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      ann['msg']!,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom Action Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sent via App Notification',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _announcements.removeWhere((item) => item['id'] == ann['id']));
                          _showToast('Announcement deleted');
                        },
                        child: Text(
                          'Delete',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // 6. BOTTOM NAVIGATION BAR (4 Fixed Tabs)
  // ===========================================================================
  Widget _buildBottomNavbar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF0F2), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTab(0, Icons.dashboard_outlined, 'Dashboard'),
          _buildNavTab(1, Icons.meeting_room_outlined, 'Rooms', onTap: () => setState(() => _activeNavIndex = 1)),
          _buildNavTab(2, Icons.verified_outlined, 'Approvals', badgeCount: 2, onTap: () => setState(() => _activeNavIndex = 2)),
          _buildNavTab(3, Icons.credit_card_outlined, 'Plan / Pay', onTap: () => setState(() => _activeNavIndex = 3)),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label, {int? badgeCount, VoidCallback? onTap}) {
    final isActive = _activeNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _activeNavIndex = index);
        if (onTap != null) onTap();
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.green : AppColors.muted,
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.outfit(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? AppColors.green : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 18,
            height: 2.5,
            decoration: BoxDecoration(
              color: isActive ? AppColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. INTERACTIVE MODAL SHEETS (8 MASTER MODALS)
  // ===========================================================================

  /// Modal 0: Payment Verification & Approval Queue (0% Direct Settlement)
  Widget _buildApprovalModalSheet() {
    return _buildModalWrapper(
      title: 'Pending Payment Approvals (${_approvalItems.length})',
      onClose: () => setState(() => _showApprovalModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Residents have transferred rent directly to your bank UPI. Verify UTR / Screenshot and tap Approve to auto-issue official PDF rent receipts.',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),

          if (_approvalItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('All pending payments are approved! ✓', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.green))),
            )
          else
            ..._approvalItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name']!, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                              const SizedBox(height: 2),
                              Text(item['sub']!, style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(item['amount']!, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Proof Attachment Box
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('IMG', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item['proof']!, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink))),
                          InkWell(
                            onTap: () => _showToast('Showing full payment screenshot proof'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE5E7EB))),
                              child: Text('View Proof', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action Buttons (Reject vs Approve)
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => _rejectPayment(item['id']!, item['name']!),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _approvePayment(item['id']!, item['name']!, item['amount']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('✓ Approve & Send Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Modal 1: Rent Collection & Defaulters
  Widget _buildRentModalSheet() {
    return _buildModalWrapper(
      title: 'Rent Collection Hub',
      onClose: () => setState(() => _showRentModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6 tenants have pending rent dues for this cycle.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹51,500 Pending', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text('6 Defaulters • 0% UPI Fee', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _showRentModal = false);
                    _showToast('WhatsApp Payment Links sent to 6 Overdue Residents');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  child: Text('Send All', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showRentModal = false);
                _showToast('WhatsApp Payment Links sent to 6 Overdue Residents');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Send WhatsApp Payment Links', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 2: Log PG Expense
  Widget _buildExpenseModalSheet() {
    return _buildModalWrapper(
      title: 'Log PG Expense',
      onClose: () => setState(() => _showExpenseModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log daily expenses for groceries, water tankers, electricity, or repairs.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expenseAmountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Amount (e.g. ₹1,200)',
                    hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _expenseCategoryController,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Category (e.g. Water)',
                    hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showExpenseModal = false);
                _expenseAmountController.clear();
                _expenseCategoryController.clear();
                _showToast('Expense Logged Successfully');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Save Expense', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 3: Police KYC Hub
  Widget _buildPoliceModalSheet() {
    return _buildModalWrapper(
      title: 'Police KYC Hub',
      onClose: () => setState(() => _showPoliceModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Download pre-filled Karnataka Police (BCP) Tenant Verification forms for all active residents.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showPoliceModal = false);
                _showToast('BCP Police KYC Forms ZIP Downloaded');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Download All BCP Forms (ZIP)', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 4: Notice Periods
  Widget _buildNoticeModalSheet() {
    return _buildModalWrapper(
      title: 'Active Notice Periods',
      onClose: () => setState(() => _showNoticeModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3 residents are vacating this month. Beds ready for advance booking.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rahul Sharma (Room 102-C)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text('Vacating on 25 May (7 days left)', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showToast('WhatsApp Vacancy Flyer Generated'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE68A),
                    foregroundColor: const Color(0xFF92400E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  child: Text('Share Flyer', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showNoticeModal = false);
                _showToast('Vacancy flyer shared to WhatsApp');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Share Vacancy on WhatsApp', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 5: Maintenance Complaints
  Widget _buildComplaintsModalSheet() {
    return _buildModalWrapper(
      title: 'Maintenance & Complaints',
      onClose: () => setState(() => _showComplaintsModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Track active repair tickets raised by residents.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room 201: Geyser Not Heating', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Reported by Vikram A • 2 hours ago', style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showComplaintsModal = false);
                _showToast('Assigned to Electrician Ramesh');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Assign to Plumber / Electrician', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 6: Staff & Warden Roles
  Widget _buildStaffModalSheet() {
    return _buildModalWrapper(
      title: 'Staff & Warden Roles',
      onClose: () => setState(() => _showStaffModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage warden permissions and daily food mess headcount.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Warden Suresh', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text('Can check-in tenants • No Bank Access', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(4)),
                  child: Text('Active', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.greenDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showStaffModal = false);
                _showToast('Mess Headcount: 28 Veg / 7 Non-Veg');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text("View Today's Mess Headcount", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal 7: New Announcement Broadcast
  Widget _buildAnnouncementModalSheet() {
    return _buildModalWrapper(
      title: 'New Announcement',
      onClose: () => setState(() => _showAnnouncementModal = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Broadcast an instant push notification & portal alert to your residents.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 14),

          // Target Audience Dropdown
          Text('Target Audience', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _annTarget,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
            items: ['All Residents (31)', '1st Floor (8)', '2nd Floor (8)', '3rd Floor (8)', 'Ground Floor (7)']
                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.outfit(fontSize: 13))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _annTarget = val);
            },
          ),
          const SizedBox(height: 10),

          // Title Input
          Text('Announcement Title', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 4),
          TextField(
            controller: _annTitleController,
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'e.g. Water Tank Cleaning Tomorrow',
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 10),

          // Message Body
          Text('Announcement Message', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 4),
          TextField(
            controller: _annMsgController,
            maxLines: 3,
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Write your message here. Residents will receive an instant app notification...',
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _broadcastAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Send App Notification', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared Bottom Modal Sheet Wrapper
  Widget _buildModalWrapper({required String title, required Widget child, required VoidCallback onClose}) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Frosted Glass Blur Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          // Bottom Slide-up Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Icon(Icons.close, size: 16, color: AppColors.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Radial Arc Painter for Apple-Style Circular Occupancy Gauge
class RadialArcPainter extends CustomPainter {
  final double percentage; // 0.0 to 1.0 (e.g. 0.885)
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  RadialArcPainter({
    required this.percentage,
    required this.primaryColor,
    required this.trackColor,
    this.strokeWidth = 8.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Background Track Circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc starting from top (-pi / 2)
    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialArcPainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
