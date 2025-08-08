// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripData _$TripDataFromJson(Map<String, dynamic> json) => TripData(
  tripId: json['tripId'] as String?,
  busId: json['busId'] as String,
  routeId: json['routeId'] as String,
  direction: json['direction'] as String,
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$TripDataToJson(TripData instance) => <String, dynamic>{
  'tripId': instance.tripId,
  'busId': instance.busId,
  'routeId': instance.routeId,
  'direction': instance.direction,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'status': instance.status,
};

AttendanceData _$AttendanceDataFromJson(Map<String, dynamic> json) =>
    AttendanceData(
      tripSessionId: json['tripSessionId'] as String,
      studentId: json['studentId'] as String,
      action: _attendanceActionFromJson(json['action'] as String),
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$AttendanceDataToJson(AttendanceData instance) =>
    <String, dynamic>{
      'tripSessionId': instance.tripSessionId,
      'studentId': instance.studentId,
      'action': _attendanceActionToJson(instance.action),
      'timestamp': instance.timestamp,
    };

StudentData _$StudentDataFromJson(Map<String, dynamic> json) => StudentData(
  id: json['id'] as String,
  name: json['name'] as String,
  photoUrl: json['photoUrl'] as String?,
  grade: json['grade'] as String?,
  section: json['section'] as String?,
  attendanceStatus: json['attendanceStatus'] as String? ?? "PENDING",
);

Map<String, dynamic> _$StudentDataToJson(StudentData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'photoUrl': instance.photoUrl,
      'grade': instance.grade,
      'section': instance.section,
      'attendanceStatus': instance.attendanceStatus,
    };

TripResponse _$TripResponseFromJson(Map<String, dynamic> json) => TripResponse(
  success: json['success'] as bool,
  data:
      json['data'] == null
          ? null
          : TripData.fromJson(json['data'] as Map<String, dynamic>),
  message: json['message'] as String?,
  statusCode: (json['statusCode'] as num).toInt(),
);

Map<String, dynamic> _$TripResponseToJson(TripResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'statusCode': instance.statusCode,
    };

StudentsResponse _$StudentsResponseFromJson(Map<String, dynamic> json) =>
    StudentsResponse(
      success: json['success'] as bool,
      data:
          (json['data'] as List<dynamic>)
              .map((e) => StudentData.fromJson(e as Map<String, dynamic>))
              .toList(),
      message: json['message'] as String?,
      statusCode: (json['statusCode'] as num).toInt(),
    );

Map<String, dynamic> _$StudentsResponseToJson(StudentsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'statusCode': instance.statusCode,
    };

AttendanceResponse _$AttendanceResponseFromJson(Map<String, dynamic> json) =>
    AttendanceResponse(
      success: json['success'] as bool,
      data:
          json['data'] == null
              ? null
              : AttendanceData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      statusCode: (json['statusCode'] as num).toInt(),
    );

Map<String, dynamic> _$AttendanceResponseToJson(AttendanceResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'statusCode': instance.statusCode,
    };
