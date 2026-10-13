import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// ==============================================================================
/// URBANSTAY — MASTER OWNER GLOBAL APP STATE (OwnerAppState)
/// Single Source of Truth for all Owner Screens & Modules
/// ==============================================================================
class OwnerAppState extends ChangeNotifier {
  // Singleton pattern for centralized global access
  static final OwnerAppState instance = OwnerAppState._internal();
  factory OwnerAppState() => instance;
  OwnerAppState._internal();

  // ---------------------------------------------------------------------------
  // 🏢 1. PROPERTY & MULTI-BUILDING STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _properties = [];
  int _activePropertyIndex = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get properties => List.unmodifiable(_properties);
  int get activePropertyIndex => _activePropertyIndex;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? get activeProperty {
    if (_properties.isEmpty) return null;
    if (_activePropertyIndex >= _properties.length) _activePropertyIndex = 0;
    return _properties[_activePropertyIndex];
  }

  String get activePropertyId =>
      activeProperty?['id']?.toString() ??
      SupabaseService.instance.activePropertyId ??
      '';

  String get activePropertyName =>
      activeProperty?['property_name']?.toString() ??
      activeProperty?['name']?.toString() ??
      activeProperty?['brand_name']?.toString() ??
      '';

  String get activePropertyCode =>
      activeProperty?['code']?.toString() ??
      activeProperty?['property_code']?.toString() ??
      '';

  String get activePropertyLocation =>
      activeProperty?['location']?.toString() ??
      activeProperty?['area_locality']?.toString() ??
      '';

  int get totalBeds =>
      (activeProperty?['total_beds'] as num?)?.toInt() ??
      (activeProperty?['totalBeds'] as num?)?.toInt() ??
      0;

  int get occupiedBeds =>
      (activeProperty?['occupiedBeds'] as num?)?.toInt() ?? 0;

  int get vacantBeds {
    final v = (activeProperty?['vacantBeds'] as num?)?.toInt();
    if (v != null) return v;
    return (totalBeds - occupiedBeds).clamp(0, totalBeds);
  }

  int get noticeBeds =>
      (activeProperty?['noticeBeds'] as num?)?.toInt() ?? 0;

  String get occupancyPct {
    if (totalBeds == 0) return '0% Full';
    return '${((occupiedBeds / totalBeds) * 100).round()}% Full';
  }

  int get activeStaffCount =>
      (activeProperty?['staffCount'] as num?)?.toInt() ?? _staffMembers.length;

  // ---------------------------------------------------------------------------
  // 📊 2. COLLECTION HEALTH & FINANCIAL METRICS STORE
  // ---------------------------------------------------------------------------
  int get paidBedsCount =>
      _rentLedgers.where((r) => r['status'] == 'paid' || r['status'] == 'PAID').length;

  int get pendingBedsCount =>
      _rentLedgers.where((r) => r['status'] != 'paid' && r['status'] != 'PAID').length;

  int get overdueBedsCount =>
      _rentLedgers.where((r) => r['isOverdue'] == true).length;

  String get monthlyCollectedFormatted {
    int total = 0;
    for (final r in _rentLedgers) {
      if (r['status'] == 'paid' || r['status'] == 'PAID') {
        final rawAmt = r['rent_amount'] ?? r['amount'] ?? r['due_amount'];
        total += ((rawAmt as num?)?.toInt() ?? 0);
      }
    }
    return '₹$total';
  }

  String get collectionRatioFormatted {
    return '$paidBedsCount/$totalBeds Beds';
  }

  // ---------------------------------------------------------------------------
  // 💰 3. PAYMENT APPROVALS HUB (0% Direct UPI Queue)
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _pendingApprovals = [];
  final List<Map<String, dynamic>> _approvalHistory = [];

  List<Map<String, dynamic>> get pendingApprovals =>
      List.unmodifiable(_pendingApprovals);
  List<Map<String, dynamic>> get approvalHistory =>
      List.unmodifiable(_approvalHistory);

  int get pendingApprovalsCount => _pendingApprovals.length;
  int get approvedPaymentsCount =>
      _approvalHistory.where((a) => a['status'] == 'approved').length;
  int get totalSubmittedPaymentsCount =>
      _pendingApprovals.length + _approvalHistory.length;

  // ---------------------------------------------------------------------------
  // 🚪 4. ROOMS & BED MATRIX STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _rooms = [];

  List<Map<String, dynamic>> get rooms => List.unmodifiable(_rooms);

  // ---------------------------------------------------------------------------
  // 📅 5. RENT COLLECTION & DAY-WISE SALARY SCHEDULE STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _floorsRentData = [];
  final List<Map<String, dynamic>> _rentLedgers = [];
  final List<Map<String, dynamic>> _dayWiseSchedules = [];

  List<Map<String, dynamic>> get floorsRentData =>
      List.unmodifiable(_floorsRentData);
  List<Map<String, dynamic>> get rentLedgers =>
      List.unmodifiable(_rentLedgers);
  List<Map<String, dynamic>> get dayWiseSchedules =>
      List.unmodifiable(_dayWiseSchedules);

  // ---------------------------------------------------------------------------
  // 🧾 6. OPERATING EXPENSES & P&L STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _expenses = [];

  List<Map<String, dynamic>> get expenses => List.unmodifiable(_expenses);

  double get totalExpensesAmount {
    double total = 0;
    for (final e in _expenses) {
      total += ((e['amount'] as num?)?.toDouble() ?? 0.0);
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // 👥 7. STAFF DIRECTORY STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _staffMembers = [];

  List<Map<String, dynamic>> get staffMembers =>
      List.unmodifiable(_staffMembers);

  // ---------------------------------------------------------------------------
  // 🔧 8. MAINTENANCE & COMPLAINTS STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _complaints = [];

  List<Map<String, dynamic>> get complaints => List.unmodifiable(_complaints);

  int get pendingComplaintsCount =>
      _complaints.where((c) => c['status'] == 'open' || c['status'] == 'in_progress').length;

  // ---------------------------------------------------------------------------
  // 📢 9. ANNOUNCEMENTS NOTICE BOARD STORE
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _announcements = [];

  List<Map<String, dynamic>> get announcements =>
      List.unmodifiable(_announcements);

  // ---------------------------------------------------------------------------
  // 💳 10. SAAS SOFTWARE LICENSING STORE (₹15/bed + ₹79 platform)
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _saasInvoices = [];

  List<Map<String, dynamic>> get saasInvoices =>
      List.unmodifiable(_saasInvoices);

  int get licensingBaseRate => totalBeds * 15;
  int get licensingPlatformFee => totalBeds > 0 ? 79 : 0;
  int get monthlySaasDues => licensingBaseRate + licensingPlatformFee;

  // ===========================================================================
  // 🔄 STATE MUTATIONS & ACTIONS
  // ===========================================================================

  /// Sets or updates the active property immediately (e.g. from Owner Setup)
  void setActiveProperty(Map<String, dynamic> property) {
    final existingIndex = _properties.indexWhere(
        (p) => p['id']?.toString() == property['id']?.toString() ||
               (property['code'] != null && p['code'] == property['code']));

    if (existingIndex >= 0) {
      _properties[existingIndex] = Map<String, dynamic>.from(property);
      _activePropertyIndex = existingIndex;
    } else {
      _properties.insert(0, Map<String, dynamic>.from(property));
      _activePropertyIndex = 0;
    }

    notifyListeners();
  }

  /// Switches active property index in multi-building dropdown
  void switchProperty(int index) {
    if (index >= 0 && index < _properties.length) {
      _activePropertyIndex = index;
      notifyListeners();
      hydrateFromSupabase();
    }
  }

  /// Hydrate all modules for the active property from Supabase
  Future<void> hydrateFromSupabase() async {
    final propId = activePropertyId;
    if (propId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch live bed metrics
      final metrics = await SupabaseService.instance.getBedMetrics(propId);
      if (activeProperty != null) {
        final total = metrics['total'] ?? totalBeds;
        final occ = metrics['occupied'] ?? occupiedBeds;
        _properties[_activePropertyIndex]['totalBeds'] = total;
        _properties[_activePropertyIndex]['occupiedBeds'] = occ;
        _properties[_activePropertyIndex]['vacantBeds'] = (total - occ).clamp(0, total);
        _properties[_activePropertyIndex]['occupancyPct'] =
            total > 0 ? '${((occ / total) * 100).round()}% Full' : '0% Full';
      }

      // 2. Fetch live rooms
      final roomsList = await SupabaseService.instance.getRooms(propId);
      _rooms.clear();
      _rooms.addAll(roomsList);

      // 3. Fetch monthly rent ledger
      final ledger = await SupabaseService.instance.getMonthlyRentLedger(propId);
      _rentLedgers.clear();
      _rentLedgers.addAll(ledger);

      // 4. Fetch SaaS Invoices
      final invoices = await SupabaseService.instance.getSaasInvoices(propertyId: propId);
      _saasInvoices.clear();
      _saasInvoices.addAll(invoices);
    } catch (e) {
      debugPrint('OwnerAppState Supabase hydration note: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approves a pending UPI payment submission
  void approveUpiPayment(String id, {String? receiptNo}) {
    final itemIndex = _pendingApprovals.indexWhere((a) => a['id'] == id);
    if (itemIndex != -1) {
      final approved = Map<String, dynamic>.from(_pendingApprovals[itemIndex]);
      approved['status'] = 'approved';
      approved['receiptNo'] = receiptNo ?? 'REC-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}';
      approved['settledTime'] = 'Just now';
      _pendingApprovals.removeAt(itemIndex);
      _approvalHistory.insert(0, approved);
      notifyListeners();
    }
  }

  /// Rejects a pending UPI payment submission
  void rejectUpiPayment(String id, String reason) {
    final itemIndex = _pendingApprovals.indexWhere((a) => a['id'] == id);
    if (itemIndex != -1) {
      final rejected = Map<String, dynamic>.from(_pendingApprovals[itemIndex]);
      rejected['status'] = 'rejected';
      rejected['rejectReason'] = reason;
      rejected['settledTime'] = 'Just now';
      _pendingApprovals.removeAt(itemIndex);
      _approvalHistory.insert(0, rejected);
      notifyListeners();
    }
  }

  /// Adds a new expense entry
  void addExpense(Map<String, dynamic> expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  /// Adds a new announcement
  void addAnnouncement(Map<String, dynamic> announcement) {
    _announcements.insert(0, announcement);
    notifyListeners();
  }

  /// Clears state (e.g. on sign out)
  void clearAll() {
    _properties.clear();
    _activePropertyIndex = 0;
    _pendingApprovals.clear();
    _approvalHistory.clear();
    _rooms.clear();
    _floorsRentData.clear();
    _rentLedgers.clear();
    _dayWiseSchedules.clear();
    _expenses.clear();
    _staffMembers.clear();
    _complaints.clear();
    _announcements.clear();
    _saasInvoices.clear();
    notifyListeners();
  }
}
