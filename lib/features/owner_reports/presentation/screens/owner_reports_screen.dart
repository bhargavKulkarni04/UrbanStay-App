import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen: Owner Business Intelligence & Master Reports Hub.
/// Specific Updates:
/// 1. Pure white cards across all cells (zero gray containers).
/// 2. Horizontally scrollable floor occupancy vertical bars supporting dynamic floor counts.
/// 3. Removed average speed badge.
/// 4. 2-Step OTP Security Shield.
/// 5. Privacy Eye Toggle [  Show /  Hidden ].
class OwnerReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerReportsScreen({super.key, this.onBack});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen> {
  // Security Gatekeeper State
  bool _isUnlocked = false;
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 28;

  // Report Settings
  String _selectedMonth = 'August 2026';
  final List<String> _monthOptions = ['August 2026', 'July 2026', 'June 2026', 'FY 2026-27'];
  bool _isAmountHidden = false;

  // Dynamic Floor Data (Supports any number of floors added by owner)
  final List<Map<String, dynamic>> _floorsData = [
    {'floor': '1st Floor', 'beds': '10/10 Beds', 'pct': '100%', 'fraction': 1.0, 'color': AppColors.green},
    {'floor': '2nd Floor', 'beds': '11/12 Beds', 'pct': '92%', 'fraction': 11 / 12, 'color': AppColors.green},
    {'floor': '3rd Floor', 'beds': '10/13 Beds', 'pct': '77%', 'fraction': 10 / 13, 'color': AppColors.greenDark},
  ];

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  String _formatAmount(int amt) {
    if (_isAmountHidden) return '••••••';
    return '₹${amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatLakh(double val) {
    if (_isAmountHidden) return '••••';
    return '₹${val.toStringAsFixed(1)}L';
  }

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showToast('Please enter complete 6-digit verification code');
      return;
    }
    setState(() => _isUnlocked = true);
    _showToast('✓ Security Verified • Financial Intelligence Unlocked');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildOtpSecurityGatekeeperView();
    }
    return _buildMasterReportsDashboardView();
  }

  // ===========================================================================
  // 1. OTP FINANCIAL SECURITY GATEKEEPER VIEW
  // ===========================================================================
  Widget _buildOtpSecurityGatekeeperView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Security Shield',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.25), width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_outline_rounded, size: 34, color: AppColors.greenDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Enter Owner Verification Code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sensitive monthly P&L, collections & tax audit reports are protected. A 6-digit OTP has been dispatched to your registered phone number:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: Text(
                          '+91 86188 •••• 22',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (idx) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: _otpControllers[idx],
                            focusNode: _otpFocusNodes[idx],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.ink, width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                if (idx < 5) {
                                  _otpFocusNodes[idx + 1].requestFocus();
                                } else {
                                  _otpFocusNodes[idx].unfocus();
                                  _verifyOtp();
                                }
                              } else {
                                if (idx > 0) {
                                  _otpFocusNodes[idx - 1].requestFocus();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resend code in ${_resendCountdown}s',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                        InkWell(
                          onTap: () => _showToast('New OTP dispatched via WhatsApp to +91 86188 •••• 22'),
                          child: Text(
                            'Resend via WhatsApp',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Verify & Unlock Financial Reports',
                            style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
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
  // 2. MASTER REPORTS DASHBOARD VIEW (UNLOCKED)
  // ===========================================================================
  Widget _buildMasterReportsDashboardView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 56.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodAndPrivacyBar(),
                    const SizedBox(height: 20),
                    _buildQuickExportActionBar(),
                    const SizedBox(height: 20),
                    _buildBedsAndVacancySection(),
                    const SizedBox(height: 20),
                    _buildAmountAndRentSection(),
                    const SizedBox(height: 20),
                    _buildRentApprovalsSection(),
                    const SizedBox(height: 20),
                    _buildOperatingExpensesSection(),
                    const SizedBox(height: 20),
                    _buildWorkersAndPayrollSection(),
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
  // TOP STICKY HEADER (UNLOCKED STATE)
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations & Financial Intelligence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Greenview PG • Comprehensive Business Audit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () => setState(() => _isAmountHidden = !_isAmountHidden),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isAmountHidden ? Colors.white : AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isAmountHidden ? const Color(0xFFE5E7EB) : AppColors.green.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAmountHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 15,
                    color: _isAmountHidden ? AppColors.muted : AppColors.greenDark,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isAmountHidden ? 'Hidden' : 'Show',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isAmountHidden ? AppColors.muted : AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PERIOD SELECTOR & PRIVACY BAR
  // ===========================================================================
  Widget _buildPeriodAndPrivacyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_outlined, size: 17, color: AppColors.ink),
              const SizedBox(width: 8),
              Text(
                'Audit Period:',
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonth,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.ink),
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMonth = val);
              },
              items: _monthOptions.map((m) {
                return DropdownMenuItem(value: m, child: Text(m));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1-TAP QUICK EXPORT ACTION BAR
  // ===========================================================================
  Widget _buildQuickExportActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 1.2),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Audit Statements',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '1-Tap instant exports for CA tax filing & police verification',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () => _showToast('Generating 50ms Offline Master Audit PDF...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Download Financial PDF Statement',
                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showToast('Opening WhatsApp with CA / Accountant...'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.greenDark),
                      const SizedBox(width: 6),
                      Text(
                        'WhatsApp to CA',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showToast('Exporting Police Station Dossier ZIP...'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_police_outlined, size: 14, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        'Police Dossier',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
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
  // 1. SECTION 1: BEDS & VACANCY ANALYTICS (PURE WHITE CARDS & SCROLLABLE FLOORS)
  // ===========================================================================
  Widget _buildBedsAndVacancySection() {
    return _buildExecutiveCard(
      title: '1. Beds & Vacancy Analytics',
      subtitle: 'Real-time occupancy yield, vacant beds & 30-day notice pipeline',
      icon: Icons.hotel_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 LARGE, BOLD 2x2 SQUARE CAPACITY CARDS (PURE WHITE)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildLargeSquareMetricCard(
                      'Total Capacity',
                      '35 Beds',
                      '100% Scale',
                      Icons.domain_outlined,
                      AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLargeSquareMetricCard(
                      'Active Tenants',
                      '31 Beds',
                      '88.6% Occupied',
                      Icons.how_to_reg_outlined,
                      AppColors.greenDark,
                      accentBorder: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLargeSquareMetricCard(
                      'Vacant Slots',
                      '4 Beds',
                      'Available Now',
                      Icons.bed_outlined,
                      AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLargeSquareMetricCard(
                      'On Notice',
                      '3 Beds',
                      '30-Day Vacancy Risk',
                      Icons.event_busy_outlined,
                      AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // DYNAMIC SCROLLABLE THICK VERTICAL FLOOR BARS
          _buildSubHeader('Floor-by-Floor Occupancy Yield (Scrollable)'),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _floorsData.map((fl) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildThickVerticalFloorBar(
                      fl['floor'],
                      fl['beds'],
                      fl['pct'],
                      fl['fraction'],
                      fl['color'],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sharing Type Breakdown Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSharingTypeInfo('Single Share', '5 Beds', '100% Full'),
                Container(width: 1, height: 32, color: const Color(0xFFEEF0F2)),
                _buildSharingTypeInfo('2-Sharing', '18 Beds', '89% Full'),
                Container(width: 1, height: 32, color: const Color(0xFFEEF0F2)),
                _buildSharingTypeInfo('3-Sharing', '12 Beds', '83% Full'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SECTION 2: AMOUNT & RENT COLLECTION (WITH DUAL INFLOW/OUTFLOW CHART)
  // ===========================================================================
  Widget _buildAmountAndRentSection() {
    return _buildExecutiveCard(
      title: '2. Amount & Rent Collections',
      subtitle: 'Gross potential, actual collections, pending dues & 0% UPI savings',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBigMetricCard(
                  'Total Collections',
                  _formatAmount(263500),
                  '25 Residents Settled',
                  AppColors.greenDark,
                  AppColors.greenLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBigMetricCard(
                  'Pending Dues',
                  _formatAmount(34000),
                  '6 Dues to Collect',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.savings_outlined, size: 18, color: AppColors.greenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatAmount(5270)} Gateway Fee Saved',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                      ),
                      Text(
                        '100% direct bank UPI settlement at 0% processing deduction',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildSubHeader('6-Month Inflow Trend (Gross Collection)'),
          const SizedBox(height: 12),
          _buildTrendBarChart(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SECTION 3: RENT APPROVALS & VERIFICATION (PURE WHITE & NO AVG SPEED)
  // ===========================================================================
  Widget _buildRentApprovalsSection() {
    return _buildExecutiveCard(
      title: '3. Rent Approvals & Settlements',
      subtitle: '0% Direct UPI bank verification volume & audit status',
      icon: Icons.check_circle_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '92.5% Approved Volume',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '25 of 27 Rent Submissions Verified & Settled in Bank',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSubHeader('Rent Verification Status Breakdown'),
          const SizedBox(height: 10),
          _buildProgressBarRow('Verified & Settled in Bank', '${_formatAmount(263500)} (25 Paid • 92.5%)', 0.925, AppColors.green),
          const SizedBox(height: 10),
          _buildProgressBarRow('Pending Owner Review', '${_formatAmount(17000)} (2 Pending • 7.5%)', 0.075, AppColors.ink),
          const SizedBox(height: 10),
          _buildProgressBarRow('Flagged / Invalid UTRs', '₹0 (0 Flagged • 0%)', 0.0, const Color(0xFF9CA3AF)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.ink),
                    const SizedBox(width: 8),
                    Text(
                      'Total Security Deposits Held:',
                      style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  _formatAmount(465000),
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. SECTION 4: OPERATING EXPENSES (WITH 4-SEGMENT DONUT CHART)
  // ===========================================================================
  Widget _buildOperatingExpensesSection() {
    final List<Map<String, dynamic>> expenses = [
      {'name': 'BESCOM Electricity Bill', 'amount': 18400, 'share': 0.36, 'color': AppColors.ink},
      {'name': 'Kitchen & Grocery Rations', 'amount': 22000, 'share': 0.44, 'color': AppColors.greenDark},
      {'name': 'BWSSB Water & Tanker Supply', 'amount': 6800, 'share': 0.14, 'color': const Color(0xFF4B5563)},
      {'name': 'Wi-Fi, Repairs & Maintenance', 'amount': 3200, 'share': 0.06, 'color': const Color(0xFF9CA3AF)},
    ];

    return _buildExecutiveCard(
      title: '4. Operating Expenses Audit',
      subtitle: 'Itemized electricity, water tanker, grocery rations & repair costs',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Monthly Operating Costs:',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatAmount(50400),
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _ExpenseDonutPainter(
                    segments: [0.44, 0.36, 0.14, 0.06],
                    colors: [AppColors.greenDark, AppColors.ink, const Color(0xFF4B5563), const Color(0xFF9CA3AF)],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kitchen Rations (44%) & BESCOM (36%)',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account for 80% of monthly building operating costs',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...expenses.map((exp) {
            final amtStr = '${_formatAmount(exp['amount'] as int)} (${((exp['share'] as double) * 100).toInt()}%)';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildProgressBarRow(exp['name'], amtStr, exp['share'], exp['color']),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. SECTION 5: WORKERS & STAFF PAYROLL ANALYTICS
  // ===========================================================================
  Widget _buildWorkersAndPayrollSection() {
    return _buildExecutiveCard(
      title: '5. Staff & Worker Payroll Audit',
      subtitle: 'Active building crew, monthly salaries & payout disbursement status',
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricTile('Team Size', '4 Staff', 'Active', AppColors.ink)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Total Payroll', _formatAmount(56000), 'Monthly', AppColors.ink)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Disbursed', _formatAmount(28000), '2 Staff', AppColors.greenDark, bgColor: AppColors.greenLight)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Pending', _formatAmount(28000), '2 Staff', AppColors.ink)),
            ],
          ),
          const SizedBox(height: 16),

          _buildProgressBarRow('Ramesh Kumar (Warden)', '${_formatAmount(18000)} (Paid ✓)', 1.0, AppColors.green),
          const SizedBox(height: 8),
          _buildProgressBarRow('Manjunath (Cook)', '${_formatAmount(16000)} (Pending)', 0.5, AppColors.muted),
          const SizedBox(height: 8),
          _buildProgressBarRow('Lakshmi (Housekeeping)', '${_formatAmount(12000)} (Paid ✓)', 1.0, AppColors.green),
          const SizedBox(height: 8),
          _buildProgressBarRow('Somanna (Night Guard)', '${_formatAmount(10000)} (Pending)', 0.5, AppColors.muted),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE EXECUTIVE CARD & HELPER WIDGETS
  // ===========================================================================
  Widget _buildExecutiveCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Icon(icon, size: 17, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEF0F2)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
    );
  }

  Widget _buildLargeSquareMetricCard(
    String title,
    String val,
    String sub,
    IconData icon,
    Color valColor, {
    Color? accentBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBorder ?? const Color(0xFFE5E7EB), width: accentBorder != null ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: valColor),
              Text(
                sub,
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: valColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: valColor),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildThickVerticalFloorBar(
    String floorName,
    String bedsCount,
    String pctStr,
    double fraction,
    Color barColor,
  ) {
    const double totalHeight = 110.0;
    final double filledHeight = totalHeight * fraction.clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          pctStr,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: barColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: 44,
          height: totalHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0F2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 44,
            height: filledHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Text(
          floorName,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        Text(
          bedsCount,
          style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBigMetricCard(String title, String val, String sub, Color valColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: valColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(val, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: valColor)),
          const SizedBox(height: 3),
          Text(sub, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: valColor)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String val, String sub, Color textColor, {Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(val, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 10, color: textColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildProgressBarRow(String label, String valueStr, double fraction, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            Text(valueStr, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: barColor)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0F2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharingTypeInfo(String label, String beds, String yield) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(beds, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
        Text(yield, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.greenDark)),
      ],
    );
  }

  Widget _buildTrendBarChart() {
    final months = [
      {'m': 'Mar', 'val': 2.4, 'h': 50.0},
      {'m': 'Apr', 'val': 2.5, 'h': 56.0},
      {'m': 'May', 'val': 2.5, 'h': 56.0},
      {'m': 'Jun', 'val': 2.6, 'h': 62.0},
      {'m': 'Jul', 'val': 2.6, 'h': 64.0},
      {'m': 'Aug', 'val': 2.63, 'h': 68.0, 'active': true},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.map((item) {
          final isActive = item['active'] == true;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _formatLakh(item['val'] as double),
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppColors.greenDark : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 26,
                height: item['h'] as double,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.green : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['m'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: 4-SEGMENT EXPENSE DONUT RING
// =============================================================================
class _ExpenseDonutPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;

  _ExpenseDonutPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    var currentAngle = -math.pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = 2 * math.pi * segments[i];
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpenseDonutPainter oldDelegate) => true;
}
