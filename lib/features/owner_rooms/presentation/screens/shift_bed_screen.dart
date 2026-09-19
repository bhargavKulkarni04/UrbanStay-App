import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';

/// Full-Page Screen for Shifting a Resident's Bed or Swapping Rooms with another Resident.
class ShiftBedScreen extends StatefulWidget {
  final Map<String, dynamic> resident;
  final String roomName;
  final List<Map<String, dynamic>> rooms;
  final VoidCallback onShiftSuccess;

  const ShiftBedScreen({
    super.key,
    required this.resident,
    required this.roomName,
    required this.rooms,
    required this.onShiftSuccess,
  });

  @override
  State<ShiftBedScreen> createState() => _ShiftBedScreenState();
}

class _ShiftBedScreenState extends State<ShiftBedScreen> {
  // 0: Move to Vacant Room, 1: Swap Rooms
  int _selectedTab = 0;

  // State for Empty Room selection
  String? _selectedEmptyRoom;
  String? _selectedEmptyBed;
  int? _selectedEmptyRent;
  String _selectedFloorFilter = 'all';

  // State for Swap selection
  Map<String, dynamic>? _selectedTargetResident;
  String? _selectedTargetRoom;
  String _swapSearchQuery = '';
  String _swapFloorFilter = 'all';
  String _effectiveDate = 'immediate'; // 'immediate' or 'next_cycle'
  String _depositHandling = 'keep'; // 'keep' or 'adjust'

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newRentController = TextEditingController();
  final TextEditingController _newDepositController = TextEditingController();

  // Controllers for Swap Tab (both residents editable)
  final TextEditingController _swapRes1RentController = TextEditingController();
  final TextEditingController _swapRes1DepositController = TextEditingController();
  final TextEditingController _swapRes2RentController = TextEditingController();
  final TextEditingController _swapRes2DepositController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _newRentController.dispose();
    _newDepositController.dispose();
    _swapRes1RentController.dispose();
    _swapRes1DepositController.dispose();
    _swapRes2RentController.dispose();
    _swapRes2DepositController.dispose();
    super.dispose();
  }

  // Get all empty beds
  List<Map<String, dynamic>> _getVacantBeds() {
    final List<Map<String, dynamic>> vacant = [];
    for (final room in widget.rooms) {
      if (_selectedFloorFilter != 'all' &&
          room['floor'] != _selectedFloorFilter) {
        continue;
      }
      final beds = room['beds'] as List<dynamic>;
      for (final bed in beds) {
        if (bed['isOccupied'] == false) {
          vacant.add({
            'room': room['room'],
            'floor': room['floorLabel'] ?? room['floor'],
            'roomType': room['type'],
            'bed': bed['bed'],
            'title': bed['title'] ?? '${room['room']} - ${bed['bed']}',
            'rent': int.tryParse(bed['rent']?.toString() ?? '8500') ?? 8500,
            'deposit': bed['deposit']?.toString() ?? '15000',
            'rawBed': bed,
            'rawRoom': room,
          });
        }
      }
    }
    return vacant;
  }

  // Get all occupied residents eligible for swap (excluding current resident)
  List<Map<String, dynamic>> _getEligibleSwapResidents() {
    final List<Map<String, dynamic>> residents = [];
    final currentName = widget.resident['name']?.toString().toLowerCase() ?? '';
    final currentPhone = widget.resident['phone']?.toString() ?? '';

    for (final room in widget.rooms) {
      if (_swapFloorFilter != 'all' &&
          room['floor'] != _swapFloorFilter) {
        continue;
      }
      final beds = room['beds'] as List<dynamic>;
      for (final bed in beds) {
        if (bed['isOccupied'] == true) {
          final name = bed['name']?.toString() ?? '';
          final phone = bed['phone']?.toString() ?? '';

          // Exclude self
          if (name.toLowerCase() == currentName && phone == currentPhone) {
            continue;
          }

          // Search query filter
          if (_swapSearchQuery.isNotEmpty) {
            final q = _swapSearchQuery.toLowerCase();
            final roomStr = room['room']?.toString().toLowerCase() ?? '';
            if (!name.toLowerCase().contains(q) && !roomStr.contains(q)) {
              continue;
            }
          }

          residents.add({
            'room': room['room'],
            'floor': room['floorLabel'] ?? room['floor'],
            'roomType': room['type'],
            'bed': bed['bed'],
            'resident': bed,
            'rawRoom': room,
          });
        }
      }
    }
    return residents;
  }

  // Execute Move to Empty Bed
  void _executeMoveToEmptyBed() {
    if (_selectedEmptyRoom == null || _selectedEmptyBed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an empty bed first'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final residentName = widget.resident['name'] ?? 'Resident';

    // 1. Locate and vacate the current bed
    for (final r in widget.rooms) {
      if (r['room'] == widget.roomName) {
        final beds = r['beds'] as List<dynamic>;
        for (final b in beds) {
          if (b['bed'] == widget.resident['bed'] && b['isOccupied'] == true) {
            b['isOccupied'] = false;
            b['title'] = 'Vacant ${b['bed']} — Available';
            b['sub'] = '₹${widget.resident['rent']}/mo • Ready for Walk-In';
            b.remove('name');
            b.remove('phone');
            b.remove('work');
            b.remove('initials');
            b.remove('status');
            b.remove('docs');
            b.remove('docsVerified');
            break;
          }
        }
        r['occupied'] = (r['occupied'] as int? ?? 1) - 1;
        break;
      }
    }

    // 2. Locate and occupy target bed
    for (final r in widget.rooms) {
      if (r['room'] == _selectedEmptyRoom) {
        final beds = r['beds'] as List<dynamic>;
        for (final b in beds) {
          if (b['bed'] == _selectedEmptyBed) {
            b['isOccupied'] = true;
            b['name'] = widget.resident['name'];
            b['initials'] = widget.resident['initials'];
            b['phone'] = widget.resident['phone'];
            b['work'] = widget.resident['work'];
            b['status'] = widget.resident['status'] ?? 'Active';
            b['rent'] = _newRentController.text.isNotEmpty ? _newRentController.text : (_selectedEmptyRent?.toString() ?? widget.resident['rent']);
            b['deposit'] = _newDepositController.text.isNotEmpty ? _newDepositController.text : widget.resident['deposit'];
            b['docs'] = widget.resident['docs'] ?? 'KYC Verified ✓';
            b['docsVerified'] = widget.resident['docsVerified'] ?? true;
            b.remove('title');
            b.remove('sub');
            break;
          }
        }
        r['occupied'] = (r['occupied'] as int? ?? 0) + 1;
        break;
      }
    }

    widget.onShiftSuccess();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$residentName successfully shifted to $_selectedEmptyRoom ✓'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  // Execute Mutual Resident Swap
  void _executeMutualSwap() {
    if (_selectedTargetResident == null || _selectedTargetRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a resident to swap with'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final currentResName = widget.resident['name'] ?? 'Resident 1';
    final targetResData = _selectedTargetResident!['resident'] as Map<String, dynamic>;
    final targetResName = targetResData['name'] ?? 'Resident 2';

    // Store snapshots
    final res1Name = widget.resident['name'];
    final res1Initials = widget.resident['initials'];
    final res1Phone = widget.resident['phone'];
    final res1Work = widget.resident['work'];
    final res1Status = widget.resident['status'] ?? 'Active';
    final res1Docs = widget.resident['docs'];
    final res1DocsVerified = widget.resident['docsVerified'];

    final res2Name = targetResData['name'];
    final res2Initials = targetResData['initials'];
    final res2Phone = targetResData['phone'];
    final res2Work = targetResData['work'];
    final res2Status = targetResData['status'] ?? 'Active';
    final res2Docs = targetResData['docs'];
    final res2DocsVerified = targetResData['docsVerified'];

    // Update Room 1 Bed -> Assign Resident 2
    for (final r in widget.rooms) {
      if (r['room'] == widget.roomName) {
        final beds = r['beds'] as List<dynamic>;
        for (final b in beds) {
          if (b['bed'] == widget.resident['bed']) {
            b['name'] = res2Name;
            b['initials'] = res2Initials;
            b['phone'] = res2Phone;
            b['work'] = res2Work;
            b['status'] = res2Status;
            b['rent'] = _swapRes2RentController.text.isNotEmpty
                ? _swapRes2RentController.text
                : (b['rent'] ?? '8500');
            b['deposit'] = _swapRes2DepositController.text.isNotEmpty
                ? _swapRes2DepositController.text
                : (b['deposit'] ?? '15000');
            b['docs'] = res2Docs;
            b['docsVerified'] = res2DocsVerified;
            break;
          }
        }
        break;
      }
    }

    // Update Room 2 Bed -> Assign Resident 1
    for (final r in widget.rooms) {
      if (r['room'] == _selectedTargetRoom) {
        final beds = r['beds'] as List<dynamic>;
        for (final b in beds) {
          if (b['bed'] == _selectedTargetResident!['bed']) {
            b['name'] = res1Name;
            b['initials'] = res1Initials;
            b['phone'] = res1Phone;
            b['work'] = res1Work;
            b['status'] = res1Status;
            b['rent'] = _swapRes1RentController.text.isNotEmpty
                ? _swapRes1RentController.text
                : (b['rent'] ?? '8500');
            b['deposit'] = _swapRes1DepositController.text.isNotEmpty
                ? _swapRes1DepositController.text
                : (b['deposit'] ?? '15000');
            b['docs'] = res1Docs;
            b['docsVerified'] = res1DocsVerified;
            break;
          }
        }
        break;
      }
    }

    widget.onShiftSuccess();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swapped $currentResName and $targetResName between ${widget.roomName} and $_selectedTargetRoom successfully ✓'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resName = widget.resident['name']?.toString() ?? 'Resident';
    final resInitials = widget.resident['initials']?.toString() ?? 'UR';
    final resBed = widget.resident['bed']?.toString() ?? 'Bed';
    final resRent = widget.resident['rent']?.toString() ?? '8500';
    final resDeposit = widget.resident['deposit']?.toString() ?? '15000';

    final vacantBeds = _getVacantBeds();
    final eligibleResidents = _getEligibleSwapResidents();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift Room or Swap Resident',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Property Room Matrix Management',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsiveHorizontalPadding,
                    vertical: 16,
                  ),
                  children: [
                    // 1. Current Resident Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CURRENT RESIDENT',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.greenLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.roomName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.greenLight,
                                child: Text(
                                  resInitials,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Current Rent: ₹$resRent',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    Text(
                                      'Deposit: ₹$resDeposit',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Tab Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: _selectedTab == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Move to Vacant Room',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 0 ? AppColors.ink : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: _selectedTab == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Swap Rooms',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 1 ? AppColors.ink : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TAB 0: MOVE TO EMPTY BED
                    if (_selectedTab == 0) ...[
                      // Floor Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFloorChip('all', 'All Floors'),
                            const SizedBox(width: 8),
                            _buildFloorChip('1st', '1st Floor'),
                            const SizedBox(width: 8),
                            _buildFloorChip('2nd', '2nd Floor'),
                            const SizedBox(width: 8),
                            _buildFloorChip('3rd', '3rd Floor'),
                            const SizedBox(width: 8),
                            _buildFloorChip('ground', 'Ground Floor'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'SELECT VACANT ROOM (${vacantBeds.length} AVAILABLE)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (vacantBeds.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Center(
                            child: Text(
                              'No vacant rooms found on this floor.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        )
                      else
                        ...vacantBeds.map((bedItem) {
                          final isSelected = _selectedEmptyRoom == bedItem['room'] &&
                              _selectedEmptyBed == bedItem['bed'];
                          final newRent = bedItem['rent'] as int;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedEmptyRoom = bedItem['room'];
                                  _selectedEmptyBed = bedItem['bed'];
                                  _selectedEmptyRent = newRent;
                                  _newRentController.text = newRent.toString();
                                  _newDepositController.text = bedItem['deposit']?.toString() ?? '15000';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected ? AppColors.green : AppColors.muted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${bedItem['room']} • ${bedItem['roomType']}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '₹$newRent',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.greenDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${bedItem['floor']}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      // Editable Rent & Deposit (visible when a bed is selected)
                      if (_selectedEmptyRoom != null) ...[
                        const SizedBox(height: 16),
                        _buildEditableRentDeposit(),
                      ],
                    ],

                    // TAB 1: SWAP WITH RESIDENT
                    if (_selectedTab == 1) ...[
                      // Floor Filter for Swap
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFloorChip('all', 'All Floors', isSwap: true),
                            const SizedBox(width: 8),
                            _buildFloorChip('1st', '1st Floor', isSwap: true),
                            const SizedBox(width: 8),
                            _buildFloorChip('2nd', '2nd Floor', isSwap: true),
                            const SizedBox(width: 8),
                            _buildFloorChip('3rd', '3rd Floor', isSwap: true),
                            const SizedBox(width: 8),
                            _buildFloorChip('ground', 'Ground Floor', isSwap: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _swapSearchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search resident name or room number...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                            prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'SELECT RESIDENT TO SWAP WITH',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (eligibleResidents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Center(
                            child: Text(
                              'No matching residents found.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        )
                      else
                        ...eligibleResidents.map((item) {
                          final targetRes = item['resident'] as Map<String, dynamic>;
                          final tName = targetRes['name']?.toString() ?? 'Resident';
                          final tInitials = targetRes['initials']?.toString() ?? 'TR';
                          final tRent = targetRes['rent']?.toString() ?? '8500';
                          final isSelected = _selectedTargetRoom == item['room'] &&
                              _selectedTargetResident?['bed'] == item['bed'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTargetResident = item;
                                  _selectedTargetRoom = item['room'];
                                  _swapRes1RentController.text = targetRes['rent']?.toString() ?? '8500';
                                  _swapRes1DepositController.text = targetRes['deposit']?.toString() ?? '15000';
                                  _swapRes2RentController.text = widget.resident['rent']?.toString() ?? '8500';
                                  _swapRes2DepositController.text = widget.resident['deposit']?.toString() ?? '15000';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected ? AppColors.green : AppColors.muted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: isSelected
                                          ? AppColors.greenLight
                                          : const Color(0xFFF1F5F9),
                                      child: Text(
                                        tInitials,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppColors.greenDark
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.greenDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item['room']} • ${item['roomType']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹$tRent',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.greenDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      // If target resident is selected, show Swap Details
                      if (_selectedTargetResident != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MUTUAL SWAP SUMMARY',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSwapColumn(
                                      name: resName,
                                      from: widget.roomName,
                                      to: '$_selectedTargetRoom',
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.swap_horiz_rounded,
                                        color: AppColors.greenDark, size: 26),
                                  ),
                                  Expanded(
                                    child: _buildSwapColumn(
                                      name: _selectedTargetResident!['resident']['name'] ?? 'Target',
                                      from: '$_selectedTargetRoom',
                                      to: widget.roomName,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Editable Rent & Deposit for BOTH Residents
                        _buildSwapEditableAmounts(
                          resName,
                          _selectedTargetResident!['resident']['name'] ?? 'Resident 2',
                        ),
                        const SizedBox(height: 16),

                        // Effective Date Options
                        Text(
                          'EFFECTIVE DATE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                label: 'Immediate Today',
                                isSelected: _effectiveDate == 'immediate',
                                onTap: () => setState(() => _effectiveDate = 'immediate'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRadioOption(
                                label: '1st of Next Month',
                                isSelected: _effectiveDate == 'next_cycle',
                                onTap: () => setState(() => _effectiveDate = 'next_cycle'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Deposit Policy
                        Text(
                          'SECURITY DEPOSIT HANDLING',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRadioOption(
                                label: 'Keep as-is',
                                isSelected: _depositHandling == 'keep',
                                onTap: () => setState(() => _depositHandling = 'keep'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRadioOption(
                                label: 'Adjust Difference',
                                isSelected: _depositHandling == 'adjust',
                                onTap: () => setState(() => _depositHandling = 'adjust'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveHorizontalPadding,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _showConfirmationSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedTab == 0 ? 'Review & Shift Room' : 'Review & Swap Rooms',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirmation Bottom Sheet ──────────────────────────────────────
  void _showConfirmationSheet() {
    final isShift = _selectedTab == 0;

    // Validate selection
    if (isShift && (_selectedEmptyRoom == null || _selectedEmptyBed == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vacant room first'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!isShift && (_selectedTargetResident == null || _selectedTargetRoom == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a resident to swap with'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final resName = widget.resident['name']?.toString() ?? 'Resident';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isShift ? 'Confirm Room Shift' : 'Confirm Mutual Room Swap',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            // Details card (White background, hairline border)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isShift
                    ? [
                        _confirmDetailRow('Resident', resName, isGreen: true),
                        const SizedBox(height: 8),
                        _confirmDetailRow('From Room', widget.roomName),
                        const SizedBox(height: 8),
                        _confirmDetailRow('To Room', '$_selectedEmptyRoom'),
                        const SizedBox(height: 8),
                        _confirmDetailRow('New Rent', '₹${_newRentController.text}', isGreen: true),
                        const SizedBox(height: 8),
                        _confirmDetailRow('New Deposit', '₹${_newDepositController.text}', isGreen: true),
                      ]
                    : [
                        _confirmDetailRow('Resident 1', resName, isGreen: true),
                        const SizedBox(height: 4),
                        _confirmDetailRow('Moves to', '$_selectedTargetRoom'),
                        const SizedBox(height: 4),
                        _confirmDetailRow('New Rent', '₹${_swapRes1RentController.text}', isGreen: true),
                        const SizedBox(height: 4),
                        _confirmDetailRow('New Deposit', '₹${_swapRes1DepositController.text}', isGreen: true),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE5E7EB), height: 1),
                        ),
                        _confirmDetailRow('Resident 2',
                            _selectedTargetResident!['resident']['name'] ?? 'Resident', isGreen: true),
                        const SizedBox(height: 4),
                        _confirmDetailRow('Moves to', widget.roomName),
                        const SizedBox(height: 4),
                        _confirmDetailRow('New Rent', '₹${_swapRes2RentController.text}', isGreen: true),
                        const SizedBox(height: 4),
                        _confirmDetailRow('New Deposit', '₹${_swapRes2DepositController.text}', isGreen: true),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE5E7EB), height: 1),
                        ),
                        _confirmDetailRow('Effective Date',
                            _effectiveDate == 'immediate' ? 'Immediately Today' : '1st of Next Month'),
                        const SizedBox(height: 6),
                        _confirmDetailRow('Deposit Handling',
                            _depositHandling == 'keep' ? 'Keep as-is' : 'Adjust Difference'),
                      ],
              ),
            ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (isShift) {
                        _executeMoveToEmptyBed();
                      } else {
                        _executeMutualSwap();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Yes, Confirm',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmDetailRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isGreen ? AppColors.greenDark : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  // ── Editable Rent & Deposit Widget (Tab 0: Vacant Room) ────────────
  Widget _buildEditableRentDeposit() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMIZE RENT & DEPOSIT',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust the amount if different from default room rate',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newRentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent',
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _newDepositController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Deposit',
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dual Editable Rent & Deposit Widget (Tab 1: Swap Rooms) ───────
  Widget _buildSwapEditableAmounts(String res1Name, String res2Name) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.currency_rupee, color: AppColors.greenDark, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMIZE RENT & DEPOSIT (BOTH RESIDENTS)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Set personalized room rates for each resident',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Resident 1 section
          Text(
            '$res1Name (Moving to $_selectedTargetRoom)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _swapRes1RentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent',
                    labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _swapRes1DepositController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Deposit',
                    labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),

          // Resident 2 section
          Text(
            '$res2Name (Moving to ${widget.roomName})',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _swapRes2RentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent',
                    labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _swapRes2DepositController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Deposit',
                    labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Floor Chip Builder ─────────────────────────────────────────────
  Widget _buildFloorChip(String id, String label, {bool isSwap = false}) {
    final isSelected = isSwap ? _swapFloorFilter == id : _selectedFloorFilter == id;
    return InkWell(
      onTap: () {
        setState(() {
          if (isSwap) {
            _swapFloorFilter = id;
          } else {
            _selectedFloorFilter = id;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildSwapColumn({
    required String name,
    required String from,
    required String to,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'From: $from',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            color: AppColors.muted,
          ),
        ),
        Text(
          'To: $to',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.greenDark,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.green : AppColors.muted,
              size: 15,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.greenDark : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
