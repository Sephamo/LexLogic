import 'api_service.dart';
import 'storage_service.dart';

class FraudService {
  final ApiService _apiService;
  final StorageService _storageService;

  FraudService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  // ------------------------------------------------------------
  // MY FRAUD FLAGS
  // ------------------------------------------------------------

  Future<FraudResult> getMyFlags() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const FraudResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/fraud/my-flags',
        token: token,
      );

      return FraudResult(
        success: true,
        message: 'Fraud flags loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const FraudResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // MY FRAUD STATUS
  // ------------------------------------------------------------

  Future<FraudResult> getMyStatus() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const FraudResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/fraud/my-status',
        token: token,
      );

      return FraudResult(
        success: true,
        message: 'Fraud status loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const FraudResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // SUBMIT FRAUD REPORT
  // ------------------------------------------------------------

  Future<FraudResult> submitFraudReport({
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const FraudResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.post(
        '/api/fraud-reports',
        body: reportData,
        token: token,
      );

      return FraudResult(
        success: true,
        message: 'Fraud report submitted successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const FraudResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // MY FRAUD REPORTS
  // ------------------------------------------------------------

  Future<FraudResult> getMyReports() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const FraudResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/fraud-reports/my-reports',
        token: token,
      );

      return FraudResult(
        success: true,
        message: 'Fraud reports loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const FraudResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // ERROR HANDLING
  // ------------------------------------------------------------

  Future<FraudResult> _handleApiException(ApiException e) async {
    if (e.statusCode == 401) {
      await _storageService.deleteToken();

      return const FraudResult(
        success: false,
        message: 'Your session has expired. Please log in again.',
      );
    }

    return FraudResult(
      success: false,
      message: e.message,
    );
  }
}

class FraudResult {
  final bool success;
  final String message;
  final dynamic data;

  const FraudResult({
    required this.success,
    required this.message,
    this.data,
  });
}