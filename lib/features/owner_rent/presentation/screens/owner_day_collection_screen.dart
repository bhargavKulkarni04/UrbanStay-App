import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';

/// Screen 9th Quick Action: Dedicated Day-Wise Rent Collection & Salary Cycle Hub.
/// Features:
/// - Horizontal Salary Cycle Date Strip (1st, 2nd, 3rd, 5th, 7th, 10th, 15th).
/// - Dynamic Date Re-Scheduling (shifting tenant moves them to new date in real-time).
/// - Non-Green WhatsApp button styling (clean neutral outline).
/// - Verification Actions (View Proof, Reject, Accept).
/// - Comprehensive Chronological Audit & History Log.
class OwnerDayCollectionScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerDayCollectionScreen({super.key, this.onBack});

  @override
  State<OwnerDayCollectionScreen> createState() =>
      _OwnerDayCollectionScreenState();
}

class _OwnerDayCollectionScreenState extends State<OwnerDayCollectionScreen> {
  String _activeTab = 'schedule'; // 'schedule' or 'history'
  int _selectedDay = 1;
  String _selectedStaffActor = 'Ramesh Gowda (Manager)';
  final List<String> _staffActors = [
    'Ramesh Gowda (Manager)',
    'Arun Kumar (Co-Owner)',
    'Bhargav S Kulkarni (Owner)',
  ];

  String _historyFilter = 'all'; // 'all', 'payments', 'rescheduled', 'rejected'
  String _selectedFloor =
      'all'; // 'all', 'Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'

  String _formatSubtitle(Map<String, dynamic> tenant) {
    final floor = tenant['floor'] ?? '1st Floor';
    final sharing = tenant['sharing'] ?? '2-Sharing';
    String room = tenant['room'] ?? '';
    if (room.isEmpty) {
      final bedStr = (tenant['bed'] ?? '').toString();
      final clean = bedStr
          .replaceAll(RegExp(r'-[A-Za-z]$'), '')
          .replaceAll('Bed ', 'Room ');
      room = clean.isNotEmpty
          ? (clean.startsWith('Room') ? clean : 'Room $clean')
          : 'Room 101';
    }
    return '$floor • $sharing • $room';
  }

  // Master Tenant List with Explicit Salary Cycle Pay Dates
  final List<Map<String, dynamic>> _tenants = [
    {
      'id': 't1',
      'name': 'Rahul Sharma',
      'initials': 'RS',
      'bed': 'Room 101',
      'room': 'Room 101',
      'sharing': '2-Sharing',
      'floor': '1st Floor',
      'work': 'Infosys',
      'phone': '9876543210',
      'amount': 8500,
      'payDay': 1,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug via Direct UPI',
      'ref': 'UTR-423189765412',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't2',
      'name': 'Amit Verma',
      'initials': 'AV',
      'bed': 'Room 101',
      'room': 'Room 101',
      'sharing': '2-Sharing',
      'floor': '1st Floor',
      'work': 'Christ Univ',
      'phone': '9988776655',
      'amount': 8500,
      'payDay': 1,
      'status': 'overdue',
      'overdueDays': '3 Days Overdue',
      'dueLabel': 'Due since 15 Aug • All Utilities Included',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't3',
      'name': 'Suresh Gowda',
      'initials': 'SG',
      'bed': 'Room G-01',
      'room': 'Room G-01',
      'sharing': '2-Sharing',
      'floor': 'Ground Floor',
      'work': 'Flipkart',
      'phone': '9844001122',
      'amount': 8000,
      'payDay': 1,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug via Direct UPI',
      'ref': 'UTR-338811229900',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't4',
      'name': 'Ananya Roy',
      'initials': 'AR',
      'bed': 'Room 102',
      'room': 'Room 102',
      'sharing': '3-Sharing',
      'floor': '1st Floor',
      'work': 'Accenture',
      'phone': '9822334455',
      'amount': 7500,
      'payDay': 2,
      'status': 'paid',
      'paidLabel': 'Paid on 2 Aug via Direct UPI',
      'ref': 'UTR-110299384756',
      'paidDate': '2 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't5',
      'name': 'Manisha Patel',
      'initials': 'MP',
      'bed': 'Room 301',
      'room': 'Room 301',
      'sharing': '2-Sharing',
      'floor': '3rd Floor',
      'work': 'IBM',
      'phone': '9866443322',
      'amount': 8500,
      'payDay': 2,
      'status': 'paid',
      'paidLabel': 'Paid on 2 Aug via Direct UPI',
      'ref': 'UTR-554433221100',
      'paidDate': '2 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't6',
      'name': 'Vikram Rao',
      'initials': 'VR',
      'bed': 'Room 102',
      'room': 'Room 102',
      'sharing': '3-Sharing',
      'floor': '1st Floor',
      'work': 'TCS',
      'phone': '9733445566',
      'amount': 7500,
      'payDay': 3,
      'status': 'pending',
      'dueLabel': 'Salary Cycle 3rd • Awaiting UPI Transfer',
      'approvedBy': 'Arun Kumar (Co-Owner)',
    },
    {
      'id': 't7',
      'name': 'Tanmay Bhat',
      'initials': 'TB',
      'bed': 'Room G-01',
      'room': 'Room G-01',
      'sharing': '2-Sharing',
      'floor': 'Ground Floor',
      'work': 'Freelance',
      'phone': '9855112233',
      'amount': 8000,
      'payDay': 3,
      'status': 'overdue',
      'overdueDays': '7 Days Overdue',
      'dueLabel': 'Due since 11 Aug • Utilities Included',
      'approvedBy': 'Arun Kumar (Co-Owner)',
    },
    {
      'id': 't8',
      'name': 'Rohit Sen',
      'initials': 'RS',
      'bed': 'Room 103',
      'room': 'Room 103',
      'sharing': '2-Sharing',
      'floor': '1st Floor',
      'work': 'Wipro',
      'phone': '9811223344',
      'amount': 8500,
      'payDay': 5,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug (Direct UPI)',
      'ref': 'UTR-994411223344',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't9',
      'name': 'Naveen Kumar',
      'initials': 'NK',
      'bed': 'Room 103',
      'room': 'Room 103',
      'sharing': '2-Sharing',
      'floor': '1st Floor',
      'work': 'Razorpay',
      'phone': '9844119988',
      'amount': 8500,
      'payDay': 5,
      'status': 'paid',
      'paidLabel': 'Paid on 3 Aug (Direct UPI)',
      'ref': 'UTR-883311224455',
      'paidDate': '3 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't10',
      'name': 'Karthik Raja',
      'initials': 'KR',
      'bed': 'Room 201',
      'room': 'Room 201',
      'sharing': '2-Sharing',
      'floor': '2nd Floor',
      'work': 'Swiggy',
      'phone': '9741234567',
      'amount': 9000,
      'payDay': 5,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug (Direct UPI)',
      'ref': 'UTR-991200458812',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Bhargav S Kulkarni (Owner)',
    },
    {
      'id': 't11',
      'name': 'Priya Nair',
      'initials': 'PN',
      'bed': 'Room 201',
      'room': 'Room 201',
      'sharing': '2-Sharing',
      'floor': '2nd Floor',
      'work': 'Dell',
      'phone': '9819876543',
      'amount': 9000,
      'payDay': 5,
      'status': 'paid',
      'paidLabel': 'Paid on 3 Aug (Cash)',
      'ref': 'CSH-8902',
      'paidDate': '3 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't12',
      'name': 'Nikhil Kamath',
      'initials': 'NK',
      'bed': 'Room G-02',
      'room': 'Room G-02',
      'sharing': 'Single Room',
      'floor': 'Ground Floor',
      'work': 'Zerodha',
      'phone': '9899001122',
      'amount': 8500,
      'payDay': 5,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug (Direct UPI)',
      'ref': 'UTR-990011223344',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Bhargav S Kulkarni (Owner)',
    },
    {
      'id': 't13',
      'name': 'Rohan Patil',
      'initials': 'RP',
      'bed': 'Room 202',
      'room': 'Room 202',
      'sharing': '2-Sharing',
      'floor': '2nd Floor',
      'work': 'Wipro',
      'phone': '9811223344',
      'amount': 7500,
      'payDay': 7,
      'status': 'overdue',
      'overdueDays': '5 Days Overdue',
      'dueLabel': 'Due since 13 Aug • All Utilities Included',
      'approvedBy': 'Arun Kumar (Co-Owner)',
    },
    {
      'id': 't14',
      'name': 'Sneha Reddy',
      'initials': 'SR',
      'bed': 'Room 202',
      'room': 'Room 202',
      'sharing': '2-Sharing',
      'floor': '2nd Floor',
      'work': 'Amazon',
      'phone': '9845009988',
      'amount': 7500,
      'payDay': 7,
      'status': 'paid',
      'paidLabel': 'Paid on 4 Aug (Direct UPI)',
      'ref': 'UTR-772288119933',
      'paidDate': '4 Aug 2026',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't15',
      'name': 'Deepak Joshi',
      'initials': 'DJ',
      'bed': 'Room 301',
      'room': 'Room 301',
      'sharing': '2-Sharing',
      'floor': '3rd Floor',
      'work': 'Oracle',
      'phone': '9877112233',
      'amount': 8500,
      'payDay': 10,
      'status': 'pending',
      'dueLabel': 'Extension Requested till 15 Aug',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
    {
      'id': 't16',
      'name': 'Aditya Sen',
      'initials': 'AS',
      'bed': 'Room 302',
      'room': 'Room 302',
      'sharing': '2-Sharing',
      'floor': '3rd Floor',
      'work': 'Razorpay',
      'phone': '9811883377',
      'amount': 8000,
      'payDay': 10,
      'status': 'paid',
      'paidLabel': 'Paid on 1 Aug (Direct UPI)',
      'ref': 'UTR-883399221100',
      'paidDate': '1 Aug 2026',
      'approvedBy': 'Bhargav S Kulkarni (Owner)',
    },
    {
      'id': 't17',
      'name': 'Pooja Hegde',
      'initials': 'PH',
      'bed': 'Room 302',
      'room': 'Room 302',
      'sharing': '2-Sharing',
      'floor': '3rd Floor',
      'work': 'Capgemini',
      'phone': '9833557799',
      'amount': 8000,
      'payDay': 15,
      'status': 'overdue',
      'overdueDays': '6 Days Overdue',
      'dueLabel': 'Due since 12 Aug • Utilities Included',
      'approvedBy': 'Ramesh Gowda (Manager)',
    },
  ];

  // Master History & Audit Log
  final List<Map<String, dynamic>> _historyLogs = [
    {
      'id': 'h1',
      'type': 'payment_verified',
      'title': '₹8,500 Direct UPI Verified',
      'tenant': 'Rahul Sharma • 1st Floor • 2-Sharing • Room 101',
      'phone': '9876543210',
      'actor': 'Ramesh Gowda (Manager)',
      'time': '1 Aug 2026, 09:35 AM',
      'ref': 'UTR-423189765412',
      'badge': 'Paid Early',
    },
    {
      'id': 'h2',
      'type': 'rescheduled',
      'title': 'Salary Pay Date Changed: 5th ➔ 10th',
      'tenant': 'Aditya Sen • 3rd Floor • 2-Sharing • Room 302',
      'phone': '9811883377',
      'actor': 'Bhargav S Kulkarni (Owner)',
      'time': '1 Aug 2026, 11:20 AM',
      'reason': 'Salary credit cycle confirmed on 10th by Razorpay HR',
      'badge': 'Re-Scheduled',
    },
    {
      'id': 'h3',
      'type': 'payment_verified',
      'title': '₹8,000 Direct UPI Verified',
      'tenant': 'Suresh Gowda • Ground Floor • 2-Sharing • Room G-01',
      'phone': '9844001122',
      'actor': 'Ramesh Gowda (Manager)',
      'time': '1 Aug 2026, 02:15 PM',
      'ref': 'UTR-338811229900',
      'badge': 'Paid on Time',
    },
    {
      'id': 'h4',
      'type': 'payment_verified',
      'title': '₹7,500 Direct UPI Verified',
      'tenant': 'Ananya Roy • 1st Floor • 3-Sharing • Room 102',
      'phone': '9822334455',
      'actor': 'Ramesh Gowda (Manager)',
      'time': '2 Aug 2026, 10:00 AM',
      'ref': 'UTR-110299384756',
      'badge': 'Paid on Time',
    },
    {
      'id': 'h5',
      'type': 'rejected',
      'title': 'Payment Rejected (Not Credited in Bank)',
      'tenant': 'Tanmay Bhat • Ground Floor • 2-Sharing • Room G-01',
      'phone': '9855112233',
      'actor': 'Arun Kumar (Co-Owner)',
      'time': '3 Aug 2026, 04:45 PM',
      'reason': 'UTR 9988221100 invalid - not reflected in HDFC Bank',
      'badge': 'Rejected',
    },
  ];

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultDays = [1, 2, 3, 5, 7, 10, 15, 20, 25];
    final tenantDays = _tenants.map((t) => (t['payDay'] as int)).toList();
    final availableDays = {...defaultDays, ...tenantDays}.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Header
            _buildTopHeader(),

            // 2. Tab Bar: Daily Schedule vs Collection History
            _buildTopTabs(),

            // 3. Main Content View
            Expanded(
              child: _activeTab == 'schedule'
                  ? _buildScheduleContent(availableDays)
                  : _buildHistoryContent(),
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
        border:
            Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Day-Wise Collection',
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
                        'Greenview PG • Salary Cycle Calendar',
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
          ),
          const SizedBox(width: 8),

          // Active Staff Actor Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined,
                    size: 12, color: AppColors.greenDark),
                const SizedBox(width: 4),
                Text(
                  _selectedStaffActor.split(' ')[0], // First name
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. TOP TABS: SCHEDULE VS HISTORY
  // ===========================================================================
  Widget _buildTopTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2))),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 'schedule'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'schedule'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'schedule'
                        ? const [
                            BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: _activeTab == 'schedule'
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Salary Schedule',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'schedule'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'schedule'
                                ? AppColors.greenDark
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 'history'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'history'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'history'
                        ? const [
                            BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: _activeTab == 'history'
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Audit & History (${_historyLogs.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'history'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'history'
                                ? AppColors.ink
                                : AppColors.muted,
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
      ),
    );
  }

  // ===========================================================================
  // 3. SCHEDULE CONTENT VIEW
  // ===========================================================================
  Widget _buildFloorFilterChip(String id, String label) {
    final isSel = _selectedFloor == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFloor = id),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSel ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: isSel ? AppColors.ink : const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent(List<int> availableDays) {
    final selectedTenants = _tenants.where((t) {
      final matchesDay = (t['payDay'] as int) == _selectedDay;
      final matchesFloor =
          _selectedFloor == 'all' || t['floor'] == _selectedFloor;
      return matchesDay && matchesFloor;
    }).toList();
    final dayTotalExpected =
        selectedTenants.fold<int>(0, (sum, t) => sum + (t['amount'] as int));
    final dayPaidCount =
        selectedTenants.where((t) => t['status'] == 'paid').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        14,
        context.responsiveHorizontalPadding,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Floor Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                _buildFloorFilterChip('all', 'All Floors'),
                _buildFloorFilterChip('Ground Floor', 'Ground Floor'),
                _buildFloorFilterChip('1st Floor', '1st Floor'),
                _buildFloorFilterChip('2nd Floor', '2nd Floor'),
                _buildFloorFilterChip('3rd Floor', '3rd Floor'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Interactive Date Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: availableDays.map((d) {
                final count = _tenants.where((t) {
                  final matchesDay = (t['payDay'] as int) == d;
                  final matchesFloor =
                      _selectedFloor == 'all' || t['floor'] == _selectedFloor;
                  return matchesDay && matchesFloor;
                }).length;
                final isSel = _selectedDay == d;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDay = d),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.green : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSel ? AppColors.green : const Color(0xFFE5E7EB),
                          width: isSel ? 1.5 : 1.0,
                        ),
                        boxShadow: isSel
                            ? const [
                                BoxShadow(
                                    color: Color(0x1808A63F),
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${d}th',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isSel ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count Beds',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Selected Day Cashflow Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedDay}th of Month (Salary Cycle)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedTenants.length} Tenants • $dayPaidCount Paid • ${selectedTenants.length - dayPaidCount} Due',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹$dayTotalExpected',
                  style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tenant Cards for the Selected Day
          if (selectedTenants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Center(
                child: Text(
                  'No tenants scheduled for ${_selectedDay}th of the month.',
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                ),
              ),
            )
          else
            ...selectedTenants.map((t) => _buildTenantCard(t)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TENANT CARD (With Neutral WhatsApp & Verification Actions)
  // ===========================================================================
  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final isPaid = tenant['status'] == 'paid';
    final isOverdue = tenant['status'] == 'overdue';
    final String approvedBy = tenant['approvedBy'] ?? _selectedStaffActor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.green.withValues(alpha: 0.3)
              : isOverdue
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Avatar + Name + Bed + Rent Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.greenLight
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          tenant['initials'] ?? 'TN',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isPaid ? AppColors.greenDark : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant['name'] ?? 'Resident',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSubtitle(tenant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '₹${tenant['amount']}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isPaid ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Verification / Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              children: [
                Icon(
                  isPaid
                      ? Icons.verified_user_outlined
                      : Icons.schedule_rounded,
                  size: 13,
                  color: isPaid ? AppColors.greenDark : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPaid
                        ? 'Verified by $approvedBy • Paid on ${tenant['paidDate'] ?? '1 Aug'}'
                        : isOverdue
                            ? 'Agreed Date: ${_selectedDay}th • Overdue (${tenant['overdueDays'] ?? 'Pending'})'
                            : 'Agreed Salary Date: ${_selectedDay}th • Due Today (No Late Fine)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.greenDark : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ROW 1: Call & WhatsApp Side-by-Side (Clean Outlined Neutral, NOT Dark Green!)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showToast('Calling +91 ${tenant['phone']}...'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/phone.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'WhatsApp Chat opened with ${tenant['name']} (+91 ${tenant['phone']}) ✓'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/whatsapp.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ROW 2: If Paid -> Full-Width Change Date (Receipt Removed)
          //        If Not Paid -> View Proof, Reject, Accept
          if (isPaid)
            InkWell(
              onTap: () => _openChangePayDateModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'PAID',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paid on ${tenant['paidDate'] ?? '1 Aug 2026'}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Verification Bar: View Proof, Reject, and Accept
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => _openViewProofModal(tenant),
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: AppColors.ink),
                    label: Text(
                      'View Proof',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => _openRejectPaymentModal(tenant),
                    icon: const Icon(Icons.close_rounded,
                        size: 13, color: Color(0xFFDC2626)),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] =
                            'Paid on ${_selectedDay} Aug (Verified by $_selectedStaffActor)';
                        tenant['ref'] =
                            'UTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                        tenant['paidDate'] = '${_selectedDay} Aug 2026';
                        tenant['approvedBy'] = _selectedStaffActor;

                        _historyLogs.insert(0, {
                          'id': 'h_${DateTime.now().millisecondsSinceEpoch}',
                          'type': 'payment_verified',
                          'title': '₹${tenant['amount']} Direct UPI Verified',
                          'tenant': '${tenant['name']} (${tenant['bed']})',
                          'actor': _selectedStaffActor,
                          'time': 'Just now',
                          'ref': tenant['ref'],
                          'badge': 'Paid on Time',
                        });
                      });
                      _showToast(
                          'Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                    },
                    icon: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Secondary: Record Cash / Re-Schedule Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openRecordCashModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Record Cash Instead',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openChangePayDateModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Change Pay Date',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'DUE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant['overdueDays'] ??
                        (isOverdue ? 'Overdue' : 'Due Today'),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. HISTORY & AUDIT LOG CONTENT VIEW
  // ===========================================================================
  Widget _buildHistoryContent() {
    final filtered = _historyLogs.where((log) {
      if (_historyFilter == 'payments')
        return log['type'] == 'payment_verified';
      if (_historyFilter == 'rescheduled') return log['type'] == 'rescheduled';
      if (_historyFilter == 'rejected') return log['type'] == 'rejected';
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        14,
        context.responsiveHorizontalPadding,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips (All, Payments, Date Changed, Rejected)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                _buildHistoryFilterChip(
                    'all', 'All Audit Logs (${_historyLogs.length})'),
                _buildHistoryFilterChip('payments', 'Payments Verified'),
                _buildHistoryFilterChip('rescheduled', 'Date Changes'),
                _buildHistoryFilterChip('rejected', 'Rejected'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Center(
                child: Text('No audit records found.',
                    style: GoogleFonts.outfit(color: AppColors.muted)),
              ),
            )
          else
            ...filtered.map((log) => _buildHistoryCard(log)),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterChip(String id, String label) {
    final isSel = _historyFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _historyFilter = id),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSel ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: isSel ? AppColors.ink : const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final isPayment = log['type'] == 'payment_verified';
    final isRescheduled = log['type'] == 'rescheduled';
    final isRejected = log['type'] == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPayment
                            ? AppColors.greenLight
                            : isRescheduled
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPayment
                            ? Icons.check_circle_outline_rounded
                            : isRescheduled
                                ? Icons.calendar_today_outlined
                                : Icons.cancel_outlined,
                        size: 15,
                        color: isPayment
                            ? AppColors.greenDark
                            : isRescheduled
                                ? const Color(0xFFB45309)
                                : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log['title'],
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPayment
                      ? AppColors.greenLight
                      : isRescheduled
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log['badge'],
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isPayment
                        ? AppColors.greenDark
                        : isRescheduled
                            ? const Color(0xFFB45309)
                            : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log['tenant'],
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          if (log['ref'] != null)
            Text(
              'Reference: ${log['ref']}',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted),
            ),
          if (log['reason'] != null)
            Text(
              'Note: ${log['reason']}',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Action By: ${log['actor']}',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
                Text(
                  log['time'],
                  style: GoogleFonts.outfit(
                      fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mandatory Call & WhatsApp buttons for Audit Log
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final phone = log['phone'] ?? '9876543210';
                    _showToast('Calling +91 $phone...');
                  },
                  icon: const Icon(Icons.phone_outlined,
                      size: 13, color: AppColors.ink),
                  label: Text(
                    'Call',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final phone = log['phone'] ?? '9876543210';
                    _showToast('WhatsApp Chat opened (+91 $phone) ✓');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.ink),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
  // MODALS
  // ===========================================================================

  // Modal: View Proof
  void _openViewProofModal(Map<String, dynamic> tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Payment Proof: ${tenant['name']}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildRow(
                        'Resident:', '${tenant['name']} (${tenant['bed']})',
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildRow('Amount Claimed:', '₹${tenant['amount']}',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildRow('Payment Mode:', 'Direct UPI / PhonePe'),
                    const SizedBox(height: 8),
                    _buildRow('Submitted UTR / Ref:',
                        tenant['ref'] ?? 'UTR-423189765412',
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildRow('Submission Time:', '1 Aug 2026, 09:30 AM'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please verify that ₹${tenant['amount']} was credited to your HDFC/SBI bank account before accepting.',
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openRejectPaymentModal(tenant);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Reject Payment',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          tenant['status'] = 'paid';
                          tenant['paidLabel'] =
                              'Paid on ${_selectedDay} Aug (Verified by $_selectedStaffActor)';
                          tenant['ref'] = 'UTR-423189765412';
                          tenant['paidDate'] = '${_selectedDay} Aug 2026';
                          tenant['approvedBy'] = _selectedStaffActor;

                          _historyLogs.insert(0, {
                            'id': 'h_${DateTime.now().millisecondsSinceEpoch}',
                            'type': 'payment_verified',
                            'title': '₹${tenant['amount']} Direct UPI Verified',
                            'tenant': '${tenant['name']} (${tenant['bed']})',
                            'actor': _selectedStaffActor,
                            'time': 'Just now',
                            'ref': 'UTR-423189765412',
                            'badge': 'Paid on Time',
                          });
                        });
                        _showToast(
                            'Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept & Mark Paid',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Modal: Structured Payment Rejection
  void _openRejectPaymentModal(Map<String, dynamic> tenant) {
    String selectedReason = 'Money Not Credited in Bank Account';
    final customNoteCtrl = TextEditingController();
    final List<String> reasons = [
      'Money Not Credited in Bank Account',
      'Incorrect / Invalid 12-Digit UTR Number',
      'Partial Amount Paid (Shortfall)',
      'Payment Sent to Wrong UPI Account',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildBottomSheetWrapper(
              title: 'Reject Payment: ${tenant['name']}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tenant['name']} (${tenant['bed']})',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF991B1B)),
                            ),
                            Text(
                              'Claimed Amount: ₹${tenant['amount']} • ${tenant['ref'] ?? 'UTR-Pending'}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UNVERIFIED',
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Rejection Reason (Sent to Resident):',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => setModalState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: isSel
                                    ? const Color(0xFFDC2626)
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFF991B1B)
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text(
                    'Additional Note (Optional):',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: customNoteCtrl,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.ink),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Please resend proof from bank passbook',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final finalReason = customNoteCtrl.text.trim().isNotEmpty
                          ? '$selectedReason - ${customNoteCtrl.text.trim()}'
                          : selectedReason;

                      setState(() {
                        _historyLogs.insert(0, {
                          'id': 'h_${DateTime.now().millisecondsSinceEpoch}',
                          'type': 'rejected',
                          'title': 'Payment Rejected ($selectedReason)',
                          'tenant': '${tenant['name']} (${tenant['bed']})',
                          'actor': _selectedStaffActor,
                          'time': 'Just now',
                          'reason': finalReason,
                          'badge': 'Declined',
                        });
                      });
                      Navigator.of(ctx).pop();
                      _showToast(
                          'Payment rejected: Alert sent to ${tenant['name']} on WhatsApp ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Rejection & Send Alert',
                      style: GoogleFonts.outfit(
                          fontSize: 13.5, fontWeight: FontWeight.w800),
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

  // Modal: Re-Assign Monthly Pay Date (Dynamic Date Movement)
  void _openChangePayDateModal(Map<String, dynamic> tenant) {
    int currentDay = (tenant['payDay'] as int?) ?? 1;
    int selectedDay = currentDay;
    final reasonCtrl =
        TextEditingController(text: 'Salary credited on ${selectedDay}th');
    final List<int> quickDays = [1, 2, 3, 5, 7, 10, 15, 20, 25];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildBottomSheetWrapper(
              title: 'Re-Schedule Pay Date: ${tenant['name']}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${tenant['bed']} • Current Agreed Pay Date: ${currentDay}th of month',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Text('Select New Monthly Pay Date',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickDays.map((d) {
                      final isSel = selectedDay == d;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedDay = d;
                            reasonCtrl.text =
                                'Salary credited on ${d}th of every month';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.greenLight
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.green
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '${d}th of Month',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color:
                                  isSel ? AppColors.greenDark : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Reason / Notes',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Salary credited on 10th from employer',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        tenant['payDay'] = selectedDay;
                        _selectedDay =
                            selectedDay; // Automatically move user to new scheduled date view!

                        _historyLogs.insert(0, {
                          'id': 'h_${DateTime.now().millisecondsSinceEpoch}',
                          'type': 'rescheduled',
                          'title':
                              'Salary Pay Date Changed: ${currentDay}th ➔ ${selectedDay}th',
                          'tenant': '${tenant['name']} (${tenant['bed']})',
                          'actor': _selectedStaffActor,
                          'time': 'Just now',
                          'reason': reasonCtrl.text.trim(),
                          'badge': 'Re-Scheduled',
                        });
                      });
                      _showToast(
                          'Moved ${tenant['name']} to ${selectedDay}th of month (Audit Logged) ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Move to ${selectedDay}th of Month',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal: Record Cash Payment
  void _openRecordCashModal(Map<String, dynamic> tenant) {
    final amountCtrl = TextEditingController(text: tenant['amount'].toString());
    final notesCtrl =
        TextEditingController(text: 'Paid cash at reception desk');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Record Cash: ${tenant['name']}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Amount Received (₹)',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
              ),
              const SizedBox(height: 14),
              Text('Verified By',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStaffActor,
                    isExpanded: true,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    items: _staffActors
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedStaffActor = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final amt = int.tryParse(amountCtrl.text.trim()) ??
                      (tenant['amount'] as int);
                  Navigator.of(ctx).pop();
                  setState(() {
                    tenant['status'] = 'paid';
                    tenant['paidLabel'] =
                        'Paid in Cash (Verified by $_selectedStaffActor)';
                    tenant['ref'] =
                        'CSH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    tenant['paidDate'] = '${_selectedDay} Aug 2026';
                    tenant['approvedBy'] = _selectedStaffActor;

                    _historyLogs.insert(0, {
                      'id': 'h_${DateTime.now().millisecondsSinceEpoch}',
                      'type': 'payment_verified',
                      'title': '₹$amt Cash Payment Verified',
                      'tenant': '${tenant['name']} (${tenant['bed']})',
                      'actor': _selectedStaffActor,
                      'time': 'Just now',
                      'ref': tenant['ref'],
                      'badge': 'Cash Settled',
                    });
                  });
                  _showToast(
                      '₹$amt Cash recorded for ${tenant['name']} by $_selectedStaffActor ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Confirm & Mark Paid',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Modal: View Stamped Receipt
  void _openReceiptModal(Map<String, dynamic> tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Digital Rent Receipt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildRow('Tenant Name:', tenant['name'], isBold: true),
                    const SizedBox(height: 8),
                    _buildRow('Room / Bed:', tenant['bed']),
                    const SizedBox(height: 8),
                    _buildRow('Month / Period:', 'August 2026'),
                    const SizedBox(height: 8),
                    _buildRow('Amount Paid:', '₹${tenant['amount']}',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildRow(
                        'Transaction Ref:', tenant['ref'] ?? 'UTR-423189765412',
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildRow('Date of Payment:',
                        tenant['paidDate'] ?? '${_selectedDay} Aug 2026'),
                    const SizedBox(height: 8),
                    _buildRow('Verified By:',
                        tenant['approvedBy'] ?? _selectedStaffActor),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Receipt PDF Downloaded ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Download PDF Receipt',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetWrapper(
      {required String title, required Widget child}) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom + 16
        : mediaQuery.padding.bottom + 32;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child:
                            Icon(Icons.close, size: 14, color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
