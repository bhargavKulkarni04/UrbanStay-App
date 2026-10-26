import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/urban_loading.dart';

/// 💵 Dedicated Standalone Widget: Paid Via Cash at Reception Card
/// Allows tenants to record physical currency note handovers to the owner, warden,
/// or custom relation (e.g. Owner's Father), flowing directly into the owner's cash audit.
class PaidViaCashCard extends StatefulWidget {
  final String residentName;
  final String roomNumber;
  final String floor;
  final String bedId;
  final String pgName;
  final double amount;
  final String cycleMonth;
  final String defaultOwnerName;
  final String? tenantId;
  final String? propertyId;
  final String? phone;
  final String? ledgerId;
  final ValueChanged<Map<String, dynamic>> onCashSubmitted;

  const PaidViaCashCard({
    super.key,
    required this.residentName,
    required this.roomNumber,
    this.floor = '',
    required this.bedId,
    required this.pgName,
    required this.amount,
    required this.cycleMonth,
    required this.defaultOwnerName,
    this.tenantId,
    this.propertyId,
    this.phone,
    this.ledgerId,
    this.initiallyExpanded = false,
    required this.onCashSubmitted,
  });

  final bool initiallyExpanded;

  @override
  State<PaidViaCashCard> createState() => _PaidViaCashCardState();
}

class _PaidViaCashCardState extends State<PaidViaCashCard> {
  late bool _isExpanded;
  late String _selectedRecipient;
  final TextEditingController _customRecipientController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late String _selectedRentMonth;
  List<String> _recipientsList = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    final ownerLabel = widget.defaultOwnerName.isNotEmpty
        ? '${widget.defaultOwnerName} (Owner)'
        : 'PG Owner';
    _selectedRecipient = ownerLabel;
    _recipientsList = [
      ownerLabel,
      'Other / Custom Person...',
    ];
    final parts = widget.cycleMonth.split(' ');
    _selectedRentMonth = (parts.isNotEmpty && parts.first.isNotEmpty)
        ? parts.first
        : _currentMonthName();
    _fetchPropertyTeam();
  }

  Future<void> _fetchPropertyTeam() async {
    final pId = widget.propertyId;
    if (pId == null || pId.isEmpty) return;
    try {
      final team = await SupabaseService.instance.getPropertyTeamMembers(pId);
      if (mounted && team.isNotEmpty) {
        setState(() {
          final ownerLabel = widget.defaultOwnerName.isNotEmpty
              ? '${widget.defaultOwnerName} (Owner)'
              : 'PG Owner';
          final List<String> list = [ownerLabel];
          for (final m in team) {
            final roleCapitalized = m.role.isNotEmpty
                ? '${m.role[0].toUpperCase()}${m.role.substring(1)}'
                : 'Team';
            final label = '${m.name} ($roleCapitalized)';
            if (!list.contains(label)) {
              list.add(label);
            }
          }
          list.add('Other / Custom Person...');
          _recipientsList = list;
          if (!_recipientsList.contains(_selectedRecipient)) {
            _selectedRecipient = list.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching property team for cash dropdown: $e');
    }
  }

  String _currentMonthName() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[DateTime.now().month - 1];
  }

  @override
  void dispose() {
    _customRecipientController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
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
        _selectedDate = picked;
      });
    }
  }

  void _showConfirmationDialog() {
    if (_selectedRecipient == 'Other / Custom Person...') {
      final custom = _customRecipientController.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please enter the recipient's name (e.g. Owner's Father)",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Cash Payment',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to record this cash payment to $_selectedRecipient?',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _submit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Yes, Confirm',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  Future<void> _submit() async {
    String recipient = _selectedRecipient;
    if (recipient == 'Other / Custom Person...') {
      final custom = _customRecipientController.text.trim();
      if (custom.isEmpty) {
        return;
      }
      recipient = custom;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);
    UrbanLoadingService.show('Recording Cash Handover in Database...');

    try {
      final client = SupabaseService.instance.client;
      final remarks = _remarksController.text.trim();

      final generatedUtr =
          'CASH-${recipient.trim().replaceAll(RegExp(r'\s+'), '_')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final payload = {
        'amount': widget.amount,
        'collected_by': recipient,
        'utr_number': generatedUtr,
        'payment_app': 'Cash Handover',
        'status': 'pending',
        if (widget.pgName.isNotEmpty) 'property_name': widget.pgName,
        if (widget.tenantId != null && widget.tenantId!.isNotEmpty)
          'tenant_id': widget.tenantId,
        if (widget.propertyId != null && widget.propertyId!.isNotEmpty)
          'property_id': widget.propertyId,
        if (widget.residentName.isNotEmpty) 'tenant_name': widget.residentName,
        if (widget.roomNumber.isNotEmpty) 'room_number': widget.roomNumber,
        if (widget.ledgerId != null && widget.ledgerId!.isNotEmpty)
          'ledger_id': widget.ledgerId,
      };

      // If switching from another mode, clean up previous pending approvals for this resident & ledger
      if (widget.tenantId != null && widget.tenantId!.isNotEmpty) {
        try {
          var delQuery = client
              .from('payment_approvals')
              .delete()
              .eq('tenant_id', widget.tenantId!)
              .eq('status', 'pending');
          if (widget.ledgerId != null &&
              widget.ledgerId!.isNotEmpty &&
              !widget.ledgerId!.startsWith('bed_')) {
            delQuery = delQuery.eq('ledger_id', widget.ledgerId!);
          } else if (widget.propertyId != null &&
              widget.propertyId!.isNotEmpty) {
            delQuery = delQuery.eq('property_id', widget.propertyId!);
          }
          await delQuery;
        } catch (_) {}
      }

      await client.from('payment_approvals').insert(payload);

      // Also ensure rent_ledgers has property_name updated if it was empty
      if (widget.ledgerId != null &&
          widget.ledgerId!.isNotEmpty &&
          widget.pgName.isNotEmpty &&
          !widget.ledgerId!.startsWith('bed_')) {
        try {
          await client.from('rent_ledgers').update({
            'property_name': widget.pgName,
          }).eq('id', widget.ledgerId!);
        } catch (_) {}
      }

      if (!mounted) return;

      final resultPayload = {
        'paymentMode': 'CASH',
        'amount': widget.amount,
        'recipient': recipient,
        'date': _formatDate(_selectedDate),
        'cycleMonth': _selectedRentMonth,
        'remarks': remarks,
        'residentName': widget.residentName,
        'room': widget.roomNumber,
      };

      widget.onCashSubmitted(resultPayload);
    } catch (e) {
      debugPrint('Error saving cash handover to payment_approvals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save cash payment: $e',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      UrbanLoadingService.hide();
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Accordion Header (No payment icon)
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid via Cash at Reception?',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record cash handover to owner, warden or relative',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                  size: 22,
                ),
              ],
            ),
          ),

          // 2. Expanded Body
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),

            // Pre-added Lease & Room Details Summary Strip (Pure white, clean borders)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.residentName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                      Text(
                        AppCurrency.format(widget.amount),
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Room ${widget.roomNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        _selectedRentMonth,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Handed Over To Dropdown
            Text(
              'Handed Over To',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRecipient,
                  isExpanded: true,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _recipientsList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRecipient = val);
                    }
                  },
                ),
              ),
            ),

            // Custom Recipient Input if "Other" is chosen (e.g. Owner's Father)
            if (_selectedRecipient == 'Other / Custom Person...') ...[
              const SizedBox(height: 10),
              Text(
                'Recipient Name / Relation',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _customRecipientController,
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: "e.g. Owner's Father, Brother, Relative",
                    hintStyle:
                        TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Handover Date (Interactive with real date picker)
            Text(
              'Handover Date',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: AppColors.muted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Remarks / Notes (Optional)
            Text(
              'Remarks / Notes (Optional)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _remarksController,
                maxLines: 2,
                style: GoogleFonts.outfit(fontSize: 12.5),
                decoration: const InputDecoration(
                  hintText: 'e.g. Handed cash at reception desk',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Record Cash Payment Button (Green bg, white text, no amount, triggers confirmation modal)
            ElevatedButton(
              onPressed: _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Record Cash Payment',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
