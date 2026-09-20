import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:urbanstay/features/owner_settings/presentation/screens/owner_settings_screen.dart';

/// Screen 13: Owner B2B SaaS Plan & Billing Screen.
/// Clean 4-card UI:
/// 1. Payment Breakdown (₹999 + ₹49 = ₹1,048 in green, green Pay button)
/// 2. Current Plan (₹999 under 200 beds)
/// 3. Upgrade Capacity (200-400, 400-600, 600+ beds in green + Explore button)
/// 4. Payment History (Month, Year, Paid Date, green amount)
/// + Interactive Swiggy/Zepto-style UPI Checkout Sheet with inline expanding Pay button
class OwnerSaaSBillingScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerSaaSBillingScreen({super.key, this.onBack});

  @override
  State<OwnerSaaSBillingScreen> createState() => _OwnerSaaSBillingScreenState();
}

class _OwnerSaaSBillingScreenState extends State<OwnerSaaSBillingScreen> {
  bool _isAnnual = false;
  final int _currentTierIndex = 0; // 0: Up to 200 Beds (Active)

  final List<Map<String, dynamic>> _tiers = [
    {
      'id': 'tier_200',
      'title': 'Starter PG',
      'beds': 'Up to 200 Beds',
      'monthlyPrice': 999,
      'annualPrice': 9990,
      'desc': 'Single or dual property operations with under 200 residents.',
      'features': [
        'Up to 200 Total Beds',
        '0% Direct Bank UPI Rent Settlements',
        '300 Automated WhatsApp Reminders / mo',
        'Tenant Aadhaar KYC & Room Damage Audit',
        'Warden Cash Ledger Audit',
        '50ms Offline PDF Rent Receipts',
      ],
      'isCurrent': true,
    },
    {
      'id': 'tier_400',
      'title': 'Scale PG',
      'beds': '200 to 400 Beds',
      'monthlyPrice': 1399,
      'annualPrice': 13990,
      'desc': 'Multi-building PG networks with distributed property managers.',
      'features': [
        '200 to 400 Total Beds',
        'Multi-Property Building Switcher',
        'Granular Staff & Manager Permissions',
        '600 Automated WhatsApp Messages / mo',
        'CA Financial Statement & P&L Export',
        'Priority Technical Support',
      ],
      'isCurrent': false,
    },
    {
      'id': 'tier_600',
      'title': 'Enterprise Hub',
      'beds': '400 to 600 Beds',
      'monthlyPrice': 1899,
      'annualPrice': 18990,
      'desc': 'Large coliving and hostel clusters across multiple zones.',
      'features': [
        '400 to 600 Total Beds',
        'Everything in Scale PG',
        '1,000 Automated WhatsApp Messages / mo',
        'Custom Standee QR with Your PG Branding',
        'Priority Direct Phone Support',
      ],
      'isCurrent': false,
    },
    {
      'id': 'tier_mega',
      'title': 'Mega Network',
      'beds': '600+ Beds',
      'monthlyPrice': 2499,
      'annualPrice': 24990,
      'desc': 'Institutional student living networks and multi-city PG chains.',
      'features': [
        '600+ Beds (Unlimited)',
        'Multi-City Property Isolation',
        'Dedicated Account Manager',
        'Custom ERP & Bank API Webhooks',
      ],
      'isCurrent': false,
    },
  ];

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToScaleCapacity() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerSettingsScreen(
          initialView: 'scale_capacity',
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Payment Breakdown
                    _buildPaymentBreakdownCard(),
                    const SizedBox(height: 18),

                    // Card 2: Current Plan
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 18),

                    // Card 3: Upgrade Capacity
                    _buildUpgradeCapacityCard(),
                    const SizedBox(height: 18),

                    // Card 4: Payment History
                    _buildPaymentHistoryCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP HEADER
  // ===========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: AppColors.ink),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan & Billing',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Greenview PG • BTM Layout',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(99),
              border:
                  Border.all(color: AppColors.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Active',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PAYMENT BREAKDOWN (GREEN TOTAL + GREEN BUTTON)
  // ===========================================================================
  Widget _buildPaymentBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          _buildLineItem('Property License (Under 200 Beds)', '₹999'),
          const SizedBox(height: 10),
          _buildLineItem('Platform Fee', '₹49'),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEF0F2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Payable',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '₹1,048',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: AppColors.greenDark, // Vibrant Green
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Next billing date: 30 September 2026',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => _openCheckoutModal(
              planName: 'Starter PG (Under 200 Beds)',
              basePrice: 999,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green, // Solid Green
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pay ₹1,048',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // White Text
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CURRENT PROPERTY PLAN (GREEN PRICE)
  // ===========================================================================
  Widget _buildCurrentPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Plan',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Monthly Billing',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹999',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenDark, // Green
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ month for properties with under 200 beds',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Current configuration: 31 / 35 Beds configured in property setup.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. UPGRADE CAPACITY (GREEN PRICES + EXPLORE MODAL)
  // ===========================================================================
  Widget _buildUpgradeCapacityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upgrade Capacity',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Higher Tiers',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _navigateToScaleCapacity,
            borderRadius: BorderRadius.circular(12),
            child: _buildUpgradeTierRow('200 to 400 Beds', '₹1,399', '/ month'),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _navigateToScaleCapacity,
            borderRadius: BorderRadius.circular(12),
            child: _buildUpgradeTierRow('400 to 600 Beds', '₹1,899', '/ month'),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _navigateToScaleCapacity,
            borderRadius: BorderRadius.circular(12),
            child: _buildUpgradeTierRow('600+ Beds', '₹2,499', '/ month'),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _openPlansUpgradeModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore & Upgrade Plans',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    size: 15, color: AppColors.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PAYMENT HISTORY (MONTH, YEAR, DATE, GREEN AMOUNT)
  // ===========================================================================
  Widget _buildPaymentHistoryCard() {
    final payments = [
      {
        'monthYear': 'August 2026',
        'paidDate': 'Paid on 1 Aug 2026 • 10:45 AM',
        'amount': '₹1,048',
        'ref': 'UPI Ref: 421890241829',
        'invoice': 'INV-2026-08',
      },
      {
        'monthYear': 'July 2026',
        'paidDate': 'Paid on 1 Jul 2026 • 11:20 AM',
        'amount': '₹1,048',
        'ref': 'UPI Ref: 418902189342',
        'invoice': 'INV-2026-07',
      },
      {
        'monthYear': 'June 2026',
        'paidDate': 'Paid on 1 Jun 2026 • 09:15 AM',
        'amount': '₹1,048',
        'ref': 'UPI Ref: 415890123849',
        'invoice': 'INV-2026-06',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment History',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${payments.length} Payments',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 20, color: Color(0xFFEEF0F2)),
            itemBuilder: (context, idx) {
              final p = payments[idx];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['monthYear']!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p['paidDate']!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['ref']!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        p['amount']!,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.greenDark, // Green Color
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _showToast(
                            'Downloading Invoice ${p['invoice']}...'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.download_rounded,
                              size: 14, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FULL-PAGE CHECKOUT — Stripe-style minimal fintech
  // ===========================================================================
  void _openCheckoutModal({
    required String planName,
    required int basePrice,
    bool isAnnual = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CheckoutPage(
          planName: planName,
          basePrice: basePrice,
          onToast: _showToast,
        ),
      ),
    );
  }

  // _buildInteractiveUPIOption is no longer needed (moved inside _CheckoutPage)
  // kept as a no-op stub so callers in tests don't break
  Widget _buildInteractiveUPIOption({
    required String id,
    required String title,
    required String svgAsset,
    required String selectedId,
    required int totalAmount,
    required VoidCallback onSelect,
    required VoidCallback onPay,
    bool isFirst = false,
    bool isLast = false,
  }) =>
      const SizedBox.shrink();

  // ===========================================================================
  // EXPLORE & UPGRADE PLANS MODAL
  // ===========================================================================
  void _openPlansUpgradeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade Property Plan',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Select capacity based on total property beds',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                              child: Icon(Icons.close,
                                  size: 16, color: AppColors.muted)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCycleButton(
                              'Monthly Billing', !_isAnnual, () {
                            setModalState(() => _isAnnual = false);
                            setState(() => _isAnnual = false);
                          }),
                        ),
                        Expanded(
                          child: _buildCycleButton(
                              'Annual (2 Months FREE)', _isAnnual, () {
                            setModalState(() => _isAnnual = true);
                            setState(() => _isAnnual = true);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _tiers.length,
                      itemBuilder: (context, idx) {
                        final t = _tiers[idx];
                        final isCurrent = idx == _currentTierIndex;
                        final isHigher = idx > _currentTierIndex;

                        int price = _isAnnual
                            ? (t['annualPrice'] as int)
                            : (t['monthlyPrice'] as int);
                        String priceText = _isAnnual
                            ? '₹${price.toString()} / year'
                            : '₹${price.toString()} / month';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                isCurrent ? AppColors.greenLight : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.green
                                  : const Color(0xFFE5E7EB),
                              width: isCurrent ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        t['title'] as String,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isCurrent
                                              ? AppColors.greenDark
                                              : AppColors.ink,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.green,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'ACTIVE',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    priceText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isCurrent
                                          ? AppColors.greenDark
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t['beds']} • ${t['desc']}',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: AppColors.muted),
                              ),
                              const SizedBox(height: 12),
                              ...((t['features'] as List<String>).map((f) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          f,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })),
                              const SizedBox(height: 14),
                              if (isCurrent)
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Current Active Plan',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                )
                              else if (isHigher)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _navigateToScaleCapacity();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(42),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Upgrade to ${t['title']}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildCycleButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.greenDark : AppColors.muted,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  Widget _buildLineItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeTierRow(String beds, String price, String suffix) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                beds,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                price,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                suffix,
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
    );
  }
}

// =============================================================================
// FULL-PAGE CHECKOUT — Pure white, Stripe-level minimal fintech
// =============================================================================
class _CheckoutPage extends StatefulWidget {
  final String planName;
  final int basePrice;
  final void Function(String) onToast;

  const _CheckoutPage({
    required this.planName,
    required this.basePrice,
    required this.onToast,
  });

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  String _selectedApp = 'phonepe';

  static const _upiApps = [
    {'id': 'phonepe', 'title': 'PhonePe', 'asset': 'assets/images/phonepe.svg'},
    {'id': 'gpay',    'title': 'Google Pay', 'asset': 'assets/images/gpay.svg'},
    {'id': 'paytm',   'title': 'Paytm UPI', 'asset': 'assets/images/paytm.svg'},
    {'id': 'whatsapp','title': 'WhatsApp Pay','asset':'assets/images/whatsapp.svg'},
  ];

  int get _platformFee => 49;
  int get _total => widget.basePrice + _platformFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Order Summary ──────────────────────────────────────
                    Text(
                      'Order Summary',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _lineRow(widget.planName, '₹${widget.basePrice}',
                              isBold: false),
                          const SizedBox(height: 10),
                          _lineRow('Platform Fee', '₹$_platformFee',
                              isBold: false),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                                height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '₹$_total',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Pay via UPI ───────────────────────────────────────
                    Row(
                      children: [
                        SvgPicture.asset('assets/images/upi.svg',
                            width: 20, height: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pay via UPI',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // UPI option list
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: _upiApps.asMap().entries.map((entry) {
                          final i = entry.key;
                          final app = entry.value;
                          final isFirst = i == 0;
                          final isLast = i == _upiApps.length - 1;
                          final isSelected = _selectedApp == app['id'];

                          return Column(
                            children: [
                              if (!isFirst)
                                const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: Color(0xFFF0F0F0)),
                              InkWell(
                                onTap: () =>
                                    setState(() => _selectedApp = app['id']!),
                                borderRadius: BorderRadius.vertical(
                                  top: isFirst
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          // App icon
                                          Container(
                                            width: 52,
                                            height: 52,
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: const Color(
                                                      0xFFE5E7EB)),
                                            ),
                                            child: SvgPicture.asset(
                                                app['asset']!,
                                                fit: BoxFit.contain),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              app['title']!,
                                              style: GoogleFonts.outfit(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          // Radio dot
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? AppColors.green
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.green
                                                    : const Color(0xFFD1D5DB),
                                                width: 1.8,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Center(
                                                    child: Icon(Icons.check,
                                                        size: 13,
                                                        color: Colors.white),
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                      // Expand pay button when selected
                                      AnimatedCrossFade(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        crossFadeState: isSelected
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        firstChild: const SizedBox.shrink(),
                                        secondChild: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              widget.onToast(
                                                  'Launching ${app['title']} for ₹$_total...');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.green,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(46),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              'Pay ₹$_total via ${app['title']}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Security note ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          '256-bit encrypted • 0% gateway fee • Direct bank settlement',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineRow(String label, String value, {bool isBold = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.ink : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
