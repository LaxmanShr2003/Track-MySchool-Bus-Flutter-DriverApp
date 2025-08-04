import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/auth/service/auth_service.dart';
import 'package:driver_app/models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/core/error_handler.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final LoginResponse? response;
  const LoginState({this.isLoading = false, this.error, this.response});

  LoginState copyWith({
    bool? isLoading,
    String? error,
    LoginResponse? response,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  LoginController(this._authService) : super(const LoginState());

  /// Attempts to log in and saves tokens securely if successful.
  /// Uses centralized error handling for consistent error messages.
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Call the AuthService to perform login
      final response = await _authService.login(
        username: username,
        password: password,
      );
      // Save accessToken and userId securely
      await _secureStorage.write(
        key: 'accessToken',
        value: response.accessToken,
      );
      await _secureStorage.write(key: 'userId', value: response.user.id);
      // Update state with the successful response
      state = state.copyWith(isLoading: false, response: response);
    } catch (e) {
      // Use centralized error handler for consistent error messages
      final errorMessage = ErrorHandler.handleError(e);
      print('Login error: $e'); // Debug print
      print('Error message: $errorMessage'); // Debug print
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
      return LoginController(AuthService());
    });
