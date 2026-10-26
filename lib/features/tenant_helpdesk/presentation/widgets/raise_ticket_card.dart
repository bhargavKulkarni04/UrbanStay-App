import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/urban_loading.dart';

/// Authentic UrbanStay Facility Helpdesk Request Card
/// Designed strictly to match UrbanStay's production card architecture:
/// - Pure elevated white card (#FFFFFF) on light-gray canvas (#F4F6F9)
/// - Clean neutral input surfaces (#FAFAFA) with hairline borders (#D1D5DB)
/// - Authentic placeholder styling matching `paid_via_cash_card.dart` & `tenant_checkin.html`
/// - ZERO emojis anywhere (100% native vector icons & Outfit typography)
class RaiseTicketCard extends StatefulWidget {
  final String? propertyId;
  final String? tenantId;
  final String residentName;
  final String roomNumber;
  final String bedId;
  final String floor;
  final String sharingType;
  final String phone;
  final String pgName;
  final ValueChanged<MaintenanceTicketModel> onTicketSubmitted;

  const RaiseTicketCard({
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
    required this.onTicketSubmitted,
  });

  @override
  State<RaiseTicketCard> createState() => _RaiseTicketCardState();
}

class _RaiseTicketCardState extends State<RaiseTicketCard> {
  // 5 facility maintenance categories (Zero emojis, clean titles)
  final List<String> _categories = [
    'Electrical',
    'Plumbing',
    'WiFi',
    'Carpentry',
    'Other',
  ];

  late String _selectedCategory;
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  final FocusNode _customTitleFocusNode = FocusNode();
  final FocusNode _issueFocusNode = FocusNode();

  String? _attachedPhotoName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _issueController.dispose();
    _customTitleFocusNode.dispose();
    _issueFocusNode.dispose();
    super.dispose();
  }

  bool get _isOtherSelected => _selectedCategory == 'Other';

  String get _resolvedCategoryTitle {
    if (_isOtherSelected) {
      final custom = _customTitleController.text.trim();
      return custom.isNotEmpty ? custom : 'Other';
    }
    return _selectedCategory;
  }

  void _showPhotoOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.ink),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _attachedPhotoName =
                          '${_selectedCategory.toLowerCase()}_photo.jpg';
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.ink),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _attachedPhotoName =
                          '${_selectedCategory.toLowerCase()}_photo.jpg';
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    final text = _issueController.text.trim();
    if (_isOtherSelected && _customTitleController.text.trim().isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the issue title',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _customTitleFocusNode.requestFocus();
      return;
    }

    if (text.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please describe the issue before submitting',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _issueFocusNode.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    UrbanLoadingService.show('Submitting maintenance request...');

    try {
      final client = SupabaseService.instance.client;
      String? resolvedPropId = widget.propertyId;
      String? resolvedTenantId = widget.tenantId;

      if (resolvedTenantId == null || resolvedTenantId.isEmpty) {
        final phone = SupabaseService.instance.currentUser?.phone ??
            SupabaseService.instance.currentUserPhone;
        if (phone != null && phone.isNotEmpty) {
          final tRes = await client
              .from('tenants')
              .select('id, property_id')
              .eq('phone', phone)
              .maybeSingle();
          if (tRes != null) {
            resolvedTenantId = tRes['id']?.toString();
            resolvedPropId ??= tRes['property_id']?.toString();
          }
        }
      }

      final String safePropId =
          (resolvedPropId != null && resolvedPropId.isNotEmpty)
              ? resolvedPropId
              : (SupabaseService.instance.activePropertyId ?? '');

      final MaintenanceTicketModel? createdTicket =
          await SupabaseService.instance.createMaintenanceTicket(
        propertyId: safePropId,
        propertyName: widget.pgName,
        tenantId: resolvedTenantId ?? '',
        tenantName: widget.residentName,
        roomNumber: widget.roomNumber,
        category: _resolvedCategoryTitle,
        issue: text,
        photoUrl: _attachedPhotoName,
      );

      if (createdTicket != null) {
        if (mounted) {
          widget.onTicketSubmitted(createdTicket);
        }
      } else {
        final fallbackTicket = MaintenanceTicketModel(
          id: 'TKT-${DateTime.now().millisecondsSinceEpoch}',
          propertyId: safePropId,
          propertyName: widget.pgName,
          tenantId: resolvedTenantId,
          tenantName: widget.residentName,
          roomNumber: widget.roomNumber,
          category: _resolvedCategoryTitle,
          issue: text,
          photoUrl: _attachedPhotoName,
          status: 'pending',
          createdAt: DateTime.now(),
        );
        if (mounted) {
          widget.onTicketSubmitted(fallbackTicket);
        }
      }
    } catch (e) {
      debugPrint('Error creating maintenance ticket model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not submit request. Please try again.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Room Context Strip (Matching paid_via_cash_card.dart)
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
                    if (widget.residentName.trim().isNotEmpty)
                      Text(
                        widget.residentName.trim(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    if (widget.pgName.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.pgName.trim(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.roomNumber.isNotEmpty ||
                    widget.bedId.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.roomNumber.isNotEmpty)
                        Text(
                          widget.roomNumber.startsWith('Room')
                              ? widget.roomNumber
                              : 'Room ${widget.roomNumber}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      if (widget.bedId.isNotEmpty)
                        Text(
                          widget.bedId.startsWith('Bed')
                              ? widget.bedId
                              : 'Bed ${widget.bedId}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Category Selection
          Text(
            'Select Issue Category',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),

          // Interactive 5-Pill Grid (Identical to tenant_checkin.html .interactive-grid)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in _categories)
                _buildCategoryPill(
                  label: cat,
                  isSelected: _selectedCategory == cat,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                    if (cat == 'Other') {
                      _customTitleFocusNode.requestFocus();
                    }
                  },
                ),
            ],
          ),

          // Custom Title Field (if Other is selected)
          if (_isOtherSelected) ...[
            const SizedBox(height: 14),
            Text(
              'Custom Issue Title',
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
                controller: _customTitleController,
                focusNode: _customTitleFocusNode,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Broken Mirror, Window Latch',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 3. Problem Description Field (Clean Native Container)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Describe the Issue',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${_issueController.text.length} / 300',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: TextField(
              controller: _issueController,
              focusNode: _issueFocusNode,
              maxLines: 3,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Describe what needs repair or attention in your room...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Photo Attachment
          Text(
            'Photo Proof (Optional)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),

          if (_attachedPhotoName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedPhotoName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _attachedPhotoName = null);
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _showPhotoOptions,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 17,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attach Photo or Proof',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // 5. Green Action Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit Service Request',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Category Pill matching UrbanStay Design Tokens
  Widget _buildCategoryPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
