import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen: Tenant Feature Control (Resident App Controls)
/// Clean, executive enterprise design:
/// - Pure White background (#FFFFFF)
/// - NO icons inside cards (minimalist text + switch only)
/// - Prominent in-house green (#08A63F) bottom CTA bar with crisp white text:
///   "Edit Features" -> in edit mode becomes "Save Changes"
class OwnerTenantControlsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerTenantControlsScreen({super.key, this.onBack});

  @override
  State<OwnerTenantControlsScreen> createState() =>
      _OwnerTenantControlsScreenState();
}

class _OwnerTenantControlsScreenState extends State<OwnerTenantControlsScreen> {
  bool _isEditing = false;

  // Master Feature Toggles (Initial State)
  bool _payViaUpi = true;
  bool _paidViaCash = true;
  bool _raiseTicket = true;
  bool _ticketStatus = true;
  bool _bedsheetChange = true;
  bool _rentAgreement = true;

  // Staged values while in edit mode
  late bool _stagedPayViaUpi;
  late bool _stagedPaidViaCash;
  late bool _stagedRaiseTicket;
  late bool _stagedTicketStatus;
  late bool _stagedBedsheetChange;
  late bool _stagedRentAgreement;

  @override
  void initState() {
    super.initState();
    _resetStaged();
  }

  void _resetStaged() {
    _stagedPayViaUpi = _payViaUpi;
    _stagedPaidViaCash = _paidViaCash;
    _stagedRaiseTicket = _raiseTicket;
    _stagedTicketStatus = _ticketStatus;
    _stagedBedsheetChange = _bedsheetChange;
    _stagedRentAgreement = _rentAgreement;
  }

  void _saveChanges() {
    setState(() {
      _payViaUpi = _stagedPayViaUpi;
      _paidViaCash = _stagedPaidViaCash;
      _raiseTicket = _stagedRaiseTicket;
      _ticketStatus = _stagedTicketStatus;
      _bedsheetChange = _stagedBedsheetChange;
      _rentAgreement = _stagedRentAgreement;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feature controls saved & applied ✓',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          'Tenant Feature Control',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // 1. PAYMENTS SECTION
                  _buildSectionHeader('PAYMENTS'),
                  const SizedBox(height: 6),
                  _buildToggleCard(
                    title: 'Pay Rent via UPI',
                    subtitle:
                        'Allow residents to pay rent online via Direct UPI',
                    value: _isEditing ? _stagedPayViaUpi : _payViaUpi,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedPayViaUpi = v)
                        : null,
                  ),
                  _buildToggleCard(
                    title: 'Paid via Cash',
                    subtitle:
                        'Allow residents to record cash handed to warden/manager',
                    value: _isEditing ? _stagedPaidViaCash : _paidViaCash,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedPaidViaCash = v)
                        : null,
                  ),
                  const SizedBox(height: 18),

                  // 2. HELPDESK SECTION
                  _buildSectionHeader('HELPDESK'),
                  const SizedBox(height: 6),
                  _buildToggleCard(
                    title: 'Raise a Ticket',
                    subtitle:
                        'Allow residents to report electrical/plumbing issues',
                    value: _isEditing ? _stagedRaiseTicket : _raiseTicket,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedRaiseTicket = v)
                        : null,
                  ),
                  _buildToggleCard(
                    title: 'Ticket Status',
                    subtitle:
                        'Allow residents to track progress of raised complaints',
                    value: _isEditing ? _stagedTicketStatus : _ticketStatus,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedTicketStatus = v)
                        : null,
                  ),
                  const SizedBox(height: 18),

                  // 3. HOUSEKEEPING SECTION
                  _buildSectionHeader('HOUSEKEEPING'),
                  const SizedBox(height: 6),
                  _buildToggleCard(
                    title: 'Bedsheet Change',
                    subtitle:
                        'Allow residents to request linen & bedsheet service',
                    value: _isEditing ? _stagedBedsheetChange : _bedsheetChange,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedBedsheetChange = v)
                        : null,
                  ),
                  const SizedBox(height: 18),

                  // 4. TENANCY AGREEMENT SECTION
                  _buildSectionHeader('TENANCY AGREEMENT'),
                  const SizedBox(height: 6),
                  _buildToggleCard(
                    title: 'Rent Agreement',
                    subtitle:
                        'Allow residents to view and sign digital rent agreement',
                    value: _isEditing ? _stagedRentAgreement : _rentAgreement,
                    onChanged: _isEditing
                        ? (v) => setState(() => _stagedRentAgreement = v)
                        : null,
                  ),
                ],
              ),
            ),

            // Fixed Bottom CTA: UrbanStay In-House Green (#08A63F) with White Text
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _resetStaged();
                                  _isEditing = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save Changes',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () => setState(() => _isEditing = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Edit Features',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final bool isInteractive = onChanged != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: value ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                    if (!value) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DISABLED',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.green,
            activeTrackColor: AppColors.green.withValues(alpha: 0.35),
            inactiveThumbColor:
                isInteractive ? Colors.white : const Color(0xFFD1D5DB),
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}
