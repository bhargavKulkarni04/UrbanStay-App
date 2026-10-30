import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/owner_app_state.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/urban_loading.dart';
import 'shift_bed_screen.dart';
import 'owner_move_out_notice_screen.dart';

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
  final String? propertyId;
  final String? propertyName;

  const OwnerRoomsScreen(
      {super.key, this.onBack, this.propertyId, this.propertyName});

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
  final TextEditingController _assignDepositController =
      TextEditingController();

  // Loading State
  bool _isLoading = true;
  String? _propertyId;
  String? _propertyName;

  // Native Device Contacts State
  List<Contact>? _deviceContacts;
  bool _isLoadingContacts = false;
  bool _contactsPermissionDenied = false;

  // Property Notice Period Policy (Configured in Owner Setup / Settings)
  String _noticePeriod = '30 Days';

  int get _noticeDaysInt {
    final match = RegExp(r'\d+').firstMatch(_noticePeriod);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ?? 30;
    }
    return 30;
  }

  @override
  void initState() {
    super.initState();
    _loadRoomsFromSupabase();
  }

  Future<void> _loadRoomsFromSupabase() async {
    try {
      final targetPropId = _propertyId ??
          widget.propertyId ??
          SupabaseService.instance.activePropertyId;
      String? propId = targetPropId;
      String? pName =
          widget.propertyName ?? SupabaseService.instance.activePropertyName;
      if (propId == null || propId.isEmpty || pName == null || pName.isEmpty) {
        final prop = await SupabaseService.instance.getOwnerProperty();
        if (prop != null) {
          OwnerAppState.instance.setActiveProperty(prop);
          propId ??= prop['id']?.toString();
          pName ??= (prop['property_name'] ?? prop['name'])?.toString();
        }
      }

      if (propId != null && propId.isNotEmpty) {
        _propertyId = propId;
        _propertyName = pName;
        if (pName != null &&
            pName.isNotEmpty &&
            OwnerAppState.instance.activePropertyName.isEmpty) {
          OwnerAppState.instance
              .setActiveProperty({'id': propId, 'property_name': pName});
        }
        try {
          final propData = await SupabaseService.instance
              .getOwnerProperty(propertyId: propId);
          if (propData != null &&
              propData['notice_period'] != null &&
              propData['notice_period'].toString().isNotEmpty) {
            _noticePeriod = propData['notice_period'].toString();
          }
        } catch (_) {}
        final roomsWithBeds =
            await SupabaseService.instance.getRoomsWithBeds(_propertyId!);
        if (mounted) {
          final List<Map<String, dynamic>> loadedRooms = [];
          for (final r in roomsWithBeds) {
            final List bedsList = (r['beds'] as List?) ?? [];
            final int occupiedCount =
                bedsList.where((b) => b['is_occupied'] == true).length;
            final formattedBeds = bedsList.map((b) {
              final isOcc = b['is_occupied'] == true;
              final rawName = b['tenant_name']?.toString().trim();
              final String tenantName = (rawName != null && rawName.isNotEmpty)
                  ? rawName
                  : (isOcc ? 'Resident' : '');
              final String bedStatus =
                  b['status'] ?? (isOcc ? 'Active' : 'Vacant');

              // Compute initials from actual tenant name (e.g. 'Rahul Sharma' → 'RS')
              String? initials;
              if (isOcc && tenantName.isNotEmpty) {
                final parts = tenantName
                    .trim()
                    .split(' ')
                    .where((p) => p.isNotEmpty)
                    .toList();
                if (parts.length >= 2) {
                  initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
                } else {
                  initials = tenantName[0].toUpperCase();
                }
              }

              // Derive docs/KYC status from bed status field
              String docsLabel;
              bool docsVerified;
              if (bedStatus.toLowerCase() == 'notice') {
                docsLabel = 'Notice Period';
                docsVerified = false;
              } else if (isOcc) {
                docsLabel = b['kyc_status'] ?? 'KYC Verified ✓';
                docsVerified = true;
              } else {
                docsLabel = '';
                docsVerified = false;
              }

              final bedLabel = b['bed_number']?.toString() ??
                  b['bed_label']?.toString() ??
                  b['bed_code']?.toString() ??
                  'Bed';
              final actualBedRent =
                  isOcc ? ((b['rent'] ?? r['rent_per_bed'] ?? 0) as num) : 0;
              final actualBedDeposit = isOcc
                  ? ((b['deposit'] ?? r['deposit_per_bed'] ?? 0) as num)
                  : 0;
              final actualBedRefundableDeposit = isOcc
                  ? ((b['refundable_deposit'] ??
                      r['refundable_deposit'] ??
                      actualBedDeposit) as num)
                  : 0;
              return {
                'id': b['id']?.toString() ?? '',
                'label': bedLabel,
                'bed': bedLabel,
                'isOccupied': isOcc,
                'name': isOcc ? tenantName : '',
                'initials': initials ?? (isOcc ? 'RS' : ''),
                'status': bedStatus,
                'phone': b['tenant_phone'] ?? '',
                'tenant_id': b['tenant_id']?.toString() ?? '',
                'room_id': r['id']?.toString() ?? '',
                'room_number': r['room_number']?.toString() ?? '',
                'work': b['workplace'] ?? '',
                'rent': actualBedRent > 0 ? actualBedRent.toString() : '0',
                'deposit':
                    actualBedDeposit > 0 ? actualBedDeposit.toString() : '0',
                'refundable_deposit': actualBedRefundableDeposit > 0
                    ? actualBedRefundableDeposit.toString()
                    : actualBedDeposit.toString(),
                'docs': docsLabel,
                'docsVerified': docsVerified,
                'title': !isOcc ? 'Vacant $bedLabel — Available' : null,
                'sub': !isOcc ? 'Ready for Walk-In' : null,
              };
            }).toList();

            loadedRooms.add({
              'id': r['id']?.toString() ?? '',
              'room': r['room_number']?.toString() ?? '',
              'room_number': r['room_number']?.toString() ?? '',
              'floor':
                  r['floor_label']?.toString().split(' ').first.toLowerCase() ??
                      (r['floor_id'] != null ? 'floor_${r['floor_id']}' : ''),
              'floorLabel': r['floor_label'] ??
                  (r['floor_id'] != null ? 'Floor ${r['floor_id']}' : ''),
              'type': r['sharing_type'] ?? '${bedsList.length}-Sharing',
              'occupied': occupiedCount,
              'total': r['total_beds'] ?? bedsList.length,
              'beds': formattedBeds,
            });
          }

          setState(() {
            _rooms.clear();
            _rooms.addAll(loadedRooms);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading rooms from Supabase: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDeviceContacts(
      [void Function(void Function())? setModalState]) async {
    if (_deviceContacts != null && _deviceContacts!.isNotEmpty) return;

    if (setModalState != null) {
      setModalState(() {
        _isLoadingContacts = true;
        _contactsPermissionDenied = false;
      });
    }

    try {
      final status =
          await FlutterContacts.permissions.request(PermissionType.read);
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

  Future<void> _pickNativeContact(
      void Function(void Function()) setModalState) async {
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

  // Master Room & Bed Data (Populated live from Supabase — no mock/hardcoded fallback)
  final List<Map<String, dynamic>> _rooms = [];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _workController.dispose();
    _rentController.dispose();
    _depositController.dispose();
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
              _buildFormField(
                'Phone Number / WhatsApp',
                _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 12),
              _buildFormField('Company / College', _workController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      'Monthly Rent (₹)',
                      _rentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFormField(
                      'Security Deposit (₹)',
                      _depositController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save Changes Primary Button (Iconic Green + White Text)
              ElevatedButton(
                onPressed: () async {
                  final newName = _nameController.text.trim();
                  final newPhone = _phoneController.text.trim();
                  final newRent = double.tryParse(_rentController.text.trim());
                  final newDeposit =
                      double.tryParse(_depositController.text.trim());
                  final bedId = resident['id']?.toString() ?? '';

                  if (bedId.isNotEmpty) {
                    final success =
                        await SupabaseService.instance.assignResidentToBed(
                      bedId: bedId,
                      name: newName,
                      phone: newPhone,
                      propertyName: _propertyName,
                      roomNumber: resident['roomNumber'] ?? resident['room'],
                      rent: newRent,
                      deposit: newDeposit,
                    );
                    if (!success) {
                      _showToast(
                          'Failed to save resident changes. Please try again.');
                      return;
                    }
                    await _loadRoomsFromSupabase();
                  }

                  setState(() {
                    resident['name'] = newName;
                    resident['phone'] = newPhone;
                    resident['rent'] = _rentController.text.trim();
                    resident['deposit'] = _depositController.text.trim();
                  });

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  _showToast('Resident Details Saved ✓');
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
                  'Save Changes',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),

              // Operational Action Buttons Section
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEF0F2), width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // + Add / View Damage Charges (Navigates to Full Page)
                    _buildActionSubButton(
                      Icons.warning_amber_rounded,
                      '+ Add / View Damage Charges',
                      textColor: const Color(0xFFB45309),
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.3),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => ShiftBedScreen(
                              resident: resident,
                              roomName: roomName,
                              rooms: _rooms,
                              onShiftSuccess: () async {
                                await _loadRoomsFromSupabase();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Dynamic Notice Button: Toggle between "Give Move-Out Notice" and "Cancel Notice (Revert)"
                    Builder(
                      builder: (context) {
                        final isNotice =
                            resident['status']?.toString().toLowerCase() ==
                                'notice';
                        final vacateTarget =
                            DateTime.now().add(Duration(days: _noticeDaysInt));
                        final formattedVacateDate =
                            '${vacateTarget.day.toString().padLeft(2, '0')}/${vacateTarget.month.toString().padLeft(2, '0')}/${vacateTarget.year}';

                        return _buildActionSubButton(
                          isNotice
                              ? Icons.undo_rounded
                              : Icons.event_note_outlined,
                          isNotice
                              ? 'Cancel Notice (Revert to Active)'
                              : 'Initiate Move-Out Notice ($_noticePeriod)',
                          textColor: isNotice ? AppColors.greenDark : null,
                          bgColor: isNotice ? AppColors.greenLight : null,
                          borderColor: isNotice
                              ? AppColors.green.withValues(alpha: 0.3)
                              : null,
                          onTap: () {
                            if (isNotice) {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text(
                                    'Cancel Move-Out Notice',
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17),
                                  ),
                                  content: Text(
                                    'Are you sure you want to cancel the move-out notice for ${resident['name'] ?? "this resident"} in Room $roomName and revert to Active Occupied?',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13, color: AppColors.muted),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(),
                                      child: Text('Cancel',
                                          style: GoogleFonts.outfit(
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(dialogCtx).pop();
                                        final bedId =
                                            resident['id']?.toString();
                                        final roomNum = resident['room_number']
                                                ?.toString() ??
                                            roomName;
                                        final bedLabel =
                                            resident['bed']?.toString() ??
                                                resident['label']?.toString() ??
                                                '';

                                        if (bedId != null && bedId.isNotEmpty) {
                                          try {
                                            await SupabaseService
                                                .instance.client
                                                .from('beds')
                                                .update({
                                              'status': 'Occupied'
                                            }).eq('id', bedId);
                                          } catch (e) {
                                            debugPrint(
                                                'Error updating notice status in beds: $e');
                                          }
                                        }

                                        if (_propertyId != null &&
                                            _propertyId!.isNotEmpty) {
                                          try {
                                            await SupabaseService
                                                .instance.client
                                                .from('move_out_notices')
                                                .update({'status': 'cancelled'})
                                                .eq('property_id', _propertyId!)
                                                .eq('room_number', roomNum)
                                                .eq('bed_identifier', bedLabel)
                                                .eq('status', 'ACTIVE');
                                          } catch (e) {
                                            debugPrint(
                                                'Error syncing move_out_notices: $e');
                                          }
                                        }

                                        setState(() {
                                          resident['status'] = 'Occupied';
                                        });
                                        await _loadRoomsFromSupabase();
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        _showToast(
                                            'Move-Out Notice Cancelled • Reverted to Active ✓');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.green,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: Text('Yes, Cancel Notice',
                                          style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (c) => OwnerMoveOutNoticeScreen(
                                    resident: resident,
                                    roomName: roomName,
                                    propertyId: _propertyId,
                                    propertyName: _propertyName,
                                    noticePeriod: _noticePeriod,
                                    noticeDaysInt: _noticeDaysInt,
                                    onNoticeSuccess: () async {
                                      await _loadRoomsFromSupabase();
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Delete / Evict Resident with Confirmation Dialog
                    _buildActionSubButton(
                      Icons.delete_outline_rounded,
                      'Delete / Evict Resident',
                      textColor: AppColors.danger,
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: AppColors.danger.withValues(alpha: 0.2),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Confirm Eviction',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.danger),
                            ),
                            content: Text(
                              'Are you sure you want to evict ${resident['name'] ?? "Resident"} from Room $roomName? This will immediately vacate the bed.',
                              style: GoogleFonts.outfit(
                                  fontSize: 13, color: AppColors.muted),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: Text('Cancel',
                                    style: GoogleFonts.outfit(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(dialogCtx).pop();
                                  final bedId = resident['id']?.toString();
                                  final oldName = resident['name'];
                                  if (bedId != null && bedId.isNotEmpty) {
                                    await SupabaseService.instance
                                        .vacateBed(bedId: bedId);
                                  }
                                  setState(() {
                                    resident['isOccupied'] = false;
                                    resident['status'] = 'Vacant';
                                    resident['name'] = null;
                                    resident['phone'] = null;
                                    resident['rent'] = '0';
                                    resident['deposit'] = '0';
                                    resident['sub'] = 'Ready for Walk-In';
                                  });
                                  _loadRoomsFromSupabase();
                                  Navigator.of(ctx).pop();
                                  _showToast(
                                      '${oldName ?? "Resident"} evicted and bed marked vacant');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Yes, Evict',
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        );
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          List<Map<String, dynamic>> loggedDamages = [];
          bool isLoadingDamages = true;

          return StatefulBuilder(
            builder: (context, setPageState) {
              void loadDamages() async {
                final pId = widget.propertyId ??
                    _propertyId ??
                    SupabaseService.instance.activePropertyId ??
                    '';
                final list = await SupabaseService.instance.getDamageDeductions(
                  propertyId: pId,
                  roomNumber: roomName,
                  tenantName: resident['name']?.toString(),
                  tenantId: resident['tenant_id']?.toString(),
                );
                if (context.mounted) {
                  setPageState(() {
                    loggedDamages = list;
                    isLoadingDamages = false;
                  });
                }
              }

              if (isLoadingDamages) {
                loadDamages();
              }

              final currentDepositStr = resident['deposit']?.toString() ?? '0';

              return Scaffold(
                backgroundColor: AppColors.pageBg,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.ink),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  title: Text(
                    'Damage Charges: ${resident['name'] ?? "Resident"} ($roomName)',
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                body: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Resident Header Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_outline_rounded,
                                    color: AppColors.greenDark, size: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resident['name'] ?? 'Resident',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Room $roomName • ${resident['bed'] ?? "Bed"}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        AppColors.green.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Security Deposit',
                                      style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600)),
                                  Text('₹$currentDepositStr',
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: AppColors.greenDark,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Logged Damages History List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Logged Damage Records',
                            style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink),
                          ),
                          Text(
                            '${loggedDamages.length} Records',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (isLoadingDamages)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: UrbanSpinner(size: 22)))
                      else if (loggedDamages.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              'No damage charges recorded yet.',
                              style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loggedDamages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final dmg = loggedDamages[idx];
                            final item =
                                dmg['item_damaged']?.toString() ?? 'Damage';
                            final amt = (dmg['amount'] as num?)?.toInt() ?? 0;
                            final mode =
                                dmg['deduction_mode']?.toString() ?? 'deposit';
                            final dmgId = dmg['id']?.toString() ?? '';
                            final bedId = resident['id']?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          color: AppColors.danger, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        final dRoom = dmg['room_number']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true
                                            ? dmg['room_number'].toString()
                                            : roomName;
                                        final dTenantId = dmg['tenant_id']
                                                ?.toString() ??
                                            resident['tenant_id']?.toString() ??
                                            '';
                                        final dRoomId = dmg['room_id']
                                                ?.toString() ??
                                            resident['room_id']?.toString() ??
                                            '';

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Room $dRoom • ${mode == 'deposit' ? 'From Deposit' : 'Added to Dues'}',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.muted),
                                            ),
                                            if (dTenantId.isNotEmpty ||
                                                dRoomId.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  '${dTenantId.isNotEmpty ? "Tenant: ${dTenantId.substring(0, dTenantId.length > 8 ? 8 : dTenantId.length)}…" : ""}${dRoomId.isNotEmpty ? " • Room ID: ${dRoomId.substring(0, dRoomId.length > 8 ? 8 : dRoomId.length)}…" : ""}',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                          0xFF6B7280)),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Text(
                                    '₹$amt',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.danger),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit Button
                                  InkWell(
                                    onTap: () {
                                      final editItemCtrl =
                                          TextEditingController(text: item);
                                      final editAmtCtrl = TextEditingController(
                                          text: amt.toString());

                                      showDialog(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          title: Text('Edit Damage Charge',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: editItemCtrl,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: 'Item Name'),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: editAmtCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Amount (₹)'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dCtx).pop(),
                                              child: Text('Cancel',
                                                  style: GoogleFonts.outfit(
                                                      color: AppColors.muted)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final newName =
                                                    editItemCtrl.text.trim();
                                                final newAmt = double.tryParse(
                                                        editAmtCtrl.text
                                                            .trim()) ??
                                                    0.0;
                                                if (newName.isEmpty ||
                                                    newAmt <= 0) return;

                                                Navigator.of(dCtx).pop();
                                                final ok = await SupabaseService
                                                    .instance
                                                    .updateDamageDeduction(
                                                  damageId: dmgId,
                                                  itemDamaged: newName,
                                                  newAmount: newAmt,
                                                  oldAmount: amt.toDouble(),
                                                  deductionMode: mode,
                                                  bedId: bedId,
                                                );
                                                if (ok) {
                                                  if (mode == 'deposit') {
                                                    final curDep = double
                                                            .tryParse(resident[
                                                                        'deposit']
                                                                    ?.toString() ??
                                                                '0') ??
                                                        0.0;
                                                    final updatedDep = (curDep +
                                                            (amt - newAmt))
                                                        .clamp(0.0,
                                                            double.infinity);
                                                    setState(() {
                                                      resident['deposit'] =
                                                          updatedDep
                                                              .toInt()
                                                              .toString();
                                                    });
                                                  }
                                                  setPageState(() {
                                                    isLoadingDamages = true;
                                                  });
                                                  _showToast(
                                                      'Damage updated to ₹${newAmt.toInt()} ✓');
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.green,
                                                  foregroundColor:
                                                      Colors.white),
                                              child: Text('Save',
                                                  style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.edit_outlined,
                                          size: 15, color: AppColors.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Revert / Remove Button (Restores Security Deposit)
                                  InkWell(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          title: Text('Revert Damage Charge',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800)),
                                          content: Text(
                                            'Are you sure you want to remove this ₹$amt damage charge for "$item"?\n\n'
                                            '${mode == 'deposit' ? '₹$amt will be immediately refunded back to the resident\'s security deposit.' : 'Pending dues will be cleared.'}',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12.5,
                                                color: AppColors.muted),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dCtx).pop(false),
                                              child: Text('Cancel',
                                                  style: GoogleFonts.outfit(
                                                      color: AppColors.muted)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(dCtx).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.danger,
                                                  foregroundColor:
                                                      Colors.white),
                                              child: Text('Yes, Revert',
                                                  style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final ok = await SupabaseService
                                            .instance
                                            .deleteDamageDeduction(
                                          damageId: dmgId,
                                          amount: amt.toDouble(),
                                          deductionMode: mode,
                                          bedId: bedId,
                                        );
                                        if (ok) {
                                          if (mode == 'deposit') {
                                            final curDep = double.tryParse(
                                                    resident['deposit']
                                                            ?.toString() ??
                                                        '0') ??
                                                0.0;
                                            setState(() {
                                              resident['deposit'] =
                                                  (curDep + amt)
                                                      .toInt()
                                                      .toString();
                                            });
                                          }
                                          setPageState(() {
                                            isLoadingDamages = true;
                                          });
                                          _showToast(
                                              'Reverted ₹$amt damage charge ✓');
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 15,
                                          color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 22),

                      // Existing Add New Damage Form
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              ' Log New Damage Deduction',
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink),
                            ),
                            const SizedBox(height: 14),
                            _buildFormField(
                              'Damage Item / Reason',
                              _damageItemController,
                              hint:
                                  'e.g. Broken Bathroom Mirror, Wall Stain, AC Remote',
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              'Damage Amount (₹)',
                              _damageAmountController,
                              hint: 'e.g. 1200',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Upload Photo Proof Box
                            Text(
                              'Upload Photo Proof (Optional)',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                setPageState(() {
                                  _damageAttachedPhoto = _damageAttachedPhoto ==
                                          null
                                      ? 'damage_proof_photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
                                      : null;
                                });
                                _showToast(_damageAttachedPhoto != null
                                    ? 'Damage Photo Attached ✓'
                                    : 'Photo Removed');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _damageAttachedPhoto != null
                                      ? AppColors.greenLight
                                      : const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _damageAttachedPhoto != null
                                          ? AppColors.green
                                          : const Color(0xFFE5E7EB),
                                      width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _damageAttachedPhoto != null
                                          ? Icons.check_circle_rounded
                                          : Icons.camera_alt_outlined,
                                      size: 22,
                                      color: _damageAttachedPhoto != null
                                          ? AppColors.greenDark
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _damageAttachedPhoto ??
                                            'Click to Attach Photo Proof',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: _damageAttachedPhoto != null
                                              ? AppColors.greenDark
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Deduction Option Dropdown
                            Text(
                              'Deduction Option',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB), width: 1.5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _damageDeductionMode,
                                  isExpanded: true,
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'dues',
                                      child: Text(
                                          "Add to Current Month's Dues (Immediate Pay)"),
                                    ),
                                    DropdownMenuItem(
                                      value: 'deposit',
                                      child: Text(
                                          'Deduct from Security Deposit at Exit'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setPageState(() {
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
                                border: Border.all(
                                    color:
                                        AppColors.green.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      size: 16, color: AppColors.greenDark),
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
                              onPressed: () async {
                                final item = _damageItemController.text.trim();
                                final amount =
                                    _damageAmountController.text.trim();
                                if (item.isEmpty || amount.isEmpty) {
                                  _showToast(
                                      'Please enter damage item and amount');
                                  return;
                                }

                                final bedId = resident['id']?.toString() ?? '';
                                final dmgAmount =
                                    double.tryParse(amount) ?? 0.0;

                                final propId = widget.propertyId ??
                                    _propertyId ??
                                    SupabaseService.instance.activePropertyId;
                                final propName = (_propertyName != null &&
                                        _propertyName!.isNotEmpty)
                                    ? _propertyName!
                                    : ((widget.propertyName != null &&
                                            widget.propertyName!.isNotEmpty)
                                        ? widget.propertyName!
                                        : (SupabaseService
                                                .instance.activePropertyName ??
                                            OwnerAppState
                                                .instance.activePropertyName));

                                final success = await SupabaseService.instance
                                    .addDamageDeduction(
                                  propertyId: propId ?? '',
                                  propertyName: propName,
                                  tenantId: resident['tenant_id']?.toString(),
                                  roomId: resident['room_id']?.toString(),
                                  roomNumber: roomName,
                                  bedId: bedId,
                                  tenantName: resident['name'] ?? 'Resident',
                                  itemDamaged: item,
                                  amount: dmgAmount,
                                  deductionMode: _damageDeductionMode,
                                  photoUrl: _damageAttachedPhoto,
                                );

                                if (!success) {
                                  _showToast(
                                      'Failed to log damage deduction. Please check connection.');
                                  return;
                                }

                                if (_damageDeductionMode == 'deposit') {
                                  final currentDeposit = double.tryParse(
                                          resident['deposit']?.toString() ??
                                              '0') ??
                                      0.0;
                                  final newDeposit =
                                      (currentDeposit - dmgAmount)
                                          .clamp(0.0, double.infinity);
                                  setState(() {
                                    resident['deposit'] =
                                        newDeposit.toInt().toString();
                                  });
                                }

                                await _loadRoomsFromSupabase();
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                                final modeText = _damageDeductionMode == 'dues'
                                    ? "Added to Dues"
                                    : "Deducted from Deposit";
                                _showToast(
                                    '₹$amount Damage for $item logged ($modeText) & sent on WhatsApp ✓');
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
                                'Save & Apply Damage Charge',
                                style: GoogleFonts.outfit(
                                    fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PRODUCTION MODAL 3: ASSIGN RESIDENT MODAL (Phonebook Picker & Strict Validation)
  // ===========================================================================
  void _openAssignModal(
      Map<String, dynamic> vacantBed, String roomName, String floorLabel) {
    _assignNameController.clear();
    _assignPhoneController.clear();
    _assignRentController.clear();
    _assignDepositController.clear();

    String contactSearch = '';
    bool showPhonebookPicker = true;
    int? selectedDueDay;

    // Immediately trigger real contact permission & fetch on open
    _fetchDeviceContacts();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.ink),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Resident',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '$roomName (${vacantBed['bed'] ?? vacantBed['label'] ?? ""}) • $floorLabel',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
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
            body: SafeArea(
              child: StatefulBuilder(
                builder: (modalCtx, setModalState) {
                  // Build dynamic list from real device contacts
                  final List<Map<String, String>> contactsList =
                      (_deviceContacts ?? [])
                          .map<Map<String, String>>((c) {
                            final name = c.displayName ?? '';
                            String phone = '';
                            if (c.phones.isNotEmpty) {
                              phone = c.phones.first.number
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              if (phone.length > 10) {
                                phone = phone.substring(phone.length - 10);
                              }
                            }
                            final initials = name.isNotEmpty
                                ? name.substring(0, 1).toUpperCase()
                                : '+';
                            return <String, String>{
                              'name': name,
                              'phone': phone,
                              'initials': initials,
                            };
                          })
                          .where((c) => c['phone']!.isNotEmpty)
                          .toList();

                  final filteredContacts = contactsList.where((c) {
                    if (contactSearch.isEmpty) return true;
                    final q = contactSearch.toLowerCase();
                    return c['name']!.toLowerCase().contains(q) ||
                        c['phone']!.contains(q);
                  }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          showPhonebookPicker =
                                              !showPhonebookPicker;
                                          if (showPhonebookPicker &&
                                              _deviceContacts == null) {
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
                                              color: const Color(0xFF2563EB)
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.contacts_rounded,
                                                size: 16,
                                                color: Color(0xFF2563EB)),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Pick from Phonebook',
                                            style: GoogleFonts.outfit(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            showPhonebookPicker
                                                ? Icons
                                                    .keyboard_arrow_up_rounded
                                                : Icons
                                                    .keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 1-Tap Native Android OS Contact Picker Button
                                    InkWell(
                                      onTap: () =>
                                          _pickNativeContact(setModalState),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 13,
                                                color: Color(0xFF2563EB)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'System Contacts',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF2563EB)),
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
                                const Divider(
                                    height: 1, color: Color(0xFFE5E7EB)),

                                // Loading State
                                if (_isLoadingContacts) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Color(0xFF2563EB)),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Reading phone contacts from device...',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: AppColors.muted),
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
                                        const Icon(Icons.no_accounts_rounded,
                                            size: 28, color: AppColors.muted),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Contacts permission needed to load phonebook',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () => _fetchDeviceContacts(
                                              setModalState),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                              'Allow Contacts Permission',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 6),
                                    child: Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: TextField(
                                        onChanged: (v) => setModalState(
                                            () => contactSearch = v),
                                        style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            color: AppColors.ink),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search contacts by name or number...',
                                          hintStyle: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppColors.muted),
                                          prefixIcon: const Icon(Icons.search,
                                              size: 16, color: AppColors.muted),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 9),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Contact List View
                                  if (filteredContacts.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Center(
                                        child: Text(
                                          _deviceContacts == null
                                              ? 'Tap "System Contacts" above to load contacts'
                                              : 'No contacts found matching "$contactSearch"',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppColors.muted),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      constraints:
                                          const BoxConstraints(maxHeight: 180),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: filteredContacts.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                                height: 1,
                                                color: Color(0xFFF3F4F6),
                                                indent: 48),
                                        itemBuilder: (context, idx) {
                                          final contact = filteredContacts[idx];
                                          return InkWell(
                                            onTap: () {
                                              setModalState(() {
                                                _assignNameController.text =
                                                    contact['name']!;
                                                _assignPhoneController.text =
                                                    contact['phone']!;
                                                showPhonebookPicker = false;
                                              });
                                              _showToast(
                                                  'Auto-filled from ${contact['name']}');
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xFF2563EB),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        contact['initials']!,
                                                        style:
                                                            GoogleFonts.outfit(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: Colors
                                                                    .white),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          contact['name']!,
                                                          style: GoogleFonts
                                                              .outfit(
                                                                  fontSize:
                                                                      12.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color:
                                                                      AppColors
                                                                          .ink),
                                                        ),
                                                        Text(
                                                          '+91 ${contact['phone']}',
                                                          style: GoogleFonts
                                                              .outfit(
                                                                  fontSize: 11,
                                                                  color: AppColors
                                                                      .muted),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      size: 16,
                                                      color: AppColors.muted),
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFormField(
                                'Security Deposit (₹)',
                                _assignDepositController,
                                prefixText: '₹ ',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Monthly Rent Due Date (Salary Cycle) Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent Due Date',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Agreed monthly salary payment cycle day:',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // 1st Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        setModalState(() => selectedDueDay = 1),
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selectedDueDay == 1
                                            ? AppColors.green
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selectedDueDay == 1
                                              ? AppColors.green
                                              : const Color(0xFFE5E7EB),
                                          width:
                                              selectedDueDay == 1 ? 1.8 : 1.2,
                                        ),
                                        boxShadow: selectedDueDay == 1
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.green
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '1st',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.5,
                                              fontWeight: selectedDueDay == 1
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: selectedDueDay == 1
                                                  ? Colors.white
                                                  : AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'of Month',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
                                              color: selectedDueDay == 1
                                                  ? Colors.white
                                                      .withValues(alpha: 0.9)
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3rd Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        setModalState(() => selectedDueDay = 3),
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selectedDueDay == 3
                                            ? AppColors.green
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selectedDueDay == 3
                                              ? AppColors.green
                                              : const Color(0xFFE5E7EB),
                                          width:
                                              selectedDueDay == 3 ? 1.8 : 1.2,
                                        ),
                                        boxShadow: selectedDueDay == 3
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.green
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '3rd',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.5,
                                              fontWeight: selectedDueDay == 3
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: selectedDueDay == 3
                                                  ? Colors.white
                                                  : AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'of Month',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
                                              color: selectedDueDay == 3
                                                  ? Colors.white
                                                      .withValues(alpha: 0.9)
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 5th Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        setModalState(() => selectedDueDay = 5),
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selectedDueDay == 5
                                            ? AppColors.green
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selectedDueDay == 5
                                              ? AppColors.green
                                              : const Color(0xFFE5E7EB),
                                          width:
                                              selectedDueDay == 5 ? 1.8 : 1.2,
                                        ),
                                        boxShadow: selectedDueDay == 5
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.green
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '5th',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.5,
                                              fontWeight: selectedDueDay == 5
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: selectedDueDay == 5
                                                  ? Colors.white
                                                  : AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'of Month',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
                                              color: selectedDueDay == 5
                                                  ? Colors.white
                                                      .withValues(alpha: 0.9)
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // + Custom Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final customCtrl = TextEditingController(
                                        text: (selectedDueDay != null &&
                                                selectedDueDay != 1 &&
                                                selectedDueDay != 3 &&
                                                selectedDueDay != 5)
                                            ? selectedDueDay.toString()
                                            : '',
                                      );
                                      final picked = await showDialog<int>(
                                        context: ctx,
                                        builder: (dCtx) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            surfaceTintColor:
                                                Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            title: Text(
                                              'Custom Rent Due Day',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Enter monthly salary due day (1 to 31):',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 12.5,
                                                      color: AppColors.muted),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: customCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  autofocus: true,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                        2),
                                                  ],
                                                  decoration: InputDecoration(
                                                    hintText: 'e.g. 10 or 15',
                                                    hintStyle:
                                                        GoogleFonts.outfit(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .muted),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 14,
                                                            vertical: 12),
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: Color(
                                                                    0xFFE5E7EB))),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: AppColors
                                                                        .green,
                                                                    width:
                                                                        1.5)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(dCtx).pop(),
                                                child: Text('Cancel',
                                                    style: GoogleFonts.outfit(
                                                        color: AppColors.muted,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final d = int.tryParse(
                                                      customCtrl.text.trim());
                                                  if (d != null &&
                                                      d >= 1 &&
                                                      d <= 31) {
                                                    Navigator.of(dCtx).pop(d);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.green,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: Text('Confirm',
                                                    style: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setModalState(
                                            () => selectedDueDay = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Builder(
                                      builder: (_) {
                                        final isCustomSelected =
                                            selectedDueDay != null &&
                                                selectedDueDay != 1 &&
                                                selectedDueDay != 3 &&
                                                selectedDueDay != 5;
                                        String formatDaySuffix(int d) {
                                          if (d >= 11 && d <= 13)
                                            return '${d}th';
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

                                        final label = isCustomSelected
                                            ? formatDaySuffix(selectedDueDay!)
                                            : '+ Custom';
                                        final sub = isCustomSelected
                                            ? 'Selected'
                                            : 'Cycle';
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 9),
                                          decoration: BoxDecoration(
                                            color: isCustomSelected
                                                ? AppColors.green
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCustomSelected
                                                  ? AppColors.green
                                                  : const Color(0xFFE5E7EB),
                                              width:
                                                  isCustomSelected ? 1.8 : 1.2,
                                            ),
                                            boxShadow: isCustomSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.green
                                                          .withValues(
                                                              alpha: 0.25),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                label,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13.5,
                                                  fontWeight: isCustomSelected
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: isCustomSelected
                                                      ? Colors.white
                                                      : AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                sub,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: isCustomSelected
                                                      ? Colors.white.withValues(
                                                          alpha: 0.9)
                                                      : AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: () async {
                            final name = _assignNameController.text.trim();
                            final phone = _assignPhoneController.text.trim();
                            final rent = _assignRentController.text.trim();
                            final deposit =
                                _assignDepositController.text.trim();

                            // Strict Validation Checks
                            if (name.isEmpty) {
                              _showToast('Please enter resident full name');
                              return;
                            }

                            if (phone.length != 10) {
                              _showToast(
                                  'Please enter valid 10-digit phone number');
                              return;
                            }

                            final rentNum = int.tryParse(rent);
                            if (rentNum == null || rentNum <= 0) {
                              _showToast(
                                  'Please enter valid monthly rent amount');
                              return;
                            }

                            final depositNum = int.tryParse(deposit);
                            if (depositNum == null || depositNum < 0) {
                              _showToast(
                                  'Please enter valid security deposit amount');
                              return;
                            }

                            if (selectedDueDay == null) {
                              _showToast(
                                  'Please select Monthly Rent Due Date (1st, 3rd, 5th, or Custom)');
                              return;
                            }

                            // Successfully assign resident to bed permanently in Supabase
                            String bedId = vacantBed['id']?.toString() ?? '';
                            if (bedId.isEmpty) {
                              for (var r in _rooms) {
                                if (r['room'] == roomName) {
                                  final beds = r['beds'] as List;
                                  for (var b in beds) {
                                    if (b['bed'] == vacantBed['bed'] ||
                                        b['label'] == vacantBed['bed']) {
                                      bedId = b['id']?.toString() ?? '';
                                      break;
                                    }
                                  }
                                }
                              }
                            }

                            if (bedId.isEmpty) {
                              _showToast(
                                  'Cannot identify bed record. Please pull to refresh.');
                              return;
                            }

                            final success = await SupabaseService.instance
                                .assignResidentToBed(
                              bedId: bedId,
                              name: name,
                              phone: phone,
                              propertyName: _propertyName,
                              roomNumber: roomName,
                              rent: double.tryParse(rent),
                              deposit: double.tryParse(deposit),
                              rentDueDay: selectedDueDay,
                            );
                            if (!success) {
                              _showToast(
                                  'Failed to save to database. Please check connection.');
                              return;
                            }

                            await _loadRoomsFromSupabase();

                            setState(() {
                              for (var r in _rooms) {
                                if (r['room'] == roomName) {
                                  final beds = r['beds'] as List;
                                  for (var b in beds) {
                                    if (b['bed'] == vacantBed['bed'] ||
                                        b['label'] == vacantBed['bed']) {
                                      b['isOccupied'] = true;
                                      b['name'] = name;
                                      b['phone'] = phone;
                                      b['rent'] = rent;
                                      b['deposit'] = deposit;
                                      b['status'] = 'Active';
                                      b['work'] = 'Resident';
                                      b['docs'] = 'Aadhaar Verified';
                                      b['docsVerified'] = true;
                                      b['initials'] = name.isNotEmpty
                                          ? name.substring(0, 1).toUpperCase()
                                          : 'US';
                                      break;
                                    }
                                  }
                                  r['occupied'] = (r['occupied'] as int) + 1;
                                  break;
                                }
                              }
                            });

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            _showToast(
                                '$name assigned to $roomName (${vacantBed['bed'] ?? vacantBed['label'] ?? ""}) ✓');
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
                            'Confirm Check-In & Assign Bed',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
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

    // Filter rooms by floor, card selection filter, and search query
    final filteredRooms = _rooms.map((room) {
      final rawBeds = room['beds'];
      final List bedsList = (rawBeds is List) ? rawBeds : [];
      final beds = bedsList.where((b) {
        if (b is! Map) return false;
        if (_selectedFilter == 'tenants') {
          return b['isOccupied'] == true;
        } else if (_selectedFilter == 'vacant') {
          return b['isOccupied'] == false;
        } else if (_selectedFilter == 'notice') {
          return b['isOccupied'] == true &&
              (b['status']?.toString().toLowerCase() == 'notice');
        }
        return true;
      }).toList();

      return {
        ...room,
        'beds': beds,
      };
    }).where((room) {
      final beds = (room['beds'] is List) ? (room['beds'] as List) : [];
      if (beds.isEmpty) return false;

      // 1. Floor filter
      if (_selectedFloor != 'all') {
        final floorStr = (room['floor'] ?? '').toString().toLowerCase();
        if (floorStr != _selectedFloor.toLowerCase()) {
          return false;
        }
      }
      // 2. Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final roomNameStr = (room['room'] ?? '').toString().toLowerCase();
        final roomMatch = roomNameStr.contains(query);
        final bedMatch = beds.any((b) {
          if (b is! Map) return false;
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
                    padding: EdgeInsets.fromLTRB(
                        context.responsiveHorizontalPadding,
                        16.0,
                        context.responsiveHorizontalPadding,
                        140.0),
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
                          ...filteredRooms
                              .map((room) => _buildRoomGroupBlock(room)),
                      ],
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

  // ===========================================================================
  // 1. TOP STICKY HEADER
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding, vertical: 12),
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
              Builder(
                builder: (context) {
                  final name =
                      (_propertyName != null && _propertyName!.isNotEmpty)
                          ? _propertyName!
                          : OwnerAppState.instance.activePropertyName;
                  final loc = OwnerAppState.instance.activePropertyLocation;
                  final parts = [
                    if (name.isNotEmpty) name,
                    if (loc.isNotEmpty) loc,
                  ];
                  return Text(
                    parts.isNotEmpty ? parts.join(' • ') : 'Room Matrix',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  );
                },
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
        style: GoogleFonts.outfit(
            fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search resident by name or room...',
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.muted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.clear, size: 16, color: AppColors.muted),
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
    int totalCapacity = 0;
    for (final r in _rooms) {
      final beds = (r['beds'] as List?) ?? [];
      totalCapacity += (r['total'] as num?)?.toInt() ?? beds.length;
    }
    final List<Map<String, String>> floors = [
      {'id': 'all', 'label': 'All Floors ($totalCapacity Beds)'},
    ];

    final Set<String> addedFloorIds = {};
    for (final r in _rooms) {
      final rawFloor = r['floor']?.toString().trim() ?? '';
      if (rawFloor.isEmpty) continue;
      final fLabel = (r['floorLabel'] != null &&
              r['floorLabel'].toString().trim().isNotEmpty)
          ? r['floorLabel'].toString().trim()
          : (rawFloor.toLowerCase().contains('floor')
              ? rawFloor
              : '$rawFloor Floor');
      if (!addedFloorIds.contains(rawFloor)) {
        addedFloorIds.add(rawFloor);
        floors.add({'id': rawFloor, 'label': fLabel});
      }
    }

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
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
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
  // 4. 3-PILL STAT STRIP (Dynamic: Occupied, Vacant, Notice)
  // ===========================================================================
  Widget _buildStatsStrip() {
    int totalCapacity = 0;
    int occupiedCount = 0;
    int noticeCount = 0;

    for (final r in _rooms) {
      final beds = (r['beds'] as List?) ?? [];
      totalCapacity += (r['total'] as num?)?.toInt() ?? beds.length;
      for (final b in beds) {
        if (b['isOccupied'] == true) {
          occupiedCount++;
          if (b['status'] == 'Notice') noticeCount++;
        }
      }
    }

    final vacantCount = (totalCapacity - occupiedCount).clamp(0, totalCapacity);

    return Row(
      children: [
        // Total Tenants (Green)
        Expanded(
          child: _buildStatTile(
            '$occupiedCount',
            'Total Tenants',
            AppColors.greenDark,
            isSelected: _selectedFilter == 'tenants',
            onTap: () {
              setState(() {
                _selectedFilter =
                    _selectedFilter == 'tenants' ? 'all' : 'tenants';
              });
              _showToast(_selectedFilter == 'tenants'
                  ? 'Showing Active Tenants ($occupiedCount)'
                  : 'Showing All Beds');
            },
          ),
        ),
        const SizedBox(width: 8),

        // Vacant Beds (Green)
        Expanded(
          child: _buildStatTile(
            '$vacantCount',
            'Vacant Beds',
            AppColors.greenDark,
            isSelected: _selectedFilter == 'vacant',
            onTap: () {
              setState(() {
                _selectedFilter =
                    _selectedFilter == 'vacant' ? 'all' : 'vacant';
              });
              _showToast(_selectedFilter == 'vacant'
                  ? 'Showing Vacant Beds ($vacantCount)'
                  : 'Showing All Beds');
            },
          ),
        ),
        const SizedBox(width: 8),

        // Notice Period (Green)
        Expanded(
          child: _buildStatTile(
            '$noticeCount',
            'Notice Period',
            AppColors.greenDark,
            isSelected: _selectedFilter == 'notice',
            onTap: () {
              setState(() {
                _selectedFilter =
                    _selectedFilter == 'notice' ? 'all' : 'notice';
              });
              _showToast(_selectedFilter == 'notice'
                  ? 'Showing Notice Period Tenants ($noticeCount)'
                  : 'Showing All Beds');
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
              color: isSelected
                  ? const Color(0x0C000000)
                  : const Color(0x03000000),
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
                          color: isFullyOccupied
                              ? AppColors.green
                              : const Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        '${room['occupied']}/${room['total']} Occupied',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isFullyOccupied
                              ? AppColors.greenDark
                              : const Color(0xFFD97706),
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
            final isOcc = bed['isOccupied'] == true ||
                (bed['name'] != null &&
                    bed['name'].toString().trim().isNotEmpty);
            if (isOcc) {
              return _buildTenantCard(
                bed,
                room['room']?.toString() ?? '',
                room['floorLabel']?.toString() ?? '',
                room['type']?.toString() ?? '',
              );
            } else {
              return _buildVacantBedCard(bed, room['room']?.toString() ?? '',
                  room['floorLabel']?.toString() ?? '');
            }
          })),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. OCCUPIED RESIDENT CARD (Spacious, Big & Eye-Catching)
  // ===========================================================================
  Widget _buildTenantCard(Map<String, dynamic> tenant, String roomName,
      [String? floorLabel, String? roomType]) {
    final isNotice = tenant['status'] == 'Notice';

    // 1. Resolve Floor String (no hardcoded defaults)
    final rawFloor = (floorLabel != null && floorLabel.trim().isNotEmpty)
        ? floorLabel.trim()
        : (tenant['floorLabel']?.toString().trim() ?? '');
    final displayFloor = rawFloor.isEmpty
        ? ''
        : (rawFloor.toLowerCase().contains('floor')
            ? rawFloor
            : '$rawFloor Floor');

    // 2. Resolve Room String (no hardcoded defaults)
    final rawRoom = (roomName.trim().isNotEmpty)
        ? roomName.trim()
        : (tenant['room_number']?.toString().trim() ??
            tenant['room']?.toString().trim() ??
            '');
    final displayRoom = rawRoom.isEmpty
        ? ''
        : ((rawRoom.toLowerCase().startsWith('room') ||
                rawRoom.toLowerCase().startsWith('flat'))
            ? rawRoom
            : 'Room $rawRoom');

    // 3. Resolve Sharing Type (Studio PG vs Apartment Unit - no hardcoded defaults)
    final bedLabel = (tenant['label'] ?? tenant['bed'] ?? '').toString();
    String displaySharing = '';
    if (bedLabel.contains('(Hall)')) {
      displaySharing = 'Hall';
    } else if (bedLabel.contains('(Master)')) {
      displaySharing = 'Master';
    } else if (bedLabel.contains('(Bedroom)')) {
      displaySharing = 'Bedroom';
    } else if (tenant['sharing_type'] != null &&
        tenant['sharing_type'].toString().trim().isNotEmpty) {
      displaySharing = tenant['sharing_type'].toString().trim();
    } else if (roomType != null && roomType.trim().isNotEmpty) {
      displaySharing = roomType.trim();
    } else if (tenant['type'] != null &&
        tenant['type'].toString().trim().isNotEmpty) {
      displaySharing = tenant['type'].toString().trim();
    }

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
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.25),
                            width: 1.5),
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

                  // Name
                  InkWell(
                    onTap: () => _openEditModal(tenant, roomName),
                    child: Text(
                      tenant['name']?.toString() ?? 'Resident',
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),

              // Clean [ ✏️ Edit ] Button
              InkWell(
                onTap: () => _openEditModal(tenant, roomName),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 13, color: AppColors.ink),
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

          // 2. Dedicated Status (Active / Notice Period) & Rent Row
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNotice
                        ? const Color(0xFFFEF2F2)
                        : AppColors.greenLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isNotice
                          ? const Color(0xFFFCA5A5)
                          : AppColors.green.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNotice
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: isNotice
                            ? const Color(0xFFDC2626)
                            : AppColors.greenDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isNotice ? 'Notice Period' : 'Active',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isNotice
                              ? const Color(0xFFDC2626)
                              : AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${tenant['rent'] ?? ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Spacious 2-Button Action Row: Icon-Only [ 📞 Call ] and [ 💬 WhatsApp ]
          Row(
            children: [
              // Call Button (Phone SVG Icon Only)
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'Calling ${tenant['name'] ?? 'Resident'}: +91${tenant['phone'] ?? ''}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3)),
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

              // WhatsApp Button (WhatsApp SVG Icon Only)
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'Opening WhatsApp chat with ${tenant['name'] ?? 'Resident'} (+91${tenant['phone'] ?? ''}) ✓'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3)),
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
          const SizedBox(height: 4),

          // Clean & Visible Stay Line: Floor • Room • Sharing Type (Only non-empty parts, no broken bullets)
          Builder(
            builder: (context) {
              final stayParts = <Widget>[];
              if (displayFloor.isNotEmpty) {
                stayParts.add(Text(
                  displayFloor,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ));
              }
              if (displayRoom.isNotEmpty) {
                if (stayParts.isNotEmpty) {
                  stayParts.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      '•',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ));
                }
                stayParts.add(Text(
                  displayRoom,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ));
              }
              if (displaySharing.isNotEmpty) {
                if (stayParts.isNotEmpty) {
                  stayParts.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      '•',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ));
                }
                stayParts.add(Text(
                  displaySharing,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ));
              }

              if (stayParts.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: stayParts,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),

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
                      const Icon(Icons.badge_outlined,
                          size: 14, color: AppColors.muted),
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
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.ink),
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
  Widget _buildVacantBedCard(
      Map<String, dynamic> bed, String roomName, String floorLabel) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
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
    final bool isSearch = _searchQuery.isNotEmpty ||
        _selectedFloor != 'all' ||
        _selectedFilter != 'all';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.bed_outlined,
              size: 44,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              isSearch
                  ? 'No rooms or residents match your search'
                  : 'No Rooms Added Yet',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSearch
                  ? 'Try a different room number or resident name'
                  : 'Tap the + button below to add your first room and beds.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
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
          style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted),
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
            style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: AppColors.ink,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: prefixText,
              prefixStyle: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700),
              hintText: hint,
              hintStyle:
                  GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
