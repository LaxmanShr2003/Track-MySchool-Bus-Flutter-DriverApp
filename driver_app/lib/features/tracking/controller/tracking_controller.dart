import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/tracking/service/tracking_service.dart';
import 'package:driver_app/models/tracking_response.dart';
import 'package:driver_app/models/driver_response.dart';
import 'package:driver_app/models/route_details_response.dart' as route_details;
import 'package:driver_app/core/error_handler.dart';

class TrackingState {
  final bool isLoading;
  final String? error;
  final List<RouteData> routes;
  final RouteData? currentRoute;
  final bool isTracking;
  final bool isWebSocketConnected;
  final bool hasLoaded;
  final DriverMessage? driverInfo;
  final route_details.RouteDetailsData? routeDetails;

  const TrackingState({
    this.isLoading = false,
    this.error,
    this.routes = const [],
    this.currentRoute,
    this.isTracking = false,
    this.isWebSocketConnected = false,
    this.hasLoaded = false,
    this.driverInfo,
    this.routeDetails,
  });

  TrackingState copyWith({
    bool? isLoading,
    String? error,
    List<RouteData>? routes,
    RouteData? currentRoute,
    bool? isTracking,
    bool? isWebSocketConnected,
    bool? hasLoaded,
    DriverMessage? driverInfo,
    route_details.RouteDetailsData? routeDetails,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      routes: routes ?? this.routes,
      currentRoute: currentRoute ?? this.currentRoute,
      isTracking: isTracking ?? this.isTracking,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      driverInfo: driverInfo ?? this.driverInfo,
      routeDetails: routeDetails ?? this.routeDetails,
    );
  }
}

class TrackingController extends StateNotifier<TrackingState> {
  final TrackingService _service;

  TrackingController(this._service) : super(const TrackingState());

  /// Fetches driver by driver ID
  Future<void> fetchDriverByDriverId(String driverId) async {
    print('🔄 TrackingController: Fetching driver by ID: $driverId');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.fetchDriverByDriverId(driverId);
      print('✅ TrackingController: Driver fetched successfully');
      print(
        '👤 Driver: ${response.message.firstName} ${response.message.lastName}',
      );

      state = state.copyWith(
        isLoading: false,
        driverInfo: response.message,
        error: null,
      );
    } catch (e) {
      print('❌ TrackingController: Error fetching driver - $e');

      final errorMessage = ErrorHandler.handleError(e);
      print('❌ TrackingController: Error message - $errorMessage');

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Fetches route details by route ID
  Future<void> fetchRouteDetailsByRouteId(int routeId) async {
    print(
      '🔄 TrackingController: Fetching route details for route ID: $routeId',
    );

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.fetchRouteDetailsByRouteId(routeId);
      print('✅ TrackingController: Route details fetched successfully');
      print('📍 Route: ${response.data.routeName}');

      state = state.copyWith(
        isLoading: false,
        routeDetails: response.data,
        error: null,
      );
    } catch (e) {
      print('❌ TrackingController: Error fetching route details - $e');

      final errorMessage = ErrorHandler.handleError(e);
      print('❌ TrackingController: Error message - $errorMessage');

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Gets route ID for current driver
  Future<int?> getRouteIdForCurrentDriver() async {
    print('🔄 TrackingController: Getting route ID for current driver');

    try {
      final routeId = await _service.getRouteIdForCurrentDriver();

      if (routeId != null) {
        print('✅ TrackingController: Route ID found: $routeId');
      } else {
        print('⚠️ TrackingController: No route ID found for current driver');
      }

      return routeId;
    } catch (e) {
      print('❌ TrackingController: Error getting route ID - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
      return null;
    }
  }

  /// Fetches all routes from the backend
  Future<void> fetchRoutes() async {
    print('🔄 TrackingController: Starting to fetch routes');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.fetchRoutes();
      print('✅ TrackingController: Routes fetched successfully');
      print('📊 TrackingController: Found ${response.data.length} routes');

      state = state.copyWith(
        isLoading: false,
        routes: response.data,
        hasLoaded: true,
      );
    } catch (e) {
      print('❌ TrackingController: Error fetching routes - $e');

      final errorMessage = ErrorHandler.handleError(e);
      print('❌ TrackingController: Error message - $errorMessage');

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        hasLoaded: false,
      );
    }
  }

  /// Gets the current route for the driver
  Future<void> getCurrentRoute() async {
    print('🔄 TrackingController: Getting current route');

    try {
      final currentRoute = await _service.getCurrentRoute();
      print('✅ TrackingController: Current route retrieved');

      if (currentRoute != null) {
        print(
          '📍 TrackingController: Current route - ${currentRoute.routeName}',
        );
        state = state.copyWith(currentRoute: currentRoute);
      } else {
        print('⚠️ TrackingController: No current route found');
        state = state.copyWith(currentRoute: null);
      }
    } catch (e) {
      print('❌ TrackingController: Error getting current route - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
    }
  }

  /// Starts GPS tracking
  Future<void> startTracking() async {
    print('🔄 TrackingController: Starting GPS tracking');

    if (state.isTracking) {
      print('⚠️ TrackingController: Tracking already started');
      return;
    }

    try {
      final success = await _service.startTracking();

      if (success) {
        print('✅ TrackingController: GPS tracking started successfully');
        state = state.copyWith(
          isTracking: true,
          isWebSocketConnected: _service.isWebSocketConnected,
          error: null,
        );
      } else {
        print('❌ TrackingController: Failed to start tracking');
        state = state.copyWith(error: 'Failed to start GPS tracking');
      }
    } catch (e) {
      print('❌ TrackingController: Error starting tracking - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
    }
  }

  /// Stops GPS tracking
  Future<void> stopTracking() async {
    print('🔄 TrackingController: Stopping GPS tracking');

    try {
      await _service.stopTracking();
      print('✅ TrackingController: GPS tracking stopped successfully');

      state = state.copyWith(
        isTracking: false,
        isWebSocketConnected: false,
        error: null,
      );
    } catch (e) {
      print('❌ TrackingController: Error stopping tracking - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
    }
  }

  /// Initializes tracking with new flow (fetch driver, get route ID, fetch route details)
  Future<void> initializeTrackingWithNewFlow() async {
    print('🔄 TrackingController: Initializing tracking with new flow');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user ID
      final userId = await _service.getCurrentUserId();
      if (userId == null) {
        throw ErrorHandler.createApiException(
          'User ID not found. Please login again.',
        );
      }

      // Step 1: Fetch driver by driver ID
      await fetchDriverByDriverId(userId);

      // Step 2: Get route ID for current driver
      final routeId = await getRouteIdForCurrentDriver();
      if (routeId == null) {
        throw ErrorHandler.createApiException(
          'No active route found for driver',
        );
      }

      // Step 3: Fetch route details by route ID
      await fetchRouteDetailsByRouteId(routeId);

      print(
        '✅ TrackingController: Tracking initialized successfully with new flow',
      );
    } catch (e) {
      print(
        '❌ TrackingController: Error initializing tracking with new flow - $e',
      );
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Initializes tracking (fetches routes and gets current route)
  Future<void> initializeTracking() async {
    print('🔄 TrackingController: Initializing tracking');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch all routes
      await fetchRoutes();

      // Get current route for the driver
      await getCurrentRoute();

      print('✅ TrackingController: Tracking initialized successfully');
    } catch (e) {
      print('❌ TrackingController: Error initializing tracking - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Refreshes tracking data
  Future<void> refreshTracking() async {
    print('🔄 TrackingController: Refreshing tracking data');
    await initializeTracking();
  }

  /// Clears tracking data and error
  void clearTracking() {
    print('🔄 TrackingController: Clearing tracking data');
    state = const TrackingState();
  }

  /// Gets routes assigned to current driver
  List<RouteData> getDriverRoutes() {
    // Since fetchRoutes now filters for current driver,
    // all routes in state.routes are already assigned to the driver
    return state.routes;
  }

  /// Gets all checkpoints for current route
  List<Checkpoint> getCurrentRouteCheckpoints() {
    return state.currentRoute?.checkpoints ?? [];
  }

  /// Gets sorted checkpoints (by order)
  List<Checkpoint> getSortedCheckpoints() {
    final checkpoints = getCurrentRouteCheckpoints();
    checkpoints.sort((a, b) => a.order.compareTo(b.order));
    return checkpoints;
  }

  /// Checks if driver has an active route
  bool get hasActiveRoute => state.currentRoute != null;

  /// Gets current route name
  String get currentRouteName => state.currentRoute?.routeName ?? 'No Route';

  /// Gets current route ID
  int? get currentRouteId => state.currentRoute?.id;

  /// Gets tracking status
  bool get isTracking => state.isTracking;

  /// Gets WebSocket connection status
  bool get isWebSocketConnected => state.isWebSocketConnected;

  /// Gets loading status
  bool get isLoading => state.isLoading;

  /// Gets error message
  String? get error => state.error;

  /// Gets all routes
  List<RouteData> get routes => state.routes;

  /// Gets current route
  RouteData? get currentRoute => state.currentRoute;

  /// Gets has loaded status
  bool get hasLoaded => state.hasLoaded;

  /// Gets driver info
  DriverMessage? get driverInfo => state.driverInfo;

  /// Gets route details
  route_details.RouteDetailsData? get routeDetails => state.routeDetails;

  /// Gets checkpoints from route details
  List<route_details.Checkpoint> get routeDetailsCheckpoints {
    return state.routeDetails?.checkpoints ?? [];
  }

  /// Gets sorted checkpoints from route details (by order)
  List<route_details.Checkpoint> get sortedRouteDetailsCheckpoints {
    final checkpoints = routeDetailsCheckpoints;
    checkpoints.sort((a, b) => a.order.compareTo(b.order));
    return checkpoints;
  }

  /// Gets route assignments from route details
  List<route_details.RouteAssignmentDetails> get routeDetailsAssignments {
    return state.routeDetails?.routeAssignment ?? [];
  }

  /// Gets active route assignment from route details
  route_details.RouteAssignmentDetails? get activeRouteDetailsAssignment {
    return routeDetailsAssignments
        .where((assignment) => assignment.assignmentStatus == 'ACTIVE')
        .firstOrNull;
  }

  /// Gets students from active route assignment
  List<String> get studentsFromActiveAssignment {
    return activeRouteDetailsAssignment?.students ?? [];
  }
}

// Provider for TrackingService
final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService();
});

// Provider for TrackingController
final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
      final service = ref.watch(trackingServiceProvider);
      return TrackingController(service);
    });
