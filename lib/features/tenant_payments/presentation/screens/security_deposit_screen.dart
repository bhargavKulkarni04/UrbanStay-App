import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';

class SecurityDepositScreen extends StatefulWidget {
  final String roomNumber;
  final String bedLabel;
  final String propertyName;

  const SecurityDepositScreen({
    super.key,
    this.roomNumber = '104',
    this.bedLabel = 'Bed B',
    this.propertyName = 'UrbanStay Prime',
  });

  @override
  State<SecurityDepositScreen> createState() => _SecurityDepositScreenState();
}

class _SecurityDepositScreenState extends State<SecurityDepositScreen> {
  // Financial breakdown values (3k total = 1.5k deposit + 1.5k maintenance)
  final double _totalOnboardingPaid = 3000.0;
  final double _refundableDeposit = 1500.0;
  final double _maintenanceFee = 1500.0;
  final String _paymentDate = '01 Apr 2026';
  final String _receiptNumber = 'DEP-2026-04-0104';

  // State
  String _refundUpiId = 'bhargavkulkarni04@oksbi';
  bool _hasDamage = false; // Toggle to view damage deduction state
  final double _damageAmount = 500.0;
  final String _damageItem = 'Broken Bathroom Mirror';
  final String _damageLoggedDate = '12 Aug 2026';
  final String _damageLoggedBy = 'Arun Kumar (Owner)';

  double get _netRefundable =>
      _hasDamage ? (_refundableDeposit - _damageAmount) : _refundableDeposit;

  void _openEditUpiDialog() {
    final controller = TextEditingController(text: _refundUpiId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Update Refund UPI ID',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security deposit will be transferred to this VPA upon move-out inspection.',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. name@okhdfcbank',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF08A63F), width: 1.5),
                ),
              ),
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() => _refundUpiId = val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Refund UPI updated to $val',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: const Color(0xFF111111),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08A63F),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openDamagePhotoProof() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Damage Photo Proof',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      _damageItem,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Logged: $_damageLoggedDate by $_damageLoggedBy',
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deduction Amount:', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                  Text(AppCurrency.format(_damageAmount),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Close', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadDepositReceipt() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF08A63F), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt $_receiptNumber downloaded (PDF)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111111),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F9),
            border: Border.symmetric(
              vertical: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            appBar: _buildAppBar(),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Hero Net Refundable Balance
                    _buildNetRefundableCard(),

                    const SizedBox(height: 14),

                    // 2. Onboarding Fee Breakdown (3k Split: 1.5k Deposit + 1.5k Maintenance)
                    _buildBreakdownCard(),

                    const SizedBox(height: 14),

                    // 3. Recorded Damages Card
                    _buildDamagesCard(),

                    const SizedBox(height: 14),

                    // 4. Refund Destination & Exit Settlement
                    _buildSettlementCard(),

                    const SizedBox(height: 14),

                    // 5. Download Official Deposit Receipt
                    _buildReceiptAction(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF111111)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Deposit & Fees',
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
          ),
          Text(
            '${widget.propertyName} • Room ${widget.roomNumber} - ${widget.bedLabel}',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
      actions: [
        // Demo Toggle for Damage Simulation
        TextButton(
          onPressed: () {
            setState(() => _hasDamage = !_hasDamage);
          },
          child: Text(
            _hasDamage ? 'Clear Damage' : 'Simulate Damage',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  /// 1. Hero Net Refundable Balance Card
  Widget _buildNetRefundableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET REFUNDABLE AT EXIT',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF08A63F).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 11, color: Color(0xFF068237)),
                    const SizedBox(width: 4),
                    Text(
                      'HELD IN ESCROW',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF068237),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF08A63F),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                AppCurrency.format(_netRefundable, includeSymbol: false),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: const Color(0xFF08A63F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Total Move-In Paid: ${AppCurrency.format(_totalOnboardingPaid)}  •  Paid on $_paymentDate',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  /// 2. Onboarding Fee Breakdown Card (3k Split)
  Widget _buildBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEE BREAKDOWN',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          // Refundable Deposit Item
          _buildBreakdownRow(
            title: 'Security Deposit (Refundable)',
            subtitle: '100% returnable at checkout minus damages',
            amount: AppCurrency.format(_refundableDeposit),
            amountColor: const Color(0xFF111111),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),

          // Maintenance Fee Item
          _buildBreakdownRow(
            title: 'Maintenance Fee (Non-Refundable)',
            subtitle: 'One-time admission, room setup & painting fee',
            amount: AppCurrency.format(_maintenanceFee),
            amountColor: const Color(0xFF6B7280),
          ),

          if (_hasDamage) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            _buildBreakdownRow(
              title: 'Damage Deductions',
              subtitle: _damageItem,
              amount: '-${AppCurrency.format(_damageAmount)}',
              amountColor: const Color(0xFFDC2626),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: amountColor),
        ),
      ],
    );
  }

  /// 3. Recorded Damages Card (Synced with Owner Rooms Module)
  Widget _buildDamagesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXIT INSPECTION & DAMAGES',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _hasDamage ? const Color(0xFFFEF2F2) : const Color(0xFFEBF8EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasDamage ? const Color(0xFFFCA5A5) : const Color(0xFF08A63F).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _hasDamage ? '1 DEDUCTION PENDING' : 'CLEAR • 0 ISSUES',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _hasDamage ? const Color(0xFFDC2626) : const Color(0xFF068237),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_hasDamage)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF08A63F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No room damages reported by owner. Full deposit eligible for refund at checkout.',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF111111)),
                  ),
                ),
              ],
            )
          else ...[
            // Notice Period End Day Timeline Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice Period End Day: 30 Sep 2026 (Final Move-Out Inspection)',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Itemized Owner Damage Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _damageItem,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      Text(
                        '-${AppCurrency.format(_damageAmount)}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Logged: $_damageLoggedDate by $_damageLoggedBy',
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      'Mode: Deduct from Security Deposit at Exit',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _openDamagePhotoProof,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_outlined, size: 13, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              'View Photo Proof (damage_proof_photo_101.jpg) >',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 4. Refund Destination Card
  Widget _buildSettlementCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REFUND SETTLEMENT ACCOUNT',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              InkWell(
                onTap: _openEditUpiDialog,
                child: Text(
                  'Change',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF08A63F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF111111)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPI ID (Primary)',
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                    ),
                    Text(
                      _refundUpiId,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),
          Text(
            'Transfer timeline: 24h after checkout upon serving mandatory 30-day notice.',
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  /// 5. Receipt Download Action
  Widget _buildReceiptAction() {
    return OutlinedButton.icon(
      onPressed: _downloadDepositReceipt,
      icon: const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF111111)),
      label: Text(
        'Download Deposit Receipt ($_receiptNumber)',
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
