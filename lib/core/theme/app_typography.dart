import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Official Master Typography Tokens for UrbanStay Application.
/// Strict adherence to Google Font 'Outfit' hierarchy in AGENTS.md.
class AppTypography {
  AppTypography._();

  static TextStyle heading1 = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static TextStyle heading2 = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static TextStyle heading3 = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.25,
  );

  static TextStyle bodyRegular = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.45,
  );

  static TextStyle bodySemiBold = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.45,
  );

  static TextStyle subtitleMuted = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.45,
  );

  static TextStyle captionSmall = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
    letterSpacing: 1.2,
  );
}
