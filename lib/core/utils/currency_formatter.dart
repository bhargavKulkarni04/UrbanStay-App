/// Standard Indian Currency Formatter (en_IN format)
/// Adheres to Indian numbering system (thousands, lakhs, crores)
/// Ensures standard formatting across all database models and UI screens.
class AppCurrency {
  AppCurrency._();

  /// Formats a numeric value into Indian Rupee format with standard commas
  /// e.g. 1500 -> "₹1,500", 15000 -> "₹15,000", 150000 -> "₹1,50,000"
  static String format(num amount, {bool includeSymbol = true}) {
    final isNegative = amount < 0;
    final absVal = amount.abs().round();
    final str = absVal.toString();

    String result;
    if (str.length <= 3) {
      result = str;
    } else {
      // Last 3 digits
      final lastThree = str.substring(str.length - 3);
      // Remaining leading digits formatted in groups of 2 (Indian lakh/crore system)
      final remaining = str.substring(0, str.length - 3);
      final formattedRemaining = _formatIndianDigits(remaining);
      result = '$formattedRemaining,$lastThree';
    }

    final prefix = isNegative ? '-' : '';
    return includeSymbol ? '$prefix₹$result' : '$prefix$result';
  }

  /// Groups leading digits by 2s according to Indian numbering standard
  static String _formatIndianDigits(String digits) {
    if (digits.length <= 2) return digits;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count == 2 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
