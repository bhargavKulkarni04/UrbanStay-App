import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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
  State<OwnerRentCollectionScreen> createState() => _OwnerRentCollectionScreenState();
}

class _OwnerRentCollectionScreenState extends State<OwnerRentCollectionScreen> {
  String _selectedCycle = 'August 2026';
  String _selectedFloor = 'all'; // 'all', '1st', '2nd', '3rd', 'ground'
  String _selectedStatus = 'all'; // 'all', 'overdue', 'extension', 'paid'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Form Controllers for Record Cash Modal
  final TextEditingController _cashAmountController = TextEditingController();
  final TextEditingController _cashNotesController = TextEditingController();
  String _cashPaymentDate = '2026-08-18';

  // Form Controllers for Grant Extension Modal
  String _selectedExtensionDate = '15 Aug 2026';
  final TextEditingController _extensionReasonController = TextEditingController();

  // Active Target for Modals
  Map<String, dynamic> _activeCashTarget = {
    'name': 'Amit Verma',
    'room': '101-B',
    'outstanding': 8500,
  };

  Map<String, dynamic> _activeExtensionTarget = {
    'name': 'Deepak Joshi',
    'room': '301-A',
    'amount': 8500,
  };

  Map<String, dynamic> _activeReceiptTarget = {
    'name': 'Rahul Sharma',
    'room': '101-A',
    'amount': '₹8,500',
    'ref': '423189765412',
    'date': '1 Aug 2026',
  };

  String _activeViewMode = 'calendar'; // 'calendar' (Day-Wise Salary Calendar) or 'floor' (By Floor & Rooms)
  int _selectedCalendarDay = 5; // Default 5th of month
  String _selectedStaffActor = 'Ramesh Gowda (Manager)';
  final List<String> _staffActors = [
    'Ramesh Gowda (Manager)',
    'Arun Kumar (Co-Owner)',
    'Bhargav S Kulkarni (Owner)',
  ];

  // Master Floor, Room & Bed Hierarchy Data
  final List<Map<String, dynamic>> _floorsData = [
    // =========================================================================
    // 1ST FLOOR
    // =========================================================================
    {
      'id': '1st',
      'title': '1st Floor',
      'roomsSubtitle': 'Rooms 101 – 103 • 7 Beds',
      'rooms': [
        {
          'room': 'Room 101',
          'type': '2-Sharing',
          'monthlyExpected': 17000,
          'beds': [
            {
              'id': '1',
              'name': 'Rahul Sharma',
              'initials': 'RS',
              'bed': 'Bed 101-A',
              'room': '101-A',
              'roomNum': '101',
              'floor': '1st',
              'work': 'Infosys',
              'phone': '9876543210',
              'amount': 8500,
              'status': 'paid',
              'paidLabel': 'Paid on 1 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '423189765412',
              'paidDate': '1 Aug 2026',
            },
            {
              'id': '2',
              'name': 'Amit Verma',
              'initials': 'AV',
              'bed': 'Bed 101-B',
              'room': '101-B',
              'roomNum': '101',
              'floor': '1st',
              'work': 'Christ Univ',
              'phone': '9988776655',
              'amount': 8500,
              'status': 'overdue',
              'overdueDays': '3 Days Overdue',
              'dueLabel': 'Due since 15 Aug • All Utilities Included',
            },
          ],
        },
        {
          'room': 'Room 102',
          'type': '3-Sharing',
          'monthlyExpected': 22500,
          'beds': [
            {
              'id': '3',
              'name': 'Ananya Roy',
              'initials': 'AR',
              'bed': 'Bed 102-A',
              'room': '102-A',
              'roomNum': '102',
              'floor': '1st',
              'work': 'Accenture',
              'phone': '9822334455',
              'amount': 7500,
              'status': 'paid',
              'paidLabel': 'Paid on 2 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '110299384756',
              'paidDate': '2 Aug 2026',
            },
            {
              'id': '4',
              'isVacant': true,
              'bed': 'Bed 102-B',
              'room': '102-B',
              'roomNum': '102',
              'floor': '1st',
              'title': 'Vacant Bed — Available',
              'amount': 7500,
              'sub': 'Ready for Walk-In Tenant',
            },
            {
              'id': '5',
              'name': 'Vikram Rao',
              'initials': 'VR',
              'bed': 'Bed 102-C',
              'room': '102-C',
              'roomNum': '102',
              'floor': '1st',
              'work': 'TCS',
              'phone': '9733445566',
              'amount': 7500,
              'status': 'extension_approved',
              'extensionDate': '15 Aug 2026',
              'dueLabel': 'Extension Approved • Due 15 Aug',
              'extensionReason': 'Salary credited on 15th from TCS',
            },
          ],
        },
        {
          'room': 'Room 103',
          'type': '2-Sharing',
          'monthlyExpected': 17000,
          'beds': [
            {
              'id': '6',
              'name': 'Rohit Sen',
              'initials': 'RS',
              'bed': 'Bed 103-A',
              'room': '103-A',
              'roomNum': '103',
              'floor': '1st',
              'work': 'Wipro',
              'phone': '9811223344',
              'amount': 8500,
              'status': 'paid',
              'paidLabel': 'Paid on 1 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '994411223344',
              'paidDate': '1 Aug 2026',
            },
            {
              'id': '7',
              'name': 'Naveen Kumar',
              'initials': 'NK',
              'bed': 'Bed 103-B',
              'room': '103-B',
              'roomNum': '103',
              'floor': '1st',
              'work': 'Razorpay',
              'phone': '9844119988',
              'amount': 8500,
              'status': 'paid',
              'paidLabel': 'Paid on 3 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '883311224455',
              'paidDate': '3 Aug 2026',
            },
          ],
        },
      ],
    },

    // =========================================================================
    // 2ND FLOOR
    // =========================================================================
    {
      'id': '2nd',
      'title': '2nd Floor',
      'roomsSubtitle': 'Rooms 201 – 202 • 4 Beds',
      'rooms': [
        {
          'room': 'Room 201',
          'type': '2-Sharing',
          'monthlyExpected': 18000,
          'beds': [
            {
              'id': '8',
              'name': 'Karthik Raja',
              'initials': 'KR',
              'bed': 'Bed 201-A',
              'room': '201-A',
              'roomNum': '201',
              'floor': '2nd',
              'work': 'Swiggy',
              'phone': '9741234567',
              'amount': 9000,
              'status': 'paid',
              'paidLabel': 'Paid on 1 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '991200458812',
              'paidDate': '1 Aug 2026',
            },
            {
              'id': '9',
              'name': 'Priya Nair',
              'initials': 'PN',
              'bed': 'Bed 201-B',
              'room': '201-B',
              'roomNum': '201',
              'floor': '2nd',
              'work': 'Dell',
              'phone': '9819876543',
              'amount': 9000,
              'status': 'paid',
              'paidLabel': 'Paid on 3 Aug (Cash)',
              'tag': 'Cash Verified',
              'ref': 'CASH-REC-8902',
              'paidDate': '3 Aug 2026',
            },
          ],
        },
        {
          'room': 'Room 202',
          'type': '2-Sharing',
          'monthlyExpected': 15000,
          'beds': [
            {
              'id': '10',
              'name': 'Rohan Patil',
              'initials': 'RP',
              'bed': 'Bed 202-A',
              'room': '202-A',
              'roomNum': '202',
              'floor': '2nd',
              'work': 'Wipro',
              'phone': '9811223344',
              'amount': 7500,
              'status': 'overdue',
              'overdueDays': '5 Days Overdue',
              'dueLabel': 'Due since 13 Aug • All Utilities Included',
            },
            {
              'id': '11',
              'name': 'Sneha Reddy',
              'initials': 'SR',
              'bed': 'Bed 202-B',
              'room': '202-B',
              'roomNum': '202',
              'floor': '2nd',
              'work': 'Amazon',
              'phone': '9845009988',
              'amount': 7500,
              'status': 'paid',
              'paidLabel': 'Paid on 4 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '772288119933',
              'paidDate': '4 Aug 2026',
            },
          ],
        },
      ],
    },

    // =========================================================================
    // 3RD FLOOR
    // =========================================================================
    {
      'id': '3rd',
      'title': '3rd Floor',
      'roomsSubtitle': 'Rooms 301 – 302 • 4 Beds',
      'rooms': [
        {
          'room': 'Room 301',
          'type': '2-Sharing',
          'monthlyExpected': 17000,
          'beds': [
            {
              'id': '12',
              'name': 'Deepak Joshi',
              'initials': 'DJ',
              'bed': 'Bed 301-A',
              'room': '301-A',
              'roomNum': '301',
              'floor': '3rd',
              'work': 'Oracle',
              'phone': '9877112233',
              'amount': 8500,
              'status': 'extension_requested',
              'requestedDate': '15 Aug 2026',
              'dueLabel': 'Extension Requested till 15 Aug',
              'extensionReason': 'Salary delay from Oracle. Will pay full amount on 15th.',
            },
            {
              'id': '13',
              'name': 'Manisha Patel',
              'initials': 'MP',
              'bed': 'Bed 301-B',
              'room': '301-B',
              'roomNum': '301',
              'floor': '3rd',
              'work': 'IBM',
              'phone': '9866443322',
              'amount': 8500,
              'status': 'paid',
              'paidLabel': 'Paid on 2 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '554433221100',
              'paidDate': '2 Aug 2026',
            },
          ],
        },
        {
          'room': 'Room 302',
          'type': '2-Sharing',
          'monthlyExpected': 16000,
          'beds': [
            {
              'id': '14',
              'name': 'Aditya Sen',
              'initials': 'AS',
              'bed': 'Bed 302-A',
              'room': '302-A',
              'roomNum': '302',
              'floor': '3rd',
              'work': 'Razorpay',
              'phone': '9811883377',
              'amount': 8000,
              'status': 'paid',
              'paidLabel': 'Paid on 1 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '883399221100',
              'paidDate': '1 Aug 2026',
            },
            {
              'id': '15',
              'name': 'Pooja Hegde',
              'initials': 'PH',
              'bed': 'Bed 302-B',
              'room': '302-B',
              'roomNum': '302',
              'floor': '3rd',
              'work': 'Capgemini',
              'phone': '9833557799',
              'amount': 8000,
              'status': 'overdue',
              'overdueDays': '6 Days Overdue',
              'dueLabel': 'Due since 12 Aug • Utilities Included',
            },
          ],
        },
      ],
    },

    // =========================================================================
    // GROUND FLOOR
    // =========================================================================
    {
      'id': 'ground',
      'title': 'Ground Floor',
      'roomsSubtitle': 'Rooms G-01 – G-02 • 3 Beds',
      'rooms': [
        {
          'room': 'Room G-01',
          'type': '2-Sharing',
          'monthlyExpected': 16000,
          'beds': [
            {
              'id': '16',
              'name': 'Suresh Gowda',
              'initials': 'SG',
              'bed': 'Bed G-01-A',
              'room': 'G-01-A',
              'roomNum': 'G-01',
              'floor': 'ground',
              'work': 'Flipkart',
              'phone': '9844001122',
              'amount': 8000,
              'status': 'paid',
              'paidLabel': 'Paid on 2 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '338811229900',
              'paidDate': '2 Aug 2026',
            },
            {
              'id': '17',
              'name': 'Tanmay Bhat',
              'initials': 'TB',
              'bed': 'Bed G-01-B',
              'room': 'G-01-B',
              'roomNum': 'G-01',
              'floor': 'ground',
              'work': 'Freelance',
              'phone': '9855112233',
              'amount': 8000,
              'status': 'overdue',
              'overdueDays': '7 Days Overdue',
              'dueLabel': 'Due since 11 Aug • All Utilities Included',
            },
          ],
        },
        {
          'room': 'Room G-02',
          'type': '1-Sharing (Single)',
          'monthlyExpected': 8500,
          'beds': [
            {
              'id': '18',
              'name': 'Nikhil Kamath',
              'initials': 'NK',
              'bed': 'Bed G-02-A',
              'room': 'G-02-A',
              'roomNum': 'G-02',
              'floor': 'ground',
              'work': 'Zerodha',
              'phone': '9899001122',
              'amount': 8500,
              'status': 'paid',
              'paidLabel': 'Paid on 1 Aug (Direct UPI)',
              'tag': 'Settled 0% Fee',
              'ref': '990011223344',
              'paidDate': '1 Aug 2026',
            },
          ],
        },
      ],
    },
  ];

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
      tenant['extensionDate'] = tenant['requestedDate'] ?? '15 Aug 2026';
      tenant['dueLabel'] = 'Extension Approved • Due ${tenant['extensionDate']}';
    });
    _showToast('Extension Approved for ${tenant['name']} till ${tenant['extensionDate']} • Reminders paused ✓');
  }

  void _declineExtension(Map<String, dynamic> tenant) {
    setState(() {
      tenant['status'] = 'overdue';
      tenant['dueLabel'] = 'Extension Declined • Due Immediately';
    });
    _showToast('Extension Declined for ${tenant['name']}. Reminder sent on WhatsApp.');
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
              title: 'Record Payment: ${tenant['name']} (${tenant['bed']})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormLabel('Payment Mode'),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => paymentMode = 'cash'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: paymentMode == 'cash' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: paymentMode == 'cash'
                                    ? const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Cash Payment',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: paymentMode == 'cash' ? FontWeight.w800 : FontWeight.w600,
                                  color: paymentMode == 'cash' ? AppColors.ink : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => paymentMode = 'online'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: paymentMode == 'online' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: paymentMode == 'online'
                                    ? const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Paid Online (Direct UPI)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: paymentMode == 'online' ? FontWeight.w800 : FontWeight.w600,
                                  color: paymentMode == 'online' ? AppColors.greenDark : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Amount Received (₹)'),
                            _buildTextInput(_cashAmountController, keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Total Due (₹)'),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                '₹${tenant['amount']}',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (paymentMode == 'online') ...[
                    _buildFormLabel('UPI Ref / UTR (Optional)'),
                    _buildTextInput(utrController, hint: 'e.g. 423189765412 or GPay tick shown'),
                    const SizedBox(height: 12),
                  ],

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
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.ink),
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
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
                      final amountReceived = int.tryParse(_cashAmountController.text.trim()) ?? 0;
                      if (amountReceived <= 0) {
                        _showToast('Please enter a valid amount');
                        return;
                      }
                      Navigator.of(ctx).pop();
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] = paymentMode == 'cash'
                            ? 'Paid in Cash (Verified by $currentStaff)'
                            : 'Paid Online via Direct UPI (Verified by $currentStaff)';
                        tenant['tag'] = paymentMode == 'cash' ? 'Cash Verified' : 'Direct UPI';
                        tenant['ref'] = paymentMode == 'cash'
                            ? 'CSH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
                            : (utrController.text.trim().isNotEmpty
                                ? utrController.text.trim()
                                : 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
                        tenant['paidDate'] = '18 Aug 2026';
                        tenant['approvedBy'] = currentStaff;
                      });
                      _showToast('₹$amountReceived marked Paid for ${tenant['name']} (Verified by $currentStaff) ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm & Mark Paid',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
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
    final reasonCtrl = TextEditingController(text: 'Salary credited on ${selectedDay}th');

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
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
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
                            reasonCtrl.text = 'Salary credited on ${d}th of every month';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.greenLight : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? AppColors.green : const Color(0xFFE5E7EB),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '${d}th of Month',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? AppColors.greenDark : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _buildFormLabel('Reason / Notes'),
                  _buildTextInput(reasonCtrl, hint: 'e.g. Salary credited on 10th from employer'),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        tenant['payDay'] = selectedDay;
                        tenant['payDayReason'] = reasonCtrl.text.trim();
                      });
                      _showToast('Pay Date updated to ${selectedDay}th of month for ${tenant['name']} ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Move to ${selectedDay}th of Month',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
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
      'ref': tenant['ref'] ?? '423189765412',
      'date': tenant['paidDate'] ?? '1 Aug 2026',
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
                      'Greenview Luxury PG',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#42, 5th Cross, 4th Block, Koramangala, Bengaluru',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE5E7EB), height: 1),
                    const SizedBox(height: 12),

                    _buildReceiptRow('Tenant Name:', _activeReceiptTarget['name'], isBold: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Room / Bed:', 'Room ${_activeReceiptTarget['room']}'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Month / Period:', 'August 2026'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Amount Paid:', _activeReceiptTarget['amount'], isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Transaction Ref:', _activeReceiptTarget['ref'], isMonospace: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Date of Payment:', _activeReceiptTarget['date']),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                  _showToast('PDF Rent Receipt Downloaded & Shared on WhatsApp ✓');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Download PDF Receipt',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
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
                    _buildReceiptRow('Resident:', '${tenant['name']} (${tenant['bed']})', isBold: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Amount Claimed:', '₹${tenant['amount']}', isBold: true, valueColor: AppColors.greenDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Payment Mode:', 'Direct UPI / PhonePe'),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Submitted UTR / Ref:', tenant['ref'] ?? '423189765412', isMonospace: true),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Submission Time:', '1 Aug 2026, 09:30 AM'),
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
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please verify that ₹${tenant['amount']} was credited to your HDFC/SBI bank account before accepting.',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
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
                        _showToast('Payment marked as Not Received. WhatsApp notification sent to ${tenant['name']}');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Reject (Not in Bank)',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          tenant['status'] = 'paid';
                          tenant['paidLabel'] = 'Paid Early on 1 Aug (Verified by $_selectedStaffActor)';
                          tenant['tag'] = 'Direct UPI';
                          tenant['ref'] = 'UTR-423189765412';
                          tenant['paidDate'] = '1 Aug 2026';
                          tenant['approvedBy'] = _selectedStaffActor;
                        });
                        _showToast('Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept & Mark Paid',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final allOccupied = _getAllOccupiedTenants();
    final overdueCount = allOccupied.where((t) => t['status'] == 'overdue').length;
    final extensionCount = allOccupied.where((t) => t['status'] == 'extension_requested' || t['status'] == 'extension_approved').length;
    final paidCount = allOccupied.where((t) => t['status'] == 'paid').length;
    final overdueSum = allOccupied
        .where((t) => t['status'] == 'overdue' || t['status'] == 'extension_requested' || t['status'] == 'extension_approved')
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
                    _buildStatusFilterChips(overdueCount, extensionCount, paidCount),
                    const SizedBox(height: 12),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 16),

                    // 3-TIER HIERARCHY: Floor -> Room (Sharing Type) -> Bed Cards
                    ..._floorsData
                        .where((f) => _selectedFloor == 'all' || _selectedFloor == f['id'])
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
                    'Rent Collection',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Greenview PG • 31 Beds',
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
                value: _selectedCycle,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                items: const [
                  DropdownMenuItem(value: 'August 2026', child: Text('August 2026')),
                  DropdownMenuItem(value: 'July 2026', child: Text('July 2026')),
                  DropdownMenuItem(value: 'June 2026', child: Text('June 2026')),
                ],
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
    return Row(
      children: [
        Expanded(child: _buildStatTile('₹2,63,500', 'Total Expected', const Color(0xFF2563EB))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatTile('₹2,12,000', 'Collected (81%)', AppColors.greenDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatTile('₹$overdueSum', '$totalPendingCount Pending/Ext', AppColors.danger)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$overdueCount Overdue (Extensions Paused)',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Send 1-tap WhatsApp payment links',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _showToast('WhatsApp Payment Reminders sent to $overdueCount Overdue Residents ✓'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Remind All',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
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
                  color: _activeViewMode == 'calendar' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeViewMode == 'calendar'
                      ? const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 15,
                      color: _activeViewMode == 'calendar' ? AppColors.greenDark : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Salary Date Calendar',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: _activeViewMode == 'calendar' ? FontWeight.w800 : FontWeight.w600,
                        color: _activeViewMode == 'calendar' ? AppColors.greenDark : AppColors.muted,
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
                  color: _activeViewMode == 'floor' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeViewMode == 'floor'
                      ? const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 15,
                      color: _activeViewMode == 'floor' ? AppColors.ink : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'By Floor & Rooms',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: _activeViewMode == 'floor' ? FontWeight.w800 : FontWeight.w600,
                        color: _activeViewMode == 'floor' ? AppColors.ink : AppColors.muted,
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

    final dayTotalExpected = selectedTenants.fold<int>(0, (sum, t) => sum + (t['amount'] as int));
    final dayPaidCount = selectedTenants.where((t) => t['status'] == 'paid').length;
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
              final count = allOccupied.where((t) => ((t['payDay'] as int?) ?? 5) == d).length;
              final isSel = _selectedCalendarDay == d;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedCalendarDay = d),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.green : const Color(0xFFE5E7EB),
                        width: isSel ? 1.5 : 1.0,
                      ),
                      boxShadow: isSel
                          ? const [BoxShadow(color: Color(0x1808A63F), blurRadius: 6, offset: Offset(0, 2))]
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF3F4F6),
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
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                  ),
                  Text(
                    '₹$dayTotalExpected Expected',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.greenDark),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedTenants.length} Tenants • $dayPaidCount Paid • $dayPendingCount Pending for today',
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.muted),
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
                const Icon(Icons.event_available_outlined, size: 32, color: AppColors.muted),
                const SizedBox(height: 8),
                Text(
                  'No tenants scheduled for ${_selectedCalendarDay}th',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...selectedTenants.map((tenant) => _buildCalendarTenantCard(tenant)).toList(),
      ],
    );
  }

  // ===========================================================================
  // 3D. CALENDAR TENANT CARD (With 2-Row Horizontal Actions & Attribution)
  // ===========================================================================
  Widget _buildCalendarTenantCard(Map<String, dynamic> tenant) {
    final isPaid = tenant['status'] == 'paid';
    final isOverdue = tenant['status'] == 'overdue';
    final isExt = tenant['status'] == 'extension_requested' || tenant['status'] == 'extension_approved';
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
                      color: isPaid ? AppColors.greenLight : const Color(0xFFF3F4F6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  isPaid ? Icons.verified_user_outlined : Icons.schedule_rounded,
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
                  onPressed: () => _showToast('Dialing +91 ${tenant['phone'] ?? '9876543210'}...'),
                  icon: const Icon(Icons.phone_outlined, size: 14, color: AppColors.ink),
                  label: Text(
                    'Call',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showToast('WhatsApp Chat opened with ${tenant['name']} (+91 ${tenant['phone'] ?? '9876543210'}) ✓'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    icon: const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.greenDark),
                    label: Text(
                      'View Receipt',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.greenDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                      side: BorderSide(color: AppColors.green.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChangePayDateModal(tenant),
                    icon: const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                    label: Text(
                      'Change Date',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 13, color: AppColors.ink),
                    label: Text(
                      'View Proof',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showToast('Payment rejected: Not received in owner bank account. Alert sent to ${tenant['name']}');
                    },
                    icon: const Icon(Icons.close_rounded, size: 13, color: Color(0xFFDC2626)),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        tenant['status'] = 'paid';
                        tenant['paidLabel'] = 'Paid Early on 1 Aug (Verified by $_selectedStaffActor)';
                        tenant['tag'] = 'Direct UPI';
                        tenant['ref'] = 'UTR-423189765412';
                        tenant['paidDate'] = '1 Aug 2026';
                        tenant['approvedBy'] = _selectedStaffActor;
                      });
                      _showToast('Payment of ₹${tenant['amount']} Accepted by $_selectedStaffActor for ${tenant['name']} ✓');
                    },
                    icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    label: Text(
                      'Accept',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
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
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
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
  Widget _buildStatusFilterChips(int overdueCount, int extensionCount, int paidCount) {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
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
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search resident by name, room 101, or workplace...',
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
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

      if (_selectedStatus == 'overdue' && b['status'] != 'overdue') return false;
      if (_selectedStatus == 'extension' && (b['status'] != 'extension_requested' && b['status'] != 'extension_approved')) return false;
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
          // Room Header Row: Room 101 • 2-Sharing • Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                  const SizedBox(width: 8),
                  Text(
                    '${roomData['type']} • ₹${roomData['monthlyExpected']}/mo',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),

              // Occupancy / Payment Progress Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: totalOverdue > 0 ? const Color(0xFFFEF2F2) : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  totalOverdue > 0 ? '$totalOverdue Overdue' : '$totalPaid/$totalOccupied Paid',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: totalOverdue > 0 ? AppColors.danger : AppColors.greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 10),

          // Level 3: Bed & Resident Cards inside this Room
          ...filteredBeds.map((b) => b['isVacant'] == true ? _buildVacantBedCard(b) : _buildBedResidentCard(b)),
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
              : (isExtApproved ? const Color(0xFFE5E7EB) : const Color(0xFFEEF0F2)),
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
                          : (isExtRequested || isExtApproved ? const Color(0xFFFFFBEB) : const Color(0xFFFFFFFF)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPaid
                            ? AppColors.green.withValues(alpha: 0.25)
                            : (isExtRequested ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB)),
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
                              : (isExtRequested || isExtApproved ? const Color(0xFF92400E) : AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name & Bed Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            tenant['bed'],
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '• ${tenant['work']}',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Status Pill on Top-Right (Clean Family Colors)
              _buildStatusPillBadge(status, tenant),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Rent Amount & Due Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFFFFFFF) : const Color(0xFFFFFDFD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPaid ? const Color(0xFFE5E7EB) : const Color(0xFFFEE2E2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${tenant['amount']} / month',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isPaid ? AppColors.greenDark : (isExtRequested || isExtApproved ? const Color(0xFF92400E) : AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tenant['dueLabel'] ?? tenant['paidLabel'] ?? 'Due on 15 Aug',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isPaid ? AppColors.muted : (isExtRequested || isExtApproved ? const Color(0xFF92400E) : AppColors.danger),
                      ),
                    ),
                  ],
                ),
                if (tenant['tag'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tenant['tag'],
                      style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.greenDark),
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
                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${tenant['extensionReason'] ?? 'Requested payment extension till 15th.'}',
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
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
              // [ 📞 Call ]
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Calling ${tenant['name']}: +91${tenant['phone']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text(
                          'Call',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // [ 💬 WhatsApp ]
              Expanded(
                child: InkWell(
                  onTap: () => _showToast('WhatsApp opened with ${tenant['name']} (+91${tenant['phone']})'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.greenLight : AppColors.green,
                      borderRadius: BorderRadius.circular(8),
                      border: isPaid ? Border.all(color: AppColors.green.withValues(alpha: 0.25)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: isPaid ? AppColors.greenDark : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPaid ? 'WhatsApp' : 'Send Link',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isPaid ? AppColors.greenDark : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Secondary Action Row (Specific to status)
          if (isExtRequested) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _declineExtension(tenant),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Center(
                        child: Text(
                          '✕ Decline',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.danger),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _approveExtension(tenant),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '✓ Approve (${tenant['requestedDate'] ?? '15 Aug'})',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isOverdue) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openRecordCashModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Text(
                    '+ Record Cash / Partial Payment',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ] else if (isExtApproved) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openRecordCashModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Text(
                    '+ Record Cash / Partial Payment',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ] else if (isPaid) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openReceiptModal(tenant),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 14, color: AppColors.ink),
                    const SizedBox(width: 5),
                    Text(
                      'View Stamped PDF Receipt',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
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
        border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                child: const Icon(Icons.single_bed_outlined, size: 16, color: AppColors.muted),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bed['title'] ?? 'Vacant Bed',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    '₹${bed['amount']}/mo • Ready for Walk-In',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: () => _showToast('Opening Bed ${bed['room']} Onboarding'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                '+ Assign',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
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
          border: Border.all(color: AppColors.green.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Paid', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
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
            Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Requested 15 Aug', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
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
            Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: Color(0xFF92400E), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('Extended (15 Aug)', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
            Container(width: 4.5, height: 4.5, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(tenant['overdueDays'] ?? 'Overdue', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
          ],
        ),
      );
    }
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

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
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
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted)),
        Text(
          value,
          style: isMonospace
              ? const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)
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
