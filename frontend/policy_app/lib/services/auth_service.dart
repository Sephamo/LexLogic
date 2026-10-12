import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({ApiService? apiService, StorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? StorageService();

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

Future<AuthResult> register({
  required String firstName,
  required String lastName,
  required String idNumber,
  required String phoneNumber,
  required String password,
}) async {
  try {
    final response = await _apiService.post(
      '/api/users/register',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    int? userId;

    if (response is Map<String, dynamic>) {
      final rawUserId = response['userId'];

      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId != null) {
        userId = int.tryParse(rawUserId.toString());
      }
    }

    if (userId == null) {
      return const AuthResult(
        success: false,
        message: 'Account was created but no user ID was returned.',
      );
    }

    return AuthResult(
      success: true,
      message: response is Map<String, dynamic> &&
              response['message'] != null
          ? response['message'].toString()
          : 'Account created successfully. Please verify your phone number.',
      data: response,
      userId: userId,
    );
  } on ApiException catch (e) {
    return _handleApiException(e);
  } catch (_) {
    return const AuthResult(
      success: false,
      message: 'Unable to connect to the server',
    );
  }
}

  // ------------------------------------------------------------
  // REGISTRATION OTP
  // ------------------------------------------------------------

  Future<AuthResult> verifyRegistrationOtp({
    required int userId,
    required String otpCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/otp/verify?userId=$userId&otpCode=$otpCode',
      );

      return AuthResult(
        success: true,
        message: 'Phone number verified successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  Future<AuthResult> resendRegistrationOtp({required int userId}) async {
    try {
      final response = await _apiService.post('/otp/resend?userId=$userId');

      return AuthResult(
        success: true,
        message: 'OTP resent successfully',
        data: response,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // LOGIN OTP REQUEST
  // ------------------------------------------------------------

  Future<AuthResult> requestLoginOtp({required String phoneNumber}) async {
    try {
      final response = await _apiService.post(
        '/api/users/login/request?phoneNumber=$phoneNumber',
      );

      int? userId;

      if (response is Map<String, dynamic>) {
        final rawUserId = response['userId'];

        if (rawUserId is int) {
          userId = rawUserId;
        } else if (rawUserId != null) {
          userId = int.tryParse(rawUserId.toString());
        }
      }

      return AuthResult(
        success: true,
        message: 'Login OTP requested successfully',
        data: response,
        userId: userId,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // LOGIN OTP VERIFICATION
  // ------------------------------------------------------------

  Future<AuthResult> verifyLoginOtp({
    required int userId,
    required String otpCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/otp/login/verify?userId=$userId&otpCode=$otpCode',
      );

      return AuthResult(
        success: true,
        message: 'Login OTP verified successfully',
        data: response,
        userId: userId,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // LOGIN OTP RESEND
  // ------------------------------------------------------------

  Future<AuthResult> resendLoginOtp({required int userId}) async {
    try {
      final response = await _apiService.post(
        '/otp/login/resend?userId=$userId',
      );

      return AuthResult(
        success: true,
        message: 'Login OTP resent successfully',
        data: response,
        userId: userId,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // PASSWORD VERIFICATION + JWT
  // ------------------------------------------------------------

  Future<AuthResult> verifyPassword({
    required int userId,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/users/password?userId=$userId',
        body: {'password': password},
      );

      // The backend documentation does not yet guarantee
      // whether the JWT is returned as a raw string or
      // inside a JSON property such as "token" or "jwt".
      final token = _extractJwt(response);

      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'Login succeeded but no authentication token was returned.',
        );
      }

      // Store the JWT securely.
      await _storageService.saveToken(token);

      return AuthResult(
        success: true,
        message: 'Login successful',
        data: response,
        token: token,
        userId: userId,
      );
    } on ApiException catch (e) {
      return _handleApiException(e);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // JWT EXTRACTION
  // ------------------------------------------------------------

  String? _extractJwt(dynamic response) {
    if (response == null) {
      return null;
    }

    // Case 1:
    // Backend returns the JWT directly as a string.
    if (response is String) {
      final value = response.trim();

      if (value.isEmpty) {
        return null;
      }

      return value;
    }

    // Case 2:
    // Backend returns JSON containing the JWT.
    if (response is Map<String, dynamic>) {
      final possibleKeys = ['token', 'jwt', 'accessToken', 'access_token'];

      for (final key in possibleKeys) {
        final value = response[key];

        if (value != null) {
          final token = value.toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // PROFILE
  // ------------------------------------------------------------

  Future<AuthResult> getProfile() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        return const AuthResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await _apiService.get(
        '/api/users/profile',
        token: token,
      );

      return AuthResult(
        success: true,
        message: 'Profile loaded successfully',
        data: response,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storageService.deleteToken();

        return const AuthResult(
          success: false,
          message: 'Your session has expired. Please log in again.',
        );
      }

      return AuthResult(success: false, message: e.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Unable to connect to the server',
      );
    }
  }

  // ------------------------------------------------------------
  // SESSION HELPERS
  // ------------------------------------------------------------

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<bool> isLoggedIn() async {
    return await _storageService.hasToken();
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // ------------------------------------------------------------
  // COMMON ERROR HANDLING
  // ------------------------------------------------------------

  Future<AuthResult> _handleApiException(ApiException e) async {
    if (e.statusCode == 401) {
      await _storageService.deleteToken();

      return const AuthResult(
        success: false,
        message: 'Your session has expired. Please log in again.',
      );
    }

    return AuthResult(success: false, message: e.message);
  }
}

// ============================================================
// AUTH RESULT
// ============================================================

class AuthResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? token;
  final int? userId;

  const AuthResult({
    required this.success,
    required this.message,
    this.data,
    this.token,
    this.userId,
  });
}
