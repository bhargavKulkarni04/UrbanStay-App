import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/screens/phone_verify_screen.dart';

/// Screen 1: App Onboarding Walkthrough for UrbanStay.
/// Exact 1-to-1 replication of `ProductionCode/app_preview.html`.
/// Features interactive human touch scrolling on the right-side feature cards,
/// and an isolated, fully active emerald green `Continue` CTA button.
class OnboardingWalkthroughScreen extends StatefulWidget {
  final VoidCallback? onContinuePressed;

  const OnboardingWalkthroughScreen({
    super.key,
    this.onContinuePressed,
  });

  @override
  State<OnboardingWalkthroughScreen> createState() =>
      _OnboardingWalkthroughScreenState();
}

class _OnboardingWalkthroughScreenState
    extends State<OnboardingWalkthroughScreen> {
  late final ScrollController _scrollController;

  static const List<Map<String, dynamic>> _featureCards = [
    {
      'title': 'Digital Rent Receipt',
      'sub': 'Instant HRA tax receipts',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'title': 'Room Management',
      'sub': 'Manage rooms & beds',
      'icon': Icons.apartment_rounded,
    },
    {
      'title': 'Rent Collection',
      'sub': '0% fee direct UPI pay',
      'icon': Icons.currency_rupee_rounded,
    },
    {
      'title': 'Maintenance Request',
      'sub': 'Track repairs in real-time',
      'icon': Icons.build_rounded,
    },
    {
      'title': 'Occupancy Overview',
      'sub': 'Live vacant bed status',
      'icon': Icons.bar_chart_rounded,
    },
    {
      'title': 'Visitor Management',
      'sub': 'Digital guest entry passes',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Tenant Onboarding',
      'sub': '6-digit room PIN check-in',
      'icon': Icons.key_rounded,
    },
    {
      'title': 'Payment History',
      'sub': 'View past invoices',
      'icon': Icons.history_rounded,
    },
    {
      'title': 'Reports & Analytics',
      'sub': 'Revenue & net profit',
      'icon': Icons.pie_chart_outline_rounded,
    },
    {
      'title': 'Notices & Alerts',
      'sub': 'Instant building updates',
      'icon': Icons.notifications_none_rounded,
    },
    {
      'title': 'WhatsApp Dues Chaser',
      'sub': 'Automated UPI reminders',
      'icon': Icons.chat_bubble_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _handleContinue() {
    debugPrint('[UrbanStay] Screen 1 Continue TAPPED -> Navigating to PhoneVerifyScreen');
    if (widget.onContinuePressed != null) {
      widget.onContinuePressed!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PhoneVerifyScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Isolated, 100% touch-responsive Bottom Action Bar
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 2-Step Indicator Dots (active green capsule + inactive circle)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Full-Width High-Contrast Emerald Green CTA Button
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.green.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: AppTypography.bodySemiBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
          child: Column(
            children: [
              // 1. Center Hero Typography (Exact match from app_preview.html)
              Text(
                'PG & CO-LIVING MANAGEMENT',
                textAlign: TextAlign.center,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: AppColors.muted,
                ),
              ),

              const SizedBox(height: 10),

              // Headline: "One App that / handles everything / your PG needs."
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.heading1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.2,
                    color: AppColors.ink,
                  ),
                  children: const [
                    TextSpan(text: 'One App that\n'),
                    TextSpan(text: 'handles everything\n'),
                    TextSpan(text: 'your '),
                    TextSpan(
                      text: 'PG needs.',
                      style: TextStyle(color: AppColors.green),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  'Manage rooms, tenants, rent collection, maintenance, notices and analytics—all from one intuitive platform.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyRegular.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Split Stage: Phone Mockup on Left + Touch Scrollable Card Flow on Right
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Side: Phone Mockup (46% width)
                    Expanded(
                      flex: 46,
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 330),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/phone_mockup_tenant.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 280,
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBg,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      size: 48,
                                      color: AppColors.green,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right Side: Human Touch Scrollable Card Stream (54% width)
                    Expanded(
                      flex: 54,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _featureCards.length,
                        itemBuilder: (context, index) {
                          final card = _featureCards[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Green Outlined Icon Circle
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.green,
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    card['icon'] as IconData,
                                    size: 16,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Card Text Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        card['title'] as String,
                                        style: AppTypography.bodySemiBold.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        card['sub'] as String,
                                        style: AppTypography.subtitleMuted.copyWith(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
