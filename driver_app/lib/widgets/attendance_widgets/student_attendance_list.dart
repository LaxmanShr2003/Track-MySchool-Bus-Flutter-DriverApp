import 'package:flutter/material.dart';
import 'package:driver_app/features/attendance/models/attendance_models.dart';
import 'package:driver_app/features/attendance/controller/attendance_controller.dart';

class StudentAttendanceList extends StatelessWidget {
  final List<StudentData> students;
  final Function(String studentId, String action) onMarkAttendance;
  final VoidCallback onCompleteTrip;
  final bool isLoading;
  final bool isWebSocketConnected;
  final AttendanceController? controller; // Add controller reference

  const StudentAttendanceList({
    super.key,
    required this.students,
    required this.onMarkAttendance,
    required this.onCompleteTrip,
    this.isLoading = false,
    this.isWebSocketConnected = false,
    this.controller, // Add controller parameter
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Color(0xFF6B7280)),
            SizedBox(height: 16),
            Text(
              'No students assigned to this route',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Trip Status Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
                color:
                    isWebSocketConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isWebSocketConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      isWebSocketConnected
                          ? 'Connected - Ready for attendance'
                          : 'Disconnected - Check connection',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAttendanceSummary(),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ), // Add bottom padding
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentAttendanceCard(
                student: student,
                onMarkAttendance: onMarkAttendance,
                isLoading: isLoading,
              );
            },
          ),
        ),

        // Complete Trip Button
        Container(
          margin: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ), // Extra bottom margin for bottom nav
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onCompleteTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Complete Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    // Use controller's persistent attendance states if available, otherwise fall back to student list
    Map<String, int> summary;

    if (controller != null) {
      summary = controller!.attendanceSummary;
    } else {
      // Fallback to calculating from student list
      final onboardedCount =
          students.where((s) => s.attendanceStatus == 'ONBOARDED').length;
      final absentCount =
          students.where((s) => s.attendanceStatus == 'ABSENT').length;
      final pendingCount =
          students.where((s) => s.attendanceStatus == 'PENDING').length;

      summary = {
        'ONBOARDED': onboardedCount,
        'ABSENT': absentCount,
        'PENDING': pendingCount,
      };
    }

    return Row(
      children: [
        _buildSummaryItem(
          'Onboarded',
          summary['ONBOARDED'] ?? 0,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _buildSummaryItem(
          'Absent',
          summary['ABSENT'] ?? 0,
          const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),
        _buildSummaryItem(
          'Pending',
          summary['PENDING'] ?? 0,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final StudentData student;
  final Function(String studentId, String action) onMarkAttendance;
  final bool isLoading;

  const _StudentAttendanceCard({
    required this.student,
    required this.onMarkAttendance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnboarded = student.attendanceStatus == 'ONBOARDED';
    final isPending = student.attendanceStatus == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Student Photo (tappable to view profile)
            InkWell(
              onTap: () => _showStudentProfile(context, student),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child:
                    student.photoUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            student.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Color(0xFF6B7280),
                                size: 24,
                              );
                            },
                          ),
                        )
                        : const Icon(
                          Icons.person,
                          color: Color(0xFF6B7280),
                          size: 24,
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (student.grade != null || student.section != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${student.grade ?? ''} ${student.section ?? ''}'.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        student.attendanceStatus,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      student.attendanceStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(student.attendanceStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons stacked vertically
            if (isPending && !isLoading) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ActionButton(
                    label: 'ONBOARD',
                    color: const Color(0xFF10B981),
                    onTap: () => onMarkAttendance(student.id, 'ONBOARD'),
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'ABSENT',
                    color: const Color(0xFFEF4444),
                    onTap: () => onMarkAttendance(student.id, 'ABSENT'),
                  ),
                ],
              ),
            ] else if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Icon(
                isOnboarded ? Icons.check_circle : Icons.cancel,
                color:
                    isOnboarded
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ONBOARDED':
        return const Color(0xFF10B981);
      case 'ABSENT':
        return const Color(0xFFEF4444);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

void _showStudentProfile(BuildContext context, StudentData student) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      student.photoUrl != null
                          ? NetworkImage(student.photoUrl!)
                          : null,
                  child:
                      student.photoUrl == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.grade ?? 'N/A'} ${student.section ?? 'N/A'}'
                            .trim(),
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('ID: ${student.id}'),
            if (student.photoUrl != null) Text('Photo: ${student.photoUrl}'),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
