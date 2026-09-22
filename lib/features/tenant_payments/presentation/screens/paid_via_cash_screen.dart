import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/paid_via_cash_card.dart';

/// 💵 Dedicated Paid Via Cash Screen
/// Accessible directly from the Tenant Dashboard between "Pay Rent via UPI" and "Payment Ledger".
/// Records physical cash handovers at the PG reception desk into the owner's cash audit ledger.
class PaidViaCashScreen extends StatelessWidget {
  final String residentName;
  final String roomNumber;
  final String floor;
  final String bedId;
  final String pgName;
  final double amount;
  final String cycleMonth;
  final String ownerName;

  const PaidViaCashScreen({
    super.key,
    this.residentName = 'Bhargav Kulkarni',
    required this.roomNumber,
    this.floor = '1st Floor',
    required this.bedId,
    required this.pgName,
    required this.amount,
    required this.cycleMonth,
    this.ownerName = 'Arun Kumar',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid via Cash',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Reception Desk Physical Handover',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Clean White Notice Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Payment Verification',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit this form after handing cash at the reception desk. The owner will verify the amount and issue your digital rent receipt.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // The Standalone Modular Cash Card (Pre-expanded)
              PaidViaCashCard(
                residentName: residentName,
                roomNumber: roomNumber,
                floor: floor,
                bedId: bedId,
                pgName: pgName,
                amount: amount,
                cycleMonth: cycleMonth,
                defaultOwnerName: ownerName,
                initiallyExpanded: true,
                onCashSubmitted: (cashData) {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, {
                    'status': 'UNDER_REVIEW',
                    'mode': 'CASH',
                    'recipient': cashData['recipient'],
                    'remarks': cashData['remarks'],
                    'amount': amount,
                  });
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
