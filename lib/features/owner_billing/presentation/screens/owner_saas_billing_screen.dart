import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cashfree_launcher.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';
import 'package:urbanstay/features/owner_settings/presentation/screens/owner_settings_screen.dart';

class OwnerSaaSBillingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? propertyId;
  final String? propertyName;
  final int? totalBeds;
  final String? ownerName;

  const OwnerSaaSBillingScreen({
    super.key,
    this.onBack,
    this.propertyId,
    this.propertyName,
    this.totalBeds,
    this.ownerName,
  });

  @override
  State<OwnerSaaSBillingScreen> createState() => _OwnerSaaSBillingScreenState();
}

class _OwnerSaaSBillingScreenState extends State<OwnerSaaSBillingScreen> {
  late int _totalBeds;
  final int _pricePerBed = 15;
  final int _platformFee = 79;
  late String _activePropertyName;
  List<SaasInvoiceModel> _invoices = [];
  bool _isMandateActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _totalBeds = widget.totalBeds ?? 0;
    _activePropertyName = widget.propertyName ?? '';
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    try {
      if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        final metrics = await SupabaseService.instance.getBedMetrics(widget.propertyId!);
        final int beds = metrics['total'] ?? 0;
        if (beds > 0 && mounted) {
          setState(() {
            _totalBeds = beds;
          });
        }
      } else {
        final prop = await SupabaseService.instance.getPropertyModel();
        if (prop != null) {
          final propId = prop.id;
          final metrics = await SupabaseService.instance.getBedMetrics(propId);
          final int beds = metrics['total'] ?? 0;
          if (mounted) {
            setState(() {
              if (widget.propertyName == null) {
                _activePropertyName = prop.propertyName.isNotEmpty ? prop.propertyName : _activePropertyName;
              }
              if (widget.totalBeds == null && beds > 0) {
                _totalBeds = beds;
              }
            });
          }
        }
      }

      final invoicesList = await SupabaseService.instance.getSaasInvoiceModels();
      if (mounted) {
        setState(() {
          _invoices = invoicesList;
        });
      }
    } catch (e) {
      debugPrint('Error loading billing data: $e');
    }
  }

  int get _bedLicenseCost => _totalBeds * _pricePerBed;
  int get _totalDue => _bedLicenseCost + _platformFee;

  Future<void> _activateMandate() async {
    setState(() => _isLoading = true);

    try {
      // Calls Cloudflare Pages backend function which securely talks to Cashfree
      final res = await http.post(
        Uri.parse('https://urbanstay.living/api/cashfree-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': _totalDue,
          'customer_id': 'owner_bhargav',
          'phone': '9876543210',
          'name': 'Bhargav Kulkarni',
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final sessionId = data['payment_session_id'];
        if (sessionId != null && sessionId.toString().isNotEmpty) {
          // Launch OFFICIAL Cashfree Checkout Web SDK
          final mode = data['environment'] ?? 'production';
          launchCashfreeWebCheckout(sessionId.toString(), mode: mode.toString());
        } else {
          _showError('Order created but payment_session_id missing: ${res.body}');
        }
      } else {
        String msg = 'Cashfree Order Failed (${res.statusCode})';
        try {
          final errData = jsonDecode(res.body);
          msg = errData['error'] ?? errData['message'] ?? res.body;
        } catch (_) {
          msg = res.body;
        }
        _showError(msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Cashfree API error: $e\nEnsure functions/api/cashfree-order.js is deployed on Cloudflare Pages with CF_APP_ID & CF_SECRET_KEY.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 6),
      ),
    );
  }




  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OwnerSettingsScreen(initialView: 'property'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF111111), size: 20),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'UrbanStay',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: const Color(0xFF111111),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_activePropertyName.isNotEmpty ? _activePropertyName : "My PG"} • $_totalBeds ${_totalBeds == 1 ? "Bed (Test)" : "Beds"}',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------------------------------------------------------------
            // 1. TRIAL STATUS CARD
            // -------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRIAL STATUS',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        _isMandateActive ? 'Mandate Active' : 'Active',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '12 Days Remaining in Free Trial',
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free access until 1 September 2026',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      value: 0.62,
                      minHeight: 4,
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // -------------------------------------------------------------
            // 2. UPCOMING BILLING SUMMARY
            // -------------------------------------------------------------
            Text(
              'UPCOMING BILLING SUMMARY',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryRow('First Invoice Date', '1 Sep 2026'),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Billing Period', '1 Sep 2026 – 30 Sep 2026'),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Total Beds', '$_totalBeds Beds'),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
                  const SizedBox(height: 14),
                  Text(
                    'ITEM BREAKDOWN',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    'Bed Operating License ($_totalBeds Beds × ₹$_pricePerBed/bed)',
                    '₹$_bedLicenseCost.00',
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Platform Fee', '₹$_platformFee.00'),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
                  const SizedBox(height: 14),
                  _buildSummaryRow(
                    'Total Due on 1st of Month',
                    '₹$_totalDue.00',
                    fontSize: 14,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // -------------------------------------------------------------
            // 3. PAYMENT MANDATE SETUP
            // -------------------------------------------------------------
            Text(
              'PAYMENT MANDATE SETUP',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMandateActive
                        ? 'Mandate Status: Active'
                        : 'Mandate Status: Pending Setup',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set up your payment mandate before trial ends to continue using property operations, staff access and receipts.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Button 1: ACTIVATE SUBSCRIPTION & PAY ₹604 (Solid Green Bar, White Text)
             SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _activateMandate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.green.withOpacity(0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'ACTIVATE SUBSCRIPTION & PAY ₹$_totalDue',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // 4. PROPERTY SCALING
            // -------------------------------------------------------------
            Text(
              'PROPERTY SCALING',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add more rooms or floors to your property:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Button 2: Scale Property & Add Beds (Settings) (Solid Green Bar, White Text)
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _navigateToSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Scale Property & Add Beds (Settings)',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Opens Settings → Property Settings → Floors & Bed Capacity',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // -------------------------------------------------------------
            // 5. INVOICES
            // -------------------------------------------------------------
            Text(
              'INVOICES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            if (_invoices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      'No Past Invoices Yet',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Monthly tax invoices will appear here after automated payment settlements.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._invoices.map((inv) {
                final invNum = inv.invoiceNumber.isNotEmpty ? inv.invoiceNumber : 'US-INV-001';
                final dateStr = inv.createdAt != null
                    ? inv.createdAt!.toString().split('T').first
                    : 'Recent';
                final amount = '₹${inv.amount.toStringAsFixed(2)}';
                final status = inv.isPaid ? 'Paid' : 'Pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerInvoiceDetailScreen(
                              invoiceNumber: invNum,
                              dateTimeStr: dateStr,
                              amountStr: amount,
                              statusStr: status,
                              propertyName: _activePropertyName,
                              totalBeds: _totalBeds,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invNum,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      amount,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      status,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {double fontSize = 13, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? const Color(0xFF111111) : const Color(0xFF4B5563),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : fontSize,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: isTotal ? -0.3 : 0,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// DEDICATED FULL-SCREEN: OWNER INVOICE & RECEIPT SCREEN
// ==============================================================================
class OwnerInvoiceDetailScreen extends StatelessWidget {
  final String invoiceNumber;
  final String dateTimeStr;
  final String amountStr;
  final String statusStr;
  final String propertyName;
  final int totalBeds;

  const OwnerInvoiceDetailScreen({
    super.key,
    this.invoiceNumber = 'US-2026-0891',
    this.dateTimeStr = '1 Aug 2026, 10:30 AM',
    this.amountStr = '₹11.00',
    this.statusStr = 'Paid',
    this.propertyName = 'My PG',
    this.totalBeds = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Invoice #$invoiceNumber',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: const Color(0xFF111111),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green Section Header as requested
            Text(
              'PAYMENT INVOICE & RECEIPT',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            // Pure White Card with Hairline Border
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row: Brand & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UrbanStay Technologies',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'B2B SaaS Platform Licensing',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF8EE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFB9F1CA)),
                        ),
                        child: Text(
                          statusStr.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 14),

                  // Metadata Key-Value Rows
                  _buildDetailRow('Invoice Number', invoiceNumber),
                  const SizedBox(height: 10),
                  _buildDetailRow('Date & Time', dateTimeStr),
                  const SizedBox(height: 10),
                  _buildDetailRow('Billing Period', '1 Aug 2026 – 31 Aug 2026'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Billed To', '$propertyName • Bhargav Kulkarni'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Payment Mode', 'Direct UPI AutoPay (Cashfree Verified)'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Transaction Ref / UTR', 'CF-984210385912'),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 14),

                  // Itemized Breakdown
                  _buildDetailRow('Bed Licensing ($totalBeds Bed × ₹10)', '₹10.00'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Platform & WhatsApp Alerts', '₹1.00'),
                  const SizedBox(height: 10),
                  _buildDetailRow('GST (SAC 998315 @ 0% Micro-exempt)', '₹0.00'),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 14),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount Paid',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        amountStr,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Solid Green Download PDF Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tax Invoice $invoiceNumber PDF downloaded successfully',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                label: Text(
                  'DOWNLOAD TAX INVOICE (PDF)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'UrbanStay Technologies Pvt. Ltd. • MSME Registered • SAC Code 998315\nGST Exempt under small business threshold',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }
}

