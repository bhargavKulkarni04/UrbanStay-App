import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/urban_loading.dart';

/// Security Deposit Refund Details Screen (UPI / Bank Account)
class DepositRefundScreen extends StatefulWidget {
  final String? tenantId;
  final String? propertyId;

  const DepositRefundScreen({
    super.key,
    this.tenantId,
    this.propertyId,
  });

  @override
  State<DepositRefundScreen> createState() => _DepositRefundScreenState();
}

class _DepositRefundScreenState extends State<DepositRefundScreen> {
  final _upiController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _holderController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRefundDetails();
  }

  Future<void> _loadExistingRefundDetails() async {
    if (widget.tenantId == null || widget.tenantId!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await SupabaseService.instance.client
          .from('tenants')
          .select('refund_upi_id, emergency_contact_name')
          .eq('id', widget.tenantId!)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _upiController.text = res['refund_upi_id']?.toString() ?? '';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveRefundDetails() async {
    final upi = _upiController.text.trim();
    if (upi.isEmpty && _accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid UPI ID or Bank Account Number',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.ink,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    UrbanLoadingService.show('Saving refund account details...');

    try {
      if (widget.tenantId != null && widget.tenantId!.isNotEmpty) {
        await SupabaseService.instance.client
            .from('tenants')
            .update({'refund_upi_id': upi.isNotEmpty ? upi : _accountController.text.trim()})
            .eq('id', widget.tenantId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deposit refund details saved successfully.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.greenDark,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: $e',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      UrbanLoadingService.hide();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Deposit Refund Account',
          style: GoogleFonts.outfit(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refund UPI ID (Fastest)',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _upiController,
                            decoration: InputDecoration(
                              hintText: 'e.g. mobile@okaxis or name@paytm',
                              hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRefundDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Save Refund Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
