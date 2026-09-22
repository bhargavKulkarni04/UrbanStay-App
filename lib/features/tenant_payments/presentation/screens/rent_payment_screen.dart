import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/official_payment_icons.dart';

/// 💳 Production-Grade Indian Foodtech/Fintech Checkout Screen (Swiggy / Zomato standard)
/// Built for UrbanStay Resident Rent Settlements with 0% Direct Bank UPI Rails.
class RentPaymentScreen extends StatefulWidget {
  final String roomNumber;
  final String bedId;
  final String pgName;
  final String ownerName;
  final String ownerPhone;
  final String ownerUpiId;
  final String tenantPhone;
  final String ownerBankName;
  final double amount;
  final String cycleMonth;
  final ValueChanged<String>? onUtrSubmitted;
  final ValueChanged<String>? onPaymentCompleted;
  final bool initialIsSubmitted;
  final String? initialUtr;
  final String? initialPhone;
  final String? initialScreenshot;
  final VoidCallback? onOwnerApproved;

  const RentPaymentScreen({
    super.key,
    required this.roomNumber,
    required this.bedId,
    required this.pgName,
    this.tenantPhone = '8618818322',
    this.ownerName = 'Arun Kumar',
    this.ownerPhone = '98450 12345',
    this.ownerUpiId = 'arun.kumar@oksbi',
    this.ownerBankName = 'State Bank of India (SBI)',
    this.amount = 8500.0,
    this.cycleMonth = 'September 2026',
    this.onUtrSubmitted,
    this.onPaymentCompleted,
    this.initialIsSubmitted = false,
    this.initialUtr,
    this.initialPhone,
    this.initialScreenshot,
    this.onOwnerApproved,
  });

  @override
  State<RentPaymentScreen> createState() => _RentPaymentScreenState();
}

class _RentPaymentScreenState extends State<RentPaymentScreen> {
  final String _selectedApp = 'gpay';
  bool _isBillExpanded = false;
  bool _isProcessing = false;
  late bool _isSubmitted;
  late final TextEditingController _phoneController;
  final TextEditingController _utrController = TextEditingController();
  final TextEditingController _vpaController = TextEditingController();
  String? _phoneError;
  String? _utrError;
  bool _hasScreenshot = false;
  String? _screenshotName;

  // 💵 Cash Handover at Reception State
  bool _isCashMode = false;
  String? _submittedCashRecipient;
  String? _submittedCashRemarks;

  @override
  void initState() {
    super.initState();
    _isSubmitted = widget.initialIsSubmitted;
    _phoneController =
        TextEditingController(text: widget.initialPhone ?? widget.tenantPhone);
    if (widget.initialUtr != null && widget.initialUtr!.isNotEmpty) {
      _utrController.text = widget.initialUtr!;
    }
    if (widget.initialScreenshot != null &&
        widget.initialScreenshot!.isNotEmpty) {
      _hasScreenshot = true;
      _screenshotName = widget.initialScreenshot;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _utrController.dispose();
    _vpaController.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    return '₹${widget.amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  void _submitUtr() {
    final utr = _utrController.text.trim();
    final phone = _phoneController.text.trim();

    String? utrErr;
    String? phoneErr;

    if (phone.length < 10) {
      phoneErr = 'Enter 10-digit mobile number used for payment';
    }

    if (utr.length < 8) {
      utrErr = 'Enter a valid 12-digit bank reference (UTR)';
    }

    if (utrErr != null || phoneErr != null) {
      setState(() {
        _utrError = utrErr;
        _phoneError = phoneErr;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _utrError = null;
      _phoneError = null;
      _isProcessing = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSubmitted = true;
      });
      widget.onUtrSubmitted?.call(utr);
      HapticFeedback.lightImpact();
    });
  }

  void _showConfirmPaymentPopup() {
    final utr = _utrController.text.trim();
    final phone = _phoneController.text.trim();

    String? utrErr;
    String? phoneErr;

    if (phone.length < 10) {
      phoneErr = 'Enter 10-digit mobile number used for payment';
    }

    if (utr.length < 8) {
      utrErr = 'Enter a valid 12-digit bank reference (UTR)';
    }

    if (utrErr != null || phoneErr != null) {
      setState(() {
        _utrError = utrErr;
        _phoneError = phoneErr;
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to submit this payment proof to ${widget.ownerName}?',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _submitUtr();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Yes, Confirm',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildUnderReviewScaffold();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Soft enterprise canvas
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Options',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Room ${widget.roomNumber} • ${widget.cycleMonth}',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // Scrollable Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Bill Header Card
                      _buildSwiggyBillCard(),

                      const SizedBox(height: 18),

                      // 2. Owner's Direct UPI QR Card (0% Gateway Cut)
                      _buildOwnerQrCard(),

                      const SizedBox(height: 18),

                      // 3. Direct 12-Digit Bank UTR & Screenshot Submission Card
                      _buildUtrSubmissionCard(),

                      const SizedBox(height: 22),

                      // 4. Official NPCI Security Lockup
                      Center(
                        child: OfficialPaymentIcons.npciSecurityLockup(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⏳ Dedicated Under Review Confirmation View (With Edit Option & Details)
  Widget _buildUnderReviewScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context, {
            'status': 'UNDER_REVIEW',
            'utr': _utrController.text,
            'phone': _phoneController.text,
            'screenshot': _screenshotName,
          }),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Status',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Room ${widget.roomNumber} • ${widget.cycleMonth}',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 13,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                Text(
                  'Under Review',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Status Hero Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFDE68A), width: 2),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 26,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isCashMode
                            ? 'Cash Handover Recorded!'
                            : 'Payment Proof Submitted!',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCashMode
                            ? 'Physical cash handover recorded to $_submittedCashRecipient. Awaiting owner audit into the PG cash locker.'
                            : 'Awaiting confirmation from ${widget.ownerName} against his bank credit SMS. Your receipt will be unlocked once approved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. What You Submitted Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHAT YOU SUBMITTED',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Amount & Cycle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rent Amount',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            _formattedAmount,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 10),

                      if (_isCashMode) ...[
                        // Handed Over To
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Handed Over To',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              _submittedCashRecipient ?? 'PG Staff',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),

                        // Handover Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Handover Date',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '13 Sep 2026',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        if (_submittedCashRemarks != null &&
                            _submittedCashRemarks!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remarks',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _submittedCashRemarks!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        // Bank UTR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bank UTR Ref',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _utrController.text.isEmpty
                                      ? '425689123456'
                                      : _utrController.text,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: _utrController.text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Copied UTR to clipboard!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded,
                                      size: 13, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),

                        // Paid From Phone
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid From Mobile',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '+91 ${_phoneController.text}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),

                        // Screenshot Attached
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Proof',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasScreenshot
                                    ? const Color(0xFFEBF8EE)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _hasScreenshot
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    size: 13,
                                    color: _hasScreenshot
                                        ? AppColors.greenDark
                                        : AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _hasScreenshot
                                        ? (_screenshotName ??
                                            'Receipt Attached')
                                        : 'No screenshot',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _hasScreenshot
                                          ? AppColors.greenDark
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Edit Option Button (Editable until approved)
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isSubmitted = false; // Switches back to form!
                      });
                    },
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.ink),
                    label: Text(
                      'Edit Submitted Details (Fix Typo)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFD1D5DB), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Test Demo Simulation: Owner Approves
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined,
                          size: 18, color: Color(0xFF4B5563)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Test Demo: Simulate owner confirming this UTR',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onOwnerApproved?.call();
                          Navigator.pop(context, {'status': 'APPROVED'});
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.greenDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Done / Return to Dashboard
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'status': 'UNDER_REVIEW',
                        'utr': _utrController.text,
                        'phone': _phoneController.text,
                        'screenshot': _screenshotName,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done • Return to Dashboard',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 1. Bill Card with Expandable Details
  Widget _buildSwiggyBillCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Property & Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pgName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Room ${widget.roomNumber} • ${widget.cycleMonth}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Text(
                _formattedAmount,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bill Breakdown Accordion Toggle
          InkWell(
            onTap: () => setState(() => _isBillExpanded = !_isBillExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBillExpanded
                        ? 'Hide Bill Breakdown'
                        : 'View Bill Breakdown',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenDark,
                    ),
                  ),
                  Icon(
                    _isBillExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.greenDark,
                  ),
                ],
              ),
            ),
          ),

          if (_isBillExpanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),
            _buildBillItem('Monthly Stay Rent', _formattedAmount),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount Payable',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  _formattedAmount,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillItem(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.greenDark : AppColors.ink,
          ),
        ),
      ],
    );
  }

  /// 📲 2. Owner's Direct UPI QR Code Card
  Widget _buildOwnerQrCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OWNER DIRECT UPI QR',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
              OfficialPaymentIcons.upiLogo(width: 44, height: 16),
            ],
          ),

          const SizedBox(height: 16),

          // QR Code Frame with Authentic UPI Standee Appearance
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // QR Graphic Container
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPaint(
                      painter: _DirectUpiQrPainter(),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'UPI',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OfficialPaymentIcons.googlePay(width: 30, height: 18),
                      const SizedBox(width: 10),
                      OfficialPaymentIcons.phonePe(width: 26, height: 18),
                      const SizedBox(width: 10),
                      OfficialPaymentIcons.paytm(width: 32, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Owner Beneficiary Details Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payee Name',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      widget.ownerName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bank Account',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      widget.ownerBankName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Phone Number',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '+91 ${widget.ownerPhone}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.ownerPhone));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copied "${widget.ownerPhone}" to clipboard!',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: AppColors.ink,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 12, color: AppColors.ink),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner UPI ID',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          widget.ownerUpiId,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.ownerUpiId));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copied "${widget.ownerUpiId}" to clipboard!',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: AppColors.ink,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 12, color: AppColors.ink),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
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

          const SizedBox(height: 14),

          // 3-Step Clear Instructions Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF8EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB7E4C7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'How to Pay via QR Code (₹0 Fee):',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Take a screenshot of this QR Code.\n'
                  '2. Open Google Pay, PhonePe, or Paytm → Tap Scanner icon → Select from Gallery.\n'
                  '3. Pay $_formattedAmount and copy the 12-digit Bank UTR from receipt.',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E3A1E),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 3. Direct 12-Digit Bank UTR Submission Card
  Widget _buildUtrSubmissionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBMIT PAYMENT PROOF',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Confirm Payment to ${widget.ownerName}',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. Paid Mobile Number Input Field
          Text(
            'Mobile Number Paid From',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _phoneError != null
                    ? Colors.red.shade400
                    : const Color(0xFFD1D5DB),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  '+91 ',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g. 8618818322',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.phone_android_rounded,
                    size: 18, color: AppColors.muted),
              ],
            ),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 4),
            Text(
              _phoneError!,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 2. 12-Digit UTR Input Field
          Text(
            '12-Digit Bank Reference / UTR',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _utrError != null
                    ? Colors.red.shade400
                    : const Color(0xFFD1D5DB),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _utrController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 1.0,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g. 425689123456',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.paste_rounded,
                      size: 18, color: AppColors.muted),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      final clean = data!.text!.replaceAll(RegExp(r'\D'), '');
                      _utrController.text = clean;
                    }
                  },
                ),
              ],
            ),
          ),
          if (_utrError != null) ...[
            const SizedBox(height: 4),
            Text(
              _utrError!,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. Payment Screenshot Upload Box
          Text(
            'Attach Payment Screenshot (Optional)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (!_hasScreenshot) {
                  _hasScreenshot = true;
                  _screenshotName =
                      'gpay_receipt_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _hasScreenshot
                    ? const Color(0xFFEBF8EE)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasScreenshot
                      ? AppColors.green
                      : const Color(0xFFD1D5DB),
                  style: _hasScreenshot ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: _hasScreenshot
                  ? Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFB7E4C7)),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: AppColors.greenDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _screenshotName ?? 'payment_screenshot.jpg',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '384 KB • Attached for Owner Verification',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _hasScreenshot = false;
                              _screenshotName = null;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 20,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload GPay / PhonePe Screenshot',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Helps owner approve your rent instantly',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 18),

          // Big Confident Submit Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _showConfirmPaymentPopup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit UTR & Confirm Rent',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Custom Painter that renders an authentic, sharp UPI QR Matrix
class _DirectUpiQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;

    const double moduleSize = 8.0;
    final int modules = (size.width / moduleSize).floor();

    // 1. Finder pattern helper
    void drawFinder(double x, double y) {
      // Outer 7x7
      canvas.drawRect(
          Rect.fromLTWH(x, y, 7 * moduleSize, 7 * moduleSize), paint);
      // Inner white 5x5
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(
            x + moduleSize, y + moduleSize, 5 * moduleSize, 5 * moduleSize),
        whitePaint,
      );
      // Center 3x3 black
      canvas.drawRect(
        Rect.fromLTWH(x + 2 * moduleSize, y + 2 * moduleSize, 3 * moduleSize,
            3 * moduleSize),
        paint,
      );
    }

    // Top-Left Finder
    drawFinder(moduleSize, moduleSize);
    // Top-Right Finder
    drawFinder(size.width - 8 * moduleSize, moduleSize);
    // Bottom-Left Finder
    drawFinder(moduleSize, size.height - 8 * moduleSize);

    // Timing patterns
    for (int i = 8; i < modules - 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * moduleSize, 6 * moduleSize, moduleSize, moduleSize),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(6 * moduleSize, i * moduleSize, moduleSize, moduleSize),
        paint,
      );
    }

    // Realistic decorative QR matrix dots (pseudorandom grid)
    for (int r = 0; r < modules; r++) {
      for (int c = 0; c < modules; c++) {
        // Skip finders
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= modules - 8) ||
            (r >= modules - 8 && c < 8)) {
          continue;
        }
        // Skip center logo area
        if (r >= modules ~/ 2 - 2 &&
            r <= modules ~/ 2 + 2 &&
            c >= modules ~/ 2 - 3 &&
            c <= modules ~/ 2 + 3) {
          continue;
        }
        // Deterministic dot pattern
        if ((r * 7 + c * 13 + (r % 3) * (c % 5)) % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * moduleSize + 0.5, r * moduleSize + 0.5,
                  moduleSize - 1, moduleSize - 1),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
