import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/profile/service/profile_service.dart';
import 'package:driver_app/models/profile_response.dart';
import 'package:driver_app/core/error_handler.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final ProfileUser? user;
  final bool hasLoaded;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.user,
    this.hasLoaded = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    ProfileUser? user,
    bool? hasLoaded,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileService _service;

  ProfileController(this._service) : super(const ProfileState());

  /// Fetches the profile and updates state accordingly
  Future<void> fetchProfile() async {
    print('ProfileController: Starting to fetch profile'); // Debug log

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _service.fetchProfile();
      print('ProfileController: Profile fetched successfully'); // Debug log
      print(
        'ProfileController: User data - ${user.firstName} ${user.lastName}',
      ); // Debug log

      state = state.copyWith(isLoading: false, user: user, hasLoaded: true);
    } catch (e) {
      print('ProfileController: Error fetching profile - $e'); // Debug log

      // Use centralized error handler for consistent error messages
      final errorMessage = ErrorHandler.handleError(e);
      print('ProfileController: Error message - $errorMessage'); // Debug log

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        hasLoaded: false,
      );
    }
  }

  /// Refreshes the profile data
  Future<void> refreshProfile() async {
    print('ProfileController: Refreshing profile'); // Debug log
    await fetchProfile();
  }

  /// Clears the profile data and error
  void clearProfile() {
    print('ProfileController: Clearing profile data'); // Debug log
    state = const ProfileState();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ProfileService());
    });
