import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Notice Model representing an official announcement
class NoticeItem {
  final String title;
  final String timestamp;
  final String description;
  final bool isLiveAlert;

  const NoticeItem({
    required this.title,
    required this.timestamp,
    required this.description,
    this.isLiveAlert = false,
  });
}

/// 📋 Tenant Notice Board Screen
/// Clean, minimalist broadcast notice board with live timings and zero emojis.
class TenantNoticeBoardScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const TenantNoticeBoardScreen({
    super.key,
    this.onBack,
  });

  static const List<NoticeItem> _notices = [
    NoticeItem(
      title: 'Overhead Tank Cleaning & Pressure Wash',
      timestamp: '15 mins ago • Live Alert',
      description:
          'Terrace water tanks will undergo deep pressure cleaning today between 10:00 AM and 1:00 PM. Water supply will be temporarily paused. Please store adequate drinking and bucket water.',
      isLiveAlert: true,
    ),
    NoticeItem(
      title: '3rd Floor Wi-Fi Router Maintenance',
      timestamp: '2 hours ago',
      description:
          'Wi-Fi router on the 3rd floor is being upgraded to 300 Mbps commercial fiber mesh. Internet connectivity may pause for 10 minutes during the reboot cycle.',
    ),
    NoticeItem(
      title: 'Main Entrance Gate Closing Time 11:00 PM',
      timestamp: 'Today, 9:00 AM',
      description:
          'For resident security, the main entrance shutter is locked at 11:00 PM. Residents arriving late due to office shift timings must inform Warden Suresh in advance via WhatsApp.',
    ),
    NoticeItem(
      title: 'Monthly Rent Payment Due by 5th',
      timestamp: 'Yesterday, 6:30 PM',
      description:
          'Please clear your monthly rent dues on or before the 5th of every month via direct UPI to avoid a late fee of 100 rupees per day. Instant tax receipts are generated in the app.',
    ),
    NoticeItem(
      title: 'Bi-Weekly Pest Control & Fumigation Drive',
      timestamp: '22 Sep 2026',
      description:
          'General pest control and mosquito fogging will take place on Saturday from 3:00 PM across all common corridors, dining hall, and staircase areas. Keep room doors closed.',
    ),
  ];

  String _getFormattedDateHeader() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${now.day} ${months[now.month - 1]} (${shortDays[now.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notice Board',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Maruthi Luxury PG • Official Announcements',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  _getFormattedDateHeader(),
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RECENT NOTICES HEADER (Solid Deep Black, No Background, Zero Emoji)
              Text(
                'RECENT NOTICES',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // NOTICES LIST
              ..._notices.map((notice) => _buildNoticeCard(notice)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 📦 Individual Notice Card (Parent Card with In-House Green Title and Live Timing)
  Widget _buildNoticeCard(NoticeItem notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notice.isLiveAlert
              ? AppColors.green.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
          width: notice.isLiveAlert ? 1.3 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title in Solid Deep Black (Executive & Readable)
          Text(
            notice.title,
            style: GoogleFonts.outfit(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          // Live Timing (Pure Text, No Emoji)
          Text(
            notice.timestamp,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: notice.isLiveAlert ? FontWeight.w700 : FontWeight.w500,
              color: notice.isLiveAlert ? AppColors.greenDark : AppColors.muted,
            ),
          ),

          const SizedBox(height: 10),

          // Description Text
          Text(
            notice.description,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
