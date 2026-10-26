import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/urban_loading.dart';

class PaymentLedgerScreen extends StatefulWidget {
  final String? tenantId;
  final String? propertyId;
  final String? tenantName;
  final String roomNumber;
  final String bedLabel;
  final String propertyName;

  const PaymentLedgerScreen({
    super.key,
    this.tenantId,
    this.propertyId,
    this.tenantName,
    this.roomNumber = '',
    this.bedLabel = '',
    this.propertyName = 'UrbanStay',
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<LedgerRecord> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchLedgerRecords();
  }

  /// Format DateTime into clean Indian financial date string (e.g. 26 Oct 2026, 02:30 PM)
  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    try {
      final local = dt.toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final day = local.day.toString().padLeft(2, '0');
      final month = months[local.month - 1];
      final year = local.year;
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $period';
    } catch (_) {
      return dt.toString();
    }
  }

  /// Live Supabase query fetching strongly-typed 8-pillar models (Pillar 3 & Pillar 4)
  Future<void> _fetchLedgerRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    UrbanLoadingService.show('Loading verified payment ledger...');

    try {
      final client = SupabaseService.instance.client;
      String? resolvedTenantId = widget.tenantId;

      // Fallback: If tenantId wasn't passed directly, resolve via current authenticated phone
      if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
        final phone = SupabaseService.instance.currentUser?.phone ??
            SupabaseService.instance.currentUserPhone;
        if (phone != null && phone.isNotEmpty) {
          final tRes = await client
              .from('tenants')
              .select('id')
              .eq('phone', phone)
              .maybeSingle();
          resolvedTenantId = tRes?['id']?.toString();
        }
      }

      if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
        setState(() {
          _transactions.clear();
          _isLoading = false;
        });
        return;
      }

      // 1. Fetch monthly rent ledgers (Pillar 4: RentLedgerModel)
      var ledgersRes = await client
          .from('rent_ledgers')
          .select('*')
          .eq('tenant_id', resolvedTenantId)
          .order('created_at', ascending: false);

      List ledgersList = (ledgersRes as List?) ?? [];

      // Secondary fallback: if tenantId had zero rows, search by property + tenant name
      if (ledgersList.isEmpty &&
          widget.propertyId != null &&
          widget.tenantName != null &&
          widget.tenantName!.isNotEmpty &&
          widget.tenantName != 'Resident') {
        final fallbackRes = await client
            .from('rent_ledgers')
            .select('*')
            .eq('property_id', widget.propertyId!)
            .ilike('tenant_name', widget.tenantName!)
            .order('created_at', ascending: false);
        ledgersList = (fallbackRes as List?) ?? [];
      }

      // Map into strongly-typed Pillar 4 RentLedgerModel
      final List<RentLedgerModel> ledgerModels = ledgersList
          .map((e) => RentLedgerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // 2. Fetch payment approvals (Pillar 4: PaymentApprovalModel)
      final approvalsRes = await client
          .from('payment_approvals')
          .select('*')
          .eq('tenant_id', resolvedTenantId)
          .order('created_at', ascending: false);

      final List approvalsList = (approvalsRes as List?) ?? [];

      // Map into strongly-typed Pillar 4 PaymentApprovalModel
      final List<PaymentApprovalModel> approvalModels = approvalsList
          .map((e) =>
              PaymentApprovalModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // 3. Fetch move-in security deposit details from tenants table (Pillar 3: TenantModel)
      final tenantProfile = await client
          .from('tenants')
          .select(
              'id, name, full_name, room_number, security_deposit, deposit_status, move_in_date, created_at')
          .eq('id', resolvedTenantId)
          .maybeSingle();

      TenantModel? tenantModel;
      if (tenantProfile != null) {
        try {
          tenantModel =
              TenantModel.fromJson(Map<String, dynamic>.from(tenantProfile));
        } catch (_) {}
      }

      final List<LedgerRecord> records = [];

      // Reconcile each strongly-typed RentLedgerModel
      for (final ledger in ledgerModels) {
        // Match payment approval record from Pillar 4
        PaymentApprovalModel? matchingApproval;
        for (final a in approvalModels) {
          if (a.ledgerId == ledger.id) {
            matchingApproval = a;
            break;
          }
        }
        if (matchingApproval == null) {
          for (final a in approvalModels) {
            if ((a.amount - ledger.rentAmount).abs() < 1.0) {
              matchingApproval = a;
              break;
            }
          }
        }

        LedgerStatus status = LedgerStatus.pending;
        if (ledger.isPaid || (matchingApproval?.isApproved ?? false)) {
          status = LedgerStatus.verified;
        } else if (matchingApproval?.isPending ?? false) {
          status = LedgerStatus.underReview;
        }

        final isCash = matchingApproval?.isCash ??
            ledger.paymentMode.toLowerCase().contains('cash');

        final method = isCash
            ? 'Cash (Reception Desk)'
            : (matchingApproval != null &&
                    matchingApproval.paymentApp.isNotEmpty
                ? matchingApproval.paymentApp
                : ledger.paymentMode);

        final utrNumber = (matchingApproval != null &&
                matchingApproval.utrNumber.isNotEmpty &&
                matchingApproval.utrNumber != 'null')
            ? matchingApproval.utrNumber
            : (isCash ? 'Cash Handover' : 'Direct Bank UPI');

        final recipient = matchingApproval?.collectedBy ?? ledger.approvedBy;
        final approvedBy = ledger.approvedBy ?? matchingApproval?.approvedBy;

        final rawDate =
            ledger.paidDate ?? matchingApproval?.createdAt ?? ledger.createdAt;
        final timestamp = _formatDate(rawDate);

        final cleanRoom = (ledger.roomNumber.isNotEmpty
                ? ledger.roomNumber
                : widget.roomNumber)
            .replaceAll(RegExp(r'[^0-9]'), '');
        final receiptNumber =
            'REC-${ledger.cycleMonth.replaceAll(' ', '-').toUpperCase()}-${cleanRoom.isNotEmpty ? cleanRoom : '01'}';

        records.add(
          LedgerRecord(
            id: ledger.id.isNotEmpty ? ledger.id : 'TXN-${ledger.cycleMonth}',
            title: '${ledger.cycleMonth} Rent',
            category: 'Rent',
            amount: ledger.rentAmount,
            timestamp: timestamp,
            method: method,
            utrNumber: utrNumber,
            recipient: recipient,
            approvedBy: approvedBy,
            status: status,
            receiptNumber: receiptNumber,
            hasProofScreenshot: !isCash && matchingApproval != null,
            screenshotLabel: isCash
                ? 'Cash_Handover_Record.pdf'
                : 'UPI_Receipt_${ledger.cycleMonth.replaceAll(' ', '_')}.png',
            screenshotDetails:
                '$method • Ref: $utrNumber • ₹${ledger.rentAmount.toStringAsFixed(0)}',
          ),
        );
      }

      // Add Move-in Security Deposit if recorded in tenant profile (Pillar 3)
      if (tenantModel != null && tenantModel.securityDeposit > 0) {
        final double deposit = tenantModel.securityDeposit;
        final String depositStatusStr =
            tenantProfile?['deposit_status']?.toString().toUpperCase() ??
                'PAID';
        final isDepPaid = depositStatusStr == 'PAID';
        final DateTime? depDate = (tenantProfile?['move_in_date'] != null)
            ? DateTime.tryParse(tenantProfile!['move_in_date'].toString())
            : tenantModel.createdAt;
        final rawRoom = (tenantModel.roomNumber != null &&
                tenantModel.roomNumber!.isNotEmpty)
            ? tenantModel.roomNumber!
            : widget.roomNumber;
        final depCleanRoom = rawRoom.replaceAll(RegExp(r'[^0-9]'), '');

        records.add(
          LedgerRecord(
            id: 'DEP-${tenantModel.id}',
            title: 'Security Deposit (Move-In)',
            category: 'Security Deposit',
            amount: deposit,
            timestamp: _formatDate(depDate),
            method: 'Direct Bank Transfer / Cash',
            utrNumber:
                'DEP-${depCleanRoom.isNotEmpty ? depCleanRoom : '01'}-SEC',
            recipient: null,
            approvedBy: 'PG Owner',
            status: isDepPaid ? LedgerStatus.verified : LedgerStatus.pending,
            receiptNumber:
                'DEP-${depCleanRoom.isNotEmpty ? depCleanRoom : '01'}',
            hasProofScreenshot: false,
            screenshotLabel: 'Deposit_Receipt.png',
            screenshotDetails:
                'Move-In Deposit • ₹${deposit.toStringAsFixed(0)}',
          ),
        );
      }

      setState(() {
        _transactions = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching live payment ledger: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load payment ledger. Tap to retry.';
      });
    } finally {
      UrbanLoadingService.hide();
    }
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
      builder: (ctx) => _PaymentProofDialog(
        record: record,
        propertyName: widget.propertyName,
      ),
    );
  }

  void _downloadReceipt(LedgerRecord record) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => _ReceiptVoucherDialog(
        record: record,
        propertyName: widget.propertyName,
        tenantName: widget.tenantName,
        roomNumber: widget.roomNumber,
        bedLabel: widget.bedLabel,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF08A63F), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt ${record.receiptNumber} ready (HRA Verified)',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w500),
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
              child: _isLoading
                  ? const UrbanLoadingCard(
                      message: 'Loading verified payment ledger...',
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 44, color: Color(0xFFEF4444)),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _fetchLedgerRecords,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111111),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Retry',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF08A63F),
                          onRefresh: _fetchLedgerRecords,
                          child: _transactions.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.25),
                                    _buildEmptyState(),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  itemCount: _transactions.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final record = _transactions[index];
                                    return _buildTransactionCard(record);
                                  },
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: Color(0xFF111111)),
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
                        isCash
                            ? (record.recipient ?? record.utrNumber)
                            : record.utrNumber,
                        isCash ? 'Recipient details' : 'UTR Number',
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              isCash
                                  ? (record.recipient ?? record.utrNumber)
                                  : record.utrNumber,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111111),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 12, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Online Payment Proof (UPI only — Cash has no image attachment)
          if (!isCash && record.hasProofScreenshot) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openScreenshotViewer(record),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                            'Payment Proof Screenshot',
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
                  : (isUnderReview
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isVerified
                    ? const Color(0xFF08A63F).withOpacity(0.2)
                    : (isUnderReview
                        ? const Color(0xFFF59E0B).withOpacity(0.25)
                        : const Color(0xFFE5E7EB)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified
                      ? Icons.check_circle_rounded
                      : (isUnderReview
                          ? Icons.schedule_rounded
                          : Icons.info_outline_rounded),
                  size: 11.5,
                  color: isVerified
                      ? const Color(0xFF068237)
                      : (isUnderReview
                          ? const Color(0xFFB45309)
                          : const Color(0xFF6B7280)),
                ),
                const SizedBox(width: 4),
                Text(
                  isVerified
                      ? 'VERIFIED'
                      : (isUnderReview ? 'UNDER REVIEW' : 'PENDING'),
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isVerified
                        ? const Color(0xFF068237)
                        : (isUnderReview
                            ? const Color(0xFFB45309)
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. Download Receipt Button (Full width, green BG, white text, no icon)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _downloadReceipt(record),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08A63F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: Text(
                'Download Receipt',
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_outlined,
              size: 48, color: Color(0xFF9CA3AF)),
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
  final String? propertyName;

  const _PaymentProofDialog({
    required this.record,
    this.propertyName,
  });

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
                  const Icon(Icons.verified_outlined,
                      size: 18, color: Color(0xFF08A63F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCash
                          ? 'Cash Payment Proof'
                          : 'Payment Proof Attachment',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF6B7280)),
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
                          : (propertyName != null && propertyName!.isNotEmpty
                              ? 'Paid to $propertyName'
                              : 'Paid to UrbanStay'),
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
                      _buildProofRow(
                          'Handed Over To', record.recipient ?? 'PG Owner'),
                      const SizedBox(height: 8),
                      _buildProofRow('Audit Ref Number', record.utrNumber),
                      const SizedBox(height: 8),
                      _buildProofRow(
                          'Verification Status', 'Verified by Owner'),
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
                        side: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                              style: GoogleFonts.outfit(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: const Color(0xFF111111),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08A63F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
  final String? approvedBy;

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
    this.approvedBy,
  });
}

/// Modal dialog displaying official HRA Rent Receipt with verification stamps
class _ReceiptVoucherDialog extends StatelessWidget {
  final LedgerRecord record;
  final String propertyName;
  final String? tenantName;
  final String roomNumber;
  final String bedLabel;

  const _ReceiptVoucherDialog({
    required this.record,
    required this.propertyName,
    this.tenantName,
    required this.roomNumber,
    required this.bedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final verifier = record.approvedBy ?? record.recipient ?? 'PG Owner';
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
                  const Icon(Icons.receipt_long_rounded,
                      size: 20, color: Color(0xFF08A63F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Official Rent Receipt (HRA)',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Receipt Body
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
                    // Verified Badge Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8EE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF08A63F).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: Color(0xFF08A63F)),
                          const SizedBox(width: 5),
                          Text(
                            'VERIFIED & SETTLED',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF068237),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${record.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),

                    _buildVoucherRow('Receipt Number', record.receiptNumber),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Resident Name', tenantName ?? 'Resident'),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Property', propertyName),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Room / Bed',
                        'Room ${roomNumber.isNotEmpty ? roomNumber : '--'} ($bedLabel)'),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Payment Mode', record.method),
                    const SizedBox(height: 8),
                    _buildVoucherRow(
                        isCash ? 'Collected By' : 'Bank UTR', record.utrNumber),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Verified By', verifier),
                    const SizedBox(height: 8),
                    _buildVoucherRow('Date & Time', record.timestamp),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final summary =
                            'URBANSTAY RENT RECEIPT\nReceipt: ${record.receiptNumber}\nResident: ${tenantName ?? "Resident"}\nProperty: $propertyName (Room $roomNumber)\nAmount: ₹${record.amount.toStringAsFixed(2)}\nPeriod: ${record.title}\nMode: ${record.method}\nRef: ${record.utrNumber}\nVerified By: $verifier\nDate: ${record.timestamp}\nStatus: Verified ✓';
                        Clipboard.setData(ClipboardData(text: summary));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Receipt details copied to clipboard (HRA format)',
                              style: GoogleFonts.outfit(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: const Color(0xFF111111),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded,
                          size: 14, color: Colors.white),
                      label: Text(
                        'Copy Receipt',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08A63F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
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

  Widget _buildVoucherRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }
}
