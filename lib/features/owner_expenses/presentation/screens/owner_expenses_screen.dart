import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen 10: Operating Costs, Grocery Rations & Monthly Expense Ledger.
/// Strict Design System:
/// - Focused Monthly Expenses Summary: Total Spent on Expenses (e.g. ₹68,400 across 6 bills).
/// - Premium Vector Icons: Bolt, Restaurant/Kitchen, Water drop, Staff badge, Handyman, WiFi, Receipt.
/// - Log Expense Sheet with "+ Other (Custom)" category manual text input.
/// - Live instant Search & Filter chips by category.
/// - Pure white elevated cards (#FFFFFF), soft hairline borders (#E5E7EB), zero harsh colors.
/// - Zero Emojis (pure native vector icons & Outfit typography).
/// - 100% Zero Overflow protection with Expanded & Flexible.
class OwnerExpensesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerExpensesScreen({super.key, this.onBack});

  @override
  State<OwnerExpensesScreen> createState() => _OwnerExpensesScreenState();
}

class _OwnerExpensesScreenState extends State<OwnerExpensesScreen> {
  String _selectedMonth = 'August 2026';
  String _selectedCategoryFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  // Log Modal State
  String _selectedModalCat = 'Electricity';
  bool _isCustomCategory = false;
  final TextEditingController _customCatController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: '28 Aug 2026');
  String _selectedPayMode = 'UPI'; // 'UPI', 'Cash'
  String? _attachedBillName;

  // Photo Viewer Modal Target
  Map<String, dynamic>? _activeReceiptTarget;

  // Master Expenses Ledger
  final List<Map<String, dynamic>> _expenses = [
    {
      'id': 'EXP-101',
      'title': 'Electricity Bill',
      'category': 'Electricity',
      'icon': Icons.bolt_rounded,
      'vendor': 'BESCOM Karnataka • Meter #48921 (3 Floors)',
      'amount': 24500,
      'date': '15 Aug 2026',
      'mode': 'Direct Bank Transfer',
      'ref': 'Ref: TXN99120',
      'receiptFile': 'bescom_bill_aug2026.pdf',
      'hasReceipt': true,
    },
    {
      'id': 'EXP-102',
      'title': 'Kitchen Groceries & Ration',
      'category': 'Kitchen',
      'icon': Icons.restaurant_rounded,
      'vendor': 'Annapurna Stores • Monthly Rice, Dal & Oil Supplies',
      'amount': 18200,
      'date': '12 Aug 2026',
      'mode': 'Direct UPI',
      'ref': 'Ref: UPI-RATION-88',
      'receiptFile': 'annapurna_grocery_bill.jpg',
      'hasReceipt': true,
    },
    {
      'id': 'EXP-103',
      'title': 'Cook & Warden Salaries',
      'category': 'Salary',
      'icon': Icons.badge_outlined,
      'vendor': 'Monthly Payroll • 2 Staff Members',
      'amount': 15000,
      'date': '01 Aug 2026',
      'mode': 'Bank Transfer',
      'ref': 'Salary Vouchers Acknowledged',
      'receiptFile': 'salary_voucher_aug.pdf',
      'hasReceipt': true,
    },
    {
      'id': 'EXP-104',
      'title': 'Water Tankers (4 Trips)',
      'category': 'Water',
      'icon': Icons.water_drop_rounded,
      'vendor': 'Kaveri Water Supplies • 6000L x 4 Trips',
      'amount': 4800,
      'date': '10 Aug 2026',
      'mode': 'Cash (Petty Cash)',
      'ref': 'Receipt Signed by Driver',
      'receiptFile': 'water_tanker_slips.jpg',
      'hasReceipt': true,
    },
    {
      'id': 'EXP-105',
      'title': 'Plumbing & Tap Replacements',
      'category': 'Repair',
      'icon': Icons.handyman_rounded,
      'vendor': 'Sridhar Plumber • Room 102 & 201 Washroom Repairs',
      'amount': 3400,
      'date': '08 Aug 2026',
      'mode': 'Cash',
      'ref': 'Work Completed & Verified',
      'receiptFile': 'hardware_store_receipt.jpg',
      'hasReceipt': true,
    },
    {
      'id': 'EXP-106',
      'title': 'High-Speed Wi-Fi (300 Mbps)',
      'category': 'WiFi',
      'icon': Icons.wifi_rounded,
      'vendor': 'ACT Fibernet • Commercial Account #889214',
      'amount': 2499,
      'date': '05 Aug 2026',
      'mode': 'Direct UPI',
      'ref': 'Paid (Auto-Debit)',
      'receiptFile': 'act_invoice_aug2026.pdf',
      'hasReceipt': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _customCatController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _dateController.dispose();
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

  int get _totalSpent => _expenses.fold<int>(0, (sum, item) => sum + (item['amount'] as int));

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('elect')) return Icons.bolt_rounded;
    if (lower.contains('kitch') || lower.contains('food') || lower.contains('ration')) return Icons.restaurant_rounded;
    if (lower.contains('water')) return Icons.water_drop_rounded;
    if (lower.contains('sal') || lower.contains('staff') || lower.contains('warden')) return Icons.badge_outlined;
    if (lower.contains('repair') || lower.contains('plumb') || lower.contains('maint')) return Icons.handyman_rounded;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    return Icons.receipt_rounded;
  }

  // ===========================================================================
  // MODAL: LOG NEW PG EXPENSE (With "+ Other" custom category text input)
  // ===========================================================================
  void _openLogExpenseModal() {
    _selectedModalCat = 'Electricity';
    _isCustomCategory = false;
    _customCatController.clear();
    _titleController.clear();
    _amountController.clear();
    _vendorController.clear();
    _dateController.text = '28 Aug 2026';
    _selectedPayMode = 'UPI';
    _attachedBillName = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Log New PG Expense',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Selector Chips
                  _buildFormLabel('Expense Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalCatChip('Electricity', Icons.bolt_rounded, setModalState),
                      _buildModalCatChip('Kitchen / Ration', Icons.restaurant_rounded, setModalState),
                      _buildModalCatChip('Water Tanker', Icons.water_drop_rounded, setModalState),
                      _buildModalCatChip('Staff Salary', Icons.badge_outlined, setModalState),
                      _buildModalCatChip('Repairs', Icons.handyman_rounded, setModalState),
                      _buildModalCatChip('WiFi / Misc', Icons.wifi_rounded, setModalState),
                      _buildModalCatChip('+ Other (Custom)', Icons.add_circle_outline_rounded, setModalState, isCustom: true),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Inline Custom Category Input (If + Other selected)
                  if (_isCustomCategory) ...[
                    _buildFormLabel('Enter Custom Category Name'),
                    _buildTextInput(
                      _customCatController,
                      hint: 'e.g. Diesel Generator, Pest Control, Waste Disposal',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title / Item Description
                  _buildFormLabel('Expense Title / Description'),
                  _buildTextInput(
                    _titleController,
                    hint: 'e.g. Kaveri Water Tankers (2 Trips)',
                  ),
                  const SizedBox(height: 12),

                  // Amount & Date Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Amount (₹)'),
                            _buildTextInput(
                              _amountController,
                              hint: '₹ Amount',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Date'),
                            _buildTextInput(_dateController, hint: 'Date'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Paid To / Vendor Name
                  _buildFormLabel('Paid To / Vendor Name'),
                  _buildTextInput(
                    _vendorController,
                    hint: 'e.g. Kaveri Water Supplies / Annapurna Stores',
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode Toggle: Direct UPI / Bank vs Cash
                  _buildFormLabel('Payment Mode'),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => _selectedPayMode = 'UPI'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _selectedPayMode == 'UPI' ? AppColors.greenLight : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedPayMode == 'UPI' ? AppColors.green : const Color(0xFFE5E7EB),
                                width: _selectedPayMode == 'UPI' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 15,
                                  color: _selectedPayMode == 'UPI' ? AppColors.greenDark : AppColors.ink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Direct UPI / Bank',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: _selectedPayMode == 'UPI' ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedPayMode == 'UPI' ? AppColors.greenDark : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => _selectedPayMode = 'Cash'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: _selectedPayMode == 'Cash' ? AppColors.greenLight : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedPayMode == 'Cash' ? AppColors.green : const Color(0xFFE5E7EB),
                                width: _selectedPayMode == 'Cash' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 15,
                                  color: _selectedPayMode == 'Cash' ? AppColors.greenDark : AppColors.ink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cash / Petty Cash',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: _selectedPayMode == 'Cash' ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedPayMode == 'Cash' ? AppColors.greenDark : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bill Slip Photo Attachment
                  _buildFormLabel('Bill / Invoice Slip Photo'),
                  InkWell(
                    onTap: () {
                      setModalState(() {
                        _attachedBillName = 'bill_receipt_${DateTime.now().millisecondsSinceEpoch % 1000}.jpg';
                      });
                      _showToast('Bill photo receipt attached ✓');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _attachedBillName != null ? AppColors.green : const Color(0xFFE5E7EB),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _attachedBillName != null ? Icons.check_circle_outline_rounded : Icons.camera_alt_outlined,
                            size: 16,
                            color: _attachedBillName != null ? AppColors.greenDark : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _attachedBillName ?? 'Tap to Attach Bill Photo / Camera',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _attachedBillName != null ? AppColors.greenDark : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final amountStr = _amountController.text.trim();
                      final vendor = _vendorController.text.trim();

                      if (title.isEmpty || amountStr.isEmpty) {
                        _showToast('Please enter expense title and amount');
                        return;
                      }

                      final amount = int.tryParse(amountStr.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
                      final finalCat = _isCustomCategory && _customCatController.text.trim().isNotEmpty
                          ? _customCatController.text.trim()
                          : _selectedModalCat.split(' / ')[0];

                      Navigator.of(ctx).pop();
                      setState(() {
                        _expenses.insert(0, {
                          'id': 'EXP-${DateTime.now().millisecondsSinceEpoch % 1000}',
                          'title': title,
                          'category': finalCat,
                          'icon': _getCategoryIcon(finalCat),
                          'vendor': vendor.isNotEmpty ? vendor : 'Direct Expense',
                          'amount': amount,
                          'date': _dateController.text.trim(),
                          'mode': _selectedPayMode == 'UPI' ? 'Direct UPI / Bank' : 'Cash (Petty Cash)',
                          'ref': 'Saved to Ledger',
                          'receiptFile': _attachedBillName ?? 'invoice_receipt.pdf',
                          'hasReceipt': _attachedBillName != null,
                        });
                      });
                      _showToast('₹${amount.toString()} logged under $finalCat ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Expense to Ledger',
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
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

  Widget _buildModalCatChip(String label, IconData icon, StateSetter setModalState, {bool isCustom = false}) {
    final isSelected = isCustom ? _isCustomCategory : (!_isCustomCategory && _selectedModalCat == label);

    return InkWell(
      onTap: () {
        setModalState(() {
          if (isCustom) {
            _isCustomCategory = true;
          } else {
            _isCustomCategory = false;
            _selectedModalCat = label;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.inkSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL: VIEW RECEIPT PHOTO PREVIEW
  // ===========================================================================
  void _openReceiptModal(Map<String, dynamic> expense) {
    _activeReceiptTarget = expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Bill Invoice Proof',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(expense['icon'] as IconData, size: 48, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(
                      expense['receiptFile'] ?? 'bill_receipt.pdf',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${(expense['amount'] as int).toString()} • Verified in Expense Ledger',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Expense Item',
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                '${expense['title']} — ${expense['vendor']}',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, height: 1.4),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Close Preview',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _expenses.where((item) {
      if (_selectedCategoryFilter != 'all') {
        final cat = (item['category'] as String).toLowerCase();
        if (!cat.contains(_selectedCategoryFilter)) return false;
      }
      if (query.isNotEmpty) {
        final title = (item['title'] as String).toLowerCase();
        final vendor = (item['vendor'] as String).toLowerCase();
        if (!title.contains(query) && !vendor.contains(query)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogExpenseModal,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
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
                    // Total Spent on Expenses Card
                    _buildTotalSpentCard(),
                    const SizedBox(height: 12),

                    // Monthly Expense Statement & CA Export Banner
                    _buildCaExportBanner(),
                    const SizedBox(height: 14),

                    // Category Filter Chips
                    _buildCategoryFilterChips(),
                    const SizedBox(height: 12),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 14),

                    // Expense Cards Stack
                    if (filtered.isEmpty)
                      _buildEmptyState('No expenses found matching your filter.')
                    else
                      ...filtered.map((e) => _buildExpenseCard(e)).toList(),
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
                    'PG Expenses & Costs',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Greenview PG • Operating Ledger',
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

          // Cycle Selector Dropdown Pill
          InkWell(
            onTap: () {
              setState(() {
                _selectedMonth = _selectedMonth == 'August 2026' ? 'July 2026' : 'August 2026';
              });
              _showToast('Switched ledger cycle to $_selectedMonth');
            },
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedMonth,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. TOTAL SPENT ON EXPENSES CARD (Clean Focused Summary)
  // ===========================================================================
  Widget _buildTotalSpentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Spent This Month',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${_totalSpent.toString()}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),

          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '${_expenses.length} Recorded Bills',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. CA EXPORT BANNER
  // ===========================================================================
  Widget _buildCaExportBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Expense Statement',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    'Itemized GST invoices ready for audit',
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),

          InkWell(
            onTap: () => _showToast('Generating CA Tax & Expense Statement (Excel & PDF)... Downloaded ✓'),
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
                  const Icon(Icons.download_rounded, size: 13, color: AppColors.ink),
                  const SizedBox(width: 4),
                  Text(
                    'Export CA',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
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
  // 4. CATEGORY FILTER CHIPS
  // ===========================================================================
  Widget _buildCategoryFilterChips() {
    final categories = [
      {'id': 'all', 'label': 'All (6)'},
      {'id': 'elect', 'label': 'Electricity'},
      {'id': 'kitch', 'label': 'Kitchen & Ration'},
      {'id': 'water', 'label': 'Water Tankers'},
      {'id': 'sal', 'label': 'Staff Salaries'},
      {'id': 'repair', 'label': 'Repairs'},
      {'id': 'wifi', 'label': 'WiFi & Utilities'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategoryFilter == c['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategoryFilter = c['id']!);
                _showToast('Filtering by ${c['label']}');
              },
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.ink : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  c['label']!,
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
  // 5. SEARCH BOX
  // ===========================================================================
  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search by vendor, bill or item...',
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
          suffixIcon: _searchController.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. EXPENSE CARD
  // ===========================================================================
  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
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
          // Top Row: 44px Icon + Title & Vendor + Amount & Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Icon(expense['icon'] as IconData, size: 22, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Vendor (Wrapped in Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expense['vendor'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount & Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(expense['amount'] as int).toString()}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense['date'],
                    style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment Mode & Audit Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mode: ${expense['mode']}',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSecondary),
                ),
                Text(
                  expense['ref'] ?? 'Verified',
                  style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.greenDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons: View Bill Slip + Edit
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openReceiptModal(expense),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_outlined, size: 14, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text(
                          'View Bill Slip',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: InkWell(
                  onTap: () => _showToast('Editing ${expense['title']}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'Edit Expense',
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.inkSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 38, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE NATIVE BOTTOM SHEET WRAPPER
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
}
