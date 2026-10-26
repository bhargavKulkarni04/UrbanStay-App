import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/models.dart';
import '../widgets/raise_ticket_card.dart';
import 'ticket_status_screen.dart';

/// Dedicated Screen: Facility Helpdesk (Raise Service Request)
/// Formatted strictly using UrbanStay's executive design standards:
/// - Light canvas background (#F4F6F9)
/// - Clean executive AppBar with hairline divider
/// - ZERO emojis anywhere
class RaiseTicketScreen extends StatelessWidget {
  final String? propertyId;
  final String? tenantId;
  final String residentName;
  final String roomNumber;
  final String bedId;
  final String floor;
  final String sharingType;
  final String phone;
  final String pgName;

  const RaiseTicketScreen({
    super.key,
    this.propertyId,
    this.tenantId,
    this.residentName = '',
    required this.roomNumber,
    required this.bedId,
    this.floor = '',
    this.sharingType = '',
    this.phone = '',
    this.pgName = '',
  });

  @override
  Widget build(BuildContext context) {
    final cleanRoomTitle = roomNumber.isNotEmpty
        ? (roomNumber.startsWith('Room') ? roomNumber : 'Room $roomNumber')
        : '';

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
            if (cleanRoomTitle.isNotEmpty)
              Text(
                cleanRoomTitle,
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
                propertyId: propertyId,
                tenantId: tenantId,
                residentName: residentName,
                roomNumber: roomNumber,
                bedId: bedId,
                floor: floor,
                sharingType: sharingType,
                phone: phone,
                pgName: pgName,
                onTicketSubmitted: (ticket) {
                  HapticFeedback.heavyImpact();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => TicketStatusScreen(
                        ticket: ticket,
                        bedLabel: bedId,
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
