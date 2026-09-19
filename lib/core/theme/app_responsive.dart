import 'package:flutter/material.dart';

/// Universal fluid responsiveness extension for UrbanStay.
/// Calculates all dimensions dynamically as percentages of the active screen.
/// Zero hardcoded widths, zero hardcoded heights.
extension ResponsiveContext on BuildContext {
  /// Active screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Active screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Safe area top padding (notch / status bar).
  double get paddingTop => MediaQuery.paddingOf(this).top;

  /// Safe area bottom padding (home bar / navigation bar).
  double get paddingBottom => MediaQuery.paddingOf(this).bottom;

  /// Dynamic horizontal padding that scales naturally with screen width.
  /// (e.g. 14px on 320px screens, 18px on 400px screens, 24px on wide screens).
  double get responsiveHorizontalPadding => (screenWidth * 0.045).clamp(14.0, 24.0);

  /// Dynamic vertical padding that scales naturally with screen height.
  double get responsiveVerticalPadding => (screenHeight * 0.02).clamp(10.0, 20.0);

  /// Dynamic percentage of screen width (e.g. `context.wp(50)` = 50% of screen width).
  double wp(double percent) => screenWidth * (percent / 100);

  /// Dynamic percentage of screen height (e.g. `context.hp(20)` = 20% of screen height).
  double hp(double percent) => screenHeight * (percent / 100);

  /// Whether current device is a tablet or desktop display (> 600px).
  bool get isTabletOrDesktop => screenWidth > 600;
}
