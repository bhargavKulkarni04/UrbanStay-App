import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbanstay/core/theme/app_colors.dart';

/// 🧺 Washing Machine Slot Booking Screen
/// Matches the 4-step design system:
/// 1. Machine & Date Selection (Book Slot / My Bookings)
/// 2. Slot Time & Duration Selection
/// 3. Booking Confirmation Sheet
/// 4. Slot Booked! (Success Screen)
class WashingMachineBookingScreen extends StatefulWidget {
  final String roomNumber;
  final String bedId;

  const WashingMachineBookingScreen({
    super.key,
    this.roomNumber = '104',
    this.bedId = 'B',
  });

  @override
  State<WashingMachineBookingScreen> createState() =>
      _WashingMachineBookingScreenState();
}

class _WashingMachineBookingScreenState
    extends State<WashingMachineBookingScreen> {
  // Navigation step: 0 = Machine List, 1 = Time Slot, 2 = Confirm, 3 = Booked!
  int _currentStep = 0;

  // Tab: 0 = Book Slot, 1 = My Bookings
  int _activeTabIndex = 0;

  // Selected Date Index (0 = Sun 14 Sep, 1 = Mon 15 Sep, etc.)
  int _selectedDateIndex = 0;

  final List<Map<String, String>> _dates = [
    {'day': 'Sun', 'date': '14 Sep'},
    {'day': 'Mon', 'date': '15 Sep'},
    {'day': 'Tue', 'date': '16 Sep'},
    {'day': 'Wed', 'date': '17 Sep'},
    {'day': 'Thu', 'date': '18 Sep'},
  ];

  // Selected Machine
  int _selectedMachineIndex = 0;

  final List<Map<String, dynamic>> _machines = [
    {
      'name': 'Machine 01',
      'status': 'Available',
      'isAvailable': true,
      'subtext': 'Max 2 hours per booking',
    },
    {
      'name': 'Machine 02',
      'status': 'Available',
      'isAvailable': true,
      'subtext': 'Max 2 hours per booking',
    },
    {
      'name': 'Machine 03',
      'status': 'In Use',
      'isAvailable': false,
      'subtext': 'Available from 8:30 PM',
    },
  ];

  // Time Slot Selection
  String _selectedStartTime = '7:00 PM';
  final List<String> _timeSlots = [
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
    '9:00 PM',
  ];

  // Duration Selection
  String _selectedDuration = '2 hours';
  final List<String> _durations = ['1 hour', '2 hours', '3 hours'];

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = 'Washing Machine';
    if (_currentStep == 1) {
      title = _machines[_selectedMachineIndex]['name'];
    } else if (_currentStep == 2) {
      title = 'Confirm Booking';
    } else if (_currentStep == 3) {
      title = 'Booking Confirmed';
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: Color(0xFF111827)),
        onPressed: _goToPreviousStep,
      ),
      centerTitle: true,
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE5E7EB), height: 1),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1MachineSelection();
      case 1:
        return _buildStep2SlotSelection();
      case 2:
        return _buildStep3Confirmation();
      case 3:
        return _buildStep4Success();
      default:
        return _buildStep1MachineSelection();
    }
  }

  // ===========================================================================
  // 🟢 STEP 1: Available Machines & Date Selector
  // ===========================================================================
  Widget _buildStep1MachineSelection() {
    return ListView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Top Tabs: Book Slot | My Bookings
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              _buildTopTabItem('Book Slot', 0),
              _buildTopTabItem('My Bookings', 1),
            ],
          ),
        ),

        const SizedBox(height: 18),

        if (_activeTabIndex == 0) ...[
          // 2. Date Carousel (< Sun 14 Sep, Mon 15 Sep... >)
          _buildDateCarousel(),

          const SizedBox(height: 24),

          // 3. Section Title
          Text(
            'Available Machines',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Machines List Cards
          ...List.generate(_machines.length, (index) {
            final machine = _machines[index];
            return _buildMachineCard(machine, index);
          }),

          const SizedBox(height: 18),

          // 5. Booking Rules Card
          _buildBookingRulesCard(),
        ] else ...[
          // Empty or My Bookings List
          _buildMyBookingsTab(),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTopTabItem(String label, int index) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF08A63F) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color:
                  isActive ? const Color(0xFF08A63F) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCarousel() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 24, color: Color(0xFF6B7280)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
          onPressed: () {
            if (_selectedDateIndex > 0) {
              setState(() => _selectedDateIndex--);
            }
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_dates.length, (index) {
                final isSelected = _selectedDateIndex == index;
                final dateItem = _dates[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 68,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(
                                0xFF0F3E2E) // Dark elegant forest green
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F3E2E)
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateItem['day']!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.85)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateItem['date']!,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded,
              size: 24, color: Color(0xFF6B7280)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
          onPressed: () {
            if (_selectedDateIndex < _dates.length - 1) {
              setState(() => _selectedDateIndex++);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> machine, int index) {
    final bool isAvailable = machine['isAvailable'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (isAvailable) {
              setState(() {
                _selectedMachineIndex = index;
                _currentStep = 1;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${machine['name']} is currently in use. Please select Machine 01 or 02.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFD97706),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Washing Machine Thumbnail
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
                  ),
                  child: Image.asset(
                    'assets/images/washing_machine.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_laundry_service_rounded,
                      size: 32,
                      color: Color(0xFF08A63F),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvailable
                                  ? const Color(0xFF08A63F)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            machine['status'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? const Color(0xFF08A63F)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        machine['subtext'],
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F9F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1EAD8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF08A63F),
              ),
              const SizedBox(width: 8),
              Text(
                'Please follow the booking rules',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRuleBullet('Max 2 hours per booking'),
          _buildRuleBullet('1 booking per day'),
          _buildRuleBullet('10 mins buffer time between slots'),
          const SizedBox(height: 8),
          Text(
            'View all rules',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF08A63F),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B5563))),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFEBF8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_laundry_service_outlined,
              size: 36,
              color: Color(0xFF08A63F),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Bookings',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You do not have any upcoming laundry slots.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🟢 STEP 2: Slot Time & Duration Selection
  // ===========================================================================
  Widget _buildStep2SlotSelection() {
    final machine = _machines[_selectedMachineIndex];
    return ListView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Top Machine Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
                ),
                child: Image.asset(
                  'assets/images/washing_machine.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_laundry_service_rounded,
                    size: 32,
                    color: Color(0xFF08A63F),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF08A63F),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Available',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF08A63F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Max 2 hours per booking',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Select Start Time Section
        Text(
          'Select Start Time',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 12),

        // 3-Column Time Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedStartTime == slot;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedStartTime = slot),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F3E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F3E2E)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Text(
                  slot,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // 3. Select Duration Section
        Text(
          'Select Duration',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: _durations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedDuration = duration),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF0F3E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F3E2E)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      duration,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // 4. Booking Preview Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Preview',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              _buildPreviewRow(Icons.calendar_today_outlined, 'Sun, 14 Sep'),
              const SizedBox(height: 8),
              _buildPreviewRow(Icons.access_time_rounded,
                  '$_selectedStartTime - ${_calculateEndTime(_selectedStartTime, _selectedDuration)} ($_selectedDuration)'),
              const SizedBox(height: 8),
              _buildPreviewRow(
                  Icons.local_laundry_service_outlined, machine['name']),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 5. CTA Button: Check Availability
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3E2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Check Availability',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviewRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🟢 STEP 3: Confirm Booking Screen
  // ===========================================================================
  Widget _buildStep3Confirmation() {
    final machine = _machines[_selectedMachineIndex];
    return ListView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Machine Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            children: [
              // Top Machine Icon
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Image.asset(
                  'assets/images/washing_machine.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_laundry_service_rounded,
                    size: 40,
                    color: Color(0xFF08A63F),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                machine['name'],
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF08A63F),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Available',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF08A63F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE5E7EB), height: 1),
              const SizedBox(height: 18),

              // Breakdown rows
              _buildConfirmRow(
                  Icons.calendar_today_outlined, 'Sun, 14 Sep 2026'),
              const SizedBox(height: 14),
              _buildConfirmRow(Icons.access_time_rounded,
                  '$_selectedStartTime - ${_calculateEndTime(_selectedStartTime, _selectedDuration)} ($_selectedDuration)'),
              const SizedBox(height: 14),
              _buildConfirmRow(
                  Icons.hourglass_empty_rounded, '10 mins buffer after slot'),
              const SizedBox(height: 14),
              _buildConfirmRow(
                  Icons.person_outline_rounded, '1 booking per day'),
              const SizedBox(height: 14),
              _buildConfirmRow(Icons.currency_rupee_rounded, 'Free of cost'),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Please be on time banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F9F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1EAD8), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF08A63F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please be on time',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'In case you can\'t make it, cancel the slot so others can book.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 3. Confirm Booking CTA
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3E2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Confirm Booking',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4B5563)),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🟢 STEP 4: Slot Booked! (Success Screen)
  // ===========================================================================
  Widget _buildStep4Success() {
    final machine = _machines[_selectedMachineIndex];
    return ListView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // 1. Success Celebration Circle
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFF08A63F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Title & Subtitle
        Center(
          child: Text(
            'Slot Booked!',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F3E2E),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Center(
          child: Text(
            'Your washing machine slot has\nbeen successfully reserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 26),

        // 3. Booking Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE5E7EB), width: 0.8),
                    ),
                    child: Image.asset(
                      'assets/images/washing_machine.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_laundry_service_rounded,
                        size: 28,
                        color: Color(0xFF08A63F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sun, 14 Sep 2026',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF3F4F6), height: 1),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: Color(0xFF4B5563)),
                  const SizedBox(width: 8),
                  Text(
                    '$_selectedStartTime - ${_calculateEndTime(_selectedStartTime, _selectedDuration)} ($_selectedDuration)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Confirmed Status Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8EE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 14, color: Color(0xFF08A63F)),
                    const SizedBox(width: 5),
                    Text(
                      'Confirmed',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF08A63F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Action: Add to Calendar
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to your calendar with 15m reminder!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF08A63F),
              ),
            );
          },
          icon: const Icon(Icons.calendar_today_outlined,
              size: 17, color: Color(0xFF0F3E2E)),
          label: Text(
            'Add to Calendar',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F3E2E),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 5. Action: Cancel Booking (Soft Red Button)
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _currentStep = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled successfully.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          },
          icon: const Icon(Icons.delete_outline_rounded,
              size: 17, color: Color(0xFFDC2626)),
          label: Text(
            'Cancel Booking',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            backgroundColor: const Color(0xFFFEE2E2).withOpacity(0.6),
            foregroundColor: const Color(0xFFDC2626),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 6. Advisory Note
        Text(
          'Need to make changes?\nYou can cancel your booking anytime before the slot starts.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
            height: 1.35,
          ),
        ),

        const SizedBox(height: 26),

        // 7. Back to Home Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3E2E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Back to Home',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  String _calculateEndTime(String startTime, String duration) {
    // Basic calculation for UI display
    try {
      final parts = startTime.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int addHours = int.parse(duration.split(' ')[0]);
      String period = parts[1];

      int newHour = hour + addHours;
      if (newHour > 12) {
        newHour = newHour - 12;
        if (period == 'AM') {
          period = 'PM';
        } else {
          period = 'AM';
        }
      } else if (newHour == 12) {
        period = (period == 'AM') ? 'PM' : 'AM';
      }
      return '$newHour:00 $period';
    } catch (_) {
      return '9:00 PM';
    }
  }
}
