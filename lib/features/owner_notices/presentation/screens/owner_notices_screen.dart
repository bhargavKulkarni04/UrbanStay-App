import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/owner_app_state.dart';
import '../../../../core/widgets/urban_loading.dart';

/// Screen: Owner Move-Out Notices Pipeline
/// Displays all active move-out notices across the property.
/// Features:
/// - Minimalist executive typography (Stripe/Linear style)
/// - Two action bars per resident: [ Call with Phone SVG ] & [ WhatsApp with WhatsApp SVG ]
/// - Iconic UrbanStay styling: AppColors.greenLight (#EBF8EE) with AppColors.green border
/// - Fully connected to live Supabase tables: `move_out_notices`, `rooms`, `beds`, `tenants`.
class OwnerNoticesScreen extends StatefulWidget {
  const OwnerNoticesScreen({super.key});

  @override
  State<OwnerNoticesScreen> createState() => _OwnerNoticesScreenState();
}

class _OwnerNoticesScreenState extends State<OwnerNoticesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final propId = OwnerAppState.instance.activePropertyId;
      if (propId.isEmpty) {
        setState(() {
          _isLoading = false;
          _notices = [];
        });
        return;
      }

      // 1. Fetch active move-out notices from public.move_out_notices
      final noticesRes = await SupabaseService.instance.client
          .from('move_out_notices')
          .select()
          .eq('property_id', propId)
          .neq('status', 'cancelled')
          .order('vacate_date', ascending: true);

      // 2. Fetch rooms to get floor_number and sharing_type
      final roomsRes = await SupabaseService.instance.client
          .from('rooms')
          .select('room_number, floor_number, sharing_type')
          .eq('property_id', propId);

      final Map<String, Map<String, String>> roomLookup = {};
      if (roomsRes is List) {
        for (var r in roomsRes) {
          if (r is Map) {
            final rNum = r['room_number']?.toString().trim() ?? '';
            if (rNum.isNotEmpty) {
              roomLookup[rNum] = {
                'floor': r['floor_number']?.toString().trim() ?? '',
                'sharing': r['sharing_type']?.toString().trim() ?? '',
              };
            }
          }
        }
      }

      // 3. Fetch beds for base_price (rent) and occupant details
      final bedsRes = await SupabaseService.instance.client
          .from('beds')
          .select('room_number, name, base_price, tenant_name, tenant_phone')
          .eq('property_id', propId);

      final Map<String, int> bedRentLookup = {};
      final Map<String, String> bedTenantLookup = {};
      final Map<String, String> bedPhoneLookup = {};
      if (bedsRes is List) {
        for (var b in bedsRes) {
          if (b is Map) {
            final key = '${b['room_number']?.toString().trim()}-${b['name']?.toString().trim()}';
            final price = int.tryParse(b['base_price']?.toString() ?? '0') ?? 0;
            bedRentLookup[key] = price;
            final tName = b['tenant_name']?.toString().trim() ?? '';
            if (tName.isNotEmpty) {
              bedTenantLookup[key] = tName;
            }
            final tPhone = b['tenant_phone']?.toString().trim() ?? '';
            if (tPhone.isNotEmpty) {
              bedPhoneLookup[key] = tPhone;
            }
          }
        }
      }

      // 4. Fetch tenants for security_deposit, phone and fallback rent
      final tenantsRes = await SupabaseService.instance.client
          .from('tenants')
          .select('id, name, room_number, bed_name, monthly_rent, security_deposit, phone')
          .eq('property_id', propId);

      final Map<String, Map<String, dynamic>> tenantLookup = {};
      if (tenantsRes is List) {
        for (var t in tenantsRes) {
          if (t is Map) {
            final tId = t['id']?.toString().trim() ?? '';
            final keyByBed = '${t['room_number']?.toString().trim()}-${t['bed_name']?.toString().trim()}';
            final data = <String, dynamic>{
              'name': t['name']?.toString().trim() ?? '',
              'phone': t['phone']?.toString().trim() ?? '',
              'rent': int.tryParse(t['monthly_rent']?.toString() ?? '0') ?? 0,
              'deposit': int.tryParse(t['security_deposit']?.toString() ?? '0') ?? 0,
            };
            if (tId.isNotEmpty) tenantLookup[tId] = data;
            tenantLookup[keyByBed] = data;
          }
        }
      }

      // 5. Combine and structure display rows
      final List<Map<String, dynamic>> parsedList = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (noticesRes is List) {
        for (var item in noticesRes) {
          if (item is! Map) continue;
          final row = item;
          final roomNum = row['room_number']?.toString().trim() ?? '';
          final bedId = row['bed_identifier']?.toString().trim() ?? '';
          final bedKey = '$roomNum-$bedId';
          final tenantId = row['tenant_id']?.toString().trim() ?? '';

          // Tenant Name resolution
          String tenantName = row['tenant_name']?.toString().trim() ?? '';
          if (tenantName.isEmpty && tenantId.isNotEmpty && tenantLookup.containsKey(tenantId)) {
            tenantName = tenantLookup[tenantId]!['name']?.toString() ?? '';
          }
          if (tenantName.isEmpty && tenantLookup.containsKey(bedKey)) {
            tenantName = tenantLookup[bedKey]!['name']?.toString() ?? '';
          }
          if (tenantName.isEmpty && bedTenantLookup.containsKey(bedKey)) {
            tenantName = bedTenantLookup[bedKey] ?? '';
          }
          if (tenantName.isEmpty) {
            tenantName = 'Resident (Room $roomNum)';
          }

          // Phone resolution
          String phone = '';
          if (tenantId.isNotEmpty && tenantLookup.containsKey(tenantId)) {
            phone = tenantLookup[tenantId]!['phone']?.toString() ?? '';
          }
          if (phone.isEmpty && tenantLookup.containsKey(bedKey)) {
            phone = tenantLookup[bedKey]!['phone']?.toString() ?? '';
          }
          if (phone.isEmpty && bedPhoneLookup.containsKey(bedKey)) {
            phone = bedPhoneLookup[bedKey] ?? '';
          }

          // Floor Name resolution
          final rawFloor = roomLookup[roomNum]?['floor'] ?? '';
          final floorDisplay = _formatFloor(rawFloor);

          // Sharing Type resolution
          final rawSharing = roomLookup[roomNum]?['sharing'] ?? '';
          final sharingDisplay = _formatSharing(rawSharing);

          // Rent resolution
          int rent = bedRentLookup[bedKey] ?? 0;
          if (rent == 0 && tenantLookup.containsKey(bedKey)) {
            rent = (tenantLookup[bedKey]!['rent'] as int?) ?? 0;
          }

          // Deposit resolution
          int deposit = 0;
          if (tenantId.isNotEmpty && tenantLookup.containsKey(tenantId)) {
            deposit = (tenantLookup[tenantId]!['deposit'] as int?) ?? 0;
          } else if (tenantLookup.containsKey(bedKey)) {
            deposit = (tenantLookup[bedKey]!['deposit'] as int?) ?? 0;
          }

          // Vacate date and days calculation
          DateTime vacateDate;
          if (row['vacate_date'] != null) {
            vacateDate = DateTime.tryParse(row['vacate_date'].toString()) ?? now;
          } else {
            vacateDate = now;
          }
          final vacateTarget = DateTime(vacateDate.year, vacateDate.month, vacateDate.day);
          final daysLeft = vacateTarget.difference(today).inDays;

          // Reason resolution (Check if Owner initiated or Tenant initiated)
          final rawReason = row['reason']?.toString().trim() ?? '';
          final reasonDisplay = _formatReason(rawReason);

          parsedList.add({
            'id': row['id']?.toString() ?? '',
            'tenant_name': tenantName,
            'phone': phone,
            'floor_display': floorDisplay,
            'room_number': roomNum,
            'sharing_display': sharingDisplay,
            'days_left': daysLeft,
            'vacate_date': vacateDate,
            'vacate_formatted': _formatDate(vacateDate),
            'rent': rent,
            'deposit': deposit,
            'reason': reasonDisplay,
          });
        }
      }

      setState(() {
        _notices = parsedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatFloor(String raw) {
    if (raw.isEmpty) return 'Floor 1';
    final trimmed = raw.toLowerCase().replaceAll('floor', '').trim();
    if (trimmed == '0' || trimmed == 'g' || trimmed == 'ground') return 'Ground Floor';
    if (trimmed == '1') return '1st Floor';
    if (trimmed == '2') return '2nd Floor';
    if (trimmed == '3') return '3rd Floor';
    final n = int.tryParse(trimmed);
    if (n != null) return '${n}th Floor';
    return raw.contains('Floor') ? raw : '$raw Floor';
  }

  String _formatSharing(String raw) {
    if (raw.isEmpty) return '2-Sharing';
    final lower = raw.toLowerCase();
    if (lower.contains('single') || lower == '1') return '1-Sharing';
    if (lower.contains('double') || lower == '2') return '2-Sharing';
    if (lower.contains('triple') || lower == '3') return '3-Sharing';
    if (lower.contains('four') || lower == '4') return '4-Sharing';
    return raw.contains('Sharing') ? raw : '$raw-Sharing';
  }

  String _formatReason(String raw) {
    if (raw.isEmpty) return 'Owner Raised';
    final lower = raw.toLowerCase();
    if (lower.contains('owner') || lower == 'admin') {
      return 'Owner Raised';
    }
    return raw;
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }

  Future<void> _callTenant(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      _showSnackBar('No phone number recorded for $name');
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Calling +91 $cleanPhone');
      }
    } catch (_) {
      _showSnackBar('Calling +91 $cleanPhone');
    }
  }

  Future<void> _whatsappTenant(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      _showSnackBar('No phone number recorded for $name');
      return;
    }
    final formattedNumber = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final text = Uri.encodeComponent('Hi $name, regarding your move-out notice at UrbanStay:');
    final uri = Uri.parse('https://wa.me/$formattedNumber?text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Opening WhatsApp with +91 $cleanPhone');
      }
    } catch (_) {
      _showSnackBar('Opening WhatsApp with +91 $cleanPhone');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Move-Out Notices',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_notices.length} Active',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: UrbanSpinner(size: 44));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load move-out notices',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchNotices,
                child: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchNotices,
        color: AppColors.green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Text(
                    'No Active Move-Out Notices',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All occupied beds are in good standing.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotices,
      color: AppColors.green,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _notices.length,
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFFE5E7EB),
          height: 32,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final item = _notices[index];
          final int daysLeft = item['days_left'] as int;
          final String phone = item['phone'] as String;

          String daysText;
          Color daysColor;
          if (daysLeft < 0) {
            daysText = 'Overdue by ${daysLeft.abs()} Days';
            daysColor = AppColors.danger;
          } else if (daysLeft == 0) {
            daysText = 'Vacating Today';
            daysColor = AppColors.warning;
          } else {
            daysText = '$daysLeft Days Left';
            daysColor = daysLeft <= 7 ? AppColors.warning : AppColors.muted;
          }

          final floorSharing = '${item['floor_display']} • Room ${item['room_number']} • ${item['sharing_display']}';
          final vacateText = 'Vacating ${item['vacate_formatted']}';

          final rentDeposit = 'Rent ₹${item['rent']} • Deposit ₹${item['deposit']}';
          final reasonText = 'Reason: ${item['reason']}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Line 1: Tenant Name on left, Days Left on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      item['tenant_name'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    daysText,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: daysColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Line 2: Floor • Room • Sharing on left, Vacating Date on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      floorSharing,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    vacateText,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Line 3: Rent & Deposit
              Text(
                rentDeposit,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),

              // Line 4: Reason (Owner Raised or Tenant's chosen reason)
              Text(
                reasonText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),

              // Line 5: The Two Action Bars (Call & WhatsApp) with SVG Icons & UrbanStay Brand Styling
              Row(
                children: [
                  // Call Bar with Phone SVG
                  Expanded(
                    child: InkWell(
                      onTap: () => _callTenant(phone, item['tenant_name'] as String),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/phone.svg',
                              width: 15,
                              height: 15,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                phone.isNotEmpty ? phone : 'Call',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greenDark,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // WhatsApp Bar with WhatsApp SVG
                  Expanded(
                    child: InkWell(
                      onTap: () => _whatsappTenant(phone, item['tenant_name'] as String),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/whatsapp.svg',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'WhatsApp',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
