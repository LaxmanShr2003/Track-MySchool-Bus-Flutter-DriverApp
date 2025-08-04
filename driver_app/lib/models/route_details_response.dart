// route_details_response.dart
class RouteDetailsResponse {
  final bool success;
  final String message;
  final RouteDetailsData data;
  final int statusCode;

  RouteDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.statusCode,
  });

  factory RouteDetailsResponse.fromJson(Map<String, dynamic> json) {
    return RouteDetailsResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: RouteDetailsData.fromJson(json['data'] as Map<String, dynamic>),
      statusCode: json['statusCode'] ?? 200,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
      'statusCode': statusCode,
    };
  }
}

class RouteDetailsData {
  final int id;
  final String routeName;
  final double startLat;
  final double endLng;
  final String startingPointName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RouteAssignmentDetails> routeAssignment;
  final List<Checkpoint> checkpoints;

  RouteDetailsData({
    required this.id,
    required this.routeName,
    required this.startLat,
    required this.endLng,
    required this.startingPointName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.routeAssignment,
    required this.checkpoints,
  });

  factory RouteDetailsData.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }

    return RouteDetailsData(
      id: json['id'] ?? 0,
      routeName: json['routeName']?.toString() ?? '',
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0.0,
      endLng: (json['endLng'] as num?)?.toDouble() ?? 0.0,
      startingPointName: json['startingPointName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      routeAssignment:
          (json['routeAssignment'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RouteAssignmentDetails.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      checkpoints:
          (json['checkpoints'] as List<dynamic>?)
              ?.map((e) => Checkpoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeName': routeName,
      'startLat': startLat,
      'endLng': endLng,
      'startingPointName': startingPointName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'routeAssignment': routeAssignment.map((e) => e.toJson()).toList(),
      'checkpoints': checkpoints.map((e) => e.toJson()).toList(),
    };
  }
}

class RouteAssignmentDetails {
  final String busId;
  final String driverId;
  final String assignedDate;
  final String endDate;
  final String assignmentStatus;
  final List<String> students;

  RouteAssignmentDetails({
    required this.busId,
    required this.driverId,
    required this.assignedDate,
    required this.endDate,
    required this.assignmentStatus,
    required this.students,
  });

  factory RouteAssignmentDetails.fromJson(Map<String, dynamic> json) {
    return RouteAssignmentDetails(
      busId: json['busId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      assignedDate: json['assignedDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? 'ACTIVE',
      students:
          (json['students'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'driverId': driverId,
      'assignedDate': assignedDate,
      'endDate': endDate,
      'assignmentStatus': assignmentStatus,
      'students': students,
    };
  }
}

class Checkpoint {
  final int id;
  final double lat;
  final double lng;
  final String label;
  final int order;

  Checkpoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    required this.order,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: json['id'] ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      label: json['label']?.toString() ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'lat': lat, 'lng': lng, 'label': label, 'order': order};
  }
}
