/// ==============================================================================
/// EXPENSE_MODEL.DART
/// Purpose: Strongly-typed Dart class for Operating Expenses (OpEx) & Ledger
/// Matches: public.expenses table in Supabase
/// Source: supabase/migrations/04_create_operations_and_staff_tables.sql
/// ==============================================================================

class ExpenseModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String title;
  final String category;
  final String? vendor;
  final double amount;
  final String paymentMode;
  final String? receiptUrl;
  final DateTime expenseDate;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.propertyId,
    this.propertyName = '',
    required this.title,
    this.category = 'Maintenance',
    this.vendor,
    required this.amount,
    this.paymentMode = 'UPI',
    this.receiptUrl,
    required this.expenseDate,
    this.createdAt,
  });

  /// Formatted date string (YYYY-MM-DD)
  String get formattedDate {
    final y = expenseDate.year.toString().padLeft(4, '0');
    final m = expenseDate.month.toString().padLeft(2, '0');
    final d = expenseDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Backward compatible alias for title
  String? get notes => title;

  /// Deserializer from Supabase JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0);

    DateTime parsedExpenseDate;
    if (json['expense_date'] != null) {
      parsedExpenseDate =
          DateTime.tryParse(json['expense_date'].toString()) ?? DateTime.now();
    } else {
      parsedExpenseDate = DateTime.now();
    }

    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      propertyName: json['property_name']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Expense',
      category: json['category']?.toString() ?? 'Maintenance',
      vendor: json['vendor']?.toString(),
      amount: amount,
      paymentMode: json['payment_mode']?.toString() ?? 'UPI',
      receiptUrl: json['receipt_url']?.toString(),
      expenseDate: parsedExpenseDate,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializer to Supabase JSON
  Map<String, dynamic> toJson({bool includeId = false}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (propertyName.isNotEmpty) 'property_name': propertyName,
      'title': title,
      'category': category,
      if (vendor != null && vendor!.trim().isNotEmpty) 'vendor': vendor!.trim(),
      'amount': amount,
      'payment_mode': paymentMode,
      if (receiptUrl != null && receiptUrl!.isNotEmpty)
        'receipt_url': receiptUrl,
      'expense_date': formattedDate,
    };
  }

  /// CopyWith helper
  ExpenseModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? title,
    String? category,
    String? vendor,
    double? amount,
    String? paymentMode,
    String? receiptUrl,
    DateTime? expenseDate,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      title: title ?? this.title,
      category: category ?? this.category,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
