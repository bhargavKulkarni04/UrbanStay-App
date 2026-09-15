import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Screen 11: Staff Directory & Payroll Management.
/// Strict Design System:
/// - Executive Enterprise Palette: Ink #111111, Green #08A63F, GreenDark #068237, Warm Gold #92400E, Border #E5E7EB.
/// - 100% Zero Emojis (pure native vector icons & Outfit typography).
/// - 100% Zero Vibe-Coded Colors (zero purple, neon, or artificial dark gradients).
/// - Side-by-Side [ 📞 Call ] and [ 💬 WhatsApp ] contact ergonomics.
/// - 1-Tap Salary Approval with instant status update.
/// - Add Staff Modal with "+ Other (Custom Role)" manual text input.
/// - Live instant Search and Role Filter Chips.
class OwnerStaffScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerStaffScreen({super.key, this.onBack});

  @override
  State<OwnerStaffScreen> createState() => _OwnerStaffScreenState();
}

class _OwnerStaffScreenState extends State<OwnerStaffScreen> {
  String _selectedRoleFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  // Add Staff Modal State
  String _selectedModalRole = 'Warden';
  bool _isCustomRole = false;
  final TextEditingController _customRoleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _workTitleController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Master Staff Directory List
  final List<Map<String, dynamic>> _staffList = [
    {
      'id': 'STF-101',
      'name': 'Suresh Kumar',
      'initials': 'SK',
      'role': 'warden',
      'workTitle': 'Warden & Operations Manager',
      'phone': '9845122334',
      'salary': 18000,
      'month': 'August Salary',
      'status': 'paid', // 'paid', 'pending'
      'joinedDate': 'Jan 2024',
    },
    {
      'id': 'STF-102',
      'name': 'Ramesh Chand',
      'initials': 'RC',
      'role': 'cook',
      'workTitle': 'Head Cook',
      'phone': '9880144556',
      'salary': 16000,
      'month': 'August Salary',
      'status': 'pending',
      'joinedDate': 'Mar 2024',
    },
    {
      'id': 'STF-103',
      'name': 'Manjula Devi',
      'initials': 'MD',
      'role': 'housekeeping',
      'workTitle': 'Housekeeping & Cleaning',
      'phone': '9741288990',
      'salary': 10000,
      'month': 'August Salary',
      'status': 'paid',
      'joinedDate': 'Feb 2024',
    },
    {
      'id': 'STF-104',
      'name': 'Narayana Swamy',
      'initials': 'NS',
      'role': 'security',
      'workTitle': 'Night Security Guard',
      'phone': '9611033221',
      'salary': 12000,
      'month': 'August Salary',
      'status': 'pending',
      'joinedDate': 'May 2024',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _customRoleController.dispose();
    _nameController.dispose();
    _workTitleController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
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

  int get _totalPayroll => _staffList.fold<int>(0, (sum, s) => sum + (s['salary'] as int));
  int get _pendingPayroll => _staffList
      .where((s) => s['status'] == 'pending')
      .fold<int>(0, (sum, s) => sum + (s['salary'] as int));

  void _approveSalary(Map<String, dynamic> staff) {
    setState(() {
      staff['status'] = 'paid';
    });
    _showToast('₹${(staff['salary'] as int).toString()} Salary Approved for ${staff['name']} • Recorded in PG Expenses');
  }

  // ===========================================================================
  // MODAL: ADD NEW STAFF (With "+ Other" custom role entry)
  // ===========================================================================
  void _openAddStaffModal() {
    _selectedModalRole = 'Warden';
    _isCustomRole = false;
    _customRoleController.clear();
    _nameController.clear();
    _workTitleController.clear();
    _salaryController.clear();
    _phoneController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Add New Staff Member',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Selector Chips
                  _buildFormLabel('Staff Category / Role'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalRoleChip('Warden', Icons.badge_outlined, setModalState),
                      _buildModalRoleChip('Cook', Icons.restaurant_rounded, setModalState),
                      _buildModalRoleChip('Housekeeping', Icons.cleaning_services_outlined, setModalState),
                      _buildModalRoleChip('Security', Icons.shield_outlined, setModalState),
                      _buildModalRoleChip('+ Other (Custom)', Icons.add_circle_outline_rounded, setModalState, isCustom: true),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Inline Custom Role Input (If + Other selected)
                  if (_isCustomRole) ...[
                    _buildFormLabel('Enter Custom Role Name'),
                    _buildTextInput(
                      _customRoleController,
                      hint: 'e.g. Electrician, Plumber, Gardener, Driver',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Full Legal Name
                  _buildFormLabel('Full Name'),
                  _buildTextInput(_nameController, hint: 'e.g. Rajesh Kumar'),
                  const SizedBox(height: 12),

                  // Work Title
                  _buildFormLabel('Designation / Work Title'),
                  _buildTextInput(_workTitleController, hint: 'e.g. Assistant Cook / Day Cleaner'),
                  const SizedBox(height: 12),

                  // Monthly Salary & Phone Number Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormLabel('Monthly Salary (₹)'),
                            _buildTextInput(
                              _salaryController,
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
                            _buildFormLabel('Phone Number'),
                            _buildTextInput(
                              _phoneController,
                              hint: '10-digit Mobile',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final workTitle = _workTitleController.text.trim();
                      final salaryStr = _salaryController.text.trim();
                      final phone = _phoneController.text.trim();

                      if (name.isEmpty || salaryStr.isEmpty || phone.isEmpty) {
                        _showToast('Please fill all required fields');
                        return;
                      }

                      final salary = int.tryParse(salaryStr.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
                      final roleKey = _isCustomRole && _customRoleController.text.trim().isNotEmpty
                          ? _customRoleController.text.trim().toLowerCase()
                          : _selectedModalRole.toLowerCase();

                      final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join('').toUpperCase();

                      Navigator.of(ctx).pop();
                      setState(() {
                        _staffList.insert(0, {
                          'id': 'STF-${DateTime.now().millisecondsSinceEpoch % 1000}',
                          'name': name,
                          'initials': initials.length > 2 ? initials.substring(0, 2) : initials,
                          'role': roleKey,
                          'workTitle': workTitle.isNotEmpty ? workTitle : _selectedModalRole,
                          'phone': phone,
                          'salary': salary,
                          'month': 'August Salary',
                          'status': 'pending',
                          'joinedDate': 'Today',
                        });
                      });
                      _showToast('$name added to Staff Directory ✓');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Staff Member',
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

  Widget _buildModalRoleChip(String label, IconData icon, StateSetter setModalState, {bool isCustom = false}) {
    final isSelected = isCustom ? _isCustomRole : (!_isCustomRole && _selectedModalRole == label);

    return InkWell(
      onTap: () {
        setModalState(() {
          if (isCustom) {
            _isCustomRole = true;
          } else {
            _isCustomRole = false;
            _selectedModalRole = label;
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

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _staffList.where((s) {
      if (_selectedRoleFilter != 'all') {
        final role = (s['role'] as String).toLowerCase();
        if (!role.contains(_selectedRoleFilter)) return false;
      }
      if (query.isNotEmpty) {
        final name = (s['name'] as String).toLowerCase();
        final title = (s['workTitle'] as String).toLowerCase();
        if (!name.contains(query) && !title.contains(query)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStaffModal,
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
                    // 3-Pill Payroll Summary Strip
                    _buildPayrollStatsStrip(),
                    const SizedBox(height: 14),

                    // Role Filter Chips
                    _buildRoleFilterChips(),
                    const SizedBox(height: 12),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 14),

                    // Staff Cards Stack
                    if (filtered.isEmpty)
                      _buildEmptyState('No staff members found matching your search.')
                    else
                      ...filtered.map((s) => _buildStaffCard(s)).toList(),
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
                    'Staff & Payroll',
                    style: GoogleFonts.outfit(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Greenview PG • ${_staffList.length} Active Staff',
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

          // Add Staff Header Button
          InkWell(
            onTap: _openAddStaffModal,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Add Staff',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
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
  // 2. 3-PILL PAYROLL STATS STRIP
  // ===========================================================================
  Widget _buildPayrollStatsStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile('${_staffList.length} Staff', 'Active Team', AppColors.ink),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile('₹${_totalPayroll.toString()}', 'Monthly Payroll', AppColors.ink),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile('₹${_pendingPayroll.toString()}', 'Pending Payout', const Color(0xFF92400E)),
        ),
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
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
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
  // 3. ROLE FILTER CHIPS
  // ===========================================================================
  Widget _buildRoleFilterChips() {
    final roles = [
      {'id': 'all', 'label': 'All Staff (${_staffList.length})'},
      {'id': 'warden', 'label': 'Warden'},
      {'id': 'cook', 'label': 'Cook'},
      {'id': 'housekeeping', 'label': 'Housekeeping'},
      {'id': 'security', 'label': 'Security'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: roles.map((r) {
          final isSelected = _selectedRoleFilter == r['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedRoleFilter = r['id']!);
                _showToast('Filtering by ${r['label']}');
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
                  r['label']!,
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
  // 4. SEARCH BOX
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
          hintText: 'Search staff by name or role...',
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
  // 5. STAFF CARD (Clean Elevated White Card, Zero Overflow, Side-by-Side Call & WA)
  // ===========================================================================
  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final isPaid = staff['status'] == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          // Top Row: Avatar + Name & Work Title + Direct Call/WA buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 44px Avatar Circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    staff['initials'] ?? 'SK',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Staff Details (Wrapped in Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff['workTitle'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Side-by-Side Call & WA Quick Action Buttons
              Row(
                children: [
                  InkWell(
                    onTap: () => _showToast('Calling ${staff['name']}: +91${staff['phone']}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.phone_outlined, size: 15, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showToast('WhatsApp opened with ${staff['name']} (${staff['workTitle']})'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: AppColors.greenDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle Salary Summary Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF0F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['month'] ?? 'August Salary',
                      style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '₹${(staff['salary'] as int).toString()}',
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),

                // Status Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.greenLight : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPaid ? AppColors.green.withValues(alpha: 0.25) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? AppColors.greenDark : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Action Row
          if (isPaid)
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  'Salary Settled & Added to Expenses ✓',
                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            )
          else
            InkWell(
              onTap: () => _approveSalary(staff),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Approve & Mark Paid (₹${(staff['salary'] as int).toString()})',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
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
          const Icon(Icons.badge_outlined, size: 38, color: AppColors.muted),
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
