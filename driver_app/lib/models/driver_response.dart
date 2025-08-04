// driver_response.dart
class DriverResponse {
  final bool success;
  final DriverMessage message;
  final String data;

  DriverResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DriverResponse.fromJson(Map<String, dynamic> json) {
    return DriverResponse(
      success: json['success'] ?? false,
      message: DriverMessage.fromJson(json['message'] as Map<String, dynamic>),
      data: json['data']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message.toJson(), 'data': data};
  }
}

class DriverMessage {
  final String id;
  final String firstName;
  final String lastName;
  final String userName;
  final String profileImageUrl;
  final String mobileNumber;
  final String email;
  final String gender;
  final String password;
  final String address;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String licenseNumber;
  final bool isAssigned;
  final List<RouteAssignment> routeAssignment;

  DriverMessage({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.profileImageUrl,
    required this.mobileNumber,
    required this.email,
    required this.gender,
    required this.password,
    required this.address,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.licenseNumber,
    required this.isAssigned,
    required this.routeAssignment,
  });

  factory DriverMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }

    return DriverMessage(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updateAt']),
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      isAssigned: json['isAssigned'] ?? false,
      routeAssignment:
          (json['routeAssignment'] as List<dynamic>?)
              ?.map((e) => RouteAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,
      'profileImageUrl': profileImageUrl,
      'mobileNumber': mobileNumber,
      'email': email,
      'gender': gender,
      'password': password,
      'address': address,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updateAt': updatedAt.toIso8601String(),
      'licenseNumber': licenseNumber,
      'isAssigned': isAssigned,
      'routeAssignment': routeAssignment.map((e) => e.toJson()).toList(),
    };
  }
}

class RouteAssignment {
  final String busId;
  final String driverId;
  final String studentId;
  final int busRouteId;
  final String assignedDate;
  final String endDate;
  final String assignmentStatus;
  final Bus bus;
  final BusRoute busRoute;

  RouteAssignment({
    required this.busId,
    required this.driverId,
    required this.studentId,
    required this.busRouteId,
    required this.assignedDate,
    required this.endDate,
    required this.assignmentStatus,
    required this.bus,
    required this.busRoute,
  });

  factory RouteAssignment.fromJson(Map<String, dynamic> json) {
    return RouteAssignment(
      busId: json['busId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      busRouteId: json['busRouteId'] ?? 0,
      assignedDate: json['assignedDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? 'ACTIVE',
      bus: Bus.fromJson(json['bus'] as Map<String, dynamic>),
      busRoute: BusRoute.fromJson(json['busRoute'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'driverId': driverId,
      'studentId': studentId,
      'busRouteId': busRouteId,
      'assignedDate': assignedDate,
      'endDate': endDate,
      'assignmentStatus': assignmentStatus,
      'bus': bus.toJson(),
      'busRoute': busRoute.toJson(),
    };
  }
}

class Bus {
  final String id;
  final String busName;
  final String plateNumber;
  final bool isAssigned;
  final bool isActive;

  Bus({
    required this.id,
    required this.busName,
    required this.plateNumber,
    required this.isAssigned,
    required this.isActive,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id']?.toString() ?? '',
      busName: json['busName']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      isAssigned: json['isAssigned'] ?? false,
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busName': busName,
      'plateNumber': plateNumber,
      'isAssigned': isAssigned,
      'isActive': isActive,
    };
  }
}

class BusRoute {
  final int id;
  final String routeName;
  final double startLat;
  final double endLng;
  final String startingPointName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusRoute({
    required this.id,
    required this.routeName,
    required this.startLat,
    required this.endLng,
    required this.startingPointName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }

    return BusRoute(
      id: json['id'] ?? 0,
      routeName: json['routeName']?.toString() ?? '',
      startLat: (json['startLat'] as num?)?.toDouble() ?? 0.0,
      endLng: (json['endLng'] as num?)?.toDouble() ?? 0.0,
      startingPointName: json['startingPointName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
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
    };
  }
}
