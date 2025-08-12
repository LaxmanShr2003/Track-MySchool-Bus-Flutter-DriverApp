import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/auth/service/auth_service.dart';
import 'package:driver_app/models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/core/error_handler.dart';
import 'package:driver_app/core/post_login_initializer.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final LoginResponse? response;
  final bool isPostLoginInitialized;
  const LoginState({
    this.isLoading = false,
    this.error,
    this.response,
    this.isPostLoginInitialized = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    LoginResponse? response,
    bool? isPostLoginInitialized,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      response: response ?? this.response,
      isPostLoginInitialized:
          isPostLoginInitialized ?? this.isPostLoginInitialized,
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

      // Initialize post-login systems (trip check, chat, WebSocket)
      await _initializePostLoginSystems();
    } catch (e) {
      // Use centralized error handler for consistent error messages
      final errorMessage = ErrorHandler.handleError(e);
      print('Login error: $e'); // Debug print
      print('Error message: $errorMessage'); // Debug print
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Initialize systems that depend on successful login
  Future<void> _initializePostLoginSystems() async {
    try {
      print('🔄 LoginController: Initializing post-login systems...');

      // Use the PostLoginInitializer service
      final success = await PostLoginInitializer.instance.initialize();

      if (success) {
        state = state.copyWith(isPostLoginInitialized: true);
        print('✅ LoginController: Post-login systems initialized successfully');
      } else {
        print('⚠️ LoginController: Post-login systems initialization failed');
        // Don't fail the login, the user can still use the app
      }
    } catch (e) {
      print('❌ LoginController: Error initializing post-login systems - $e');
      // Don't fail the login, just log the error
      // The user can still use the app and retry later
    }
  }

  /// Check if post-login systems are initialized
  bool get isPostLoginInitialized => state.isPostLoginInitialized;

  /// Get the current trip info if available
  Map<String, dynamic>? get currentTripInfo =>
      PostLoginInitializer.instance.tripInfo;

  /// Check if chat is available
  bool get isChatAvailable => PostLoginInitializer.instance.isChatAvailable;
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
      return LoginController(AuthService());
    });
