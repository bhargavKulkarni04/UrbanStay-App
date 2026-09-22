import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tenant_payments/presentation/screens/rent_payment_screen.dart';
import '../../../tenant_payments/presentation/screens/paid_via_cash_screen.dart';
import '../../../tenant_payments/presentation/screens/payment_ledger_screen.dart';
import '../../../tenant_payments/presentation/screens/security_deposit_screen.dart';
import '../../../tenant_helpdesk/presentation/screens/raise_ticket_screen.dart';
import '../../../tenant_helpdesk/presentation/screens/ticket_status_screen.dart';
import '../../../tenant_helpdesk/presentation/screens/washing_machine_booking_screen.dart';
import '../../../tenant_housekeeping/presentation/widgets/room_sweep_sheet.dart';
import '../../../tenant_housekeeping/presentation/widgets/full_room_clean_sheet.dart';
import '../../../tenant_housekeeping/presentation/widgets/bedsheet_change_sheet.dart';

class TenantDashboardScreen extends StatefulWidget {
  final String tenantName;
  final String roomNumber;
  final String bedId;
  final String pgName;

  const TenantDashboardScreen({
    super.key,
    this.tenantName = 'Bhargav S Kulkarni',
    this.roomNumber = '104',
    this.bedId = 'B',
    this.pgName = 'UrbanStay Premium PG',
  });

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int _currentNavIndex = 0;
  String _paymentStatus =
      'DUE'; // 'DUE' | 'UNDER_REVIEW' | 'PAID_CYCLE_OCTOBER'
  String _submittedUtr = '425689123456';
  String _submittedPhone = '8618818322';
  String _submittedScreenshot = 'gpay_receipt_room104.jpg';
  String _currentCycleMonth = 'September 2026';
  String _currentDueDate = '05 Sep';
  final double _currentRentAmount = 8500.0;
  Map<String, dynamic>? _activeTicket;

  void _simulateOwnerApproval() {
    setState(() {
      _paymentStatus = 'PAID_CYCLE_OCTOBER';
      _currentCycleMonth = 'October 2026';
      _currentDueDate = '05 Oct';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 September 2026 rent approved by Arun Kumar! Next cycle updated to October 2026.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.greenDark,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transparent status bar for edge-to-edge header image integration
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🟢 1. Top Architectural Header with Smooth Curve
                _buildSmoothCurvedHeader(context),

                const SizedBox(height: 18),

                // 🔍 2. Clean Search Input Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),

                const SizedBox(height: 18),

                // ⚡ 3. Hero Rent Status & Pay Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHeroRentCard(),
                ),

                const SizedBox(height: 22),

                // 💳 4. Payments Card (Custom Stepped Folder Tab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPaymentsCard(),
                ),

                const SizedBox(height: 20),

                // 🛠️ 4. Helpdesk Card (Custom Stepped Folder Tab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHelpdeskCard(),
                ),

                const SizedBox(height: 20),

                // 🧹 5. Housekeeping & Services Card (Custom Stepped Folder Tab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHousekeepingCard(),
                ),

                const SizedBox(height: 20),

                // 🚪 7. Tenancy & Exit Card (Custom Stepped Folder Tab)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTenancyCard(),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔍 2. Clean Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search anything (eg. rent, maintenance, food...)',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ 3. Hero Rent Status & Pay Banner (Clean Executive Split Card)
  Widget _buildHeroRentCard() {
    final isUnderReview = _paymentStatus == 'UNDER_REVIEW';
    final isNextMonth = _paymentStatus == 'PAID_CYCLE_OCTOBER';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isUnderReview ? const Color(0xFFFDE68A) : const Color(0xFFE5E7EB),
          width: isUnderReview ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Cycle Title & Room/Bed Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnderReview
                    ? 'SEPTEMBER RENT SUBMITTED'
                    : (isNextMonth ? 'OCTOBER 2026 RENT' : 'SEPTEMBER RENT'),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color:
                      isUnderReview ? const Color(0xFFD97706) : AppColors.muted,
                ),
              ),

              // Prominent & Clearly Visible Room Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Room ${widget.roomNumber}',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Middle Split Row: Amount & Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Amount & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹8,500',
                      style: GoogleFonts.outfit(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: isUnderReview ? AppColors.ink : AppColors.green,
                        letterSpacing: -0.7,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isUnderReview) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Under Review by Arun Kumar',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'UTR: $_submittedUtr • +91 $_submittedPhone',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            isNextMonth
                                ? Icons.calendar_today_rounded
                                : Icons.access_time_rounded,
                            size: 13,
                            color: const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNextMonth
                                ? 'Due by $_currentDueDate'
                                : 'Due by 05 Sep',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      if (isNextMonth) ...[
                        const SizedBox(height: 2),
                        Text(
                          '✅ September Rent Cleared & Verified',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Column: Action Button
              GestureDetector(
                onTap: _openRentPaymentSheet,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUnderReview ? Colors.white : AppColors.green,
                    borderRadius: BorderRadius.circular(24),
                    border: isUnderReview
                        ? Border.all(color: const Color(0xFFD1D5DB), width: 1.2)
                        : null,
                    boxShadow: isUnderReview
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUnderReview) ...[
                        const Icon(
                          Icons.edit_outlined,
                          color: AppColors.ink,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit Proof',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Pay Rent',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hairline Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
          ),

          const SizedBox(height: 9),

          // 3. Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnderReview
                    ? 'Awaiting owner bank credit match'
                    : 'All-inclusive monthly stay',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              if (isUnderReview)
                InkWell(
                  onTap: _simulateOwnerApproval,
                  child: Text(
                    'Simulate Approval >',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                )
              else if (isNextMonth)
                Text(
                  'View Sep Receipt >',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenDark,
                  ),
                )
              else
                GestureDetector(
                  onTap: _openPaidViaCashScreen,
                  child: Text(
                    'Paid in cash? >',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 💳 4. Payments Card (Exact 4-Item Balanced Row)
  Widget _buildPaymentsCard() {
    return _FolderTabCard(
      tabWidth: 125,
      title: 'Payments',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.currency_rupee_rounded,
            label: 'Pay Rent\nvia UPI',
            onTap: _openRentPaymentSheet,
          ),
          _buildItemButton(
            icon: Icons.payments_outlined,
            label: 'Paid via\nCash',
            onTap: _openPaidViaCashScreen,
          ),
          _buildItemButton(
            icon: Icons.receipt_long_outlined,
            label: 'Payment\nLedger',
            onTap: _openPaymentLedger,
          ),
          _buildItemButton(
            icon: Icons.shield_outlined,
            label: 'Security\nDeposit',
            onTap: _openSecurityDeposit,
          ),
        ],
      ),
    );
  }

  Future<void> _openPaidViaCashScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaidViaCashScreen(
          roomNumber: widget.roomNumber,
          bedId: widget.bedId,
          pgName: widget.pgName,
          amount: _currentRentAmount,
          cycleMonth: _currentCycleMonth,
          ownerName: 'Arun Kumar',
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['status'] == 'UNDER_REVIEW') {
      setState(() {
        _paymentStatus = 'UNDER_REVIEW';
        _submittedUtr = 'CASH-${result['recipient']}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cash handover recorded with ${result['recipient']}. Awaiting owner audit ✓',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF111111),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPaymentLedger() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentLedgerScreen(
          roomNumber: widget.roomNumber,
          bedLabel: 'Bed ${widget.bedId}',
          propertyName: widget.pgName,
        ),
      ),
    );
  }

  void _openSecurityDeposit() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityDepositScreen(
          roomNumber: widget.roomNumber,
          bedLabel: 'Bed ${widget.bedId}',
          propertyName: widget.pgName,
        ),
      ),
    );
  }

  /// 🚀 Navigate to Full-Page Rent Payment Screen (Full Page Checkout)
  Future<void> _openRentPaymentSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentPaymentScreen(
          roomNumber: widget.roomNumber,
          bedId: widget.bedId,
          pgName: widget.pgName,
          ownerName: 'Arun Kumar',
          ownerUpiId: 'arun.kumar@oksbi',
          ownerBankName: 'State Bank of India (SBI)',
          amount: _currentRentAmount,
          cycleMonth: _currentCycleMonth,
          initialIsSubmitted: _paymentStatus == 'UNDER_REVIEW',
          initialUtr: _submittedUtr,
          initialPhone: _submittedPhone,
          initialScreenshot: _submittedScreenshot,
          onOwnerApproved: _simulateOwnerApproval,
          onUtrSubmitted: (utr) {
            setState(() {
              _paymentStatus = 'UNDER_REVIEW';
              _submittedUtr = utr;
            });
          },
        ),
      ),
    );

    if (result is Map) {
      if (result['status'] == 'UNDER_REVIEW') {
        setState(() {
          _paymentStatus = 'UNDER_REVIEW';
          if (result['utr'] != null && (result['utr'] as String).isNotEmpty) {
            _submittedUtr = result['utr'];
          }
          if (result['phone'] != null &&
              (result['phone'] as String).isNotEmpty) {
            _submittedPhone = result['phone'];
          }
          if (result['screenshot'] != null &&
              (result['screenshot'] as String).isNotEmpty) {
            _submittedScreenshot = result['screenshot'];
          }
        });
      } else if (result['status'] == 'APPROVED') {
        _simulateOwnerApproval();
      }
    }
  }

  /// 🛠️ 4. Helpdesk Card (4-Item Layout: Ticket, Status, Washing Machine, Rain Alert)
  Widget _buildHelpdeskCard() {
    return _FolderTabCard(
      tabWidth: 120,
      title: 'Helpdesk',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.edit_document,
            label: 'Raise a\nService Ticket',
            onTap: _openRaiseTicketScreen,
          ),
          _buildItemButton(
            icon: Icons.bar_chart_rounded,
            label: 'Live Repair\nStatus',
            onTap: _openLiveRepairStatus,
          ),
          _buildItemButton(
            icon: Icons.local_laundry_service_outlined,
            label: 'Washing Machine\nSlot Booking',
            onTap: _openWashingMachineBooking,
          ),
          _buildItemButton(
            icon: Icons.thunderstorm_outlined,
            label: 'Terrace\nRain Alert',
            onTap: _openRainAlert,
          ),
        ],
      ),
    );
  }

  void _openWashingMachineBooking() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WashingMachineBookingScreen(
          roomNumber: widget.roomNumber,
          bedId: widget.bedId,
        ),
      ),
    );
  }

  void _openRainAlert() {
    HapticFeedback.lightImpact();
    // Rain Alert screen handler
  }

  void _openLiveRepairStatus() {
    HapticFeedback.lightImpact();
    final ticket = _activeTicket ??
        {
          'id': 'TKT-104',
          'category': 'Electrical',
          'room': 'Room ${widget.roomNumber}',
          'bed': 'Bed ${widget.bedId}',
          'floor': '1st Floor',
          'issue': 'Geyser in bathroom is tripping MCB switch every 2 minutes.',
          'reportedDate': 'Today, 11:30 AM',
          'photoName': 'geyser_mcb_photo.jpg',
          'status': 'pending',
        };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketStatusScreen(
          ticketData: ticket,
          pgName: widget.pgName,
        ),
      ),
    );
  }

  Future<void> _openRaiseTicketScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaiseTicketScreen(
          residentName: widget.tenantName,
          roomNumber: widget.roomNumber,
          bedId: widget.bedId,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result.containsKey('id')) {
      setState(() {
        _activeTicket = Map<String, dynamic>.from(result);
      });
    }
  }

  /// 🧹 5. Housekeeping & Services Card
  Widget _buildHousekeepingCard() {
    return _FolderTabCard(
      tabWidth: 155,
      title: 'Housekeeping',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.cleaning_services_outlined,
            label: 'Room Sweep\nRequest',
            onTap: () {
              RoomSweepSheet.show(
                context,
                roomNumber: widget.roomNumber,
                pgName: widget.pgName,
              );
            },
          ),
          _buildItemButton(
            icon: Icons.wash_outlined,
            label: 'Full Room\nClean',
            onTap: () {
              FullRoomCleanSheet.show(
                context,
                roomNumber: widget.roomNumber,
                pgName: widget.pgName,
              );
            },
          ),
          _buildItemButton(
            icon: Icons.bed_outlined,
            label: 'Bedsheet\nChange',
            onTap: () {
              BedsheetChangeSheet.show(
                context,
                roomNumber: widget.roomNumber,
                pgName: widget.pgName,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🚪 6. Tenancy & Exit Card
  Widget _buildTenancyCard() {
    return _FolderTabCard(
      tabWidth: 165,
      title: 'Tenancy & Exit',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.article_outlined,
            label: 'Stay\nAgreement',
            onTap: () {},
          ),
          _buildItemButton(
            icon: Icons.event_busy_outlined,
            label: 'Move-Out\nNotice (30D)',
            onTap: () {},
          ),
          _buildItemButton(
            icon: Icons.payments_outlined,
            label: 'Deposit\nSettlement',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Single Action Item Button (Soft green circle + 2-line centered label)
  Widget _buildItemButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8EE), // Soft green circle (#EBF8EE)
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Bottom Navigation Bar matching the image
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavTab(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavTab(
                index: 1,
                icon: Icons.event_note_rounded,
                label: 'Food & Notices',
              ),
              _buildNavTab(
                index: 2,
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
              ),
              _buildNavTab(
                index: 3,
                icon: Icons.grid_view_rounded,
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentNavIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.green : AppColors.muted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.green : AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          if (isSelected)
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  /// Smart Initial Generator (e.g. "Bhargav S Kulkarni" -> "BK", "Joy Sen" -> "JS")
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'BK';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Dynamic font sizing so short and long names never wrap or break
  double _getNameFontSize(String name) {
    if (name.length <= 16) return 24.0;
    if (name.length <= 22) return 22.0;
    return 19.5;
  }

  /// 🟢 Top Header with Tenant_nameBG.png Background Image
  Widget _buildSmoothCurvedHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final initials = _getInitials(widget.tenantName);
    final nameFontSize = _getNameFontSize(widget.tenantName);

    return ClipPath(
      clipper: _SmoothHeaderClipper(),
      child: Stack(
        children: [
          // 1. Background Building Image from Assets
          Positioned.fill(
            child: Image.asset(
              'assets/images/Tenant_nameBG.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Subtle Darkening Gradient for 100% High-Contrast Text Legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),

          // 3. Foreground Header Content (Strictly matching reference image)
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: PG Name & Location (Left) + White BK Avatar (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.pgName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BTM Layout 2nd Stage, Bangalore',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Clean White Circular Avatar (Bold 'BK' initials)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // Greeting: "Welcome back,"
                Text(
                  'Welcome back,',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.90),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),

                // Resident Full Name (Auto-sized, 1-line lock)
                Text(
                  widget.tenantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 14),

                // Actionable Room Pill: [ 🛏️ Room 104 - Bed B  > ]
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.single_bed_rounded,
                          size: 16.5,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Room ${widget.roomNumber} - Bed ${widget.bedId}',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16.5,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🗂️ Reusable Stepped Folder-Tab Card Widget (Clean Title, No Icon)
class _FolderTabCard extends StatelessWidget {
  final double tabWidth;
  final String title;
  final Widget child;

  const _FolderTabCard({
    required this.tabWidth,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FolderTabPainter(tabWidth: tabWidth),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Folder Tab Header - Clean Bold Title (No Icon)
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(
                height: 20), // Generous vertical breathing space before buttons

            // Child Action Items
            child,
          ],
        ),
      ),
    );
  }
}

/// 📐 Custom Painter for the Stepped Folder Tab Silhouette
class _FolderTabPainter extends CustomPainter {
  final double tabWidth;
  final double shoulderDrop = 16.0;
  final Color backgroundColor = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);

  _FolderTabPainter({
    required this.tabWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const cornerRadius = 20.0;

    // Start at top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Across the top of the raised tab
    path.lineTo(tabWidth - 12, 0);

    // Smooth S-curve transition stepping down to the shoulder
    path.cubicTo(
      tabWidth + 4,
      0,
      tabWidth + 10,
      shoulderDrop,
      tabWidth + 24,
      shoulderDrop,
    );

    // Across the lower shoulder line to the top-right corner
    path.lineTo(size.width - cornerRadius, shoulderDrop);
    path.quadraticBezierTo(
        size.width, shoulderDrop, size.width, shoulderDrop + cornerRadius);

    // Down the right edge
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - cornerRadius, size.height);

    // Across the bottom edge
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Back up the left edge
    path.close();

    // Draw soft drop shadow
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.035),
      12.0,
      true,
    );

    // Fill with pure white
    final fillPaint = Paint()..color = backgroundColor;
    canvas.drawPath(path, fillPaint);

    // Stroke hairline border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderTabPainter oldDelegate) {
    return oldDelegate.tabWidth != tabWidth ||
        oldDelegate.shoulderDrop != shoulderDrop ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// 📐 Custom Clipper to produce the smooth downward curve matching the sketch
class _SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);

    final firstControlPoint = Offset(size.width / 2, size.height + 12);
    final firstEndPoint = Offset(size.width, size.height - 28);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
