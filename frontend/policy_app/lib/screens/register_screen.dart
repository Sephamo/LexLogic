import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  bool _agreedToTerms = false;

  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  // ---- Visual-only tokens (redesign) ----
  // Path of the background image. Add it to pubspec.yaml under `assets:`.
  static const _backgroundAsset = 'assets/images/register_bg.png';
  static const _oxblood = Color(0xFF5E0E14);
  static const _newsprint = Color(0xFFF3ECDD);
  static const _errorTint = Color(0xFFFFB4B4);

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    return null;
  }

  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Surname is required';
    }

    return null;
  }

  String? _validateSaId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID number is required';
    }

    if (value.length != 13) {
      return 'Must be exactly 13 digits';
    }

    if (!RegExp(r'^\d{13}$').hasMatch(value)) {
      return 'Digits only';
    }

    final month = int.parse(value.substring(2, 4));
    final day = int.parse(value.substring(4, 6));

    if (month < 1 || month > 12) {
      return 'Invalid ID number';
    }

    if (day < 1 || day > 31) {
      return 'Invalid ID number';
    }

    int sum = 0;

    for (int i = 0; i < 13; i++) {
      int digit = int.parse(value[i]);

      if (i % 2 != 0) {
        digit *= 2;

        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
    }

    if (sum % 10 != 0) {
      return 'Invalid ID number';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(' ', '');

    final saPhoneRegex =
        RegExp(r'^(0\d{9}|\+27\d{9})$');

    if (!saPhoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid SA number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'At least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include an uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include a lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include a number';
    }

    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Include a special character';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ------------------------------------------------------------
  // PASSWORD STRENGTH
  // ------------------------------------------------------------

  void _updatePasswordStrength(String value) {
    int score = 0;

    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      score++;
    }

    setState(() {
      if (value.isEmpty) {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
      } else if (score <= 2) {
        _passwordStrength = 0.25;
        _passwordStrengthLabel = 'Weak';
      } else if (score == 3) {
        _passwordStrength = 0.5;
        _passwordStrengthLabel = 'Fair';
      } else if (score == 4) {
        _passwordStrength = 0.75;
        _passwordStrengthLabel = 'Strong';
      } else {
        _passwordStrength = 1.0;
        _passwordStrengthLabel = 'Very Strong';
      }
    });
  }

  // Colours brightened slightly so they read on the dark glass.
  Color get _strengthColor {
    if (_passwordStrength <= 0.25) {
      return Colors.redAccent;
    }

    if (_passwordStrength <= 0.5) {
      return Colors.orange;
    }

    if (_passwordStrength <= 0.75) {
      return Colors.blue;
    }

    return Colors.green;
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms of Service and Privacy Policy',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();

    final result = await authService.register(
      firstName: _nameController.text.trim(),
      lastName: _surnameController.text.trim(),
      idNumber: _idNumberController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    if (result.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration succeeded, but no user ID was returned.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    // Account has been created and the backend
    // has sent the registration OTP.
    Navigator.pushNamed(
      context,
      '/registration-otp',
      arguments: {
        'userId': result.userId,
        'phoneNumber': _phoneController.text.trim(),
      },
    );
  }

  // ------------------------------------------------------------
  // FIELD DECORATION (glass inputs)
  // ------------------------------------------------------------

  InputDecoration _fieldDecoration(
    String label,
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
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
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

  static const TextStyle _inputTextStyle = TextStyle(
    color: Colors.black87,
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // ------------------------------------------------------------
  // FIELD ROW
  // ------------------------------------------------------------

  Widget _buildFieldRow(
    bool isWide,
    Widget left,
    Widget right,
  ) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 14),
          Expanded(child: right),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        left,
        const SizedBox(height: 16),
        right,
      ],
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
        // Depth: darken toward the bottom so the glass panel reads well,
        // keep the top clear and rich.
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
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final isWide = screenWidth > 640;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _oxblood,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 620 : double.infinity,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              // Header fills the top half of the screen,
                              // so the white panel starts halfway down.
                              SizedBox(
                                height: (size.height * 0.5 -
                                        MediaQuery.of(context)
                                            .padding
                                            .top)
                                    .clamp(300.0, 900.0)
                                    .toDouble(),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: _buildHeader(),
                                ),
                              ),
                              _buildGlassPanel(isWide),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER (logo + titles, sits on the open background)
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BRAND
          ClipRRect(
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
          ),

          const SizedBox(height: 26),

          Text(
            'Create Your Account',
            textAlign: TextAlign.left,
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Join thousands protecting their identity from insurance fraud',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
              color: Colors.white.withOpacity(0.80),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // GLASS PANEL (curved top, straight bottom)
  // ------------------------------------------------------------

  Widget _buildGlassPanel(bool isWide) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(44),
      topRight: Radius.circular(44),
      bottomLeft: Radius.circular(0),
      bottomRight: Radius.circular(0),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              32,
              24,
              32 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              borderRadius: radius,
              color: Colors.white,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab-handle style highlight
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

                  // Name + surname
                  _buildFieldRow(
                    isWide,
                    TextFormField(
                      controller: _nameController,
                      validator: _validateName,
                      style: _inputTextStyle,
                      cursorColor: _gradientStart,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        'Name',
                        Icons.person_outline,
                      ),
                    ),
                    TextFormField(
                      controller: _surnameController,
                      validator: _validateSurname,
                      style: _inputTextStyle,
                      cursorColor: _gradientStart,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(
                        'Surname',
                        Icons.person_outline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ID + phone
                  _buildFieldRow(
                    isWide,
                    TextFormField(
                      controller: _idNumberController,
                      validator: _validateSaId,
                      style: _inputTextStyle,
                      cursorColor: _gradientStart,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                      decoration: _fieldDecoration(
                        'SA ID Number',
                        Icons.badge_outlined,
                      ),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      validator: _validatePhone,
                      style: _inputTextStyle,
                      cursorColor: _gradientStart,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(
                        'Phone Number',
                        Icons.phone_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password + confirm
                  _buildFieldRow(
                    isWide,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          onChanged: _updatePasswordStrength,
                          style: _inputTextStyle,
                          cursorColor: _gradientStart,
                          decoration: _fieldDecoration(
                            'Password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        if (_passwordStrengthLabel.isNotEmpty) ...[
                          const SizedBox(height: 10),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: _passwordStrength,
                              ),
                              duration:
                                  const Duration(milliseconds: 250),
                              builder: (context, v, _) {
                                return LinearProgressIndicator(
                                  value: v,
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    _strengthColor,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            _passwordStrengthLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _strengthColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      style: _inputTextStyle,
                      cursorColor: _gradientStart,
                      decoration: _fieldDecoration(
                        'Confirm Password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // TERMS
                  // ------------------------------------------------

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: _gradientStart,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: Colors.grey.shade500,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // CREATE ACCOUNT BUTTON (liquid glass)
                  // ------------------------------------------------

                  _GlassButton(
                    onTap: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // LOGIN
                  // ------------------------------------------------

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: _gradientStart,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ------------------------------------------------------------
// LIQUID GLASS BUTTON (visual only – forwards onTap unchanged)
// ------------------------------------------------------------

class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final enabled = widget.onTap != null;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB)
                  .withOpacity(_pressed ? 0.25 : 0.45),
              blurRadius: _pressed ? 12 : 24,
              offset: Offset(0, _pressed ? 3 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                splashColor: Colors.white.withOpacity(0.15),
                highlightColor: Colors.transparent,
                onTap: widget.onTap,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7DB8FF)
                            .withOpacity(enabled ? 0.95 : 0.5),
                        const Color(0xFF2F6BFF)
                            .withOpacity(enabled ? 0.95 : 0.5),
                        const Color(0xFF1D4FD8)
                            .withOpacity(enabled ? 0.95 : 0.5),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Specular highlight along the top edge
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 30,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        child: Center(child: widget.child),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}