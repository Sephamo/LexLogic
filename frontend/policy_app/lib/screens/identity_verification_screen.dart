import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/biometric_service.dart';

enum _Phase {
  form,
  processing,
  result,
}

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  final BiometricService _biometricService = BiometricService();

  _Phase _phase = _Phase.form;

  Uint8List? _idImageBytes;
  String? _idFileName;
  String? _idImagePath;

  Uint8List? _selfieImageBytes;
  String? _selfieImagePath;

  bool _verificationPassed = false;
  String? _verificationMessage;

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  Future<void> _pickIdDocument() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _idImageBytes = bytes;
        _idFileName = file.name;
        _idImagePath = file.path;
      });
    }
  }

  Future<void> _captureSelfie() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (file != null) {
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selfieImageBytes = bytes;
        _selfieImagePath = file.path;
      });
    }
  }

  bool get _canSubmit =>
      _idImageBytes != null &&
      _selfieImageBytes != null &&
      _idImagePath != null &&
      _selfieImagePath != null;

Future<void> _submitVerification() async {
  if (!_canSubmit) return;

  setState(() {
    _phase = _Phase.processing;
    _verificationPassed = false;
    _verificationMessage = null;
  });

  try {
    final result = await _biometricService.verifyIdentity(
      idImage: File(_idImagePath!),
      selfieImage: File(_selfieImagePath!),
    );

    if (!mounted) return;

    bool verified = false;

    if (result.data is Map<String, dynamic>) {
      verified = result.data['verified'] == true;
    }

    print('BIOMETRIC UI: result.success = ${result.success}');
    print('BIOMETRIC UI: result.message = ${result.message}');
    print('BIOMETRIC UI: result.data = ${result.data}');
    print('BIOMETRIC UI: verified = $verified');

    setState(() {
      _verificationPassed = result.success && verified;
      _verificationMessage = result.message;
      _phase = _Phase.result;
    });
  } catch (e) {
    print('BIOMETRIC UI ERROR: $e');

    if (!mounted) return;

    setState(() {
      _verificationPassed = false;
      _verificationMessage =
          'Unable to complete identity verification. Please try again.';
      _phase = _Phase.result;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _phase == _Phase.form
                    ? _buildForm()
                    : _phase == _Phase.processing
                        ? _buildProcessing()
                        : _buildResult(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gradientStart,
                  _gradientEnd,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Verify Your Identity',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload your SA ID document and a clear selfie to verify your identity',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _gradientStart.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: _gradientStart,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Important Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _BulletLine(
                'Ensure your ID document is clear and all details are readable',
              ),
              const _BulletLine(
                'Take a selfie with good lighting and your face clearly visible',
              ),
              const _BulletLine(
                'Supported formats: JPG, PNG (Max 5MB)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '1. Upload SA ID Document *',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        _buildUploadBox(
          uploaded: _idImageBytes != null,
          fileName: _idFileName,
          placeholderIcon: Icons.upload_file_outlined,
          placeholderText: 'Tap to upload ID document',
          onTap: _pickIdDocument,
          previewBytes: _idImageBytes,
        ),
        const SizedBox(height: 24),
        const Text(
          '2. Upload Selfie Photo *',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        _buildUploadBox(
          uploaded: _selfieImageBytes != null,
          fileName: _selfieImageBytes != null ? 'Selfie captured' : null,
          placeholderIcon: Icons.camera_alt_outlined,
          placeholderText: 'Tap to take a selfie',
          onTap: _captureSelfie,
          previewBytes: _selfieImageBytes,
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _canSubmit
                  ? [
                      _gradientStart,
                      _gradientEnd,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade300,
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _canSubmit ? _submitVerification : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Center(
                  child: Text(
                    'Verify My Identity',
                    style: TextStyle(
                      color: _canSubmit
                          ? Colors.white
                          : Colors.black38,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required bool uploaded,
    required String? fileName,
    required IconData placeholderIcon,
    required String placeholderText,
    required VoidCallback onTap,
    Uint8List? previewBytes,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: uploaded
              ? const Color(0xFFEAFBF0)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? Colors.green
                : Colors.grey.shade300,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: uploaded
            ? Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Uploaded',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileName ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: onTap,
                          child: const Text(
                            'Replace document',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    placeholderIcon,
                    size: 32,
                    color: _gradientStart,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    placeholderText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20),
        SizedBox(
          height: 56,
          width: 56,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: _gradientStart,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Verifying Your Identity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Running liveness detection and comparing your selfie to your ID document...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

   Widget _buildResult() {
    final passed = _verificationPassed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed
              ? Icons.verified_outlined
              : Icons.error_outline,
          size: 56,
          color: passed
              ? Colors.green
              : Colors.redAccent,
        ),
        const SizedBox(height: 20),
        Text(
          passed
              ? 'Verification Successful'
              : 'Verification Failed',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _verificationMessage ??
              (passed
                  ? 'Your identity has been confirmed. You can now view your linked policies.'
                  : 'We couldn\'t verify your identity. Please try again with clearer photos.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        if (passed)
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gradientStart,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Continue to Policies',
            ),
          )
        else
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gradientStart,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Try Again',
            ),
          ),
      ],
    );
  }

  // Reset the verification screen so the user can try again.
  void _retry() {
    setState(() {
      _phase = _Phase.form;
      _verificationPassed = false;
      _verificationMessage = null;
      _idImageBytes = null;
      _idFileName = null;
      _idImagePath = null;
      _selfieImageBytes = null;
      _selfieImagePath = null;
    });
  }
}

// IMPORTANT: the State class ends above this line.

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 4,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}