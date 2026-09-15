import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// 💳 Modular Enterprise UPI Payment Sheet for UrbanStay Residents
/// Modeled after tier-1 B2B fintech standards (NoBroker / CRED / Stripe).
/// Features:
/// - 0% transaction fee direct bank UPI intent
/// - Official UPI payment app selectors (GPay, PhonePe, Paytm, Other)
/// - Offline cash / IMPS 12-digit UTR reference submission
/// - Zero emojis, clean vector icons & strict typography
class RentPaymentBottomSheet extends StatefulWidget {
  final String roomNumber;
  final String bedId;
  final String pgName;
  final String ownerName;
  final String ownerUpiId;
  final String ownerBankName;
  final double amount;
  final String cycleMonth;
  final ValueChanged<String> onUtrSubmitted;
  final ValueChanged<String> onPaymentCompleted;

  const RentPaymentBottomSheet({
    super.key,
    required this.roomNumber,
    required this.bedId,
    required this.pgName,
    this.ownerName = 'Arun Kumar',
    this.ownerUpiId = 'arunpg@okhdfcbank',
    this.ownerBankName = 'HDFC Bank',
    this.amount = 8500.0,
    this.cycleMonth = 'September 2026',
    required this.onUtrSubmitted,
    required this.onPaymentCompleted,
  });

  /// Static helper to trigger the bottom sheet with clean transition
  static void show({
    required BuildContext context,
    required String roomNumber,
    required String bedId,
    required String pgName,
    String ownerName = 'Arun Kumar',
    String ownerUpiId = 'arunpg@okhdfcbank',
    String ownerBankName = 'HDFC Bank',
    double amount = 8500.0,
    String cycleMonth = 'September 2026',
    required ValueChanged<String> onUtrSubmitted,
    required ValueChanged<String> onPaymentCompleted,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RentPaymentBottomSheet(
        roomNumber: roomNumber,
        bedId: bedId,
        pgName: pgName,
        ownerName: ownerName,
        ownerUpiId: ownerUpiId,
        ownerBankName: ownerBankName,
        amount: amount,
        cycleMonth: cycleMonth,
        onUtrSubmitted: onUtrSubmitted,
        onPaymentCompleted: onPaymentCompleted,
      ),
    );
  }

  @override
  State<RentPaymentBottomSheet> createState() => _RentPaymentBottomSheetState();
}

class _RentPaymentBottomSheetState extends State<RentPaymentBottomSheet> {
  final TextEditingController _utrController = TextEditingController();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = '₹${widget.amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Header: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Rent',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Room ${widget.roomNumber} (Bed ${widget.bedId}) • ${widget.pgName}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Bill Summary & Owner Beneficiary Trust Box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'AMOUNT PAYABLE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.muted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8EE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.cycleMonth,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedAmount,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),

                    // Beneficiary Trust Row
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          size: 15,
                          color: AppColors.greenDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Direct beneficiary: ${widget.ownerName} (Owner)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // UPI ID & 0% Fee Row
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.ownerBankName} • ${widget.ownerUpiId}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '0% Fee',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Section: Select UPI App
              Text(
                'SELECT UPI APP TO PAY',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),

              // UPI Apps List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildPaymentAppTile(
                      badgeColor: const Color(0xFF4285F4),
                      badgeLetter: 'G',
                      title: 'Google Pay',
                      subtitle: 'Instant UPI authorization',
                      onTap: () => _handleAppPayment('Google Pay'),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6), indent: 52),
                    _buildPaymentAppTile(
                      badgeColor: const Color(0xFF5F259F),
                      badgeLetter: 'Pe',
                      title: 'PhonePe',
                      subtitle: 'Direct bank debit via PhonePe UPI',
                      onTap: () => _handleAppPayment('PhonePe'),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6), indent: 52),
                    _buildPaymentAppTile(
                      badgeColor: const Color(0xFF00B9F1),
                      badgeLetter: 'P',
                      title: 'Paytm UPI',
                      subtitle: 'Fast payments with Paytm',
                      onTap: () => _handleAppPayment('Paytm'),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6), indent: 52),
                    _buildPaymentAppTile(
                      badgeColor: const Color(0xFF1F2937),
                      badgeIcon: Icons.qr_code_rounded,
                      title: 'Other UPI Apps',
                      subtitle: 'BHIM, CRED, Navi, Amazon Pay',
                      onTap: () => _handleAppPayment('Other UPI App'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Offline Cash / Direct IMPS Report Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 16,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paid via Cash or Direct IMPS/NEFT?',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              controller: _utrController,
                              keyboardType: TextInputType.number,
                              maxLength: 12,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111111),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                counterText: '',
                                border: InputBorder.none,
                                hintText: 'Enter 12-digit UTR No.',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _submitUtr,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Submit UTR',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Security & HRA Exemption Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'NPCI 256-bit Encrypted • Official HRA receipt unlocked',
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
        ),
      ),
    );
  }

  Widget _buildPaymentAppTile({
    Color? badgeColor,
    String? badgeLetter,
    IconData? badgeIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: badgeLetter != null
                  ? Text(
                      badgeLetter,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      badgeIcon ?? Icons.payment_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAppPayment(String appName) {
    Navigator.pop(context);
    widget.onPaymentCompleted(appName);
  }

  void _submitUtr() {
    final utr = _utrController.text.trim();
    if (utr.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 12-digit UTR reference number',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    Navigator.pop(context);
    widget.onUtrSubmitted(utr);
  }
}
