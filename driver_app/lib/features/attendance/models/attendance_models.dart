// attendance_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'attendance_models.g.dart';

// Attendance Action Enum
enum AttendanceAction {
  @JsonValue('ONBOARD')
  onboard,
  @JsonValue('OFFBOARD')
  offboard,
  @JsonValue('ABSENT')
  absent,
}

// Trip Model
@JsonSerializable()
class TripData {
  final String? tripId; // Add tripId field to store the actual trip ID
  final String busId;
  final String routeId;
  final String direction; // "HomeToSchool" or "SchoolToHome"
  final String startTime;
  final String? endTime;
  final String status; // "ACTIVE" or "COMPLETED"

  TripData({
    this.tripId, // Add tripId parameter
    required this.busId,
    required this.routeId,
    required this.direction,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory TripData.fromJson(Map<String, dynamic> json) =>
      _$TripDataFromJson(json);
  Map<String, dynamic> toJson() => _$TripDataToJson(this);

  // Create a new trip
  factory TripData.create({
    String? tripId, // Add tripId parameter
    required String busId,
    required String routeId,
    required String direction,
  }) {
    return TripData(
      tripId: tripId, // Add tripId
      busId: busId,
      routeId: routeId,
      direction: direction,
      startTime: DateTime.now().toIso8601String(),
      status: 'ACTIVE',
    );
  }

  // Complete a trip
  TripData complete() {
    return TripData(
      tripId: tripId, // Preserve tripId
      busId: busId,
      routeId: routeId,
      direction: direction,
      startTime: startTime,
      endTime: DateTime.now().toIso8601String(),
      status: 'COMPLETED',
    );
  }
}

// Attendance Model
@JsonSerializable()
class AttendanceData {
  final String tripSessionId;
  final String studentId;
  @JsonKey(fromJson: _attendanceActionFromJson, toJson: _attendanceActionToJson)
  final AttendanceAction action;
  final String timestamp;

  AttendanceData({
    required this.tripSessionId,
    required this.studentId,
    required this.action,
    required this.timestamp,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDataFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceDataToJson(this);

  // Create attendance record
  factory AttendanceData.create({
    required String tripSessionId,
    required String studentId,
    required AttendanceAction action,
  }) {
    return AttendanceData(
      tripSessionId: tripSessionId,
      studentId: studentId,
      action: action,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

// Helper functions for JSON serialization of AttendanceAction
AttendanceAction _attendanceActionFromJson(String value) {
  switch (value.toUpperCase()) {
    case 'ONBOARD':
      return AttendanceAction.onboard;
    case 'OFFBOARD':
      return AttendanceAction.offboard;
    case 'ABSENT':
      return AttendanceAction.absent;
    default:
      throw ArgumentError('Invalid attendance action: $value');
  }
}

String _attendanceActionToJson(AttendanceAction action) {
  switch (action) {
    case AttendanceAction.onboard:
      return 'ONBOARD';
    case AttendanceAction.offboard:
      return 'OFFBOARD';
    case AttendanceAction.absent:
      return 'ABSENT';
  }
}

// Student Model for attendance list
@JsonSerializable()
class StudentData {
  final String id;
  final String name;
  final String? photoUrl;
  final String? grade;
  final String? section;
  final String
  attendanceStatus; // "PENDING", "ONBOARDED", "OFFBOARDED", "ABSENT"

  StudentData({
    required this.id,
    required this.name,
    this.photoUrl,
    this.grade,
    this.section,
    this.attendanceStatus = "PENDING",
  });

  factory StudentData.fromJson(Map<String, dynamic> json) =>
      _$StudentDataFromJson(json);
  Map<String, dynamic> toJson() => _$StudentDataToJson(this);

  // Update attendance status
  StudentData updateStatus(String status) {
    return StudentData(
      id: id,
      name: name,
      photoUrl: photoUrl,
      grade: grade,
      section: section,
      attendanceStatus: status,
    );
  }
}

// Trip Response Model
@JsonSerializable()
class TripResponse {
  final bool success;
  final TripData? data;
  final String? message;
  final int statusCode;

  TripResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory TripResponse.fromJson(Map<String, dynamic> json) =>
      _$TripResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TripResponseToJson(this);
}

// Students Response Model
@JsonSerializable()
class StudentsResponse {
  final bool success;
  final List<StudentData> data;
  final String? message;
  final int statusCode;

  StudentsResponse({
    required this.success,
    required this.data,
    this.message,
    required this.statusCode,
  });

  factory StudentsResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentsResponseToJson(this);
}

// Attendance Response Model
@JsonSerializable()
class AttendanceResponse {
  final bool success;
  final AttendanceData? data;
  final String? message;
  final int statusCode;

  AttendanceResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceResponseToJson(this);
}
