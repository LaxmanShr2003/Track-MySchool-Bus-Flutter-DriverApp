import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/models/profile_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:driver_app/core/error_handler.dart';

class ProfileService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ProfileService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Fetches the profile for the current user
  Future<ProfileUser> fetchProfile() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final userId = await _storage.read(key: 'userId');

      // Validate required data
      if (token == null) {
        throw ErrorHandler.createApiException(
          'Access token not found. Please login again.',
        );
      }

      if (userId == null) {
        throw ErrorHandler.createApiException(
          'User ID not found. Please login again.',
        );
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/driver/$userId';
      print('📡 Fetching profile from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
          responseType: ResponseType.json, // Ensure JSON response
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      print('📊 Profile API Response Status: ${response.statusCode}');
      print('📋 Profile API Response Headers: ${response.headers}');
      print('📄 Profile API Response Data Type: ${response.data.runtimeType}');
      print('📄 Profile API Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Success response with status: ${response.statusCode}');
        try {
          return _parseProfileResponse(response.data, userId);
        } catch (e, stackTrace) {
          print('❌ Error parsing successful response: $e');
          print('📚 Stack trace: $stackTrace');
          throw ErrorHandler.createApiException(
            'Failed to parse profile data: $e',
            statusCode: response.statusCode,
          );
        }
      } else {
        print('❌ Error response with status: ${response.statusCode}');
        final errorMessage = _getErrorMessageFromResponse(response.data);
        throw ErrorHandler.createApiException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('🚨 DioException caught: ${e.type} - ${e.message}');
      print('🚨 Response: ${e.response?.data}');

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage = _getErrorMessageFromResponse(e.response?.data);
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
        throw ErrorHandler.createNetworkException(
          'Network error: ${e.message}',
        );
      }
    } catch (e) {
      print('🚨 Unexpected error: $e');
      if (e is ApiException ||
          e is NetworkException ||
          e is ValidationException) {
        rethrow;
      }
      throw ErrorHandler.createApiException('Unexpected error: $e');
    }
  }

  /// Parses the profile response and handles different response structures
  ProfileUser _parseProfileResponse(dynamic responseData, String userId) {
    print('🔍 Parsing response data type: ${responseData.runtimeType}');
    print('🔍 Response data: $responseData');

    // Handle string response (shouldn't happen with ResponseType.json, but just in case)
    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (e) {
        print('❌ Failed to parse JSON string: $e');
        throw ErrorHandler.createApiException('Invalid JSON response format');
      }
    }

    if (responseData is! Map<String, dynamic>) {
      print('❌ Response data is not a Map: ${responseData.runtimeType}');
      throw ErrorHandler.createApiException('Invalid response format');
    }

    final data = responseData;
    print('📝 Response keys: ${data.keys.toList()}');

    // Strategy 1: Check if this is a direct driver object
    if (_isDriverObject(data)) {
      print('✅ Found direct driver object');
      return _parseDriverObject(data);
    }

    // Strategy 2: Check if response has a 'message' field with driver data
    if (data.containsKey('message')) {
      final message = data['message'];
      print('📨 Found message field of type: ${message.runtimeType}');

      if (message is List) {
        print('📋 Message is a list with ${message.length} items');
        return _findDriverInList(message, userId);
      } else if (message is Map<String, dynamic>) {
        print('📄 Message is a single object');
        return _parseDriverObject(message);
      }
    }

    // Strategy 3: Check if response has a 'data' field
    if (data.containsKey('data')) {
      final dataField = data['data'];
      print('📊 Found data field of type: ${dataField.runtimeType}');

      if (dataField is List) {
        return _findDriverInList(dataField, userId);
      } else if (dataField is Map<String, dynamic>) {
        return _parseDriverObject(dataField);
      }
    }

    // Strategy 4: Check if response has a 'user' field
    if (data.containsKey('user')) {
      final userField = data['user'];
      if (userField is Map<String, dynamic>) {
        print('👤 Found user field');
        return _parseDriverObject(userField);
      }
    }

    // Strategy 5: Check if response has a 'driver' field
    if (data.containsKey('driver')) {
      final driverField = data['driver'];
      if (driverField is Map<String, dynamic>) {
        print('🚛 Found driver field');
        return _parseDriverObject(driverField);
      }
    }

    print('❌ No recognizable data structure found');
    print('📋 Available keys: ${data.keys.toList()}');
    throw ErrorHandler.createApiException(
      'Unable to parse response: no driver data found',
    );
  }

  /// Checks if the given object looks like a driver object
  bool _isDriverObject(Map<String, dynamic> obj) {
    // Check for common driver fields
    final driverFields = ['firstName', 'lastName', 'email', 'role', 'userName'];
    final idFields = ['id', '_id'];

    // Must have at least one ID field and some driver-specific fields
    final hasId = idFields.any((field) => obj.containsKey(field));
    final hasDriverFields =
        driverFields.where((field) => obj.containsKey(field)).length >= 3;

    return hasId && hasDriverFields;
  }

  /// Finds a driver in a list by matching userId
  ProfileUser _findDriverInList(List drivers, String userId) {
    print(
      '🔍 Searching for driver with ID: $userId in list of ${drivers.length} drivers',
    );

    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      print('🔍 Checking driver $i: ${driver.runtimeType}');

      if (driver is! Map<String, dynamic>) {
        print('⚠️ Driver $i is not a Map, skipping');
        continue;
      }

      final driverMap = driver;
      final driverId =
          driverMap['id']?.toString() ?? driverMap['_id']?.toString() ?? '';
      final driverUserName = driverMap['userName']?.toString() ?? '';
      final driverEmail = driverMap['email']?.toString() ?? '';

      print(
        '🔍 Driver $i - ID: $driverId, UserName: $driverUserName, Email: $driverEmail',
      );

      // Try matching by different criteria
      if (driverId == userId ||
          driverUserName == userId ||
          driverEmail == userId) {
        print(
          '✅ Found matching driver: ${driverMap['firstName']} ${driverMap['lastName']}',
        );
        return _parseDriverObject(driverMap);
      }
    }

    throw ErrorHandler.createApiException(
      'Driver not found in response. Looking for: $userId',
    );
  }

  /// Parses a driver object with comprehensive error handling
  ProfileUser _parseDriverObject(Map<String, dynamic> driverData) {
    try {
      print('🔧 Parsing driver object with keys: ${driverData.keys.toList()}');

      // Log some key fields for debugging
      print(
        '👤 Driver Name: ${driverData['firstName']} ${driverData['lastName']}',
      );
      print('📧 Driver Email: ${driverData['email']}');
      print('🆔 Driver ID: ${driverData['id'] ?? driverData['_id']}');

      return ProfileUser.fromJson(driverData);
    } catch (e, stackTrace) {
      print('❌ Error parsing driver object: $e');
      print('📚 Stack trace: $stackTrace');
      print('📋 Driver data: ${driverData.toString()}');

      // Try to provide more specific error information
      final missingFields = <String>[];
      final requiredFields = [
        'firstName',
        'lastName',
        'email',
        'mobileNumber',
        'userName',
        'role',
        'address',
      ];

      for (final field in requiredFields) {
        if (!driverData.containsKey(field) || driverData[field] == null) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        throw ErrorHandler.createApiException(
          'Invalid driver data: missing fields: ${missingFields.join(', ')}',
        );
      }

      throw ErrorHandler.createApiException('Failed to parse driver data: $e');
    }
  }

  /// Enhanced error message extraction with better debugging
  String _getErrorMessageFromResponse(dynamic responseData) {
    print(
      '🚨 Extracting error from response type: ${responseData.runtimeType}',
    );

    if (responseData == null) {
      return 'Failed to fetch profile: No response data';
    }

    if (responseData is String) {
      print('🚨 String error response: $responseData');
      // Try to parse as JSON in case it's a JSON string
      try {
        final parsed = jsonDecode(responseData);
        if (parsed is Map<String, dynamic>) {
          return _extractErrorFromMap(parsed);
        }
      } catch (e) {
        // If not JSON, return the string as is
        return responseData.isEmpty ? 'Failed to fetch profile' : responseData;
      }
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      return _extractErrorFromMap(responseData);
    }

    return 'Failed to fetch profile: Unknown error format';
  }

  /// Extracts error message from a Map response
  String _extractErrorFromMap(Map<String, dynamic> data) {
    print('🚨 Error map keys: ${data.keys.toList()}');

    // Common error field names in order of preference
    final errorFields = [
      'message',
      'error',
      'msg',
      'errorMessage',
      'detail',
      'description',
    ];

    for (final field in errorFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        print('🚨 Found error field "$field": $value (${value.runtimeType})');

        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is Map<String, dynamic>) {
          // Recursive extraction for nested error objects
          final nestedError = _extractErrorFromMap(value);
          if (nestedError != 'Failed to fetch profile: Unknown error format') {
            return nestedError;
          }
        } else if (value != null) {
          return value.toString();
        }
      }
    }

    // If no standard error fields found, look for any field that might contain error info
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('error') || key.contains('message')) {
        final value = entry.value;
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return 'Failed to fetch profile: Server error';
  }
}
