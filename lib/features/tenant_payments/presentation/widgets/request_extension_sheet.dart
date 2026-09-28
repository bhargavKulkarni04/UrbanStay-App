import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Clean, Dedicated Bottom Sheet for Tenant Rent Due Extension Request.
/// Features:
/// - Quick date selection chips (1st to 10th)
/// - Numeric input for custom day of month (e.g. 15th)
/// - Non-editable pre-fixed preview: "Requested to pay on {day}th of this month"
/// - Green CTA button with double-verification confirmation popup
class RequestExtensionSheet extends StatefulWidget {
  final Function(int selectedDay)? onExtensionRequested;

  const RequestExtensionSheet({
    super.key,
    this.onExtensionRequested,
  });

  static Future<void> show(
    BuildContext context, {
    Function(int selectedDay)? onExtensionRequested,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestExtensionSheet(
        onExtensionRequested: onExtensionRequested,
      ),
    );
  }

  @override
  State<RequestExtensionSheet> createState() => _RequestExtensionSheetState();
}

class _RequestExtensionSheetState extends State<RequestExtensionSheet> {
  int _selectedDay = 10;
  late final TextEditingController _dayController;

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Extension Request?',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Request payment extension till the ${_selectedDay}th of this month?',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
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
              Navigator.pop(confirmCtx); // Close confirm
              Navigator.pop(context); // Close sheet
              widget.onExtensionRequested?.call(_selectedDay);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Extension requested till ${_selectedDay}th. Owner notified ✓',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes, Request',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request Due Date Extension',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.muted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select the target date you will complete your rent payment.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // Quick Date Chips (1 to 10)
          Text(
            'SELECT DATE (1st – 10th)',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(10, (index) {
                final day = index + 1;
                final isSel = _selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                        _dayController.text = day.toString();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.green : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? AppColors.green
                              : const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight:
                                isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Custom Day Entry (Numbers Only)
          Text(
            'OR ENTER SPECIFIC DAY OF MONTH',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _dayController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 15',
              prefixIcon: const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.green),
              suffixText: 'th of this month',
              suffixStyle: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.green, width: 1.5),
              ),
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null && parsed >= 1 && parsed <= 31) {
                setState(() => _selectedDay = parsed);
              }
            },
          ),
          const SizedBox(height: 14),

          // Fixed Pre-Formatted Message Preview Strip (Tenant cannot write, only preview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requested to pay on ${_selectedDay}th of this month',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Full-Width Green Bar CTA with White Text
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Request for Extension',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
