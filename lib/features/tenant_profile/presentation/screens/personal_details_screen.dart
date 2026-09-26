import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialAltPhone;
  final String initialEmail;
  final String initialAddress;
  final String initialUpiId;
  final String initialOrgName;

  const PersonalDetailsScreen({
    super.key,
    this.initialName = 'Bhargav S Kulkarni',
    this.initialPhone = '+91 8618818322',
    this.initialAltPhone = '',
    this.initialEmail = 'bhargav@urbanstay.living',
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
  late TextEditingController _altPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _upiController;
  late TextEditingController _orgController;

  bool _hasAadhaarFront = false;
  bool _hasAadhaarBack = false;
  bool _hasOrgIdCard = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _altPhoneController = TextEditingController(text: widget.initialAltPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _addressController = TextEditingController(text: widget.initialAddress);
    _upiController = TextEditingController(text: widget.initialUpiId);
    _orgController = TextEditingController(text: widget.initialOrgName);
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
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Text(
                            'Back',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: Personal Details with ✎
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Personal Details',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '✎',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppColors.muted,
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

                        // Alternative Phone Number
                        _buildInputField(
                          label: 'Alternative Phone Number',
                          controller: _altPhoneController,
                          hint: 'Optional secondary contact',
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

                        // Permanent Address
                        _buildInputField(
                          label: 'Permanent Address',
                          controller: _addressController,
                          hint: 'Hometown address, City, Pincode',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),

                        // Refund UPI ID
                        _buildInputField(
                          label: 'Refund UPI ID',
                          controller: _upiController,
                          hint: 'yourname@okhdfcbank',
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

                        // Aadhaar Number (Locked)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
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
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'XXXX-XXXX-4892',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Locked',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Aadhaar Front & Back Upload Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildUploadCard(
                                title: 'Front Image',
                                isUploaded: _hasAadhaarFront,
                                onTap: () {
                                  setState(() => _hasAadhaarFront = !_hasAadhaarFront);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildUploadCard(
                                title: 'Back Image',
                                isUploaded: _hasAadhaarBack,
                                onTap: () {
                                  setState(() => _hasAadhaarBack = !_hasAadhaarBack);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ─── College / Office ID Section ───
                        Text(
                          'College / Office ID',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildInputField(
                          label: 'Organization / College Name',
                          controller: _orgController,
                          hint: 'Leave blank if not applicable',
                        ),
                        const SizedBox(height: 12),

                        _buildUploadCard(
                          title: 'ID Card Photo',
                          isUploaded: _hasOrgIdCard,
                          onTap: () {
                            setState(() => _hasOrgIdCard = !_hasOrgIdCard);
                          },
                        ),
                        const SizedBox(height: 36),

                        // Save Changes Button (Green BG, White Text)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Personal details saved successfully',
                                    style: GoogleFonts.outfit(),
                                  ),
                                  backgroundColor: AppColors.greenDark,
                                ),
                              );
                              Navigator.of(context).maybePop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
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
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUploaded ? AppColors.green : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? 'Uploaded (Tap to change)' : 'Tap to upload',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isUploaded ? AppColors.greenDark : AppColors.muted,
                  ),
                ),
              ],
            ),
            Text(
              '✎',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
