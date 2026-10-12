import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'storage_service.dart';

class PolicyService {
  final ApiService _apiService;
  final StorageService _storageService;

  PolicyService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  // ------------------------------------------------------------
  // MY POLICIES
  // ------------------------------------------------------------

  Future<PolicyResult> getMyPolicies() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const PolicyResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      debugPrint(
        'POLICY SERVICE: calling /api/policies/my-policies',
      );

      final response = await _apiService.get(
        '/api/policies/my-policies',
        token: token,
      );

      debugPrint(
        'POLICY SERVICE: policies request succeeded',
      );

      return PolicyResult(
        success: true,
        message: 'Policies loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      debugPrint(
        'POLICY SERVICE ERROR: '
        'status=${e.statusCode}, message=${e.message}',
      );

      if (e.statusCode == 401) {
        await _storageService.deleteToken();

        return const PolicyResult(
          success: false,
          message: 'Your session has expired. Please log in again.',
        );
      }

      return PolicyResult(
        success: false,
        message: e.message,
      );
    } catch (e) {
      debugPrint(
        'POLICY SERVICE UNEXPECTED ERROR: $e',
      );

      return const PolicyResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }
}

class PolicyResult {
  final bool success;
  final String message;
  final dynamic data;

  const PolicyResult({
    required this.success,
    required this.message,
    this.data,
  });
}