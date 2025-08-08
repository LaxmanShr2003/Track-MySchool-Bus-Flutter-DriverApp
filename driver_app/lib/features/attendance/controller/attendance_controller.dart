import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/attendance/service/attendance_service.dart';
import 'package:driver_app/features/attendance/models/attendance_models.dart';
import 'package:driver_app/core/error_handler.dart';

class AttendanceState {
  final bool isLoading;
  final String? error;
  final TripData? currentTrip;
  final List<StudentData> students;
  final bool isWebSocketConnected;
  final String? busRouteId;
  final String? tripSessionId;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.currentTrip,
    this.students = const [],
    this.isWebSocketConnected = false,
    this.busRouteId,
    this.tripSessionId,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    TripData? currentTrip,
    List<StudentData>? students,
    bool? isWebSocketConnected,
    String? busRouteId,
    String? tripSessionId,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTrip: currentTrip ?? this.currentTrip,
      students: students ?? this.students,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      busRouteId: busRouteId ?? this.busRouteId,
      tripSessionId: tripSessionId ?? this.tripSessionId,
    );
  }
}

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceService _service;
  final Set<String> _processingStudents = <String>{};

  // Store attendance states persistently
  final Map<String, String> _persistentAttendanceStates = <String, String>{};

  AttendanceController(this._service) : super(const AttendanceState());

  /// Initialize attendance system
  Future<void> initializeAttendance() async {
    print('🔄 AttendanceController: Initializing attendance system');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get bus route ID for current driver
      final busRouteId = await _service.getCurrentUserBusRouteId();
      if (busRouteId == null) {
        throw ErrorHandler.createApiException(
          'No active bus route found for driver',
        );
      }

      // Load students for the route (independent of trips)
      await loadStudents();

      // Check for active trip
      final activeTrip = await _service.getActiveTrip();

      state = state.copyWith(
        isLoading: false,
        busRouteId: busRouteId,
        currentTrip: activeTrip,
        tripSessionId: activeTrip?.tripId, // Use tripId instead of startTime
        error: null,
      );

      print('✅ AttendanceController: Attendance system initialized');
      print('📍 Bus Route ID: $busRouteId');
      print('🚌 Active Trip: ${activeTrip?.direction ?? 'None'}');
      print('🆔 Trip ID: ${activeTrip?.tripId ?? 'None'}');
      print('👥 Students loaded: ${state.students.length}');
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

    if (state.busRouteId == null) {
      state = state.copyWith(error: 'Bus route ID not found');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
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

        state = state.copyWith(
          isLoading: false,
          currentTrip: activeTrip,
          tripSessionId: tripSessionId, // Use the extracted tripSessionId
          error: null,
        );

        // Load students for the existing trip
        await loadStudents();

        print('✅ AttendanceController: Continuing existing trip');
        print('🆔 Session ID set to: $tripSessionId');
      } else {
        // No active trip, show direction selection
        print('ℹ️ No active trip found, showing direction selection');
        state = state.copyWith(
          isLoading: false,
          currentTrip: null,
          tripSessionId: null,
          error: null,
        );
      }
    } catch (e) {
      print('❌ AttendanceController: Error starting/continuing trip - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Load students for current bus route
  Future<void> loadStudents() async {
    print('🔄 AttendanceController: Loading students');

    if (state.busRouteId == null) {
      print('❌ Bus route ID is null, cannot load students');
      state = state.copyWith(error: 'Bus route ID not found');
      return;
    }

    print('📍 Loading students for bus route: ${state.busRouteId}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getStudentsByBusRoute(state.busRouteId!);

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
        final newStatus = action == 'ONBOARD' ? 'ONBOARDED' : 'ABSENT';

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

    state = state.copyWith(isLoading: true, error: null);

    try {
      // You might need to adjust this based on your API structure
      final tripId =
          state.currentTrip!.startTime; // Using startTime as ID for now
      final response = await _service.completeTrip(tripId);

      if (response.success) {
        // Clear persistent attendance states when trip is completed
        _persistentAttendanceStates.clear();
        print('🗑️ Cleared persistent attendance states');

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

    try {
      final success = await _service.initializeWebSocket();
      state = state.copyWith(
        isWebSocketConnected: success,
        error: success ? null : 'Failed to connect to WebSocket',
      );

      if (success) {
        print('✅ AttendanceController: WebSocket connected');
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
    final absentCount =
        _persistentAttendanceStates.values
            .where((status) => status == 'ABSENT')
            .length;
    final pendingCount = state.students.length - onboardedCount - absentCount;

    return {
      'ONBOARDED': onboardedCount,
      'ABSENT': absentCount,
      'PENDING': pendingCount,
    };
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
