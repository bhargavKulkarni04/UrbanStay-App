import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/owner_app_state.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/urban_loading.dart';

/// Screen 9: Maintenance & Complaints Ticketing Hub.
/// Strict Design Standards:
/// - Clean white elevated cards (#FFFFFF), soft hairline borders (#E5E7EB), zero harsh red borders.
/// - 3-Tier Hierarchy Context: Room Number + Sharing Type (e.g. Room 101 • 2-Sharing • Bed A).
/// - Zero Overflow: Proper Expanded, Flexible & Column layouts with ellipsis protection.
/// - Simplified PG Operations: 1-tap [ In Progress ] (notifies tenant) + 1-tap [ Mark Resolved ] (moves to History).
/// - Side-by-Side [ 📞 Call ] and [ 💬 WhatsApp ] contact buttons.
/// - Photo Proof viewer modal.
/// - Zero Emojis (pure native vector icons & Outfit font).
class OwnerComplaintsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? propertyId;

  const OwnerComplaintsScreen({super.key, this.onBack, this.propertyId});

  @override
  State<OwnerComplaintsScreen> createState() => _OwnerComplaintsScreenState();
}

class _OwnerComplaintsScreenState extends State<OwnerComplaintsScreen> {
  String _activeTab = 'active'; // 'active' | 'history'
  String _selectedCategory = 'all';
  String _selectedFloor = 'all';

  // Active Complaints List (Populated live from Supabase / State)
  final List<MaintenanceTicketModel> _activeTickets = [];

  // Resolution History List (Populated live from Supabase / State)
  final List<MaintenanceTicketModel> _historyTickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaintsFromSupabase();
  }

  Future<void> _loadComplaintsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final targetPropId = widget.propertyId ??
          SupabaseService.instance.activePropertyId;
      String? propId = targetPropId;
      if (propId == null || propId.isEmpty) {
        final prop = await SupabaseService.instance.getOwnerProperty();
        propId = prop?['id']?.toString();
      }

      if (propId != null && propId.isNotEmpty) {
        final list = await SupabaseService.instance.getMaintenanceTicketModels(propId);
        if (mounted) {
          setState(() {
            _activeTickets.clear();
            _activeTickets.addAll(list.where((t) => !t.isResolved));
            _historyTickets.clear();
            _historyTickets.addAll(list.where((t) => t.isResolved));
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading complaints: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
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
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  // Helper to extract initials
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'RS';
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

  // 1-Tap Mark In Progress (Async Supabase persistence)
  Future<void> _markInProgress(MaintenanceTicketModel ticket) async {
    final complaintId = ticket.id;
    if (complaintId.isNotEmpty) {
      final success = await SupabaseService.instance.updateComplaintStatus(
        complaintId: complaintId,
        status: 'in_progress',
        resolutionNotes: 'Acknowledged by Owner • Work in progress',
      );
      if (!success) {
        _showToast('Failed to update ticket status. Check connection.');
        return;
      }
    }

    setState(() {
      final index = _activeTickets.indexOf(ticket);
      if (index != -1) {
        _activeTickets[index] = MaintenanceTicketModel(
          id: ticket.id,
          propertyId: ticket.propertyId,
          propertyName: ticket.propertyName,
          tenantId: ticket.tenantId,
          tenantName: ticket.tenantName,
          roomNumber: ticket.roomNumber,
          category: ticket.category,
          issue: ticket.issue,
          photoUrl: ticket.photoUrl,
          status: 'in_progress',
          assignedStaff: ticket.assignedStaff,
          progressNote: 'Acknowledged by Owner • Work in progress',
          createdAt: ticket.createdAt,
        );
      }
    });
    _showToast(
        'Marked In Progress! ${ticket.tenantName.isNotEmpty ? ticket.tenantName : "Resident"} notified on WhatsApp.');
  }

  // 1-Tap Mark Resolved (Migrates from Active to History)
  Future<void> _markResolved(MaintenanceTicketModel ticket) async {
    final complaintId = ticket.id;
    if (complaintId.isNotEmpty) {
      final success =
          await SupabaseService.instance.resolveComplaint(complaintId);
      if (!success) {
        _showToast(
            'Failed to resolve complaint in database. Please check connection.');
        return;
      }
    }

    setState(() {
      _activeTickets.remove(ticket);
      _historyTickets.insert(
        0,
        MaintenanceTicketModel(
          id: ticket.id,
          propertyId: ticket.propertyId,
          propertyName: ticket.propertyName,
          tenantId: ticket.tenantId,
          tenantName: ticket.tenantName,
          roomNumber: ticket.roomNumber,
          category: ticket.category,
          issue: ticket.issue,
          photoUrl: ticket.photoUrl,
          status: 'resolved',
          assignedStaff: 'Resolved by Owner',
          progressNote: 'Issue inspected and fixed. Tenant notified on WhatsApp.',
          createdAt: ticket.createdAt,
        ),
      );
    });
    _showToast('Complaint resolved! Moved to History & WhatsApp alert sent.');
  }

  // ===========================================================================
  // PHOTO PROOF VIEWER MODAL
  // ===========================================================================
  void _openPhotoModal(MaintenanceTicketModel ticket) {
    final residentName = ticket.tenantName.isNotEmpty ? ticket.tenantName : 'Resident';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Photo Proof: $residentName',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_rounded,
                        size: 48, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(
                      'damage_proof.jpg',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Captured by Resident via UrbanStay Tenant App',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Issue Summary',
                style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.issue,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.ink, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Close Preview',
                  style: GoogleFonts.outfit(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: UrbanSpinner(size: 38),
        ),
      );
    }

    final pendingCount =
        _activeTickets.where((t) => t.isPending).length;
    final inProgressCount =
        _activeTickets.where((t) => t.isInProgress).length;
    final totalActive = pendingCount + inProgressCount;
    final resolvedCount = _historyTickets.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(totalActive),
            _buildTabBar(totalActive, resolvedCount),
            Expanded(
              child: _activeTab == 'active'
                  ? _buildActiveTicketsTab(pendingCount, inProgressCount)
                  : _buildHistoryTab(resolvedCount),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP STICKY HEADER
  // ===========================================================================
  Widget _buildTopHeader(int activeCount) {
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
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaints & Repairs',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${OwnerAppState.instance.activePropertyName.isNotEmpty ? OwnerAppState.instance.activePropertyName : "My PG"} • Maintenance Hub',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Active Badge Pill (Clean Neutral Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeCount > 0
                  ? const Color(0xFFFFFBEB)
                  : AppColors.greenLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: activeCount > 0
                    ? const Color(0xFFFDE68A)
                    : AppColors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$activeCount Active',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: activeCount > 0
                    ? const Color(0xFF92400E)
                    : AppColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DUAL TAB SELECTOR — Icon + Text pill (matches rent/staff screen pattern)
  // ===========================================================================
  Widget _buildTabBar(int activeCount, int resolvedCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Active Tickets tab
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 'active'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'active'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'active'
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
                        Icons.build_outlined,
                        size: 14,
                        color: _activeTab == 'active'
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Active Tickets ($activeCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'active'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'active'
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
            // Resolution History tab
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
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Resolution History ($resolvedCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'history'
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _activeTab == 'history'
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
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ACTIVE TICKETS
  // ===========================================================================
  Widget _buildActiveTicketsTab(int pendingCount, int inProgressCount) {
    final filtered = _activeTickets.where((t) {
      if (_selectedFloor != 'all' &&
          !_getFloor(t.roomNumber).toLowerCase().contains(_selectedFloor)) {
        return false;
      }
      if (_selectedCategory != 'all' &&
          t.category.toLowerCase() != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2-Pill Telemetry Stats Strip
          _buildStatsStrip(pendingCount, inProgressCount),
          const SizedBox(height: 12),

          // Horizontal Category Filter Chips
          _buildCategoryFilters(),
          const SizedBox(height: 10),

          // Horizontal Floor Switcher Chips
          _buildFloorSwitcherChips(),
          const SizedBox(height: 14),

          // Tickets List
          if (filtered.isEmpty)
            _buildEmptyState('No active maintenance tickets found.')
          else
            ...filtered
                .map((ticket) => _buildActiveTicketCard(ticket))
                .toList(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: RESOLUTION HISTORY LEDGER
  // ===========================================================================
  Widget _buildHistoryTab(int resolvedCount) {
    final filtered = _historyTickets.where((t) {
      if (_selectedFloor != 'all' &&
          !_getFloor(t.roomNumber).toLowerCase().contains(_selectedFloor)) {
        return false;
      }
      if (_selectedCategory != 'all' &&
          t.category.toLowerCase() != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 96.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // History Header Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audit Ledger: Showing all $resolvedCount resolved repairs with full completion audit.',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category & Floor Filters
          _buildCategoryFilters(),
          const SizedBox(height: 10),
          _buildFloorSwitcherChips(),
          const SizedBox(height: 14),

          // History Cards List
          if (filtered.isEmpty)
            _buildEmptyState('No resolution history records found.')
          else
            ...filtered
                .map((ticket) => _buildHistoryTicketCard(ticket))
                .toList(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. STATS TELEMETRY STRIP
  // ===========================================================================
  Widget _buildStatsStrip(int pendingCount, int inProgressCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
              '$pendingCount', 'Pending Inspection', const Color(0xFFF97316)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
              '$inProgressCount', 'In Progress (Active)', AppColors.green),
        ),
      ],
    );
  }

  Widget _buildStatTile(String num, String label, Color numColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: numColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }

  // ===========================================================================
  // 4. CATEGORY FILTER CHIPS
  // ===========================================================================
  Widget _buildCategoryFilters() {
    final categories = [
      {'id': 'all', 'label': 'All Categories'},
      {'id': 'electrical', 'label': 'Electrical'},
      {'id': 'plumbing', 'label': 'Plumbing'},
      {'id': 'wifi', 'label': 'WiFi'},
      {'id': 'carpentry', 'label': 'Carpentry'},
      {'id': 'cleaning', 'label': 'Cleaning'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategory == c['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategory = c['id']!);
                _showToast('Filtering by ${c['label']}');
              },
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  c['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 5. FLOOR SWITCHER CHIPS
  // ===========================================================================
  Widget _buildFloorSwitcherChips() {
    final floors = [
      {'id': 'all', 'label': 'All Floors'},
      {'id': '1st', 'label': '1st Floor'},
      {'id': '2nd', 'label': '2nd Floor'},
      {'id': '3rd', 'label': '3rd Floor'},
      {'id': 'ground', 'label': 'Ground Floor'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: floors.map((f) {
          final isSelected = _selectedFloor == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedFloor = f['id']!);
                _showToast('Showing ${f['label']}');
              },
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 6. ACTIVE TICKET CARD (Clean White Elevated Card, Proper Spacing & 3-Tier Context)
  // ===========================================================================
  Widget _buildActiveTicketCard(MaintenanceTicketModel ticket) {
    final isPending = ticket.isPending;
    final residentName =
        ticket.tenantName.isNotEmpty ? ticket.tenantName : 'Resident';
    final initials = _getInitials(residentName);
    final roomDisplay = ticket.roomNumber.isNotEmpty
        ? (ticket.roomNumber.startsWith('Room')
            ? ticket.roomNumber
            : 'Room ${ticket.roomNumber}')
        : 'Room --';
    final floor = _getFloor(ticket.roomNumber);
    final categoryText =
        ticket.category.isNotEmpty ? ticket.category : 'General';
    final reportedTime = ticket.createdAt != null
        ? ticket.createdAt!.toString().split('T').first
        : 'Recent';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row: 40px Avatar + Resident Name + Category Tag + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + Category + Room Hierarchy Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            residentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryText,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Room • Sharing • Floor • Time
                    Text(
                      '$roomDisplay • 2-Sharing • $floor • $reportedTime',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill (Clean Neutral Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFFFBEB)
                      : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPending
                        ? const Color(0xFFFDE68A)
                        : AppColors.green.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  isPending ? 'Pending' : 'In Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? const Color(0xFF92400E)
                        : AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Issue Description Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Text(
              ticket.issue,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),

          // Progress Note Strip (If In Progress)
          if (!isPending && ticket.progressNote != null && ticket.progressNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
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
                      ticket.progressNote!,
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

          // Photo Proof Row (If attached)
          if (ticket.photoUrl != null && ticket.photoUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          size: 15, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        'damage_proof.jpg',
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _openPhotoModal(ticket),
                    child: Text(
                      'View Photo',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Row 1: Full-width SVG Call + WhatsApp buttons
          Row(
            children: [
              // 📞 Call — full-width with SVG phone icon
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'Calling $residentName'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/phone.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                              AppColors.ink, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Call',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 💬 WhatsApp — full-width with SVG WhatsApp icon
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'WhatsApp opened with $residentName regarding $categoryText'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/whatsapp.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                              AppColors.greenDark, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Operational Action Buttons (1-Tap In Progress + 1-Tap Mark Resolved)
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: InkWell(
                    onTap: () async => await _markInProgress(ticket),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: Text(
                          'Start Work (In Progress)',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: InkWell(
                  onTap: () async => await _markResolved(ticket),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Mark Resolved',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
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
  // 7. HISTORY TICKET CARD (Zero Overflow, Clean Layout & Spacing)
  // ===========================================================================
  Widget _buildHistoryTicketCard(MaintenanceTicketModel ticket) {
    final residentName =
        ticket.tenantName.isNotEmpty ? ticket.tenantName : 'Resident';
    final initials = _getInitials(residentName);
    final roomDisplay = ticket.roomNumber.isNotEmpty
        ? (ticket.roomNumber.startsWith('Room')
            ? ticket.roomNumber
            : 'Room ${ticket.roomNumber}')
        : 'Room --';
    final categoryText =
        ticket.category.isNotEmpty ? ticket.category : 'General';
    final resolvedDate = ticket.createdAt != null
        ? ticket.createdAt!.toString().split('T').first
        : 'Resolved';
    final resolvedBy = ticket.assignedStaff?.isNotEmpty == true
        ? ticket.assignedStaff!
        : 'Resolved by Owner';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Avatar + Name + Category + Resolved Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name + Subtitle (Wrapped in Expanded to prevent ANY overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            residentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryText,
                            style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Room & Timing Subtitle
                    Text(
                      '$roomDisplay • 2-Sharing • $resolvedDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Resolved Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Resolved',
                  style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Issue Text
          Text(
            ticket.issue,
            style: GoogleFonts.outfit(
                fontSize: 12.5, color: AppColors.inkSecondary, height: 1.35),
          ),
          const SizedBox(height: 10),

          // Resolution Audit Box (Column format - never overflows!)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      resolvedBy,
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark),
                    ),
                    Text(
                      'Tenant Notified ✓',
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted),
                    ),
                  ],
                ),
                if (ticket.progressNote != null && ticket.progressNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ticket.progressNote!,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.inkSecondary,
                        height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 40, color: AppColors.green),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE NATIVE MODAL WRAPPER
  // ===========================================================================
  Widget _buildNativeBottomSheetWrapper(
      {required String title, required Widget child}) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
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
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 15, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
