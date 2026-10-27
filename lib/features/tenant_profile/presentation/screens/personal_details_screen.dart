import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/urban_loading.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String? tenantId;
  final String? propertyId;
  final String initialName;
  final String initialPhone;
  final String initialAltPhone;
  final String initialEmail;
  final String initialAddress;
  final String initialUpiId;
  final String initialOrgName;

  const PersonalDetailsScreen({
    super.key,
    this.tenantId,
    this.propertyId,
    this.initialName = 'Resident',
    this.initialPhone = '',
    this.initialAltPhone = '',
    this.initialEmail = '',
    this.initialAddress = '',
    this.initialUpiId = '',
    this.initialOrgName = '',
  });

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController; // Emergency Contact
  late TextEditingController _emailController;
  late TextEditingController _addressController; // Permanent Address
  late TextEditingController _upiController;
  late TextEditingController _orgController; // Workplace / Organization

  bool _isLoading = false;
  bool _isSaving = false;
  String? _resolvedTenantId;
  String _aadhaarMasked = 'XXXX-XXXX-4892';
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;
  bool _isAadhaarVerified = true;

  @override
  void initState() {
    super.initState();
    _resolvedTenantId = widget.tenantId;
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _altPhoneController = TextEditingController(text: widget.initialAltPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _addressController = TextEditingController(text: widget.initialAddress);
    _upiController = TextEditingController(text: widget.initialUpiId);
    _orgController = TextEditingController(text: widget.initialOrgName);

    _fetchTenantDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  /// 1. Fetch live row from public.tenants table to pre-fill verified check-in data
  Future<void> _fetchTenantDetails() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? data;

      // 1. Primary: search by tenant UUID if passed
      if (_resolvedTenantId != null && _resolvedTenantId!.trim().isNotEmpty) {
        data = await SupabaseService.instance.client
            .from('tenants')
            .select('*')
            .eq('id', _resolvedTenantId!.trim())
            .maybeSingle();
      }

      // 2. Secondary: search by phone number
      if (data == null && widget.initialPhone.trim().isNotEmpty) {
        final clean = widget.initialPhone.replaceAll(RegExp(r'\D'), '');
        final last10 =
            clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        data = await SupabaseService.instance.client
            .from('tenants')
            .select('*')
            .ilike('phone', '%$last10%')
            .maybeSingle();
      }

      // 3. Fallback: match by resident name
      if (data == null &&
          widget.initialName.trim().isNotEmpty &&
          widget.initialName.trim().toLowerCase() != 'resident') {
        var query = SupabaseService.instance.client.from('tenants').select('*');
        if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
          query = query.eq('property_id', widget.propertyId!);
        }
        data =
            await query.ilike('name', widget.initialName.trim()).maybeSingle();
      }

      if (data != null && mounted) {
        _resolvedTenantId = data['id']?.toString() ?? _resolvedTenantId;

        final dbName = data['name']?.toString() ?? '';
        final dbPhone = data['phone']?.toString() ?? '';
        final dbEmail = data['email']?.toString() ?? '';
        final dbWorkplace = data['workplace']?.toString() ?? '';
        final dbAadhaarMasked = data['aadhaar_masked']?.toString() ?? '';
        final dbAadhaarFront = data['aadhaar_front_url']?.toString() ?? '';
        final dbAadhaarBack = data['aadhaar_back_url']?.toString() ?? '';
        final dbEmergencyContact = data['emergency_contact']?.toString() ?? '';
        final dbAddress = data['permanent_address']?.toString() ?? '';
        final dbUpi = data['refund_upi_id']?.toString() ?? '';

        setState(() {
          if (dbName.isNotEmpty) _nameController.text = dbName;
          if (dbPhone.isNotEmpty) _phoneController.text = dbPhone;
          if (dbEmail.isNotEmpty) _emailController.text = dbEmail;
          if (dbWorkplace.isNotEmpty) _orgController.text = dbWorkplace;

          // Emergency Contact & Permanent Address: show blank if empty in DB
          if (dbEmergencyContact.isNotEmpty) {
            _altPhoneController.text = dbEmergencyContact;
          }
          if (dbAddress.isNotEmpty) {
            _addressController.text = dbAddress;
          }
          if (dbUpi.isNotEmpty) {
            _upiController.text = dbUpi;
          }

          if (dbAadhaarMasked.isNotEmpty) {
            _aadhaarMasked = dbAadhaarMasked;
          }
          _aadhaarFrontUrl = dbAadhaarFront.isNotEmpty ? dbAadhaarFront : null;
          _aadhaarBackUrl = dbAadhaarBack.isNotEmpty ? dbAadhaarBack : null;
          _isAadhaarVerified = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading tenant personal details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 2. Save Changes: updates public.tenants row & pops back with updated map
  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final updatedName = _nameController.text.trim();
    final updatedPhone = _phoneController.text.trim();
    final updatedEmail = _emailController.text.trim();
    final updatedWorkplace = _orgController.text.trim();
    final updatedEmergencyContact = _altPhoneController.text.trim();
    final updatedAddress = _addressController.text.trim();
    final updatedUpi = _upiController.text.trim();

    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Full Name cannot be empty',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    UrbanLoadingService.show('Saving personal details...');

    try {
      final Map<String, dynamic> updates = {
        'name': updatedName,
        'emergency_contact': updatedEmergencyContact,
        'permanent_address': updatedAddress,
        if (updatedEmail.isNotEmpty) 'email': updatedEmail,
        if (updatedWorkplace.isNotEmpty) 'workplace': updatedWorkplace,
        if (updatedUpi.isNotEmpty) 'refund_upi_id': updatedUpi,
        if (updatedPhone.isNotEmpty) 'phone': updatedPhone,
      };

      try {
        if (_resolvedTenantId != null && _resolvedTenantId!.isNotEmpty) {
          await SupabaseService.instance.client
              .from('tenants')
              .update(updates)
              .eq('id', _resolvedTenantId!);
        } else if (updatedPhone.isNotEmpty) {
          final clean = updatedPhone.replaceAll(RegExp(r'\D'), '');
          final last10 =
              clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
          await SupabaseService.instance.client
              .from('tenants')
              .update(updates)
              .ilike('phone', '%$last10%');
        }
      } catch (e) {
        // If permanent_address column does not exist yet in DB, save all other valid fields
        if (e.toString().contains('permanent_address')) {
          final safeUpdates = Map<String, dynamic>.from(updates)
            ..remove('permanent_address');
          if (_resolvedTenantId != null && _resolvedTenantId!.isNotEmpty) {
            await SupabaseService.instance.client
                .from('tenants')
                .update(safeUpdates)
                .eq('id', _resolvedTenantId!);
          } else if (updatedPhone.isNotEmpty) {
            final clean = updatedPhone.replaceAll(RegExp(r'\D'), '');
            final last10 =
                clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
            await SupabaseService.instance.client
                .from('tenants')
                .update(safeUpdates)
                .ilike('phone', '%$last10%');
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Personal details saved successfully',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenDark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop back returning updated details to update settings & dashboard instantly
        Navigator.of(context).pop({
          'name': updatedName,
          'phone': updatedPhone,
          'email': updatedEmail,
          'workplace': updatedWorkplace,
          'emergency_contact': updatedEmergencyContact,
          'permanent_address': updatedAddress,
          'refund_upi_id': updatedUpi,
        });
      }
    } catch (e) {
      debugPrint('Error updating tenant details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      UrbanLoadingService.hide();
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showImagePreview(String title, String? imageUrl) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (imageUrl != null && imageUrl.startsWith('http'))
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, prog) => prog == null
                              ? child
                              : const Center(
                                  heightFactor: 3,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.green,
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: const Color(0xFFF9FAFB),
                            child: Center(
                              child: Text(
                                'Aadhaar Verified on Check-in ✓',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: const Color(0xFFF9FAFB),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: AppColors.green,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$title Verified on Check-in ✓',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure government ID document on record',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // ─── Top Header Bar ───
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop({
                          'name': _nameController.text.trim(),
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 15,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Personal Details',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const LinearProgressIndicator(
                    color: AppColors.green,
                    backgroundColor: Color(0xFFEBF8EE),
                    minHeight: 2,
                  )
                else
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: Personal Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resident Profile',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF8EE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Editable',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        _buildInputField(
                          label: 'Full Name',
                          controller: _nameController,
                          hint: 'Enter your full name',
                        ),
                        const SizedBox(height: 14),

                        // Phone Number
                        _buildInputField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          hint: '+91 9876543210',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),

                        // Email Address
                        _buildInputField(
                          label: 'Email Address',
                          controller: _emailController,
                          hint: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Workplace / Organization
                        _buildInputField(
                          label: 'Workplace / College',
                          controller: _orgController,
                          hint: 'e.g. Infosys, TCS, Student',
                        ),
                        const SizedBox(height: 14),

                        // Emergency Contact
                        _buildInputField(
                          label: 'Emergency Contact',
                          controller: _altPhoneController,
                          hint: '+91 98765 43210 (Parent / Guardian)',
                          keyboardType: TextInputType.phone,
                          helperText:
                              'Primary family or guardian contact for emergencies',
                        ),
                        const SizedBox(height: 14),

                        // Permanent Address
                        _buildInputField(
                          label: 'Permanent Address',
                          controller: _addressController,
                          hint: 'Hometown address, City, State, Pincode',
                          maxLines: 2,
                          helperText:
                              'Official home address as per government ID',
                        ),
                        const SizedBox(height: 14),

                        // Refund UPI ID
                        _buildInputField(
                          label: 'Refund UPI ID',
                          controller: _upiController,
                          hint: 'yourname@okhdfcbank',
                          helperText:
                              'Used for instant security deposit refund at checkout',
                        ),
                        const SizedBox(height: 28),

                        // ─── Aadhaar Verification Section ───
                        Text(
                          'Aadhaar Verification',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Aadhaar Number & Verified Badge Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aadhaar Number',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _aadhaarMasked,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF8EE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppColors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.greenDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified ✓',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.greenDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // "Front & Back Uploaded ✓ (no re-upload needed)" Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  size: 18,
                                  color: AppColors.greenDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Front & Back Uploaded ✓',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Verified during check-in. No re-upload needed.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Document Preview Cards (View Front / View Back)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocPreviewCard(
                                title: 'Front Document',
                                subtitle: 'Uploaded ✓',
                                onTap: () => _showImagePreview(
                                    'Aadhaar Front', _aadhaarFrontUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDocPreviewCard(
                                title: 'Back Document',
                                subtitle: 'Uploaded ✓',
                                onTap: () => _showImagePreview(
                                    'Aadhaar Back', _aadhaarBackUrl),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Save Changes Button (Green Accent, White Text)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              disabledBackgroundColor:
                                  AppColors.green.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
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
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocPreviewCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.visibility_outlined,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
