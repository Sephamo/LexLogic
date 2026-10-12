import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String? email;
  final int? userId;
  final String? phoneNumber;
  final String? type;

  const OtpScreen({
    super.key,
    this.email,
    this.userId,
    this.phoneNumber,
    this.type,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int _otpLength = 6;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _hasError = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  bool get _isLogin => widget.type == 'login';

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _otpLength,
      (_) => TextEditingController(),
    );

    _focusNodes = List.generate(
      _otpLength,
      (_) => FocusNode(),
    );

    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    _timer?.cancel();

    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_secondsRemaining == 0) {
          timer.cancel();
        } else {
          if (mounted) {
            setState(() => _secondsRemaining--);
          }
        }
      },
    );
  }

  void _onDigitChanged(int index, String value) {
    setState(() => _hasError = false);

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (index == _otpLength - 1 && value.isNotEmpty) {
      _tryVerify();
    }
  }

  String get _enteredCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _tryVerify() async {
    if (_enteredCode.length < _otpLength) {
      setState(() => _hasError = true);
      return;
    }

    if (widget.userId == null) {
      setState(() => _hasError = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing user ID. Please restart the login process.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();

    final AuthResult result;

    if (_isLogin) {
      result = await authService.verifyLoginOtp(
        userId: widget.userId!,
        otpCode: _enteredCode,
      );
    } else {
      result = await authService.verifyRegistrationOtp(
        userId: widget.userId!,
        otpCode: _enteredCode,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      setState(() => _hasError = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    if (_isLogin) {
      // Login OTP is verified.
      // The backend now expects the password step.
      Navigator.pushNamed(
        context,
        '/password',
        arguments: {
          'userId': widget.userId,
          'phoneNumber': widget.phoneNumber,
        },
      );
    } else {
      // Registration OTP is verified.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  Future<void> _resendCode() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing user ID. Please restart the process.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();

    final AuthResult result;

    if (_isLogin) {
      result = await authService.resendLoginOtp(
        userId: widget.userId!,
      );
    } else {
      result = await authService.resendRegistrationOtp(
        userId: widget.userId!,
      );
    }

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

    for (final controller in _controllers) {
      controller.clear();
    }

    setState(() => _hasError = false);

    _focusNodes[0].requestFocus();
    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _hasError
                  ? Colors.redAccent
                  : const Color(0xFF89CFF0)
                      .withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF4A90D9),
              width: 1.8,
            ),
          ),
        ),
        onChanged: (value) {
          _onDigitChanged(index, value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBEE3F8),
              Color(0xFFF5FAFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 450 : double.infinity,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(
                          bottom: 16,
                        ),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 36,
                          color: Color(0xFF4A90D9),
                        ),
                      ),
                      const Text(
                        'Verify Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.phoneNumber != null
                            ? 'Enter the 6-digit code sent to '
                                '${widget.phoneNumber}'
                            : widget.email != null
                                ? 'Enter the code sent to '
                                    '${widget.email}'
                                : 'Enter the 6-digit '
                                    'verification code',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          _otpLength,
                          (index) => _buildDigitBox(index),
                        ),
                      ),
                      if (_hasError) ...[
                        const SizedBox(height: 12),
                        Text(
                          _enteredCode.length < _otpLength
                              ? 'Please enter a valid 6-digit code'
                              : 'Incorrect code. Please try again.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : _tryVerify,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: _secondsRemaining > 0
                            ? Text(
                                'Resend code in '
                                '$_secondsRemaining s',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              )
                            : TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _resendCode,
                                child: const Text(
                                  'Resend Code',
                                ),
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
    );
  }
}