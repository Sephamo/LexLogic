import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      'https://manhandle-shortness-chaos.ngrok-free.dev';

  static String? _sessionCookie;

  Map<String, String> _buildHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    };
  }

  void _storeSessionCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];

    if (setCookie == null) {
      return;
    }

    final match = RegExp(r'JSESSIONID=([^;]+)').firstMatch(setCookie);

    if (match != null) {
      _sessionCookie = 'JSESSIONID=${match.group(1)}';
    }
  }

  Future<dynamic> get(String endpoint, {String? token}) async {

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(token: token),
    );

    _storeSessionCookie(response);

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(token: token),
      body: body == null ? null : jsonEncode(body),
    );

    _storeSessionCookie(response);

    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(token: token),
      body: body == null ? null : jsonEncode(body),
    );

    _storeSessionCookie(response);

    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    String? token,
  }) async {

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(token: token),
    );

    _storeSessionCookie(response);

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {

    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    throw ApiException(
      statusCode: statusCode,
      message: _extractErrorMessage(data),
    );
  }

  String _extractErrorMessage(dynamic data) {

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed';
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return 'Request failed';
  }
}

class ApiException implements Exception {

  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'ApiException ($statusCode): $message';
  }
}
