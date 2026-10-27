import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import 'personal_details_screen.dart';
import 'property_details_screen.dart';
import 'property_support_screen.dart';
import 'deposit_refund_screen.dart';
import '../../../tenant_payments/presentation/screens/payment_ledger_screen.dart';
import '../../../tenant_notice/presentation/screens/move_out_notice_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String tenantName;
  final String floor;
  final String roomNumber;
  final String? avatarUrl;
  final String? pgName;
  final String? sharingType;
  final String? tenantId;
  final String? propertyId;
  final String? tenantPhone;
  final double? monthlyRent;
  final double? securityDeposit;

  const ProfileSettingsScreen({
    super.key,
    this.tenantName = 'Resident',
    this.floor = 'Floor 1',
    this.roomNumber = '',
    this.avatarUrl,
    this.pgName,
    this.sharingType,
    this.tenantId,
    this.propertyId,
    this.tenantPhone,
    this.monthlyRent,
    this.securityDeposit,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late String _tenantName;
  late String _floor;
  late String _roomNumber;
  late String _pgName;
  late String _sharingType;

  @override
  void initState() {
    super.initState();
    _tenantName = widget.tenantName.trim().isNotEmpty
        ? widget.tenantName.trim()
        : 'Resident';
    _floor = widget.floor.trim().isNotEmpty ? widget.floor.trim() : 'Floor 1';
    _roomNumber = widget.roomNumber.trim();
    _pgName = (widget.pgName != null && widget.pgName!.trim().isNotEmpty)
        ? widget.pgName!.trim()
        : 'UrbanStay PG';
    _sharingType =
        (widget.sharingType != null && widget.sharingType!.trim().isNotEmpty)
            ? widget.sharingType!.trim()
            : 'Standard Sharing';
  }

  String _getInitial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'R';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const cardItems = [
      _SettingsItem(
        title: 'Personal details',
        subtitle: 'View and update your profile information',
        icon: Icons.person_outline_rounded,
      ),
      _SettingsItem(
        title: 'Deposit refund details',
        subtitle: 'Check your deposit and refund status',
        icon: Icons.currency_rupee_rounded,
      ),
      _SettingsItem(
        title: 'Property details & rent',
        subtitle: 'View property information and rent details',
        icon: Icons.home_outlined,
      ),
      _SettingsItem(
        title: 'Payment ledger & HRA receipts',
        subtitle: 'View rent history and download HRA tax receipts',
        icon: Icons.receipt_long_rounded,
      ),
      _SettingsItem(
        title: 'Stay agreement & house rules',
        subtitle: 'View your signed lease agreement & lock-in terms',
        icon: Icons.description_outlined,
      ),
      _SettingsItem(
        title: 'Move-out notice (30-day)',
        subtitle: 'Submit notice before vacating bed to claim deposit',
        icon: Icons.event_busy_outlined,
      ),
      _SettingsItem(
        title: 'Property management support',
        subtitle: 'Get help from your property manager',
        icon: Icons.headset_mic_outlined,
      ),
      _SettingsItem(
        title: 'Login & security',
        subtitle: 'Manage password or linked Google account',
        icon: Icons.lock_outline_rounded,
      ),
      _SettingsItem(
        title: 'Privacy policy',
        subtitle: 'Learn how we protect your data',
        icon: Icons.shield_outlined,
      ),
      _SettingsItem(
        title: 'Terms and conditions',
        subtitle: 'Read our terms of service',
        icon: Icons.article_outlined,
      ),
      _SettingsItem(
        title: 'Logout',
        subtitle: 'Sign out from your account',
        icon: Icons.logout_rounded,
      ),
      _SettingsItem(
        title: 'Delete account',
        subtitle: 'Permanently delete your account and data',
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
      ),
    ];

    final initial = _getInitial(_tenantName);
    final stayText =
        '$_floor • $_sharingType • Room ${_roomNumber.isNotEmpty ? _roomNumber : '--'}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── 1. Organic Light-Green Gradient Waves Background ───
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.22, 0.44, 1.0],
                  colors: [
                    Color(0xFFD8F4E0), // Soft fresh green top
                    Color(0xFFEBF8EE), // Gentle mint wave
                    Colors.white, // Pure white at cards
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Subtle organic wavy curve accent
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC8F0D3).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6F5DE).withValues(alpha: 0.50),
              ),
            ),
          ),

          // ─── 2. Scrollable Foreground Content ───
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Green "< Back" Bar
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop({'name': _tenantName}),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 15,
                                  color: Color(0xFF068237),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Back',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF068237),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ─── Centered Round Profile Avatar with Camera Badge ───
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Choose profile picture from gallery',
                                style: GoogleFonts.outfit(),
                              ),
                              backgroundColor: AppColors.ink,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDDF7E4),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: widget.avatarUrl != null &&
                                      widget.avatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            initial,
                                            style: GoogleFonts.outfit(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.outfit(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                            ),
                            // Green solid Camera Icon Badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF08A63F),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Resident Name
                      Text(
                        _tenantName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // PG Name
                      Text(
                        _pgName,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Stay Pill: ⌂ Floor 1 • Standard Sharing • Room --
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFDCFCE7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_outlined,
                              size: 14,
                              color: Color(0xFF068237),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stayText,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ─── 3. Floating Action Cards ───
                      ...cardItems.map((item) => _buildSettingsCard(item)),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Floating Card matching the exact screenshot design
  Widget _buildSettingsCard(_SettingsItem item) {
    final isDestructive = item.isDestructive;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: isDestructive ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDestructive
                ? const Color(0xFFDC2626).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCardTap(item.title),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Circular Icon Container (42x42)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFEBF8EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isDestructive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF08A63F),
                  ),
                ),

                const SizedBox(width: 14),

                // Title + Subtitle Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? const Color(0xFFDC2626)
                              : AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDestructive
                              ? const Color(0xFFEF4444)
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing chevron `>`
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDestructive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCardTap(String title) async {
    HapticFeedback.lightImpact();

    switch (title) {
      case 'Personal details':
        final res = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonalDetailsScreen(
              tenantId: widget.tenantId,
              propertyId: widget.propertyId,
              initialName: _tenantName,
              initialPhone: widget.tenantPhone ?? '',
            ),
          ),
        );
        if (res != null && res is Map<String, dynamic>) {
          if (res['name'] != null && (res['name'] as String).trim().isNotEmpty) {
            setState(() {
              _tenantName = (res['name'] as String).trim();
            });
          }
        }
        break;

      case 'Deposit refund details':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DepositRefundScreen(
              tenantId: widget.tenantId,
              propertyId: widget.propertyId,
            ),
          ),
        );
        break;

      case 'Property details & rent':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(
              propertyName: _pgName,
              initialFloor: _floor,
              initialRoom: _roomNumber.isNotEmpty ? _roomNumber : '--',
              sharingType: _sharingType,
              rentAmount: widget.monthlyRent != null && widget.monthlyRent! > 0
                  ? '₹${widget.monthlyRent!.round()}'
                  : '₹8,500',
              depositAmount:
                  widget.securityDeposit != null && widget.securityDeposit! > 0
                      ? '₹${widget.securityDeposit!.round()}'
                      : '₹17,000',
            ),
          ),
        );
        break;

      case 'Payment ledger & HRA receipts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentLedgerScreen(
              tenantId: widget.tenantId,
              propertyId: widget.propertyId,
              tenantName: _tenantName,
              roomNumber: _roomNumber,
              bedLabel: _sharingType,
              propertyName: _pgName,
            ),
          ),
        );
        break;

      case 'Stay agreement & house rules':
        _showStayAgreementSheet();
        break;

      case 'Move-out notice (30-day)':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MoveOutNoticeScreen(
              roomNumber: _roomNumber.isNotEmpty ? _roomNumber : '--',
              bedIdentifier: _sharingType,
              pgName: _pgName,
              propertyId: widget.propertyId,
              tenantId: widget.tenantId,
              tenantName: _tenantName,
              tenantPhone: widget.tenantPhone,
              monthlyRent: widget.monthlyRent ?? 0.0,
              securityDeposit: widget.securityDeposit ?? 0.0,
              refundableDeposit: widget.securityDeposit ?? 0.0,
            ),
          ),
        );
        break;

      case 'Property management support':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertySupportScreen(
              propertyId: widget.propertyId,
              pgName: _pgName,
            ),
          ),
        );
        break;

      case 'Login & security':
        _showLoginSecuritySheet();
        break;

      case 'Privacy policy':
        _showInfoSheet(
          title: 'Privacy Policy',
          content:
              'UrbanStay Technologies Pvt. Ltd. values resident privacy. Personal identification documents (such as Aadhaar or College/Work ID) are encrypted under 256-bit bank-grade TLS protocol and strictly accessible only to your verified property manager for local law compliance.\n\nYour rent transaction records and data are never sold or shared with 3rd-party commercial advertisers.',
        );
        break;

      case 'Terms and conditions':
        _showInfoSheet(
          title: 'Terms and Conditions',
          content:
              '1. Rent is payable on or before the due date agreed in your tenancy agreement.\n2. Security deposit deductions are strictly subject to room condition audits and 30-day notice compliance.\n3. House rules, quiet hours, and visitor access protocols set by the property manager must be respected.',
        );
        break;

      case 'Logout':
        _showConfirmationDialog(
          title: 'Logout',
          message:
              'Are you sure you want to sign out from your resident account on this device?',
          confirmText: 'Sign Out',
          isDestructive: false,
          onConfirm: () async {
            await SupabaseService.instance.client.auth.signOut();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        );
        break;

      case 'Delete account':
        _showConfirmationDialog(
          title: 'Delete Account',
          message:
              'This will initiate permanent deletion of your resident profile and personal documents in accordance with store policies. Past financial ledgers will be archived for statutory tax compliance.',
          confirmText: 'Request Deletion',
          isDestructive: true,
          onConfirm: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Account deletion request submitted to property management.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          },
        );
        break;
    }
  }

  void _showInfoSheet({required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4B5563),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDestructive ? const Color(0xFFDC2626) : AppColors.ink,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? const Color(0xFFDC2626) : AppColors.ink,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              confirmText,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStayAgreementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Stay Agreement & House Rules',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_pgName • Room ${_roomNumber.isNotEmpty ? _roomNumber : '--'}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            _buildAgreementRow('Lock-in Period', '3 Months minimum lock-in'),
            _buildAgreementRow(
                'Notice Period', '30 Days prior move-out notice required'),
            _buildAgreementRow(
                'Monthly Due Date', '5th of every calendar month'),
            _buildAgreementRow('Quiet Hours', '10:30 PM to 06:00 AM daily'),
            _buildAgreementRow(
                'Visitor Access', 'Day visitors allowed in common lobby only'),
            _buildAgreementRow('Cleanliness',
                'Rooms cleaned regularly under housekeeping schedule'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF08A63F)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFF374151)),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginSecuritySheet() {
    final user = SupabaseService.instance.client.auth.currentUser;
    final email = user?.email ?? 'Active Resident Account';
    final isGoogle = user?.appMetadata['provider']
            ?.toString()
            .toLowerCase()
            .contains('google') ??
        false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Login & Security',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    isGoogle
                        ? Icons.verified_user_rounded
                        : Icons.mail_outline_rounded,
                    size: 22,
                    color: const Color(0xFF08A63F),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGoogle
                              ? 'Signed in with Google'
                              : 'Registered Account',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!isGoogle && user?.email != null) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await SupabaseService.instance.client.auth
                        .resetPasswordForEmail(user!.email!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password reset email sent to ${user.email}',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: AppColors.greenDark,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Reset Password via Email',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDestructive;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDestructive = false,
  });
}
