import 'package:driver_app/features/attendance/service/attendance_service.dart';
import 'package:driver_app/features/chat/service/chat_service.dart';
import 'package:driver_app/core/websocket_manager.dart';
import 'package:driver_app/features/attendance/models/attendance_models.dart';

/// Service responsible for initializing systems after successful login
/// This includes checking for existing trips, setting up chat, and WebSocket connections
class PostLoginInitializer {
  static final PostLoginInitializer instance = PostLoginInitializer._internal();
  PostLoginInitializer._internal();

  final AttendanceService _attendanceService = AttendanceService();
  final ChatService _chatService = ChatService();

  bool _isInitialized = false;
  TripData? _currentTrip;

  /// Check if post-login systems are initialized
  bool get isInitialized => _isInitialized;

  /// Get the current active trip if any
  TripData? get currentTrip => _currentTrip;

  /// Initialize all post-login systems
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('ℹ️ Post-login systems already initialized');
      return true;
    }

    try {
      print('🔄 PostLoginInitializer: Starting initialization...');

      // Step 1: Check for existing active trip
      final tripCheckResult = await _checkForExistingTrip();

      // Step 2: Initialize WebSocket connection
      final wsResult = await _initializeWebSocket();

      // Step 3: Set up chat system if trip exists
      if (tripCheckResult && _currentTrip != null) {
        await _setupChatSystem();
      }

      _isInitialized = true;
      print('✅ PostLoginInitializer: All systems initialized successfully');
      return true;
    } catch (e) {
      print('❌ PostLoginInitializer: Error during initialization - $e');
      return false;
    }
  }

  /// Check for existing active trip
  Future<bool> _checkForExistingTrip() async {
    try {
      print('🔍 PostLoginInitializer: Checking for existing active trip...');

      final activeTrip = await _attendanceService.getActiveTrip();

      if (activeTrip != null) {
        _currentTrip = activeTrip;
        print('✅ PostLoginInitializer: Found existing active trip');
        print('🆔 Trip ID: ${activeTrip.tripId}');
        print('🚌 Direction: ${activeTrip.direction}');
        print('⏰ Start Time: ${activeTrip.startTime}');
        return true;
      } else {
        print('ℹ️ PostLoginInitializer: No existing active trip found');
        _currentTrip = null;
        return false;
      }
    } catch (e) {
      print('❌ PostLoginInitializer: Error checking for existing trip - $e');
      _currentTrip = null;
      return false;
    }
  }

  /// Initialize WebSocket connection
  Future<bool> _initializeWebSocket() async {
    try {
      print('🔌 PostLoginInitializer: Initializing WebSocket connection...');

      final wsConnected = await _attendanceService.initializeWebSocket();

      if (wsConnected) {
        print('✅ PostLoginInitializer: WebSocket connection established');
        return true;
      } else {
        print('⚠️ PostLoginInitializer: WebSocket connection failed');
        return false;
      }
    } catch (e) {
      print('❌ PostLoginInitializer: Error initializing WebSocket - $e');
      return false;
    }
  }

  /// Set up chat system for existing trip
  Future<void> _setupChatSystem() async {
    try {
      if (_currentTrip?.tripId == null) {
        print('⚠️ PostLoginInitializer: No trip ID available for chat setup');
        return;
      }

      print('💬 PostLoginInitializer: Setting up chat system...');

      // Set the trip ID in chat service
      await _chatService.setCurrentTripId(_currentTrip!.tripId!);
      print('💾 PostLoginInitializer: Trip ID set in chat service');

      // Join the trip chat
      await _chatService.joinTripChat(_currentTrip!.tripId!);
      print('🚪 PostLoginInitializer: Joined existing trip chat');

      // Load existing messages for the trip
      final messages = await _chatService.getLocalMessages(
        _currentTrip!.tripId!,
      );
      print(
        '📋 PostLoginInitializer: Loaded ${messages.length} existing messages',
      );
    } catch (e) {
      print('❌ PostLoginInitializer: Error setting up chat system - $e');
    }
  }

  /// Refresh the current trip status
  Future<void> refreshTripStatus() async {
    try {
      print('🔄 PostLoginInitializer: Refreshing trip status...');

      final wasInitialized = _isInitialized;
      _isInitialized = false;

      final tripExists = await _checkForExistingTrip();

      if (tripExists && _currentTrip != null && !wasInitialized) {
        // If we found a trip and weren't initialized before, set up chat
        await _setupChatSystem();
      }

      _isInitialized = true;
      print('✅ PostLoginInitializer: Trip status refreshed');
    } catch (e) {
      print('❌ PostLoginInitializer: Error refreshing trip status - $e');
      _isInitialized = false;
    }
  }

  /// Check if chat is available (requires active trip)
  bool get isChatAvailable => _currentTrip != null && _isInitialized;

  /// Get trip information for display
  Map<String, dynamic>? get tripInfo {
    if (_currentTrip == null) return null;

    return {
      'tripId': _currentTrip!.tripId,
      'direction': _currentTrip!.direction,
      'startTime': _currentTrip!.startTime,
      'status': _currentTrip!.status,
    };
  }

  /// Clear all initialization state
  void reset() {
    _isInitialized = false;
    _currentTrip = null;
    print('🔄 PostLoginInitializer: State reset');
  }
}
