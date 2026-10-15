import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/urban_loading.dart';

/// Screen 7: 0% Direct UPI Payment Approvals & Verification Hub with Audit History.
/// Design System: Pure enterprise UrbanStay aesthetic (Stripe/Linear precision),
/// exact typography, no emojis, high-contrast monospace UTRs, proof viewer,
/// and live migration to Approval History tab upon approval.
class OwnerApprovalsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? propertyId;

  const OwnerApprovalsScreen({super.key, this.onBack, this.propertyId});

  @override
  State<OwnerApprovalsScreen> createState() => _OwnerApprovalsScreenState();
}

class _OwnerApprovalsScreenState extends State<OwnerApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Pending Approvals, 1: Approval History
  String _selectedFloor = 'all'; // 'all', '1st', '2nd', '3rd', 'ground'
  bool _isLoading = true;

  String _destinationAccountName = '';
  String _destinationBankName = '';
  String _destinationUpiId = '';
  String _destinationMaskedAccount = '';

  @override
  void initState() {
    super.initState();
    _loadApprovalsFromSupabase();
  }

  Future<void> _loadApprovalsFromSupabase() async {
    try {
      final targetPropId =
          widget.propertyId ?? SupabaseService.instance.activePropertyId;
      String? propId = targetPropId;
      if (propId == null || propId.isEmpty) {
        final prop = await SupabaseService.instance.getOwnerProperty();
        propId = prop?['id']?.toString();
      }

      // Load destination account dynamically from property & authenticated owner
      PropertyModel? propModel;
      if (propId != null && propId.isNotEmpty) {
        propModel =
            await SupabaseService.instance.getPropertyModel(propertyId: propId);
      }
      if (propModel == null) {
        final propMap =
            await SupabaseService.instance.getOwnerProperty(propertyId: propId);
        if (propMap != null) {
          propModel =
              PropertyModel.fromJson(Map<String, dynamic>.from(propMap));
        }
      }

      final authUser = SupabaseService.instance.currentUser;
      final authName = authUser?.userMetadata?['full_name']?.toString() ??
          authUser?.userMetadata?['name']?.toString();
      final authPhone = authUser?.phone;

      final ownerName = (propModel?.ownerLegalName != null &&
              propModel!.ownerLegalName!.isNotEmpty)
          ? propModel.ownerLegalName!
          : (propModel?.bankHolderName != null &&
                  propModel!.bankHolderName!.isNotEmpty)
              ? propModel.bankHolderName!
              : (authName != null && authName.isNotEmpty)
                  ? authName
                  : (authUser?.email != null && authUser!.email!.isNotEmpty)
                      ? authUser.email!.split('@').first
                      : (authPhone != null && authPhone.isNotEmpty)
                          ? authPhone
                          : '';

      final bankName =
          (propModel?.bankName != null && propModel!.bankName!.isNotEmpty)
              ? propModel.bankName!
              : '';

      final upiId = (propModel?.upiVpa != null && propModel!.upiVpa!.isNotEmpty)
          ? propModel.upiVpa!
          : '';

      final maskedAcc = (propModel?.creditingPhone != null &&
              propModel!.creditingPhone!.length >= 4)
          ? '******${propModel.creditingPhone!.substring(propModel.creditingPhone!.length - 4)}'
          : (authPhone != null && authPhone.length >= 4
              ? '******${authPhone.substring(authPhone.length - 4)}'
              : '');

      if (mounted) {
        setState(() {
          _destinationAccountName = ownerName;
          _destinationBankName = bankName;
          _destinationUpiId = upiId;
          _destinationMaskedAccount = maskedAcc;
        });
      }

      if (propId != null && propId.isNotEmpty) {
        final approvals =
            await SupabaseService.instance.getPaymentApprovalModels(propId);

        if (approvals.isNotEmpty && mounted) {
          setState(() {
            _pendingApprovals.clear();
            _pendingApprovals.addAll(approvals.where((m) => m.isPending));
            _approvalHistory.clear();
            _approvalHistory.addAll(approvals.where((m) => !m.isPending));
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading UPI approvals from Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Active Pending Approvals (Populated live from Supabase)
  final List<PaymentApprovalModel> _pendingApprovals = [];

  // Settled & Rejected Approval History (Populated live from Supabase)
  final List<PaymentApprovalModel> _approvalHistory = [];

  String _getInitials(String name) {
    if (name.isEmpty) return 'TN';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'TN';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minStr = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hourStr:$minStr';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _getFloor(String roomNumber) {
    if (roomNumber.isEmpty) return '1st';
    final firstChar = roomNumber.trim()[0].toUpperCase();
    if (firstChar == 'G') return 'ground';
    if (firstChar == '1') return '1st';
    if (firstChar == '2') return '2nd';
    if (firstChar == '3') return '3rd';
    return '1st';
  }

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
  Future<void> _approvePayment(PaymentApprovalModel item) async {
    final submissionId = item.id;
    if (submissionId.isNotEmpty) {
      final success =
          await SupabaseService.instance.updatePaymentApprovalStatus(
        submissionId: submissionId,
        status: 'APPROVED',
      );
      if (!success) {
        _showToast(
            'Failed to update status in database. Please check connection.');
        return;
      }
    }

    final now = DateTime.now();
    setState(() {
      _pendingApprovals.removeWhere((p) => p.id == item.id);
      _approvalHistory.insert(
        0,
        PaymentApprovalModel(
          id: item.id,
          propertyId: item.propertyId,
          propertyName: item.propertyName,
          tenantId: item.tenantId,
          tenantName: item.tenantName,
          roomNumber: item.roomNumber,
          phone: item.phone,
          ledgerId: item.ledgerId,
          amount: item.amount,
          utrNumber: item.utrNumber,
          paymentApp: item.paymentApp,
          proofImageUrl: item.proofImageUrl,
          status: 'approved',
          approvedBy: item.approvedBy,
          createdAt: now,
        ),
      );
    });
    _showToast(
        '₹${item.amount.toInt()} Approved for ${item.tenantName}. Logged to History & Receipt sent via WhatsApp.');
  }

  void _showApproveConfirmationDialog(PaymentApprovalModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB8ECC8)),
                ),
                child: const Center(
                  child: Icon(Icons.verified_outlined,
                      size: 24, color: AppColors.greenDark),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Confirm Payment Approval',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Approve ₹${item.amount.toInt()} from ${item.tenantName} for ${item.roomNumber}?\nUTR: ${item.utrNumber}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(dialogCtx).pop();
                        await _approvePayment(item);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Yes, Approve',
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
      },
    );
  }

  void _showRejectConfirmationDialog(PaymentApprovalModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Center(
                  child: Icon(Icons.cancel_outlined,
                      size: 24, color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Confirm Payment Rejection',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to reject ₹${item.amount.toInt()} from ${item.tenantName} for ${item.roomNumber}?\nUTR: ${item.utrNumber}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(dialogCtx).pop();
                        await _rejectPayment(item);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Yes, Reject',
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
      },
    );
  }

  Future<void> _rejectPayment(PaymentApprovalModel item) async {
    final submissionId = item.id;
    if (submissionId.isNotEmpty) {
      final success =
          await SupabaseService.instance.updatePaymentApprovalStatus(
        submissionId: submissionId,
        status: 'REJECTED',
      );
      if (!success) {
        _showToast(
            'Failed to reject payment in database. Please check connection.');
        return;
      }
    }

    final now = DateTime.now();
    setState(() {
      _pendingApprovals.removeWhere((p) => p.id == item.id);
      _approvalHistory.insert(
        0,
        PaymentApprovalModel(
          id: item.id,
          propertyId: item.propertyId,
          propertyName: item.propertyName,
          tenantId: item.tenantId,
          tenantName: item.tenantName,
          roomNumber: item.roomNumber,
          phone: item.phone,
          ledgerId: item.ledgerId,
          amount: item.amount,
          utrNumber: item.utrNumber,
          paymentApp: item.paymentApp,
          proofImageUrl: item.proofImageUrl,
          status: 'rejected',
          approvedBy: item.approvedBy,
          createdAt: now,
        ),
      );
    });
    _showToast(
        'Payment rejected for ${item.tenantName}. Logged to History & Alert sent to resident.');
  }

  // ===========================================================================
  // MODAL: PROOF SCREENSHOT VIEWER (Native Bottom Sheet)
  // ===========================================================================
  void _openProofModal(PaymentApprovalModel item) {
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
                        '${item.tenantName} — ₹${item.amount.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'UTR Reference: ${item.utrNumber}',
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
                        child:
                            Icon(Icons.close, size: 15, color: AppColors.muted),
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
                        child: Icon(Icons.check_rounded,
                            size: 30, color: AppColors.greenDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _destinationAccountName.isNotEmpty
                          ? 'Paid to $_destinationAccountName'
                          : 'Payment Received',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    if (_destinationBankName.isNotEmpty || _destinationMaskedAccount.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (_destinationBankName.isNotEmpty) _destinationBankName,
                          if (_destinationMaskedAccount.isNotEmpty)
                            'Account ending in ${_destinationMaskedAccount.replaceAll('*', '')}',
                        ].join(' '),
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '₹${item.amount.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'UPI Ref / UTR: ${item.utrNumber}',
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Close Preview',
                  style: GoogleFonts.outfit(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: UrbanSpinner(size: 38),
        ),
      );
    }

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
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),

              // Title Block
              Text(
                'Payment Approvals',
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
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
                  color: _selectedTabIndex == 0
                      ? Colors.white
                      : Colors.transparent,
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
                      fontWeight: _selectedTabIndex == 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _selectedTabIndex == 0
                          ? AppColors.greenDark
                          : AppColors.muted,
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
                  color: _selectedTabIndex == 1
                      ? Colors.white
                      : Colors.transparent,
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
                      fontWeight: _selectedTabIndex == 1
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _selectedTabIndex == 1
                          ? AppColors.greenDark
                          : AppColors.muted,
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
      if (_selectedFloor != 'all' && _getFloor(p.roomNumber) != _selectedFloor) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        12.0,
        context.responsiveHorizontalPadding,
        96.0,
      ),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        12.0,
        context.responsiveHorizontalPadding,
        96.0,
      ),
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
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                Text(
                  '${_approvalHistory.length} Total Records',
                  style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.green : const Color(0xFFE5E7EB),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_rounded,
                size: 17, color: AppColors.greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (_destinationAccountName.isNotEmpty) _destinationAccountName,
                    if (_destinationBankName.isNotEmpty) _destinationBankName,
                  ].isNotEmpty
                      ? [
                          if (_destinationAccountName.isNotEmpty) _destinationAccountName,
                          if (_destinationBankName.isNotEmpty) _destinationBankName,
                        ].join(' • ')
                      : 'Destination Account',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (_destinationUpiId.isNotEmpty || _destinationMaskedAccount.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (_destinationUpiId.isNotEmpty) 'UPI ID: $_destinationUpiId',
                      if (_destinationMaskedAccount.isNotEmpty) 'A/C: $_destinationMaskedAccount',
                    ].join('  •  '),
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PENDING APPROVAL CARD
  // ===========================================================================
  Widget _buildApprovalCard(PaymentApprovalModel item) {
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
          // Top Row: Avatar + Name & Room
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
                    _getInitials(item.tenantName),
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
                    item.tenantName.isNotEmpty ? item.tenantName : 'Resident',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.roomNumber.isNotEmpty ? item.roomNumber : 'Room'} • ${_getFloor(item.roomNumber)} Floor',
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
                          '₹${item.amount.toInt()}',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        _formatTime(item.createdAt),
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted),
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
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    Text(
                      item.utrNumber,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 18, color: AppColors.muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (item.proofImageUrl != null && item.proofImageUrl!.isNotEmpty)
                                    ? item.proofImageUrl!
                                    : 'Screenshot_UPI_Payment.png',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openProofModal(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'View Proof',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact Actions: Call & WhatsApp
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'Calling ${item.tenantName}: +91${item.phone ?? ''}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/phone.svg',
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                              AppColors.ink, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Call',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      _showToast('WhatsApp opened with ${item.tenantName}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB8ECC8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/whatsapp.svg',
                          width: 15,
                          height: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: [ Reject ] and [ Approve ]
          Row(
            children: [
              // Reject Button
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => _showRejectConfirmationDialog(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5), width: 1.5),
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

              // Approve Button
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _showApproveConfirmationDialog(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Approve',
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
  Widget _buildHistoryCard(PaymentApprovalModel item) {
    final isApproved = item.isApproved;

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
                      color: isApproved
                          ? AppColors.greenLight
                          : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isApproved
                            ? AppColors.green.withValues(alpha: 0.25)
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(item.tenantName),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isApproved
                              ? AppColors.greenDark
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenantName.isNotEmpty ? item.tenantName : 'Resident',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${item.roomNumber.isNotEmpty ? item.roomNumber : 'Room'} • ${_formatTime(item.createdAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '₹${item.amount.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.green : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isApproved ? 'Paid' : 'Rejected',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color:
                            isApproved ? AppColors.greenDark : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                Text(
                  'UTR: ${item.utrNumber}',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
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
          const Icon(Icons.check_circle_outline_rounded,
              size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'All Payments Approved',
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink),
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
