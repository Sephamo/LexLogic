import 'api_service.dart';
import 'storage_service.dart';

class AuditService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuditService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  // ------------------------------------------------------------
  // MY AUDIT LOGS
  // ------------------------------------------------------------

  Future<AuditResult> getMyLogs() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const AuditResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/audit/my-logs',
        token: token,
      );

      return AuditResult(
        success: true,
        message: 'Audit logs loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storageService.deleteToken();

        return const AuditResult(
          success: false,
          message: 'Your session has expired. Please log in again.',
        );
      }

      return AuditResult(
        success: false,
        message: e.message,
      );
    } catch (_) {
      return const AuditResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }
}

class AuditResult {
  final bool success;
  final String message;
  final dynamic data;

  const AuditResult({
    required this.success,
    required this.message,
    this.data,
  });
}