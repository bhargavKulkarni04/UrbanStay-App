import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentLedgerScreen extends StatefulWidget {
  final String roomNumber;
  final String bedLabel;
  final String propertyName;

  const PaymentLedgerScreen({
    super.key,
    this.roomNumber = '104',
    this.bedLabel = 'Bed B',
    this.propertyName = 'UrbanStay Premium PG',
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  // Verified transaction records (Supporting both UPI and Cash)
  late final List<LedgerRecord> _transactions = [
    LedgerRecord(
      id: 'TXN-2026-09-104',
      title: 'September 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '03 Sep 2026, 11:24 AM',
      method: 'UPI',
      utrNumber: '425689104231',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-09-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'UPI_Payment_Sep2026.png',
      screenshotDetails: 'UPI • Ref: 425689104231 • ₹8,500.00',
    ),
    LedgerRecord(
      id: 'TXN-2026-08-104-CSH',
      title: 'August 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '04 Aug 2026, 07:15 PM',
      method: 'Cash',
      utrNumber: 'CSH-REC-8412',
      recipient: 'Arun Kumar (Owner)',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-08-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'Cash_Handover_Aug2026.pdf',
      screenshotDetails: 'Cash Handover • Arun Kumar (Owner) • ₹8,500.00',
    ),
    LedgerRecord(
      id: 'TXN-2026-07-104',
      title: 'July 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '05 Jul 2026, 09:42 AM',
      method: 'UPI',
      utrNumber: '418765432190',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-07-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'UPI_Receipt_Jul2026.png',
      screenshotDetails: 'UPI • Ref: 418765432190 • ₹8,500.00',
    ),
    LedgerRecord(
      id: 'TXN-2026-04-104-DEP',
      title: 'Security Deposit (Move-In)',
      category: 'Security Deposit',
      amount: 15000.0,
      timestamp: '01 Apr 2026, 02:10 PM',
      method: 'Direct Bank Transfer (IMPS)',
      utrNumber: '409123847561',
      status: LedgerStatus.verified,
      receiptNumber: 'DEP-2026-04-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'IMPS_Deposit_Receipt.png',
      screenshotDetails: 'HDFC IMPS • Ref: 409123847561 • ₹15,000.00',
    ),
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF111111),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openScreenshotViewer(LedgerRecord record) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => _PaymentProofDialog(record: record),
    );
  }

  void _downloadReceipt(LedgerRecord record) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF08A63F), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt ${record.receiptNumber} downloaded (HRA Stamped PDF)',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111111),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              vertical: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: SafeArea(
              child: _transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _transactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final record = _transactions[index];
                        return _buildTransactionCard(record);
                      },
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
            'Payment Ledger',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${widget.propertyName} • Room ${widget.roomNumber}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildTransactionCard(LedgerRecord record) {
    final isVerified = record.status == LedgerStatus.verified;
    final isUnderReview = record.status == LedgerStatus.underReview;
    final isCash = record.method.toLowerCase().contains('cash');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
          // 1. Title & Amount (Verified badge moved below payment proof)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.timestamp,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${record.amount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF08A63F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // 2. Metadata Grid (Payment Method & Reference / Recipient)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT METHOD',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.method,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCash ? 'HANDED OVER TO' : 'BANK REF (UTR)',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copyToClipboard(
                        isCash ? (record.recipient ?? record.utrNumber) : record.utrNumber,
                        isCash ? 'Recipient details' : 'UTR Number',
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              isCash ? (record.recipient ?? record.utrNumber) : record.utrNumber,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111111),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Online Payment Proof / Cash Proof (Without icon, 'View' text)
          if (record.hasProofScreenshot) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openScreenshotViewer(record),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCash ? 'Cash Handover Proof' : 'Payment Proof Screenshot',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            record.screenshotLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF08A63F),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF08A63F),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 4. Verification Badge (Moved below payment proof)
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFFEBF8EE)
                  : (isUnderReview ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isVerified
                    ? const Color(0xFF08A63F).withOpacity(0.2)
                    : (isUnderReview ? const Color(0xFFF59E0B).withOpacity(0.25) : const Color(0xFFE5E7EB)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified
                      ? Icons.check_circle_rounded
                      : (isUnderReview ? Icons.schedule_rounded : Icons.info_outline_rounded),
                  size: 11.5,
                  color: isVerified
                      ? const Color(0xFF068237)
                      : (isUnderReview ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                ),
                const SizedBox(width: 4),
                Text(
                  isVerified ? 'VERIFIED' : (isUnderReview ? 'UNDER REVIEW' : 'PENDING'),
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isVerified
                        ? const Color(0xFF068237)
                        : (isUnderReview ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. Download Receipt Button (Full width, share button removed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _downloadReceipt(record),
              icon: const Icon(Icons.receipt_long_outlined, size: 15, color: Color(0xFF111111)),
              label: Text(
                'Download Receipt',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_outlined, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            'No transactions recorded',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your payment receipts and verified ledger will appear here',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal dialog that displays payment proof (supporting both UPI and Cash)
class _PaymentProofDialog extends StatelessWidget {
  final LedgerRecord record;

  const _PaymentProofDialog({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCash = record.method.toLowerCase().contains('cash');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF08A63F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCash ? 'Cash Payment Proof' : 'Payment Proof Attachment',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Payment Voucher Container
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF8EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 30,
                        color: Color(0xFF08A63F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCash
                          ? 'Cash Received at Reception'
                          : 'Paid to UrbanStay Technologies',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${record.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.timestamp,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),

                    // Key-value pairs
                    if (isCash) ...[
                      _buildProofRow('Payment Mode', 'Cash (Reception Desk)'),
                      const SizedBox(height: 8),
                      _buildProofRow('Handed Over To', record.recipient ?? 'Arun Kumar (Owner)'),
                      const SizedBox(height: 8),
                      _buildProofRow('Audit Ref Number', record.utrNumber),
                      const SizedBox(height: 8),
                      _buildProofRow('Verification Status', 'Verified by Owner'),
                    ] else ...[
                      _buildProofRow('Payment Mode', 'UPI'),
                      const SizedBox(height: 8),
                      _buildProofRow('Bank Reference (UTR)', record.utrNumber),
                      const SizedBox(height: 8),
                      _buildProofRow('Reconciliation', 'Auto-Verified'),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Clipboard.setData(ClipboardData(
                          text: isCash
                              ? (record.recipient ?? record.utrNumber)
                              : record.utrNumber,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCash
                                  ? 'Receipt Ref ${record.utrNumber} copied'
                                  : 'UTR ${record.utrNumber} copied',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: const Color(0xFF111111),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08A63F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        isCash ? 'Copy Ref' : 'Copy UTR',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

enum LedgerStatus { verified, underReview, pending }

class LedgerRecord {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String timestamp;
  final String method;
  final String utrNumber;
  final LedgerStatus status;
  final String receiptNumber;
  final bool hasProofScreenshot;
  final String screenshotLabel;
  final String screenshotDetails;
  final String? recipient;

  LedgerRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.timestamp,
    required this.method,
    required this.utrNumber,
    required this.status,
    required this.receiptNumber,
    required this.hasProofScreenshot,
    required this.screenshotLabel,
    required this.screenshotDetails,
    this.recipient,
  });
}
