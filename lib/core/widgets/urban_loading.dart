// ==============================================================================
// 🕉️ URBANSTAY — BRANDED ENTERPRISE LOADING SPINNER & OVERLAY
// 🌟 Om Shri Raghavendraya Namaha ✨
// ==============================================================================
// Custom 8-pill green spoke activity spinner modeled after the UrbanStay design.
// Can be used anywhere: center of screen, modal dialog, or embedded card.
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 1. The Custom 8-Pill Green Rotating Spinner
class UrbanSpinner extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color? color;

  const UrbanSpinner({
    super.key,
    this.size = 56.0,
    this.duration = const Duration(milliseconds: 900),
    this.color,
  });

  @override
  State<UrbanSpinner> createState() => _UrbanSpinnerState();
}

class _UrbanSpinnerState extends State<UrbanSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SpokePillPainter(color: widget.color),
      ),
    );
  }
}

/// Custom painter that renders the 8 radial pill spokes in alternating UrbanStay greens
class _SpokePillPainter extends CustomPainter {
  final Color? color;
  _SpokePillPainter({this.color});

  // Brand colors from the verified design
  static const Color lightGreen = Color(0xFF77C943);
  static const Color darkGreen = Color(0xFF2C863E);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pillWidth = size.width * 0.17;
    final pillHeight = size.height * 0.30;
    final distanceFromCenter = size.width * 0.28;
    final radius = Radius.circular(pillWidth / 2);

    // 8 spokes positioned at 45-degree intervals
    // Index 7 (top-right at 315 deg) is omitted to create the signature gap
    final List<Color?> spokeColors = color != null
        ? [
            color!,
            color!.withValues(alpha: 0.5),
            color!,
            color!.withValues(alpha: 0.5),
            color!,
            color!.withValues(alpha: 0.5),
            color!,
            null,
          ]
        : [
            lightGreen, // 0: Top (270°)
            darkGreen,  // 1: Top-Left (225°)
            lightGreen, // 2: Left (180°)
            darkGreen,  // 3: Bottom-Left (135°)
            lightGreen, // 4: Bottom (90°)
            darkGreen,  // 5: Bottom-Right (45°)
            lightGreen, // 6: Right (0°)
            null,       // 7: Top-Right (gap/omitted)
          ];

    for (int i = 0; i < 8; i++) {
      final color = spokeColors[i];
      if (color == null) continue; // Skip the gap spoke

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.save();
      // Translate to center, rotate, and draw pill
      canvas.translate(center.dx, center.dy);
      // Angle: index 0 is top (-90 degrees), each step is -45 degrees
      final angle = (-math.pi / 2) - (i * (math.pi / 4));
      canvas.rotate(angle);

      final rect = Rect.fromCenter(
        center: Offset(0, -distanceFromCenter),
        width: pillWidth,
        height: pillHeight,
      );

      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Centered Pure White Elevated Placeholder Card
class UrbanLoadingCard extends StatelessWidget {
  final String? message;
  final double spinnerSize;

  const UrbanLoadingCard({
    super.key,
    this.message,
    this.spinnerSize = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground, // Pure white
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UrbanSpinner(size: spinnerSize),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 3. Full-Screen Screen Overlay with Soft White Backdrop
class UrbanLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const UrbanLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.65),
              child: UrbanLoadingCard(message: message),
            ),
          ),
      ],
    );
  }
}

/// 4. Global Application-Wide Loading Service
/// Used by SupabaseService to trigger spinner across the entire app
class UrbanLoadingService {
  UrbanLoadingService._();

  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> message = ValueNotifier<String?>(null);

  /// Show the global spinner with an optional message
  static void show([String? msg]) {
    message.value = msg;
    isLoading.value = true;
  }

  /// Hide the global spinner
  static void hide() {
    isLoading.value = false;
    message.value = null;
  }
}

/// 5. Convenience Modal Dialog Helpers
/// Call `showUrbanLoading(context, message: 'Saving...')` anywhere in the app!
void showUrbanLoading(BuildContext context, {String? message}) {
  UrbanLoadingService.show(message);
}

/// Dismiss the loading dialog
void hideUrbanLoading(BuildContext context) {
  UrbanLoadingService.hide();
}

