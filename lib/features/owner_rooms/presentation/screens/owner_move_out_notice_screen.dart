import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../../core/services/supabase_service.dart';

/// Full-Page Screen for Owner to initiate Move-Out Notice with live damage deductions
/// and editable refundable deposit amount. Zero mock data, fully synced to Supabase.
class OwnerMoveOutNoticeScreen extends StatefulWidget {
  final Map<String, dynamic> resident;
  final String roomName;
  final String? propertyId;
  final String? propertyName;
  final String noticePeriod;
  final int noticeDaysInt;
  final VoidCallback onNoticeSuccess;

  const OwnerMoveOutNoticeScreen({
    super.key,
    required this.resident,
    required this.roomName,
    required this.propertyId,
    required this.propertyName,
    required this.noticePeriod,
    required this.noticeDaysInt,
    required this.onNoticeSuccess,
  });

  @override
  State<OwnerMoveOutNoticeScreen> createState() =>
      _OwnerMoveOutNoticeScreenState();
}

class _OwnerMoveOutNoticeScreenState extends State<OwnerMoveOutNoticeScreen> {
  late DateTime _selectedVacateDate;
  late int _noticeDays;
  late String _noticePeriodLabel;
  late TextEditingController _refundableDepositController;
  late TextEditingController _reasonController;

  bool _isLoadingDamages = true;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _damageDeductions = [];

  // Local helper for logging a quick damage charge on the spot
  final TextEditingController _newItemController = TextEditingController();
  final TextEditingController _newAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _noticePeriodLabel = widget.noticePeriod;
    _noticeDays = widget.noticeDaysInt > 0 ? widget.noticeDaysInt : 30;
    _selectedVacateDate = DateTime.now().add(Duration(days: _noticeDays));

    // Initial deposit and refundable deposit calculation
    final rawDeposit =
        double.tryParse(widget.resident['deposit']?.toString() ?? '') ?? 0.0;
    final rawRefDeposit = double.tryParse(
        widget.resident['refundable_deposit']?.toString() ?? '');
    final initialRefundable = (rawRefDeposit != null && rawRefDeposit > 0)
        ? rawRefDeposit
        : rawDeposit;

    _refundableDepositController = TextEditingController(
      text: initialRefundable > 0 ? initialRefundable.toInt().toString() : '0',
    );
    _reasonController = TextEditingController(
      text: 'Owner Initiated Notice (${widget.noticePeriod})',
    );

    _loadLiveDamageDeductions();
  }

  @override
  void dispose() {
    _refundableDepositController.dispose();
    _reasonController.dispose();
    _newItemController.dispose();
    _newAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveDamageDeductions() async {
    setState(() => _isLoadingDamages = true);
    final pId =
        widget.propertyId ?? SupabaseService.instance.activePropertyId ?? '';
    final roomClean = widget.roomName.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final rawRoom = widget.roomName.trim();
    final tenantId = widget.resident['tenant_id']?.toString() ?? '';
    final tenantName = widget.resident['name']?.toString() ?? '';

    try {
      if (pId.isNotEmpty) {
        // 1. Pull live notice_period from properties table in Supabase
        try {
          final propRes = await SupabaseService.instance.client
              .from('properties')
              .select('notice_period')
              .eq('id', pId)
              .maybeSingle();

          if (propRes != null && propRes['notice_period'] != null) {
            final pNotice = propRes['notice_period'].toString();
            if (pNotice.isNotEmpty) {
              final match = RegExp(r'\d+').firstMatch(pNotice);
              if (match != null) {
                final days = int.tryParse(match.group(0) ?? '');
                if (days != null && days > 0 && mounted) {
                  setState(() {
                    _noticePeriodLabel = pNotice;
                    _noticeDays = days;
                    _selectedVacateDate =
                        DateTime.now().add(Duration(days: days));
                    _reasonController.text =
                        'Owner Initiated Notice ($pNotice)';
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Notice loading property notice_period: $e');
        }

        final res = await SupabaseService.instance.client
            .from('damage_deductions')
            .select(
                'id, item_damaged, amount, photo_url, room_number, created_at, tenant_id, tenant_name')
            .eq('property_id', pId)
            .order('created_at', ascending: false);

        final List<Map<String, dynamic>> matched = [];
        for (final item in res) {
          final dRoom = item['room_number']?.toString().trim() ?? '';
          final dCleanRoom = dRoom.replaceAll(RegExp(r'[^0-9]'), '').trim();
          final dTenantId = item['tenant_id']?.toString().trim() ?? '';
          final dTenantName =
              item['tenant_name']?.toString().trim().toLowerCase() ?? '';

          final matchesRoom = dRoom.toLowerCase() == rawRoom.toLowerCase() ||
              (roomClean.isNotEmpty && dCleanRoom == roomClean);
          final matchesTenant =
              (tenantId.isNotEmpty && dTenantId == tenantId) ||
                  (tenantName.isNotEmpty &&
                      dTenantName == tenantName.toLowerCase());

          if (matchesRoom || matchesTenant) {
            final amt =
                double.tryParse(item['amount']?.toString() ?? '') ?? 0.0;
            matched.add({
              'id': item['id']?.toString() ?? '',
              'item_damaged':
                  item['item_damaged']?.toString() ?? 'Damage Deduction',
              'amount': amt,
              'photo_url': item['photo_url']?.toString(),
              'created_at': item['created_at']?.toString(),
            });
          }
        }

        if (mounted) {
          setState(() {
            _damageDeductions.clear();
            _damageDeductions.addAll(matched);
            _isLoadingDamages = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading damage deductions: $e');
    }

    if (mounted) {
      setState(() => _isLoadingDamages = false);
    }
  }

  double get _totalDamages {
    double sum = 0.0;
    for (final d in _damageDeductions) {
      sum += (d['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  double get _currentRefundableDeposit {
    return double.tryParse(_refundableDepositController.text.trim()) ?? 0.0;
  }

  double get _netRefundPayable {
    final net = _currentRefundableDeposit - _totalDamages;
    return net > 0 ? net : 0.0;
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickVacateDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedVacateDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.green,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedVacateDate = picked;
        _noticeDays = picked.difference(now).inDays;
        if (_noticeDays <= 0) _noticeDays = 1;
      });
    }
  }

  void _showAddDamageSheet() {
    _newItemController.clear();
    _newAmountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Inspection Damage',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newItemController,
                decoration: InputDecoration(
                  labelText: 'Item Damaged (e.g. Table, Geyser, Wardrobe)',
                  labelStyle:
                      GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Deduction Amount (₹)',
                  prefixText: '₹ ',
                  labelStyle:
                      GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final item = _newItemController.text.trim();
                  final amt =
                      double.tryParse(_newAmountController.text.trim()) ?? 0.0;
                  if (item.isEmpty || amt <= 0) return;

                  Navigator.of(ctx).pop();
                  final pId = widget.propertyId ??
                      SupabaseService.instance.activePropertyId ??
                      '';
                  final tenantId =
                      widget.resident['tenant_id']?.toString() ?? '';
                  final tenantName = widget.resident['name']?.toString() ?? '';

                  try {
                    await SupabaseService.instance.client
                        .from('damage_deductions')
                        .insert({
                      'property_id': pId,
                      'room_number': widget.roomName,
                      if (tenantId.isNotEmpty && !tenantId.startsWith('bed_'))
                        'tenant_id': tenantId,
                      'tenant_name': tenantName,
                      'item_damaged': item,
                      'amount': amt,
                      'deduction_mode': 'deposit',
                    });
                    _loadLiveDamageDeductions();
                  } catch (e) {
                    debugPrint('Error inserting damage deduction: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Add Damage Deduction',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitMoveOutNotice() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final pId =
        widget.propertyId ?? SupabaseService.instance.activePropertyId ?? '';
    final bedId = widget.resident['id']?.toString();
    final tenantId = widget.resident['tenant_id']?.toString();
    final residentName = widget.resident['name']?.toString() ?? 'Resident';
    final roomNum =
        widget.resident['room_number']?.toString() ?? widget.roomName;
    final bedLabel = widget.resident['bed']?.toString() ??
        widget.resident['label']?.toString() ??
        '';

    final isoVacateDate =
        '${_selectedVacateDate.year}-${_selectedVacateDate.month.toString().padLeft(2, '0')}-${_selectedVacateDate.day.toString().padLeft(2, '0')}';
    final refundableDeposit = _currentRefundableDeposit;
    final netRefund = _netRefundPayable;

    // 1. Update Bed Status to Notice
    if (bedId != null && bedId.isNotEmpty) {
      try {
        await SupabaseService.instance.client
            .from('beds')
            .update({'status': 'Notice'}).eq('id', bedId);
      } catch (e) {
        debugPrint('Error updating bed status to Notice: $e');
      }
    }

    // 2. Insert into move_out_notices
    if (pId.isNotEmpty) {
      final payload = {
        'property_id': pId,
        if (widget.propertyName != null && widget.propertyName!.isNotEmpty)
          'property_name': widget.propertyName,
        if (tenantId != null &&
            tenantId.isNotEmpty &&
            !tenantId.startsWith('bed_'))
          'tenant_id': tenantId,
        'tenant_name': residentName,
        'room_number': roomNum,
        'bed_identifier': bedLabel,
        'vacate_date': isoVacateDate,
        'notice_days': _noticeDays,
        'reason': _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : 'Owner Initiated Notice ($_noticePeriodLabel)',
        'refund_upi_id': widget.resident['refund_upi_id'] ?? '',
        'settlement_amount': netRefund,
        'status': 'ACTIVE',
      };

      try {
        await SupabaseService.instance.client.from('move_out_notices').insert({
          ...payload,
          'refundable_deposit': refundableDeposit,
        });
      } catch (e) {
        try {
          await SupabaseService.instance.client
              .from('move_out_notices')
              .insert(payload);
        } catch (innerError) {
          debugPrint('Error syncing move_out_notices: $innerError');
        }
      }

      // 3. Update tenant refundable deposit record if present
      if (tenantId != null &&
          tenantId.isNotEmpty &&
          !tenantId.startsWith('bed_')) {
        try {
          await SupabaseService.instance.client.from('tenants').update(
              {'refundable_deposit': refundableDeposit}).eq('id', tenantId);
        } catch (_) {}
      }
    }

    widget.onNoticeSuccess();

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Initiated ${widget.noticePeriod} Move-Out Notice for $residentName ✓',
            style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final residentName = widget.resident['name']?.toString() ?? 'Resident';
    final bedLabel = widget.resident['bed']?.toString() ??
        widget.resident['label']?.toString() ??
        'Bed';
    final rentStr = widget.resident['rent']?.toString() ?? '0';
    final depositStr = widget.resident['deposit']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Move-Out Notice',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Resident & Room Profile Card (Clean separation of Room and Bed, no arbitrary -A)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            residentName.isNotEmpty
                                ? residentName[0].toUpperCase()
                                : 'R',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              residentName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'Room ${widget.roomName}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Bed $bedLabel',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY RENT',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹$rentStr / mo',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SECURITY DEPOSIT PAID',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹$depositStr',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
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
            const SizedBox(height: 14),

            // Card 2: Notice Timeline Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NOTICE TIMELINE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_noticePeriodLabel Policy',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickVacateDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_note_rounded,
                              size: 22, color: AppColors.greenDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Vacate Date',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(_selectedVacateDate)} ($_noticeDays Days)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Change',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Editable Refundable Deposit Card (With Pencil Icon)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'REFUNDABLE DEPOSIT',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.green),
                        ],
                      ),
                      Text(
                        '(Editable)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Portion of deposit eligible for refund upon room handover',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _refundableDepositController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {});
                    },
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.edit_note_rounded,
                            size: 22, color: AppColors.green),
                      ),
                      filled: true,
                      fillColor: AppColors.pageBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.green, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 4: Real Damage Deductions Logged (From Inspection)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAMAGE DEDUCTIONS LOGGED',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      InkWell(
                        onTap: _showAddDamageSheet,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            '+ Log Damage',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Itemized from inspection room audit',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingDamages)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    )
                  else if (_damageDeductions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text(
                            'No damage deductions logged for this room (₹0)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._damageDeductions.map((d) {
                          final item = d['item_damaged'] ?? 'Damage';
                          final amt = (d['amount'] as num?)?.toDouble() ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD97706),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  '- ₹${amt.toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Damage Deductions',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '- ₹${_totalDamages.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 5: Net Settlement Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTLEMENT SUMMARY',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Refundable Deposit Amount',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppColors.muted),
                      ),
                      Text(
                        '₹${_currentRefundableDeposit.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inspection Damage Deductions',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppColors.muted),
                      ),
                      Text(
                        '- ₹${_totalDamages.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET REFUND PAYABLE',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(Subject to room handover inspection)',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${_netRefundPayable.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 6: Reason / Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTICE REASON / NOTE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter reason or policy reference',
                      hintStyle: GoogleFonts.outfit(
                          fontSize: 13, color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.pageBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.green),
                      ),
                    ),
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom CTA: Confirm Move-Out Notice
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitMoveOutNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm Move-Out Notice',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
