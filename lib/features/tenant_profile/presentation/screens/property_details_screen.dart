import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyName;
  final String propertyAddress;
  final String initialFloor;
  final String initialRoom;
  final String sharingType;
  final String rentAmount;
  final String depositAmount;
  final String bedLabel;
  final String propertyStructure;
  final String? tenantId;
  final String? propertyId;
  final String? tenantPhone;

  const PropertyDetailsScreen({
    super.key,
    this.propertyName = '',
    this.propertyAddress = '',
    this.initialFloor = '',
    this.initialRoom = '',
    this.sharingType = '',
    this.rentAmount = '',
    this.depositAmount = '',
    this.bedLabel = '',
    this.propertyStructure = '',
    this.tenantId,
    this.propertyId,
    this.tenantPhone,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late String _propertyName;
  late String _propertyAddress;
  late String _floor;
  late String _roomNumber;
  late String _sharingType;
  late String _rentAmount;
  late String _depositAmount;
  late String _bedLabel;
  late String _propertyStructure;

  bool get _isApartment =>
      _propertyStructure.toLowerCase().contains('apartment');

  String _extractSpaceFromBed(String bedLabel) {
    final match = RegExp(r'\((.*?)\)').firstMatch(bedLabel);
    if (match != null && match.group(1) != null) {
      final inside = match.group(1)!.trim();
      if (inside.isNotEmpty) return inside;
    }
    final lower = bedLabel.toLowerCase();
    if (lower.contains('hall')) return 'Hall';
    if (lower.contains('master')) return 'Master Bedroom';
    if (lower.contains('bedroom')) return 'Bedroom';
    return '';
  }

  String _extractCleanBed(String bedLabel) {
    final cleaned = bedLabel.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return cleaned.isNotEmpty ? cleaned : bedLabel;
  }

  @override
  void initState() {
    super.initState();
    _propertyName = widget.propertyName.trim();
    _propertyAddress = widget.propertyAddress.trim();
    _floor = widget.initialFloor.trim();
    _roomNumber = widget.initialRoom.trim();
    _sharingType = widget.sharingType.trim();
    _rentAmount = widget.rentAmount.trim();
    _depositAmount = widget.depositAmount.trim();
    _bedLabel = widget.bedLabel.trim();
    _propertyStructure = widget.propertyStructure.trim();

    _hydrateMissingData();
  }

  Future<void> _hydrateMissingData() async {
    try {
      final pId =
          widget.propertyId ?? SupabaseService.instance.activePropertyId;
      if (pId != null && pId.isNotEmpty) {
        if (_propertyAddress.isEmpty ||
            _propertyStructure.isEmpty ||
            _propertyName.isEmpty) {
          final prop = await SupabaseService.instance.client
              .from('properties')
              .select(
                  'property_name, street_address, area_locality, city, pincode, property_structure')
              .eq('id', pId)
              .maybeSingle();

          if (prop != null && mounted) {
            setState(() {
              if (_propertyName.isEmpty) {
                _propertyName = prop['property_name']?.toString() ?? '';
              }
              if (_propertyAddress.isEmpty) {
                final street = prop['street_address']?.toString() ?? '';
                final area = prop['area_locality']?.toString() ?? '';
                final city = prop['city']?.toString() ?? '';
                final pin = prop['pincode']?.toString() ?? '';
                final full = [street, area, city, pin]
                    .where((s) => s.trim().isNotEmpty)
                    .join(', ');
                if (full.isNotEmpty) _propertyAddress = full;
              }
              if (_propertyStructure.isEmpty) {
                _propertyStructure =
                    prop['property_structure']?.toString() ?? '';
              }
            });
          }
        }
      }

      // If tenant room/bed/floor/financials missing, query tenants table
      final hasTenantId =
          widget.tenantId != null && widget.tenantId!.isNotEmpty;
      final hasTenantPhone =
          widget.tenantPhone != null && widget.tenantPhone!.isNotEmpty;

      if ((_floor.isEmpty ||
              _floor == '--' ||
              _bedLabel.isEmpty ||
              _roomNumber.isEmpty ||
              _roomNumber == '--' ||
              _rentAmount.isEmpty ||
              _depositAmount.isEmpty) &&
          (hasTenantId || hasTenantPhone)) {
        var query = SupabaseService.instance.client.from('tenants').select('''
          id, room_id, room_number, bed_id, sharing_type, monthly_rent, security_deposit,
          beds!bed_id(bed_label),
          rooms!room_id(floor_label, sharing_type)
        ''');

        Map<String, dynamic>? tenantData;
        if (hasTenantPhone) {
          tenantData =
              await query.eq('phone', widget.tenantPhone!.trim()).maybeSingle();
        } else if (hasTenantId) {
          tenantData = await query.eq('id', widget.tenantId!).maybeSingle();
        }

        if (tenantData != null && mounted) {
          final bedsData = tenantData['beds'];
          final roomsData = tenantData['rooms'];
          final resolvedBed =
              (bedsData is Map) ? bedsData['bed_label']?.toString() : null;
          final resolvedFloor =
              (roomsData is Map) ? roomsData['floor_label']?.toString() : null;
          final resolvedSharing =
              (roomsData is Map) ? roomsData['sharing_type']?.toString() : null;

          setState(() {
            if (_roomNumber.isEmpty || _roomNumber == '--') {
              _roomNumber = tenantData!['room_number']?.toString() ?? '';
            }
            if (_bedLabel.isEmpty && resolvedBed != null) {
              _bedLabel = resolvedBed;
            }
            if ((_floor.isEmpty || _floor == '--') && resolvedFloor != null) {
              _floor = resolvedFloor;
            }
            if ((_sharingType.isEmpty || _sharingType == '--') &&
                resolvedSharing != null) {
              _sharingType = resolvedSharing;
            }
            if (_rentAmount.isEmpty && tenantData!['monthly_rent'] != null) {
              final rent = (tenantData!['monthly_rent'] as num).round();
              if (rent > 0) _rentAmount = '₹$rent';
            }
            if (_depositAmount.isEmpty &&
                tenantData!['security_deposit'] != null) {
              final dep = (tenantData!['security_deposit'] as num).round();
              if (dep > 0) _depositAmount = '₹$dep';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error hydrating property details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = _extractSpaceFromBed(_bedLabel);
    final cleanBed = _extractCleanBed(_bedLabel);
    final displayBed = _isApartment && space.isNotEmpty ? cleanBed : _bedLabel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Text(
                            'Back',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Property Details & Rent',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Property Information (View Only) ───
                        Text(
                          'Property Information',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildInfoTile('Property Name', _propertyName),
                        const SizedBox(height: 10),
                        _buildInfoTile('Property Address', _propertyAddress),
                        if (_propertyStructure.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoTile(
                              'Property Structure', _propertyStructure),
                        ],
                        const SizedBox(height: 24),

                        // ─── Room / Apartment & Bed Details (View Only) ───
                        Text(
                          _isApartment
                              ? 'Apartment & Bed Details'
                              : 'Room & Bed Details',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildInfoTile('Floor', _floor),
                        const SizedBox(height: 10),
                        _buildInfoTile(
                          _isApartment ? 'Flat Number' : 'Room Number',
                          _roomNumber,
                        ),
                        if (_isApartment && space.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoTile('Flat Space', space),
                        ],
                        if (displayBed.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoTile('Allocated Bed', displayBed),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoTile('Sharing Type', _sharingType),
                        const SizedBox(height: 24),

                        // ─── Financial Overview (View Only) ───
                        Text(
                          'Financial Overview',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildInfoTile('Monthly Rent', _rentAmount),
                        const SizedBox(height: 10),
                        _buildInfoTile('Security Deposit', _depositAmount),
                        const SizedBox(height: 18),

                        // Note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'Note: Room assignments, floor changes, and rent tariffs are managed exclusively by property management.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isNotEmpty ? value.trim() : '--',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
