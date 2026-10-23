import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/models.dart';

/// 🍽️ Tenant Food Menu View & Day Inspector Screen
/// Clean, zero-bloat daily menu reader for residents.
class TenantFoodMenuScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String pgName;
  final String? propertyId;

  const TenantFoodMenuScreen({
    super.key,
    this.onBack,
    this.pgName = '',
    this.propertyId,
  });

  @override
  State<TenantFoodMenuScreen> createState() => _TenantFoodMenuScreenState();
}

class _TenantFoodMenuScreenState extends State<TenantFoodMenuScreen> {
  // Week cycle length configured by owner (e.g. 1, 2, 3, or 4 weeks)
  int _cycleWeeks = 2;

  // Active selected week (0 = Week 1, 1 = Week 2, etc.)
  int _activeWeekIndex = 0;

  // Active selected day (0 = MON ... 6 = SUN)
  late int _activeDayIndex;
  late String _pgName;
  String? _propertyId;

  final List<String> _dayNames = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];
  final List<String> _fullDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Storage representation matching the Owner data structure
  late Map<int, Map<int, Map<String, dynamic>>> _menuStore;

  @override
  void initState() {
    super.initState();
    _pgName = widget.pgName;
    _propertyId = widget.propertyId;

    // Auto-select today's day of the week (DateTime: Mon=1, Sun=7 -> 0-indexed)
    final todayWeekday = DateTime.now().weekday;
    _activeDayIndex = (todayWeekday - 1).clamp(0, 6);

    _initializeMenuStore();
    _loadMenuFromSupabase();
  }

  Future<void> _loadMenuFromSupabase() async {
    try {
      String? propId = _propertyId;
      if (propId == null || propId.isEmpty) {
        final prop = await SupabaseService.instance.getOwnerProperty();
        propId = prop?['id']?.toString() ??
            SupabaseService.instance.activePropertyId;
      }

      if (propId != null && propId.isNotEmpty) {
        _propertyId = propId;
        if (_pgName.isEmpty) {
          final propData = await SupabaseService.instance.client
              .from('properties')
              .select('property_name')
              .eq('id', propId)
              .maybeSingle();
          if (propData != null && mounted) {
            setState(() {
              _pgName = propData['property_name']?.toString() ?? '';
            });
          }
        }

        final list = await SupabaseService.instance.getFoodMenuModels(propId);
        if (mounted && list.isNotEmpty) {
          int maxCycle = _cycleWeeks;
          for (final item in list) {
            final cycle = item.cycleWeeks;
            if (cycle > 0 && cycle <= 4) {
              maxCycle = cycle;
            }
            final rawWeek = item.weekNumber;
            final weekIdx = (rawWeek - 1).clamp(0, 3);
            final day = item.dayOfWeek.toUpperCase();
            final dayIdx = _dayNames.indexOf(day);
            if (dayIdx != -1) {
              _menuStore[weekIdx] ??= {};
              _menuStore[weekIdx]![dayIdx] = {
                'breakfast': {
                  'notProvided': item.breakfast.trim().isEmpty,
                  'dishes': item.breakfast,
                },
                'lunch': {
                  'notProvided': item.lunch.trim().isEmpty,
                  'dishes': item.lunch,
                },
                'dinner': {
                  'notProvided': item.dinner.trim().isEmpty,
                  'dishes': item.dinner,
                },
              };
            }
          }
          setState(() {
            _cycleWeeks = maxCycle;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tenant menu: $e');
    }
  }

  void _initializeMenuStore() {
    _menuStore = {};
    for (int w = 0; w < 4; w++) {
      _menuStore[w] = {};
      for (int d = 0; d < 7; d++) {
        _menuStore[w]![d] = {
          'breakfast': {'notProvided': false, 'dishes': ''},
          'lunch': {'notProvided': false, 'dishes': ''},
          'dinner': {'notProvided': false, 'dishes': ''},
        };
      }
    }
  }

  String _getFormattedDateHeader() {
    final now = DateTime.now();
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
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${now.day} ${months[now.month - 1]} (${shortDays[now.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekdayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    final isSelectedDayToday = _activeDayIndex == todayWeekdayIndex;

    final dayPlan = _menuStore[_activeWeekIndex]?[_activeDayIndex] ??
        {
          'breakfast': {'notProvided': false, 'dishes': ''},
          'lunch': {'notProvided': false, 'dishes': ''},
          'dinner': {'notProvided': false, 'dishes': ''},
        };

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
              'Food Menu',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              _pgName.isNotEmpty
                  ? '$_pgName • Daily Meals'
                  : 'Daily Meals & Mess Schedule',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              // 1. DYNAMIC WEEK SELECTOR (In Parent Card with In-House Green Header)
              if (_cycleWeeks > 1) ...[
                Text(
                  'WEEK',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Parent Card for Weeks
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildWeeksLayout(),
                ),
                const SizedBox(height: 18),
              ],

              // 2. DAY SELECTOR (In Parent Card with In-House Green Header)
              Text(
                'DAY',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Parent Card for Days
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(7, (index) {
                    final isSelected = _activeDayIndex == index;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 6 ? 6 : 0),
                        child: _buildDayBox(
                          label: _dayNames[index],
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeDayIndex = index);
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 22),

              // 3. DAY HEADER (In-House Green text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_fullDayNames[_activeDayIndex]} Menu',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (isSelectedDayToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Today',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. BREAKFAST CARD (In-House Green Header)
              _buildTenantMealCard(
                mealName: 'Breakfast',
                icon: Icons.coffee_rounded,
                isNotProvided: dayPlan['breakfast']?['notProvided'] ?? false,
                dishes: dayPlan['breakfast']?['dishes'] ?? '',
              ),

              const SizedBox(height: 14),

              // 5. LUNCH CARD (In-House Green Header)
              _buildTenantMealCard(
                mealName: 'Lunch',
                icon: Icons.lunch_dining_rounded,
                isNotProvided: dayPlan['lunch']?['notProvided'] ?? false,
                dishes: dayPlan['lunch']?['dishes'] ?? '',
              ),

              const SizedBox(height: 14),

              // 6. DINNER CARD (In-House Green Header)
              _buildTenantMealCard(
                mealName: 'Dinner',
                icon: Icons.dinner_dining_rounded,
                isNotProvided: dayPlan['dinner']?['notProvided'] ?? false,
                dishes: dayPlan['dinner']?['dishes'] ?? '',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 📐 Week Buttons Layout based on count:
  /// - 1 week: Center
  /// - 2 weeks: 1 left, 1 right
  /// - 3 weeks: 1 left, 1 middle, 1 right
  /// - 4 weeks: 2 up, 2 down
  Widget _buildWeeksLayout() {
    if (_cycleWeeks == 1) {
      return Center(
        child: SizedBox(
          width: 140,
          child: _buildSelectionBox(
            label: 'Week 1',
            isSelected: _activeWeekIndex == 0,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeWeekIndex = 0);
            },
          ),
        ),
      );
    } else if (_cycleWeeks == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 1',
              isSelected: _activeWeekIndex == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeWeekIndex = 0);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 2',
              isSelected: _activeWeekIndex == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeWeekIndex = 1);
              },
            ),
          ),
        ],
      );
    } else if (_cycleWeeks == 3) {
      return Row(
        children: [
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 1',
              isSelected: _activeWeekIndex == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeWeekIndex = 0);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 2',
              isSelected: _activeWeekIndex == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeWeekIndex = 1);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 3',
              isSelected: _activeWeekIndex == 2,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeWeekIndex = 2);
              },
            ),
          ),
        ],
      );
    } else {
      // 4 Weeks: 2 Up, 2 Down
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 1',
                  isSelected: _activeWeekIndex == 0,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeWeekIndex = 0);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 2',
                  isSelected: _activeWeekIndex == 1,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeWeekIndex = 1);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 3',
                  isSelected: _activeWeekIndex == 2,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeWeekIndex = 2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 4',
                  isSelected: _activeWeekIndex == 3,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeWeekIndex = 3);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  /// 📦 Clean Selection Box for Week selector
  Widget _buildSelectionBox({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenLight : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
              width: isSelected ? 1.3 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.greenDark : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 📅 Mon-Sun Day Box (Green styling when selected, no checkmarks)
  Widget _buildDayBox({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
              width: isSelected ? 1.3 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color:
                    isSelected ? AppColors.greenDark : AppColors.inkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🍽️ Individual Tenant Meal Card (With In-House Green Header)
  Widget _buildTenantMealCard({
    required String mealName,
    required IconData icon,
    required bool isNotProvided,
    required String dishes,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Meal Name in in-house green
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text(
                mealName,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dishes Content or Not Provided Notice
          if (isNotProvided)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Text(
                'Not provided on this day',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                dishes.isEmpty ? 'Menu not published yet' : dishes,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: dishes.isEmpty ? FontWeight.w500 : FontWeight.w600,
                  color: dishes.isEmpty ? AppColors.muted : AppColors.ink,
                  fontStyle: dishes.isEmpty ? FontStyle.italic : FontStyle.normal,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
