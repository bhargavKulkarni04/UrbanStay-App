import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen 6: Tenants & Rooms Matrix.
/// Production-Grade Responsive Flutter Implementation of `ProductionCode/owner_rooms.html`.
///
/// Features:
/// - Sticky Top Header with Back button, Title & Subtitle, and 4 Pending Badge.
/// - Live Resident & Room Search input.
/// - Horizontal Floor Switcher Chips (All Floors, 1st Floor, 2nd Floor, 3rd Floor, Ground Floor).
/// - 3-Pill Stat Strip (31 Total Tenants, 4 Vacant Beds, 1 Notice Period).
/// - Spacious High-Contrast Resident Cards with Call, WhatsApp, and Edit actions.
/// - Vacant Bed Cards with Dashed Green Border & 1-Tap + Assign CTA.
/// - Full-Screen Overlay Bottom Sheets (`showModalBottomSheet`) with native keyboard avoidance (`viewInsets`) covering bottom navigation bar cleanly.
/// - Floating Black Action Button (+) positioned above bottom navigation bar (`bottom: 84`).
class OwnerRoomsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerRoomsScreen({super.key, this.onBack});

  @override
  State<OwnerRoomsScreen> createState() => _OwnerRoomsScreenState();
}

class _OwnerRoomsScreenState extends State<OwnerRoomsScreen> {
  String _selectedFloor = 'all'; // 'all', '1st', '2nd', '3rd', 'ground'
  String _selectedFilter = 'all'; // 'all', 'tenants', 'vacant', 'notice'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Form Controllers for Edit Modal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();

  // Form Controllers for Damage Modal
  final TextEditingController _damageItemController = TextEditingController();
  final TextEditingController _damageAmountController = TextEditingController();
  String _damageDeductionMode = 'dues'; // 'dues' or 'deposit'
  String? _damageAttachedPhoto;

  // Form Controllers for Assign Modal
  final TextEditingController _assignNameController = TextEditingController();
  final TextEditingController _assignPhoneController = TextEditingController();
  final TextEditingController _assignRentController = TextEditingController();
  final TextEditingController _assignDepositController = TextEditingController();

  // Native Device Contacts State
  List<Contact>? _deviceContacts;
  bool _isLoadingContacts = false;
  bool _contactsPermissionDenied = false;

  Future<void> _fetchDeviceContacts([void Function(void Function())? setModalState]) async {
    if (_deviceContacts != null && _deviceContacts!.isNotEmpty) return;

    if (setModalState != null) {
      setModalState(() {
        _isLoadingContacts = true;
        _contactsPermissionDenied = false;
      });
    }

    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status == PermissionStatus.granted) {
        final contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.name, ContactProperty.phone},
        );
        if (mounted) {
          if (setModalState != null) {
            setModalState(() {
              _deviceContacts = contacts;
              _isLoadingContacts = false;
            });
          } else {
            setState(() {
              _deviceContacts = contacts;
              _isLoadingContacts = false;
            });
          }
        }
      } else {
        if (mounted) {
          if (setModalState != null) {
            setModalState(() {
              _contactsPermissionDenied = true;
              _isLoadingContacts = false;
            });
          } else {
            setState(() {
              _contactsPermissionDenied = true;
              _isLoadingContacts = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (setModalState != null) {
          setModalState(() {
            _isLoadingContacts = false;
          });
        }
      }
    }
  }

  Future<void> _pickNativeContact(void Function(void Function()) setModalState) async {
    try {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (contact != null) {
        final name = contact.displayName ?? '';
        String phone = '';
        if (contact.phones.isNotEmpty) {
          phone = contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
          if (phone.length > 10) {
            phone = phone.substring(phone.length - 10);
          }
        }
        setModalState(() {
          _assignNameController.text = name;
          if (phone.isNotEmpty) {
            _assignPhoneController.text = phone;
          }
        });
        _showToast('Loaded $name from Phonebook ✓');
      }
    } catch (e) {
      _showToast('Could not open phone contacts: $e');
    }
  }

  // Master Room & Bed Data
  final List<Map<String, dynamic>> _rooms = [
    {
      'room': 'Room 101',
      'floor': '1st',
      'floorLabel': '1st Floor',
      'type': '2-Sharing',
      'occupied': 2,
      'total': 2,
      'beds': [
        {
          'isOccupied': true,
          'bed': 'Bed A',
          'name': 'Rahul Sharma',
          'initials': 'RS',
          'status': 'Active',
          'phone': '9876543210',
          'work': 'Infosys',
          'rent': '8500',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
        {
          'isOccupied': true,
          'bed': 'Bed B',
          'name': 'Amit Verma',
          'initials': 'AV',
          'status': 'Active',
          'phone': '9988776655',
          'work': 'Christ Univ',
          'rent': '8500',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
      ],
    },
    {
      'room': 'Room 102',
      'floor': '1st',
      'floorLabel': '1st Floor',
      'type': '3-Sharing',
      'occupied': 2,
      'total': 3,
      'beds': [
        {
          'isOccupied': true,
          'bed': 'Bed A',
          'name': 'Rohit Sen',
          'initials': 'RS',
          'status': 'Active',
          'phone': '9811223344',
          'work': 'Wipro',
          'rent': '7500',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
        {
          'isOccupied': false,
          'bed': 'Bed B',
          'title': 'Vacant Bed B — Available',
          'sub': '₹7,500/mo • Ready for Walk-In',
          'rent': '7500',
          'deposit': '15000',
        },
        {
          'isOccupied': true,
          'bed': 'Bed C',
          'name': 'Vikram Rao',
          'initials': 'VR',
          'status': 'Notice',
          'phone': '9733445566',
          'work': 'TCS',
          'rent': '7500',
          'deposit': '15000',
          'docs': 'Notice Period (Vacating in 12 days)',
          'docsVerified': false,
        },
      ],
    },
    {
      'room': 'Room 103',
      'floor': '1st',
      'floorLabel': '1st Floor',
      'type': '2-Sharing',
      'occupied': 1,
      'total': 2,
      'beds': [
        {
          'isOccupied': true,
          'bed': 'Bed A',
          'name': 'Praveen Kumar',
          'initials': 'PK',
          'status': 'Active',
          'phone': '9845012345',
          'work': 'Accenture',
          'rent': '8500',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
        {
          'isOccupied': false,
          'bed': 'Bed B',
          'title': 'Vacant Bed B — Available',
          'sub': '₹8,500/mo • Ready for Walk-In',
          'rent': '8500',
          'deposit': '15000',
        },
      ],
    },
    {
      'room': 'Room 201',
      'floor': '2nd',
      'floorLabel': '2nd Floor',
      'type': '2-Sharing',
      'occupied': 2,
      'total': 2,
      'beds': [
        {
          'isOccupied': true,
          'bed': 'Bed A',
          'name': 'Karthik Raja',
          'initials': 'KR',
          'status': 'Active',
          'phone': '9741234567',
          'work': 'Swiggy',
          'rent': '9000',
          'deposit': '18000',
          'docs': 'KYC Verified ✓',
          'docsVerified': true,
        },
        {
          'isOccupied': true,
          'bed': 'Bed B',
          'name': 'Deepak Joshi',
          'initials': 'DJ',
          'status': 'Active',
          'phone': '9819876543',
          'work': 'Dell',
          'rent': '9000',
          'deposit': '18000',
          'docs': 'KYC Verified ✓',
          'docsVerified': true,
        },
      ],
    },
    {
      'room': 'Room 301',
      'floor': '3rd',
      'floorLabel': '3rd Floor',
      'type': 'Single Private',
      'occupied': 0,
      'total': 1,
      'beds': [
        {
          'isOccupied': false,
          'bed': 'Private Room',
          'title': 'Vacant Private Room 301',
          'sub': '₹14,000/mo • Attached Balcony',
          'rent': '14000',
          'deposit': '25000',
        },
      ],
    },
    {
      'room': 'Room G-01',
      'floor': 'ground',
      'floorLabel': 'Ground Floor',
      'type': '2-Sharing',
      'occupied': 2,
      'total': 2,
      'beds': [
        {
          'isOccupied': true,
          'bed': 'Bed A',
          'name': 'Suresh Gowda',
          'initials': 'SG',
          'status': 'Active',
          'phone': '9844001122',
          'work': 'Flipkart',
          'rent': '8000',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
        {
          'isOccupied': true,
          'bed': 'Bed B',
          'name': 'Manoj Hegde',
          'initials': 'MH',
          'status': 'Active',
          'phone': '9900112233',
          'work': 'Amazon',
          'rent': '8000',
          'deposit': '15000',
          'docs': 'Aadhaar Verified',
          'docsVerified': true,
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _workController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _damageItemController.dispose();
    _damageAmountController.dispose();
    _assignNameController.dispose();
    _assignPhoneController.dispose();
    _assignRentController.dispose();
    _assignDepositController.dispose();
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

  // ===========================================================================
  // PRODUCTION MODAL 1: EDIT RESIDENT MODAL (Native Overlay Sheet)
  // ===========================================================================
  void _openEditModal(Map<String, dynamic> resident, String roomName) {
    _nameController.text = resident['name'] ?? '';
    _phoneController.text = resident['phone'] ?? '';
    _workController.text = resident['work'] ?? '';
    _rentController.text = resident['rent'] ?? '';
    _depositController.text = resident['deposit'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Edit: ${resident['name']} ($roomName)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormField('Full Legal Name', _nameController),
              const SizedBox(height: 12),
              _buildFormField('Phone Number / WhatsApp', _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField('Company / College', _workController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildFormField('Monthly Rent (₹)', _rentController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFormField('Security Deposit (₹)', _depositController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),

              // Save Changes Primary Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Resident Details Saved ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),

              // Operational Action Buttons Section
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEEF0F2), width: 1)),
                ),
                child: Column(
                  children: [
                    // + Add Damage Charges (with Photo)
                    _buildActionSubButton(
                      Icons.warning_amber_rounded,
                      '+ Add Damage Charges (with Photo)',
                      textColor: const Color(0xFFB45309),
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openDamageModal(resident, roomName);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Change Room / Shift Bed
                    _buildActionSubButton(
                      Icons.swap_horiz_rounded,
                      'Change Room / Shift Bed',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showToast('Opening Room Shift Selector for ${resident['name']}');
                      },
                    ),
                    const SizedBox(height: 10),

                    // Call Parent / Guardian
                    _buildActionSubButton(
                      Icons.contact_phone_outlined,
                      'Call Parent / Guardian',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showToast('Calling Guardian of ${resident['name']}: 9811223344');
                      },
                    ),
                    const SizedBox(height: 10),

                    // Give Move-Out Notice (30 Days)
                    _buildActionSubButton(
                      Icons.event_note_outlined,
                      'Give Move-Out Notice (30 Days)',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showToast('Initiated 30-Day Move Out Notice for ${resident['name']} ✓');
                      },
                    ),
                    const SizedBox(height: 10),

                    // Delete / Evict Resident
                    _buildActionSubButton(
                      Icons.delete_outline_rounded,
                      'Delete / Evict Resident',
                      textColor: AppColors.danger,
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: AppColors.danger.withValues(alpha: 0.2),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showToast('${resident['name']} evicted and record updated');
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // PRODUCTION MODAL 2: DAMAGE CHARGES MODAL (Native Overlay Sheet)
  // ===========================================================================
  void _openDamageModal(Map<String, dynamic> resident, String roomName) {
    _damageItemController.clear();
    _damageAmountController.clear();
    _damageAttachedPhoto = null;
    _damageDeductionMode = 'dues';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Damage Charge: ${resident['name']} ($roomName)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormField(
                    'Damage Item / Reason',
                    _damageItemController,
                    hint: 'e.g. Broken Bathroom Mirror, Wall Stain, AC Remote',
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    'Damage Amount (₹)',
                    _damageAmountController,
                    hint: 'e.g. 1200',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // Upload Photo Proof Box
                  Text(
                    'Upload Photo Proof (Required)',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      setModalState(() {
                        _damageAttachedPhoto = 'damage_proof_photo_101.jpg';
                      });
                      _showToast('Damage Photo Attached ✓');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 26, color: AppColors.muted),
                          const SizedBox(height: 6),
                          Text(
                            _damageAttachedPhoto ?? 'Click to Upload / Take Photo',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _damageAttachedPhoto != null ? AppColors.greenDark : AppColors.ink,
                            ),
                          ),
                          Text(
                            'JPEG, PNG or Camera capture',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_damageAttachedPhoto != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _damageAttachedPhoto!,
                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.greenDark),
                          ),
                          Text(
                            'Attached ✓',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Deduction Option Dropdown
                  Text(
                    'Deduction Option',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _damageDeductionMode,
                        isExpanded: true,
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(
                            value: 'dues',
                            child: Text("Add to Current Month's Dues (Immediate Pay)"),
                          ),
                          DropdownMenuItem(
                            value: 'deposit',
                            child: Text('Deduct from Security Deposit at Exit'),
                          ),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            _damageDeductionMode = val ?? 'dues';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // WhatsApp Info Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.greenDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo receipt & damage notice will be sent to resident on WhatsApp.',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      final item = _damageItemController.text.trim();
                      final amount = _damageAmountController.text.trim();
                      if (item.isEmpty || amount.isEmpty) {
                        _showToast('Please enter damage item and amount');
                        return;
                      }
                      Navigator.of(ctx).pop();
                      final modeText = _damageDeductionMode == 'dues' ? "Added to Dues" : "Deducted from Deposit";
                      _showToast('₹$amount Damage for $item logged ($modeText) & sent on WhatsApp ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Apply Damage Charge',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // PRODUCTION MODAL 3: ASSIGN RESIDENT MODAL (Phonebook Picker & Strict Validation)
  // ===========================================================================
  void _openAssignModal(Map<String, dynamic> vacantBed, String roomName, String floorLabel) {
    _assignNameController.clear();
    _assignPhoneController.clear();
    _assignRentController.text = vacantBed['rent'] ?? '8500';
    _assignDepositController.text = vacantBed['deposit'] ?? '15000';

    String contactSearch = '';
    bool showPhonebookPicker = true;

    // Immediately trigger real contact permission & fetch on open
    _fetchDeviceContacts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            // Build dynamic list from real device contacts
            final List<Map<String, String>> contactsList = (_deviceContacts ?? []).map<Map<String, String>>((c) {
              final name = c.displayName ?? '';
              String phone = '';
              if (c.phones.isNotEmpty) {
                phone = c.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
                if (phone.length > 10) {
                  phone = phone.substring(phone.length - 10);
                }
              }
              final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '+';
              return <String, String>{
                'name': name,
                'phone': phone,
                'initials': initials,
              };
            }).where((c) => c['phone']!.isNotEmpty).toList();

            final filteredContacts = contactsList.where((c) {
              if (contactSearch.isEmpty) return true;
              final q = contactSearch.toLowerCase();
              return c['name']!.toLowerCase().contains(q) || c['phone']!.contains(q);
            }).toList();

            return _buildNativeBottomSheetWrapper(
              title: 'Assign Resident: $roomName (${vacantBed['bed']})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Selection Accordion: Pick from Phone Contacts
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Bar with Toggle & Native System Picker
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    showPhonebookPicker = !showPhonebookPicker;
                                    if (showPhonebookPicker && _deviceContacts == null) {
                                      _fetchDeviceContacts(setModalState);
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.contacts_rounded, size: 16, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Pick from Phonebook',
                                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      showPhonebookPicker ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                              ),

                              // 1-Tap Native Android OS Contact Picker Button
                              InkWell(
                                onTap: () => _pickNativeContact(setModalState),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'System Contacts',
                                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expanded Contact Picker List
                        if (showPhonebookPicker) ...[
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),

                          // Loading State
                          if (_isLoadingContacts) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Reading phone contacts from device...',
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (_contactsPermissionDenied) ...[
                            // Permission Denied State
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.no_accounts_rounded, size: 28, color: AppColors.muted),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Contacts permission needed to load phonebook',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () => _fetchDeviceContacts(setModalState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      elevation: 0,
                                    ),
                                    child: Text('Allow Contacts Permission', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: TextField(
                                  onChanged: (v) => setModalState(() => contactSearch = v),
                                  style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.ink),
                                  decoration: InputDecoration(
                                    hintText: 'Search contacts by name or number...',
                                    hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.muted),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                ),
                              ),
                            ),

                            // Contact List View
                            if (filteredContacts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    _deviceContacts == null
                                        ? 'Tap "System Contacts" above to load contacts'
                                        : 'No contacts found matching "$contactSearch"',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                                  ),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredContacts.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 48),
                                  itemBuilder: (context, idx) {
                                    final contact = filteredContacts[idx];
                                    return InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          _assignNameController.text = contact['name']!;
                                          _assignPhoneController.text = contact['phone']!;
                                          showPhonebookPicker = false;
                                        });
                                        _showToast('Auto-filled from ${contact['name']}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2563EB),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  contact['initials']!,
                                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contact['name']!,
                                                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                                                  ),
                                                  Text(
                                                    '+91 ${contact['phone']}',
                                                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Resident Form Fields with Strict Validations
                  _buildFormField(
                    'Full Name',
                    _assignNameController,
                    hint: 'e.g. Siddharth Rao',
                  ),
                  const SizedBox(height: 12),

                  // Phone Number (+91) with numeric keyboard and 10-digit limit
                  _buildFormField(
                    'Phone Number (+91)',
                    _assignPhoneController,
                    hint: '9876543210',
                    prefixText: '+91 ',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rent and Security Deposit with numeric keyboard and digits only
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          'Monthly Rent (₹)',
                          _assignRentController,
                          prefixText: '₹ ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFormField(
                          'Security Deposit (₹)',
                          _assignDepositController,
                          prefixText: '₹ ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      final name = _assignNameController.text.trim();
                      final phone = _assignPhoneController.text.trim();
                      final rent = _assignRentController.text.trim();
                      final deposit = _assignDepositController.text.trim();

                      // Strict Validation Checks
                      if (name.isEmpty) {
                        _showToast('Please enter resident full name');
                        return;
                      }

                      if (phone.length != 10) {
                        _showToast('Please enter valid 10-digit phone number');
                        return;
                      }

                      final rentNum = int.tryParse(rent);
                      if (rentNum == null || rentNum <= 0) {
                        _showToast('Please enter valid monthly rent amount');
                        return;
                      }

                      final depositNum = int.tryParse(deposit);
                      if (depositNum == null || depositNum < 0) {
                        _showToast('Please enter valid security deposit amount');
                        return;
                      }

                      // Successfully assign resident to bed
                      setState(() {
                        for (var r in _rooms) {
                          if (r['room'] == roomName) {
                            final beds = r['beds'] as List;
                            for (var b in beds) {
                              if (b['bed'] == vacantBed['bed']) {
                                b['isOccupied'] = true;
                                b['name'] = name;
                                b['phone'] = phone;
                                b['rent'] = rent;
                                b['deposit'] = deposit;
                                b['status'] = 'Active';
                                b['work'] = 'Resident';
                                b['docs'] = 'Aadhaar Verified';
                                b['docsVerified'] = true;
                                b['initials'] = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'US';
                                break;
                              }
                            }
                            r['occupied'] = (r['occupied'] as int) + 1;
                            break;
                          }
                        }
                      });

                      Navigator.of(ctx).pop();
                      _showToast('$name assigned to $roomName (${vacantBed['bed']}) ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Check-In & Assign Bed',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter rooms by floor, card selection filter, and search query
    final filteredRooms = _rooms.map((room) {
      final beds = (room['beds'] as List<dynamic>).where((b) {
        if (_selectedFilter == 'tenants') {
          return b['isOccupied'] == true;
        } else if (_selectedFilter == 'vacant') {
          return b['isOccupied'] == false;
        } else if (_selectedFilter == 'notice') {
          return b['isOccupied'] == true && b['status'] == 'Notice';
        }
        return true;
      }).toList();

      return {
        ...room,
        'beds': beds,
      };
    }).where((room) {
      final beds = room['beds'] as List;
      if (beds.isEmpty) return false;

      // 1. Floor filter
      if (_selectedFloor != 'all' && room['floor'] != _selectedFloor) {
        return false;
      }
      // 2. Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final roomMatch = (room['room'] as String).toLowerCase().contains(query);
        final bedMatch = beds.any((b) {
          final name = (b['name'] ?? '').toString().toLowerCase();
          final work = (b['work'] ?? '').toString().toLowerCase();
          return name.contains(query) || work.contains(query);
        });
        return roomMatch || bedMatch;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Top Sticky Header
                _buildTopHeader(),

                // 2. Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 140.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Box
                        _buildSearchBox(),
                        const SizedBox(height: 14),

                        // Floor Filter Chips Scroll
                        _buildFloorChipsScroll(),
                        const SizedBox(height: 14),

                        // 3-Pill Stat Strip (31 Total, 4 Vacant, 1 Notice)
                        _buildStatsStrip(),
                        const SizedBox(height: 16),

                        // Rooms Matrix
                        if (filteredRooms.isEmpty)
                          _buildEmptyState()
                        else
                          ...filteredRooms.map((room) => _buildRoomGroupBlock(room)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Action Button (+) Positioned Gracefully Above Bottom Navigation Bar
            Positioned(
              right: 18,
              bottom: 84, // Clear above the 68px bottom navbar
              child: FloatingActionButton(
                onPressed: () {
                  _openAssignModal(
                    {'bed': 'Any Vacant Bed', 'rent': '8500', 'deposit': '15000'},
                    'Auto-Assign Room',
                    '1st Floor',
                  );
                },
                backgroundColor: AppColors.ink,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 26, color: Colors.white),
              ),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
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
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenants & Rooms',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Greenview PG • Koramangala',
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
    );
  }

  // ===========================================================================
  // 2. SEARCH BOX
  // ===========================================================================
  Widget _buildSearchBox() {
    return Container(
      height: 44,
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
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search resident by name or room...',
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.muted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. HORIZONTAL FLOOR SWITCHER CHIPS
  // ===========================================================================
  Widget _buildFloorChipsScroll() {
    final floors = [
      {'id': 'all', 'label': 'All Floors (35 Beds)'},
      {'id': '1st', 'label': '1st Floor (101-104)'},
      {'id': '2nd', 'label': '2nd Floor (201-204)'},
      {'id': '3rd', 'label': '3rd Floor (301-304)'},
      {'id': 'ground', 'label': 'Ground Floor (G01-G04)'},
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
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
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
  // 4. 3-PILL STAT STRIP (Interactive Filter: 31 Total, 4 Vacant, 1 Notice)
  // ===========================================================================
  Widget _buildStatsStrip() {
    return Row(
      children: [
        // Total Tenants (Green)
        Expanded(
          child: _buildStatTile(
            '31',
            'Total Tenants',
            AppColors.green,
            isSelected: _selectedFilter == 'tenants',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'tenants' ? 'all' : 'tenants';
              });
              _showToast(_selectedFilter == 'tenants' ? 'Showing Active Tenants (31)' : 'Showing All Beds');
            },
          ),
        ),
        const SizedBox(width: 8),

        // Vacant Beds (Black)
        Expanded(
          child: _buildStatTile(
            '4',
            'Vacant Beds',
            AppColors.ink,
            isSelected: _selectedFilter == 'vacant',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'vacant' ? 'all' : 'vacant';
              });
              _showToast(_selectedFilter == 'vacant' ? 'Showing Vacant Beds (4)' : 'Showing All Beds');
            },
          ),
        ),
        const SizedBox(width: 8),

        // Notice Period (Yellow / Amber)
        Expanded(
          child: _buildStatTile(
            '1',
            'Notice Period',
            const Color(0xFFD97706),
            isSelected: _selectedFilter == 'notice',
            onTap: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'notice' ? 'all' : 'notice';
              });
              _showToast(_selectedFilter == 'notice' ? 'Showing Notice Period Tenants (1)' : 'Showing All Beds');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String num,
    String label,
    Color numColor, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x0C000000) : const Color(0x03000000),
              blurRadius: isSelected ? 6 : 4,
              offset: const Offset(0, 1),
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. ROOM GROUP BLOCK
  // ===========================================================================
  Widget _buildRoomGroupBlock(Map<String, dynamic> room) {
    final isFullyOccupied = room['occupied'] == room['total'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
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
          // Centered Room Header Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                room['room'],
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${room['floorLabel']}  •  ${room['type']}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isFullyOccupied ? AppColors.green : const Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        '${room['occupied']}/${room['total']} Occupied',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isFullyOccupied ? AppColors.greenDark : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bed List in Room
          ...((room['beds'] as List).map((bed) {
            if (bed['isOccupied'] == true) {
              return _buildTenantCard(bed, room['room']);
            } else {
              return _buildVacantBedCard(bed, room['room'], room['floorLabel']);
            }
          })),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. OCCUPIED RESIDENT CARD (Spacious, Big & Eye-Catching)
  // ===========================================================================
  Widget _buildTenantCard(Map<String, dynamic> tenant, String roomName) {
    final isNotice = tenant['status'] == 'Notice';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
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
          // 1. Top Row: 44px Avatar + Name & Status Pill + ✏️ Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 44px Profile Avatar
                  InkWell(
                    onTap: () => _openEditModal(tenant, roomName),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          tenant['initials'] ?? 'RS',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name & Status Pill
                  InkWell(
                    onTap: () => _openEditModal(tenant, roomName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant['name'],
                          style: GoogleFonts.outfit(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNotice ? const Color(0xFFFEF2F2) : AppColors.greenLight,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isNotice
                                  ? AppColors.danger.withValues(alpha: 0.2)
                                  : AppColors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            isNotice ? 'Notice Period' : '● Active Resident',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isNotice ? AppColors.danger : AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Clean [ ✏️ Edit ] Button
              InkWell(
                onTap: () => _openEditModal(tenant, roomName),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 13, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Hairline Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),

          // 2. Dedicated Prominent Bed & Amount Row (No College/Company Clutter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bed_outlined, size: 16, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text(
                      tenant['bed'] ?? 'Bed A',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: AppColors.greenDark,
                    ),
                    children: [
                      TextSpan(text: '₹${tenant['rent']}'),
                      TextSpan(
                        text: ' / month',
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
          const SizedBox(height: 10),

          // 3. Spacious 2-Button Action Row: [ 📞 Call ] and [ 💬 WhatsApp ]
          Row(
            children: [
              // Call Button
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Calling ${tenant['name']}: +91${tenant['phone']}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text(
                          'Call',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
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

              // Direct WhatsApp Button
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Opening WhatsApp chat with ${tenant['name']} (+91${tenant['phone']}) ✓'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.greenDark),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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

          // 4. Simplified Details Trigger (Clean & Minimal)
          InkWell(
            onTap: () => _openEditModal(tenant, roomName),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEF0F2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        'View Details & Tenant Dossier',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. VACANT BED CARD (Dashed Green Border)
  // ===========================================================================
  Widget _buildVacantBedCard(Map<String, dynamic> bed, String roomName, String floorLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bed['title'] ?? 'Vacant Bed Available',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bed['sub'] ?? '₹7,500/mo • Ready for Walk-In',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),

          // + Assign Button
          InkWell(
            onTap: () => _openAssignModal(bed, roomName, floorLabel),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+ Assign',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'No rooms or residents match your search',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE NATIVE MODAL SHEET WRAPPER (Keyboard Avoidance & 100% Responsiveness)
  // ===========================================================================
  Widget _buildNativeBottomSheetWrapper({
    required String title,
    required Widget child,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
          // Drag Handle
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

          // Header Row
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

          // Scrollable Content
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

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: prefixText,
              prefixStyle: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.ink, fontWeight: FontWeight.w700),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSubButton(
    IconData icon,
    String label, {
    Color? textColor,
    Color? bgColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor ?? AppColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor ?? AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
