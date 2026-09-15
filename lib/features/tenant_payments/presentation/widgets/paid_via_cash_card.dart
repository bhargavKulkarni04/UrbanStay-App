import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

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
  final ValueChanged<Map<String, dynamic>> onCashSubmitted;

  const PaidViaCashCard({
    super.key,
    this.residentName = 'Bhargav Kulkarni',
    required this.roomNumber,
    this.floor = '1st Floor',
    required this.bedId,
    required this.pgName,
    required this.amount,
    required this.cycleMonth,
    this.defaultOwnerName = 'Arun Kumar',
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
  final TextEditingController _customRecipientController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final String _cashDate = '13 Sep 2026';

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _selectedRecipient = '${widget.defaultOwnerName} (Owner)';
  }

  @override
  void dispose() {
    _customRecipientController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    String recipient = _selectedRecipient;
    if (recipient == 'Other / Custom Person...') {
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
      recipient = custom;
    }

    HapticFeedback.heavyImpact();

    final payload = {
      'paymentMode': 'CASH',
      'amount': widget.amount,
      'recipient': recipient,
      'date': _cashDate,
      'remarks': _remarksController.text.trim(),
      'residentName': widget.residentName,
      'room': widget.roomNumber,
      'floor': widget.floor,
      'bed': widget.bedId,
    };

    widget.onCashSubmitted(payload);
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
          // 1. Accordion Header
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 1),
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

            // Pre-added Lease & Room Details Summary Strip (Clean standard app pattern)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        AppCurrency.format(widget.amount),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Room ${widget.roomNumber} • ${widget.floor} • Bed ${widget.bedId}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        '${widget.cycleMonth} Rent',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
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
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB)),
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
                  items: [
                    DropdownMenuItem(
                      value: '${widget.defaultOwnerName} (Owner)',
                      child: Text('${widget.defaultOwnerName} (Owner)'),
                    ),
                    const DropdownMenuItem(
                      value: 'Ramesh Gowda (Warden)',
                      child: Text('Ramesh Gowda (Warden)'),
                    ),
                    const DropdownMenuItem(
                      value: 'Suresh (Reception Supervisor)',
                      child: Text('Suresh (Reception Supervisor)'),
                    ),
                    const DropdownMenuItem(
                      value: 'Other / Custom Person...',
                      child: Text('Other / Custom Person...'),
                    ),
                  ],
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
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: TextField(
                  controller: _customRecipientController,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: "e.g. Owner's Father, Brother, Relative",
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Handover Date
            Text(
              'Handover Date',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _cashDate,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.muted),
                ],
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
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: TextField(
                controller: _remarksController,
                maxLines: 2,
                style: GoogleFonts.outfit(fontSize: 12.5),
                decoration: const InputDecoration(
                  hintText: 'e.g. Handed 17 notes of ₹500 at reception counter',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Cash Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Record Cash Payment (${AppCurrency.format(widget.amount)})',
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
