import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'personal_details_screen.dart';
import 'property_details_screen.dart';
import 'property_support_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String tenantName;
  final String floor;
  final String roomNumber;
  final String? avatarUrl;

  const ProfileSettingsScreen({
    super.key,
    this.tenantName = 'Bhargav S Kulkarni',
    this.floor = 'Floor 1',
    this.roomNumber = 'Room 104',
    this.avatarUrl,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late String _tenantName;
  late String _floor;
  late String _roomNumber;

  @override
  void initState() {
    super.initState();
    _tenantName = widget.tenantName;
    _floor = widget.floor;
    _roomNumber = widget.roomNumber;
  }

  @override
  Widget build(BuildContext context) {
    // 7 cards specified in exact order
    final cardTitles = [
      'Personal details',
      'Property details & rent',
      'Property management support',
      'Privacy policy',
      'Terms and condition',
      'Logout',
      'Delete account',
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Brand green fading from top down to pure white at Privacy Policy
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.28, 0.55, 1.0],
            colors: [
              Color(0xFFD2F5DC), // In-house UrbanStay green soft start
              Color(0xFFE9F9EE),
              Colors.white, // Pure white starting at card 4 (Privacy policy)
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar with Back Button
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                    const SizedBox(height: 16),

                    // ─── Header: Avatar | Bifurcation Line | Name & Room ───
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Circle Avatar (Left side)
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.greenLight,
                            backgroundImage: widget.avatarUrl != null
                                ? NetworkImage(widget.avatarUrl!)
                                : null,
                            child: widget.avatarUrl == null
                                ? Text(
                                    _getInitials(_tenantName),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.greenDark,
                                    ),
                                  )
                                : null,
                          ),

                          const SizedBox(width: 14),

                          // 2. Visible Vertical Bifurcation Line (|)
                          Container(
                            width: 1.5,
                            height: 38,
                            color: const Color(0xFFD1D5DB),
                          ),

                          const SizedBox(width: 14),

                          // 3. Name (Top) & Floor / Room Number (Under Name) - Non Editable
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tenantName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$_floor • $_roomNumber',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
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

                    const SizedBox(height: 24),

                    // ─── 7 Simple Cards (White BG, Black Title, Not Bold, Trailing '>') ───
                    ...cardTitles.map((title) => _buildSimpleCard(title)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Clean, minimal card with trailing '>' and special red styling for Delete account
  Widget _buildSimpleCard(String title) {
    final isDeleteAccount = title.toLowerCase() == 'delete account';

    return InkWell(
      onTap: () => _handleCardTap(title),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isDeleteAccount ? AppColors.danger : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDeleteAccount ? AppColors.danger : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDeleteAccount
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight
                    .w400, // Black color (or white for delete), not bold
                color: isDeleteAccount ? Colors.white : AppColors.ink,
              ),
            ),
            Text(
              '>',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDeleteAccount
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardTap(String title) async {
    switch (title) {
      case 'Personal details':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonalDetailsScreen(
              initialName: _tenantName,
            ),
          ),
        );
        break;

      case 'Property details & rent':
        final result = await Navigator.of(context).push<Map<String, String>>(
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(
              initialFloor: _floor,
              initialRoom: _roomNumber,
            ),
          ),
        );
        if (result != null && mounted) {
          setState(() {
            if (result['floor'] != null && result['floor']!.isNotEmpty) {
              _floor = result['floor']!;
            }
            if (result['room'] != null && result['room']!.isNotEmpty) {
              _roomNumber = result['room']!;
            }
          });
        }
        break;

      case 'Property management support':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PropertySupportScreen(),
          ),
        );
        break;

      case 'Privacy policy':
      case 'Terms and condition':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title will open in browser.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.ink,
          ),
        );
        break;

      case 'Logout':
        _showConfirmationDialog(
          title: 'Logout',
          message: 'Are you sure you want to log out of UrbanStay?',
          confirmText: 'Logout',
          isDestructive: false,
        );
        break;

      case 'Delete account':
        _showConfirmationDialog(
          title: 'Delete Account',
          message:
              'This will request permanent deletion of your account and data as per store policy.',
          confirmText: 'Request Deletion',
          isDestructive: true,
        );
        break;
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
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
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.danger : AppColors.ink,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.inkSecondary,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title request processed',
                    style: GoogleFonts.outfit(),
                  ),
                  backgroundColor:
                      isDestructive ? AppColors.danger : AppColors.ink,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.danger : AppColors.ink,
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'US';
  }
}
