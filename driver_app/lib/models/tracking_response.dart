// tracking_response.dart
class TrackingResponse {
  final bool success;
  final List<RouteData> data;
  final int statusCode;

  TrackingResponse({
    required this.success,
    required this.data,
    required this.statusCode,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => RouteData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statusCode: json['statusCode'] ?? 200,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((e) => e.toJson()).toList(),
      'statusCode': statusCode,
    };
  }
}

class RouteData {
  final int id;
  final String routeName;
  final double startLat;
  final double endLng;
  final String startingPointName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RouteAssignment> routeAssignment;
  final List<Checkpoint> checkpoints;

  RouteData({
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

  factory RouteData.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }

    return RouteData(
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
              ?.map((e) => RouteAssignment.fromJson(e as Map<String, dynamic>))
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

class RouteAssignment {
  final String busId;
  final String driverId;
  final String assignedDate;
  final String endDate;
  final String assignmentStatus;
  final List<String> students;

  RouteAssignment({
    required this.busId,
    required this.driverId,
    required this.assignedDate,
    required this.endDate,
    required this.assignmentStatus,
    required this.students,
  });

  factory RouteAssignment.fromJson(Map<String, dynamic> json) {
    return RouteAssignment(
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

// GPS Tracking Data Model
class GpsTrackingData {
  final String type;
  final int routeId;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final int heading;
  final String timestamp;

  GpsTrackingData({
    required this.type,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'heading': heading,
      'timestamp': timestamp,
    };
  }

  factory GpsTrackingData.create({
    required int routeId,
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    int? heading,
  }) {
    return GpsTrackingData(
      type: 'GPS_UPDATE',
      routeId: routeId,
      latitude: latitude,
      longitude: longitude,
      speed:
          speed ?? (45 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100),
      accuracy: accuracy ?? 4.5,
      heading: heading ?? (DateTime.now().millisecondsSinceEpoch % 360),
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
