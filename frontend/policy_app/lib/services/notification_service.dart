import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  final ApiService _apiService;
  final StorageService _storageService;

  NotificationService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  // ------------------------------------------------------------
  // MY NOTIFICATIONS
  // ------------------------------------------------------------

  Future<NotificationResult> getMyNotifications() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const NotificationResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/notifications/my-notifications',
        token: token,
      );

      return NotificationResult(
        success: true,
        message: 'Notifications loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storageService.deleteToken();

        return const NotificationResult(
          success: false,
          message: 'Your session has expired. Please log in again.',
        );
      }

      return NotificationResult(
        success: false,
        message: e.message,
      );
    } catch (_) {
      return const NotificationResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }
}

class NotificationResult {
  final bool success;
  final String message;
  final dynamic data;

  const NotificationResult({
    required this.success,
    required this.message,
    this.data,
  });
}