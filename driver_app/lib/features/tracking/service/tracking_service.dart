import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/models/tracking_response.dart';
import 'package:driver_app/models/driver_response.dart';
import 'package:driver_app/models/route_details_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:driver_app/core/error_handler.dart';

class TrackingService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  WebSocket? _webSocket;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _gpsUpdateTimer;
  bool _isTracking = false;
  RouteData? _currentRoute;

  // WebSocket configuration
  static const String _wsHost = '192.168.1.82';
  static const int _wsPort = 8080;
  static const String _wsPath = '/ws/tracking';

  TrackingService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Fetches driver by driver ID to get route assignment
  Future<DriverResponse> fetchDriverByDriverId(String driverId) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      if (token == null) {
        throw ErrorHandler.createApiException(
          'Access token not found. Please login again.',
        );
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/driver/$driverId';
      print('📡 Fetching driver from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Driver API Response Status: ${response.statusCode}');
      print('📋 Driver API Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final driverResponse = DriverResponse.fromJson(response.data);
        print(
          '✅ Driver fetched successfully: ${driverResponse.message.firstName} ${driverResponse.message.lastName}',
        );
        return driverResponse;
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

  /// Fetches route details by route ID
  Future<RouteDetailsResponse> fetchRouteDetailsByRouteId(int routeId) async {
    try {
      final token = await _storage.read(key: 'accessToken');

      if (token == null) {
        throw ErrorHandler.createApiException(
          'Access token not found. Please login again.',
        );
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/bus-route/$routeId';
      print('📡 Fetching route details from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Route Details API Response Status: ${response.statusCode}');
      print('📋 Route Details API Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final routeDetailsResponse = RouteDetailsResponse.fromJson(
          response.data,
        );
        print(
          '✅ Route details fetched successfully: ${routeDetailsResponse.data.routeName}',
        );
        return routeDetailsResponse;
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

  /// Gets current user ID from storage
  Future<String?> getCurrentUserId() async {
    return await _storage.read(key: 'userId');
  }

  /// Gets route ID for current driver
  Future<int?> getRouteIdForCurrentDriver() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        print('❌ User ID not found');
        return null;
      }

      final driverResponse = await fetchDriverByDriverId(userId);

      // Get the first active route assignment
      final activeAssignment =
          driverResponse.message.routeAssignment
              .where((assignment) => assignment.assignmentStatus == 'ACTIVE')
              .firstOrNull;

      if (activeAssignment != null) {
        final routeId = activeAssignment.busRouteId;
        print('✅ Route ID found for driver: $routeId');
        return routeId;
      }

      print('⚠️ No active route assignment found for driver: $userId');
      return null;
    } catch (e) {
      print('❌ Error getting route ID for current driver: $e');
      return null;
    }
  }

  /// Fetches all routes from the backend and filters for current driver
  Future<TrackingResponse> fetchRoutes() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      final userId = await _storage.read(key: 'userId');

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

      final url = '$baseUrl/routes';
      print('📡 Fetching routes from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Routes API Response Status: ${response.statusCode}');
      print('📋 Routes API Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final allRoutesResponse = TrackingResponse.fromJson(response.data);

        // Filter routes to only include those assigned to current driver
        final filteredRoutes =
            allRoutesResponse.data.where((route) {
              return route.routeAssignment.any(
                (assignment) =>
                    assignment.driverId == userId &&
                    assignment.assignmentStatus == 'ACTIVE',
              );
            }).toList();

        print(
          '🔍 Filtered routes for driver $userId: ${filteredRoutes.length} routes',
        );
        for (final route in filteredRoutes) {
          print('📍 Driver route: ${route.routeName} (ID: ${route.id})');
        }

        // Return filtered response
        return TrackingResponse(
          success: allRoutesResponse.success,
          data: filteredRoutes,
          statusCode: allRoutesResponse.statusCode,
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

  /// Gets the current route for the driver
  Future<RouteData?> getCurrentRoute() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) return null;

      final routes = await fetchRoutes();

      // Since fetchRoutes now filters for current driver,
      // we can simply return the first route (or null if none)
      if (routes.data.isNotEmpty) {
        final currentRoute = routes.data.first;
        print(
          '✅ Current route found: ${currentRoute.routeName} (ID: ${currentRoute.id})',
        );
        return currentRoute;
      }

      print('⚠️ No active routes found for driver: $userId');
      return null;
    } catch (e) {
      print('❌ Error getting current route: $e');
      return null;
    }
  }

  /// Initializes location services and permissions
  Future<bool> initializeLocationServices() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return false;
      }

      print('✅ Location services initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing location services: $e');
      return false;
    }
  }

  /// Connects to WebSocket server for GPS tracking
  Future<bool> connectWebSocket() async {
    try {
      if (_webSocket != null) {
        await _webSocket!.close();
      }

      final wsUrl = 'ws://$_wsHost:$_wsPort$_wsPath';
      print('🔌 Connecting to WebSocket: $wsUrl');

      _webSocket = await WebSocket.connect(wsUrl);

      _webSocket!.listen(
        (data) {
          print('📨 WebSocket received: $data');
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleWebSocketError(error);
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleWebSocketClosed();
        },
      );

      print('✅ WebSocket connected successfully');
      return true;
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
      return false;
    }
  }

  /// Starts GPS tracking and sends data to WebSocket
  Future<bool> startTracking() async {
    try {
      if (_isTracking) {
        print('⚠️ Tracking already started');
        return true;
      }

      // Initialize location services
      final locationInitialized = await initializeLocationServices();
      if (!locationInitialized) {
        throw ErrorHandler.createApiException(
          'Location services not available',
        );
      }

      // Get current route
      _currentRoute = await getCurrentRoute();
      if (_currentRoute == null) {
        throw ErrorHandler.createApiException(
          'No active route found for driver',
        );
      }

      // Connect to WebSocket
      final wsConnected = await connectWebSocket();
      if (!wsConnected) {
        throw ErrorHandler.createApiException(
          'Failed to connect to tracking server',
        );
      }

      // Start location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          _handleLocationUpdate(position);
        },
        onError: (error) {
          print('❌ Location stream error: $error');
        },
      );

      // Start periodic GPS updates
      _gpsUpdateTimer = Timer.periodic(
        const Duration(seconds: 5), // Send GPS data every 5 seconds
        (timer) {
          _sendGpsUpdate();
        },
      );

      _isTracking = true;
      print('✅ GPS tracking started successfully');
      return true;
    } catch (e) {
      print('❌ Error starting tracking: $e');
      await stopTracking();
      rethrow;
    }
  }

  /// Stops GPS tracking
  Future<void> stopTracking() async {
    try {
      _isTracking = false;

      // Stop location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Stop GPS update timer
      _gpsUpdateTimer?.cancel();
      _gpsUpdateTimer = null;

      // Close WebSocket connection
      await _webSocket?.close();
      _webSocket = null;

      print('✅ GPS tracking stopped successfully');
    } catch (e) {
      print('❌ Error stopping tracking: $e');
    }
  }

  /// Handles location updates from GPS
  void _handleLocationUpdate(Position position) {
    if (!_isTracking || _currentRoute == null) return;

    print('📍 Location update: ${position.latitude}, ${position.longitude}');

    // Create GPS tracking data
    final gpsData = GpsTrackingData.create(
      routeId: _currentRoute!.id,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      heading: position.heading.toInt(),
    );

    // Send to WebSocket
    _sendGpsDataToWebSocket(gpsData);
  }

  /// Sends GPS update manually (for testing)
  void _sendGpsUpdate() async {
    if (!_isTracking || _currentRoute == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final gpsData = GpsTrackingData.create(
        routeId: _currentRoute!.id,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        heading: position.heading.toInt(),
      );

      _sendGpsDataToWebSocket(gpsData);
    } catch (e) {
      print('❌ Error getting current position: $e');
    }
  }

  /// Sends GPS data to WebSocket server
  void _sendGpsDataToWebSocket(GpsTrackingData gpsData) {
    if (_webSocket == null) {
      print('❌ WebSocket not connected');
      return;
    }

    try {
      final jsonData = jsonEncode(gpsData.toJson());
      _webSocket!.add(jsonData);
      print('📤 GPS data sent: $jsonData');
    } catch (e) {
      print('❌ Error sending GPS data: $e');
    }
  }

  /// Handles WebSocket messages
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      print('📨 WebSocket message: $message');

      // Handle different message types
      if (message['type'] == 'ACK') {
        print('✅ GPS data acknowledged by server');
      } else if (message['type'] == 'ERROR') {
        print('❌ Server error: ${message['message']}');
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Handles WebSocket errors
  void _handleWebSocketError(dynamic error) {
    print('❌ WebSocket error: $error');
    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (_isTracking) {
        print('🔄 Attempting to reconnect WebSocket...');
        connectWebSocket();
      }
    });
  }

  /// Handles WebSocket connection closed
  void _handleWebSocketClosed() {
    print('🔌 WebSocket connection closed');
    // Attempt to reconnect if still tracking
    if (_isTracking) {
      Future.delayed(const Duration(seconds: 5), () {
        print('🔄 Attempting to reconnect WebSocket...');
        connectWebSocket();
      });
    }
  }

  /// Gets current tracking status
  bool get isTracking => _isTracking;

  /// Gets current route
  RouteData? get currentRoute => _currentRoute;

  /// Gets WebSocket connection status
  bool get isWebSocketConnected => _webSocket != null;

  /// Extracts error message from response
  String _getErrorMessageFromResponse(dynamic responseData) {
    if (responseData == null) return 'Failed to fetch routes';

    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['error'] ??
          responseData['msg'] ??
          'Failed to fetch routes';
    }

    if (responseData is String) {
      return responseData;
    }

    return 'Failed to fetch routes';
  }

  /// Disposes resources
  void dispose() {
    stopTracking();
  }
}
