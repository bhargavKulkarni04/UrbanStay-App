import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../owner_setup/presentation/screens/owner_setup_screen.dart';
import '../../../tenant_checkin/presentation/screens/tenant_checkin_screen.dart';
import '../../../tenant_dashboard/presentation/screens/tenant_dashboard_screen.dart';

/// Screen 3: Role Selector & Auth Screen (Tenant vs PG Owner).
/// 1-to-1 exact translation of `ProductionCode/auth_preview.html`.
/// Features:
/// 1. Top Organic S-Curve Wave Role Switcher ("Login as Tenant" vs "Login as Owner").
/// 2. Dynamic Hero Greeting & Section Headline per Role + Mode.
/// 3. Segmented Pill Switcher ("Sign In" vs "Create Account").
/// 4. Dynamic Form Fields (Full Name for registration, Phone/Email, Password/PIN with eye toggle).
/// 5. High-Contrast Emerald Green CTA + Official Google Sign-In button.
class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

enum AuthRole { tenant, owner }
enum AuthMode { signIn, register }

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with SingleTickerProviderStateMixin {
  AuthRole _role = AuthRole.tenant;
  AuthMode _mode = AuthMode.signIn;

  bool _obscurePassword = true;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pgCodeController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneEmailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _pgCodeFocusNode = FocusNode();

  // Wave transition animation
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOutCubic,
    );

    _nameFocusNode.addListener(() => setState(() {}));
    _phoneEmailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _pgCodeFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _nameController.dispose();
    _phoneEmailController.dispose();
    _passwordController.dispose();
    _pgCodeController.dispose();
    _nameFocusNode.dispose();
    _phoneEmailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _pgCodeFocusNode.dispose();
    super.dispose();
  }

  void _setRole(AuthRole role) {
    if (_role == role) return;
    setState(() {
      _role = role;
    });
    if (role == AuthRole.owner) {
      _waveController.forward();
    } else {
      _waveController.reverse();
    }
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
    });
  }

  void _handleSubmit() {
    final identifier = _phoneEmailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_mode == AuthMode.register && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full legal name.'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_role == AuthRole.tenant && _mode == AuthMode.register && _pgCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PG Property Code (e.g. AR-101).'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_role == AuthRole.owner) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OwnerSetupScreen(),
        ),
      );
    } else {
      if (_mode == AuthMode.signIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TenantDashboardScreen(),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TenantCheckinScreen(
              initialPgCode: _pgCodeController.text.trim().isNotEmpty
                  ? _pgCodeController.text.trim().toUpperCase()
                  : 'AR-101',
              initialName: _nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : null,
              initialPhoneOrEmail: identifier,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Organic S-Curve Wave Role Switcher (Top)
              _buildSCurveHeader(),

              const SizedBox(height: 20),

              // 2. Hero Greeting (Fixed Height to prevent layout jumping/lag)
              _buildHeroGreeting(),

              const SizedBox(height: 18),

              // 3. Segmented Pill Switcher (Sign In vs Create Account)
              _buildAuthModePill(),

              const SizedBox(height: 18),

              // 4. Input Form Fields
              _buildFormSection(),

              const SizedBox(height: 16),

              // 5. Primary Submit CTA Button
              _buildSubmitButton(),

              const SizedBox(height: 16),

              // 6. Divider "or continue with"
              _buildDivider(),

              const SizedBox(height: 16),

              // 7. Google Sign-In Button
              _buildGoogleButton(),

              const SizedBox(height: 20),

              // 8. Footer Mode Switch Link
              _buildFooterLink(),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Organic S-Curve Wave Role Switcher Header (Pixel-perfect S-Curve wave)
  Widget _buildSCurveHeader() {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // Smooth Animated S-Curve Wave
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SCurveWavePainter(
                      progress: _waveAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // Two Interactive Tabs
            Row(
              children: [
                // Left: Tenant Tab
                Expanded(
                  child: InkWell(
                    onTap: () => _setRole(AuthRole.tenant),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LOGIN AS',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: _role == AuthRole.tenant
                                ? AppColors.ink
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tenant',
                          style: AppTypography.heading2.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: _role == AuthRole.tenant
                                ? AppColors.green
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Owner Tab
                Expanded(
                  child: InkWell(
                    onTap: () => _setRole(AuthRole.owner),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LOGIN AS',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: _role == AuthRole.owner
                                ? AppColors.ink
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Owner',
                          style: AppTypography.heading2.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: _role == AuthRole.owner
                                ? AppColors.green
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Hero Greeting (Fixed size container for zero lag/jitter)
  Widget _buildHeroGreeting() {
    String title;
    String sub;

    if (_role == AuthRole.tenant) {
      title = _mode == AuthMode.signIn ? 'Welcome back' : 'Create Tenant Account';
      sub = 'Sign in to manage your stay and room services';
    } else {
      title = _mode == AuthMode.signIn ? 'Welcome back, Owner' : 'Register as PG Owner';
      sub = 'Manage rooms, collect rent & view property profit';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading1.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: AppTypography.bodyRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 3. Segmented Auth Mode Pill Switcher (Zero click bleed)
  Widget _buildAuthModePill() {
    final isSignIn = _mode == AuthMode.signIn;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Sign In Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _setMode(AuthMode.signIn),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isSignIn
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Center(
                    child: Text(
                      'Sign In',
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSignIn ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Create Account Tab
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _setMode(AuthMode.register),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: !isSignIn
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Center(
                    child: Text(
                      'Create Account',
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: !isSignIn ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Dynamic Form Input Fields
  Widget _buildFormSection() {
    String headline;
    String desc;

    if (_role == AuthRole.tenant) {
      headline = _mode == AuthMode.signIn ? 'Sign in to continue' : 'Register your stay';
      desc = 'Access your rent invoices, gate passes, and room services.';
    } else {
      headline = _mode == AuthMode.signIn ? 'Sign in to your property' : 'Start your 3-minute setup';
      desc = 'Access room matrix, 0% rent collection, and analytics.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: AppTypography.heading3.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.green,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 14),

        // Full Name Field (Registration only)
        if (_mode == AuthMode.register) ...[
          _buildInputWrapper(
            controller: _nameController,
            focusNode: _nameFocusNode,
            icon: Icons.person_outline_rounded,
            hint: 'Full Legal Name',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 12),
        ],

        // PG Code Field (Tenant Registration only)
        if (_role == AuthRole.tenant && _mode == AuthMode.register) ...[
          _buildInputWrapper(
            controller: _pgCodeController,
            focusNode: _pgCodeFocusNode,
            icon: Icons.domain_rounded,
            hint: 'PG Property Code (e.g. AR-101)',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
        ],

        // Mobile / Email Field
        _buildInputWrapper(
          controller: _phoneEmailController,
          focusNode: _phoneEmailFocusNode,
          icon: Icons.phone_outlined,
          hint: 'Mobile Number or Email',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        // Password / PIN Field with Eye Toggle
        _buildInputWrapper(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          icon: Icons.lock_outline_rounded,
          hint: 'Password or 6-digit PIN',
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Helper for Styled Input Box
  Widget _buildInputWrapper({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final hasFocus = focusNode.hasFocus;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: hasFocus ? Colors.white : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFocus ? AppColors.green : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: hasFocus ? AppColors.green : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              style: AppTypography.bodyRegular.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.bodyRegular.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  /// 5. Primary Submit CTA Button
  Widget _buildSubmitButton() {
    String label;
    if (_role == AuthRole.tenant) {
      label = _mode == AuthMode.signIn ? 'Sign In as Tenant' : 'Create Tenant Account';
    } else {
      label = _mode == AuthMode.signIn ? 'Sign In as Owner' : 'Create Owner Account';
    }

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.green.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySemiBold.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  /// 6. Divider Line
  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
      ],
    );
  }

  /// 7. Official Google Sign-In Button
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In integration ready.'),
              backgroundColor: AppColors.ink,
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Crisp Official Google G Logo
            const _CrispGoogleLogo(size: 20),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: AppTypography.bodySemiBold.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 8. Footer Link
  Widget _buildFooterLink() {
    final text = _mode == AuthMode.signIn
        ? 'No account yet? Create one'
        : 'Already have an account? Sign In';

    return GestureDetector(
      onTap: () {
        _setMode(_mode == AuthMode.signIn ? AuthMode.register : AuthMode.signIn);
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            text,
            style: AppTypography.bodySemiBold.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for S-Curve Wave Active Tab Highlight
/// Interpolates smoothly between Left (Tenant) and Right (Owner)
class _SCurveWavePainter extends CustomPainter {
  final double progress; // 0.0 = Tenant (Left), 1.0 = Owner (Right)

  _SCurveWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final linePath = Path();

    // Smooth organic wave parameters interpolated by progress
    // At progress 0 (Tenant): Left highlight from 0 to (0.52 * w) with S-curve tapering to (0.58 * w)
    // At progress 1 (Owner): Right highlight from (0.48 * w) with S-curve from (0.42 * w) to w
    final mid = w * 0.5;
    final curveSpread = w * 0.12;

    final startX = (1.0 - progress) * (mid + curveSpread * 0.5) + progress * (mid - curveSpread * 0.5);
    final endX = (1.0 - progress) * (mid - curveSpread * 0.5) + progress * (mid + curveSpread * 0.5);

    if (progress <= 0.5) {
      // Tenant Active (Left Card)
      path.moveTo(0, 0);
      path.lineTo(startX, 0);
      path.cubicTo(
        startX + 18, 0,
        endX - 18, h,
        endX, h,
      );
      path.lineTo(0, h);
      path.close();

      linePath.moveTo(startX, 0);
      linePath.cubicTo(
        startX + 18, 0,
        endX - 18, h,
        endX, h,
      );
    } else {
      // Owner Active (Right Card)
      path.moveTo(w, 0);
      path.lineTo(endX, 0);
      path.cubicTo(
        endX - 18, 0,
        startX + 18, h,
        startX, h,
      );
      path.lineTo(w, h);
      path.close();

      linePath.moveTo(endX, 0);
      linePath.cubicTo(
        endX - 18, 0,
        startX + 18, h,
        startX, h,
      );
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(linePath, borderPaint);
  }

  @override
  bool shouldRepaint(_SCurveWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Crisp, pixel-perfect official Google "G" logo
class _CrispGoogleLogo extends StatelessWidget {
  final double size;
  const _CrispGoogleLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrispGoogleLogoPainter(),
      ),
    );
  }
}

class _CrispGoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue Vector
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Vector
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow Vector
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.03, 14.72)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red Vector
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.70, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.90)
      ..cubicTo(6.71, 7.30, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

