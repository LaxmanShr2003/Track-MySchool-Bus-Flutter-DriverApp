import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/attendance/service/attendance_service.dart';
import 'package:driver_app/features/attendance/models/attendance_models.dart';
import 'package:driver_app/core/error_handler.dart';
import 'package:driver_app/features/chat/service/chat_service.dart';
import 'package:driver_app/core/post_login_initializer.dart';

class AttendanceState {
  final bool isLoading;
  final String? error;
  final TripData? currentTrip;
  final List<StudentData> students;
  final bool isWebSocketConnected;
  final String? busRouteId;
  final String? tripSessionId;
  final bool isPostLoginInitialized;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.currentTrip,
    this.students = const [],
    this.isWebSocketConnected = false,
    this.busRouteId,
    this.tripSessionId,
    this.isPostLoginInitialized = false,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    TripData? currentTrip,
    List<StudentData>? students,
    bool? isWebSocketConnected,
    String? busRouteId,
    String? tripSessionId,
    bool? isPostLoginInitialized,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTrip: currentTrip ?? this.currentTrip,
      students: students ?? this.students,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      busRouteId: busRouteId ?? this.busRouteId,
      tripSessionId: tripSessionId ?? this.tripSessionId,
      isPostLoginInitialized:
          isPostLoginInitialized ?? this.isPostLoginInitialized,
    );
  }
}

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceService _service;
  final ChatService _chatService;
  final Set<String> _processingStudents = <String>{};

  // Store attendance states persistently
  final Map<String, String> _persistentAttendanceStates = <String, String>{};

  AttendanceController(this._service)
    : _chatService = ChatService(),
      super(const AttendanceState());

  /// Initialize attendance system
  Future<void> initializeAttendance() async {
    print('🔄 AttendanceController: Initializing attendance system');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if post-login systems are already initialized
      final postLoginInitialized = PostLoginInitializer.instance.isInitialized;
      print('🔍 Post-login systems initialized: $postLoginInitialized');

      if (postLoginInitialized) {
        // Use the trip information from post-login initialization
        final currentTrip = PostLoginInitializer.instance.currentTrip;
        if (currentTrip != null) {
          print('✅ Using existing trip from post-login initialization');
          print('🆔 Trip ID: ${currentTrip.tripId}');
          print('🚌 Direction: ${currentTrip.direction}');

          // Set the trip in state
          state = state.copyWith(
            currentTrip: currentTrip,
            tripSessionId: currentTrip.tripId,
            isPostLoginInitialized: true,
          );
        }
      }

      // Get bus route ID for current driver
      final busRouteId = await _service.getCurrentUserBusRouteId();
      if (busRouteId == null) {
        throw ErrorHandler.createApiException(
          'No active bus route found for driver',
        );
      }

      // Set bus route ID in state FIRST
      state = state.copyWith(busRouteId: busRouteId);
      print('✅ Bus Route ID set in state: $busRouteId');

      // Load students for the route (independent of trips)
      await loadStudents();

      // If we don't have a trip from post-login, check for active trip
      if (state.currentTrip == null) {
        print('🔍 Checking for active trip...');
        final activeTrip = await _service.getActiveTrip();

        if (activeTrip != null) {
          print('✅ Found active trip during attendance initialization');
          state = state.copyWith(
            currentTrip: activeTrip,
            tripSessionId: activeTrip.tripId,
          );
        }
      }

      state = state.copyWith(isLoading: false, error: null);

      print('✅ AttendanceController: Attendance system initialized');
      print('📍 Bus Route ID: $busRouteId');
      print('🚌 Active Trip: ${state.currentTrip?.direction ?? 'None'}');
      print('🆔 Trip ID: ${state.currentTrip?.tripId ?? 'None'}');
      print('👥 Students loaded: ${state.students.length}');
      print('🔌 Post-login initialized: ${state.isPostLoginInitialized}');
    } catch (e) {
      print('❌ AttendanceController: Error initializing attendance - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Create a new trip
  Future<void> createTrip(String direction) async {
    print('🔄 AttendanceController: Creating new trip - $direction');

    if (state.busRouteId == null) {
      state = state.copyWith(error: 'Bus route ID not found');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create TripData object
      final tripData = TripData.create(
        busId: state.busRouteId!,
        routeId: state.busRouteId!,
        direction: direction,
      );

      final response = await _service.createTrip(tripData);

      if (response.success && response.data != null) {
        final createdTripData = response.data!;
        print('✅ Trip created successfully');
        print('🆔 Trip ID: ${createdTripData.tripId}');
        print('🚌 Direction: ${createdTripData.direction}');
        print('⏰ Start Time: ${createdTripData.startTime}');
        print('🔍 DEBUG - Full trip data:');
        print('  - busId: ${createdTripData.busId}');
        print('  - routeId: ${createdTripData.routeId}');
        print('  - status: ${createdTripData.status}');
        print('  - endTime: ${createdTripData.endTime}');

        // Set the tripSessionId from the API response
        final tripSessionId = createdTripData.tripId;
        print('🆔 Extracted tripSessionId from API: $tripSessionId');

        // Save trip ID to chat service for chat functionality
        if (tripSessionId != null) {
          await _chatService.setCurrentTripId(tripSessionId);
          print('💾 Trip ID saved to chat service: $tripSessionId');
        }

        state = state.copyWith(
          isLoading: false,
          currentTrip: createdTripData,
          tripSessionId: tripSessionId, // Use the extracted tripSessionId
          error: null,
        );

        print('✅ AttendanceController: Trip created and session started');
        print('🆔 Session ID set to: $tripSessionId');
        print('🔍 DEBUG - State after update:');
        print('  - state.tripSessionId: ${state.tripSessionId}');
        print('  - state.currentTrip?.tripId: ${state.currentTrip?.tripId}');
      } else {
        print('❌ Trip creation failed:');
        print('  - response.success: ${response.success}');
        print('  - response.data: ${response.data}');
        print('  - response.message: ${response.message}');
        throw ErrorHandler.createApiException(
          response.message ?? 'Failed to create trip',
        );
      }
    } catch (e) {
      print('❌ AttendanceController: Error creating trip - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Start or continue existing trip
  Future<void> startOrContinueTrip() async {
    print('🔄 AttendanceController: Starting or continuing trip');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // First, get the bus route ID if we don't have it
      if (state.busRouteId == null) {
        print('🔄 Getting bus route ID for driver...');
        final busRouteId = await _service.getCurrentUserBusRouteId();
        if (busRouteId == null) {
          throw ErrorHandler.createApiException(
            'No active bus route found for driver',
          );
        }

        // Update state with bus route ID
        state = state.copyWith(busRouteId: busRouteId);
        print('✅ Bus route ID set: $busRouteId');
      }

      // Check if we already have a trip from post-login initialization
      if (state.currentTrip != null && state.isPostLoginInitialized) {
        print('✅ Using existing trip from post-login initialization');
        print('🆔 Trip ID: ${state.currentTrip!.tripId}');
        print('🚌 Direction: ${state.currentTrip!.direction}');

        // Extract tripSessionId from the existing trip
        final tripSessionId = state.currentTrip!.tripId;
        print('🆔 Using existing tripSessionId: $tripSessionId');

        // Save trip ID to chat service for chat functionality
        if (tripSessionId != null) {
          await _chatService.setCurrentTripId(tripSessionId);
          print('💾 Trip ID saved to chat service: $tripSessionId');
        }

        // Store busRouteId before updating state to prevent it from being lost
        final currentBusRouteId = state.busRouteId;
        print('🔒 Preserving bus route ID: $currentBusRouteId');

        state = state.copyWith(
          isLoading: false,
          currentTrip: state.currentTrip,
          tripSessionId: tripSessionId,
          error: null,
        );

        print(
          '✅ AttendanceController: Continuing existing trip from post-login',
        );
        print('🆔 Session ID: $tripSessionId');
        print('🚌 Direction: ${state.currentTrip!.direction}');
        return;
      }

      // Check for existing active trip
      final activeTrip = await _service.getActiveTrip();

      if (activeTrip != null) {
        // Continue existing trip
        print('🔄 Continuing existing trip');
        print('🆔 Trip ID: ${activeTrip.tripId}');
        print('🚌 Direction: ${activeTrip.direction}');

        // Extract tripSessionId from the active trip
        final tripSessionId = activeTrip.tripId;
        print('🆔 Extracted tripSessionId from active trip: $tripSessionId');

        // Save trip ID to chat service for chat functionality
        if (tripSessionId != null) {
          await _chatService.setCurrentTripId(tripSessionId);
          print('💾 Trip ID saved to chat service: $tripSessionId');
        }

        // Store busRouteId before updating state to prevent it from being lost
        final currentBusRouteId = state.busRouteId;
        print('🔒 Preserving bus route ID: $currentBusRouteId');

        state = state.copyWith(
          isLoading: false,
          currentTrip: activeTrip,
          tripSessionId: tripSessionId,
          error: null,
        );

        print('✅ AttendanceController: Trip continued successfully');
        print('🆔 Session ID: $tripSessionId');
        print('🚌 Direction: ${activeTrip.direction}');
      } else {
        // No active trip found
        print('ℹ️ No active trip found');
        print('💬 Chat will be available after creating a new trip');

        state = state.copyWith(
          isLoading: false,
          currentTrip: null,
          tripSessionId: null,
          error: null,
        );

        print('✅ AttendanceController: No active trip to continue');
      }
    } catch (e) {
      print('❌ AttendanceController: Error starting/continuing trip - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Ensure bus route ID is available in state
  Future<String?> _ensureBusRouteId() async {
    if (state.busRouteId != null) {
      return state.busRouteId;
    }

    try {
      final busRouteId = await _service.getCurrentUserBusRouteId();
      if (busRouteId != null) {
        state = state.copyWith(busRouteId: busRouteId);
        print('✅ Retrieved and set bus route ID: $busRouteId');
      }
      return busRouteId;
    } catch (e) {
      print('❌ Failed to retrieve bus route ID: $e');
      return null;
    }
  }

  /// Refresh bus route ID from service
  Future<void> refreshBusRouteId() async {
    print('🔄 Refreshing bus route ID...');
    final busRouteId = await _ensureBusRouteId();
    if (busRouteId != null) {
      print('✅ Bus route ID refreshed: $busRouteId');
    } else {
      print('❌ Failed to refresh bus route ID');
    }
  }

  /// Refresh trip session ID from current trip
  Future<void> refreshTripSessionId() async {
    print('🔄 Refreshing trip session ID...');
    if (state.currentTrip?.tripId != null) {
      state = state.copyWith(tripSessionId: state.currentTrip!.tripId);
      print('✅ Trip session ID refreshed: ${state.tripSessionId}');
    } else {
      print('❌ No current trip available to refresh trip session ID');
    }
  }

  /// Ensure state consistency by refreshing critical data
  Future<void> ensureStateConsistency() async {
    print('🔄 Ensuring state consistency...');

    // Refresh bus route ID if needed
    if (state.busRouteId == null) {
      print('⚠️ Bus route ID is null, refreshing...');
      await refreshBusRouteId();
    }

    // Refresh trip session ID if needed
    if (state.tripSessionId == null && state.currentTrip?.tripId != null) {
      print(
        '⚠️ Trip session ID is null but current trip exists, refreshing...',
      );
      await refreshTripSessionId();
    }

    // Verify trip session ID is still valid
    if (state.tripSessionId != null && state.currentTrip == null) {
      print('⚠️ Trip session ID exists but no current trip, refreshing...');
      // Try to get the active trip again
      try {
        final activeTrip = await _service.getActiveTrip();
        if (activeTrip != null) {
          state = state.copyWith(currentTrip: activeTrip);
          print('✅ Current trip refreshed: ${activeTrip.tripId}');
        }
      } catch (e) {
        print('❌ Failed to refresh current trip: $e');
      }
    }

    print('✅ State consistency check completed');
  }

  /// Load students for current bus route
  Future<void> loadStudents() async {
    print('🔄 AttendanceController: Loading students');
    print('🔍 Current state busRouteId: ${state.busRouteId}');

    // Ensure bus route ID is available
    final busRouteId = await _ensureBusRouteId();

    if (busRouteId == null) {
      print('❌ Bus route ID is still null, cannot load students');
      state = state.copyWith(error: 'Bus route ID not found');
      return;
    }

    print('📍 Loading students for bus route: $busRouteId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Store busRouteId in a local variable to prevent race conditions
      final localBusRouteId = busRouteId;
      print('🔍 Using local bus route ID: $localBusRouteId');

      print('🔍 Using bus route ID: $localBusRouteId');
      final response = await _service.getStudentsByBusRoute(localBusRouteId);
      print('🔍 Response: $response');
      if (response.success) {
        print(
          '✅ Students loaded successfully: ${response.data.length} students',
        );

        // Apply persistent attendance states to loaded students
        final studentsWithPersistentState =
            response.data.map((student) {
              final persistentStatus = _persistentAttendanceStates[student.id];
              if (persistentStatus != null && persistentStatus != 'PENDING') {
                print(
                  '🔄 Restoring persistent state for ${student.name}: $persistentStatus',
                );
                return student.updateStatus(persistentStatus);
              }
              print(
                '🔍 Student: ${student.name} (ID: ${student.id}) - Status: ${student.attendanceStatus}',
              );
              return student;
            }).toList();

        for (final student in studentsWithPersistentState) {
          print(
            '👤 Student: ${student.name} (ID: ${student.id}) - Status: ${student.attendanceStatus}',
          );
        }

        state = state.copyWith(
          isLoading: false,
          students: studentsWithPersistentState,
          error: null,
        );

        print('✅ AttendanceController: Students loaded successfully');
        print('👥 Total Students: ${studentsWithPersistentState.length}');
      } else {
        print('❌ Failed to load students: ${response.message}');
        throw ErrorHandler.createApiException(
          response.message ?? 'Failed to load students',
        );
      }
    } catch (e) {
      print('❌ AttendanceController: Error loading students - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Mark attendance for a student
  Future<void> markAttendance(String studentId, String action) async {
    print(
      '🔄 AttendanceController: Marking attendance - $action for student $studentId',
    );

    // Prevent multiple simultaneous calls for the same student
    if (_processingStudents.contains(studentId)) {
      print('⏳ Student $studentId is already being processed, skipping...');
      return;
    }

    if (state.tripSessionId == null) {
      state = state.copyWith(error: 'No active trip session');
      return;
    }

    print('🆔 Using trip session ID: ${state.tripSessionId}');

    _processingStudents.add(studentId);

    try {
      // Convert string action to enum
      AttendanceAction attendanceAction;
      switch (action.toUpperCase()) {
        case 'ONBOARD':
          attendanceAction = AttendanceAction.onboard;
          break;
        case 'OFFBOARD':
          attendanceAction = AttendanceAction.offboard;
          break;
        case 'ABSENT':
          attendanceAction = AttendanceAction.absent;
          break;
        default:
          throw ErrorHandler.createApiException(
            'Invalid attendance action: $action',
          );
      }

      final attendanceData = AttendanceData.create(
        tripSessionId: state.tripSessionId!,
        studentId: studentId,
        action: attendanceAction,
      );

      print(
        '📤 Creating attendance data with trip ID: ${attendanceData.tripSessionId}',
      );

      // Send via WebSocket
      final wsSuccess = await _service.sendAttendanceViaWebSocket(
        attendanceData,
      );

      if (wsSuccess) {
        // Update local state - persist attendance state until trip completion
        String newStatus;
        switch (action.toUpperCase()) {
          case 'ONBOARD':
            newStatus = 'ONBOARDED';
            break;
          case 'OFFBOARD':
            newStatus = 'OFFBOARDED';
            break;
          case 'ABSENT':
            newStatus = 'ABSENT';
            break;
          default:
            newStatus = 'PENDING';
        }

        // Store in persistent map
        _persistentAttendanceStates[studentId] = newStatus;
        print('💾 Stored persistent state for $studentId: $newStatus');

        final updatedStudents =
            state.students.map((student) {
              if (student.id == studentId) {
                print(
                  '📝 Updating student ${student.name} status to: $newStatus',
                );
                return student.updateStatus(newStatus);
              }
              return student;
            }).toList();

        state = state.copyWith(students: updatedStudents, error: null);

        print('✅ AttendanceController: Attendance marked successfully');
        print('📤 WebSocket: $action for student $studentId');
        print('👥 Current attendance state:');
        for (final student in state.students) {
          print('  - ${student.name}: ${student.attendanceStatus}');
        }
      } else {
        throw ErrorHandler.createApiException(
          'Failed to send attendance via WebSocket',
        );
      }
    } catch (e) {
      print('❌ AttendanceController: Error marking attendance - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
    } finally {
      _processingStudents.remove(studentId);
    }
  }

  /// Complete current trip
  Future<void> completeTrip() async {
    print('🔄 AttendanceController: Completing trip');

    if (state.currentTrip == null) {
      state = state.copyWith(error: 'No active trip to complete');
      return;
    }

    // Check if trip can be completed
    if (!canCompleteTrip) {
      final studentsNeedingOffboarding = this.studentsNeedingOffboarding;
      final message =
          studentsNeedingOffboarding.isNotEmpty
              ? 'Cannot complete trip: ${studentsNeedingOffboarding.length} student(s) still need to be offboarded'
              : 'Cannot complete trip: All students must be offboarded or absent';
      state = state.copyWith(error: message);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the trip ID from the current trip
      final tripId = state.currentTrip!.tripId;
      if (tripId == null) {
        throw ErrorHandler.createApiException('Trip ID not found');
      }

      final response = await _service.completeTrip(tripId);

      if (response.success) {
        // Clear persistent attendance states when trip is completed
        _persistentAttendanceStates.clear();
        print('🗑️ Cleared persistent attendance states');

        // Clear trip ID from chat service when trip is completed
        await _chatService.clearCurrentTripId();
        print('🗑️ Trip ID cleared from chat service');

        // Reset all students to PENDING status when trip is completed
        final resetStudents =
            state.students.map((student) {
              return student.updateStatus('PENDING');
            }).toList();

        state = state.copyWith(
          isLoading: false,
          currentTrip: null,
          tripSessionId: null,
          students: resetStudents, // Reset attendance states
          error: null,
        );

        print('✅ AttendanceController: Trip completed successfully');
        print('🔄 All students reset to PENDING status');
      } else {
        throw ErrorHandler.createApiException(
          response.message ?? 'Failed to complete trip',
        );
      }
    } catch (e) {
      print('❌ AttendanceController: Error completing trip - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Initialize WebSocket connection
  Future<void> initializeWebSocket() async {
    print('🔄 AttendanceController: Initializing WebSocket');

    // Wait a bit for state to be properly updated
    await Future.delayed(const Duration(milliseconds: 100));

    // Ensure we have both trip session ID and bus route ID
    if (state.tripSessionId == null) {
      print('❌ No trip session ID, cannot initialize WebSocket');
      print('🔍 Current state:');
      print('  - Trip Session ID: ${state.tripSessionId}');
      print('  - Current Trip: ${state.currentTrip?.tripId}');
      print('  - Bus Route ID: ${state.busRouteId}');

      // Try to get trip ID from current trip if available
      if (state.currentTrip?.tripId != null) {
        print('🔄 Attempting to restore trip session ID from current trip');
        state = state.copyWith(tripSessionId: state.currentTrip!.tripId);
        print('✅ Trip session ID restored: ${state.tripSessionId}');
      } else {
        print('❌ No current trip available, cannot initialize WebSocket');
        return;
      }
    }

    // Ensure bus route ID is available
    final busRouteId = await _ensureBusRouteId();
    if (busRouteId == null) {
      print('❌ No bus route ID, cannot initialize WebSocket');
      return;
    }

    // Ensure state consistency before WebSocket connection
    await ensureStateConsistency();

    try {
      final success = await _service.initializeWebSocket();
      state = state.copyWith(
        isWebSocketConnected: success,
        error: success ? null : 'Failed to connect to WebSocket',
      );

      if (success) {
        print('✅ AttendanceController: WebSocket connected');
        print(
          '🔍 WebSocket context - Trip ID: ${state.tripSessionId}, Bus Route: $busRouteId',
        );

        // Double-check that our state is still intact after WebSocket connection
        print('🔍 Post-WebSocket state verification:');
        print('  - Trip Session ID: ${state.tripSessionId}');
        print('  - Bus Route ID: ${state.busRouteId}');
        print('  - Current Trip: ${state.currentTrip?.tripId}');

        // If bus route ID was lost, restore it
        if (state.busRouteId != busRouteId) {
          print(
            '⚠️ Bus route ID was lost during WebSocket connection, restoring...',
          );
          state = state.copyWith(busRouteId: busRouteId);
          print('✅ Bus route ID restored: ${state.busRouteId}');
        }
      } else {
        print('❌ AttendanceController: WebSocket connection failed');
      }
    } catch (e) {
      print('❌ AttendanceController: Error initializing WebSocket - $e');
      state = state.copyWith(
        isWebSocketConnected: false,
        error: 'WebSocket connection error',
      );
    }
  }

  /// Get bus ID for current driver
  Future<String> _getBusIdForCurrentDriver() async {
    final busId = await _service.getBusIdForCurrentDriver();
    if (busId == null) {
      throw ErrorHandler.createApiException('No bus assigned to driver');
    }
    return busId;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset attendance state
  void reset() {
    state = const AttendanceState();
  }

  // Getters
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  TripData? get currentTrip => state.currentTrip;
  List<StudentData> get students => state.students;
  bool get isWebSocketConnected => state.isWebSocketConnected;
  String? get busRouteId => state.busRouteId;
  String? get tripSessionId => state.tripSessionId;
  bool get hasActiveTrip => state.currentTrip != null;
  bool get hasStudents => state.students.isNotEmpty;

  /// Get current trip ID
  String? get currentTripId => state.tripSessionId;

  /// Get current attendance state for a student
  String getStudentAttendanceState(String studentId) {
    return _persistentAttendanceStates[studentId] ?? 'PENDING';
  }

  /// Check if any students have been marked
  bool get hasMarkedStudents {
    return _persistentAttendanceStates.values.any(
      (status) => status != 'PENDING',
    );
  }

  /// Get attendance summary
  Map<String, int> get attendanceSummary {
    final onboardedCount =
        _persistentAttendanceStates.values
            .where((status) => status == 'ONBOARDED')
            .length;
    final offboardedCount =
        _persistentAttendanceStates.values
            .where((status) => status == 'OFFBOARDED')
            .length;
    final absentCount =
        _persistentAttendanceStates.values
            .where((status) => status == 'ABSENT')
            .length;
    final pendingCount =
        state.students.length - onboardedCount - offboardedCount - absentCount;

    return {
      'ONBOARDED': onboardedCount,
      'OFFBOARDED': offboardedCount,
      'ABSENT': absentCount,
      'PENDING': pendingCount,
    };
  }

  /// Check if trip can be completed (all students must be OFFBOARDED or ABSENT)
  bool get canCompleteTrip {
    // Check if all students have been marked as OFFBOARDED or ABSENT
    final summary = attendanceSummary;
    final onboardedCount = summary['ONBOARDED'] ?? 0;
    final pendingCount = summary['PENDING'] ?? 0;

    // Trip can be completed if there are no ONBOARDED or PENDING students
    // (all students must be either OFFBOARDED or ABSENT)
    return onboardedCount == 0 && pendingCount == 0;
  }

  /// Get students that still need to be offboarded
  List<StudentData> get studentsNeedingOffboarding {
    return state.students.where((student) {
      final status = _persistentAttendanceStates[student.id] ?? 'PENDING';
      return status == 'ONBOARDED';
    }).toList();
  }
}

// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

// Provider for AttendanceController
final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
      final service = ref.watch(attendanceServiceProvider);
      return AttendanceController(service);
    });
