import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'storage_service.dart';

class BiometricService {
  final ApiService _apiService;
  final StorageService _storageService;

  BiometricService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  Future<BiometricResult> verifyIdentity({
    required File idImage,
    required File selfieImage,
  }) async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const BiometricResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/biometric/verify',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'id_image',
          idImage.path,
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'selfie_image',
          selfieImage.path,
        ),
      );

      print('BIOMETRIC: Sending request to: $uri');
      print('BIOMETRIC: ID image: ${idImage.path}');
      print('BIOMETRIC: Selfie image: ${selfieImage.path}');
      print('BIOMETRIC: Sending multipart request...');

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      print(
        'BIOMETRIC: Response status: ${response.statusCode}',
      );

      print(
        'BIOMETRIC: Response body: ${response.body}',
      );

      dynamic data;

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = response.body;
        }
      }

      if (response.statusCode == 401) {
        await _storageService.deleteToken();

        return const BiometricResult(
          success: false,
          message: 'Your session has expired. Please log in again.',
        );
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          final verified = data['verified'] == true;

          if (verified) {
            return BiometricResult(
              success: true,
              message: data['message']?.toString() ??
                  'Identity verification completed successfully',
              data: data,
            );
          }

          final reason = data['reason']?.toString();
          final message = data['message']?.toString();

          return BiometricResult(
            success: false,
            message: message != null &&
                    message.isNotEmpty
                ? message
                : reason != null &&
                        reason.isNotEmpty
                    ? reason
                    : 'Biometric verification failed',
            data: data,
          );
        }

        return const BiometricResult(
          success: false,
          message: 'Invalid biometric verification response',
        );
      }

      String message = 'Identity verification failed';

      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['reason']?.toString() ??
            data['error']?.toString() ??
            message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }

      return BiometricResult(
        success: false,
        message: message,
        data: data,
      );
    } catch (e) {
      print('BIOMETRIC ERROR: $e');

      return const BiometricResult(
        success: false,
        message: 'Unable to connect to the verification service',
      );
    }
  }
}

class BiometricResult {
  final bool success;
  final String message;
  final dynamic data;

  const BiometricResult({
    required this.success,
    required this.message,
    this.data,
  });
}
