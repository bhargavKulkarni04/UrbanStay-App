import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tenant_payments/presentation/screens/rent_payment_screen.dart';
import '../../../tenant_payments/presentation/screens/paid_via_cash_screen.dart';
import '../../../tenant_payments/presentation/screens/payment_ledger_screen.dart';
import '../../../tenant_payments/presentation/widgets/request_extension_sheet.dart';
import '../../../tenant_helpdesk/presentation/screens/raise_ticket_screen.dart';
import '../../../tenant_helpdesk/presentation/screens/ticket_status_screen.dart';
import '../../../tenant_helpdesk/presentation/screens/washing_machine_booking_screen.dart';
import '../../../tenant_housekeeping/presentation/widgets/room_sweep_sheet.dart';
import '../../../tenant_housekeeping/presentation/widgets/full_room_clean_sheet.dart';
import '../../../tenant_housekeeping/presentation/widgets/bedsheet_change_sheet.dart';
import '../../../tenant_notice/presentation/screens/move_out_notice_screen.dart';
import '../../../tenant_food_menu/presentation/screens/tenant_food_menu_screen.dart';
import '../../../tenant_notice_board/presentation/screens/tenant_notice_board_screen.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/supabase_service.dart';

class TenantDashboardScreen extends StatefulWidget {
  final String tenantName;
  final String roomNumber;
  final String bedId;
  final String pgName;
  final String? propertyId;
  final double? monthlyRent;
  final double? securityDeposit;
  final String? tenantPhone;
  final String? sharingType;
  final String? tenantId;

  const TenantDashboardScreen({
    super.key,
    this.tenantName = '',
    this.roomNumber = '',
    this.bedId = '',
    this.pgName = '',
    this.propertyId,
    this.monthlyRent,
    this.securityDeposit,
    this.tenantPhone,
    this.sharingType,
    this.tenantId,
  });

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int _currentNavIndex = 0;
  String _paymentStatus = 'DUE'; // 'DUE' | 'UNDER_REVIEW' | 'PAID'
  String _submittedUtr = '';
  String _submittedPhone = '';
  String _submittedScreenshot = '';
  String? _submittedPaymentMode; // 'UPI' | 'CASH'
  bool get _isPendingCash =>
      _paymentStatus == 'UNDER_REVIEW' &&
      ((_submittedPaymentMode != null && _submittedPaymentMode == 'CASH') ||
          _submittedUtr.startsWith('CASH-'));
  late String _currentCycleMonth;
  late String _currentCycleMonthUpper;
  late String _currentDueDate;
  late String _nextCycleMonth;
  late String _currentMonthShort;

  // Dynamic Tenant & PG State
  late String _tenantName;
  late String _roomNumber;
  late String _bedId;
  late String _pgName;
  String? _propertyId;
  String? _tenantId;
  String? _roomId;
  double _currentRentAmount = 0.0;
  double _currentSecurityDeposit = 0.0;
  String _tenantPhone = '';
  String _sharingType = '';
  String _ownerName = 'Owner';
  String _ownerPhone = '';
  String _ownerUpiId = '';
  String _ownerBankName = '';
  String _propertyLocation = '';
  String? _activeLedgerId;
  MaintenanceTicketModel? _activeTicket;

  @override
  void initState() {
    super.initState();
    _tenantName = widget.tenantName;
    _roomNumber = widget.roomNumber;
    _bedId = widget.bedId;
    _pgName = widget.pgName;
    _propertyId = widget.propertyId;
    _tenantId = widget.tenantId;
    _currentRentAmount = widget.monthlyRent ?? 0.0;
    _currentSecurityDeposit = widget.securityDeposit ?? 0.0;
    _tenantPhone = widget.tenantPhone ?? '';
    _sharingType = widget.sharingType ?? '';

    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    _currentCycleMonth = '${months[now.month - 1]} ${now.year}';
    _currentCycleMonthUpper = months[now.month - 1].toUpperCase();
    _currentDueDate = '05 ${shortMonths[now.month - 1]}';
    _currentMonthShort = shortMonths[now.month - 1];

    final nextMonth = DateTime(now.year, now.month + 1, 1);
    _nextCycleMonth =
        '${months[nextMonth.month - 1]} ${nextMonth.year}'.toUpperCase();

    _loadLiveTenantAndPropertyData();
  }

  Future<void> _loadLiveTenantAndPropertyData() async {
    try {
      // 1. Property Details
      String? pId = _propertyId ?? SupabaseService.instance.activePropertyId;
      if (pId == null || pId.isEmpty) {
        final prop = await SupabaseService.instance.getOwnerProperty();
        pId = prop?['id']?.toString();
      }

      if (pId != null && pId.isNotEmpty) {
        _propertyId = pId;
        final propRes = await SupabaseService.instance.client
            .from('properties')
            .select(
                'property_name, area_locality, city, owner_legal_name, bank_holder_name, upi_vpa, bank_name, rent_due_day')
            .eq('id', pId)
            .maybeSingle();

        if (propRes != null && mounted) {
          setState(() {
            if (_pgName.isEmpty) {
              _pgName = propRes['property_name']?.toString() ?? '';
            }
            final area = propRes['area_locality']?.toString() ?? '';
            final city = propRes['city']?.toString() ?? '';
            final loc = [area, city].where((s) => s.isNotEmpty).join(', ');
            if (loc.isNotEmpty) _propertyLocation = loc;

            final ownerLegal = propRes['owner_legal_name']?.toString();
            final bankHolder = propRes['bank_holder_name']?.toString();
            _ownerName = (ownerLegal != null && ownerLegal.isNotEmpty)
                ? ownerLegal
                : ((bankHolder != null && bankHolder.isNotEmpty)
                    ? bankHolder
                    : '');

            _ownerPhone = propRes['owner_phone']?.toString() ??
                propRes['crediting_phone']?.toString() ??
                '';
            _ownerUpiId = propRes['upi_vpa']?.toString() ?? '';
            _ownerBankName =
                propRes['bank_name']?.toString() ?? 'Direct Bank UPI';

            final dueDay = propRes['rent_due_day']?.toString();
            if (dueDay != null && dueDay.isNotEmpty) {
              final cleanDay =
                  RegExp(r'\d+').firstMatch(dueDay)?.group(0) ?? dueDay;
              _currentDueDate =
                  '${cleanDay.padLeft(2, '0')} $_currentMonthShort';
            }
          });
        }
      }

      // 2. Tenant & Bed details from tenants table if rent, name, or sharing missing
      if (_currentRentAmount == 0.0 ||
          _tenantName.isEmpty ||
          _sharingType.isEmpty ||
          _tenantId == null) {
        Map<String, dynamic>? tenantRecord;

        // 1. Primary: Match by resident phone number
        if (_tenantPhone.isNotEmpty) {
          try {
            tenantRecord =
                await SupabaseService.instance.client.from('tenants').select('''
                  id, room_id, name, phone, room_number, bed_id, sharing_type, monthly_rent, security_deposit,
                  beds!bed_id(bed_label),
                  rooms!room_id(sharing_type)
                ''').eq('phone', _tenantPhone.trim()).maybeSingle();
          } catch (_) {}
        }

        // 2. Secondary fallback: If bedId is a 36-character UUID, try matching by bed_id
        if (tenantRecord == null && _bedId.isNotEmpty && _bedId.length == 36) {
          try {
            tenantRecord =
                await SupabaseService.instance.client.from('tenants').select('''
                  id, room_id, name, phone, room_number, bed_id, sharing_type, monthly_rent, security_deposit,
                  beds!bed_id(bed_label),
                  rooms!room_id(sharing_type)
                ''').eq('bed_id', _bedId).maybeSingle();
          } catch (_) {}
        }

        if (tenantRecord != null && mounted) {
          final bedsData = tenantRecord!['beds'];
          final roomsData = tenantRecord!['rooms'];
          final resolvedBedLabel =
              (bedsData is Map) ? bedsData['bed_label']?.toString() : null;
          final resolvedSharing =
              (roomsData is Map) ? roomsData['sharing_type']?.toString() : null;

          setState(() {
            _tenantId = tenantRecord!['id']?.toString() ?? _tenantId;
            _roomId = tenantRecord!['room_id']?.toString() ?? _roomId;
            if (_currentRentAmount == 0.0) {
              _currentRentAmount =
                  (tenantRecord!['monthly_rent'] as num?)?.toDouble() ?? 0.0;
            }
            if (_currentSecurityDeposit == 0.0) {
              _currentSecurityDeposit =
                  (tenantRecord!['security_deposit'] as num?)?.toDouble() ??
                      0.0;
            }
            if (_tenantName.isEmpty) {
              _tenantName = tenantRecord!['name']?.toString() ?? '';
            }
            if (_tenantPhone.isEmpty) {
              _tenantPhone = tenantRecord!['phone']?.toString() ?? '';
            }
            if (_roomNumber.isEmpty) {
              _roomNumber = tenantRecord!['room_number']?.toString() ?? '';
            }
            // Use relational bed_label if available, else fall back to bed_id
            _bedId = resolvedBedLabel ??
                tenantRecord!['bed_id']?.toString() ??
                _bedId;
            // Use relational sharing_type if available
            _sharingType = resolvedSharing ??
                tenantRecord!['sharing_type']?.toString() ??
                _sharingType;
          });

          // Fetch active ledger row for this tenant for the CURRENT cycle month
          if (_tenantId != null && _tenantId!.isNotEmpty) {
            try {
              // 1. First look for current month's ledger
              var ledgerRes = await SupabaseService.instance.client
                  .from('rent_ledgers')
                  .select('id, rent_amount, due_amount, status, billing_month')
                  .eq('tenant_id', _tenantId!)
                  .eq('billing_month', _currentCycleMonth)
                  .maybeSingle();

              // If new month started and no ledger exists yet, ensure current month ledgers exist
              if (ledgerRes == null && pId != null) {
                await SupabaseService.instance.ensureMonthlyRentLedgers(
                  propertyId: pId,
                  cycleMonth: _currentCycleMonth,
                );
                ledgerRes = await SupabaseService.instance.client
                    .from('rent_ledgers')
                    .select(
                        'id, rent_amount, due_amount, status, billing_month')
                    .eq('tenant_id', _tenantId!)
                    .eq('billing_month', _currentCycleMonth)
                    .maybeSingle();
              }

              if (ledgerRes != null && mounted) {
                setState(() {
                  _activeLedgerId = ledgerRes!['id']?.toString();
                  final due = (ledgerRes['due_amount'] as num?)?.toDouble();
                  final rent = (ledgerRes['rent_amount'] as num?)?.toDouble();
                  if (due != null && due > 0) {
                    _currentRentAmount = due;
                  } else if (rent != null && rent > 0) {
                    _currentRentAmount = rent;
                  }
                  final lStatus = ledgerRes['status']?.toString().toUpperCase();
                  if (lStatus == 'PAID') {
                    _paymentStatus = 'PAID';
                  } else {
                    _paymentStatus = 'DUE';
                  }
                });
              } else if (mounted) {
                // Brand new month cycle with no payment recorded yet
                setState(() {
                  _paymentStatus = 'DUE';
                });
              }
            } catch (e) {
              debugPrint('Error fetching active tenant ledger: $e');
            }
          }
        }
      }

      // 3. Payment Status Check from payment_approvals (scoped to current month's active ledger)
      if (pId != null) {
        final approvalsRes = await SupabaseService.instance.client
            .from('payment_approvals')
            .select('*')
            .eq('property_id', pId)
            .order('created_at', ascending: false)
            .limit(15);

        if (approvalsRes.isNotEmpty && mounted) {
          final approvals = (approvalsRes as List)
              .map((e) =>
                  PaymentApprovalModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          PaymentApprovalModel? matching;
          for (final a in approvals) {
            // Match strictly to this tenant's current month's ledger
            if (_activeLedgerId != null && _activeLedgerId!.isNotEmpty) {
              if (a.ledgerId == _activeLedgerId) {
                matching = a;
                break;
              }
            } else {
              // Fallback match by tenant ID and pending status only
              if ((_tenantId != null &&
                      _tenantId!.isNotEmpty &&
                      a.tenantId == _tenantId) ||
                  (_tenantName.isNotEmpty &&
                      a.tenantName
                          .toLowerCase()
                          .contains(_tenantName.toLowerCase())) ||
                  (_tenantPhone.isNotEmpty && a.phone == _tenantPhone)) {
                matching = a;
                break;
              }
            }
          }

          if (matching != null) {
            setState(() {
              if (matching!.isApproved) {
                _paymentStatus = 'PAID';
              } else if (matching!.isPending) {
                _paymentStatus = 'UNDER_REVIEW';
                _submittedUtr = matching!.utrNumber;
                _submittedPhone =
                    (matching!.phone != null && matching!.phone!.isNotEmpty)
                        ? matching!.phone!
                        : _tenantPhone;
                _submittedPaymentMode = matching!.isCash ? 'CASH' : 'UPI';
              }
            });
          }
        }
      }

      // 4. Maintenance Tickets Check (Pillar 5: MaintenanceTicketModel)
      if (pId != null) {
        var query = SupabaseService.instance.client
            .from('maintenance_tickets')
            .select('*')
            .eq('property_id', pId)
            .neq('status', 'resolved');
        if (_tenantId != null && _tenantId!.isNotEmpty) {
          query = query.eq('tenant_id', _tenantId!);
        }
        final tickets =
            await query.order('created_at', ascending: false).limit(1);

        if (tickets.isNotEmpty && mounted) {
          final model = MaintenanceTicketModel.fromJson(
              Map<String, dynamic>.from(tickets.first));
          setState(() {
            _activeTicket = model;
          });
        } else if (mounted) {
          setState(() {
            _activeTicket = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading live tenant dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent status bar for edge-to-edge header image integration
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _currentNavIndex == 0
              ? _buildHomeBody(context)
              : (_currentNavIndex == 1
                  ? TenantFoodMenuScreen(
                      pgName: _pgName,
                      propertyId: _propertyId,
                    )
                  : const TenantNoticeBoardScreen()),
        ),
      ),
    );
  }

  /// 🏠 Tab 0: Main Home Body
  Widget _buildHomeBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🟢 1. Top Architectural Header with Smooth Curve
          _buildSmoothCurvedHeader(context),

          const SizedBox(height: 18),

          // 🔍 2. Clean Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 18),

          // ⚡ 3. Hero Rent Status & Pay Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHeroRentCard(),
          ),

          const SizedBox(height: 22),

          // 💳 4. Payments Card (Custom Stepped Folder Tab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPaymentsCard(),
          ),

          const SizedBox(height: 20),

          // 🛠️ 4. Helpdesk Card (Custom Stepped Folder Tab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHelpdeskCard(),
          ),

          const SizedBox(height: 20),

          // 🧹 5. Housekeeping & Services Card (Custom Stepped Folder Tab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHousekeepingCard(),
          ),

          const SizedBox(height: 20),

          // 🚪 6. Tenancy & Exit Card (Custom Stepped Folder Tab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTenancyCard(),
          ),

          const SizedBox(height: 28),

          // 🏡 Community Footer Illustration & Namma Bengaluru Signature
          _buildTenantCommunityFooter(),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  /// 🏡 Community Footer Signature matching Phone Verify typography
  Widget _buildTenantCommunityFooter() {
    return Column(
      children: [
        Text(
          'built with love in,',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Namma Bengaluru',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        // Clean cropped line-art illustration
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            'assets/images/Footer_tenant.png',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  /// 🔍 2. Clean Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search anything (eg. rent, maintenance, food...)',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ 3. Hero Rent Status & Pay Banner (Clean Executive Split Card)
  Widget _buildHeroRentCard() {
    final isUnderReview = _paymentStatus == 'UNDER_REVIEW';
    final isPaid = _paymentStatus == 'PAID';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.green.withValues(alpha: 0.3)
              : (isUnderReview
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFE5E7EB)),
          width: (isUnderReview || isPaid) ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Cycle Title & Room/Bed Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnderReview
                    ? '$_currentCycleMonthUpper RENT SUBMITTED'
                    : (isPaid
                        ? '$_currentCycleMonthUpper RENT SETTLED'
                        : '$_currentCycleMonthUpper RENT'),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isPaid
                      ? AppColors.greenDark
                      : (isUnderReview
                          ? const Color(0xFFD97706)
                          : AppColors.muted),
                ),
              ),

              // Prominent & Clearly Visible Room Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Text(
                  _roomNumber.isNotEmpty
                      ? (_sharingType.isNotEmpty
                          ? 'Room $_roomNumber • $_sharingType'
                          : 'Room $_roomNumber')
                      : 'Room --',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Middle Split Row: Amount & Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Amount & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentRentAmount > 0
                          ? '₹${_currentRentAmount.round()}'
                          : '₹0',
                      style: GoogleFonts.outfit(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: isUnderReview ? AppColors.ink : AppColors.green,
                        letterSpacing: -0.7,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isUnderReview) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isPendingCash
                                  ? 'Cash Handover Recorded'
                                  : 'Under Review by $_ownerName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPendingCash
                            ? 'Handed to ${_submittedUtr.replaceFirst('CASH-', '').replaceAll('_', ' ')} • Desk Cash'
                            : 'UTR: $_submittedUtr • +91 $_submittedPhone',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else if (isPaid) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: AppColors.greenDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentCycleMonth Rent Cleared ✓',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next cycle starts $_nextCycleMonth',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due by $_currentDueDate',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Column: Action Button
              GestureDetector(
                onTap: isPaid
                    ? _openPaymentLedger
                    : (_isPendingCash
                        ? _openPaidViaCashScreen
                        : _openRentPaymentSheet),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUnderReview
                        ? Colors.white
                        : (isPaid ? AppColors.greenLight : AppColors.green),
                    borderRadius: BorderRadius.circular(24),
                    border: isUnderReview
                        ? Border.all(color: const Color(0xFFD1D5DB), width: 1.2)
                        : (isPaid
                            ? Border.all(
                                color: AppColors.green.withValues(alpha: 0.3),
                                width: 1.2)
                            : null),
                    boxShadow: (isUnderReview || isPaid)
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUnderReview) ...[
                        const Icon(
                          Icons.edit_outlined,
                          color: AppColors.ink,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit Proof',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ] else if (isPaid) ...[
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.greenDark,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Receipt',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Pay Rent',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hairline Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
          ),

          const SizedBox(height: 9),

          // 3. Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnderReview
                    ? (_isPendingCash
                        ? 'Cash handover awaiting owner audit'
                        : 'Awaiting owner bank credit match')
                    : (isPaid
                        ? '0% direct bank settlement confirmed'
                        : 'All-inclusive monthly stay'),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              if (isUnderReview)
                InkWell(
                  onTap: _loadLiveTenantAndPropertyData,
                  child: Text(
                    'Refresh Status >',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                )
              else if (isPaid)
                GestureDetector(
                  onTap: _openPaymentLedger,
                  child: Text(
                    'View Receipt >',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenDark,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _openPaidViaCashScreen,
                  child: Text(
                    'Paid in cash? >',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 💳 4. Payments Card (Exact 4-Item Balanced Row)
  Widget _buildPaymentsCard() {
    return _FolderTabCard(
      tabWidth: 125,
      title: 'Payments',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.currency_rupee_rounded,
            label: 'Pay Rent\nvia UPI',
            onTap: _openRentPaymentSheet,
          ),
          _buildItemButton(
            icon: Icons.payments_outlined,
            label: 'Paid via\nCash',
            onTap: _openPaidViaCashScreen,
          ),
          _buildItemButton(
            icon: Icons.receipt_long_outlined,
            label: 'Payment\nLedger',
            onTap: _openPaymentLedger,
          ),
          _buildItemButton(
            icon: Icons.event_repeat_rounded,
            label: 'Request\nExtension',
            onTap: _openRequestExtension,
          ),
        ],
      ),
    );
  }

  void _showAlreadySettledDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.greenDark,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rent Already Settled ✓',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your rent for $_currentCycleMonth (₹${_currentRentAmount.toInt()}) is already fully paid and verified by the owner. No further payments are required.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openPaymentLedger();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View Receipt in Ledger',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showSwitchPaymentModal({
    required String fromMode,
    required String toMode,
    String? currentRef,
  }) {
    HapticFeedback.mediumImpact();
    final isFromUpi = fromMode == 'UPI';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFFB45309),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch to $toMode?',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFromUpi
                    ? 'You previously submitted a UPI payment${(currentRef != null && currentRef.isNotEmpty) ? ' (Ref: $currentRef)' : ''}. Switching will cancel your pending UPI verification and replace it with Cash Handover.'
                    : 'You previously recorded a physical Cash handover. Switching will cancel your cash report and replace it with direct bank UPI verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Yes, Switch to $toMode',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Keep Current $fromMode',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaidViaCashScreen() async {
    HapticFeedback.lightImpact();
    if (_paymentStatus == 'PAID') {
      _showAlreadySettledDialog();
      return;
    }
    if (_paymentStatus == 'UNDER_REVIEW' && !_isPendingCash) {
      final shouldSwitch = await _showSwitchPaymentModal(
        fromMode: 'UPI',
        toMode: 'Cash Handover',
        currentRef: _submittedUtr,
      );
      if (shouldSwitch != true) return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaidViaCashScreen(
          residentName: _tenantName,
          roomNumber: _roomNumber,
          bedId: _bedId,
          pgName: _pgName,
          amount: _currentRentAmount,
          cycleMonth: _currentCycleMonth,
          ownerName: _ownerName,
          tenantId: _tenantId,
          propertyId: _propertyId,
          phone: _tenantPhone,
          ledgerId: _activeLedgerId,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['status'] == 'UNDER_REVIEW') {
      setState(() {
        _paymentStatus = 'UNDER_REVIEW';
        _submittedPaymentMode = 'CASH';
        _submittedUtr = 'CASH-${result['recipient']}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cash handover recorded with ${result['recipient']}. Awaiting owner audit ✓',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF111111),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPaymentLedger() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentLedgerScreen(
          tenantId: _tenantId,
          propertyId: _propertyId,
          tenantName: _tenantName,
          roomNumber: _roomNumber,
          bedLabel: 'Bed $_bedId',
          propertyName: _pgName,
        ),
      ),
    );
  }

  void _openRequestExtension() {
    RequestExtensionSheet.show(
      context,
      propertyId: _propertyId,
      propertyName: _pgName,
      tenantName: _tenantName,
      tenantId: _tenantId,
      roomNumber: _roomNumber,
      onExtensionRequested: (selectedDay) {
        // Callback if needed for dashboard state updates
      },
    );
  }

  /// 🚀 Navigate to Full-Page Rent Payment Screen (Full Page Checkout)
  Future<void> _openRentPaymentSheet() async {
    HapticFeedback.lightImpact();
    if (_paymentStatus == 'PAID') {
      _showAlreadySettledDialog();
      return;
    }
    if (_paymentStatus == 'UNDER_REVIEW' && _isPendingCash) {
      final shouldSwitch = await _showSwitchPaymentModal(
        fromMode: 'Cash Handover',
        toMode: 'Online UPI',
        currentRef: _submittedUtr.replaceFirst('CASH-', ''),
      );
      if (shouldSwitch != true) return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentPaymentScreen(
          roomNumber: _roomNumber,
          bedId: _bedId,
          pgName: _pgName,
          ownerName: _ownerName,
          ownerPhone: _ownerPhone,
          tenantPhone: _tenantPhone,
          ownerUpiId: _ownerUpiId,
          ownerBankName:
              _ownerBankName.isNotEmpty ? _ownerBankName : 'Direct Bank UPI',
          amount: _currentRentAmount,
          cycleMonth: _currentCycleMonth,
          tenantId: _tenantId,
          tenantName: _tenantName,
          propertyId: _propertyId,
          ledgerId: _activeLedgerId,
          initialIsSubmitted: _paymentStatus == 'UNDER_REVIEW',
          initialUtr: _submittedUtr,
          initialPhone: _submittedPhone,
          initialScreenshot: _submittedScreenshot,
          onUtrSubmitted: (utr) {
            setState(() {
              _paymentStatus = 'UNDER_REVIEW';
              _submittedPaymentMode = 'UPI';
              _submittedUtr = utr;
            });
          },
        ),
      ),
    );

    if (result is Map) {
      if (result['status'] == 'UNDER_REVIEW') {
        setState(() {
          _paymentStatus = 'UNDER_REVIEW';
          _submittedPaymentMode = 'UPI';
          if (result['utr'] != null && (result['utr'] as String).isNotEmpty) {
            _submittedUtr = result['utr'];
          }
          if (result['phone'] != null &&
              (result['phone'] as String).isNotEmpty) {
            _submittedPhone = result['phone'];
          }
          if (result['screenshot'] != null &&
              (result['screenshot'] as String).isNotEmpty) {
            _submittedScreenshot = result['screenshot'];
          }
        });
      }
    }
  }

  /// 🛠️ 4. Helpdesk Card (4-Item Layout: Ticket, Status, Washing Machine, Rain Alert)
  Widget _buildHelpdeskCard() {
    return _FolderTabCard(
      tabWidth: 120,
      title: 'Helpdesk',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.edit_document,
            label: 'Raise a\nService Ticket',
            onTap: _openRaiseTicketScreen,
          ),
          _buildItemButton(
            icon: Icons.bar_chart_rounded,
            label: 'Live Repair\nStatus',
            onTap: _openLiveRepairStatus,
          ),
          _buildItemButton(
            icon: Icons.local_laundry_service_outlined,
            label: 'Washing Machine\nSlot Booking',
            onTap: _openWashingMachineBooking,
          ),
          _buildItemButton(
            icon: Icons.thunderstorm_outlined,
            label: 'Terrace\nRain Alert',
            onTap: _openRainAlert,
          ),
        ],
      ),
    );
  }

  void _openWashingMachineBooking() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WashingMachineBookingScreen(
          roomNumber: _roomNumber,
          bedId: _bedId,
          propertyId: _propertyId,
          propertyName: _pgName,
          tenantId: _tenantId,
          tenantName: _tenantName,
          tenantPhone: _tenantPhone,
          roomId: _roomId,
        ),
      ),
    );
  }

  void _openRainAlert() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Terrace Rain Sensor: Weather is clear right now.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openLiveRepairStatus() {
    HapticFeedback.lightImpact();
    if (_activeTicket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No active repair tickets. All room facilities operational. ✓',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketStatusScreen(
          ticket: _activeTicket!,
          bedLabel: _bedId,
          pgName: _pgName,
        ),
      ),
    );
  }

  Future<void> _openRaiseTicketScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaiseTicketScreen(
          propertyId: _propertyId,
          tenantId: _tenantId,
          residentName: _tenantName,
          roomNumber: _roomNumber,
          bedId: _bedId,
          phone: _tenantPhone,
          pgName: _pgName,
          sharingType: _sharingType,
        ),
      ),
    );

    if (!mounted) return;

    if (result is MaintenanceTicketModel) {
      setState(() {
        _activeTicket = result.isResolved ? null : result;
      });
    }
  }

  /// 🧹 5. Housekeeping & Services Card
  Widget _buildHousekeepingCard() {
    return _FolderTabCard(
      tabWidth: 155,
      title: 'Housekeeping',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.cleaning_services_outlined,
            label: 'Room Sweep\nRequest',
            onTap: () {
              RoomSweepSheet.show(
                context,
                roomNumber: _roomNumber,
                pgName: _pgName,
                propertyId: _propertyId,
                roomId: _roomId,
                tenantId: _tenantId,
                tenantName: _tenantName,
              );
            },
          ),
          _buildItemButton(
            icon: Icons.wash_outlined,
            label: 'Full Room\nClean',
            onTap: () {
              FullRoomCleanSheet.show(
                context,
                roomNumber: _roomNumber,
                pgName: _pgName,
                propertyId: _propertyId,
                roomId: _roomId,
                tenantId: _tenantId,
                tenantName: _tenantName,
              );
            },
          ),
          _buildItemButton(
            icon: Icons.bed_outlined,
            label: 'Bedsheet\nChange',
            onTap: () {
              BedsheetChangeSheet.show(
                context,
                roomNumber: _roomNumber,
                pgName: _pgName,
                propertyId: _propertyId,
                roomId: _roomId,
                tenantId: _tenantId,
                tenantName: _tenantName,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🚪 6. Tenancy & Exit Card
  Widget _buildTenancyCard() {
    return _FolderTabCard(
      tabWidth: 165,
      title: 'Tenancy & Exit',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemButton(
            icon: Icons.article_outlined,
            label: 'Stay\nAgreement',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Stay Agreement active for $_pgName (Room $_roomNumber).',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.ink,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          _buildItemButton(
            icon: Icons.event_busy_outlined,
            label: 'Move-Out\nNotice (30D)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoveOutNoticeScreen(
                    roomNumber: _roomNumber,
                    bedIdentifier: _bedId,
                    pgName: _pgName,
                    propertyId: _propertyId,
                    tenantId: _tenantId,
                    tenantName: _tenantName,
                    tenantPhone: _tenantPhone,
                    monthlyRent: _currentRentAmount,
                    securityDeposit: _currentSecurityDeposit > 0
                        ? _currentSecurityDeposit
                        : (_currentRentAmount * 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Single Action Item Button (Soft green circle + 2-line centered label)
  Widget _buildItemButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8EE), // Soft green circle (#EBF8EE)
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Bottom Navigation Bar matching the image
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavTab(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavTab(
                index: 1,
                icon: Icons.restaurant_menu_rounded,
                label: 'Food Menu',
              ),
              _buildNavTab(
                index: 2,
                icon: Icons.campaign_outlined,
                label: 'Notice Board',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentNavIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.green : AppColors.muted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.green : AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          if (isSelected)
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  /// Smart Initial Generator (e.g. "Bhargav S Kulkarni" -> "BK", "Joy Sen" -> "JS")
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'TN';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Dynamic font sizing so short and long names never wrap or break
  double _getNameFontSize(String name) {
    if (name.length <= 16) return 24.0;
    if (name.length <= 22) return 22.0;
    return 19.5;
  }

  /// 🟢 Top Header with Tenant_nameBG.png Background Image
  Widget _buildSmoothCurvedHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final initials = _getInitials(_tenantName);
    final nameFontSize =
        _getNameFontSize(_tenantName.isNotEmpty ? _tenantName : 'Resident');

    return ClipPath(
      clipper: _SmoothHeaderClipper(),
      child: Stack(
        children: [
          // 1. Background Building Image from Assets
          Positioned.fill(
            child: Image.asset(
              'assets/images/Tenant_nameBG.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Subtle Darkening Gradient for 100% High-Contrast Text Legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),

          // 3. Foreground Header Content (Strictly matching reference image)
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: PG Name & Location (Left) + Avatar (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _pgName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (_propertyLocation.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _propertyLocation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Clean Circular Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // Greeting: "Welcome back,"
                Text(
                  'Welcome back,',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.90),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),

                // Resident Full Name
                Text(
                  _tenantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 14),

                // Actionable Room Pill
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.single_bed_rounded,
                          size: 16.5,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _roomNumber.isNotEmpty
                              ? (_bedId.isNotEmpty && _bedId.length < 30
                                  ? (_bedId.toLowerCase().startsWith('bed')
                                      ? 'Room $_roomNumber • $_bedId'
                                      : 'Room $_roomNumber • Bed $_bedId')
                                  : (_sharingType.isNotEmpty
                                      ? 'Room $_roomNumber • $_sharingType'
                                      : 'Room $_roomNumber'))
                              : 'Room --',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16.5,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🗂️ Reusable Stepped Folder-Tab Card Widget (Clean Title, No Icon)
class _FolderTabCard extends StatelessWidget {
  final double tabWidth;
  final String title;
  final Widget child;

  const _FolderTabCard({
    required this.tabWidth,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FolderTabPainter(tabWidth: tabWidth),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Folder Tab Header - Clean Bold Title (No Icon)
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(
                height: 20), // Generous vertical breathing space before buttons

            // Child Action Items
            child,
          ],
        ),
      ),
    );
  }
}

/// 📐 Custom Painter for the Stepped Folder Tab Silhouette
class _FolderTabPainter extends CustomPainter {
  final double tabWidth;
  final double shoulderDrop = 16.0;
  final Color backgroundColor = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);

  _FolderTabPainter({
    required this.tabWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const cornerRadius = 20.0;

    // Start at top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Across the top of the raised tab
    path.lineTo(tabWidth - 12, 0);

    // Smooth S-curve transition stepping down to the shoulder
    path.cubicTo(
      tabWidth + 4,
      0,
      tabWidth + 10,
      shoulderDrop,
      tabWidth + 24,
      shoulderDrop,
    );

    // Across the lower shoulder line to the top-right corner
    path.lineTo(size.width - cornerRadius, shoulderDrop);
    path.quadraticBezierTo(
        size.width, shoulderDrop, size.width, shoulderDrop + cornerRadius);

    // Down the right edge
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - cornerRadius, size.height);

    // Across the bottom edge
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Back up the left edge
    path.close();

    // Draw soft drop shadow
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.035),
      12.0,
      true,
    );

    // Fill with pure white
    final fillPaint = Paint()..color = backgroundColor;
    canvas.drawPath(path, fillPaint);

    // Stroke hairline border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderTabPainter oldDelegate) {
    return oldDelegate.tabWidth != tabWidth ||
        oldDelegate.shoulderDrop != shoulderDrop ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// 📐 Custom Clipper to produce the smooth downward curve matching the sketch
class _SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);

    final firstControlPoint = Offset(size.width / 2, size.height + 12);
    final firstEndPoint = Offset(size.width, size.height - 28);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
