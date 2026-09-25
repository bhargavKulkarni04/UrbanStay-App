import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// 🍽️ Tenant Food Menu View & Day Inspector Screen
/// Clean, zero-bloat daily menu reader for residents.
class TenantFoodMenuScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TenantFoodMenuScreen({
    super.key,
    this.onBack,
  });

  @override
  State<TenantFoodMenuScreen> createState() => _TenantFoodMenuScreenState();
}

class _TenantFoodMenuScreenState extends State<TenantFoodMenuScreen> {
  // Week cycle length configured by owner (e.g. 2, 3, or 4 weeks)
  final int _cycleWeeks = 2;

  // Active selected week (0 = Week 1, 1 = Week 2, etc.)
  int _activeWeekIndex = 0;

  // Active selected day (0 = MON ... 6 = SUN)
  late int _activeDayIndex;

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
    // Auto-select today's day of the week (DateTime: Mon=1, Sun=7 -> 0-indexed)
    final todayWeekday = DateTime.now().weekday;
    _activeDayIndex = (todayWeekday - 1).clamp(0, 6);

    _initializeMenuStore();
  }

  void _initializeMenuStore() {
    _menuStore = {
      // Week 1
      0: {
        0: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Masala Dosa, Coconut Chutney, Sambar, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Sambar, Mix Veg Curry, Curd'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Chapati, Dal Tadka, Jeera Rice, Curd'
          },
        },
        1: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Idli Vada, Chutney, Sambar, Filter Coffee'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Rasam, Aloo Fry, Papad'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Roti, Paneer Butter Masala, Rice, Salad'
          },
        },
        2: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Poori Sagu, Chutney, Tea'
          },
          'lunch': {'notProvided': true, 'dishes': ''},
          'dinner': {
            'notProvided': false,
            'dishes': 'Egg Curry / Veg Kurma, Chapati, Ghee Rice'
          },
        },
        3: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Poha, Sev, Sweet Kesari Bath, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Palak Dal, Curd, Pickle'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Chapati, Mix Veg Gravy, Curd Rice'
          },
        },
        4: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Aloo Paratha, Curd, Green Chutney'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Tomato Dal, Beans Poriyal'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Veg Pulao, Raita, Gulab Jamun'
          },
        },
        5: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Rava Upma, Coconut Chutney, Coffee'
          },
          'lunch': {'notProvided': false, 'dishes': 'Rice, Sambar, Curd'},
          'dinner': {
            'notProvided': false,
            'dishes': 'Roti, Chana Masala, Rice'
          },
        },
        6: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Special Set Dosa, Vada, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Chicken Biryani / Veg Biryani, Raita, Sweet'
          },
          'dinner': {'notProvided': true, 'dishes': ''},
        },
      },
      // Week 2
      1: {
        0: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Onion Uttapam, Coconut Chutney, Sambar, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Dal Makhani, Bhindi Fry, Curd'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Chapati, Green Peas Masala, Jeera Rice'
          },
        },
        1: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Methi Paratha, Curd, Pickle, Coffee'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Lemon Rasam, Cabbage Poriyal, Papad'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Roti, Rajma Masala, Steamed Rice'
          },
        },
        2: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Rava Idli, Saagu, Chutney, Tea'
          },
          'lunch': {'notProvided': true, 'dishes': ''},
          'dinner': {
            'notProvided': false,
            'dishes': 'Veg Korma / Chicken Curry, Chapati, Rice'
          },
        },
        3: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Semiya Upma, Coconut Chutney, Coffee'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Drumstick Sambar, Carrot Beans Fry'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Chapati, Dal Tadka, Ghee Rice, Curd'
          },
        },
        4: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Gobi Paratha, Butter, Curd, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Rice, Palak Dal, Aloo Gobi Fry'
          },
          'dinner': {
            'notProvided': false,
            'dishes': 'Jeera Rice, Paneer Kadhai, Salad'
          },
        },
        5: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Bisibelebath, Boondi, Filter Coffee'
          },
          'lunch': {'notProvided': false, 'dishes': 'Rice, Tomato Rasam, Curd'},
          'dinner': {
            'notProvided': false,
            'dishes': 'Roti, Soya Chunks Curry, Rice'
          },
        },
        6: {
          'breakfast': {
            'notProvided': false,
            'dishes': 'Mysore Masala Dosa, Chutney, Sambar, Tea'
          },
          'lunch': {
            'notProvided': false,
            'dishes': 'Special Hyderabadi Dum Biryani, Mirchi Ka Salan'
          },
          'dinner': {'notProvided': true, 'dishes': ''},
        },
      },
    };
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
          'breakfast': {'notProvided': false, 'dishes': 'Regular Breakfast'},
          'lunch': {'notProvided': false, 'dishes': 'Regular Lunch'},
          'dinner': {'notProvided': false, 'dishes': 'Regular Dinner'},
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
              'Maruthi Luxury PG • Daily Meals',
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
                dishes.isEmpty ? 'Regular Menu' : dishes,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
