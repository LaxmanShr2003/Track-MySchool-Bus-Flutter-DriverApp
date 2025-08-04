// profile_response.dart
class ProfileResponse {
  final bool success;
  final ProfileUser message;
  final String? error;

  ProfileResponse({required this.success, required this.message, this.error});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
      message: ProfileUser.fromJson(json['message'] ?? json['data'] ?? json),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message.toJson(), 'error': error};
  }
}

class ProfileUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String userName;
  final String role;
  final String address;
  final String? licenseNumber;
  final String? profileImageUrl;
  final String? gender;
  final String? password;
  final bool isActive;
  final bool isAssigned;
  final List<RouteAssignment> routeAssignment;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.userName,
    required this.role,
    required this.address,
    this.licenseNumber,
    this.profileImageUrl,
    this.gender,
    this.password,
    required this.isActive,
    required this.isAssigned,
    required this.routeAssignment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    // Safely parse createdAt and updatedAt
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ProfileUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Driver',
      address: json['address']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      gender: json['gender']?.toString(),
      password: json['password']?.toString(),
      isActive: json['isActive'] == true,
      isAssigned: json['isAssigned'] == true,
      routeAssignment:
          (json['routeAssignment'] as List<dynamic>?)
              ?.map((e) => RouteAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updateAt'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'userName': userName,
      'role': role,
      'address': address,
      'licenseNumber': licenseNumber,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'password': password,
      'isActive': isActive,
      'isAssigned': isAssigned,
      'routeAssignment': routeAssignment.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RouteAssignment {
  final String id;
  final String busId;
  final String driverId;
  final String? studentId;
  final String? assignmentStatus;
  final String? assignedDate;
  final String? endDate;
  final String? busRouteId;
  final Bus? bus;
  final BusRoute? busRoute;

  RouteAssignment({
    required this.id,
    required this.busId,
    required this.driverId,
    this.studentId,
    this.assignmentStatus,
    this.assignedDate,
    this.endDate,
    this.busRouteId,
    this.bus,
    this.busRoute,
  });

  factory RouteAssignment.fromJson(Map<String, dynamic> json) {
    return RouteAssignment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      busId: json['busId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      assignmentStatus: json['assignmentStatus']?.toString() ?? 'Pending',
      assignedDate: json['assignedDate']?.toString(),
      endDate: json['endDate']?.toString(),
      busRouteId: json['busRouteId']?.toString(),
      bus:
          json['bus'] != null
              ? Bus.fromJson(json['bus'] as Map<String, dynamic>)
              : null,
      busRoute:
          json['busRoute'] != null
              ? BusRoute.fromJson(json['busRoute'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'busId': busId,
      'driverId': driverId,
      'studentId': studentId,
      'assignmentStatus': assignmentStatus,
      'assignedDate': assignedDate,
      'endDate': endDate,
      'busRouteId': busRouteId,
      'bus': bus?.toJson(),
      'busRoute': busRoute?.toJson(),
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
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      busName: json['busName']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      isAssigned: json['isAssigned'] == true,
      isActive: json['isActive'] == true,
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
  final String id;
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
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
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
