import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/attendance/controller/attendance_controller.dart';
import 'package:driver_app/widgets/attendance_widgets/direction_selection_card.dart';
import 'package:driver_app/widgets/attendance_widgets/student_attendance_list.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAttendance();
    });
  }

  Future<void> _initializeAttendance() async {
    print('🔄 _initializeAttendance called');
    final controller = ref.read(attendanceControllerProvider.notifier);

    try {
      await controller.initializeAttendance();
      print('✅ Attendance system initialized');

      // Check for existing active trip
      await controller.startOrContinueTrip();
      print('✅ Trip status checked');

      print('📡 Initializing WebSocket...');
      await controller.initializeWebSocket();
      print('✅ WebSocket initialized');
    } catch (e) {
      print('❌ Error in _initializeAttendance: $e');
      print('🔄 Continuing with UI despite initialization error');
    }
  }

  Future<void> _createTrip(String direction) async {
    print('🔄 _createTrip called with direction: $direction');
    final controller = ref.read(attendanceControllerProvider.notifier);

    try {
      await controller.createTrip(direction);

      // Check if trip was successfully created
      final currentTrip = controller.currentTrip;
      print(
        '📋 Current trip after createTrip: ${currentTrip?.direction ?? 'null'}',
      );

      if (currentTrip != null) {
        print('✅ Trip is active, students should already be loaded');
        print('👥 Current students: ${controller.students.length}');
        for (final student in controller.students) {
          print('  - ${student.name}: ${student.attendanceStatus}');
        }
      } else {
        print('❌ No trip was created');
      }
    } catch (e) {
      print('❌ Error in _createTrip: $e');
      // Error will be shown via the error handling in the build method
    }
  }

  Future<void> _markAttendance(String studentId, String action) async {
    final controller = ref.read(attendanceControllerProvider.notifier);
    await controller.markAttendance(studentId, action);
  }

  Future<void> _completeTrip() async {
    final controller = ref.read(attendanceControllerProvider.notifier);
    await controller.completeTrip();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);

    // Show error if any
    if (attendanceState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(attendanceState.error!);
        controller.clearError();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1F2937)),
            onPressed: attendanceState.isLoading ? null : _initializeAttendance,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          bottom: 16,
        ), // Add bottom padding for bottom nav
        child:
            attendanceState.isLoading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading attendance...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
                : attendanceState.currentTrip != null
                ? StudentAttendanceList(
                  students: attendanceState.students,
                  onMarkAttendance: _markAttendance,
                  onCompleteTrip: _completeTrip,
                  isLoading: attendanceState.isLoading,
                  isWebSocketConnected: attendanceState.isWebSocketConnected,
                  controller: controller, // Pass the controller
                )
                : Column(
                  children: [
                    // Direction selection card
                    DirectionSelectionCard(
                      onHomeToSchool: () => _createTrip('HomeToSchool'),
                      onSchoolToHome: () => _createTrip('SchoolToHome'),
                      isLoading: attendanceState.isLoading,
                    ),
                  ],
                ),
      ),
    );
  }
}
