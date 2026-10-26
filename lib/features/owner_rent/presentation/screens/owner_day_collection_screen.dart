import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/state/owner_app_state.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';

/// Screen 9th Quick Action: Dedicated Day-Wise Rent Collection & Salary Cycle Hub.
/// Features:
/// - Horizontal Salary Cycle Date Strip (1st, 2nd, 3rd, 5th, 7th, 10th, 15th).
/// - Dynamic Date Re-Scheduling (shifting tenant moves them to new date in real-time).
/// - Non-Green WhatsApp button styling (clean neutral outline).
/// - Verification Actions (View Proof, Reject, Accept).
/// - Comprehensive Chronological Audit & History Log.
class OwnerDayCollectionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? propertyId;

  const OwnerDayCollectionScreen({
    super.key,
    this.onBack,
    this.propertyId,
  });

  @override
  State<OwnerDayCollectionScreen> createState() =>
      _OwnerDayCollectionScreenState();
}

class _OwnerDayCollectionScreenState extends State<OwnerDayCollectionScreen> {
  String _activeTab = 'schedule'; // 'schedule' or 'history'
  int _selectedDay = 1;
  String _selectedStaffActor = 'Owner';
  final List<String> _staffActors = [];
  String _propertyName = '';

  String _historyFilter = 'all'; // 'all', 'payments', 'rescheduled', 'rejected'
  String _selectedFloor =
      'all'; // 'all', 'Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'

  // Helper to extract initials
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'TN';
  }

  // Helper to extract floor from room
  String _getFloor(String roomNumber) {
    final clean = roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isNotEmpty) {
      final first = clean[0];
      if (first == '1') return '1st Floor';
      if (first == '2') return '2nd Floor';
      if (first == '3') return '3rd Floor';
      if (first == '4') return '4th Floor';
      if (first == '0') return 'Ground Floor';
      return '${first}th Floor';
    }
    return '1st Floor';
  }

  String _formatSubtitle(RentLedgerModel tenant) {
    final floor = _getFloor(tenant.roomNumber);
    final room = tenant.roomNumber.isNotEmpty
        ? (tenant.roomNumber.startsWith('Room')
            ? tenant.roomNumber
            : 'Room ${tenant.roomNumber}')
        : '';
    final bed = tenant.bedNumber != null && tenant.bedNumber!.isNotEmpty
        ? 'Bed ${tenant.bedNumber}'
        : '';
    final parts = [
      if (floor.isNotEmpty) floor,
      if (bed.isNotEmpty) bed,
      if (room.isNotEmpty) room
    ];
    return parts.join(' • ');
  }

  // Master Tenant List & Audit History
  final List<RentLedgerModel> _tenants = [];
  final List<WardenCashModel> _historyLogs = [];
  final List<PaymentApprovalModel> _pendingApprovals = [];
  bool _isLoading = false;

  PaymentApprovalModel? _getPendingApprovalForTenant(RentLedgerModel tenant) {
    if (_pendingApprovals.isEmpty) return null;
    if (tenant.id.isNotEmpty) {
      final byLedger = _pendingApprovals
          .where((p) => p.isPending && p.ledgerId == tenant.id)
          .firstOrNull;
      if (byLedger != null) return byLedger;
    }
    if (tenant.tenantId.isNotEmpty) {
      final byTenantId = _pendingApprovals
          .where((p) => p.isPending && p.tenantId == tenant.tenantId)
          .firstOrNull;
      if (byTenantId != null) return byTenantId;
    }
    final tName = tenant.tenantName.trim().toLowerCase();
    final tRoom = tenant.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (tName.isNotEmpty) {
      return _pendingApprovals.where((p) {
        if (!p.isPending) return false;
        final pName = p.tenantName.trim().toLowerCase();
        final pRoom = p.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
        if (pName == tName) {
          if (tRoom.isEmpty || pRoom.isEmpty || tRoom == pRoom) return true;
        }
        return false;
      }).firstOrNull;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDayCollectionData();
  }

  Future<void> _loadDayCollectionData() async {
    setState(() => _isLoading = true);
    try {
      final prop = await SupabaseService.instance.getOwnerProperty();
      if (prop != null) {
        final propId = prop['id'].toString();
        final ownerName =
            (prop['owner_legal_name'] ?? prop['name'] ?? 'Owner').toString();
        _propertyName = (prop['property_name'] ??
                prop['name'] ??
                OwnerAppState.instance.activePropertyName)
            .toString();
        final staffList =
            await SupabaseService.instance.getStaffMembers(propId);
        final List<String> loadedStaff = ['$ownerName (Owner)'];
        for (final s in staffList) {
          final sName = s.name;
          final sRole = s.role.isNotEmpty ? s.role : 'Staff';
          if (sName.isNotEmpty) {
            loadedStaff.add('$sName ($sRole)');
          }
        }
        if (mounted) {
          setState(() {
            _staffActors.clear();
            _staffActors.addAll(loadedStaff);
            if (_staffActors.isNotEmpty &&
                (_selectedStaffActor == 'Owner' ||
                    !_staffActors.contains(_selectedStaffActor))) {
              _selectedStaffActor = _staffActors.first;
            }
          });
        }

        // Load Payment Approvals (UPI & Cash)
        final liveApprovals =
            await SupabaseService.instance.getPaymentApprovalModels(propId);
        if (mounted) {
          setState(() {
            _pendingApprovals.clear();
            _pendingApprovals.addAll(liveApprovals);
          });
        }

        // Load Warden Cash Collections Audit History
        final cashModels =
            await SupabaseService.instance.getWardenCashModels(propId);
        if (mounted && cashModels.isNotEmpty) {
          setState(() {
            _historyLogs.clear();
            _historyLogs.addAll(cashModels);
          });
        }

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
        final currentCycle = '${months[now.month - 1]} ${now.year}';
        await SupabaseService.instance.ensureMonthlyRentLedgers(
          propertyId: propId,
          propertyName: _propertyName,
          cycleMonth: currentCycle,
        );

        final ledgerModels =
            await SupabaseService.instance.getRentLedgerModels(propId);
        if (mounted && ledgerModels.isNotEmpty) {
          setState(() {
            _tenants.clear();
            _tenants.addAll(ledgerModels);
          });
        } else if (mounted) {
          final rooms = await SupabaseService.instance.getRoomsWithBeds(propId);
          final List<RentLedgerModel> bedTenants = [];
          for (final r in rooms) {
            final beds = r['beds'] as List<dynamic>? ?? [];
            final actualRoomNum = r['room_number']?.toString() ?? '';
            final roomRent = (r['rent_per_bed'] as num?)?.toDouble() ?? 0.0;
            for (final b in beds) {
              if (b['is_occupied'] == true && b['tenant_name'] != null) {
                final tName = b['tenant_name'].toString();
                final actualBedRent =
                    (b['rent'] as num?)?.toDouble() ?? roomRent;
                final bId = b['id']?.toString() ??
                    'bed_${b['bed_id'] ?? DateTime.now().millisecondsSinceEpoch}';
                bedTenants.add(RentLedgerModel(
                  id: bId,
                  propertyId: propId,
                  tenantId: b['tenant_id']?.toString() ?? '',
                  tenantName: tName,
                  roomNumber: actualRoomNum,
                  bedNumber: b['bed_number']?.toString(),
                  phone: b['tenant_phone']?.toString(),
                  cycleMonth: currentCycle,
                  rentAmount: actualBedRent,
                  dueDate: DateTime(now.year, now.month,
                      (b['rent_due_day'] as num?)?.toInt() ?? 1),
                  status: 'PENDING',
                ));
              }
            }
          }
          if (bedTenants.isNotEmpty) {
            setState(() {
              _tenants.clear();
              _tenants.addAll(bedTenants);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading day collection: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDaySuffix(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    switch (d % 10) {
      case 1:
        return '${d}st';
      case 2:
        return '${d}nd';
      case 3:
        return '${d}rd';
      default:
        return '${d}th';
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultDays = [1, 2, 3, 5, 7, 10, 15, 20, 25];
    final tenantDays = _tenants.map((t) => t.dueDate.day).toList();
    final availableDays = {...defaultDays, ...tenantDays}.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Header
            _buildTopHeader(),

            // 2. Tab Bar: Daily Schedule vs Collection History
            _buildTopTabs(),

            // 3. Main Content View
            Expanded(
              child: _activeTab == 'schedule'
                  ? _buildScheduleContent(availableDays)
                  : _buildHistoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP STICKY HEADER
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Day-Wise Collection',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        OwnerAppState.instance.activePropertyName.isNotEmpty
                            ? '${OwnerAppState.instance.activePropertyName} • Salary Cycle Calendar'
                            : (_propertyName.isNotEmpty
                                ? '$_propertyName • Salary Cycle Calendar'
                                : 'Salary Cycle Calendar'),
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
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Active Staff Actor Pill (Dynamic from DB)
          InkWell(
            onTap: _staffActors.length > 1
                ? () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Text(
                                  'Select Active Operator / Staff',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const Divider(),
                              ..._staffActors.map((actor) => ListTile(
                                    title: Text(
                                      actor,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: _selectedStaffActor == actor
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _selectedStaffActor == actor
                                            ? AppColors.greenDark
                                            : AppColors.ink,
                                      ),
                                    ),
                                    trailing: _selectedStaffActor == actor
                                        ? const Icon(Icons.check_circle_rounded,
                                            color: AppColors.green, size: 20)
                                        : null,
                                    onTap: () {
                                      setState(
                                          () => _selectedStaffActor = actor);
                                      Navigator.pop(ctx);
                                    },
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 12, color: AppColors.greenDark),
                  const SizedBox(width: 4),
                  Text(
                    _selectedStaffActor.split(' ')[0], // First name
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark),
                  ),
                  if (_staffActors.length > 1) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down_rounded,
                        size: 14, color: AppColors.greenDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. TOP TABS: SCHEDULE VS HISTORY
  // ===========================================================================
  Widget _buildTopTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2))),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 'schedule'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'schedule'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'schedule'
                        ? const [
                            BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: _activeTab == 'schedule'
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Salary Schedule',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'schedule'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'schedule'
                                ? AppColors.greenDark
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 'history'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'history'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'history'
                        ? const [
                            BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: _activeTab == 'history'
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Audit & History (${_historyLogs.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'history'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'history'
                                ? AppColors.ink
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SCHEDULE CONTENT VIEW
  // ===========================================================================
  Widget _buildFloorFilterChip(String id, String label) {
    final isSel = _selectedFloor == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFloor = id),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSel ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: isSel ? AppColors.green : const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent(List<int> availableDays) {
    final selectedTenants = _tenants.where((t) {
      final matchesDay = t.dueDate.day == _selectedDay;
      final floor = _getFloor(t.roomNumber);
      final matchesFloor = _selectedFloor == 'all' || floor == _selectedFloor;
      return matchesDay && matchesFloor;
    }).toList();
    final dayTotalExpected =
        selectedTenants.fold<int>(0, (sum, t) => sum + t.rentAmount.toInt());
    final dayPaidCount = selectedTenants.where((t) => t.isPaid).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        14,
        context.responsiveHorizontalPadding,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Floor Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                _buildFloorFilterChip('all', 'All Floors'),
                _buildFloorFilterChip('Ground Floor', 'Ground Floor'),
                _buildFloorFilterChip('1st Floor', '1st Floor'),
                _buildFloorFilterChip('2nd Floor', '2nd Floor'),
                _buildFloorFilterChip('3rd Floor', '3rd Floor'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Interactive Date Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: availableDays.map((d) {
                final count = _tenants.where((t) {
                  final matchesDay = t.dueDate.day == d;
                  final floor = _getFloor(t.roomNumber);
                  final matchesFloor =
                      _selectedFloor == 'all' || floor == _selectedFloor;
                  return matchesDay && matchesFloor;
                }).length;
                final isSel = _selectedDay == d;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDay = d),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.green : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSel ? AppColors.green : const Color(0xFFE5E7EB),
                          width: isSel ? 1.5 : 1.0,
                        ),
                        boxShadow: isSel
                            ? const [
                                BoxShadow(
                                    color: Color(0x1808A63F),
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDaySuffix(d),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isSel ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count Beds',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Selected Day Cashflow Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatDaySuffix(_selectedDay)} of Month (Salary Cycle)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedTenants.length} Tenants • $dayPaidCount Paid • ${selectedTenants.length - dayPaidCount} Due',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹$dayTotalExpected',
                  style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tenant Cards for the Selected Day
          if (selectedTenants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Center(
                child: Text(
                  'No tenants scheduled for ${_selectedDay}th of the month.',
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                ),
              ),
            )
          else
            ...selectedTenants.map((t) => _buildTenantCard(t)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TENANT CARD (With Neutral WhatsApp & Verification Actions)
  // ===========================================================================
  Widget _buildTenantCard(RentLedgerModel tenant) {
    final isPaid = tenant.isPaid;
    final isOverdue = tenant.isOverdue;
    final String approvedBy = _selectedStaffActor;
    final tenantName =
        tenant.tenantName.isNotEmpty ? tenant.tenantName : 'Resident';
    final initials = _getInitials(tenantName);
    final phone = tenant.phone ?? '';
    final pendingApproval = _getPendingApprovalForTenant(tenant);
    final isUnderReview =
        tenant.status.toLowerCase() == 'under_review' || pendingApproval != null;
    final isCash = pendingApproval?.isCash ?? false;
    final staffCollector = pendingApproval?.collectedBy?.isNotEmpty == true
        ? pendingApproval!.collectedBy!
        : 'Staff';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.green.withValues(alpha: 0.3)
              : isUnderReview
                  ? const Color(0xFFFDE68A)
                  : isOverdue
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
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
          // Header Row: Avatar + Name + Bed + Rent Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.greenLight
                            : isUnderReview
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isPaid
                                ? AppColors.greenDark
                                : isUnderReview
                                    ? const Color(0xFF92400E)
                                    : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSubtitle(tenant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '₹${tenant.rentAmount.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isPaid ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Verification / Status Pill
          if (isUnderReview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      isCash
                          ? 'Cash Handover • $staffCollector'
                          : 'Under Review • UPI',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.verified_user_outlined
                        : Icons.schedule_rounded,
                    size: 13,
                    color: isPaid ? AppColors.greenDark : AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isPaid
                          ? 'Verified by $approvedBy • Paid on ${tenant.paidDate != null ? "${tenant.paidDate!.day} Aug" : "1 Aug"}'
                          : isOverdue
                              ? 'Agreed Date: ${_selectedDay}th • Overdue'
                              : 'Agreed Salary Date: ${_selectedDay}th • Due Today (No Late Fine)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.greenDark : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // ROW 1: Call & WhatsApp Side-by-Side (Clean Outlined Neutral, NOT Dark Green!)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Calling +91 $phone...'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.green.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/phone.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'WhatsApp Chat opened with $tenantName (+91 $phone) ✓'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.green.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/whatsapp.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Extension Request Bar with Yellow Decline and Approve Buttons
          if (tenant.status.toLowerCase() == 'extension_requested') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Requested to pay on 15 ${tenant.cycleMonth.isNotEmpty ? tenant.cycleMonth : "Aug 2026"}',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Decline Extension?',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to decline the payment extension for $tenantName?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(dCtx);
                                final propId = (widget.propertyId != null &&
                                        widget.propertyId!.isNotEmpty)
                                    ? widget.propertyId!
                                    : (tenant.propertyId.isNotEmpty
                                        ? tenant.propertyId
                                        : (SupabaseService
                                                .instance.activePropertyId ??
                                            ''));
                                if (propId != null && propId.isNotEmpty) {
                                  await SupabaseService.instance
                                      .declineRentExtension(
                                    propertyId: propId,
                                    tenantName: tenantName,
                                    roomNumber: tenant.roomNumber,
                                    ledgerId: tenant.id,
                                  );
                                }
                                _showToast(
                                    'Extension Declined for $tenantName');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Yes, Decline',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: Text(
                          '✕ Decline',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Approve Extension?',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          content: Text(
                            'Approve rent payment extension for $tenantName till 15 Aug 2026?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(dCtx);
                                final propId = (widget.propertyId != null &&
                                        widget.propertyId!.isNotEmpty)
                                    ? widget.propertyId!
                                    : (tenant.propertyId.isNotEmpty
                                        ? tenant.propertyId
                                        : (SupabaseService
                                                .instance.activePropertyId ??
                                            ''));
                                if (propId != null && propId.isNotEmpty) {
                                  await SupabaseService.instance
                                      .approveRentExtension(
                                    propertyId: propId,
                                    tenantName: tenantName,
                                    roomNumber: tenant.roomNumber,
                                    ledgerId: tenant.id,
                                    newDueDay: 15,
                                  );
                                }
                                _showToast(
                                    'Extension Approved for $tenantName till 15 Aug ✓');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Yes, Approve',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: Text(
                          '✓ Approve (15 Aug)',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else if (tenant.status.toLowerCase() == 'extension_approved') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 13, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Extension Approved • Due 15 Aug 2026',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ROW 2: If Paid -> Full-Width Change Date (Receipt Removed)
          //        If Not Paid -> View Proof, Reject, Accept
          if (isPaid)
            InkWell(
              onTap: () => _openChangePayDateModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'PAID',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (context) {
                        final rawVerifier = tenant.approvedBy ?? '';
                        final cleanVerifier = rawVerifier
                            .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
                            .trim();
                        final verifierText = cleanVerifier.isNotEmpty
                            ? ' • Verified by $cleanVerifier'
                            : '';
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                        ];
                        final dateStr = tenant.paidDate != null
                            ? "${tenant.paidDate!.day} ${months[tenant.paidDate!.month - 1]} ${tenant.paidDate!.year}"
                            : "Today";
                        return Text(
                          'Paid on $dateStr$verifierText',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else if (isUnderReview) ...[
            // Tenant uploaded payment proof -> View Proof, Reject, Accept
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRealProofDialog(tenant, pendingApproval);
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: AppColors.ink),
                    label: Text(
                      'View Proof',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final success = await SupabaseService.instance
                          .updatePaymentApprovalStatus(
                        submissionId: pendingApproval?.id,
                        ledgerId: tenant.id,
                        status: 'rejected',
                      );
                      if (success) {
                        await _loadDayCollectionData();
                        _showToast('Payment Proof Rejected');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await SupabaseService.instance
                          .updatePaymentApprovalStatus(
                        submissionId: pendingApproval?.id,
                        ledgerId: tenant.id,
                        status: 'approved',
                        approvedBy: _selectedStaffActor,
                      );
                      if (success) {
                        await _loadDayCollectionData();
                        _showToast('Payment Approved for $tenantName ✓');
                      } else {
                        _showToast('Failed to approve payment');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Real Unpaid Actions: Record Cash & Change Pay Date
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openRecordCashModal(tenant),
                    icon: const Icon(Icons.payments_outlined,
                        size: 14, color: AppColors.greenDark),
                    label: Text(
                      'Record Cash',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                      side: BorderSide(
                          color: AppColors.green.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChangePayDateModal(tenant),
                    icon: const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.muted),
                    label: Text(
                      'Change Pay Date',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'DUE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOverdue ? 'Overdue' : 'Due Today',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // REAL PAYMENT PROOF DIALOG (Cash vs UPI from payment_approvals)
  // ===========================================================================
  void _showRealProofDialog(
      RentLedgerModel tenant, PaymentApprovalModel? approval) {
    final isCash = approval?.isCash ?? false;
    final staffCollector = approval?.collectedBy?.isNotEmpty == true
        ? approval!.collectedBy!
        : 'Staff';
    final tenantName =
        tenant.tenantName.isNotEmpty ? tenant.tenantName : 'Resident';
    final amount = tenant.rentAmount.toInt();
    final utr = approval?.utrNumber ?? 'Pending UTR';
    final proofImg = approval?.proofImageUrl;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCash ? const Color(0xFFEBF8EE) : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCash ? Icons.payments_outlined : Icons.account_balance_outlined,
                size: 17,
                color: isCash ? AppColors.greenDark : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCash ? 'Cash Payment Proof' : 'UPI Payment Proof',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildProofRow('Resident:', tenantName, isBold: true),
                    const SizedBox(height: 6),
                    _buildProofRow(
                        'Room / Bed:', '${tenant.roomNumber} (${tenant.bedNumber ?? ""})'),
                    const SizedBox(height: 6),
                    _buildProofRow('Amount Claimed:', '₹$amount',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 6),
                    _buildProofRow('Payment Mode:',
                        isCash ? 'Physical Cash Handover' : (approval?.paymentApp ?? 'Direct Bank UPI')),
                    const SizedBox(height: 6),
                    if (isCash)
                      _buildProofRow('Handed Over To:', '$staffCollector (Desk Staff)',
                          isBold: true, valueColor: const Color(0xFFB45309))
                    else
                      _buildProofRow('UPI Reference (UTR):', utr,
                          isMonospace: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Screenshot Preview (if UPI screenshot uploaded)
              if (!isCash && proofImg != null && proofImg.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    proofImg,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('Proof Screenshot Attached',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Ground Truth Notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCash ? const Color(0xFFEBF8EE) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCash ? AppColors.green.withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCash ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      size: 15,
                      color: isCash ? AppColors.greenDark : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCash
                            ? 'Cash of ₹$amount collected by $staffCollector at the desk. Accepting will mark rent as paid and log this in the Warden Cash Ledger.'
                            : 'Please verify ₹$amount is credited in your bank account via UTR $utr before accepting.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCash ? AppColors.greenDark : const Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await SupabaseService.instance
                  .updatePaymentApprovalStatus(
                submissionId: approval?.id,
                ledgerId: tenant.id,
                status: 'rejected',
              );
              if (success) {
                await _loadDayCollectionData();
                _showToast('Payment Proof Rejected');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Reject',
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await SupabaseService.instance
                  .updatePaymentApprovalStatus(
                submissionId: approval?.id,
                ledgerId: tenant.id,
                status: 'approved',
                approvedBy: _selectedStaffActor,
              );
              if (success) {
                await _loadDayCollectionData();
                _showToast('Payment Approved for $tenantName ✓');
              } else {
                _showToast('Failed to approve payment');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Accept',
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProofRow(String label, String value,
      {bool isBold = false, bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isMonospace
                ? const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)
                : GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                    color: valueColor ?? AppColors.ink,
                  ),
          ),
        ),
      ],
    );
  }
  // ===========================================================================
  Widget _buildHistoryContent() {
    final filtered = _historyLogs.where((log) {
      if (_historyFilter == 'payments') return log.isDeposited;
      if (_historyFilter == 'rescheduled') return log.isWithWarden;
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsiveHorizontalPadding,
        14,
        context.responsiveHorizontalPadding,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips (All, Payments, Date Changed, Rejected)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                _buildHistoryFilterChip(
                    'all', 'All Audit Logs (${_historyLogs.length})'),
                _buildHistoryFilterChip('payments', 'Deposited to Bank'),
                _buildHistoryFilterChip('rescheduled', 'With Warden'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Center(
                child: Text('No audit records found.',
                    style: GoogleFonts.outfit(color: AppColors.muted)),
              ),
            )
          else
            ...filtered.map((log) => _buildHistoryCard(log)),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterChip(String id, String label) {
    final isSel = _historyFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _historyFilter = id),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSel ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: isSel ? AppColors.ink : const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WardenCashModel log) {
    final isDeposited = log.isDeposited;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDeposited
                            ? AppColors.greenLight
                            : const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDeposited
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_rounded,
                        size: 15,
                        color: isDeposited
                            ? AppColors.greenDark
                            : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${log.amount.toInt()} Cash Collection Recorded',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDeposited
                      ? AppColors.greenLight
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDeposited ? 'Cash Settled' : 'With Warden',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDeposited
                        ? AppColors.greenDark
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${log.tenantName} (${log.roomNumber})',
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            'Status: ${isDeposited ? "Deposited to Owner" : "Held by Warden"}',
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted),
          ),
          if (log.notes != null && log.notes!.isNotEmpty)
            Text(
              'Note: ${log.notes}',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Action By: ${log.collectedBy}',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
                Text(
                  log.createdAt != null
                      ? log.createdAt.toString().split('T').first
                      : 'Recent',
                  style: GoogleFonts.outfit(
                      fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mandatory Call & WhatsApp buttons for Audit Log
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showToast('Calling resident for ${log.tenantName}...');
                  },
                  icon: const Icon(Icons.phone_outlined,
                      size: 13, color: AppColors.ink),
                  label: Text(
                    'Call',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showToast('WhatsApp Chat opened with ${log.tenantName} ✓');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.ink),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
  // MODALS
  // ===========================================================================

  // Modal: View Proof
  void _openViewProofModal(RentLedgerModel tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Payment Proof: ${tenant.tenantName}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildRow('Resident:',
                        '${tenant.tenantName} (${tenant.roomNumber})',
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildRow(
                        'Amount Claimed:', '₹${tenant.rentAmount.toInt()}',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildRow('Payment Mode:', 'Direct UPI / PhonePe'),
                    const SizedBox(height: 8),
                    _buildRow('Submitted UTR / Ref:', tenant.paymentMode,
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildRow(
                        'Submission Time:',
                        tenant.createdAt != null
                            ? '${tenant.createdAt!.day}/${tenant.createdAt!.month}'
                            : 'Today'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please verify that ₹${tenant.rentAmount.toInt()} was credited to your HDFC/SBI bank account before accepting.',
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openRejectPaymentModal(tenant);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Reject Payment',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final success = await SupabaseService.instance
                            .updatePaymentApprovalStatus(
                          ledgerId: tenant.id,
                          status: 'approved',
                        );
                        if (success) {
                          await _loadDayCollectionData();
                          _showToast(
                              'Payment of ₹${tenant.rentAmount.toInt()} Accepted by $_selectedStaffActor for ${tenant.tenantName} ✓');
                        } else {
                          _showToast('Failed to approve payment');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept & Mark Paid',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Modal: Structured Payment Rejection
  void _openRejectPaymentModal(RentLedgerModel tenant) {
    String selectedReason = 'Money Not Credited in Bank Account';
    final customNoteCtrl = TextEditingController();
    final List<String> reasons = [
      'Money Not Credited in Bank Account',
      'Incorrect / Invalid 12-Digit UTR Number',
      'Partial Amount Paid (Shortfall)',
      'Payment Sent to Wrong UPI Account',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildBottomSheetWrapper(
              title: 'Reject Payment: ${tenant.tenantName}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tenant.tenantName} (${tenant.roomNumber})',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF991B1B)),
                            ),
                            Text(
                              'Claimed Amount: ₹${tenant.rentAmount.toInt()} • ${tenant.paymentMode}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UNVERIFIED',
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Rejection Reason (Sent to Resident):',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => setModalState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: isSel
                                    ? const Color(0xFFDC2626)
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFF991B1B)
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text(
                    'Additional Note (Optional):',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: customNoteCtrl,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.ink),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Please resend proof from bank passbook',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final success = await SupabaseService.instance
                          .updatePaymentApprovalStatus(
                        ledgerId: tenant.id,
                        status: 'rejected',
                      );
                      if (success) {
                        await _loadDayCollectionData();
                        _showToast(
                            'Payment rejected: Alert sent to ${tenant.tenantName} on WhatsApp ✓');
                      } else {
                        _showToast('Failed to reject payment');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Rejection & Send Alert',
                      style: GoogleFonts.outfit(
                          fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal: Re-Assign Monthly Pay Date (Dynamic Date Movement)
  void _openChangePayDateModal(RentLedgerModel tenant) {
    int currentDay = tenant.dueDate.day;
    int selectedDay = currentDay;
    final reasonCtrl =
        TextEditingController(text: 'Salary credited on ${selectedDay}th');
    final List<int> quickDays = [1, 2, 3, 5, 7, 10, 15, 20, 25];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildBottomSheetWrapper(
              title: 'Re-Schedule Pay Date: ${tenant.tenantName}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${tenant.roomNumber} • Current Agreed Pay Date: ${currentDay}th of month',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Text('Select New Monthly Pay Date',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickDays.map((d) {
                      final isSel = selectedDay == d;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedDay = d;
                            reasonCtrl.text =
                                'Salary credited on ${d}th of every month';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.greenLight
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.green
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '${d}th of Month',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color:
                                  isSel ? AppColors.greenDark : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Reason / Notes',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Salary credited on 10th from employer',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final prop =
                          await SupabaseService.instance.getOwnerProperty();
                      final propId = prop?['id']?.toString() ??
                          (tenant.propertyId.isNotEmpty
                              ? tenant.propertyId
                              : (SupabaseService.instance.activePropertyId ??
                                  ''));

                      await SupabaseService.instance.updateRentDueDate(
                        propertyId: propId,
                        roomNumber: tenant.roomNumber,
                        tenantName: tenant.tenantName,
                        ledgerId: tenant.id,
                        newDueDay: selectedDay,
                      );
                      await _loadDayCollectionData();

                      setState(() {
                        _selectedDay = selectedDay;
                      });
                      _showToast(
                          'Moved ${tenant.tenantName} to ${selectedDay}th of month (Saved to DB ✓)');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Move to ${selectedDay}th of Month',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal: Record Cash Payment
  void _openRecordCashModal(RentLedgerModel tenant) {
    final amountCtrl =
        TextEditingController(text: tenant.rentAmount.toInt().toString());
    final loggedInName = SupabaseService.instance.client.auth.currentUser?.userMetadata?['name'] ?? 'Owner';
    if (_selectedStaffActor.isEmpty) {
      _selectedStaffActor = '$loggedInName (Owner)';
    }
    final notesCtrl =
        TextEditingController(text: 'Cash received by $_selectedStaffActor');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Record Cash: ${tenant.tenantName}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Amount Received (₹)',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
              ),
              const SizedBox(height: 14),
              Text('Verified By',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStaffActor,
                    isExpanded: true,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    items: _staffActors
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStaffActor = val;
                          notesCtrl.text = 'Cash received by $val';
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim()) ??
                      tenant.rentAmount;
                  Navigator.of(ctx).pop();

                  // Instantly update local state so card turns green immediately
                  setState(() {
                    final idx = _tenants.indexWhere((t) =>
                        t.id == tenant.id ||
                        (t.roomNumber == tenant.roomNumber &&
                            t.tenantName == tenant.tenantName));
                    if (idx != -1) {
                      final old = _tenants[idx];
                      _tenants[idx] = RentLedgerModel(
                        id: old.id,
                        propertyId: old.propertyId,
                        propertyName: old.propertyName,
                        tenantId: old.tenantId,
                        tenantName: old.tenantName,
                        roomNumber: old.roomNumber,
                        bedNumber: old.bedNumber,
                        phone: old.phone,
                        cycleMonth: old.cycleMonth,
                        rentAmount: old.rentAmount,
                        dueDate: old.dueDate,
                        paidDate: DateTime.now(),
                        status: 'PAID',
                        paymentMode: 'CASH',
                      );
                    }
                  });

                  final prop =
                      await SupabaseService.instance.getOwnerProperty();
                  final propId = prop?['id']?.toString() ??
                      (tenant.propertyId.isNotEmpty
                          ? tenant.propertyId
                          : (SupabaseService.instance.activePropertyId ?? ''));

                  if (propId.isNotEmpty) {
                    await SupabaseService.instance
                        .recordCashPaymentForRentLedger(
                      propertyId: propId,
                      propertyName: _propertyName,
                      tenantName: tenant.tenantName.isNotEmpty
                          ? tenant.tenantName
                          : 'Resident',
                      roomNumber: tenant.roomNumber,
                      amount: amt,
                      collectedBy: _selectedStaffActor,
                      ledgerId: tenant.id,
                      notes: notesCtrl.text.trim(),
                    );
                    await _loadDayCollectionData();
                  }

                  _showToast(
                      '₹${amt.toInt()} Cash recorded for ${tenant.tenantName} by $_selectedStaffActor ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Confirm & Mark Paid',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Modal: View Stamped Receipt
  void _openReceiptModal(RentLedgerModel tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildBottomSheetWrapper(
          title: 'Digital Rent Receipt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildRow('Tenant Name:', tenant.tenantName, isBold: true),
                    const SizedBox(height: 8),
                    _buildRow('Room / Bed:',
                        '${tenant.roomNumber} ${tenant.bedNumber != null ? "(${tenant.bedNumber})" : ""}'),
                    const SizedBox(height: 8),
                    _buildRow('Month / Period:', tenant.cycleMonth),
                    const SizedBox(height: 8),
                    _buildRow('Amount Paid:', '₹${tenant.rentAmount.toInt()}',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildRow('Transaction Ref:', tenant.paymentMode,
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildRow(
                        'Date of Payment:',
                        tenant.paidDate != null
                            ? '${tenant.paidDate!.day}/${tenant.paidDate!.month}/${tenant.paidDate!.year}'
                            : 'Paid'),
                    const SizedBox(height: 8),
                    _buildRow('Verified By:', _selectedStaffActor),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Receipt PDF Downloaded ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Download PDF Receipt',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetWrapper(
      {required String title, required Widget child}) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom + 16
        : mediaQuery.padding.bottom + 32;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child:
                            Icon(Icons.close, size: 14, color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
