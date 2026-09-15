import 'package:flutter/material.dart';

/// Official Master Color Palette for UrbanStay Application.
/// Strict adherence to verified design tokens in AGENTS.md.
class AppColors {
  AppColors._();

  // Primary Brand Greens
  static const Color green = Color(0xFF08A63F);
  static const Color greenDark = Color(0xFF068237);
  static const Color greenLight = Color(0xFFEBF8EE);
  static const Color greenTint = Color(0x1408A63F);

  // Inks & Typography
  static const Color ink = Color(0xFF111111);
  static const Color inkSecondary = Color(0xFF374151);
  static const Color muted = Color(0xFF6B7280);
  static const Color lightMuted = Color(0xFF9CA3AF);

  // Backgrounds & Borders
  static const Color pageBg = Color(0xFFF4F6F9);
  static const Color backgroundPage = Color(0xFFF4F6F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderCard = Color(0xFFEEF0F2);

  // Functional Status Colors
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEEF2FF);
}
