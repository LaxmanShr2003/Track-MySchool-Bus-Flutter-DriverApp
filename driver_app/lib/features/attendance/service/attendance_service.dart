import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:driver_app/core/error_handler.dart';

import 'package:driver_app/features/attendance/models/attendance_models.dart';
import 'package:driver_app/core/websocket_manager.dart';

class AttendanceService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  // WebSocket handled centrally via WebSocketManager
  bool _isInitializingWebSocket = false;

  AttendanceService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Initialize WebSocket connection
  Future<bool> initializeWebSocket() async {
    try {
      // Prevent multiple simultaneous initializations
      if (_isInitializingWebSocket) {
        print('⏳ WebSocket initialization already in progress, waiting...');
        // Wait a bit and check if connected
        await Future.delayed(const Duration(milliseconds: 500));
        if (WebSocketManager.instance.isConnected) {
          return true;
        }
      }

      _isInitializingWebSocket = true;

      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final ok = await WebSocketManager.instance.connect(token: token);
      if (ok) {
        print('✅ WebSocket connected for attendance');
      } else {
        print('❌ WebSocket connection failed for attendance');
      }

      _isInitializingWebSocket = false;
      return ok;
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
      _isInitializingWebSocket = false;
      return false;
    }
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    WebSocketManager.instance.disconnect();
  }

  /// Send attendance data via WebSocket
  Future<bool> sendAttendanceViaWebSocket(AttendanceData attendanceData) async {
    try {
      if (!WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket not connected, attempting to connect...');
        final connected = await initializeWebSocket();
        if (!connected) {
          print('❌ Failed to connect WebSocket, cannot send attendance');
          return false;
        }
      }

      final message = {'type': 'ATTENDANCE', 'data': attendanceData.toJson()};
      print('📤 Sending WebSocket message: ${jsonEncode(message)}');
      WebSocketManager.instance.emit('message', message);
      print(
        '📤 Attendance sent via WebSocket: ${attendanceData.action} for ${attendanceData.studentId}',
      );
      return true;
    } catch (e) {
      print('❌ Error sending attendance via WebSocket: $e');
      return false;
    }
  }

  /// Create a new trip
  Future<TripResponse> createTrip(TripData tripData) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/trip';
      print('📡 Creating trip: $url');

      final response = await _dio.post(
        url,
        data: tripData.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Create Trip Response Status: ${response.statusCode}');
      print('📋 Create Trip Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseMap =
            response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : <String, dynamic>{};
        final tripJson = responseMap['data'] as Map<String, dynamic>?;
        final trip =
            tripJson != null
                ? TripData.fromJson(_normalizeTripJson(tripJson))
                : null;

        return TripResponse(
          success: responseMap['success'] == true,
          data: trip,
          message: responseMap['message'] as String?,
          statusCode: response.statusCode ?? 0,
        );
      } else {
        final errorMessage = _getErrorMessageFromResponse(response.data);
        throw ErrorHandler.createApiException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('🚨 DioException caught: ${e.type} - ${e.message}');
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

  /// Complete a trip
  Future<TripResponse> completeTrip(String tripId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/trips/$tripId/complete';
      print('📡 Completing trip: $url');

      final response = await _dio.put(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Complete Trip Response Status: ${response.statusCode}');
      print('📋 Complete Trip Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseMap =
            response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : <String, dynamic>{};
        final tripJson = responseMap['data'] as Map<String, dynamic>?;
        final trip =
            tripJson != null
                ? TripData.fromJson(_normalizeTripJson(tripJson))
                : null;

        return TripResponse(
          success: responseMap['success'] == true,
          data: trip,
          message: responseMap['message'] as String?,
          statusCode: response.statusCode ?? 0,
        );
      } else {
        final errorMessage = _getErrorMessageFromResponse(response.data);
        throw ErrorHandler.createApiException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('🚨 DioException caught: ${e.type} - ${e.message}');
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

  /// Get student details by student ID
  Future<StudentData?> getStudentById(String studentId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/student/$studentId';
      print('📡 Fetching student details: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Student Response Status: ${response.statusCode}');
      print('📋 Student Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final studentData = responseData['data'];

          print('📋 Raw student data for $studentId: $studentData');

          // Extract student information from the response with better fallbacks
          String name = '';

          // Try different possible name fields
          if (studentData['name'] != null &&
              studentData['name'].toString().isNotEmpty) {
            name = studentData['name'].toString();
            print('✅ Found name in "name" field: $name');
          } else if (studentData['fullName'] != null &&
              studentData['fullName'].toString().isNotEmpty) {
            name = studentData['fullName'].toString();
            print('✅ Found name in "fullName" field: $name');
          } else if (studentData['firstName'] != null ||
              studentData['lastName'] != null) {
            final firstName = studentData['firstName']?.toString() ?? '';
            final lastName = studentData['lastName']?.toString() ?? '';
            name = '$firstName $lastName'.trim();
            print('✅ Found name in firstName/lastName fields: $name');
          } else if (studentData['studentName'] != null &&
              studentData['studentName'].toString().isNotEmpty) {
            name = studentData['studentName'].toString();
            print('✅ Found name in "studentName" field: $name');
          } else {
            // If no name found, use a more descriptive fallback
            name = 'Student $studentId';
            print('⚠️ No name found, using fallback: $name');
          }

          final student = StudentData(
            id: studentId,
            name: name,
            photoUrl: studentData['photoUrl']?.toString(),
            grade: studentData['grade']?.toString(),
            section: studentData['section']?.toString(),
            attendanceStatus: 'PENDING',
          );

          print('✅ Created student: ${student.name} (ID: ${student.id})');
          return student;
        } else {
          print('❌ Invalid response format for student $studentId');
        }
      } else {
        print('❌ Student API returned status: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('❌ Error fetching student $studentId: $e');
      return null;
    }
  }

  /// Get students assigned to a bus route
  Future<StudentsResponse> getStudentsByBusRoute(String busRouteId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/bus-route/$busRouteId';
      print('📡 Fetching bus route: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Bus Route Response Status: ${response.statusCode}');
      print('📋 Bus Route Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the bus route response to extract student IDs
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final busRouteData = responseData['data'];
          final routeAssignments =
              busRouteData['routeAssignment'] as List<dynamic>?;

          if (routeAssignments != null && routeAssignments.isNotEmpty) {
            // Extract student IDs from the first route assignment
            final firstAssignment = routeAssignments.first;
            final studentIds =
                firstAssignment['students'] as List<dynamic>? ?? [];

            print('📋 Found ${studentIds.length} students in route assignment');

            // Fetch real student data for each student ID
            final students = <StudentData>[];
            for (final studentId in studentIds) {
              final student = await getStudentById(studentId.toString());
              if (student != null) {
                students.add(student);
              } else {
                // Fallback to basic student data if API call fails
                students.add(
                  StudentData(
                    id: studentId.toString(),
                    name: studentId.toString(),
                    photoUrl: null,
                    grade: null,
                    section: null,
                    attendanceStatus: 'PENDING',
                  ),
                );
              }
            }

            return StudentsResponse(
              success: true,
              message: 'Successfully fetched students',
              data: students,
              statusCode: 200,
            );
          } else {
            // No route assignments found
            return StudentsResponse(
              success: true,
              message: 'No students assigned to this route',
              data: [],
              statusCode: 200,
            );
          }
        } else {
          throw ErrorHandler.createApiException('Invalid response format');
        }
      } else {
        final errorMessage = _getErrorMessageFromResponse(response.data);
        throw ErrorHandler.createApiException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('🚨 DioException caught: ${e.type} - ${e.message}');
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

  /// Get current user's bus route ID
  Future<String?> getCurrentUserBusRouteId() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        print('❌ User ID not found');
        return null;
      }

      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/driver/$userId';
      print('📡 Fetching driver info: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final driverData = response.data;
        final routeAssignments =
            driverData['message']['routeAssignment'] as List<dynamic>?;
        final activeAssignment =
            routeAssignments
                        ?.where(
                          (assignment) =>
                              assignment['assignmentStatus'] == 'ACTIVE',
                        )
                        .toList()
                        .isNotEmpty ==
                    true
                ? routeAssignments!
                    .where(
                      (assignment) =>
                          assignment['assignmentStatus'] == 'ACTIVE',
                    )
                    .first
                : null;

        if (activeAssignment != null) {
          final busRouteId = activeAssignment['busRouteId'].toString();
          print('✅ Bus route ID found: $busRouteId');
          return busRouteId;
        }
      }

      print('⚠️ No active bus route assignment found');
      return null;
    } catch (e) {
      print('❌ Error getting bus route ID: $e');
      return null;
    }
  }

  /// Check if there's an active trip for the current bus
  Future<TripData?> getActiveTrip() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      // Get bus ID for current driver
      final busId = await getBusIdForCurrentDriver();
      if (busId == null) {
        print('❌ Bus ID not found for driver');
        return null;
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/trip/bus/$busId';
      print('📡 Checking active trip for bus: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true && response.data['data'] != null) {
          final dynamic data = response.data['data'];

          Map<String, dynamic>? tripJson;
          if (data is List) {
            // Find first ACTIVE trip in the list; fallback to first item
            for (final item in data) {
              if (item is Map && item['status'] == 'ACTIVE') {
                tripJson = Map<String, dynamic>.from(item);
                break;
              }
            }
            if (tripJson == null && data.isNotEmpty && data.first is Map) {
              tripJson = Map<String, dynamic>.from(data.first);
            }
          } else if (data is Map) {
            tripJson = Map<String, dynamic>.from(data);
          }

          if (tripJson != null && tripJson['status'] == 'ACTIVE') {
            return TripData.fromJson(_normalizeTripJson(tripJson));
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error checking active trip: $e');
      return null;
    }
  }

  /// Normalize Trip JSON coming from API to match our model types
  Map<String, dynamic> _normalizeTripJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Handle tripId field - check for tripSessionId first, then other variations
    if (normalized.containsKey('tripSessionId')) {
      // API uses tripSessionId, map it to tripId in our model
      normalized['tripId'] = normalized['tripSessionId']?.toString();
      print(
        '✅ Found tripSessionId in API response: ${normalized['tripSessionId']}',
      );
    } else if (normalized.containsKey('tripId')) {
      normalized['tripId'] = normalized['tripId']?.toString();
      print('✅ Found tripId in API response: ${normalized['tripId']}');
    } else if (normalized.containsKey('id')) {
      // Some APIs might use 'id' instead of 'tripId'
      normalized['tripId'] = normalized['id']?.toString();
      print('✅ Found id in API response: ${normalized['id']}');
    } else {
      print(
        '⚠️ No trip ID found in API response. Available fields: ${normalized.keys.toList()}',
      );
    }

    if (normalized.containsKey('routeId')) {
      normalized['routeId'] = normalized['routeId']?.toString();
    }
    if (normalized.containsKey('busId')) {
      normalized['busId'] = normalized['busId']?.toString();
    }
    if (normalized.containsKey('startTime')) {
      normalized['startTime'] = normalized['startTime']?.toString();
    }
    if (normalized.containsKey('endTime')) {
      final end = normalized['endTime'];
      normalized['endTime'] = end == null ? null : end.toString();
    }
    if (normalized.containsKey('direction')) {
      normalized['direction'] = normalized['direction']?.toString();
    }
    if (normalized.containsKey('status')) {
      normalized['status'] = normalized['status']?.toString();
    }

    print('🔄 Normalized trip JSON: $normalized');
    return normalized;
  }

  /// Get bus ID for current driver
  Future<String?> getBusIdForCurrentDriver() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        print('❌ User ID not found');
        return null;
      }

      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/driver/$userId';
      print('📡 Fetching driver info for bus ID: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final driverData = response.data;
        final routeAssignments =
            driverData['message']['routeAssignment'] as List<dynamic>?;
        final activeAssignment =
            routeAssignments
                        ?.where(
                          (assignment) =>
                              assignment['assignmentStatus'] == 'ACTIVE',
                        )
                        .toList()
                        .isNotEmpty ==
                    true
                ? routeAssignments!
                    .where(
                      (assignment) =>
                          assignment['assignmentStatus'] == 'ACTIVE',
                    )
                    .first
                : null;

        if (activeAssignment != null) {
          final busId = activeAssignment['busId'].toString();
          print('✅ Bus ID found: $busId');
          return busId;
        }
      }

      print('⚠️ No active bus assignment found');
      return null;
    } catch (e) {
      print('❌ Error getting bus ID: $e');
      return null;
    }
  }

  /// Extracts error message from response
  String _getErrorMessageFromResponse(dynamic responseData) {
    if (responseData == null) return 'Request failed';

    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['error'] ??
          responseData['msg'] ??
          'Request failed';
    }

    if (responseData is String) {
      return responseData;
    }

    return 'Request failed';
  }

  /// Dispose resources
  void dispose() {
    disconnectWebSocket();
  }
}
