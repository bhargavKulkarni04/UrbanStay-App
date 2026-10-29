import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/housekeeping_model.dart';
import '../../../../core/widgets/urban_loading.dart';

/// ==============================================================================
/// OWNER HOUSEKEEPING & ROOM CLEANING SCREEN
/// Clean enterprise screen for PG owners & wardens to view incoming housekeeping
/// requests from residents and mark them as COMPLETED.
/// Zero mocks, zero fallbacks, zero emojis.
/// ==============================================================================

class OwnerHousekeepingScreen extends StatefulWidget {
  final String? propertyId;
  final String propertyName;
  final VoidCallback? onBack;

  const OwnerHousekeepingScreen({
    super.key,
    this.propertyId,
    this.propertyName = 'Property',
    this.onBack,
  });

  @override
  State<OwnerHousekeepingScreen> createState() =>
      _OwnerHousekeepingScreenState();
}

class _OwnerHousekeepingScreenState extends State<OwnerHousekeepingScreen> {
  bool _isLoading = true;
  String _selectedTab = 'PENDING'; // 'PENDING' | 'COMPLETED'
  List<HousekeepingModel> _allRequests = [];

  String get _resolvedPropertyId =>
      widget.propertyId ?? SupabaseService.instance.activePropertyId ?? '';

  @override
  void initState() {
    super.initState();
    _fetchHousekeepingRequests();
  }

  Future<void> _fetchHousekeepingRequests() async {
    setState(() => _isLoading = true);
    UrbanLoadingService.show('Loading housekeeping requests...');

    try {
      final requests = await SupabaseService.instance
          .getHousekeepingModels(_resolvedPropertyId);

      if (mounted) {
        setState(() {
          _allRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading housekeeping in owner screen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      UrbanLoadingService.hide();
    }
  }

  Future<void> _markRequestCompleted(String requestId) async {
    HapticFeedback.lightImpact();
    UrbanLoadingService.show('Marking request completed...');

    try {
      final success =
          await SupabaseService.instance.completeHousekeepingRequest(requestId);

      if (success && mounted) {
        // Refresh live list from Supabase
        final updated = await SupabaseService.instance
            .getHousekeepingModels(_resolvedPropertyId);

        if (mounted) {
          setState(() {
            _allRequests = updated;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Housekeeping service marked as completed.',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking request complete: $e');
    } finally {
      UrbanLoadingService.hide();
    }
  }

  List<HousekeepingModel> get _filteredRequests {
    if (_selectedTab == 'PENDING') {
      return _allRequests.where((r) => r.isPending).toList();
    } else {
      return _allRequests.where((r) => r.isCompleted).toList();
    }
  }

  int get _pendingCount => _allRequests.where((r) => r.isPending).length;
  int get _completedCount => _allRequests.where((r) => r.isCompleted).length;

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      final months = [
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
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Housekeeping Hub',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              widget.propertyName,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.ink, size: 20),
            onPressed: _fetchHousekeepingRequests,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: _isLoading
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: AppColors.green,
              onRefresh: _fetchHousekeepingRequests,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // 1. Metric Counters
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Pending Requests',
                          count: _pendingCount,
                          isActive: _selectedTab == 'PENDING',
                          highlightColor: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                          onTap: () {
                            setState(() => _selectedTab = 'PENDING');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'Completed Services',
                          count: _completedCount,
                          isActive: _selectedTab == 'COMPLETED',
                          highlightColor: AppColors.greenDark,
                          bgColor: const Color(0xFFEBF8EE),
                          onTap: () {
                            setState(() => _selectedTab = 'COMPLETED');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Segmented Filter Tabs
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            title: 'Scheduled ($_pendingCount)',
                            isSelected: _selectedTab == 'PENDING',
                            onTap: () {
                              setState(() => _selectedTab = 'PENDING');
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: 'Completed ($_completedCount)',
                            isSelected: _selectedTab == 'COMPLETED',
                            onTap: () {
                              setState(() => _selectedTab = 'COMPLETED');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Requests List
                  if (_filteredRequests.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredRequests.map((req) => _buildRequestCard(req)),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required bool isActive,
    required Color highlightColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? highlightColor : const Color(0xFFE5E7EB),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'View',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: highlightColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(HousekeepingModel req) {
    final bool isCompleted = req.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isCompleted ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Room number & Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.roomNumber.isNotEmpty
                    ? 'Room ${req.roomNumber}'
                    : 'Room --',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                _formatTimestamp(req.createdAt),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Resident Name
          Text(
            req.tenantName.isNotEmpty
                ? 'Resident: ${req.tenantName}'
                : 'Resident Assigned',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 10),

          // Service Pill Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF8EE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              req.serviceType,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.greenDark,
              ),
            ),
          ),

          if (req.timeSlot.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Slot / Items: ${req.timeSlot}',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Bottom Action
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _markRequestCompleted(req.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Mark Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.greenDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Completed',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cleaning_services_outlined,
              size: 26,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 'PENDING'
                ? 'No Pending Requests'
                : 'No Completed History',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 'PENDING'
                ? 'All housekeeping requests for this property are cleared.'
                : 'Completed cleaning services will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
