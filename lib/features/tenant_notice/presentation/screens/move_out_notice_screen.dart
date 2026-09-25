import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen: Move-Out Notice (Digital Settlement Pass - Option 2 Final)
/// Features:
/// 1. Entire page background is pure white (#FFFFFF).
/// 2. Top Pass Header: MARUTHI LUXURY PG (Black) on left, BED 204-A (Green) on right.
/// 3. Move-in & Vacating timeline with Notice days (No tick marks).
/// 4. Deductions in warm yellow/amber (#D97706), no red, no sub-meter text.
/// 5. Custom sky-blue to white gradient card for PG & Property Buzz:
///    - Left: Official logo (assets/images/pgand property logo_4.jpeg).
///    - Right: Explore 500+ video-verified PGs / Powered by PG & Property Buzz + Visit ↗.
/// 6. Clean refund destination and reason selection (no black cards).
/// 7. Solid Emerald Green Submit CTA + Active Notice State.
class MoveOutNoticeScreen extends StatefulWidget {
  final String roomNumber;
  final String bedIdentifier;
  final String pgName;
  final double monthlyRent;
  final double securityDeposit;
  final bool initialIsActive;

  const MoveOutNoticeScreen({
    super.key,
    this.roomNumber = '204',
    this.bedIdentifier = 'A',
    this.pgName = 'MARUTHI LUXURY PG',
    this.monthlyRent = 11500.0,
    this.securityDeposit = 23000.0,
    this.initialIsActive = false,
  });

  @override
  State<MoveOutNoticeScreen> createState() => _MoveOutNoticeScreenState();
}

class _MoveOutNoticeScreenState extends State<MoveOutNoticeScreen> {
  bool _isNoticeActive = false;
  late DateTime _selectedVacateDate;
  int _noticeDaysServed = 31;
  String _selectedReason = 'Job Relocation';
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _upiController = TextEditingController(text: 'rahul@okhdfcbank');
  final FocusNode _upiFocusNode = FocusNode();

  // Deductions in warm amber/yellow
  final List<Map<String, dynamic>> _deductions = [
    {
      'title': 'Electricity Dues',
      'amount': 180.0,
    },
    {
      'title': 'Maintenance / Repair',
      'amount': 350.0,
    },
  ];

  static const List<String> _reasons = [
    'Job Relocation',
    'Moving to Flat',
    'College / Study Complete',
    'Returning to Hometown',
    'Other Reason',
  ];

  static const String _partnerUrl = 'https://www.pgandpropertybuzz.co.in/';

  @override
  void initState() {
    super.initState();
    _isNoticeActive = widget.initialIsActive;

    final now = DateTime.now();
    _selectedVacateDate = now.add(const Duration(days: 31));
    _calculateNoticeDays();
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    _upiController.dispose();
    _upiFocusNode.dispose();
    super.dispose();
  }

  void _calculateNoticeDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedVacateDate.year, _selectedVacateDate.month, _selectedVacateDate.day);
    setState(() {
      _noticeDaysServed = target.difference(today).inDays;
    });
  }

  double get _totalDeductions {
    return _deductions.fold(0.0, (sum, item) => sum + (item['amount'] as double));
  }

  double get _estimatedRefund {
    final balance = widget.securityDeposit - _totalDeductions;
    return balance > 0 ? balance : 0.0;
  }

  Future<void> _pickVacateDate() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 15));
    final maxDate = now.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedVacateDate.isBefore(minDate) ? minDate : _selectedVacateDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.green,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedVacateDate = picked;
      });
      _calculateNoticeDays();
    }
  }

  Future<void> _launchPartnerWebsite() async {
    final uri = Uri.parse(_partnerUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnackBar('Opening: $_partnerUrl');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Could not launch website: $_partnerUrl');
      }
    }
  }

  void _submitNotice() {
    final upi = _upiController.text.trim();
    if (upi.isEmpty || !upi.contains('@')) {
      _showSnackBar('Please enter a valid UPI ID for deposit refund.');
      return;
    }

    setState(() {
      _isNoticeActive = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Move-out notice submitted successfully to PG Owner.'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _withdrawNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Withdraw Notice?',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'This will cancel your move-out notice and retain your active stay in Room ${widget.roomNumber}-${widget.bedIdentifier}. The owner will be notified.',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Notice',
              style: GoogleFonts.outfit(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isNoticeActive = false;
              });
              _showSnackBar('Move-out notice withdrawn.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Withdraw Notice',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Pure White Background for Entire Page (No Gray)
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Move-Out Notice',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Notice State (if submitted)
              if (_isNoticeActive) ...[
                _buildActiveNoticeCard(),
                const SizedBox(height: 16),
              ],

              // 2. The Digital Settlement Pass
              _buildSettlementPass(),
              const SizedBox(height: 16),

              // 3. Reason for Leaving (Clean, no black pills)
              if (!_isNoticeActive) ...[
                Text(
                  'Reason for Leaving',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReasonPills(),
                const SizedBox(height: 16),
              ],

              // 4. PG & Property Buzz Relocation Card (Sky Blue Gradient Top to White)
              _buildPartnerRelocationCard(),
              const SizedBox(height: 16),

              // 5. Deposit Refund Destination Field
              if (!_isNoticeActive) ...[
                Text(
                  'Deposit Refund Destination',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _buildUpiInput(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Digital Settlement Pass Card (Option 2 Architecture)
  Widget _buildSettlementPass() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: MARUTHI LUXURY PG (Black) on left, BED 204-A (Green) on right
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.pgName,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink, // Black on left
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'BED ${widget.roomNumber}-${widget.bedIdentifier}',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green, // Green on right
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hairline Divider
          const Divider(color: Color(0xFFF3F4F6), height: 1, thickness: 1),

          // Timeline Row: Move-In on left, Vacating on right (No tick marks)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move-In Date',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '15 Jan 2026',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vacating Date',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                          ),
                          if (!_isNoticeActive)
                            GestureDetector(
                              onTap: _pickVacateDate,
                              child: Text(
                                'Change',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_selectedVacateDate),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      Text(
                        '($_noticeDaysServed Days Notice)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _noticeDaysServed >= 30 ? AppColors.greenDark : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                32,
                (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0 ? Colors.transparent : const Color(0xFFE5E7EB),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Financial Ledger Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Security Deposit',
                      style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${widget.securityDeposit.toInt()}',
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Deductions in Warm Amber/Yellow (#D97706), no red, no meter units
                ..._deductions.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d['title'] as String,
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '- ₹${(d['amount'] as double).toInt()}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFFD97706), // Warm yellow/amber
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: Color(0xFFF3F4F6), height: 16),

                // Net Refund Payable
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NET REFUND PAYABLE',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '₹${_estimatedRefund.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PG & Property Buzz Relocation Card
  /// Top: Darker Sky-Blue (#BAE6FD / #E0F2FE), fading down to Pure White (#FFFFFF) at the bottom
  /// Left: Logo image (assets/images/pgand property logo_4.jpeg)
  /// Right: Explore 500+ video-verified PGs across Bengaluru / Powered by PG & Property Buzz
  Widget _buildPartnerRelocationCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFBAE6FD), // Darker sky-blue at top
            Color(0xFFE0F2FE), // Soft transition
            Colors.white,      // Fades down to white at bottom
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag & External Visit Button (Arrow button ↗)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RELOCATION PARTNER',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0284C7),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              InkWell(
                onTap: _launchPartnerWebsite,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Visit',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Content: Logo on Left, Text on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Logo Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  color: Colors.white,
                  child: Image.asset(
                    'assets/images/pgand property logo_4.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Color(0xFF0284C7),
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Right: Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore 500+ video-verified PGs across Bengaluru',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Powered by PG & Property Buzz',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0369A1),
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

  Widget _buildReasonPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reasons.map((r) {
        final isSel = _selectedReason == r;
        return GestureDetector(
          onTap: () => setState(() => _selectedReason = r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.greenLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel ? AppColors.green : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            child: Text(
              r,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? AppColors.greenDark : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpiInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _upiController,
        focusNode: _upiFocusNode,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Enter UPI ID (e.g. rahul@okhdfcbank)',
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActiveNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NOTICE ACTIVE',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Text(
                '$_noticeDaysServed Days Remaining',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.greenDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Vacating on ${_formatDate(_selectedVacateDate)}',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Acknowledged by PG Owner • Refund will be sent to ${_upiController.text.trim()}',
            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: _withdrawNotice,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Withdraw / Cancel Notice',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isNoticeActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submitNotice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.green.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Submit Move-Out Notice',
              style: GoogleFonts.outfit(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
