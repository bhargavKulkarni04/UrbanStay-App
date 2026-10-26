import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/supabase_service.dart';

/// 📋 Post-Submission Screen: Ticket Status with 3 Vertical Tracking Steps
/// 1. Top Card: "Sent to PG Owner" (No technician claims)
/// 2. 3 Vertical Lines / Stepper:
///    - Step 1: Sent to Owner (Done ✓)
///    - Step 2: Assigned (In Review)
///    - Step 3: Resolved (Pending / Done)
///    - No timestamps or dates
/// 3. Small Self-Resolution Bar: Resident can mark resolved anytime if owner didn't resolve
/// 4. WhatsApp Button: Authentic official WhatsApp logo
/// 5. Return to Dashboard Button: Pure Green background (#08A63F) with White text
class TicketStatusScreen extends StatefulWidget {
  final MaintenanceTicketModel ticket;
  final String bedLabel;
  final String pgName;
  final String ownerName;

  const TicketStatusScreen({
    super.key,
    required this.ticket,
    this.bedLabel = '',
    this.pgName = '',
    this.ownerName = '',
  });

  @override
  State<TicketStatusScreen> createState() => _TicketStatusScreenState();
}

class _TicketStatusScreenState extends State<TicketStatusScreen> {
  late bool _isResolved;
  late MaintenanceTicketModel _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _isResolved = _currentTicket.isResolved;
  }

  Future<void> _toggleResolved() async {
    HapticFeedback.mediumImpact();
    final newStatus = !_isResolved;

    setState(() {
      _isResolved = newStatus;
      _currentTicket = MaintenanceTicketModel(
        id: _currentTicket.id,
        propertyId: _currentTicket.propertyId,
        propertyName: _currentTicket.propertyName,
        tenantId: _currentTicket.tenantId,
        tenantName: _currentTicket.tenantName,
        roomNumber: _currentTicket.roomNumber,
        category: _currentTicket.category,
        issue: _currentTicket.issue,
        photoUrl: _currentTicket.photoUrl,
        status: newStatus ? 'resolved' : 'pending',
        assignedStaff: _currentTicket.assignedStaff,
        progressNote: newStatus
            ? 'Resolved directly by resident'
            : 'Reopened by resident',
        createdAt: _currentTicket.createdAt,
      );
    });

    if (_currentTicket.id.isNotEmpty) {
      await SupabaseService.instance.updateComplaintStatus(
        complaintId: _currentTicket.id,
        status: newStatus ? 'resolved' : 'pending',
        resolutionNotes: newStatus
            ? 'Resolved directly by resident'
            : 'Reopened by resident',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isResolved
                ? 'Issue marked as resolved by you ✓'
                : 'Ticket reopened and marked pending',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              _isResolved ? const Color(0xFF065F46) : const Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketId = _currentTicket.id;
    final category = _currentTicket.category;
    final room = _currentTicket.roomNumber.isNotEmpty
        ? (_currentTicket.roomNumber.startsWith('Room')
            ? _currentTicket.roomNumber
            : 'Room ${_currentTicket.roomNumber}')
        : '';
    final bed = widget.bedLabel.isNotEmpty
        ? (widget.bedLabel.startsWith('Bed')
            ? widget.bedLabel
            : 'Bed ${widget.bedLabel}')
        : '';
    final issue = _currentTicket.issue;
    final photoName = _currentTicket.photoUrl;
    final ownerNameText = widget.ownerName.trim();

    final appBarSubtitle = [
      if (ticketId.isNotEmpty) ticketId,
      if (room.isNotEmpty) room,
    ].join(' • ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context, _currentTicket),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Status',
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            if (appBarSubtitle.isNotEmpty)
              Text(
                appBarSubtitle,
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
              // 1. Top Card: Direct Delivery to Owner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isResolved
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8EE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isResolved
                              ? AppColors.green
                              : const Color(0xFFB7EB8F),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _isResolved
                              ? Icons.done_all_rounded
                              : Icons.check_rounded,
                          size: 26,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isResolved ? 'Issue Resolved' : 'Sent to Property Owner',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isResolved
                          ? 'Marked as resolved directly by resident.'
                          : (ownerNameText.isNotEmpty
                              ? 'Your issue has been delivered to $ownerNameText.'
                              : 'Your issue has been delivered to the property team.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. 3 Vertical Lines Stepper: Sent -> Assigned -> Resolved
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVICE TRACKING',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Step 1: Sent to Owner
                    _buildStepRow(
                      stepNumber: 1,
                      title: 'Sent to Owner',
                      subtitle: ownerNameText.isNotEmpty
                          ? 'Delivered to $ownerNameText & team'
                          : 'Delivered to management & warden',
                      tagText: 'Delivered',
                      tagColor: AppColors.greenDark,
                      tagBg: AppColors.greenLight,
                      isDone: true,
                      hasLineBelow: true,
                      isLineDone: true,
                    ),

                    // Step 2: Assigned
                    _buildStepRow(
                      stepNumber: 2,
                      title: 'Assigned',
                      subtitle: room.isNotEmpty
                          ? 'Arranging inspection for $room'
                          : 'Arranging inspection & repair',
                      tagText: 'In Review',
                      tagColor: const Color(0xFFD97706),
                      tagBg: const Color(0xFFFFFBEB),
                      isDone: _isResolved,
                      isActive: !_isResolved,
                      hasLineBelow: true,
                      isLineDone: _isResolved,
                    ),

                    // Step 3: Resolved
                    _buildStepRow(
                      stepNumber: 3,
                      title: 'Resolved',
                      subtitle: _isResolved
                          ? 'Resolved directly by resident'
                          : 'Direct resident sign-off or self-resolve',
                      tagText: _isResolved ? 'Resolved' : 'Pending',
                      tagColor:
                          _isResolved ? AppColors.greenDark : AppColors.muted,
                      tagBg: _isResolved
                          ? AppColors.greenLight
                          : const Color(0xFFF3F4F6),
                      isDone: _isResolved,
                      isActive: false,
                      hasLineBelow: false,
                      isLineDone: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Small "Mark as Resolved" Bar (Self-resolve if owner didn't resolve)
              InkWell(
                onTap: _toggleResolved,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isResolved ? const Color(0xFFEBF8EE) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isResolved
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isResolved
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 22,
                        color:
                            _isResolved ? AppColors.greenDark : AppColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isResolved
                                  ? 'Resolved by Resident'
                                  : 'Issue already fixed?',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isResolved
                                    ? const Color(0xFF065F46)
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _isResolved
                                  ? 'Ticket closed • Tap to re-open'
                                  : 'Tap if problem is resolved on your own',
                              style: GoogleFonts.outfit(
                                fontSize: 11.2,
                                fontWeight: FontWeight.w400,
                                color: _isResolved
                                    ? const Color(0xFF047857)
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isResolved
                              ? Colors.white
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isResolved
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Text(
                          _isResolved ? 'Undo' : 'Mark Resolved',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _isResolved
                                ? const Color(0xFF047857)
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Reported Details Card (No timestamps)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPORTED DETAILS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (ticketId.isNotEmpty) ...[
                      _buildInfoRow('Ticket ID', ticketId, isHighlight: true),
                      _buildDivider(),
                    ],
                    if (category.isNotEmpty) ...[
                      _buildInfoRow('Category', category),
                      _buildDivider(),
                    ],
                    if (room.isNotEmpty || bed.isNotEmpty) ...[
                      _buildInfoRow(
                          'Room & Bed',
                          [if (room.isNotEmpty) room, if (bed.isNotEmpty) bed]
                              .join(' • ')),
                      _buildDivider(),
                    ],
                    if (issue.isNotEmpty) ...[
                      Text(
                        'Problem Details',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          issue,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (photoName != null && photoName.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined,
                                size: 16, color: AppColors.inkSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                photoName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const Text(
                              'Attached',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. WhatsApp Button (Authentic WhatsApp SVG Icon)
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ownerNameText.isNotEmpty
                              ? 'Opening WhatsApp chat with $ownerNameText...'
                              : 'Opening WhatsApp chat with management...',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: const Color(0xFF1E3A1E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/whatsapp.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ownerNameText.isNotEmpty
                            ? 'Ping $ownerNameText on WhatsApp'
                            : 'Message Management on WhatsApp',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 6. Return to Dashboard Button (GREEN BG + WHITE TEXT)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _currentTicket),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Return to Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required String tagText,
    required Color tagColor,
    required Color tagBg,
    required bool isDone,
    bool isActive = false,
    required bool hasLineBelow,
    required bool isLineDone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Circle & Vertical Line
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.green
                    : (isActive ? Colors.white : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? AppColors.green
                      : (isActive
                          ? const Color(0xFFD97706)
                          : const Color(0xFFD1D5DB)),
                  width: isActive ? 2.5 : 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : (isActive
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
            if (hasLineBelow)
              Container(
                width: 2,
                height: 38,
                color: isLineDone ? AppColors.green : const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Right: Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: hasLineBelow ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagText,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.greenDark : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Color(0xFFEEEEEE), height: 1),
    );
  }
}
