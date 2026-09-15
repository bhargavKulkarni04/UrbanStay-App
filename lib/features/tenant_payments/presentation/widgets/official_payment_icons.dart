import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 🇮🇳 Official Authentic Payment Brand Logos (Loaded from Verified Vector SVGs)
class OfficialPaymentIcons {
  OfficialPaymentIcons._();

  /// 🟢 Official NPCI UPI Vector Logo
  static Widget upiLogo({double width = 50, double height = 18}) {
    return SvgPicture.asset(
      'assets/images/upi.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// 🌐 Official Google Pay Vector Logo
  static Widget googlePay({double width = 55, double height = 22}) {
    return SvgPicture.asset(
      'assets/images/gpay.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// 🟣 Official PhonePe Vector Logo
  static Widget phonePe({double width = 64, double height = 22}) {
    return SvgPicture.asset(
      'assets/images/phonepe.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// 🔵 Official Paytm Vector Logo
  static Widget paytm({double width = 52, double height = 18}) {
    return SvgPicture.asset(
      'assets/images/paytm.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// 🛡️ Official NPCI Security Lockup Badge
  static Widget npciSecurityLockup() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        upiLogo(width: 38, height: 14),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 12,
          color: const Color(0xFFD1D5DB),
        ),
        const SizedBox(width: 8),
        const Text(
          'NPCI Certified 256-Bit SSL • Official Direct Bank Rails',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
