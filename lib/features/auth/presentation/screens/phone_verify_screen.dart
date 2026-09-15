import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'role_selector_screen.dart';

/// Screen 2: Phone Number & 6-Digit OTP Verification.
/// 1-to-1 exact replication of `ProductionCode/phone_verify.html`.
/// Features clean header, phone input step, OTP step with auto-advance digit boxes,
/// 28s resend countdown timer, and bottom Bengaluru skyline marquee signature.
class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen>
    with TickerProviderStateMixin {
  // Mode: false = Phone Input, true = OTP Verification
  bool _isOtpStep = false;
  bool _isVerified = false;

  // Controllers & Focus Nodes
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Resend Timer
  int _timerSeconds = 28;
  Timer? _countdownTimer;
  bool _canResend = false;

  // Skyline Marquee Animation (Slow, graceful 24s continuous glide)
  late final AnimationController _skylineAnimController;

  // Verification Pop-up Animation
  late final AnimationController _verifiedAnimController;
  late final Animation<double> _verifiedScaleAnim;
  late final Animation<double> _verifiedFadeAnim;

  @override
  void initState() {
    super.initState();
    // 24-second calm, slow, graceful marquee translation matching phone_verify.html
    _skylineAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // Verification checkmark pop-up animation
    _verifiedAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _verifiedScaleAnim = CurvedAnimation(
      parent: _verifiedAnimController,
      curve: Curves.elasticOut,
    );

    _verifiedFadeAnim = CurvedAnimation(
      parent: _verifiedAnimController,
      curve: Curves.easeIn,
    );
  }

  void _startOtpTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerSeconds = 28;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSeconds > 1) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _timerSeconds = 0;
          _canResend = true;
        });
      }
    });
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isOtpStep = true;
    });

    _startOtpTimer();

    // Auto-focus first digit box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  void _handleBackToPhone() {
    _countdownTimer?.cancel();
    setState(() {
      _isOtpStep = false;
      _isVerified = false;
      for (var c in _otpControllers) {
        c.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_phoneFocusNode.canRequestFocus) {
        _phoneFocusNode.requestFocus();
      }
    });
  }

  void _handleVerifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the OTP.'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isVerified = true;
    });

    _verifiedAnimController.forward(from: 0.0);

    // Auto-navigate to Screen 3: Role Selector after smooth verification pop-up
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RoleSelectorScreen(),
        ),
      );
    });
  }

  void _showHelpModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'UrbanStay Support',
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help logging in?',
                style: AppTypography.bodySemiBold.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'WhatsApp: +91 9876543210\nEmail: support@urbanstay.living',
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: AppTypography.bodySemiBold.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneNumber(String raw) {
    if (raw.length == 10) {
      return '+91 ${raw.substring(0, 5)} ${raw.substring(5)}';
    }
    return '+91 $raw';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _skylineAnimController.dispose();
    _verifiedAnimController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Underlying Main Screen (Stays visible underneath)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOtpStep ? 'Enter 6-Digit' : 'Verify your',
                            style: AppTypography.heading1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.1,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            _isOtpStep ? 'Verification OTP' : 'Phone number',
                            style: AppTypography.heading1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              height: 1.1,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),

                      // Right Help Link
                      TextButton(
                        onPressed: _showHelpModal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'help',
                          style: AppTypography.bodySemiBold.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main Content: Step 1 (Phone) OR Step 2 (OTP)
                  if (!_isOtpStep) _buildPhoneStep() else _buildOtpStep(),

                  const Spacer(),

                  // Sticky Bottom Bengaluru Skyline Marquee + Signature
                  _buildSkylineFooter(),
                ],
              ),
            ),
          ),

          // 2. Frosted Glass Blur Overlay + Centered Verification Card
          if (_isVerified) _buildVerifiedModal(),
        ],
      ),
    );
  }

  /// Step 3: Frosted Glass Background Blur + Centered Spring Success Card
  Widget _buildVerifiedModal() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _verifiedFadeAnim,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withValues(alpha: 0.32),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: ScaleTransition(
                  scale: _verifiedScaleAnim,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 36,
                          spreadRadius: 4,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Spring Green Circle with Checkmark Icon
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.38),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'OTP Verified!',
                          style: AppTypography.heading2.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Phone number verified successfully.\nRedirecting...',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyRegular.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Subtle active green capsule indicator
                        Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1: Mobile Number Input View (.main-flow-container)
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Label
        Text(
          'Mobile Number',
          style: AppTypography.captionSmall.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),

        const SizedBox(height: 6),

        // Phone Input Row
        Row(
          children: [
            // Country Badge 🇮🇳 +91
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '+91',
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 10-Digit Mobile Input
            Expanded(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter 10-digit number',
                      hintStyle: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Single-Line Terms Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                letterSpacing: 0,
              ),
              children: const [
                TextSpan(text: 'By continuing, you agree to our '),
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Primary Action Button (Continue)
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.green.withValues(alpha: 0.42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: AppTypography.bodySemiBold.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: 6-Digit OTP Verification View (#otpSection)
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info text + Bold Phone Row with Edit Button
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We sent a 6-digit verification code to',
              style: AppTypography.bodyRegular.copyWith(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  _formatPhoneNumber(_phoneController.text.trim()),
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleBackToPhone,
                  child: Text(
                    'Edit',
                    style: AppTypography.bodySemiBold.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 6 Auto-Advancing Digit Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _otpFocusNodes[index].hasFocus
                        ? AppColors.green
                        : const Color(0xFFE5E7EB),
                    width: 1.8,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: AppTypography.heading2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      final otp = _otpControllers.map((c) => c.text).join();
                      if (otp.length == 6) {
                        _handleVerifyOtp();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // Timer & Resend Link Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_canResend)
              Text(
                'Resend in ${_timerSeconds}s',
                style: AppTypography.bodyRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              )
            else
              GestureDetector(
                onTap: _startOtpTimer,
                child: Text(
                  'Resend Code',
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Verify & Continue Button
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.green.withValues(alpha: 0.42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Verify & Continue',
                  style: AppTypography.bodySemiBold.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sticky Bottom Section: India Heritage Skyline Marquee + Bengaluru Signature
  Widget _buildSkylineFooter() {
    return Column(
      children: [
        // Seamless Continuous Horizontal Skyline Marquee (24s, zero snap-back)
        // Image: 1584x396px → rendered at height=150 → width = 1584*(150/396) ≈ 600px
        // One segment = 600 + 20px gap = 620px. Translate exactly 620px per cycle.
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.92, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: AnimatedBuilder(
                  animation: _skylineAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(-_skylineAnimController.value * 620, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Image.asset(
                          'assets/images/skyline_bengaluru.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Clean Footer Signature: built with love in, Bengaluru, Karnataka
        Column(
          children: [
            Text(
              'built with love in,',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bengaluru, Karnataka',
              style: AppTypography.bodySemiBold.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
