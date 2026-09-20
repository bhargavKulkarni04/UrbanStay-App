import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:urbanstay/features/owner_setup/presentation/screens/owner_setup_screen.dart';

/// Screen 12: Master Owner Settings & Configuration Hub.
/// 1-to-1 exact translation of `ProductionCode/owner_settings.html`.
/// Features:
/// - 6 Dedicated Sub-Views: Property, Management, Stay Rules, 0% Bank UPI, Checklist, Account & Security.
/// - Master Settings Directory with Search and Owner Hero Card.
/// - Interactive Edit Bottom Sheets with live in-memory updates.
/// - 100% Zero Emojis (pure native vector icons & Google Fonts Outfit typography).
/// - 100% Zero Vibe-Coded Colors (strict emerald green, ink, warm gold, and pure white cards).
/// - Apple App Store Guideline 5.1.1(v) compliant Account Deletion and Session Logout.
class OwnerSettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialView;

  const OwnerSettingsScreen({super.key, this.onBack, this.initialView});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  // Navigation State
  late String _activeView;
  final TextEditingController _searchController = TextEditingController();


  // ===========================================================================
  // LIVE SETTINGS DATA STATE
  // ===========================================================================
  // View 1: Property
  String _propName = 'Greenview Luxury Coliving';
  String _propType = 'Standard PG';
  String _propId = 'US-560034-A';
  String _propAddress = 'Koramangala 5th Block, Bengaluru, 560034';
  String _streetAddress = '#42, 7th Main, 4th Cross';
  String _locality = 'Koramangala 5th Block';
  String _landmark = 'Near Sony World Signal';
  String _selectedState = 'Karnataka';
  String _selectedCity = 'Bengaluru';
  String _pincode = '560034';
  String _propMapPin = 'maps.google.com/?q=12.9352,77.6245';
  String _tenantPreference = 'Co-Living'; // 'Gents', 'Ladies', 'Co-Living'
  String _curfewTime = '10:30 PM';
  String _morningOpen = '6:00 AM';

  static const List<String> _propertyTypeOptions = [
    'Standard PG',
    'Apartment Units',
  ];

  static const List<String> _tenantPreferenceOptions = [
    'Gents',
    'Ladies',
    'Co-Living',
  ];

  // View 2: Management & Business
  String _bizStatus = 'Verified Business';
  String _bizEntityType = 'Sole Proprietorship';
  String _bizLegalName = 'Greenview Hospitality Services';
  String _bizGst = '29ABCDE1234F1Z5';
  String _bizCin = 'BBMP-TR-2025-8819';
  String _adminName = 'Bhargav Kulkarni';
  String _adminEmail = 'bhargav@gmail.com';
  String _adminPhone = '+91 86188 18322';
  String _ownerGovtIdType = 'Aadhaar Card';
  String _ownerGovtIdProofStatus = 'Verified (aadhaar_front_back.pdf)';
  String _bizGstProofStatus = 'Uploaded (gst_reg_certificate.pdf)';

  // View 3: Renting & Stay Rules
  String _rentDueDay = '1st of Every Month';
  String _gracePeriod = '3 Days';
  String _dailyRate = '₹100 / day';
  String _lockinPeriod = '3 Months';
  String _noticePeriod = '30 Days';
  String _agreementDur = '11 Months Standard';

  // View 4: Banking Details
  String _upiId = 'bhargav@hdfcbank';
  String _bankName = 'HDFC Bank';
  String _bankAccNum = '501002348921';
  String _ifscCode = 'HDFC0001244';
  String _beneficiaryName = 'Bhargav Kulkarni';

  // View 6: Security & Account
  String _appPasscode = '••••••••';
  String _appLanguage = 'English';

  // View 7: Rent & Dues Collection Settings
  bool _allowOnlineUpi = true;
  bool _dailyLateFineEnabled = false;
  bool _acceptPartialPayments = true;
  bool _autoSendWhatsappReceipts = true;
  bool _autoDuesReminders = true;
  String _receiptTerms = 'This is an official acknowledgment of payment received for accommodation and hospitality services.\n\nIn case of payment reversal, chargeback, or dishonored instruments, this receipt stands immediately null and void.\n\nSecurity deposits and rent payments are strictly subject to the agreed notice period and premises rules.';

  // View 8: Tenant Onboarding & KYC Settings
  bool _autoWelcomeWhatsapp = true;
  bool _autoApproveBookings = false;
  bool _sendDepositReminders = true;
  bool _lockProfileAfterMovein = true;
  bool _mandatoryTenantKyc = true;
  bool _requireComplaintPhoto = true;
  String _kycApplicableTo = 'All Residents';
  String _authorizedSignatory = 'Bhargav S Kulkarni (Proprietor)';
  String _stampBusinessName = 'Greenview Hospitality Services';
  bool _foodMessRsvpEnabled = true;

  // View: Property Scale & Capacity Setup (C1–C4 Drilldown)
  String? _scaleSubSection; // null, 'c1', 'c2', 'c3', 'c4'
  String _ownerFullName = 'Bhargav S Kulkarni';
  String _ownerFatherName = 'Srinivas Kulkarni';
  String _ownerWhatsapp = '+91 86188 18322';
  String _ownerEmail = 'bhargav@gmail.com';
  String _ownerAadhaar = '5678 9012 3456';
  String _ownerAddress = 'Bengaluru, Karnataka';

  String _scalePgName = 'Greenview Luxury Coliving';
  String _scaleGenderCategory = 'Unisex / Coliving';
  String _scaleOwnershipType = 'Self-Owned Independent Building';
  String _scaleAreaLocality = 'Koramangala 5th Block';
  String _scalePincode = '560034';
  String _scaleLiftCount = '1 Passenger Lift';
  String _scalePowerBackup = '25 kVA Diesel Generator';

  int _scaleFloorCount = 4;
  int _scaleGroundRooms = 2;
  int _scaleRoomsEachFloor = 4;
  int _scaleTotalRooms = 14;
  int _scaleTotalBeds = 35;
  int _scale1SharingRooms = 2;
  int _scale2SharingRooms = 8;
  int _scale3SharingRooms = 4;
  int _scale4SharingRooms = 0;

  int _scale1SharingRent = 14000;
  int _scale1SharingDeposit = 25000;
  int _scale2SharingRent = 8500;
  int _scale2SharingDeposit = 15000;
  int _scale3SharingRent = 7500;
  int _scale3SharingDeposit = 12000;
  int _scale4SharingRent = 6500;
  int _scale4SharingDeposit = 10000;

  Map<String, List<String>> _liveStatesMap = {};

  @override
  void initState() {
    super.initState();
    _activeView = widget.initialView ?? 'master';
    _fetchLiveGeoData();
  }

  Future<void> _fetchLiveGeoData() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse(
        'https://raw.githubusercontent.com/sab99r/Indian-States-And-Districts/master/states-and-districts.json',
      ));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final statesList = data['states'] as List<dynamic>?;
        if (statesList != null) {
          final Map<String, List<String>> map = {};
          for (final item in statesList) {
            final stName = item['state']?.toString() ?? '';
            final districts = (item['districts'] as List<dynamic>?)
                    ?.map((d) => d.toString())
                    .toList() ??
                [];
            if (stName.isNotEmpty && districts.isNotEmpty) {
              map[stName] = districts;
            }
          }
          if (mounted && map.isNotEmpty) {
            setState(() {
              _liveStatesMap = map;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _lookupPincodeFromApi(String pincode) async {
    if (pincode.length != 6) return null;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>?;
          if (postOffices != null && postOffices.isNotEmpty) {
            final first = postOffices[0];
            return {
              'state': first['State']?.toString() ?? '',
              'city': first['District']?.toString() ?? first['Block']?.toString() ?? '',
              'locality': first['Name']?.toString() ?? '',
              'allLocalities': postOffices.map((p) => p['Name'].toString()).toSet().toList(),
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  void _handleBack() {
    if (_activeView == 'scale_capacity' && _scaleSubSection != null) {
      setState(() => _scaleSubSection = null);
    } else if (_activeView != 'master') {
      setState(() {
        _activeView = 'master';
        _scaleSubSection = null;
      });
    } else {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Sticky Dynamic Header
            _buildTopHeader(),

            // 2. Body Views
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 40.0),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP STICKY DYNAMIC HEADER
  // ===========================================================================
  Widget _buildTopHeader() {
    String title = 'Settings';
    String subtitle = 'Greenview PG • System Configuration';

    if (_activeView == 'property') {
      title = 'Property Settings';
      subtitle = 'Basic Info, Curfew & Digital Card';
    } else if (_activeView == 'management') {
      title = 'Management Details';
      subtitle = 'Entity, Tax & Admin Contact';
    } else if (_activeView == 'stay_rules') {
      title = 'Renting & Stay Rules';
      subtitle = 'Rent Cycles, Lock-in & Notice';
    } else if (_activeView == 'bank') {
      title = 'Banking Details';
      subtitle = 'Direct Bank UPI & Payment Mode';
    } else if (_activeView == 'scale_capacity') {
      if (_scaleSubSection == 'c1') {
        title = 'Owner Personal Identity';
        subtitle = 'Legal Name, Contact & Aadhaar KYC';
      } else if (_scaleSubSection == 'c2') {
        title = 'Property Infrastructure';
        subtitle = 'Location, Structure & Amenities';
      } else if (_scaleSubSection == 'c3') {
        title = 'Floors & Bed Capacity';
        subtitle = 'Building Layout & Capacity Upgrade';
      } else if (_scaleSubSection == 'c4') {
        title = 'Sharing Types & Rents';
        subtitle = 'Monthly Rates & Deposit Rules';
      } else {
        title = 'Scale & Capacity Setup';
        subtitle = 'Building Layout & Bed Upgrades (C1–C4)';
      }
    } else if (_activeView == 'rent_settings') {
      title = 'Rent & Dues Settings';
      subtitle = 'Direct UPI, Late Fine & Receipts';
    } else if (_activeView == 'onboarding_settings') {
      title = 'Onboarding & KYC Settings';
      subtitle = 'Welcome Pack, Aadhaar & Digital Seal';
    } else if (_activeView == 'account') {
      title = 'Account & Security';
      subtitle = 'Credentials, Sessions & Compliance';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F2), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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

  // ===========================================================================
  // VIEW SWITCHER
  // ===========================================================================
  Widget _buildCurrentView() {
    switch (_activeView) {
      case 'property':
        return _buildPropertyView();
      case 'management':
        return _buildManagementView();
      case 'stay_rules':
        return _buildStayRulesView();
      case 'bank':
        return _buildBankView();
      case 'scale_capacity':
        return _buildScaleCapacityView();
      case 'rent_settings':
        return _buildRentSettingsView();
      case 'onboarding_settings':
        return _buildOnboardingSettingsView();
      case 'account':
        return _buildAccountView();
      case 'master':
      default:
        return _buildMasterDirectoryView();
    }
  }

  // ===========================================================================
  // VIEW 0: MASTER DIRECTORY VIEW
  // ===========================================================================
  Widget _buildMasterDirectoryView() {
    final query = _searchController.text.toLowerCase().trim();

    final List<Map<String, dynamic>> menuItems = [
      {
        'id': 'property',
        'title': 'Property Settings',
        'desc': 'Property name, location, curfew & tenant preferences',
        'icon': Icons.home_work_outlined,
      },
      {
        'id': 'management',
        'title': 'Management & Business Details',
        'desc': 'Business entity, GST, CIN, and admin contact',
        'icon': Icons.business_center_outlined,
      },
      {
        'id': 'stay_rules',
        'title': 'Renting & Stay Rules',
        'desc': 'Rent cycles, lock-in, notice period & daily charges',
        'icon': Icons.description_outlined,
      },
      {
        'id': 'bank',
        'title': 'Banking Details',
        'desc': 'Payment mode (UPI or Cash), Bank account & QR standee',
        'icon': Icons.account_balance_outlined,
      },
      {
        'id': 'scale_capacity',
        'title': 'Property Scale & Capacity Setup',
        'desc': 'Owner KYC, building layout & bed capacity upgrade (C1–C4)',
        'icon': Icons.domain_add_outlined,
      },
      {
        'id': 'rent_settings',
        'title': 'Rent & Dues Collection Settings',
        'desc': 'Direct UPI, auto late fine, partial payments & receipt terms',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'id': 'onboarding_settings',
        'title': 'Tenant Onboarding & KYC Settings',
        'desc': 'Welcome pack, booking auto-approval, Aadhaar KYC & digital seal',
        'icon': Icons.how_to_reg_outlined,
      },
      {
        'id': 'account',
        'title': 'Account & Security Settings',
        'desc': 'Password, phone/email update, language & session logout',
        'icon': Icons.lock_outline_rounded,
      },
    ];

    final filtered = menuItems.where((item) {
      if (query.isEmpty) return true;
      final t = (item['title'] as String).toLowerCase();
      final d = (item['desc'] as String).toLowerCase();
      return t.contains(query) || d.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Box
        _buildMasterSearchBox(),
        const SizedBox(height: 14),

        // 2. Owner Profile Hero Card
        _buildOwnerHeroCard(),
        const SizedBox(height: 14),

        // 3. Master Menu Tiles
        ...filtered.map((item) => _buildMasterMenuTile(item)).toList(),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No settings matching "$query"',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),

        const SizedBox(height: 10),

        // 4. Subscription & Plan Link Banner
        _buildSubscriptionPlanBanner(),
      ],
    );
  }

  Widget _buildMasterSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search settings or rules...',
          hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
          suffixIcon: _searchController.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOwnerHeroCard() {
    return InkWell(
      onTap: () => setState(() => _activeView = 'account'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x03000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'BK',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _adminName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Primary Owner & Administrator',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_adminPhone • Pro 0% Fee Tier',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterMenuTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _activeView = item['id']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x02000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Icon(item['icon'] as IconData, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['desc'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlanBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_outline_rounded, size: 20, color: AppColors.greenDark),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Subscription & Plan',
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '31 Beds Managed • Renews 24 Sep',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }

  // ===========================================================================
  // VIEW 1: PROPERTY SETTINGS
  // ===========================================================================
  Widget _buildPropertyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Basic Details Card
        _buildElevatedCard(
          title: 'Basic Property Details',
          onEdit: _openEditBasicPropertyDetailsModal,
          rows: [
            _DetailRow('Property Name', _propName),
            _DetailRow('Property Structure', _propType),
            _DetailRow('UrbanStay ID', _propId, isCode: true, onTap: () {
              Clipboard.setData(ClipboardData(text: _propId));
              _showToast('Property ID copied to clipboard');
            }),
            _DetailRow('Address', _propAddress),
            _DetailRow('Google Maps', _propMapPin, isCode: true, isGreen: true),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Tenant Preference Card (Gender Category)
        _buildElevatedCard(
          title: 'Tenant Preference',
          onEdit: _openEditTenantPreferencesModal,
          rows: [
            _DetailRow('Gender Category', _tenantPreference),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Curfew & Gate Timings Card
        _buildElevatedCard(
          title: 'Curfew & Gate Timings',
          onEdit: _openEditCurfewTimingsModal,
          rows: [
            _DetailRow('Night Last Entry Time', _curfewTime),
            _DetailRow('Morning Gate Open Time', _morningOpen),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Digital Business Card
        _buildDigitalBusinessCard(),
      ],
    );
  }

  Widget _buildDigitalBusinessCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _propName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VERIFIED PG',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_propAddress\nDirect Bank UPI • Free High-Speed WiFi • 3 Meals Food',
            style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://urbanstay.living/pg/$_propId'));
              _showToast('Digital PG Card Link Copied ✓');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_outlined, size: 14, color: AppColors.greenDark),
                  const SizedBox(width: 6),
                  Text(
                    'Share Card Link',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.greenDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VIEW 2: MANAGEMENT & BUSINESS DETAILS
  // ===========================================================================
  Widget _buildManagementView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Business & Tax Details',
          onEdit: () => _openEditModal(
            title: 'Edit Business Details',
            fields: [
              _ModalField('Registered Legal Name', _bizLegalName, (v) => setState(() => _bizLegalName = v)),
              _ModalField('GST Number', _bizGst, (v) => setState(() => _bizGst = v)),
              _ModalField('CIN / License No', _bizCin, (v) => setState(() => _bizCin = v)),
            ],
          ),
          rows: [
            _DetailRow('Verification Status', _bizStatus, isGreen: true),
            _DetailRow('Registered Name', _bizLegalName),
            _DetailRow('GST Number', _bizGst, isCode: true),
            _DetailRow('License No', _bizCin, isCode: true),
          ],
        ),
        const SizedBox(height: 14),

        // Government KYC & Tax Documents Card
        _buildElevatedCard(
          title: 'Government KYC & Tax Documents',
          onEdit: _openEditGovtKycModal,
          rows: [
            _DetailRow('Owner Identity Proof', '$_ownerGovtIdType • $_ownerAadhaar'),
            _DetailRow('ID Document Status', _ownerGovtIdProofStatus, isGreen: true),
            _DetailRow('GSTIN Tax Certificate', _bizGstProofStatus, isGreen: true),
            _DetailRow('Trade License / BBMP', 'Verified • BBMP-TR-2025-8819', isGreen: true),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 3: RENTING & STAY RULES
  // ===========================================================================
  Widget _buildStayRulesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Monthly Rent Due & Grace Period',
          onEdit: _openEditRentingTermsModal,
          rows: [
            _DetailRow('Monthly Rent Due Date', _rentDueDay),
            _DetailRow('Grace Period Days', _gracePeriod),
          ],
        ),
        const SizedBox(height: 14),

        _buildElevatedCard(
          title: 'Stay & Policy Terms',
          onEdit: _openEditStayTermsModal,
          rows: [
            _DetailRow('Daily Late Penalty', _dailyRate),
            _DetailRow('Minimum Lock-in', _lockinPeriod),
            _DetailRow('Notice Period', _noticePeriod),
            _DetailRow('Agreement Duration', _agreementDur),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 4: BANKING DETAILS (PAYMENT MODE: UPI VS CASH)
  // ===========================================================================
  Widget _buildBankView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Payment Collection Mode Toggle Card
        _buildElevatedCard(
          title: 'Payment Collection Mode',
          customBody: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleSwitchRow(
                'Accept Direct UPI Payments',
                _allowOnlineUpi
                    ? 'Tenants pay via GPay / PhonePe directly to your bank account with 0% fee.'
                    : 'Cash Only Mode active. Direct UPI payments are disabled.',
                _allowOnlineUpi,
                (v) => setState(() {
                  _allowOnlineUpi = v;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInteractiveCard(
                    title: 'UPI + Online',
                    sub: '0% Direct Bank',
                    isSelected: _allowOnlineUpi,
                    onTap: () => setState(() {
                      _allowOnlineUpi = true;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildInteractiveCard(
                    title: 'Cash Only',
                    sub: 'Manual Collection',
                    isSelected: !_allowOnlineUpi,
                    onTap: () => setState(() {
                      _allowOnlineUpi = false;
                    }),
                  ),
                ],
              ),
            ],
          ),
          rows: const [],
        ),
        const SizedBox(height: 14),

        // 2. Conditional View: UPI Active vs Cash Only
        if (_allowOnlineUpi) ...[
          // Direct Banking & UPI Details (Active & Editable)
          _buildElevatedCard(
            title: 'Direct Banking & UPI Details',
            onEdit: () => _openEditModal(
              title: 'Edit Banking Details',
              fields: [
                _ModalField('Primary UPI ID', _upiId, (v) => setState(() => _upiId = v)),
                _ModalField('Bank Name', _bankName, (v) => setState(() => _bankName = v)),
                _ModalField('Account Number', _bankAccNum, (v) => setState(() => _bankAccNum = v)),
                _ModalField('IFSC Code', _ifscCode, (v) => setState(() => _ifscCode = v)),
                _ModalField('Beneficiary Name', _beneficiaryName, (v) => setState(() => _beneficiaryName = v)),
              ],
            ),
            rows: [
              _DetailRow('Payment Mode', 'Direct Bank UPI (Active)', isGreen: true),
              _DetailRow('Primary UPI ID', _upiId, isCode: true, isGreen: true),
              _DetailRow('Bank Name', _bankName),
              _DetailRow('Account Number', _bankAccNum, isCode: true),
              _DetailRow('IFSC Code', _ifscCode, isCode: true),
              _DetailRow('Beneficiary Name', _beneficiaryName),
              _DetailRow('Gateway Cut', '0% (Lifetime Direct Bank Settlement)', isGreen: true),
            ],
          ),
          const SizedBox(height: 14),

          // Standee Generator Card (Active for UPI)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.greenDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reception Desk QR Standee',
                        style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Printable high-resolution QR standee for your reception desk. Tenants scan to check in and pay rent directly to your bank account with ₹0 gateway commission.',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _showToast('Generating Printable Standee PDF for Greenview PG ✓'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Download Standee PDF (Ready to Print)',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Cash Only Warning & Mandatory Notification Instruction Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cash Only Mode Active',
                        style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Online direct UPI payments are disabled. After receiving cash (or offline UPI) in hand from the tenant:',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF92400E), height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You must mark the tenant as "Payment Recorded via Cash" in the Rent Collection screen after receiving the money. Until marked as cash recorded, the tenant will continue to receive automated pending dues reminders.',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF78350F),
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Disabled Bank Details Card (Read-only / Greyed out in Cash Mode)
          Opacity(
            opacity: 0.65,
            child: _buildElevatedCard(
              title: 'Direct Banking Details (Inactive in Cash Mode)',
              rows: [
                _DetailRow('Payment Mode', 'Cash Only (Manual Collection)', isGreen: false),
                _DetailRow('Primary UPI ID', _upiId, isCode: true),
                _DetailRow('Bank Name', _bankName),
                _DetailRow('Account Number', _bankAccNum, isCode: true),
                _DetailRow('Bank Settlement', 'Disabled (Switch toggle above to enable UPI)', isGreen: false),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // VIEW 5: PROPERTY SCALE & CAPACITY SETUP (C1–C4 DRILLDOWN)
  // ===========================================================================
  Widget _buildScaleCapacityView() {
    if (_scaleSubSection == 'c1') return _buildC1OwnerIdentityView();
    if (_scaleSubSection == 'c2') return _buildC2PropertyInfraView();
    if (_scaleSubSection == 'c3') return _buildC3BedCapacityView();
    if (_scaleSubSection == 'c4') return _buildC4SharingRentsView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScaleCategoryCard(
          code: 'C1',
          title: 'Owner Personal Identity',
          subtitle: '$_ownerFullName • $_ownerWhatsapp',
          desc: 'Legal identity, contact details, father name & Aadhaar status',
          onTap: () => setState(() => _scaleSubSection = 'c1'),
        ),
        const SizedBox(height: 12),

        _buildScaleCategoryCard(
          code: 'C2',
          title: 'Property Location & Infrastructure',
          subtitle: '$_scalePgName • $_scaleAreaLocality',
          desc: 'Gender category, pincode, lift & power backup generators',
          onTap: () => setState(() => _scaleSubSection = 'c2'),
        ),
        const SizedBox(height: 12),

        _buildScaleCategoryCard(
          code: 'C3',
          title: 'Floors, Rooms & Bed Capacity',
          subtitle: '$_scaleFloorCount Floors • $_scaleTotalRooms Rooms • $_scaleTotalBeds Total Beds',
          desc: 'Building floors layout, room counts & upgrade total bed size',
          onTap: () => setState(() => _scaleSubSection = 'c3'),
        ),
        const SizedBox(height: 12),

        _buildScaleCategoryCard(
          code: 'C4',
          title: 'Sharing Types & Rent Structure',
          subtitle: '1, 2, 3 & 4 Sharing Rooms',
          desc: 'Configured sharing room types, security deposits & rules',
          onTap: () => setState(() => _scaleSubSection = 'c4'),
        ),
      ],
    );
  }

  Widget _buildScaleCategoryCard({
    required String code,
    required String title,
    required String subtitle,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  code,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // C1 Detail View
  Widget _buildC1OwnerIdentityView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Owner Personal Identity',
          onEdit: _openEditC1OwnerModal,
          rows: [
            _DetailRow('Legal Full Name', _ownerFullName),
            _DetailRow("Father's Name", _ownerFatherName),
            _DetailRow('WhatsApp Mobile Number', _ownerWhatsapp),
            _DetailRow('Official Email Address', _ownerEmail),
            _DetailRow('12-Digit Aadhaar Number', 'Verified • $_ownerAadhaar', isGreen: true),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _openEditC1OwnerModal,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.green,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('Edit Personal Profile', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
        ),
      ],
    );
  }

  // C2 Detail View
  Widget _buildC2PropertyInfraView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Property Infrastructure & Location',
          onEdit: _openEditC2InfraModal,
          rows: [
            _DetailRow('PG Brand Name', _scalePgName),
            _DetailRow('Gender Category', _scaleGenderCategory),
            _DetailRow('Area & Locality', _scaleAreaLocality),
            _DetailRow('Postal Pincode', _scalePincode),
            _DetailRow('Lift / Elevator Availability', _scaleLiftCount),
            _DetailRow('Power Backup Generator', _scalePowerBackup),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _openEditC2InfraModal,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.green,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('Edit Property Details', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
        ),
      ],
    );
  }

  void _navigateToScaleCapacityScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwnerSetupScreen(
          isScaleMode: true,
          onCapacityUpdated: (newBeds, newRooms, newFloors) {
            setState(() {
              _scaleTotalBeds = newBeds;
              _scaleTotalRooms = newRooms;
              _scaleFloorCount = newFloors;
            });
          },
        ),
      ),
    );
  }

  // C3 Detail View
  Widget _buildC3BedCapacityView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Floors, Rooms & Bed Architecture',
          onEdit: _navigateToScaleCapacityScreen,
          rows: [
            _DetailRow('Ground Floor Rooms', '$_scaleGroundRooms Rooms (${_scaleGroundRooms * 2} Beds)'),
            _DetailRow('Total Building Floors', '$_scaleFloorCount Floors (Ground + ${_scaleFloorCount - 1} Floors)'),
            _DetailRow('Rooms per Upper Floor', '$_scaleRoomsEachFloor Rooms each'),
            _DetailRow('Total Rooms in Property', '$_scaleTotalRooms Rooms'),
            _DetailRow('Total Bed Capacity', '$_scaleTotalBeds Beds', isGreen: true),
            _DetailRow('1-Sharing Distribution', '$_scale1SharingRooms Rooms (${_scale1SharingRooms * 1} Beds)'),
            _DetailRow('2-Sharing Distribution', '$_scale2SharingRooms Rooms (${_scale2SharingRooms * 2} Beds)'),
            _DetailRow('3-Sharing Distribution', '$_scale3SharingRooms Rooms (${_scale3SharingRooms * 3} Beds)'),
            _DetailRow('4-Sharing Distribution', '$_scale4SharingRooms Rooms (${_scale4SharingRooms * 4} Beds)'),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _navigateToScaleCapacityScreen,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.green,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upgrade_rounded, size: 20, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'Scale Bed Capacity (Current: $_scaleTotalBeds Beds)',
                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // C4 Detail View
  Widget _buildC4SharingRentsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Sharing Types & Stay Policies',
          onEdit: _openEditC4RentsModal,
          rows: [
            _DetailRow('1-Sharing (Single Room)', 'Configured • Active Room Type'),
            _DetailRow('2-Sharing Room', 'Configured • Active Room Type'),
            _DetailRow('3-Sharing Room', 'Configured • Active Room Type'),
            _DetailRow('4-Sharing Room', 'Configured • Active Room Type'),
            _DetailRow('Rent Due Day', '1st of every month'),
            _DetailRow('Grace Period & Late Fee', '5 Days Grace • ₹100 / day late fee'),
            _DetailRow('Notice Period Requirement', '30 Days mandatory notice'),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _openEditC4RentsModal,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.green,
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('Edit Tariffs & Deposit Rules', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
        ),
      ],
    );
  }

  // ===========================================================================
  // EDIT BOTTOM SHEETS FOR C1–C4
  // ===========================================================================
  void _openEditC1OwnerModal() {
    final nameCtrl = TextEditingController(text: _ownerFullName);
    final fatherCtrl = TextEditingController(text: _ownerFatherName);
    String initialPhone = _ownerWhatsapp.replaceAll(RegExp(r'\D'), '');
    if (initialPhone.length > 10) initialPhone = initialPhone.substring(initialPhone.length - 10);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final emailCtrl = TextEditingController(text: _ownerEmail);
    final aadhaarCtrl = TextEditingController(text: _ownerAadhaar.replaceAll(RegExp(r'\D'), ''));
    String docAttachedStatus = 'Aadhaar Card Front & Back Attached ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildModalBottomSheetWrapper(
              ctx,
              title: 'Edit Owner Personal Identity',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModalTextField('Legal Full Name', nameCtrl),
                  const SizedBox(height: 12),
                  _buildModalTextField("Father's Name", fatherCtrl),
                  const SizedBox(height: 12),
                  _buildModalTextField(
                    'WhatsApp Mobile Number (10 Digits)',
                    phoneCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    hintText: 'e.g. 9876543210',
                  ),
                  const SizedBox(height: 12),
                  _buildModalTextField('Official Email Address', emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),

                  // 12-Digit Aadhaar Field with Strict Number Validation
                  _buildModalTextField(
                    '12-Digit Aadhaar Number (Numbers Only)',
                    aadhaarCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 12,
                    hintText: 'e.g. 542198761234',
                  ),
                  const SizedBox(height: 12),

                  // Aadhaar Photo / Document Upload Tile
                  Text(
                    'Aadhaar KYC Photo / Document',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setModalState(() {
                        docAttachedStatus = 'Aadhaar Uploaded ✓ (aadhaar_front_back.pdf)';
                      });
                      _showToast('Aadhaar Document Selected ✓');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 18, color: AppColors.greenDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              docAttachedStatus,
                              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ),
                          Text(
                            'Upload Photo/PDF',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      final phone = phoneCtrl.text.trim();
                      if (phone.length != 10) {
                        _showToast('Please enter a valid 10-digit mobile number');
                        return;
                      }
                      final aadhaar = aadhaarCtrl.text.trim();
                      if (aadhaar.isNotEmpty && aadhaar.length != 12) {
                        _showToast('Aadhaar number must be exactly 12 digits');
                        return;
                      }

                      setState(() {
                        _ownerFullName = nameCtrl.text.trim();
                        _ownerFatherName = fatherCtrl.text.trim();
                        _ownerWhatsapp = '+91 $phone';
                        _ownerEmail = emailCtrl.text.trim();
                        if (aadhaar.isNotEmpty) {
                          _ownerAadhaar = '${aadhaar.substring(0, 4)} •••• ${aadhaar.substring(8)}';
                        }
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Owner Personal Identity updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Save Identity Changes', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.green)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditGovtKycModal() {
    String tempGovtType = _ownerGovtIdType;
    final gstCtrl = TextEditingController(text: _bizGst);
    final aadhaarCtrl = TextEditingController(text: _ownerAadhaar);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildModalBottomSheetWrapper(
              ctx,
              title: 'Government KYC & Proofs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModalSectionLabel('Owner Government ID Proof Type'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: 'Aadhaar',
                        sub: '12 Digits',
                        isSelected: tempGovtType == 'Aadhaar Card',
                        onTap: () => setModalState(() => tempGovtType = 'Aadhaar Card'),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'PAN Card',
                        sub: '10 Digits',
                        isSelected: tempGovtType == 'PAN Card',
                        onTap: () => setModalState(() => tempGovtType = 'PAN Card'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildModalTextField('Government ID Number', aadhaarCtrl),
                  const SizedBox(height: 8),

                  // Upload ID Proof Button
                  InkWell(
                    onTap: () => _showToast('Government ID File Attached ✓ (aadhaar_front_back.pdf)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_rounded, size: 18, color: AppColors.greenDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ownerGovtIdProofStatus,
                              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ),
                          Text(
                            'Change File',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildModalSectionLabel('Business GSTIN Details'),
                  _buildModalTextField('15-Digit GSTIN Number', gstCtrl),
                  const SizedBox(height: 8),

                  // Upload GSTIN Certificate Button
                  InkWell(
                    onTap: () => _showToast('GST Certificate Attached ✓ (gst_reg_certificate.pdf)'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 18, color: AppColors.greenDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _bizGstProofStatus,
                              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ),
                          Text(
                            'Upload PDF',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _ownerGovtIdType = tempGovtType;
                        _ownerAadhaar = aadhaarCtrl.text.trim();
                        _bizGst = gstCtrl.text.trim();
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Government KYC & GST Details Saved ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('Save KYC & Tax Documents', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditC2InfraModal() {
    String tempGender = _scaleGenderCategory;
    String tempLift = _scaleLiftCount;
    String tempGen = _scalePowerBackup;
    final nameCtrl = TextEditingController(text: _scalePgName);
    final areaCtrl = TextEditingController(text: _scaleAreaLocality);
    final pinCtrl = TextEditingController(text: _scalePincode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return _buildModalBottomSheetWrapper(
              ctx,
              title: 'Edit Property Infrastructure',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModalTextField('PG Brand Name', nameCtrl),
                  const SizedBox(height: 12),
                  _buildModalTextField('Area / Locality', areaCtrl),
                  const SizedBox(height: 12),
                  _buildModalTextField(
                    'Pincode (6 Digits)',
                    pinCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                  ),
                  const SizedBox(height: 14),

                  // Gender Category Selection
                  _buildModalSectionLabel('Gender & Resident Category'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: "Men's PG",
                        sub: 'Gents Only',
                        isSelected: tempGender.contains("Men's") || tempGender.contains('Gents'),
                        onTap: () => setModalState(() => tempGender = "Men's PG (Gents Only)"),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: "Women's PG",
                        sub: 'Ladies Only',
                        isSelected: tempGender.contains("Women's") || tempGender.contains('Ladies'),
                        onTap: () => setModalState(() => tempGender = "Women's PG (Ladies Only)"),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'Unisex',
                        sub: 'Coliving',
                        isSelected: tempGender.contains('Unisex') || tempGender.contains('Coliving'),
                        onTap: () => setModalState(() => tempGender = 'Unisex / Coliving'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Lift / Elevator Selection
                  _buildModalSectionLabel('Elevator / Lift Count'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: '0',
                        sub: 'No Lift',
                        isSelected: tempLift.startsWith('0') || tempLift.contains('No Lift'),
                        onTap: () => setModalState(() => tempLift = '0 (No Lift)'),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '1',
                        sub: '1 Lift',
                        isSelected: tempLift.startsWith('1') || tempLift == '1 Passenger Lift',
                        onTap: () => setModalState(() => tempLift = '1 Passenger Lift'),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '2',
                        sub: '2 Lifts',
                        isSelected: tempLift.startsWith('2'),
                        onTap: () => setModalState(() => tempLift = '2 Passenger Lifts'),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '3+',
                        sub: '3+ Lifts',
                        isSelected: tempLift.startsWith('3') || tempLift.contains('3+'),
                        onTap: () => setModalState(() => tempLift = '3+ Elevators'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Power Backup Facility
                  _buildModalSectionLabel('Power Backup Facility'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: 'Full Backup',
                        sub: 'Generator / Inverter',
                        isSelected: tempGen.contains('Full') || tempGen.contains('Diesel') || tempGen.contains('Generator'),
                        onTap: () => setModalState(() => tempGen = '25 kVA Diesel Generator (Full Backup)'),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'No Backup',
                        sub: 'Standard Line',
                        isSelected: tempGen.contains('No Backup') || tempGen.contains('Standard'),
                        onTap: () => setModalState(() => tempGen = 'Standard Line (No Backup)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _scalePgName = nameCtrl.text.trim();
                        _scaleAreaLocality = areaCtrl.text.trim();
                        _scalePincode = pinCtrl.text.trim();
                        _scaleGenderCategory = tempGender;
                        _scaleLiftCount = tempLift;
                        _scalePowerBackup = tempGen;
                        _tenantPreference = tempGender.contains("Men's") ? 'Gents' : (tempGender.contains("Women's") ? 'Ladies' : 'Co-Living');
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Property Infrastructure updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('Save Infrastructure Changes', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // C3 Basic Architecture Edit Modal (Numbers validation only, sharing steppers removed)
  void _openEditC3CapacityModal() {
    final floorCtrl = TextEditingController(text: _scaleFloorCount.toString());
    final upperRoomsCtrl = TextEditingController(text: _scaleRoomsEachFloor.toString());
    bool tempGroundHasRooms = _scaleGroundRooms > 0;
    final gfRoomsCtrl = TextEditingController(text: _scaleGroundRooms.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final fCount = int.tryParse(floorCtrl.text) ?? _scaleFloorCount;
            final rPerUpper = int.tryParse(upperRoomsCtrl.text) ?? _scaleRoomsEachFloor;
            final gfRooms = tempGroundHasRooms ? (int.tryParse(gfRoomsCtrl.text) ?? 2) : 0;
            final calcRooms = gfRooms + ((fCount > 1 ? fCount - 1 : 0) * rPerUpper);

            return _buildModalBottomSheetWrapper(
              ctx,
              title: 'Edit Floors & Building Layout',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModalTextField(
                    'Total Building Floors (Numbers Only)',
                    floorCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    hintText: 'e.g. 3 (Ground + 2 Floors)',
                    onChanged: (v) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  _buildModalSectionLabel('Does Ground Floor have rooms for rent?'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: 'Yes',
                        sub: 'Has Rooms',
                        isSelected: tempGroundHasRooms,
                        onTap: () => setModalState(() {
                          tempGroundHasRooms = true;
                          if (gfRoomsCtrl.text == '0' || gfRoomsCtrl.text.isEmpty) {
                            gfRoomsCtrl.text = '2';
                          }
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'No',
                        sub: 'Parking / Office',
                        isSelected: !tempGroundHasRooms,
                        onTap: () => setModalState(() {
                          tempGroundHasRooms = false;
                          gfRoomsCtrl.text = '0';
                        }),
                      ),
                    ],
                  ),
                  if (tempGroundHasRooms) ...[
                    const SizedBox(height: 12),
                    _buildModalTextField(
                      'Ground Floor Rooms Count',
                      gfRoomsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 2,
                      hintText: 'e.g. 2',
                      onChanged: (v) => setModalState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),

                  _buildModalTextField(
                    'Rooms per Upper Floor (Numbers Only)',
                    upperRoomsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    hintText: 'e.g. 4',
                    onChanged: (v) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Total Rooms:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                        Text('$calcRooms Rooms', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      final f = int.tryParse(floorCtrl.text) ?? _scaleFloorCount;
                      final u = int.tryParse(upperRoomsCtrl.text) ?? _scaleRoomsEachFloor;
                      final g = tempGroundHasRooms ? (int.tryParse(gfRoomsCtrl.text) ?? 2) : 0;
                      if (f <= 0) {
                        _showToast('Building must have at least 1 floor');
                        return;
                      }

                      setState(() {
                        _scaleFloorCount = f;
                        _scaleRoomsEachFloor = u;
                        _scaleGroundRooms = g;
                        _scaleTotalRooms = g + ((f > 1 ? f - 1 : 0) * u);
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Building Architecture updated to $_scaleTotalRooms Rooms ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Save Building Layout', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.green)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // DEDICATED SCALE BED CAPACITY MODAL (With Floor, Rooms & Sharing Steppers + / -)
  void _openScaleBedCapacityModal() {
    int tempFloors = _scaleFloorCount;
    bool tempGroundHasRooms = _scaleGroundRooms > 0;
    int tempGfRooms = _scaleGroundRooms;
    int tempRoomsPerUpperFloor = _scaleRoomsEachFloor;
    int s1 = _scale1SharingRooms;
    int s2 = _scale2SharingRooms;
    int s3 = _scale3SharingRooms;
    int s4 = _scale4SharingRooms;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            int calculatedRooms = (tempGroundHasRooms ? tempGfRooms : 0) + ((tempFloors > 1 ? tempFloors - 1 : 0) * tempRoomsPerUpperFloor);
            int calculatedBeds = (s1 * 1) + (s2 * 2) + (s3 * 3) + (s4 * 4);
            if (calculatedBeds == 0) calculatedBeds = calculatedRooms * 2;

            return _buildModalBottomSheetWrapper(
              ctx,
              title: 'Scale Bed Capacity & Matrix',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Calculated Capacity Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Scaled Bed Capacity',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.greenDark),
                            ),
                            Text(
                              '$calculatedBeds Total Beds ($calculatedRooms Rooms)',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.greenDark),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$tempFloors Floors (G+${tempFloors - 1})',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Building Floors Selector
                  _buildModalSectionLabel('Total Building Floors'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: 'G + 1',
                        sub: '2 Floors',
                        isSelected: tempFloors == 2,
                        onTap: () => setModalState(() => tempFloors = 2),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'G + 2',
                        sub: '3 Floors',
                        isSelected: tempFloors == 3,
                        onTap: () => setModalState(() => tempFloors = 3),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'G + 3',
                        sub: '4 Floors',
                        isSelected: tempFloors == 4,
                        onTap: () => setModalState(() => tempFloors = 4),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'G + 4+',
                        sub: '5+ Floors',
                        isSelected: tempFloors >= 5,
                        onTap: () => setModalState(() => tempFloors = 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Ground Floor Rooms
                  _buildModalSectionLabel('Does Ground Floor have rooms for rent?'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: 'Yes',
                        sub: 'Has Rent Rooms',
                        isSelected: tempGroundHasRooms,
                        onTap: () => setModalState(() {
                          tempGroundHasRooms = true;
                          if (tempGfRooms == 0) tempGfRooms = 2;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: 'No',
                        sub: 'Parking / Reception',
                        isSelected: !tempGroundHasRooms,
                        onTap: () => setModalState(() {
                          tempGroundHasRooms = false;
                          tempGfRooms = 0;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Rooms per Upper Floor Selector
                  _buildModalSectionLabel('Rooms on each Upper Floor'),
                  Row(
                    children: [
                      _buildSettingsInteractiveCard(
                        title: '2',
                        sub: 'Rooms/Fl',
                        isSelected: tempRoomsPerUpperFloor == 2,
                        onTap: () => setModalState(() => tempRoomsPerUpperFloor = 2),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '3',
                        sub: 'Rooms/Fl',
                        isSelected: tempRoomsPerUpperFloor == 3,
                        onTap: () => setModalState(() => tempRoomsPerUpperFloor = 3),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '4',
                        sub: 'Rooms/Fl',
                        isSelected: tempRoomsPerUpperFloor == 4,
                        onTap: () => setModalState(() => tempRoomsPerUpperFloor = 4),
                      ),
                      const SizedBox(width: 6),
                      _buildSettingsInteractiveCard(
                        title: '5+',
                        sub: 'Rooms/Fl',
                        isSelected: tempRoomsPerUpperFloor >= 5,
                        onTap: () => setModalState(() => tempRoomsPerUpperFloor = 6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sharing Distribution Stepper Options (+ / -)
                  Text(
                    'Sharing Distribution (Rooms per type):',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStepperBox('1-Share', s1, (v) => setModalState(() => s1 = v)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStepperBox('2-Share', s2, (v) => setModalState(() => s2 = v)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStepperBox('3-Share', s3, (v) => setModalState(() => s3 = v)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStepperBox('4-Share', s4, (v) => setModalState(() => s4 = v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // White Button with Bold Green Text and Subtle Border
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _scaleFloorCount = tempFloors;
                        _scaleGroundRooms = tempGroundHasRooms ? tempGfRooms : 0;
                        _scaleRoomsEachFloor = tempRoomsPerUpperFloor;
                        _scale1SharingRooms = s1;
                        _scale2SharingRooms = s2;
                        _scale3SharingRooms = s3;
                        _scale4SharingRooms = s4;

                        _scaleTotalRooms = calculatedRooms;
                        _scaleTotalBeds = calculatedBeds;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Bed Capacity Scaled to $_scaleTotalBeds Beds ($calculatedRooms Rooms) ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Scale to $calculatedBeds Beds',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.green),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditC4RentsModal() {
    final s1RentCtrl = TextEditingController(text: _scale1SharingRent.toString());
    final s1DepCtrl = TextEditingController(text: _scale1SharingDeposit.toString());
    final s2RentCtrl = TextEditingController(text: _scale2SharingRent.toString());
    final s2DepCtrl = TextEditingController(text: _scale2SharingDeposit.toString());
    final s3RentCtrl = TextEditingController(text: _scale3SharingRent.toString());
    final s3DepCtrl = TextEditingController(text: _scale3SharingDeposit.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildModalBottomSheetWrapper(
          ctx,
          title: 'Edit Sharing Tariffs & Deposits',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildModalTextField('1-Sharing Rent', s1RentCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildModalTextField('1-Sharing Deposit', s1DepCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModalTextField('2-Sharing Rent', s2RentCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildModalTextField('2-Sharing Deposit', s2DepCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModalTextField('3-Sharing Rent', s3RentCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildModalTextField('3-Sharing Deposit', s3DepCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _scale1SharingRent = int.tryParse(s1RentCtrl.text) ?? _scale1SharingRent;
                    _scale1SharingDeposit = int.tryParse(s1DepCtrl.text) ?? _scale1SharingDeposit;
                    _scale2SharingRent = int.tryParse(s2RentCtrl.text) ?? _scale2SharingRent;
                    _scale2SharingDeposit = int.tryParse(s2DepCtrl.text) ?? _scale2SharingDeposit;
                    _scale3SharingRent = int.tryParse(s3RentCtrl.text) ?? _scale3SharingRent;
                    _scale3SharingDeposit = int.tryParse(s3DepCtrl.text) ?? _scale3SharingDeposit;
                  });
                  Navigator.of(ctx).pop();
                  _showToast('Tariffs & Deposit structure updated ✓');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Save Tariff Rates', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.green)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildSettingsInteractiveCard({
    required String title,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.green.withValues(alpha: 0.08)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.greenDark : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBox(String label, int val, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  if (val > 0) onChanged(val - 1);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Center(child: Icon(Icons.remove, size: 11, color: AppColors.ink)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('$val', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              InkWell(
                onTap: () => onChanged(val + 1),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Center(child: Icon(Icons.add, size: 11, color: AppColors.ink)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalTextField(
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildModalBottomSheetWrapper(BuildContext ctx, {required String title, required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.close, size: 15, color: AppColors.muted)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW 7: RENT & DUES COLLECTION SETTINGS
  // ===========================================================================
  Widget _buildRentSettingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Dues & Collection Rules
        _buildElevatedCard(
          title: 'Dues & Collection Rules',
          customBody: Column(
            children: [
              _buildToggleSwitchRow(
                'Accept In-App Direct UPI Payments',
                'Tenants pay via GPay/PhonePe with 0% fee. If OFF, cash only is mandated.',
                _allowOnlineUpi,
                (v) => setState(() => _allowOnlineUpi = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Auto-Debit Daily Late Fine (₹100/day)',
                'Automatically adds ₹100/day penalty for payments made after the 5th.',
                _dailyLateFineEnabled,
                (v) => setState(() => _dailyLateFineEnabled = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Accept Partial Rent Payments',
                'Allows tenants to pay rent in multiple installments across the month.',
                _acceptPartialPayments,
                (v) => setState(() => _acceptPartialPayments = v),
              ),
            ],
          ),
          rows: [],
        ),
        const SizedBox(height: 14),

        // Card 2: Automated Communication & Receipts
        _buildElevatedCard(
          title: 'Automated Reminders & Receipts',
          customBody: Column(
            children: [
              _buildToggleSwitchRow(
                'Auto-Send WhatsApp PDF Receipts',
                'Dispatches 50ms HRA-stamped PDF rent receipt instantly upon payment approval.',
                _autoSendWhatsappReceipts,
                (v) => setState(() => _autoSendWhatsappReceipts = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Automated Dues WhatsApp Reminders',
                'Sends polite payment notifications to tenants between 1st and 5th of month.',
                _autoDuesReminders,
                (v) => setState(() => _autoDuesReminders = v),
              ),
            ],
          ),
          rows: [],
        ),
        const SizedBox(height: 14),

        // Card 3: PDF Receipt Terms & Conditions
        _buildElevatedCard(
          title: 'PDF Receipt Terms & Conditions',
          onEdit: _openEditReceiptTermsModal,
          customBody: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _receiptTerms,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.ink,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          rows: [],
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 8: TENANT ONBOARDING & KYC SETTINGS
  // ===========================================================================
  Widget _buildOnboardingSettingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Tenant Onboarding Rules
        _buildElevatedCard(
          title: 'Tenant Onboarding Rules',
          customBody: Column(
            children: [
              _buildToggleSwitchRow(
                'Auto-Send Welcome WhatsApp Pack',
                'Dispatches Wi-Fi password, gate curfew rules & mess timings on check-in.',
                _autoWelcomeWhatsapp,
                (v) => setState(() => _autoWelcomeWhatsapp = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Auto-Approve Move-In Bookings',
                'Instantly locks bed when deposit is paid. If OFF, requires owner manual approval.',
                _autoApproveBookings,
                (v) => setState(() => _autoApproveBookings = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Send Advance Deposit Reminders',
                'Sends automated advance payment reminders before the move-in date.',
                _sendDepositReminders,
                (v) => setState(() => _sendDepositReminders = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Lock Resident Profile After Move-In',
                'Prevents residents from modifying their name, phone, or KYC proof post check-in.',
                _lockProfileAfterMovein,
                (v) => setState(() => _lockProfileAfterMovein = v),
              ),
            ],
          ),
          rows: [],
        ),
        const SizedBox(height: 14),

        // Card 2: Identity & KYC Verification
        _buildElevatedCard(
          title: 'Identity & Verification (KYC)',
          customBody: Column(
            children: [
              _buildToggleSwitchRow(
                'Mandatory Aadhaar KYC Verification',
                'Blocks room keycard allocation until identity documents are verified.',
                _mandatoryTenantKyc,
                (v) => setState(() => _mandatoryTenantKyc = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              _buildToggleSwitchRow(
                'Require Photo Proof for Maintenance Tickets',
                'Residents must attach a photo before submitting maintenance complaints.',
                _requireComplaintPhoto,
                (v) => setState(() => _requireComplaintPhoto = v),
              ),
              const Divider(height: 24, color: Color(0xFFEEF0F2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply KYC Verification Rule To',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Select resident stay duration scope',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _kycApplicableTo,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.ink),
                        items: ['All Residents', 'Long-Term Only'].map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _kycApplicableTo = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          rows: [],
        ),
        const SizedBox(height: 14),

        // Card 3: Digital Stamp & Signatory
        _buildElevatedCard(
          title: 'Digital Business Stamp & Seal',
          onEdit: _openEditDigitalStampModal,
          rows: [
            _DetailRow('Official Business Name', _stampBusinessName),
            _DetailRow('Authorized Signatory', _authorizedSignatory),
            _DetailRow('Stamp Application', 'Applied on all 50ms PDF Receipts', isGreen: true),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 6: ACCOUNT & SECURITY (Apple / Play Store Compliance)
  // ===========================================================================
  Widget _buildAccountView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Security & Login Credentials',
          onEdit: _openEditAccountModal,
          rows: [
            _DetailRow('App Passcode', _appPasscode, onTap: () => _openChangePasswordOtpModal(_adminPhone)),
            _DetailRow('Registered Phone', _adminPhone, onTap: _openEditAccountModal),
            _DetailRow('Registered Email', _adminEmail, onTap: _openEditAccountModal),
            _DetailRow('App Language', _appLanguage, onTap: () {
              _openEditModal(
                title: 'Select Language',
                fields: [
                  _ModalField('Language', _appLanguage, (v) => setState(() => _appLanguage = v)),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 14),

        // Session Controls
        _buildAccountActionButton(
          label: 'Logout Current Session',
          icon: Icons.logout_rounded,
          onTap: () => _showToast('Logged out from current session'),
        ),
        const SizedBox(height: 8),

        _buildAccountActionButton(
          label: 'Logout from All Devices (2 Active)',
          icon: Icons.devices_other_rounded,
          onTap: () => _showToast('Logged out from all active sessions'),
        ),
        const SizedBox(height: 8),

        // Mandatory Apple App Store Guideline 5.1.1(v) Delete Account Button
        _buildAccountActionButton(
          label: 'Delete Account',
          icon: Icons.delete_outline_rounded,
          isDanger: true,
          onTap: _openDeleteAccountModal,
        ),
      ],
    );
  }

  // ===========================================================================
  // EDIT MODAL HANDLERS
  // ===========================================================================
  Widget _buildModalDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.ink),
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalTextInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? hintText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onChanged: onChanged,
            scrollPadding: const EdgeInsets.only(bottom: 160),
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              counterText: '',
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.green.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.green : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.greenDark : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditBasicPropertyDetailsModal() {
    final nameCtrl = TextEditingController(text: _propName);
    final streetCtrl = TextEditingController(text: _streetAddress);
    final localityCtrl = TextEditingController(text: _locality);
    final landmarkCtrl = TextEditingController(text: _landmark);
    final pinCtrl = TextEditingController(text: _pincode);
    final mapCtrl = TextEditingController(text: _propMapPin);

    String tempType = _propType;
    String tempState = _selectedState;
    String tempCity = _selectedCity;
    bool isFetchingPostal = false;
    String? postalApiStatus;
    List<String> suggestedLocalities = [];

    if (_liveStatesMap.isEmpty) {
      _fetchLiveGeoData();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final effectiveStateMap = _liveStatesMap;
            final stateKeys = effectiveStateMap.keys.toList();
            if (!stateKeys.contains(tempState) && stateKeys.isNotEmpty) {
              tempState = stateKeys.contains('Karnataka') ? 'Karnataka' : stateKeys.first;
            }
            final availableCities = effectiveStateMap[tempState] ?? (tempCity.isNotEmpty ? [tempCity] : ['Loading...']);
            if (!availableCities.contains(tempCity) && availableCities.isNotEmpty) {
              tempCity = availableCities.first;
            }

            return _buildNativeBottomSheetWrapper(
              title: 'Edit Basic Property Details',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModalTextInputField(
                    label: 'Property Name',
                    controller: nameCtrl,
                    hintText: 'e.g. Greenview Luxury Coliving',
                  ),
                  const SizedBox(height: 12),

                  // Property Structure (Standard PG vs Apartment Units - Matched to Owner Setup)
                  Text(
                    'Property Structure',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: 'Standard PG',
                        sub: 'Rooms & Beds',
                        isSelected: tempType == 'Standard PG',
                        onTap: () => setModalState(() => tempType = 'Standard PG'),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: 'Apartment Units',
                        sub: '1BHK / 2BHK / 3BHK',
                        isSelected: tempType == 'Apartment Units',
                        onTap: () => setModalState(() => tempType = 'Apartment Units'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section Header for PG Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        'PG Address Details',
                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const Spacer(),
                      if (isFetchingPostal)
                        Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.green),
                            ),
                            const SizedBox(width: 5),
                            Text('API Looking up...', style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.green)),
                          ],
                        )
                      else if (postalApiStatus != null)
                        Text(postalApiStatus!, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.greenDark)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildModalTextInputField(
                    label: 'Street Address',
                    controller: streetCtrl,
                    hintText: 'Door No, Cross, Main Road',
                  ),
                  const SizedBox(height: 12),

                  _buildModalTextInputField(
                    label: 'Area / Locality',
                    controller: localityCtrl,
                    hintText: 'e.g. Koramangala 5th Block',
                  ),
                  if (suggestedLocalities.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: suggestedLocalities.map((loc) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(loc, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.greenDark)),
                              backgroundColor: AppColors.greenLight,
                              side: BorderSide(color: AppColors.green.withValues(alpha: 0.3)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setModalState(() {
                                  localityCtrl.text = loc;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  _buildModalTextInputField(
                    label: 'Nearest Landmark',
                    controller: landmarkCtrl,
                    hintText: 'e.g. Near Sony World Signal',
                  ),
                  const SizedBox(height: 12),

                  // 6-Digit Pincode (Triggers Instant Postal API Lookup)
                  _buildModalTextInputField(
                    label: '6-Digit Pincode',
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    hintText: 'e.g. 560034 (Auto-detects State & City via API)',
                    onChanged: (pin) async {
                      if (pin.length == 6) {
                        setModalState(() {
                          isFetchingPostal = true;
                          postalApiStatus = null;
                        });
                        final details = await _lookupPincodeFromApi(pin);
                        if (context.mounted) {
                          setModalState(() {
                            isFetchingPostal = false;
                            if (details != null) {
                              final fetchedState = details['state']?.toString() ?? '';
                              final fetchedCity = details['city']?.toString() ?? '';
                              final fetchedLocality = details['locality']?.toString() ?? '';
                              final List<String> locs = (details['allLocalities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                              // Match state from live API map
                              for (final st in stateKeys) {
                                if (st.toLowerCase() == fetchedState.toLowerCase()) {
                                  tempState = st;
                                  break;
                                }
                              }
                              final currentCities = effectiveStateMap[tempState] ?? [];
                              for (final c in currentCities) {
                                if (c.toLowerCase() == fetchedCity.toLowerCase()) {
                                  tempCity = c;
                                  break;
                                }
                              }
                              if (!currentCities.contains(tempCity) && fetchedCity.isNotEmpty) {
                                tempCity = fetchedCity;
                              }
                              if (localityCtrl.text.isEmpty && fetchedLocality.isNotEmpty) {
                                localityCtrl.text = fetchedLocality;
                              }
                              suggestedLocalities = locs;
                              postalApiStatus = 'Postal API Verified ✓';
                            } else {
                              postalApiStatus = 'Pincode not found';
                            }
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // State & City Cascading Dropdowns from Live Geo API
                  if (stateKeys.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Loading Indian States & Cities from Geo API...',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalDropdownField(
                            label: 'State',
                            value: tempState,
                            items: stateKeys,
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  tempState = v;
                                  final newCities = effectiveStateMap[v] ?? ['Other'];
                                  tempCity = newCities.isNotEmpty ? newCities.first : 'Other';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModalDropdownField(
                            label: 'City',
                            value: tempCity,
                            items: availableCities.contains(tempCity) ? availableCities : [tempCity, ...availableCities],
                            onChanged: (v) {
                              if (v != null) setModalState(() => tempCity = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  _buildModalTextInputField(
                    label: 'Google Maps Link / GPS Pin (Optional)',
                    controller: mapCtrl,
                    hintText: 'maps.google.com/?q=...',
                  ),
                  const SizedBox(height: 18),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _propName = nameCtrl.text.trim();
                        _propType = tempType;
                        _streetAddress = streetCtrl.text.trim();
                        _locality = localityCtrl.text.trim();
                        _landmark = landmarkCtrl.text.trim();
                        _selectedState = tempState;
                        _selectedCity = tempCity;
                        _pincode = pinCtrl.text.trim();
                        _propMapPin = mapCtrl.text.trim();

                        final parts = <String>[];
                        if (_locality.isNotEmpty) parts.add(_locality);
                        if (_selectedCity.isNotEmpty) parts.add(_selectedCity);
                        if (_pincode.isNotEmpty) parts.add(_pincode);
                        _propAddress = parts.isNotEmpty ? parts.join(', ') : _propAddress;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Property Details & Address Updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditTenantPreferencesModal() {
    String tempTenant = _tenantPreference;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Edit Tenant Preference',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select who is allowed to stay at this property (matches Owner Setup).',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Gender Category (Gents, Ladies, Co-Living)
                  Text(
                    'Gender Category',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: 'Gents',
                        sub: 'Male Only',
                        isSelected: tempTenant == 'Gents',
                        onTap: () => setModalState(() => tempTenant = 'Gents'),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: 'Ladies',
                        sub: 'Female Only',
                        isSelected: tempTenant == 'Ladies',
                        onTap: () => setModalState(() => tempTenant = 'Ladies'),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: 'Co-Living',
                        sub: 'Unisex / All',
                        isSelected: tempTenant == 'Co-Living',
                        onTap: () => setModalState(() => tempTenant = 'Co-Living'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tenantPreference = tempTenant;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Tenant Preference Updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditCurfewTimingsModal() {
    String tempCurfew = _curfewTime;
    String tempMorning = _morningOpen;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Edit Curfew & Gate Timings',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set official 12-hour curfew and morning gate open times for resident check-in.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Night Last Entry Time Tile (Interactive Clock Picker)
                  Text(
                    'Night Last Entry Time',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 22, minute: 30),
                        helpText: 'SELECT NIGHT CURFEW (12-HOUR)',
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
                        setModalState(() {
                          final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                          final minute = picked.minute.toString().padLeft(2, '0');
                          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                          tempCurfew = '$hour:$minute $period';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round, size: 18, color: AppColors.green),
                              const SizedBox(width: 10),
                              Text(
                                tempCurfew,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap Clock',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Morning Gate Open Time Tile (Interactive Clock Picker)
                  Text(
                    'Morning Gate Open Time',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 6, minute: 0),
                        helpText: 'SELECT MORNING OPEN TIME (12-HOUR)',
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
                        setModalState(() {
                          final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                          final minute = picked.minute.toString().padLeft(2, '0');
                          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                          tempMorning = '$hour:$minute $period';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny_rounded, size: 18, color: Color(0xFFD97706)),
                              const SizedBox(width: 10),
                              Text(
                                tempMorning,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap Clock',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _curfewTime = tempCurfew;
                        _morningOpen = tempMorning;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Curfew & Timings Updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditRentingTermsModal() {
    String tempDueDay = _rentDueDay;
    String tempGrace = _gracePeriod;
    bool showCustomDue = false;
    bool showCustomGrace = false;
    final customDueCtrl = TextEditingController();
    final customGraceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Edit Rent Due Date & Grace Period',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configure when monthly rent is due and grace period before late penalties apply.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 1. Monthly Rent Due Date
                  Text(
                    'Monthly Rent Due Date',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '1st',
                        sub: 'of Month',
                        isSelected: !showCustomDue && tempDueDay.startsWith('1st'),
                        onTap: () => setModalState(() {
                          tempDueDay = '1st of Every Month';
                          showCustomDue = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '5th',
                        sub: 'Default',
                        isSelected: !showCustomDue && tempDueDay.startsWith('5th'),
                        onTap: () => setModalState(() {
                          tempDueDay = '5th of Every Month';
                          showCustomDue = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '10th',
                        sub: 'of Month',
                        isSelected: !showCustomDue && tempDueDay.startsWith('10th'),
                        onTap: () => setModalState(() {
                          tempDueDay = '10th of Every Month';
                          showCustomDue = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Day',
                        sub: 'Custom',
                        isSelected: showCustomDue,
                        onTap: () => setModalState(() => showCustomDue = true),
                      ),
                    ],
                  ),
                  if (showCustomDue) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Due Date (1 to 28)',
                      controller: customDueCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 7 (will be 7th of Every Month)',
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 1 && n <= 31) {
                          String suffix = 'th';
                          if (n == 1 || n == 21 || n == 31) {
                            suffix = 'st';
                          } else if (n == 2 || n == 22) {
                            suffix = 'nd';
                          } else if (n == 3 || n == 23) {
                            suffix = 'rd';
                          }
                          tempDueDay = '$n$suffix of Every Month';
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 2. Grace Period Days (Numbers / Date)
                  Text(
                    'Grace Period Days (Before Late Fine)',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '2 Days',
                        sub: 'Grace',
                        isSelected: !showCustomGrace && tempGrace.startsWith('2'),
                        onTap: () => setModalState(() {
                          tempGrace = '2 Days';
                          showCustomGrace = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '3 Days',
                        sub: 'Default',
                        isSelected: !showCustomGrace && tempGrace.startsWith('3'),
                        onTap: () => setModalState(() {
                          tempGrace = '3 Days';
                          showCustomGrace = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '5 Days',
                        sub: 'Extended',
                        isSelected: !showCustomGrace && tempGrace.startsWith('5'),
                        onTap: () => setModalState(() {
                          tempGrace = '5 Days';
                          showCustomGrace = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '7 Days',
                        sub: '1 Week',
                        isSelected: !showCustomGrace && tempGrace.startsWith('7'),
                        onTap: () => setModalState(() {
                          tempGrace = '7 Days';
                          showCustomGrace = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Days',
                        sub: 'Custom',
                        isSelected: showCustomGrace,
                        onTap: () => setModalState(() => showCustomGrace = true),
                      ),
                    ],
                  ),
                  if (showCustomGrace) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Grace Days (Numbers Only)',
                      controller: customGraceCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 4 (4 days grace period)',
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n > 0) {
                          tempGrace = '$n Days';
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 22),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _rentDueDay = tempDueDay;
                        _gracePeriod = tempGrace;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Renting Terms Updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditStayTermsModal() {
    String tempDailyRate = _dailyRate;
    String tempLockin = _lockinPeriod;
    String tempNotice = _noticePeriod;
    String tempAgreement = _agreementDur;

    bool showCustomRate = false;
    bool showCustomLockin = false;
    bool showCustomNotice = false;
    bool showCustomAgreement = false;

    final customRateCtrl = TextEditingController();
    final customLockinCtrl = TextEditingController();
    final customNoticeCtrl = TextEditingController();
    final customAgreementCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Edit Stay & Policy Terms',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configure daily penalties, lock-in duration, notice period, and rental agreements.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 1. Daily Late Payment Penalty (₹50, ₹100, ₹200, ₹500, + Custom)
                  Text(
                    'Daily Late Payment Penalty',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '₹50',
                        sub: 'per day',
                        isSelected: !showCustomRate && tempDailyRate.contains('50'),
                        onTap: () => setModalState(() {
                          tempDailyRate = '₹50 / day';
                          showCustomRate = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '₹100',
                        sub: 'per day',
                        isSelected: !showCustomRate && tempDailyRate.contains('100'),
                        onTap: () => setModalState(() {
                          tempDailyRate = '₹100 / day';
                          showCustomRate = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '₹200',
                        sub: 'per day',
                        isSelected: !showCustomRate && tempDailyRate.contains('200'),
                        onTap: () => setModalState(() {
                          tempDailyRate = '₹200 / day';
                          showCustomRate = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '₹500',
                        sub: 'per day',
                        isSelected: !showCustomRate && tempDailyRate.contains('500'),
                        onTap: () => setModalState(() {
                          tempDailyRate = '₹500 / day';
                          showCustomRate = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Custom',
                        sub: 'Enter ₹',
                        isSelected: showCustomRate,
                        onTap: () => setModalState(() => showCustomRate = true),
                      ),
                    ],
                  ),
                  if (showCustomRate) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Daily Late Penalty (₹ / day)',
                      controller: customRateCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 150',
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null) tempDailyRate = '₹$n / day';
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 2. Minimum Lock-in Period
                  Text(
                    'Minimum Lock-in Period',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '1 Month',
                        sub: 'Short',
                        isSelected: !showCustomLockin && tempLockin.startsWith('1'),
                        onTap: () => setModalState(() {
                          tempLockin = '1 Month';
                          showCustomLockin = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '2 Months',
                        sub: 'Standard',
                        isSelected: !showCustomLockin && tempLockin.startsWith('2'),
                        onTap: () => setModalState(() {
                          tempLockin = '2 Months';
                          showCustomLockin = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '3 Months',
                        sub: 'Default',
                        isSelected: !showCustomLockin && tempLockin.startsWith('3'),
                        onTap: () => setModalState(() {
                          tempLockin = '3 Months';
                          showCustomLockin = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '6 Months',
                        sub: 'Long Term',
                        isSelected: !showCustomLockin && tempLockin.startsWith('6'),
                        onTap: () => setModalState(() {
                          tempLockin = '6 Months';
                          showCustomLockin = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Custom',
                        sub: 'Months',
                        isSelected: showCustomLockin,
                        onTap: () => setModalState(() => showCustomLockin = true),
                      ),
                    ],
                  ),
                  if (showCustomLockin) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Lock-in (Months)',
                      controller: customLockinCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 4',
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null) tempLockin = '$n Months';
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 3. Move-out Notice Period
                  Text(
                    'Move-out Notice Period',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '15 Days',
                        sub: 'Half Month',
                        isSelected: !showCustomNotice && tempNotice.startsWith('15'),
                        onTap: () => setModalState(() {
                          tempNotice = '15 Days';
                          showCustomNotice = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '30 Days',
                        sub: 'Default',
                        isSelected: !showCustomNotice && tempNotice.startsWith('30'),
                        onTap: () => setModalState(() {
                          tempNotice = '30 Days';
                          showCustomNotice = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '45 Days',
                        sub: 'Standard',
                        isSelected: !showCustomNotice && tempNotice.startsWith('45'),
                        onTap: () => setModalState(() {
                          tempNotice = '45 Days';
                          showCustomNotice = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '60 Days',
                        sub: '2 Months',
                        isSelected: !showCustomNotice && tempNotice.startsWith('60'),
                        onTap: () => setModalState(() {
                          tempNotice = '60 Days';
                          showCustomNotice = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Custom',
                        sub: 'Days',
                        isSelected: showCustomNotice,
                        onTap: () => setModalState(() => showCustomNotice = true),
                      ),
                    ],
                  ),
                  if (showCustomNotice) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Notice Period (Days)',
                      controller: customNoticeCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 20',
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null) tempNotice = '$n Days';
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 4. Agreement Duration
                  Text(
                    'Agreement Duration',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInteractiveCard(
                        title: '6 Months',
                        sub: 'Half Year',
                        isSelected: !showCustomAgreement && tempAgreement.startsWith('6'),
                        onTap: () => setModalState(() {
                          tempAgreement = '6 Months';
                          showCustomAgreement = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '11 Months',
                        sub: 'Standard',
                        isSelected: !showCustomAgreement && tempAgreement.startsWith('11'),
                        onTap: () => setModalState(() {
                          tempAgreement = '11 Months Standard';
                          showCustomAgreement = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '12 Months',
                        sub: '1 Year',
                        isSelected: !showCustomAgreement && tempAgreement.startsWith('12'),
                        onTap: () => setModalState(() {
                          tempAgreement = '12 Months (1 Year)';
                          showCustomAgreement = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '24 Months',
                        sub: '2 Years',
                        isSelected: !showCustomAgreement && tempAgreement.startsWith('24'),
                        onTap: () => setModalState(() {
                          tempAgreement = '24 Months (2 Years)';
                          showCustomAgreement = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      _buildInteractiveCard(
                        title: '+ Custom',
                        sub: 'Months',
                        isSelected: showCustomAgreement,
                        onTap: () => setModalState(() => showCustomAgreement = true),
                      ),
                    ],
                  ),
                  if (showCustomAgreement) ...[
                    const SizedBox(height: 8),
                    _buildModalTextInputField(
                      label: 'Enter Custom Agreement Duration',
                      controller: customAgreementCtrl,
                      keyboardType: TextInputType.text,
                      hintText: 'e.g. 18 Months',
                      onChanged: (v) {
                        if (v.trim().isNotEmpty) tempAgreement = v.trim();
                      },
                    ),
                  ],
                  const SizedBox(height: 22),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _dailyRate = tempDailyRate;
                        _lockinPeriod = tempLockin;
                        _noticePeriod = tempNotice;
                        _agreementDur = tempAgreement;
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Stay & Policy Terms Updated ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditReceiptTermsModal() {
    final ctrl = TextEditingController(text: _receiptTerms);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Edit PDF Receipt Terms',
          modalContext: ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'These terms are permanently printed at the bottom of all generated HRA-compliant PDF rent receipts.',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 6,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _receiptTerms = ctrl.text.trim());
                  Navigator.of(ctx).pop();
                  _showToast('Receipt Terms & Conditions Updated ✓');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Save Receipt Terms', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openEditDigitalStampModal() {
    final busCtrl = TextEditingController(text: _stampBusinessName);
    final signCtrl = TextEditingController(text: _authorizedSignatory);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Edit Digital Business Stamp',
          modalContext: ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Official Business Name', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: busCtrl,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Authorized Signatory & Role', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: signCtrl,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _stampBusinessName = busCtrl.text.trim();
                    _authorizedSignatory = signCtrl.text.trim();
                  });
                  Navigator.of(ctx).pop();
                  _showToast('Digital Stamp & Seal Updated ✓');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Save Digital Stamp', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openEditAccountModal() {
    final phoneCtrl = TextEditingController(text: _adminPhone);
    final emailCtrl = TextEditingController(text: _adminEmail);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Edit Account Credentials',
          modalContext: ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registered Mobile Number', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Official Admin Email', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Change Password Action Tile (Sends OTP to main number)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.ink),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Passcode',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          Text(
                            'Update passcode via SMS OTP to $_adminPhone',
                            style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openChangePasswordOtpModal(_adminPhone);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Change',
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _adminPhone = phoneCtrl.text.trim();
                    _adminEmail = emailCtrl.text.trim();
                  });
                  Navigator.of(ctx).pop();
                  _showToast('Account Credentials Updated Successfully ✓');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Account Details',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openChangePasswordOtpModal(String phone) {
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscurePass = true;

    // Trigger simulated OTP dispatch to phone
    _showToast('6-Digit OTP sent to $phone via SMS');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildNativeBottomSheetWrapper(
              title: 'Change Account Passcode',
              modalContext: ctx,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 20, color: AppColors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.ink, height: 1.35),
                              children: [
                                const TextSpan(text: 'An OTP has been dispatched to your registered primary number: '),
                                TextSpan(
                                  text: phone,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.greenDark),
                                ),
                                const TextSpan(text: '. Enter the 6-digit code below to set your new password.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6-digit OTP Field
                  Text('Enter 6-Digit OTP', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • • • •',
                      hintStyle: GoogleFonts.outfit(fontSize: 16, letterSpacing: 6, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // New Passcode Field
                  Text('New 6-Digit Passcode', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: obscurePass,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Enter new 6-digit passcode',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.muted),
                        onPressed: () => setModalState(() => obscurePass = !obscurePass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Passcode Field
                  Text('Confirm New Passcode', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPassCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: obscurePass,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Re-enter new 6-digit passcode',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Resend OTP link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showToast('New OTP resent to $phone');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greenDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Submit Button
                  OutlinedButton(
                    onPressed: () {
                      final otp = otpCtrl.text.trim();
                      final p1 = newPassCtrl.text.trim();
                      final p2 = confirmPassCtrl.text.trim();

                      if (otp.length < 6) {
                        _showToast('Please enter the full 6-digit OTP');
                        return;
                      }
                      if (p1.length < 4) {
                        _showToast('Passcode must be at least 4-6 digits');
                        return;
                      }
                      if (p1 != p2) {
                        _showToast('New passcodes do not match');
                        return;
                      }

                      setState(() {
                        _appPasscode = '••••••••';
                      });
                      Navigator.of(ctx).pop();
                      _showToast('Password Updated Successfully via OTP ✓');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Verify OTP & Change Password',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // REUSABLE TOGGLE SWITCH ROW (Clean Executive Standard)
  // ===========================================================================
  Widget _buildToggleSwitchRow(String title, String subtitle, bool isEnabled, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () {
        onChanged(!isEnabled);
        _showToast('$title toggled ${!isEnabled ? "ON" : "OFF"}');
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.greenLight : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled ? AppColors.green.withValues(alpha: 0.4) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Text(
                isEnabled ? 'ON' : 'OFF',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isEnabled ? AppColors.greenDark : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isDanger ? const Color(0xFFDC2626) : AppColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDanger ? const Color(0xFFDC2626) : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDeleteAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: 'Delete UrbanStay Account',
          modalContext: ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This will permanently delete your Greenview PG data, tenant records, and direct UPI configuration. This action cannot be undone.',
                style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showToast('Account Deletion Requested • Verification OTP Sent');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Permanent Deletion',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // REUSABLE ELEVATED CARD & ROW COMPONENTS
  // ===========================================================================
  Widget _buildElevatedCard({
    required String title,
    VoidCallback? onEdit,
    Widget? headerExtra,
    required List<_DetailRow> rows,
    Widget? footer,
    Widget? customBody,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (headerExtra != null) headerExtra,
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEF0F2)),
          const SizedBox(height: 8),

          if (customBody != null)
            customBody
          else
            ...rows.map((r) => _buildDetailRowItem(r)).toList(),

          if (footer != null) footer,
        ],
      ),
    );
  }

  Widget _buildDetailRowItem(_DetailRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              row.label,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                row.val,
                textAlign: TextAlign.right,
                style: row.isCode
                    ? GoogleFonts.firaCode(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: row.isGreen ? AppColors.greenDark : AppColors.ink,
                      )
                    : GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: row.isGreen ? AppColors.greenDark : AppColors.ink,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW 7: AUTOMATION & OPERATIONAL POLICY RULES
  // ===========================================================================
  Widget _buildAutomationPolicyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildElevatedCard(
          title: 'Automated Communication & Billing',
          rows: [],
          customBody: Column(
            children: [
              _buildToggleRow(
                'Auto-Send WhatsApp PDF Receipts',
                'Dispatches 50ms rent receipt immediately upon UTR approval',
                _autoSendWhatsappReceipts,
                (val) {
                  setState(() => _autoSendWhatsappReceipts = val);
                  _showToast(val
                      ? '✓ Auto WhatsApp Receipts Enabled'
                      : 'Auto WhatsApp Receipts Disabled (Silent Recording)');
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEF0F2)),
              const SizedBox(height: 16),
              _buildToggleRow(
                'Daily Late Fine Auto-Debit (₹100/day)',
                'Adds ₹100/day penalty after 5th of every month',
                _dailyLateFineEnabled,
                (val) {
                  setState(() => _dailyLateFineEnabled = val);
                  _showToast(val
                      ? '✓ Daily Late Fine Active (₹100/day after 5th)'
                      : 'Late Fine Enforcement Waived');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildElevatedCard(
          title: 'Tenant Verification & Mess Policies',
          rows: [],
          customBody: Column(
            children: [
              _buildToggleRow(
                'Mandatory Tenant KYC & Aadhaar',
                'Requires Aadhaar verification and owner approval before bed lock',
                _mandatoryTenantKyc,
                (val) {
                  setState(() => _mandatoryTenantKyc = val);
                  _showToast(val
                      ? '✓ Mandatory Tenant KYC Active'
                      : 'Direct Self Check-In Enabled (No KYC Block)');
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEF0F2)),
              const SizedBox(height: 16),
              _buildToggleRow(
                'Food Mess Meal Attendance RSVP',
                'Requires residents to confirm meals to avoid cook ration waste',
                _foodMessRsvpEnabled,
                (val) {
                  setState(() => _foodMessRsvpEnabled = val);
                  _showToast(val
                      ? '✓ Food Mess RSVP Active (Cook Headcount Tracked)'
                      : 'Flat Occupancy Headcount Enabled');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, String desc, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              Text(
                desc,
                style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        _buildToggleSwitch(val, onChanged),
      ],
    );
  }

  Widget _buildToggleSwitch(bool val, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!val),
      child: Container(
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: val ? AppColors.green : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: val ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x15000000), blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL: DYNAMIC EDIT BOTTOM SHEET
  // ===========================================================================
  void _openEditModal({required String title, required List<_ModalField> fields}) {
    final controllers = fields.map((f) => TextEditingController(text: f.initialVal)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildNativeBottomSheetWrapper(
          title: title,
          modalContext: ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...List.generate(fields.length, (i) {
                final labelLower = fields[i].label.toLowerCase();
                final isPhone = labelLower.contains('phone') || labelLower.contains('mobile');
                final isEmail = labelLower.contains('email');
                final isNumber = labelLower.contains('pin') || labelLower.contains('passcode');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fields[i].label,
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        ),
                        child: TextField(
                          controller: controllers[i],
                          keyboardType: isPhone
                              ? TextInputType.phone
                              : (isEmail
                                  ? TextInputType.emailAddress
                                  : (isNumber ? TextInputType.number : TextInputType.text)),
                          scrollPadding: const EdgeInsets.only(bottom: 160),
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {
                  for (int i = 0; i < fields.length; i++) {
                    fields[i].onSave(controllers[i].text.trim());
                  }
                  Navigator.of(ctx).pop();
                  _showToast('$title Saved ✓');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.green),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNativeBottomSheetWrapper({
    required String title,
    required Widget child,
    BuildContext? modalContext,
  }) {
    final effectiveCtx = modalContext ?? context;
    final bottomInset = MediaQuery.of(effectiveCtx).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(effectiveCtx).size.height * 0.88),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(effectiveCtx).pop(),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Icon(Icons.close, size: 15, color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helpers
class _DetailRow {
  final String label;
  final String val;
  final bool isCode;
  final bool isGreen;
  final VoidCallback? onTap;

  _DetailRow(this.label, this.val, {this.isCode = false, this.isGreen = false, this.onTap});
}

class _ModalField {
  final String label;
  final String initialVal;
  final ValueChanged<String> onSave;

  _ModalField(this.label, this.initialVal, this.onSave);
}
