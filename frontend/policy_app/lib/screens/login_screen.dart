import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();

  bool _isLoading = false;

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  // ---- Visual-only tokens (redesign) ----
  // Same background image as the register screen.
  static const _backgroundAsset = 'assets/images/register_bg.png';
  static const _oxblood = Color(0xFF5E0E14);
  static const _glassBlueLight = Color(0xFF7DB8FF);
  static const _glassBlueDeep = Color(0xFF1D4FD8);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim().replaceAll(RegExp(r'[\s-]'), '');

    final phoneRegex = RegExp(
      r'^(\+27|0)[6-8][0-9]{8}$',
    );

    if (!phoneRegex.hasMatch(phone)) {
      return 'Enter a valid South African phone number';
    }

    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = AuthService();

    final result = await authService.requestLoginOtp(
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final data = result.data;

    if (data is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected response from server'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final userId = int.tryParse(
      data['userId']?.toString() ?? '',
    );

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login response did not contain a valid user ID',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/otp',
      arguments: {
        'userId': userId,
        'phoneNumber': _phoneController.text.trim(),
        'type': 'login',
      },
    );
  }

  InputDecoration _fieldDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _gradientStart,
        fontWeight: FontWeight.w600,
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: Colors.grey.shade600,
      ),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: border(Colors.grey.shade300),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(_gradientStart, 1.6),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.6),
    );
  }

  // ------------------------------------------------------------
  // BACKGROUND
  // ------------------------------------------------------------

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _oxblood),
        Image.asset(
          _backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.bottomRight,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.10),
                Colors.black.withOpacity(0.30),
                Colors.black.withOpacity(0.55),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _oxblood,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            SafeArea(
              bottom: false,
              child: isWide
                  ? _buildWideLayout()
                  : _buildNarrowLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: _buildBrandingPanel(),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header fills the top half, so the white panel
                // starts halfway down the screen.
                SizedBox(
                  height: (size.height * 0.5 - topInset)
                      .clamp(300.0, 900.0)
                      .toDouble(),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(28, 16, 28, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBadge(),
                          const SizedBox(height: 26),
                          Text(
                            'Protect Your Identity\nfrom Insurance Fraud',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildNarrowPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowPanel() {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(44),
      topRight: Radius.circular(44),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            32,
            24,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.40),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'PolicyCheck SA',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 56,
        vertical: 40,
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadge(),
            const SizedBox(height: 28),
            Text(
              'Protect Your Identity\n'
              'from Insurance Fraud',
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verify insurance policies linked to your '
              'South African ID number and detect '
              'fraudulent activity in real-time.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.82),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            const Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _FeatureCheck(
                  label: 'Real-time fraud detection',
                ),
                _FeatureCheck(
                  label: 'Instant verification',
                ),
                _FeatureCheck(
                  label: 'Secure & private',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Wide screens: white card
  Widget _buildLoginCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 440,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: _buildLoginForm(),
      ),
    );
  }

  // Shared form content (used by both layouts)
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to access your dashboard',
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 28),

          // PHONE NUMBER
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            cursorColor: _gradientStart,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: _fieldDecoration(
              'Phone Number',
              '082 123 4567',
              Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: 24),

          // SIGN IN BUTTON — liquid glass (blue)
          _LiquidGlassButton(
            isLoading: _isLoading,
            onTap: _isLoading ? null : _handleLogin,
            colorStart: _glassBlueLight,
            colorEnd: _glassBlueDeep,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // CREATE ACCOUNT
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/register',
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: _gradientStart,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LOGIN INFORMATION
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: _gradientStart,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A verification code will be sent '
                    'to your registered phone number.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCheck extends StatelessWidget {
  final String label;

  const _FeatureCheck({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// A "liquid glass" styled sign-in button (blue): glossy gradient, a
/// pulsing glow, a moving sheen and a press-down interaction.
/// Purely visual — behavior (onTap/isLoading) is unchanged.
class _LiquidGlassButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  final Color colorStart;
  final Color colorEnd;

  const _LiquidGlassButton({
    required this.isLoading,
    required this.onTap,
    required this.colorStart,
    required this.colorEnd,
  });

  @override
  State<_LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<_LiquidGlassButton>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _shimmerController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [_glowController, _shimmerController, _pressController],
      ),
      builder: (context, _) {
        final glow = _glowController.value; // 0..1, pulses
        final scale = 1.0 - (_pressController.value * 0.035);

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(
                      0.30 + (glow * 0.20),
                    ),
                    blurRadius: 18 + (glow * 12),
                    spreadRadius: 1 + (glow * 1.5),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.colorStart.withOpacity(0.95),
                        const Color(0xFF2F6BFF).withOpacity(0.95),
                        widget.colorEnd.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Moving glass sheen sweeping across the surface
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Align(
                            alignment: Alignment(
                              -1.6 + (_shimmerController.value * 3.2),
                              -1,
                            ),
                            child: Transform.rotate(
                              angle: 0.5,
                              child: Container(
                                width: 60,
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.30),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top edge highlight — crystal glass rim light
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.50),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        child: Center(
                          child: widget.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}