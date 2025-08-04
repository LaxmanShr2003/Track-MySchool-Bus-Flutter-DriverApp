import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:driver_app/models/login_response.dart';
import 'package:driver_app/core/error_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final Dio _dio;
  AuthService({Dio? dio}) : _dio = dio ?? Dio();

  /// Attempts to log in with the provided username and password.
  /// Throws custom exceptions that can be handled by the centralized ErrorHandler.
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }
      // Debug: Print request details
      print('Making login request to: $baseUrl/login');
      print('Username: $username');
      print('Password: ${password.length} characters');

      // Make the POST request to the login API
      // Try different field name variations that your backend might expect
      final requestData = {
        'userName': username,
        'password': password,
        // Alternative field names your backend might expect:
        // 'username': username,
        // 'user_name': username,
        // 'email': username,
        // 'user': username,
      };

      final response = await _dio.post(
        '$baseUrl/login',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus:
              (status) => status! < 500, // Accept all status codes < 500
        ),
      );

      // Debug: Print response details
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      // Check for successful response
      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        // Parse the response into a LoginResponse model
        return LoginResponse.fromJson(data);
      } else {
        // Throw a custom API exception with status code
        throw ErrorHandler.createApiException(
          'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors and convert to custom exceptions
      if (e.response != null) {
        // Handle HTTP error responses (like 403, 401, etc.)
        final statusCode = e.response?.statusCode;
        final errorMessage = _getErrorMessageFromResponse(e.response?.data);

        // Debug: Print detailed error information
        print('HTTP Error - Status: $statusCode');
        print('Error Response Data: ${e.response?.data}');
        print('Error Headers: ${e.response?.headers}');

        throw ErrorHandler.createApiException(
          errorMessage,
          statusCode: statusCode,
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw ErrorHandler.createNetworkException('Request timed out');
      } else if (e.type == DioExceptionType.connectionError) {
        throw ErrorHandler.createNetworkException('No internet connection');
      } else {
        throw ErrorHandler.createNetworkException(e.message ?? 'Network error');
      }
    } catch (e) {
      // Re-throw custom exceptions as-is, wrap others
      if (e is NetworkException ||
          e is ApiException ||
          e is ValidationException) {
        rethrow;
      }
      throw ErrorHandler.createApiException('Unexpected error: $e');
    }
  }

  /// Extracts error message from response data
  String _getErrorMessageFromResponse(dynamic responseData) {
    if (responseData == null) return 'Login failed';

    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['error'] ??
          responseData['msg'] ??
          'Login failed';
    }

    if (responseData is String) {
      return responseData;
    }

    return 'Login failed';
  }
}
