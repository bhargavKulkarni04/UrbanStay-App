import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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

  const OwnerComplaintsScreen({super.key, this.onBack});

  @override
  State<OwnerComplaintsScreen> createState() => _OwnerComplaintsScreenState();
}

class _OwnerComplaintsScreenState extends State<OwnerComplaintsScreen> {
  String _activeTab = 'active'; // 'active' | 'history'
  String _selectedCategory = 'all';
  String _selectedFloor = 'all';

  // Photo Viewer Modal Target
  Map<String, dynamic>? _activePhotoTarget;

  // Active Complaints List
  final List<Map<String, dynamic>> _activeTickets = [
    {
      'id': 'TKT-101',
      'residentName': 'Amit Verma',
      'initials': 'AV',
      'phone': '9988776655',
      'room': 'Room 201',
      'sharingType': '2-Sharing',
      'bed': 'Bed B',
      'floor': '2nd Floor',
      'category': 'Electrical',
      'categoryIcon': Icons.bolt_outlined,
      'issue': 'Geyser in bathroom is tripping the MCB switch every 2 minutes. Unable to get hot water.',
      'reportedTime': '2 hours ago',
      'reportedDate': '28 Aug 2026, 08:30 AM',
      'photoName': 'geyser_mcb_issue.jpg',
      'hasPhoto': true,
      'status': 'pending', // 'pending', 'in_progress'
    },
    {
      'id': 'TKT-102',
      'residentName': 'Rohan Patil',
      'initials': 'RP',
      'phone': '9811223344',
      'room': 'Room 102',
      'sharingType': '3-Sharing',
      'bed': 'Bed A',
      'floor': '1st Floor',
      'category': 'Plumbing',
      'categoryIcon': Icons.plumbing_outlined,
      'issue': 'Washbasin tap is continuously leaking and making noise throughout the night.',
      'reportedTime': '4 hours ago',
      'reportedDate': '28 Aug 2026, 06:15 AM',
      'photoName': 'tap_leak_photo.jpg',
      'hasPhoto': true,
      'status': 'in_progress',
      'progressNote': 'Acknowledged by Owner • Work in progress',
    },
    {
      'id': 'TKT-103',
      'residentName': 'Deepak Joshi',
      'initials': 'DJ',
      'phone': '9877112233',
      'room': 'Room 301',
      'sharingType': '2-Sharing',
      'bed': 'Bed A',
      'floor': '3rd Floor',
      'category': 'Carpentry',
      'categoryIcon': Icons.handyman_outlined,
      'issue': 'Wardrobe middle drawer handle is broken and latch is stuck.',
      'reportedTime': 'Yesterday',
      'reportedDate': '27 Aug 2026, 04:45 PM',
      'photoName': 'wardrobe_latch.jpg',
      'hasPhoto': true,
      'status': 'pending',
    },
  ];

  // Resolution History List
  final List<Map<String, dynamic>> _historyTickets = [
    {
      'id': 'TKT-098',
      'residentName': 'Rahul Sharma',
      'initials': 'RS',
      'phone': '9876543210',
      'room': 'Room 101',
      'sharingType': '2-Sharing',
      'bed': 'Bed A',
      'floor': '1st Floor',
      'category': 'WiFi',
      'categoryIcon': Icons.wifi_outlined,
      'issue': '1st floor Wi-Fi access point was blinking red and dropping connection.',
      'reportedDate': '26 Aug, 11:20 AM',
      'resolvedDate': 'Resolved 26 Aug, 01:10 PM',
      'resolvedBy': 'Resolved by Owner',
      'resolutionNote': 'Router rebooted and static DNS configured. Speed verified at 120 Mbps.',
      'status': 'resolved',
    },
    {
      'id': 'TKT-095',
      'residentName': 'Manisha Patel',
      'initials': 'MP',
      'phone': '9866443322',
      'room': 'Room 301',
      'sharingType': '2-Sharing',
      'bed': 'Bed B',
      'floor': '3rd Floor',
      'category': 'Electrical',
      'categoryIcon': Icons.bolt_outlined,
      'issue': 'Ceiling LED panel flickering continuously in bathroom.',
      'reportedDate': '25 Aug, 07:00 PM',
      'resolvedDate': 'Resolved 26 Aug, 10:00 AM',
      'resolvedBy': 'Resolved by Electrician',
      'resolutionNote': 'Replaced damaged driver with new 15W unit. Tested and confirmed with tenant.',
      'status': 'resolved',
    },
    {
      'id': 'TKT-092',
      'residentName': 'Priya Nair',
      'initials': 'PN',
      'phone': '9819876543',
      'room': 'Room 201',
      'sharingType': '2-Sharing',
      'bed': 'Bed B',
      'floor': '2nd Floor',
      'category': 'Cleaning',
      'categoryIcon': Icons.cleaning_services_outlined,
      'issue': 'Balcony drain clogged due to dry leaves during heavy rain.',
      'reportedDate': '24 Aug, 09:30 AM',
      'resolvedDate': 'Resolved 24 Aug, 11:00 AM',
      'resolvedBy': 'Resolved by Housekeeping',
      'resolutionNote': 'Drain cleared and mesh filter reinstalled to prevent leaf blockages.',
      'status': 'resolved',
    },
  ];

  @override
  void initState() {
    super.initState();
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

  // 1-Tap Mark In Progress (Simplified - no modal required)
  void _markInProgress(Map<String, dynamic> ticket) {
    setState(() {
      ticket['status'] = 'in_progress';
      ticket['progressNote'] = 'Acknowledged by Owner • Work in progress';
    });
    _showToast('Marked In Progress! ${ticket['residentName']} notified on WhatsApp.');
  }

  // 1-Tap Mark Resolved (Migrates from Active to History)
  void _markResolved(Map<String, dynamic> ticket) {
    setState(() {
      _activeTickets.remove(ticket);
      _historyTickets.insert(0, {
        'id': ticket['id'],
        'residentName': ticket['residentName'],
        'initials': ticket['initials'],
        'phone': ticket['phone'],
        'room': ticket['room'],
        'sharingType': ticket['sharingType'] ?? '2-Sharing',
        'bed': ticket['bed'],
        'floor': ticket['floor'],
        'category': ticket['category'],
        'categoryIcon': ticket['categoryIcon'],
        'issue': ticket['issue'],
        'reportedDate': ticket['reportedTime'] ?? 'Today',
        'resolvedDate': 'Resolved Today, Just Now',
        'resolvedBy': 'Resolved by Owner',
        'resolutionNote': 'Issue inspected and fixed. Tenant notified on WhatsApp.',
        'status': 'resolved',
      });
    });
    _showToast('Complaint resolved! Moved to History & WhatsApp alert sent.');
  }

  // ===========================================================================
  // PHOTO PROOF VIEWER MODAL
  // ===========================================================================
  void _openPhotoModal(Map<String, dynamic> ticket) {
    _activePhotoTarget = ticket;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Photo Proof: ${ticket['residentName']}',
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
                    Icon(ticket['categoryIcon'] ?? Icons.image_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(
                      ticket['photoName'] ?? 'damage_proof.jpg',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Captured by Resident via UrbanStay Tenant App',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Issue Summary',
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                ticket['issue'],
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, height: 1.4),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Close Preview',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
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
    final pendingCount = _activeTickets.where((t) => t['status'] == 'pending').length;
    final inProgressCount = _activeTickets.where((t) => t['status'] == 'in_progress').length;
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
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
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
                    'Greenview PG • Maintenance Hub',
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
              color: activeCount > 0 ? const Color(0xFFFFFBEB) : AppColors.greenLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: activeCount > 0 ? const Color(0xFFFDE68A) : AppColors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$activeCount Active',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: activeCount > 0 ? const Color(0xFF92400E) : AppColors.greenDark,
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
                    color: _activeTab == 'active' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'active'
                        ? const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_outlined,
                        size: 14,
                        color: _activeTab == 'active' ? AppColors.greenDark : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Active Tickets ($activeCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'active' ? FontWeight.w800 : FontWeight.w600,
                            color: _activeTab == 'active' ? AppColors.greenDark : AppColors.muted,
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
                    color: _activeTab == 'history' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'history'
                        ? const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: _activeTab == 'history' ? AppColors.greenDark : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Resolution History ($resolvedCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: _activeTab == 'history' ? FontWeight.w800 : FontWeight.w600,
                            color: _activeTab == 'history' ? AppColors.greenDark : AppColors.muted,
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
      if (_selectedFloor != 'all' && !(t['floor'] as String).toLowerCase().contains(_selectedFloor)) return false;
      if (_selectedCategory != 'all' && (t['category'] as String).toLowerCase() != _selectedCategory) return false;
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
            ...filtered.map((ticket) => _buildActiveTicketCard(ticket)).toList(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: RESOLUTION HISTORY LEDGER
  // ===========================================================================
  Widget _buildHistoryTab(int resolvedCount) {
    final filtered = _historyTickets.where((t) {
      if (_selectedFloor != 'all' && !(t['floor'] as String).toLowerCase().contains(_selectedFloor)) return false;
      if (_selectedCategory != 'all' && (t['category'] as String).toLowerCase() != _selectedCategory) return false;
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
                const Icon(Icons.history_rounded, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audit Ledger: Showing all $resolvedCount resolved repairs with full completion audit.',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.inkSecondary),
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
            ...filtered.map((ticket) => _buildHistoryTicketCard(ticket)).toList(),
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
          child: _buildStatTile('$pendingCount', 'Pending Inspection', const Color(0xFFF97316)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile('$inProgressCount', 'In Progress (Active)', AppColors.green),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
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
  Widget _buildActiveTicketCard(Map<String, dynamic> ticket) {
    final isPending = ticket['status'] == 'pending';

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
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    ticket['initials'] ?? 'AV',
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
                            ticket['residentName'],
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket['category'],
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
                    // Room • Sharing • Floor • Time (bed removed)
                    Text(
                      '${ticket['room']} • ${ticket['sharingType'] ?? '2-Sharing'} • ${ticket['floor']} • ${ticket['reportedTime']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill (Clean Neutral Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFFFBEB) : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPending ? const Color(0xFFFDE68A) : AppColors.green.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  isPending ? 'Pending' : 'In Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending ? const Color(0xFF92400E) : AppColors.greenDark,
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
              ticket['issue'],
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),

          // Progress Note Strip (If In Progress)
          if (!isPending && ticket['progressNote'] != null) ...[
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
                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket['progressNote'],
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Photo Proof Row (If attached)
          if (ticket['hasPhoto'] == true) ...[
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
                      const Icon(Icons.image_outlined, size: 15, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        ticket['photoName'],
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _openPhotoModal(ticket),
                    child: Text(
                      'View Photo',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
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
                  onTap: () => _showToast('Calling ${ticket['residentName']}: +91${ticket['phone']}'),
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
                          colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
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
                  onTap: () => _showToast('WhatsApp opened with ${ticket['residentName']} regarding ${ticket['category']}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/whatsapp.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(AppColors.greenDark, BlendMode.srcIn),
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
                    onTap: () => _markInProgress(ticket),
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
                  onTap: () => _markResolved(ticket),
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
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
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
  Widget _buildHistoryTicketCard(Map<String, dynamic> ticket) {
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
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    ticket['initials'] ?? 'RS',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.greenDark),
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
                            ticket['residentName'],
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket['category'],
                            style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Room & Timing Subtitle
                    Text(
                      '${ticket['room']} • ${ticket['sharingType'] ?? '2-Sharing'} (${ticket['bed']}) • ${ticket['resolvedDate']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
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
                  style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Issue Text
          Text(
            ticket['issue'],
            style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.inkSecondary, height: 1.35),
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
                      ticket['resolvedBy'],
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.greenDark),
                    ),
                    Text(
                      'Tenant Notified ✓',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
                if (ticket['resolutionNote'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ticket['resolutionNote'],
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.inkSecondary, height: 1.3),
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
          const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.green),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE NATIVE MODAL WRAPPER
  // ===========================================================================
  Widget _buildNativeBottomSheetWrapper({required String title, required Widget child}) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
