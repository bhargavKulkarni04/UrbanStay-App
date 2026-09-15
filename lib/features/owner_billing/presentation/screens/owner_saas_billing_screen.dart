import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen 13: Owner B2B SaaS Bed Licensing & Billing Screen.
/// Redesigned with generous breathing room, Apple/Linear spacious elegance,
/// focused payment & renewal flow, and locked upgrade progression.
class OwnerSaaSBillingScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerSaaSBillingScreen({super.key, this.onBack});

  @override
  State<OwnerSaaSBillingScreen> createState() => _OwnerSaaSBillingScreenState();
}

class _OwnerSaaSBillingScreenState extends State<OwnerSaaSBillingScreen> {
  bool _isAnnual = false;
  final int _currentTierIndex = 1; // 1: Growth PG (Active Plan)

  final List<Map<String, dynamic>> _tiers = [
    {
      'id': 'starter',
      'title': 'Starter Micro',
      'beds': 'Up to 25 Beds',
      'monthlyPrice': 0,
      'annualPrice': 0,
      'priceDisplay': 'Free Forever',
      'desc': 'For single-floor micro PGs with under 25 residents.',
      'features': ['Up to 25 Beds', '0% Direct UPI Rent Pay', 'WhatsApp PDF Receipts'],
    },
    {
      'id': 'growth',
      'title': 'Growth PG',
      'beds': '26 to 100 Beds',
      'monthlyPrice': 999,
      'annualPrice': 9990,
      'priceDisplay': '₹999',
      'desc': 'For standard full-building PGs and coliving properties.',
      'features': ['Up to 100 Beds', '0% Direct UPI Rent Pay', 'Auto WhatsApp Chaser', 'Mess Headcount RSVP', 'Warden Cash Audit'],
      'isCurrent': true,
    },
    {
      'id': 'mid_scale',
      'title': 'Mid-Scale Hub',
      'beds': '101 to 200 Beds',
      'monthlyPrice': 1299,
      'annualPrice': 12990,
      'priceDisplay': '₹1,299',
      'desc': 'For multi-building owners managing 2 to 3 PG properties.',
      'features': ['Up to 200 Beds', 'Multi-Building Switcher', 'Co-Owner & Manager Access', 'CA Financial Statements', 'Priority Support'],
    },
    {
      'id': 'multi_pg',
      'title': 'Multi-PG Network',
      'beds': '201 to 1,000 Beds',
      'monthlyPrice': 1499,
      'annualPrice': 14990,
      'priceDisplay': '₹1,499',
      'desc': 'For large PG clusters with distributed warden teams.',
      'features': ['Up to 1,000 Beds', 'Multi-Property Isolation', 'Custom Domain Standees', 'Bank Webhook APIs', 'Dedicated Account Manager'],
    },
    {
      'id': 'enterprise',
      'title': 'Enterprise Coliving',
      'beds': '1,000+ Beds',
      'monthlyPrice': -1,
      'annualPrice': -1,
      'priceDisplay': 'Custom',
      'desc': 'For institutional coliving operators and student housing networks.',
      'features': ['Unlimited Beds', 'Custom ERP Integration', 'On-Premises Dedicated SLA', 'Tailored Legal Agreement'],
    },
  ];

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
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
            // Top Spacious Header
            _buildSpaciousHeader(),

            // Scrollable Content with Airy Spacing
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Current Active Subscription & Next Payment Due Card
                    _buildSubscriptionPaymentCard(),
                    const SizedBox(height: 20),

                    // 2. Latest Payment Receipt Card
                    _buildLatestReceiptCard(),
                    const SizedBox(height: 20),

                    // 3. Upgrade Property Capacity / Plan Card
                    _buildUpgradeInvitationCard(),
                    const SizedBox(height: 28),

                    // 4. Apple & Google Play Store Legal Disclosures
                    _buildLegalComplianceSection(),
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
  // TOP SPACIOUS HEADER
  // ===========================================================================
  Widget _buildSpaciousHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan & Billing',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Greenview PG • Account #US-560034',
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
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
                    fontWeight: FontWeight.w800,
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
  // CARD 1: SUBSCRIPTION & NEXT PAYMENT DUE (Spacious & Clean)
  // ===========================================================================
  Widget _buildSubscriptionPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Subscription',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Monthly Auto-Debit',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Growth PG Plan',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Licensed for up to 100 beds',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹999',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: AppColors.greenDark,
                    ),
                  ),
                  Text(
                    '/ month + 18% GST',
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEF0F2)),
          const SizedBox(height: 18),

          _buildSpaciousRow('Next Auto-Debit Date', '30 September 2026'),
          const SizedBox(height: 12),
          _buildSpaciousRow('Amount Payable', '₹1,178.82 (incl. 18% GST)'),
          const SizedBox(height: 12),
          _buildSpaciousRow('Payment Method', 'UPI Auto-Debit (bhargav@hdfcbank)'),
          const SizedBox(height: 22),

          ElevatedButton(
            onPressed: () => _openRazorpayModal(amount: 1178.82, planName: 'Growth PG Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card_outlined, size: 17, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Pay & Renew Subscription (₹1,178.82)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
  // CARD 2: LATEST PAYMENT RECEIPT (Airy & Direct)
  // ===========================================================================
  Widget _buildLatestReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Payment Receipt',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SAC 998315',
                  style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #INV-2026-0881',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid on 1 Aug 2026 • ₹1,178.82 (UPI Settled)',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showToast('Downloading Official Tax Invoice PDF (#INV-2026-0881)...'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download_rounded, size: 14, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        'PDF',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD 3: UPGRADE PROPERTY CAPACITY / PLAN
  // ===========================================================================
  Widget _buildUpgradeInvitationCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.upgrade_rounded, size: 22, color: AppColors.greenDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade Property Capacity',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unlock more beds and multi-building features',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _openPlansUpgradeModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore & Upgrade Plans',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. APPLE & GOOGLE PLAY STORE LEGAL COMPLIANCE SECTION
  // ===========================================================================
  Widget _buildLegalComplianceSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription & Billing Terms',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Auto-Renewal: Your subscription automatically renews every month unless cancelled at least 24 hours before the cycle ends.\n• Refund Policy: 7-day unconditional money-back guarantee for new property licenses.\n• Taxes: 18% GST itemized under SAC Code 998315 (Software as a Service).',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _showToast('Auto-renewal cancellation requested. Plan active until 30 Sep 2026.'),
            child: Text(
              'Cancel Auto-Renewal Subscription',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL: UPGRADE PLANS SELECTOR (Locked Progression — Higher Plans Only)
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),

                  // Header with Monthly/Annual Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade Property Plan',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                          Text(
                            'Select a plan higher than your current capacity',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.close, size: 16, color: AppColors.muted)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Monthly vs Annual Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCycleButton('Monthly Billing', !_isAnnual, () {
                            setModalState(() => _isAnnual = false);
                            setState(() => _isAnnual = false);
                          }),
                        ),
                        Expanded(
                          child: _buildCycleButton('Annual (20% OFF)', _isAnnual, () {
                            setModalState(() => _isAnnual = true);
                            setState(() => _isAnnual = true);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrollable List of Plans
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _tiers.length,
                      itemBuilder: (context, idx) {
                        final t = _tiers[idx];
                        final isCurrent = idx == _currentTierIndex;
                        final isLower = idx < _currentTierIndex;
                        final isHigher = idx > _currentTierIndex;

                        int price = _isAnnual ? (t['annualPrice'] as int) : (t['monthlyPrice'] as int);
                        String priceText = price == 0
                            ? 'Free Forever'
                            : price == -1
                                ? 'Custom Quote'
                                : _isAnnual
                                    ? '₹${price.toString()} / year'
                                    : '₹${price.toString()} / month';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.greenLight
                                : isLower
                                    ? const Color(0xFFFAFAFA)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.green
                                  : isLower
                                      ? const Color(0xFFEEF0F2)
                                      : const Color(0xFFE5E7EB),
                              width: isCurrent ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        t['title'] as String,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: isCurrent ? AppColors.greenDark : AppColors.ink,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.green,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'CURRENT ACTIVE',
                                            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
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
                                      color: isCurrent ? AppColors.greenDark : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t['beds']} • ${t['desc']}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                              ),
                              const SizedBox(height: 12),

                              // Features List
                              ...((t['features'] as List<String>).map((f) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: isLower ? AppColors.muted : AppColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        f,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isLower ? AppColors.muted : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })),
                              const SizedBox(height: 14),

                              // Action Button depending on tier hierarchy
                              if (isCurrent)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Active Plan',
                                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                                  ),
                                )
                              else if (isLower)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Current Plan is Higher',
                                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    if (price == -1) {
                                      _showToast('Enterprise Sales: Dialing +91 86188 18322...');
                                    } else {
                                      final double baseAmt = price.toDouble();
                                      final double totalWithGst = baseAmt * 1.18;
                                      _openRazorpayModal(amount: totalWithGst, planName: t['title'] as String);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ink,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(42),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    price == -1 ? 'Contact Sales' : 'Upgrade to ${t['title']}',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
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
              ? const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // RAZORPAY CHECKOUT MODAL
  // ===========================================================================
  void _openRazorpayModal({required double amount, required String planName}) {
    final basePrice = amount / 1.18;
    final gst = amount - basePrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
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
                        'Razorpay Secure Checkout',
                        style: GoogleFonts.outfit(fontSize: 17.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                      Text('UrbanStay Technologies Pvt. Ltd. (SAC 998315)', style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted)),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.close, size: 15, color: AppColors.muted)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Itemized Bill
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildBillRow('Plan: $planName', '₹${basePrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildBillRow('CGST (9%)', '₹${(gst / 2).toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildBillRow('SGST (9%)', '₹${(gst / 2).toStringAsFixed(2)}'),
                    const Divider(height: 20, color: Color(0xFFE5E7EB)),
                    _buildBillRow('Total Payable Amount', '₹${amount.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Payment of ₹${amount.toStringAsFixed(2)} successful via Razorpay ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ₹${amount.toStringAsFixed(2)} via Razorpay',
                      style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpaciousRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppColors.ink : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold ? AppColors.greenDark : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
