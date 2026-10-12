import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class RegistrationOtpScreen extends StatefulWidget {
  final int userId;
  final String phoneNumber;

  const RegistrationOtpScreen({
    super.key,
    required this.userId,
    required this.phoneNumber,
  });

  @override
  State<RegistrationOtpScreen> createState() =>
      _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState
    extends State<RegistrationOtpScreen> {
  static const int _otpLength = 6;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _hasError = false;

  int _secondsRemaining = 60;
  Timer? _timer;

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

    // Automatically focus the first box.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
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
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_secondsRemaining <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _secondsRemaining = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _secondsRemaining--;
            });
          }
        }
      },
    );
  }

  String get _enteredCode {
    return _controllers
        .map((controller) => controller.text)
        .join();
  }

  void _onDigitChanged(int index, String value) {
    if (mounted) {
      setState(() {
        _hasError = false;
      });
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (index == _otpLength - 1 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredCode.length != _otpLength) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();

    final result = await authService.verifyRegistrationOtp(
      userId: widget.userId,
      otpCode: _enteredCode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      setState(() {
        _hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    // Registration phone has now been verified.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Phone number verified successfully!',
        ),
      ),
    );

    // Send the user to login.
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();

    final result = await authService.resendRegistrationOtp(
      userId: widget.userId,
    );

    if (!mounted) return;

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

    for (final controller in _controllers) {
      controller.clear();
    }

    setState(() {
      _hasError = false;
    });

    _focusNodes[0].requestFocus();

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
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
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _hasError
                  ? Colors.redAccent
                  : const Color(0xFF89CFF0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF4A90D9),
              width: 2,
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
                      // Icon
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
                          Icons.phone_android_outlined,
                          size: 36,
                          color: Color(0xFF4A90D9),
                        ),
                      ),

                      const Text(
                        'Verify Your Phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'We sent a 6-digit verification code to\n'
                        '${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Enter the code below to activate your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // OTP boxes
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          _otpLength,
                          (index) => _buildOtpBox(index),
                        ),
                      ),

                      if (_hasError) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Incorrect verification code. Please try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Verify button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF4A90D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
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
                              : const Text(
                                  'Verify Phone Number',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend
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
                                    : _resendOtp,
                                child: const Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: Color(0xFF4A90D9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Back to Registration',
                          style: TextStyle(
                            color: Colors.black54,
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