class LoginResponse {
  final String message;
  final String accessToken;
  final String? refreshToken;
  final User user;

  LoginResponse({
    required this.message,
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final String id;
  final String userName;
  final String email;
  final String role;
  final int routeId;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    required this.routeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      role: json['role'],
      routeId: json['routeId'],
    );
  }
}
