import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/raise_ticket_card.dart';
import 'ticket_status_screen.dart';

/// Dedicated Screen: Facility Helpdesk (Raise Service Request)
/// Formatted strictly using UrbanStay's executive design standards:
/// - Light canvas background (#F4F6F9)
/// - Clean executive AppBar with hairline divider
/// - ZERO emojis anywhere
class RaiseTicketScreen extends StatelessWidget {
  final String residentName;
  final String roomNumber;
  final String bedId;
  final String floor;
  final String sharingType;
  final String phone;
  final String pgName;

  const RaiseTicketScreen({
    super.key,
    this.residentName = 'Bhargav Kulkarni',
    required this.roomNumber,
    required this.bedId,
    this.floor = '1st Floor',
    this.sharingType = '2-Sharing',
    this.phone = '8618818322',
    this.pgName = 'Greenview PG',
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
              'Raise Service Request',
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Room $roomNumber',
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
              RaiseTicketCard(
                residentName: residentName,
                roomNumber: roomNumber,
                bedId: bedId,
                floor: floor,
                sharingType: sharingType,
                phone: phone,
                pgName: pgName,
                onTicketSubmitted: (ticketData) {
                  HapticFeedback.heavyImpact();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => TicketStatusScreen(
                        ticketData: ticketData,
                        pgName: pgName,
                      ),
                    ),
                  );
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
