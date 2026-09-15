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
    this.propertyName = 'UrbanStay Prime',
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Rent', 'Security Deposit', 'Maintenance'];

  // Verified transaction records
  late final List<LedgerRecord> _transactions = [
    LedgerRecord(
      id: 'TXN-2026-09-104',
      title: 'September 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '03 Sep 2026, 11:24 AM',
      method: 'Google Pay (UPI)',
      utrNumber: '425689104231',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-09-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'GPay_Payment_Sep2026.png',
      screenshotDetails: 'Google Pay • Ref: 425689104231 • ₹8,500.00',
    ),
    LedgerRecord(
      id: 'TXN-2026-08-104',
      title: 'August 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '04 Aug 2026, 07:15 PM',
      method: 'PhonePe (UPI)',
      utrNumber: '421890334812',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-08-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'PhonePe_Receipt_Aug2026.png',
      screenshotDetails: 'PhonePe • Ref: 421890334812 • ₹8,500.00',
    ),
    LedgerRecord(
      id: 'TXN-2026-07-104',
      title: 'July 2026 Rent',
      category: 'Rent',
      amount: 8500.0,
      timestamp: '05 Jul 2026, 09:42 AM',
      method: 'Paytm (UPI)',
      utrNumber: '418765432190',
      status: LedgerStatus.verified,
      receiptNumber: 'REC-2026-07-0104',
      hasProofScreenshot: true,
      screenshotLabel: 'Paytm_Payment_Jul2026.png',
      screenshotDetails: 'Paytm • Ref: 418765432190 • ₹8,500.00',
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

  List<LedgerRecord> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;
    return _transactions.where((t) => t.category == _selectedFilter).toList();
  }

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
              child: Column(
                children: [
                  _buildFilterBar(),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: _filteredTransactions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final record = _filteredTransactions[index];
                              return _buildTransactionCard(record);
                            },
                          ),
                  ),
                ],
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
            '${widget.propertyName} • Room ${widget.roomNumber} - ${widget.bedLabel}',
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

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = filter);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF111111) : const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF111111) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(LedgerRecord record) {
    final isVerified = record.status == LedgerStatus.verified;
    final isUnderReview = record.status == LedgerStatus.underReview;

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
          // 1. Title, Amount & Verification Chip
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${record.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF08A63F),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
                          size: 11,
                          color: isVerified
                              ? const Color(0xFF068237)
                              : (isUnderReview ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified ? 'VERIFIED' : (isUnderReview ? 'UNDER REVIEW' : 'PENDING'),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
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
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // 2. Metadata Grid (Payment Method & Bank UTR)
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
                      'BANK REF (UTR)',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copyToClipboard(record.utrNumber, 'UTR Number'),
                      child: Row(
                        children: [
                          Text(
                            record.utrNumber,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
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

          // 3. Online Payment Proof Screenshot Attachment
          if (record.hasProofScreenshot) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openScreenshotViewer(record),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF08A63F).withOpacity(0.2), width: 1),
                      ),
                      child: const Icon(
                        Icons.photo_outlined,
                        size: 18,
                        color: Color(0xFF068237),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Proof Screenshot',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111111),
                            ),
                          ),
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
                          'View Proof',
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

          const SizedBox(height: 12),

          // 4. Receipt Download & Share Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadReceipt(record),
                  icon: const Icon(Icons.receipt_long_outlined, size: 15, color: Color(0xFF111111)),
                  label: Text(
                    'Download Receipt',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 38,
                child: OutlinedButton(
                  onPressed: () => _copyToClipboard(
                    'UrbanStay Rent Receipt ${record.receiptNumber}: ₹${record.amount.toStringAsFixed(0)} (UTR: ${record.utrNumber})',
                    'Receipt reference',
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9FAFB),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF111111)),
                ),
              ),
            ],
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
            'No transactions in this category',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select "All" to view your complete payment history',
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

/// Modal dialog that displays the payment screenshot proof
class _PaymentProofDialog extends StatelessWidget {
  final LedgerRecord record;

  const _PaymentProofDialog({required this.record});

  @override
  Widget build(BuildContext context) {
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
                      'Payment Proof Attachment',
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

            // Simulated Payment Screenshot Container
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
                    // Green Check Circle
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
                      'Paid to UrbanStay Technologies',
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

                    // Key-value pairs inside screenshot
                    _buildProofRow('UPI Transaction ID', record.utrNumber),
                    const SizedBox(height: 8),
                    _buildProofRow('Google Transaction ID', 'CICAgIC...9281'),
                    const SizedBox(height: 8),
                    _buildProofRow('Payment Mode', record.method),
                    const SizedBox(height: 8),
                    _buildProofRow('Bank Reference (UTR)', record.utrNumber),
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
                        Clipboard.setData(ClipboardData(text: record.utrNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'UTR ${record.utrNumber} copied',
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
                        'Copy UTR',
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
  });
}
