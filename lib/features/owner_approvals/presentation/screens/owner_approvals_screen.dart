import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen 7: 0% Direct UPI Payment Approvals & Verification Hub with Audit History.
/// Design System: Pure enterprise UrbanStay aesthetic (Stripe/Linear precision),
/// exact typography, no emojis, high-contrast monospace UTRs, proof viewer,
/// and live migration to Approval History tab upon approval.
class OwnerApprovalsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerApprovalsScreen({super.key, this.onBack});

  @override
  State<OwnerApprovalsScreen> createState() => _OwnerApprovalsScreenState();
}

class _OwnerApprovalsScreenState extends State<OwnerApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Pending Approvals, 1: Approval History
  String _selectedFloor = 'all'; // 'all', '1st', '2nd', '3rd', 'ground'

  // Active Pending Approvals
  final List<Map<String, dynamic>> _pendingApprovals = [
    {
      'id': 'appr_1',
      'name': 'Rahul Sharma',
      'initials': 'RS',
      'room': 'Room 101 (Bed A)',
      'floor': '1st',
      'amount': 8500,
      'phone': '9876543210',
      'utr': '4231 8976 5412',
      'time': '18 Aug • 2:34 PM',
      'app': 'Google Pay to HDFC',
      'proofFile': 'gpay_hdfc_transfer_proof.jpg',
    },
    {
      'id': 'appr_2',
      'name': 'Amit Verma',
      'initials': 'AV',
      'room': 'Room 101 (Bed B)',
      'floor': '1st',
      'amount': 8500,
      'phone': '9988776655',
      'utr': '8891 2345 0912',
      'time': '18 Aug • 3:12 PM',
      'app': 'PhonePe Transfer',
      'proofFile': 'phonepe_hdfc_receipt.png',
    },
    {
      'id': 'appr_3',
      'name': 'Priya Nair',
      'initials': 'PN',
      'room': 'Room 201 (Bed B)',
      'floor': '2nd',
      'amount': 9000,
      'phone': '9819876543',
      'utr': '9912 0045 8812',
      'time': '18 Aug • 4:05 PM',
      'app': 'Paytm UPI to HDFC',
      'proofFile': 'paytm_hdfc_transfer.png',
    },
  ];

  // Settled & Rejected Approval History
  final List<Map<String, dynamic>> _approvalHistory = [
    {
      'id': 'hist_1',
      'name': 'Karthik Raja',
      'initials': 'KR',
      'room': 'Room 201 (Bed A)',
      'floor': '2nd',
      'amount': 9000,
      'phone': '9741234567',
      'utr': '9912 0045 8812',
      'settledTime': '18 Aug • 1:15 PM',
      'status': 'approved',
      'receiptNo': 'REC-8901',
    },
    {
      'id': 'hist_2',
      'name': 'Suresh Gowda',
      'initials': 'SG',
      'room': 'Room G-01 (Bed A)',
      'floor': 'ground',
      'amount': 8000,
      'phone': '9844001122',
      'utr': '3388 1122 9900',
      'settledTime': '17 Aug • 6:40 PM',
      'status': 'approved',
      'receiptNo': 'REC-8899',
    },
    {
      'id': 'hist_3',
      'name': 'Tanmay Bhat',
      'initials': 'TB',
      'room': 'Room G-01 (Bed B)',
      'floor': 'ground',
      'amount': 8000,
      'phone': '9855112233',
      'utr': '1122 3344 5566',
      'settledTime': '16 Aug • 11:20 AM',
      'status': 'rejected',
      'rejectReason': 'Incorrect UTR number provided',
    },
  ];

  // Active Proof Target for Modal
  Map<String, dynamic>? _activeProofTarget;

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
  // ACTIONS: APPROVE & REJECT WITH AUDIT HISTORY MIGRATION
  // ===========================================================================
  void _approvePayment(Map<String, dynamic> item) {
    setState(() {
      _pendingApprovals.removeWhere((p) => p['id'] == item['id']);
      _approvalHistory.insert(0, {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'name': item['name'],
        'initials': item['initials'],
        'room': item['room'],
        'floor': item['floor'],
        'amount': item['amount'],
        'phone': item['phone'],
        'utr': item['utr'],
        'settledTime': 'Just now',
        'status': 'approved',
        'receiptNo': 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      });
    });
    _showToast('₹${item['amount']} Approved for ${item['name']}. Logged to History & Receipt sent via WhatsApp.');
  }

  void _rejectPayment(Map<String, dynamic> item) {
    setState(() {
      _pendingApprovals.removeWhere((p) => p['id'] == item['id']);
      _approvalHistory.insert(0, {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'name': item['name'],
        'initials': item['initials'],
        'room': item['room'],
        'floor': item['floor'],
        'amount': item['amount'],
        'phone': item['phone'],
        'utr': item['utr'],
        'settledTime': 'Just now',
        'status': 'rejected',
        'rejectReason': 'Declined by owner',
      });
    });
    _showToast('Payment rejected for ${item['name']}. Logged to History & Alert sent to resident.');
  }

  // ===========================================================================
  // MODAL: PROOF SCREENSHOT VIEWER (Native Bottom Sheet)
  // ===========================================================================
  void _openProofModal(Map<String, dynamic> item) {
    _activeProofTarget = item;
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
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['name']} — ₹${item['amount']}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'UTR Reference: ${item['utr']}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
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

              // Mock Payment Proof Card
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, size: 30, color: AppColors.greenDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paid to Arun Kumar',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'HDFC Bank Account ending in 8902',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${item['amount']}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'UPI Ref / UTR: ${item['utr']}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Close Preview',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Header
            _buildTopHeader(),

            // 2. Dual Tab Selector (Pending Approvals vs Approval History)
            _buildDualTabSelector(),

            // 3. Scrollable Body
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildPendingApprovalsView()
                  : _buildApprovalHistoryView(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Back Button
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

              // Title & Subtitle Block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Approvals',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '0% Fee Direct Bank Settlements',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Pending Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${_pendingApprovals.length} Pending',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DUAL TAB SELECTOR (Pending vs History)
  // ===========================================================================
  Widget _buildDualTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 0
                      ? const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Pending Approvals (${_pendingApprovals.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: _selectedTabIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                      color: _selectedTabIndex == 0 ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 1
                      ? const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Approval History (${_approvalHistory.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: _selectedTabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                      color: _selectedTabIndex == 1 ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. TAB 1: PENDING APPROVALS VIEW
  // ===========================================================================
  Widget _buildPendingApprovalsView() {
    final filtered = _pendingApprovals.where((p) {
      if (_selectedFloor != 'all' && p['floor'] != _selectedFloor) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Floor Filter Chips
          _buildFloorTabsScroll(),
          const SizedBox(height: 12),

          // Trust Info Strip
          _buildTrustStrip(),
          const SizedBox(height: 14),

          // Pending Approval Cards
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ...filtered.map((item) => _buildApprovalCard(item)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TAB 2: APPROVAL AUDIT HISTORY VIEW
  // ===========================================================================
  Widget _buildApprovalHistoryView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // History Subtitle Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Master Settlement Audit Log',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  '${_approvalHistory.length} Total Records',
                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // History Cards
          if (_approvalHistory.isEmpty)
            _buildEmptyState()
          else
            ..._approvalHistory.map((item) => _buildHistoryCard(item)),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-COMPONENTS: FLOOR TABS & TRUST STRIP
  // ===========================================================================
  Widget _buildFloorTabsScroll() {
    final floors = [
      {'id': 'all', 'label': 'All Floors'},
      {'id': '1st', 'label': '1st Floor'},
      {'id': '2nd', 'label': '2nd Floor'},
      {'id': '3rd', 'label': '3rd Floor'},
      {'id': 'ground', 'label': 'Ground Floor'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: floors.map((f) {
          final isSelected = _selectedFloor == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFloor = f['id']!),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrustStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Destination: ',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                'Arun Kumar (HDFC Bank)',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          Text(
            '0% Gateway Fee',
            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.greenDark),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PENDING APPROVAL CARD
  // ===========================================================================
  Widget _buildApprovalCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Avatar + Name + Room + Quick Phone/WhatsApp Contact Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 44px Avatar Initial Circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        item['initials'] ?? 'RS',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Room
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['room']} • ${item['floor']} Floor',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Contact Actions (Call & WhatsApp)
              Row(
                children: [
                  InkWell(
                    onTap: () => _showToast('Calling ${item['name']}: +91${item['phone']}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.phone_outlined, size: 16, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showToast('WhatsApp opened with ${item['name']}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Payment & Proof Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Transferred & Timestamp Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT TRANSFERRED',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '₹${item['amount']}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        item['time'],
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
                const SizedBox(height: 10),

                // UPI Reference (UTR) Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UPI Reference (UTR)',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    ),
                    Text(
                      item['utr'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Screenshot Proof Row with View Proof Trigger
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                'IMG',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['proofFile'],
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _openProofModal(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'View Proof',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: [ Reject ] and [ Approve & Send Receipt ]
          Row(
            children: [
              // Reject Button
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => _rejectPayment(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'Reject',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Approve & Send Receipt Button
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _approvePayment(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Approve & Send Receipt',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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
  // AUDIT HISTORY CARD
  // ===========================================================================
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final isApproved = item['status'] == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isApproved ? AppColors.greenLight : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isApproved ? AppColors.green.withValues(alpha: 0.25) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item['initials'] ?? 'KR',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isApproved ? AppColors.greenDark : AppColors.danger,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${item['room']} • ${item['settledTime']}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item['amount']}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isApproved ? AppColors.greenDark : AppColors.danger,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isApproved ? AppColors.greenLight : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isApproved ? 'Settled (0% Cut)' : 'Rejected',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isApproved ? AppColors.greenDark : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isApproved ? 'Receipt #${item['receiptNo']}' : '${item['rejectReason']}',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                Text(
                  'UTR: ${item['utr']}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'All Payments Approved',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'No pending approvals right now. New tenant payments will appear here automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
