import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/owner_app_state.dart';

/// Screen 8: Rent Collection Hub & WhatsApp Dues Chaser.
/// 3-Tier Hierarchy: Floor -> Room (Sharing Type & Rent Total) -> Beds & Resident Cards.
/// Strict Design System (No purple, pure executive UrbanStay palette):
/// - No top-right phone number pills on cards.
/// - Side-by-side [ 📞 Call ] and [ 💬 WhatsApp ] buttons on ALL cards (Paid, Overdue, Extension).
/// - Clean Warm Gold / Neutral Ink family styling for extensions (zero purple).
class OwnerRentCollectionScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerRentCollectionScreen({super.key, this.onBack});

  @override
  State<OwnerRentCollectionScreen> createState() =>
      _OwnerRentCollectionScreenState();
}

class _OwnerRentCollectionScreenState extends State<OwnerRentCollectionScreen> {
  late String _selectedCycle;
  String _selectedFloor = 'all'; // 'all', '1st', '2nd', '3rd', 'ground'
  String _selectedStatus = 'all'; // 'all', 'overdue', 'extension', 'paid'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Form Controllers for Record Cash Modal
  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _cashNotesController = TextEditingController();
  String _cashPaymentDate = DateTime.now().toIso8601String().split('T').first;

  // Form Controllers for Grant Extension Modal
  String _selectedExtensionDate = '';
  final TextEditingController _extensionReasonController =
      TextEditingController();

  // Active Target for Modals (Populated when user taps tenant action)
  Map<String, dynamic> _activeCashTarget = {};
  Map<String, dynamic> _activeExtensionTarget = {};
  Map<String, dynamic> _activeReceiptTarget = {};

  String _activeViewMode =
      'calendar'; // 'calendar' (Day-Wise Salary Calendar) or 'floor' (By Floor & Rooms)
  int _selectedCalendarDay = 5; // Default 5th of month
  String _selectedStaffActor = 'Ramesh Gowda (Manager)';
  final List<String> _staffActors = [
    'Ramesh Gowda (Manager)',
    'Arun Kumar (Co-Owner)',
    'Bhargav S Kulkarni (Owner)',
  ];

  List<String> get _cycleList {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${months[d.month - 1]} ${d.year}';
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    _selectedCycle = '${months[now.month - 1]} ${now.year}';
    _loadRentLedgerFromSupabase();
  }

  Future<void> _loadRentLedgerFromSupabase() async {
    try {
      final prop = await SupabaseService.instance.getOwnerProperty();
      if (prop != null) {
        final propId = prop['id'].toString();
        final ledger = await SupabaseService.instance.getMonthlyRentLedger(propId);
        if (ledger.isNotEmpty && mounted) {
          final Map<String, Map<String, List<Map<String, dynamic>>>> floorMap = {};
          for (final row in ledger) {
            final tenant = row['tenants'] as Map<String, dynamic>?;
            final roomNum = tenant?['room_number'] ?? 'Room 101';
            final floorName = roomNum.startsWith('G') ? 'Ground Floor' : '${roomNum[0]}st Floor';
            final floorId = floorName.split(' ').first.toLowerCase();

            floorMap.putIfAbsent(floorId, () => {});
            floorMap[floorId]!.putIfAbsent(roomNum, () => []);

            final status = (row['status'] ?? 'PENDING').toString().toLowerCase();
            final isPaid = status == 'paid';
              final tenantName = tenant?['full_name'] ?? 'Resident';
              final nameParts = tenantName.trim().split(' ');
              final computedInitials = nameParts.length >= 2
                  ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
                  : (tenantName.isNotEmpty ? tenantName[0].toUpperCase() : '?');

            floorMap[floorId]![roomNum]!.add({
              'id': row['id'].toString(),
              'name': tenantName,
              'initials': computedInitials,
              'bed': tenant?['bed_number'] ?? 'Bed A',
              'room': roomNum,
              'roomNum': roomNum,
              'floor': floorId,
              'work': 'Resident',
              'phone': tenant?['phone'] ?? '',
              'amount': (row['amount'] as num?)?.toInt() ?? 8000,
              'status': isPaid ? 'paid' : 'overdue',
              'paidLabel': isPaid ? 'Paid (Direct UPI)' : null,
              'tag': isPaid ? 'Settled 0% Fee' : null,
              'ref': row['transaction_ref'] ?? 'UPI-REF',
              'paidDate': row['paid_at'] != null ? row['paid_at'].toString().split('T').first : null,
              'overdueDays': !isPaid ? 'Payment Pending' : null,
              'dueLabel': !isPaid ? 'Due this month' : null,
            });
          }

          final List<Map<String, dynamic>> loadedFloors = [];
          floorMap.forEach((fId, roomsMap) {
            final List<Map<String, dynamic>> roomsList = [];
            roomsMap.forEach((rNum, beds) {
              roomsList.add({
                'room': rNum,
                'type': '2-Sharing',
                'monthlyExpected': beds.fold<int>(0, (acc, b) => acc + (b['amount'] as int)),
                'beds': beds,
              });
            });
            loadedFloors.add({
              'id': fId,
              'title': '$fId Floor',
              'roomsSubtitle': '${roomsList.length} Rooms • ${roomsList.fold<int>(0, (acc, r) => acc + (r['beds'] as List).length)} Beds',
              'rooms': roomsList,
            });
          });

          setState(() {
            _floorsData.clear();
            _floorsData.addAll(loadedFloors);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading rent ledger from Supabase: $e');
    }
  }

  // Master Floor, Room & Bed Hierarchy Data (Populated live from Supabase — no mock fallback)
  final List<Map<String, dynamic>> _floorsData = [];

  @override
  void dispose() {
    _searchController.dispose();
    _cashAmountController.dispose();
    _cashNotesController.dispose();
    _extensionReasonController.dispose();
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

  // Flattened list of all occupied beds for stats calculations
  List<Map<String, dynamic>> _getAllOccupiedTenants() {
    final List<Map<String, dynamic>> list = [];
    for (var f in _floorsData) {
      for (var r in (f['rooms'] as List<Map<String, dynamic>>)) {
        for (var b in (r['beds'] as List<Map<String, dynamic>>)) {
          if (b['isVacant'] != true) {
            list.add(b);
          }
        }
      }
    }
    return list;
  }

  // Extension Flow Actions
  void _approveExtension(Map<String, dynamic> tenant) {
    setState(() {
      tenant['status'] = 'extension_approved';
      tenant['extensionDate'] = tenant['requestedDate'] ?? 'Not Set';
      tenant['dueLabel'] =
          'Extension Approved • Due ${tenant['extensionDate']}';
    });
    _showToast(
        'Extension Approved for ${tenant['name']} till ${tenant['extensionDate']} • Reminders paused ✓');
  }

  void _declineExtension(Map<String, dynamic> tenant) {
    setState(() {
      tenant['status'] = 'overdue';
      tenant['dueLabel'] = 'Extension Declined • Due Immediately';
    });
    _showToast(
        'Extension Declined for ${tenant['name']}. Reminder sent on WhatsApp.');
  }

  // ===========================================================================
  // MODAL 1: RECORD PAYMENT (Cash or Direct Online UPI with Staff Attribution)
  // ===========================================================================
  void _openRecordCashModal(Map<String, dynamic> tenant) {
    _activeCashTarget = {
      'name': tenant['name'],
      'room': tenant['room'],
      'outstanding': tenant['amount'],
    };
    _cashAmountController.text = tenant['amount'].toString();
    _cashNotesController.clear();
    String currentStaff = _selectedStaffActor;
    String paymentMode = 'cash'; // 'cash' or 'online'
    final utrController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Record Cash',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormLabel('Amount Received (₹)'),
                  _buildTextInput(
                    _cashAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('Verified / Recorded By'),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentStaff,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: AppColors.ink),
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                        items: _staffActors.map((actor) {
                          return DropdownMenuItem<String>(
                            value: actor,
                            child: Text(actor),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => currentStaff = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final amountReceived =
                          int.tryParse(_cashAmountController.text.trim()) ?? 0;
                      if (amountReceived <= 0) {
                        _showToast('Please enter a valid amount');
                        return;
                      }
                      Navigator.of(ctx).pop();
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] = 'Paid in Cash';
                        tenant['paidDate'] = '18 Aug 2026';
                        tenant['approvedBy'] = currentStaff;
                      });
                      _showToast(
                          '₹$amountReceived marked Paid for ${tenant['name']} (Verified by $currentStaff) ✓');
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
                      'Confirm & Mark Paid',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 1B: CHANGE PAY DATE / SALARY CYCLE
  // ===========================================================================
  void _openChangePayDateModal(Map<String, dynamic> tenant) {
    int currentDay = (tenant['payDay'] as int?) ?? 5;
    int selectedDay = currentDay;
    final reasonCtrl =
        TextEditingController(text: 'Salary credited on ${selectedDay}th');

    final List<int> quickDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Re-Assign Pay Date: ${tenant['name']}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${tenant['bed']} • Current Agreed Pay Date: ${currentDay}th of month',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('Select New Monthly Pay Date'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickDays.map((d) {
                      final isSel = selectedDay == d;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedDay = d;
                            reasonCtrl.text =
                                'Salary credited on ${d}th of every month';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.greenLight
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.green
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '${d}th of Month',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color:
                                  isSel ? AppColors.greenDark : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('Reason / Notes'),
                  _buildTextInput(reasonCtrl,
                      hint: 'e.g. Salary credited on 10th from employer'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        tenant['payDay'] = selectedDay;
                        tenant['payDayReason'] = reasonCtrl.text.trim();
                      });
                      _showToast(
                          'Pay Date updated to ${selectedDay}th of month for ${tenant['name']} ✓');
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
                      'Save & Move to ${selectedDay}th of Month',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 3: STAMPED DIGITAL RENT RECEIPT
  // ===========================================================================
  void _openReceiptModal(Map<String, dynamic> tenant) {
    _activeReceiptTarget = {
      'name': tenant['name'],
      'room': tenant['bed'],
      'amount': '₹${tenant['amount']}',
      'ref': tenant['ref'] ?? 'UTR-${DateTime.now().millisecondsSinceEpoch}',
      'date': tenant['paidDate'] ?? _selectedCycle,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Digital Rent Receipt (HRA Tax Valid)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Text(
                      OwnerAppState.instance.activePropertyName.isNotEmpty
                          ? OwnerAppState.instance.activePropertyName
                          : 'My PG',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#42, 5th Cross, 4th Block, Koramangala, Bengaluru',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE5E7EB), height: 1),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                        'Tenant Name:', _activeReceiptTarget['name'],
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Room / Bed:', 'Room ${_activeReceiptTarget['room']}'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Month / Period:', _selectedCycle),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Amount Paid:', _activeReceiptTarget['amount'],
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Transaction Ref:', _activeReceiptTarget['ref'],
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Date of Payment:', _activeReceiptTarget['date']),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.green, width: 1.5),
                      ),
                      child: Text(
                        '✓ DIGITALLY VERIFIED & STAMPED',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast(
                      'PDF Rent Receipt Downloaded & Shared on WhatsApp ✓');
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
                  'Download PDF Receipt',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 4: VIEW PAYMENT PROOF & UTR
  // ===========================================================================
  void _openViewProofModal(Map<String, dynamic> tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Payment Proof: ${tenant['name']}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(
                        'Resident:', '${tenant['name']} (${tenant['bed']})',
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Amount Claimed:', '₹${tenant['amount']}',
                        isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Payment Mode:', 'Direct UPI / PhonePe'),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Submitted UTR / Ref:', tenant['ref'] ?? 'Pending UTR',
                        isMonospace: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                        'Submission Time:', tenant['submissionTime'] ?? 'Today'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please verify that ₹${tenant['amount']} was credited to your HDFC/SBI bank account before accepting.',
                        style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openRejectPaymentModal(tenant);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Reject (Not in Bank)',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final now = DateTime.now();
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
                        setState(() {
                          tenant['status'] = 'paid';
                          tenant['paidLabel'] =
                              'Paid on ${now.day} ${months[now.month - 1]} (Verified by $_selectedStaffActor)';
                          tenant['tag'] = 'Direct UPI';
                          tenant['ref'] = tenant['ref'] ?? 'UTR-${now.millisecondsSinceEpoch}';
                          tenant['paidDate'] = dateStr;
                          tenant['approvedBy'] = _selectedStaffActor;
                        });
                        _showToast(
                            'Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept & Mark Paid',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 5: REJECT PAYMENT (Direct Bank UPI Failure Alert)
  // ===========================================================================
  void _openRejectPaymentModal(Map<String, dynamic> tenant) {
    String selectedReason = 'Money Not Credited in Bank Account';
    final customNoteCtrl = TextEditingController();
    final List<String> reasons = [
      'Money Not Credited in Bank Account',
      'Incorrect / Invalid 12-Digit UTR Number',
      'Partial Amount Paid (Shortfall)',
      'Payment Sent to Wrong UPI Account',
    ];

    final roomStr = tenant['roomNum'] != null
        ? 'Room ${tenant['roomNum']}'
        : (tenant['room'] ?? tenant['bed'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Reject Payment: ${tenant['name']}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tenant['name']} ($roomStr)',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF991B1B)),
                            ),
                            Text(
                              'Claimed Amount: ₹${tenant['amount']} · ${tenant['ref'] ?? 'UTR-Pending'}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UNVERIFIED',
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Rejection Reason (Sent to Resident):',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => setModalState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: isSel
                                    ? const Color(0xFFDC2626)
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? const Color(0xFF991B1B)
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text(
                    'Additional Note (Optional):',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: customNoteCtrl,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.ink),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Please resend proof from bank passbook',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tenant['status'] = 'overdue';
                        tenant['dueLabel'] = 'Payment Rejected ($selectedReason)';
                      });
                      Navigator.of(ctx).pop();
                      _showToast(
                          'Payment rejected: Alert sent to ${tenant['name']} on WhatsApp ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Rejection & Send Alert',
                      style: GoogleFonts.outfit(
                          fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
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
    final allOccupied = _getAllOccupiedTenants();
    final overdueCount =
        allOccupied.where((t) => t['status'] == 'overdue').length;
    final extensionCount = allOccupied
        .where((t) =>
            t['status'] == 'extension_requested' ||
            t['status'] == 'extension_approved')
        .length;
    final paidCount = allOccupied.where((t) => t['status'] == 'paid').length;
    final overdueSum = allOccupied
        .where((t) =>
            t['status'] == 'overdue' ||
            t['status'] == 'extension_requested' ||
            t['status'] == 'extension_approved')
        .fold<int>(0, (sum, item) => sum + (item['amount'] as int));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Header
            _buildTopHeader(),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 96.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3-Pill Financial Summary Strip
                    _buildStatsStrip(overdueCount + extensionCount, overdueSum),
                    const SizedBox(height: 14),

                    // 1-Tap Broadcast WhatsApp Reminders Card
                    _buildBroadcastRemindersCard(overdueCount),
                    const SizedBox(height: 14),

                    // Horizontal Floor Switcher Chips
                    _buildFloorChipsScroll(),
                    const SizedBox(height: 10),

                    // Filter Chips Bar (All, Overdue, ⏳ Extension, Paid)
                    _buildStatusFilterChips(
                        overdueCount, extensionCount, paidCount),
                    const SizedBox(height: 12),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 16),

                    // 3-TIER HIERARCHY: Floor -> Room (Sharing Type) -> Bed Cards
                    if (_floorsData.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: AppColors.greenLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 26,
                                color: AppColors.greenDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Active Rent Ledgers Found',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Assign tenants to beds to track monthly rent, send automated WhatsApp reminders, and audit collections.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._floorsData
                          .where((f) =>
                              _selectedFloor == 'all' ||
                              _selectedFloor == f['id'])
                          .map((floor) => _buildFloorSection(floor))
                          .toList(),
                  ],
                ),
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
                    'Rent Collection',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${OwnerAppState.instance.activePropertyName.isNotEmpty ? OwnerAppState.instance.activePropertyName : "My PG"} • ${OwnerAppState.instance.totalBeds} Beds',
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

          // Cycle Selector Dropdown
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _cycleList.contains(_selectedCycle)
                    ? _selectedCycle
                    : _cycleList.first,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
                items: _cycleList.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCycle = val);
                    _showToast('Viewing $val');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. 3-PILL FINANCIAL SUMMARY STRIP
  // ===========================================================================
  Widget _buildStatsStrip(int totalPendingCount, int overdueSum) {
    final allOccupied = _getAllOccupiedTenants();
    final totalExpected = allOccupied.fold<int>(0, (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0));
    final collected = allOccupied
        .where((t) => t['status'] == 'paid')
        .fold<int>(0, (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0));

    return Row(
      children: [
        Expanded(
            child: _buildStatTile(
                '₹$totalExpected', 'Total Expected', AppColors.greenDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatTile(
                '₹$collected', 'Collected', AppColors.greenDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatTile(
                '₹$overdueSum', '$totalPendingCount Due', AppColors.greenDark)),
      ],
    );
  }

  Widget _buildStatTile(String num, String label, Color numColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              fontSize: 16.5,
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
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. BROADCAST REMINDERS CARD
  // ===========================================================================
  Widget _buildBroadcastRemindersCard(int overdueCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Due: $overdueCount',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.ink,
            ),
          ),
          InkWell(
            onTap: () => _showToast(
                'Payment Reminders sent to $overdueCount Due Residents ✓'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Reminder',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3B. VIEW MODE SWITCHER (Salary Date Calendar vs By Floor & Room)
  // ===========================================================================
  Widget _buildViewModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewMode = 'calendar'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _activeViewMode == 'calendar'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeViewMode == 'calendar'
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
                      Icons.calendar_month_outlined,
                      size: 15,
                      color: _activeViewMode == 'calendar'
                          ? AppColors.greenDark
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Salary Date Calendar',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: _activeViewMode == 'calendar'
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _activeViewMode == 'calendar'
                            ? AppColors.greenDark
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewMode = 'floor'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _activeViewMode == 'floor'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeViewMode == 'floor'
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
                      Icons.apartment_outlined,
                      size: 15,
                      color: _activeViewMode == 'floor'
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'By Floor & Rooms',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: _activeViewMode == 'floor'
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _activeViewMode == 'floor'
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3C. DAY-WISE SALARY DATE CALENDAR SECTION
  // ===========================================================================
  Widget _buildDayWiseCalendarSection() {
    final allOccupied = _getAllOccupiedTenants();

    final availableDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20];
    final selectedTenants = allOccupied.where((t) {
      final day = (t['payDay'] as int?) ?? 5;
      return day == _selectedCalendarDay;
    }).toList();

    final dayTotalExpected =
        selectedTenants.fold<int>(0, (sum, t) => sum + (t['amount'] as int));
    final dayPaidCount =
        selectedTenants.where((t) => t['status'] == 'paid').length;
    final dayPendingCount = selectedTenants.length - dayPaidCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal Date Strip (1st to 31st)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: availableDays.map((d) {
              final count = allOccupied
                  .where((t) => ((t['payDay'] as int?) ?? 5) == d)
                  .length;
              final isSel = _selectedCalendarDay == d;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedCalendarDay = d),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSel ? AppColors.green : const Color(0xFFE5E7EB),
                        width: isSel ? 1.5 : 1.0,
                      ),
                      boxShadow: isSel
                          ? const [
                              BoxShadow(
                                  color: Color(0x1808A63F),
                                  blurRadius: 6,
                                  offset: Offset(0, 2))
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${d}th',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isSel ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$count Beds',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Selected Day Cashflow Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedCalendarDay}th of the Month (Salary Cycle)',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark),
                  ),
                  Text(
                    '₹$dayTotalExpected Expected',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenDark),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedTenants.length} Tenants • $dayPaidCount Paid • $dayPendingCount Pending for today',
                style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // List of Tenants paying on this date
        if (selectedTenants.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_available_outlined,
                    size: 32, color: AppColors.muted),
                const SizedBox(height: 8),
                Text(
                  'No tenants scheduled for ${_selectedCalendarDay}th',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...selectedTenants
              .map((tenant) => _buildCalendarTenantCard(tenant))
              .toList(),
      ],
    );
  }

  // ===========================================================================
  // 3D. CALENDAR TENANT CARD (With 2-Row Horizontal Actions & Attribution)
  // ===========================================================================
  Widget _buildCalendarTenantCard(Map<String, dynamic> tenant) {
    final isPaid = tenant['status'] == 'paid';
    final isOverdue = tenant['status'] == 'overdue';
    final isExt = tenant['status'] == 'extension_requested' ||
        tenant['status'] == 'extension_approved';
    final String approvedBy = tenant['approvedBy'] ?? 'Ramesh Gowda (Manager)';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? AppColors.green.withValues(alpha: 0.3)
              : isOverdue
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
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
          // Header Row: Avatar + Name + Bed + Rent Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.greenLight
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        tenant['initials'] ?? 'TN',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isPaid ? AppColors.greenDark : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['name'] ?? 'Resident',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tenant['bed']} • Room ${tenant['roomNum']} (${tenant['floor']} Floor)',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${tenant['amount']}',
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: isPaid ? AppColors.greenDark : AppColors.ink,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.greenLight
                          : isOverdue
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid
                          ? 'PAID'
                          : isOverdue
                              ? 'OVERDUE'
                              : 'PENDING',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isPaid
                            ? AppColors.greenDark
                            : isOverdue
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Attribution / Status Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              children: [
                Icon(
                  isPaid
                      ? Icons.verified_user_outlined
                      : Icons.schedule_rounded,
                  size: 13,
                  color: isPaid ? AppColors.greenDark : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPaid
                        ? 'Verified by $approvedBy • Paid on ${tenant['paidDate'] ?? '1 Aug'}'
                        : isOverdue
                            ? 'Due on ${_selectedCalendarDay}th • Overdue (${tenant['overdueDays'] ?? 'Pending'})'
                            : 'Salary Date: ${_selectedCalendarDay}th • Due Today (No Late Fine)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.greenDark : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ROW 1: Call & WhatsApp Side-by-Side
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showToast(
                      'Dialing +91 ${tenant['phone'] ?? '9876543210'}...'),
                  icon: const Icon(Icons.phone_outlined,
                      size: 14, color: AppColors.ink),
                  label: Text(
                    'Call',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showToast(
                      'WhatsApp Chat opened with ${tenant['name']} (+91 ${tenant['phone'] ?? '9876543210'}) ✓'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: Colors.white),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ROW 2: If Paid -> View Receipt & Change Date
          //        If Not Paid -> Verification Actions (View Proof, Reject, Accept) + Change Date Option
          if (isPaid)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openReceiptModal(tenant),
                    icon: const Icon(Icons.receipt_long_outlined,
                        size: 14, color: AppColors.greenDark),
                    label: Text(
                      'View Receipt',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                      side: BorderSide(
                          color: AppColors.green.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChangePayDateModal(tenant),
                    icon: const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.muted),
                    label: Text(
                      'Change Date',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            // Verification Bar: View Proof, Reject (Not in Bank), and Accept
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => _openViewProofModal(tenant),
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: AppColors.ink),
                    label: Text(
                      'View Proof',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showToast(
                          'Payment rejected: Not received in owner bank account. Alert sent to ${tenant['name']}');
                    },
                    icon: const Icon(Icons.close_rounded,
                        size: 13, color: Color(0xFFDC2626)),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] =
                            'Paid on ${now.day} ${months[now.month - 1]} (Verified by $_selectedStaffActor)';
                        tenant['tag'] = 'Direct UPI';
                        tenant['ref'] = tenant['ref'] ?? 'UTR-${now.millisecondsSinceEpoch}';
                        tenant['paidDate'] = dateStr;
                        tenant['approvedBy'] = _selectedStaffActor;
                      });
                      _showToast(
                          'Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                    },
                    icon: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Secondary Option: Manual Record Cash / Change Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openRecordCashModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Record Cash Instead',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openChangePayDateModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Change Pay Date',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. HORIZONTAL FLOOR SWITCHER CHIPS
  // ===========================================================================
  Widget _buildFloorChipsScroll() {
    final List<Map<String, String>> floors = [
      {'id': 'all', 'label': 'All Floors'},
    ];
    for (final f in _floorsData) {
      final fId = f['id']?.toString() ?? '';
      if (!floors.any((x) => x['id'] == fId)) {
        floors.add({
          'id': fId,
          'label': f['title']?.toString() ?? '$fId Floor',
        });
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
  // 5. STATUS FILTER CHIPS BAR
  // ===========================================================================
  Widget _buildStatusFilterChips(
      int overdueCount, int extensionCount, int paidCount) {
    final filters = [
      {'id': 'all', 'label': 'All Status (17)'},
      {'id': 'overdue', 'label': 'Overdue ($overdueCount)'},
      {'id': 'extension', 'label': 'Extension ($extensionCount)'},
      {'id': 'paid', 'label': 'Paid ($paidCount)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedStatus = f['id']!);
                _showToast('Showing ${f['label']}');
              },
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.green : const Color(0xFFE5E7EB),
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
  // 6. SEARCH BOX
  // ===========================================================================
  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          hintText: '',
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. LEVEL 1: FLOOR SECTION CONTAINER
  // ===========================================================================
  Widget _buildFloorSection(Map<String, dynamic> floor) {
    final List<Map<String, dynamic>> rooms = floor['rooms'];

    // Check if any room has matching beds after filtering
    final List<Widget> roomWidgets = [];
    for (var r in rooms) {
      final roomWidget = _buildRoomSubBlock(r);
      if (roomWidget != null) {
        roomWidgets.add(roomWidget);
      }
    }

    if (roomWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(20),
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
          // Centered Floor Master Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                floor['title'],
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                floor['roomsSubtitle'],
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render Nested Room Blocks
          ...roomWidgets,
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. LEVEL 2: ROOM SUB-BLOCK (Sharing Type & Room Sub-Header)
  // ===========================================================================
  Widget? _buildRoomSubBlock(Map<String, dynamic> roomData) {
    final List<Map<String, dynamic>> beds = roomData['beds'];

    // Filter beds based on search & status
    final filteredBeds = beds.where((b) {
      if (b['isVacant'] == true) {
        if (_selectedStatus != 'all') return false;
        if (_searchQuery.isNotEmpty) return false;
        return true;
      }

      if (_selectedStatus == 'overdue' && b['status'] != 'overdue')
        return false;
      if (_selectedStatus == 'extension' &&
          (b['status'] != 'extension_requested' &&
              b['status'] != 'extension_approved')) return false;
      if (_selectedStatus == 'paid' && b['status'] != 'paid') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = (b['name'] as String).toLowerCase().contains(q);
        final roomMatch = (b['room'] as String).toLowerCase().contains(q);
        final workMatch = (b['work'] as String).toLowerCase().contains(q);
        return nameMatch || roomMatch || workMatch;
      }
      return true;
    }).toList();

    if (filteredBeds.isEmpty) return null;

    final totalOccupied = beds.where((b) => b['isVacant'] != true).length;
    final totalPaid = beds.where((b) => b['status'] == 'paid').length;
    final totalOverdue = beds.where((b) => b['status'] == 'overdue').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Header Row: Room 101 [Box] + 2-Sharing [Box]
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  roomData['room'],
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  roomData['type'],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 10),

          // Level 3: Bed & Resident Cards inside this Room
          ...filteredBeds.map((b) => b['isVacant'] == true
              ? _buildVacantBedCard(b)
              : _buildBedResidentCard(b)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. LEVEL 3: BED RESIDENT CARD (Zero Purple, Side-by-Side Call + WhatsApp)
  // ===========================================================================
  Widget _buildBedResidentCard(Map<String, dynamic> tenant) {
    final status = tenant['status'] as String;
    final isPaid = status == 'paid';
    final isExtRequested = status == 'extension_requested';
    final isExtApproved = status == 'extension_approved';
    final isOverdue = status == 'overdue';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExtRequested
              ? const Color(0xFFFDE68A)
              : (isExtApproved
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFEEF0F2)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Resident Header Row: Avatar + Name + Bed Tag + Status Pill (NO TOP RIGHT PHONE PILL)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 42px Avatar Initial Circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.greenLight
                          : (isExtRequested || isExtApproved
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFFFFFFF)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPaid
                            ? AppColors.green.withValues(alpha: 0.25)
                            : (isExtRequested
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFE5E7EB)),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tenant['initials'] ?? 'RS',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isPaid
                              ? AppColors.greenDark
                              : (isExtRequested || isExtApproved
                                  ? const Color(0xFF92400E)
                                  : AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Resident Name Only
                  Text(
                    tenant['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Rent Amount Only (Clean)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${tenant['amount']}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),

          // Extension Reason Box (Clean Warm Gold Tone - No Purple)
          if (isExtRequested || isExtApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Requested to pay on ${tenant['requestedDate'] ?? tenant['extensionDate'] ?? '15 Aug 2026'}',
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
          const SizedBox(height: 10),

          // 3. ACTION BUTTONS: SIDE-BY-SIDE [ 📞 Call ] AND [ 💬 WhatsApp ] FOR ALL!
          Row(
            children: [
              // [ 📞 Phone SVG Icon Only - Light Green Background ]
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'Calling ${tenant['name']}: +91${tenant['phone']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/phone.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            AppColors.greenDark, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // [ 💬 WhatsApp SVG Icon Only - Light Green Background ]
              Expanded(
                child: InkWell(
                  onTap: () => _showToast(
                      'WhatsApp opened with ${tenant['name']} (+91${tenant['phone']})'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/whatsapp.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                            AppColors.greenDark, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isPaid) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openChangePayDateModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'PAID',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paid on ${tenant['paidDate'] ?? '1 Aug 2026'}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (isExtRequested) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Decline Extension?',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to decline the payment extension for ${tenant['name']}?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dCtx);
                                _declineExtension(tenant);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Yes, Decline',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: Text(
                          '✕ Decline',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      final extDate = tenant['requestedDate'] ?? '15 Aug 2026';
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Approve Extension?',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          content: Text(
                            'Approve rent payment extension for ${tenant['name']} till $extDate?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dCtx);
                                _approveExtension(tenant);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Yes, Approve',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: Text(
                          '✓ Approve (${tenant['requestedDate'] ?? '15 Aug 2026'})',
                          style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Row 1: Verification Bar: View Proof, Reject, Accept
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => _openViewProofModal(tenant),
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: AppColors.ink),
                    label: Text(
                      'View Proof',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => _openRejectPaymentModal(tenant),
                    icon: const Icon(Icons.close_rounded,
                        size: 13, color: Color(0xFFDC2626)),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] =
                            'Paid on ${now.day} ${months[now.month - 1]} (Verified by $_selectedStaffActor)';
                        tenant['tag'] = 'Direct UPI';
                        tenant['ref'] = tenant['ref'] ?? 'UTR-${now.millisecondsSinceEpoch}';
                        tenant['paidDate'] = dateStr;
                        tenant['approvedBy'] = _selectedStaffActor;
                      });
                      _showToast(
                          'Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                    },
                    icon: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Secondary Options: Record Cash Instead / Change Pay Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openRecordCashModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Record Cash Instead',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openChangePayDateModal(tenant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEF0F2)),
                      ),
                      child: Text(
                        'Change Pay Date',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'DUE',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant['overdueDays'] ??
                        (isOverdue ? 'Overdue' : 'Due Today'),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // VACANT BED CARD
  // ===========================================================================
  Widget _buildVacantBedCard(Map<String, dynamic> bed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.single_bed_outlined,
                    size: 16, color: AppColors.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bed['title'] ?? 'Vacant Bed — Available',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showToast('Opening Bed ${bed['room']} Onboarding'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+ Assign',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATUS PILL BADGE (Zero Purple, Warm Gold & Emerald Family Colors)
  // ===========================================================================
  Widget _buildStatusPillBadge(String status, Map<String, dynamic> tenant) {
    if (status == 'paid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: AppColors.green.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4.5,
                height: 4.5,
                decoration: const BoxDecoration(
                    color: AppColors.green, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Paid',
                style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark)),
          ],
        ),
      );
    } else if (status == 'extension_requested') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4.5,
                height: 4.5,
                decoration: const BoxDecoration(
                    color: Color(0xFFD97706), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Requested 15 Aug',
                style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E))),
          ],
        ),
      );
    } else if (status == 'extension_approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4.5,
                height: 4.5,
                decoration: const BoxDecoration(
                    color: Color(0xFF92400E), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Extended (15 Aug)',
                style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4.5,
                height: 4.5,
                decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(tenant['overdueDays'] ?? 'Overdue',
                style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger)),
          ],
        ),
      );
    }
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
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom + 16
            : MediaQuery.of(context).padding.bottom + 32,
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

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.muted),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller,
      {String? hint,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
    return Container(
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
            fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBold = false, bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted)),
        Text(
          value,
          style: isMonospace
              ? const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)
              : GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.ink,
                ),
        ),
      ],
    );
  }
}
