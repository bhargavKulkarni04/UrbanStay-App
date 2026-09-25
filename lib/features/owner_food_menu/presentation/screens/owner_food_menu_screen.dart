import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// 🍽️ Meal Item Data Model for each daily meal slot
class MealSlot {
  bool notProvided;
  String dishes;

  MealSlot({
    this.notProvided = false,
    this.dishes = '',
  });

  MealSlot copy() => MealSlot(
        notProvided: notProvided,
        dishes: dishes,
      );
}

/// 📅 Day Meal Plan (Breakfast, Lunch, Dinner)
class DayMealPlan {
  MealSlot breakfast;
  MealSlot lunch;
  MealSlot dinner;

  DayMealPlan({
    MealSlot? breakfast,
    MealSlot? lunch,
    MealSlot? dinner,
  })  : breakfast = breakfast ?? MealSlot(),
        lunch = lunch ?? MealSlot(),
        dinner = dinner ?? MealSlot();

  DayMealPlan copy() => DayMealPlan(
        breakfast: breakfast.copy(),
        lunch: lunch.copy(),
        dinner: dinner.copy(),
      );
}

/// 🏢 Owner Food Menu & Cycle Planner Screen
/// Allows PG Owners to setup a 1, 2, 3, or 4-week repeating meal cycle.
class OwnerFoodMenuScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerFoodMenuScreen({
    super.key,
    this.onBack,
  });

  @override
  State<OwnerFoodMenuScreen> createState() => _OwnerFoodMenuScreenState();
}

class _OwnerFoodMenuScreenState extends State<OwnerFoodMenuScreen> {
  // Selected repeating cycle length: 1, 2, 3, or 4 weeks
  int _selectedCycleWeeks = 2;

  // Active selected week index: 0 = Week 1, 1 = Week 2, etc.
  int _activeWeekIndex = 0;

  // Active selected day: 0 = MON ... 6 = SUN
  int _activeDayIndex = 0;

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

  // Storage: Map<WeekIndex, Map<DayIndex, DayMealPlan>>
  late Map<int, Map<int, DayMealPlan>> _menuStore;

  // Text editing controllers for current day
  late TextEditingController _breakfastController;
  late TextEditingController _lunchController;
  late TextEditingController _dinnerController;

  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _breakfastController = TextEditingController();
    _lunchController = TextEditingController();
    _dinnerController = TextEditingController();

    _initializeMenuStore();
    _loadCurrentDayIntoControllers();
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    super.dispose();
  }

  void _initializeMenuStore() {
    _menuStore = {};
    for (int w = 0; w < 4; w++) {
      _menuStore[w] = {};
      for (int d = 0; d < 7; d++) {
        _menuStore[w]![d] = _defaultMealFor(d);
      }
    }
  }

  DayMealPlan _defaultMealFor(int dayIndex) {
    switch (dayIndex) {
      case 0: // Mon
        return DayMealPlan(
          breakfast:
              MealSlot(dishes: 'Masala Dosa, Coconut Chutney, Sambar, Tea'),
          lunch: MealSlot(
              notProvided: false, dishes: 'Rice, Sambar, Mix Veg Curry, Curd'),
          dinner: MealSlot(dishes: 'Chapati, Dal Tadka, Jeera Rice, Curd'),
        );
      case 1: // Tue
        return DayMealPlan(
          breakfast:
              MealSlot(dishes: 'Idli Vada, Chutney, Sambar, Filter Coffee'),
          lunch: MealSlot(
              notProvided: false, dishes: 'Rice, Rasam, Aloo Fry, Papad'),
          dinner: MealSlot(dishes: 'Roti, Paneer Butter Masala, Rice, Salad'),
        );
      case 2: // Wed
        return DayMealPlan(
          breakfast: MealSlot(dishes: 'Poori Sagu, Chutney, Tea'),
          lunch: MealSlot(notProvided: true, dishes: ''),
          dinner: MealSlot(dishes: 'Egg Curry / Veg Kurma, Chapati, Ghee Rice'),
        );
      case 3: // Thu
        return DayMealPlan(
          breakfast: MealSlot(dishes: 'Poha, Sev, Sweet Kesari Bath, Tea'),
          lunch: MealSlot(
              notProvided: false, dishes: 'Rice, Palak Dal, Curd, Pickle'),
          dinner: MealSlot(dishes: 'Chapati, Mix Veg Gravy, Curd Rice'),
        );
      case 4: // Fri
        return DayMealPlan(
          breakfast: MealSlot(dishes: 'Aloo Paratha, Curd, Green Chutney'),
          lunch: MealSlot(
              notProvided: false, dishes: 'Rice, Tomato Dal, Beans Poriyal'),
          dinner: MealSlot(dishes: 'Veg Pulao, Raita, Gulab Jamun'),
        );
      case 5: // Sat
        return DayMealPlan(
          breakfast: MealSlot(dishes: 'Rava Upma, Coconut Chutney, Coffee'),
          lunch: MealSlot(notProvided: false, dishes: 'Rice, Sambar, Curd'),
          dinner: MealSlot(dishes: 'Roti, Chana Masala, Rice'),
        );
      case 6: // Sun
        return DayMealPlan(
          breakfast: MealSlot(dishes: 'Special Set Dosa, Vada, Tea'),
          lunch:
              MealSlot(dishes: 'Chicken Biryani / Veg Biryani, Raita, Sweet'),
          dinner: MealSlot(notProvided: true, dishes: ''),
        );
      default:
        return DayMealPlan();
    }
  }

  void _saveCurrentControllersToStore() {
    final currentPlan = _menuStore[_activeWeekIndex]?[_activeDayIndex];
    if (currentPlan != null) {
      currentPlan.breakfast.dishes = _breakfastController.text.trim();
      currentPlan.lunch.dishes = _lunchController.text.trim();
      currentPlan.dinner.dishes = _dinnerController.text.trim();
    }
  }

  void _loadCurrentDayIntoControllers() {
    final currentPlan =
        _menuStore[_activeWeekIndex]?[_activeDayIndex] ?? DayMealPlan();
    _breakfastController.text = currentPlan.breakfast.dishes;
    _lunchController.text = currentPlan.lunch.dishes;
    _dinnerController.text = currentPlan.dinner.dishes;
  }

  void _onCycleChanged(int newCycle) {
    _saveCurrentControllersToStore();
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCycleWeeks = newCycle;
      if (_activeWeekIndex >= newCycle) {
        _activeWeekIndex = 0;
      }
      _loadCurrentDayIntoControllers();
    });
  }

  void _onWeekChanged(int weekIndex) {
    _saveCurrentControllersToStore();
    HapticFeedback.selectionClick();
    setState(() {
      _activeWeekIndex = weekIndex;
      _loadCurrentDayIntoControllers();
    });
  }

  void _onDayChanged(int dayIndex) {
    _saveCurrentControllersToStore();
    HapticFeedback.selectionClick();
    setState(() {
      _activeDayIndex = dayIndex;
      _loadCurrentDayIntoControllers();
    });
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  void _copyToOtherWeeksOrMonth() {
    _saveCurrentControllersToStore();
    HapticFeedback.mediumImpact();

    final currentPlan = _menuStore[_activeWeekIndex]![_activeDayIndex]!;

    setState(() {
      if (_selectedCycleWeeks > 1) {
        for (int w = 0; w < _selectedCycleWeeks; w++) {
          if (w != _activeWeekIndex) {
            _menuStore[w]![_activeDayIndex] = currentPlan.copy();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              '${_fullDayNames[_activeDayIndex]} menu copied to all $_selectedCycleWeeks weeks',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        for (int w = 1; w < 4; w++) {
          _menuStore[w]![_activeDayIndex] = currentPlan.copy();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Menu set for whole month (same 1-week cycle)',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    });
  }

  void _handleSaveMenu() {
    _saveCurrentControllersToStore();
    HapticFeedback.heavyImpact();
    setState(() => _isSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Food menu published successfully',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan =
        _menuStore[_activeWeekIndex]?[_activeDayIndex] ?? DayMealPlan();

    return Scaffold(
      backgroundColor: Colors.white,
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
              'Food & Mess Menu',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Set repeating menu cycle for residents',
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
            child: InkWell(
              onTap: _handleSaveMenu,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.green, width: 1.2),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
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
              // 1. CHOOSE WEEK CYCLE (Parent Card + In-House Green Header + 1, 2, 3, 4 labels)
              Text(
                'CHOOSE WEEK CYCLE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Parent Card for Cycle Options (1, 2, 3, 4)
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
                child: Row(
                  children: [1, 2, 3, 4].map((cycle) {
                    final isSelected = _selectedCycleWeeks == cycle;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: cycle < 4 ? 8 : 0),
                        child: _buildSelectionBox(
                          label: '$cycle',
                          isSelected: isSelected,
                          onTap: () => _onCycleChanged(cycle),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // 2. DYNAMIC WEEKS TABS (In Parent Card with Placement Rules)
              if (_selectedCycleWeeks > 1) ...[
                Text(
                  'WEEKS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Parent Card for Weeks with Dynamic Placement
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

              // 3. DAY SELECTOR (In Parent Card + In-House Green Header)
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
                          onTap: () => _onDayChanged(index),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 22),

              // 4. DAY HEADER (In-House Green Text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_fullDayNames[_activeDayIndex]} Menu${_selectedCycleWeeks > 1 ? ' (Week ${_activeWeekIndex + 1})' : ''}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Max 30 words per meal',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. BREAKFAST CARD (In-House Green Header)
              _buildMealInputCard(
                mealName: 'Breakfast',
                icon: Icons.coffee_rounded,
                slot: currentPlan.breakfast,
                controller: _breakfastController,
                onToggleNotProvided: () {
                  setState(() {
                    currentPlan.breakfast.notProvided =
                        !currentPlan.breakfast.notProvided;
                  });
                },
              ),

              const SizedBox(height: 14),

              // 6. LUNCH CARD (In-House Green Header)
              _buildMealInputCard(
                mealName: 'Lunch',
                icon: Icons.lunch_dining_rounded,
                slot: currentPlan.lunch,
                controller: _lunchController,
                onToggleNotProvided: () {
                  setState(() {
                    currentPlan.lunch.notProvided =
                        !currentPlan.lunch.notProvided;
                  });
                },
              ),

              const SizedBox(height: 14),

              // 7. DINNER CARD (In-House Green Header)
              _buildMealInputCard(
                mealName: 'Dinner',
                icon: Icons.dinner_dining_rounded,
                slot: currentPlan.dinner,
                controller: _dinnerController,
                onToggleNotProvided: () {
                  setState(() {
                    currentPlan.dinner.notProvided =
                        !currentPlan.dinner.notProvided;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 8. APPLY TO OTHER WEEKS / MONTH BUTTON
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _copyToOtherWeeksOrMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        _selectedCycleWeeks > 1
                            ? 'Set this ${_fullDayNames[_activeDayIndex]} for other weeks'
                            : 'Set for whole month (same cycle)',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 9. PRIMARY SUBMIT CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSaveMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaved ? 'Menu Saved ✓' : 'Save Changes',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
    if (_selectedCycleWeeks == 1) {
      return Center(
        child: SizedBox(
          width: 140,
          child: _buildSelectionBox(
            label: 'Week 1',
            isSelected: _activeWeekIndex == 0,
            onTap: () => _onWeekChanged(0),
          ),
        ),
      );
    } else if (_selectedCycleWeeks == 2) {
      return Row(
        children: [
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 1',
              isSelected: _activeWeekIndex == 0,
              onTap: () => _onWeekChanged(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 2',
              isSelected: _activeWeekIndex == 1,
              onTap: () => _onWeekChanged(1),
            ),
          ),
        ],
      );
    } else if (_selectedCycleWeeks == 3) {
      return Row(
        children: [
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 1',
              isSelected: _activeWeekIndex == 0,
              onTap: () => _onWeekChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 2',
              isSelected: _activeWeekIndex == 1,
              onTap: () => _onWeekChanged(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSelectionBox(
              label: 'Week 3',
              isSelected: _activeWeekIndex == 2,
              onTap: () => _onWeekChanged(2),
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
                  onTap: () => _onWeekChanged(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 2',
                  isSelected: _activeWeekIndex == 1,
                  onTap: () => _onWeekChanged(1),
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
                  onTap: () => _onWeekChanged(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionBox(
                  label: 'Week 4',
                  isSelected: _activeWeekIndex == 3,
                  onTap: () => _onWeekChanged(3),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  /// 📦 Clean Selection Box (Light green background & green border when selected, white when unselected)
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

  /// 📅 Mon-Sun Day Box (Green styling when selected, no checkmark)
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

  /// 🍽️ Individual Meal Input Card (Breakfast, Lunch, Dinner with in-house green header)
  Widget _buildMealInputCard({
    required String mealName,
    required IconData icon,
    required MealSlot slot,
    required TextEditingController controller,
    required VoidCallback onToggleNotProvided,
  }) {
    final wordCount = _countWords(controller.text);
    final isOverLimit = wordCount > 30;

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
          // Header: Meal Name in in-house green + Not Provided Toggle Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

              // Not Provided Box
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleNotProvided();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: slot.notProvided
                          ? AppColors.greenLight
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: slot.notProvided
                            ? AppColors.green
                            : const Color(0xFFE5E7EB),
                        width: slot.notProvided ? 1.2 : 1.0,
                      ),
                    ),
                    child: Text(
                      'Not Provided',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: slot.notProvided
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: slot.notProvided
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Input Field or Disabled Container
          if (slot.notProvided)
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
          else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isOverLimit ? AppColors.warning : const Color(0xFFE5E7EB),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 2,
                minLines: 1,
                onChanged: (val) {
                  slot.dishes = val;
                  setState(() {});
                },
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Masala Dosa, Sambar, Coconut Chutney, Tea',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$wordCount/30 words',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isOverLimit ? AppColors.warning : AppColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
