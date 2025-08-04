import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:driver_app/features/tracking/controller/tracking_controller.dart';
import 'package:driver_app/models/tracking_response.dart';

class BusRouteScreen extends ConsumerStatefulWidget {
  const BusRouteScreen({super.key});

  @override
  ConsumerState<BusRouteScreen> createState() => _BusRouteScreenState();
}

class _BusRouteScreenState extends ConsumerState<BusRouteScreen> {
  MapController? _mapController;
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _isInfoCardExpanded = false;
  List<Marker> _cachedMarkers = [];
  List<Polyline> _cachedPolylines = [];
  bool _mapInitialized = false;

  // Default camera position (Kathmandu, Nepal)
  static const LatLng _defaultPosition = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();

    // Delay provider state modification until after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTrackingWithNewFlow();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Get route from OSRM API
  Future<List<LatLng>> _getOSRMRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    try {
      setState(() {
        _isLoadingRoute = true;
      });

      // Create coordinates string for OSRM
      String coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      // OSRM API endpoint
      final url =
          'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            return coordinates
                .map(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                )
                .toList();
          }
        }
      } else {
        print('OSRM API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching OSRM route: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }

    // Return original waypoints if OSRM fails
    return waypoints;
  }

  /// Update route with OSRM data
  Future<void> _updateRouteWithOSRM() async {
    final trackingController = ref.read(trackingControllerProvider.notifier);
    final routeDetails = trackingController.routeDetails;

    if (routeDetails != null) {
      final sortedCheckpoints =
          trackingController.sortedRouteDetailsCheckpoints;

      if (sortedCheckpoints.isNotEmpty) {
        List<LatLng> waypoints = [
          LatLng(routeDetails.startLat, routeDetails.endLng),
          ...sortedCheckpoints.map((cp) => LatLng(cp.lat, cp.lng)),
        ];

        final routePoints = await _getOSRMRoute(waypoints);
        if (mounted) {
          setState(() {
            _routePoints = routePoints;
          });
        }
      }
    }
  }

  /// Build and cache map elements (markers and polylines)
  void _buildAndCacheMapElements() {
    if (!mounted) return;

    print('🗺️ Building and caching map elements');

    // Build markers
    _cachedMarkers = _buildMarkers();
    print('🗺️ Cached ${_cachedMarkers.length} markers');

    // Build polylines
    _cachedPolylines = _buildPolylines();
    print('🗺️ Cached ${_cachedPolylines.length} polylines');

    setState(() {
      _mapInitialized = true;
    });

    // Fit map to show all elements after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _mapController != null) {
        _fitRouteToMap();
      }
    });
  }

  /// Initialize location services
  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Move camera to current position
        if (_mapController != null) {
          _mapController!.move(
            LatLng(position.latitude, position.longitude),
            15.0,
          );
        }

        print(
          '✅ Location initialized: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      print('❌ Error initializing location: $e');
      if (mounted) {
        _showSnackBar('Error getting location: $e');
      }
    }
  }

  /// Initialize tracking with new flow
  Future<void> _initializeTrackingWithNewFlow() async {
    final trackingController = ref.read(trackingControllerProvider.notifier);
    await trackingController.initializeTrackingWithNewFlow();

    // Update route after initialization
    await _updateRouteWithOSRM();

    // Build and cache markers and polylines
    _buildAndCacheMapElements();
  }

  /// Start GPS tracking
  Future<void> _startTracking() async {
    print('🔄 Starting GPS tracking');
    try {
      final trackingController = ref.read(trackingControllerProvider.notifier);
      await trackingController.startTracking();
      print('✅ GPS tracking started successfully');
      _showSnackBar('GPS tracking started');
    } catch (e) {
      print('❌ Error starting tracking: $e');
      _showSnackBar('Error starting tracking: $e');
    }
  }

  /// Stop GPS tracking
  Future<void> _stopTracking() async {
    try {
      final trackingController = ref.read(trackingControllerProvider.notifier);
      await trackingController.stopTracking();
      _showSnackBar('GPS tracking stopped');
    } catch (e) {
      _showSnackBar('Error stopping tracking: $e');
    }
  }

  /// Refresh tracking data
  Future<void> _refreshData() async {
    try {
      final trackingController = ref.read(trackingControllerProvider.notifier);
      await trackingController.initializeTrackingWithNewFlow();
      await _updateRouteWithOSRM();
      _buildAndCacheMapElements();
      _showSnackBar('Data refreshed');
    } catch (e) {
      _showSnackBar('Error refreshing data: $e');
    }
  }

  /// Center map on current location
  void _centerOnCurrentLocation() {
    print('🗺️ Centering map on current location');
    if (_currentPosition != null && _mapController != null) {
      _mapController!.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
      print(
        '✅ Map centered on: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
    } else {
      print('🔄 No current position, initializing location');
      _initializeLocation();
    }
  }

  /// Fit map to show entire route
  void _fitRouteToMap() {
    print('🗺️ Fitting map to show entire route');
    if (_routePoints.isNotEmpty && _mapController != null) {
      final bounds = LatLngBounds.fromPoints(_routePoints);
      final cameraFit = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      );
      _mapController!.fitCamera(cameraFit);
      print('✅ Map fitted to route with ${_routePoints.length} points');
    } else if (_cachedMarkers.isNotEmpty && _mapController != null) {
      // Fallback: fit to markers if no route points
      final points = _cachedMarkers.map((m) => m.point).toList();
      final bounds = LatLngBounds.fromPoints(points);
      final cameraFit = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      );
      _mapController!.fitCamera(cameraFit);
      print('✅ Map fitted to markers with ${points.length} points');
    } else {
      print('⚠️ No route points or markers available for fitting');
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Build markers for the map
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final trackingController = ref.read(trackingControllerProvider.notifier);
    final routeDetails = trackingController.routeDetails;

    // Add current position marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (routeDetails != null) {
      // Add route start point marker
      markers.add(
        Marker(
          point: LatLng(routeDetails.startLat, routeDetails.endLng),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 24),
          ),
        ),
      );

      // Add checkpoint markers
      final sortedCheckpoints =
          trackingController.sortedRouteDetailsCheckpoints;
      for (int i = 0; i < sortedCheckpoints.length; i++) {
        final checkpoint = sortedCheckpoints[i];
        markers.add(
          Marker(
            point: LatLng(checkpoint.lat, checkpoint.lng),
            width: 45,
            height: 45,
            child: GestureDetector(
              onTap: () {
                _showCheckpointDialog(checkpoint);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${checkpoint.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  /// Show checkpoint details dialog
  void _showCheckpointDialog(dynamic checkpoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${checkpoint.order}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Checkpoint ${checkpoint.order}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('Location', checkpoint.label),
              _buildDialogInfoRow(
                'Coordinates',
                '${checkpoint.lat.toStringAsFixed(6)}, ${checkpoint.lng.toStringAsFixed(6)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _mapController?.move(
                  LatLng(checkpoint.lat, checkpoint.lng),
                  16.0,
                );
              },
              child: Text(
                'Center on Map',
                style: GoogleFonts.poppins(color: const Color(0xFF3B82F6)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build info row for dialog
  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  /// Build polylines for the route
  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];
    final trackingController = ref.read(trackingControllerProvider.notifier);
    final routeDetails = trackingController.routeDetails;

    // Use OSRM route points if available, otherwise use controller data
    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routePoints,
          color: const Color(0xFF3B82F6),
          strokeWidth: 4,
        ),
      );
    } else if (routeDetails != null) {
      // Fallback: create simple route from controller data
      final sortedCheckpoints =
          trackingController.sortedRouteDetailsCheckpoints;
      if (sortedCheckpoints.isNotEmpty) {
        final List<LatLng> polylinePoints = [
          LatLng(routeDetails.startLat, routeDetails.endLng), // Start point
          ...sortedCheckpoints.map(
            (cp) => LatLng(cp.lat, cp.lng),
          ), // Checkpoints
        ];

        polylines.add(
          Polyline(
            points: polylinePoints,
            color: const Color(0xFF3B82F6),
            strokeWidth: 4,
          ),
        );
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);
    final routeDetails = trackingState.routeDetails;

    // Update route points when controller data changes
    if (routeDetails != null && _routePoints.isEmpty && !_isLoadingRoute) {
      print('🗺️ Route details updated, updating route points');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateRouteWithOSRM();
        _buildAndCacheMapElements();
      });
    }

    // Build and cache map elements if not done yet
    if (routeDetails != null && !_mapInitialized && !trackingState.isLoading) {
      print('🗺️ Initializing map elements');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildAndCacheMapElements();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // OSM Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    routeDetails != null
                        ? LatLng(routeDetails.startLat, routeDetails.endLng)
                        : _defaultPosition,
                initialZoom: 13.0,
                minZoom: 10.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableScrollWheel: true,
                  enableMultiFingerGestureRace: true,
                ),
                onMapReady: () {
                  print('✅ Map is ready');
                  // Delay fit to route to ensure map is properly initialized
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _fitRouteToMap();
                  });
                },
                onTap: (tapPosition, point) {
                  print(
                    '🗺️ Map tapped at: ${point.latitude}, ${point.longitude}',
                  );
                },
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.driver_app',
                  maxZoom: 19,
                ),
                // Route polylines
                PolylineLayer(polylines: _cachedPolylines),
                // Markers
                MarkerLayer(markers: _cachedMarkers),
              ],
            ),

            // Status overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: IgnorePointer(child: _buildStatusCard(trackingState)),
              ),
            ),

            // Control buttons
            Positioned(
              bottom: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: _buildControlButtons(trackingState),
              ),
            ),

            // Route info toggle button (only show when route details are available)
            if (routeDetails != null && !_isInfoCardExpanded)
              Positioned(
                bottom: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: FloatingActionButton(
                    heroTag: 'info_toggle',
                    onPressed: () {
                      print('🗺️ Info button pressed');
                      setState(() {
                        _isInfoCardExpanded = true;
                      });
                    },
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 8,
                    mini: true,
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // Route info card (only show when expanded or when there's an error)
            if (routeDetails != null &&
                (_isInfoCardExpanded || trackingState.error != null))
              Positioned(
                bottom: 16,
                left: 16,
                right: 100,
                child: _buildRouteInfoCard(trackingState),
              ),

            // Loading overlay
            if (trackingState.isLoading || _isLoadingRoute)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isLoadingRoute ? 'Loading route...' : 'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build status card
  Widget _buildStatusCard(TrackingState trackingState) {
    final trackingController = ref.read(trackingControllerProvider.notifier);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: trackingState.isTracking ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trackingState.isTracking ? Icons.gps_fixed : Icons.gps_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackingState.isTracking
                            ? 'GPS Tracking Active'
                            : 'GPS Tracking Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              trackingState.isTracking
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      Text(
                        trackingState.isWebSocketConnected
                            ? 'Server Connected'
                            : 'Server Disconnected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              trackingState.isWebSocketConnected
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (trackingState.routeDetails != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.route, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route: ${trackingState.routeDetails!.routeName}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Checkpoints: ${trackingController.routeDetailsCheckpoints.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build control buttons
  Widget _buildControlButtons(TrackingState trackingState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start/Stop tracking button
        FloatingActionButton(
          heroTag: 'tracking',
          onPressed:
              trackingState.isLoading
                  ? null
                  : () {
                    print('🗺️ Tracking button pressed');
                    if (trackingState.isTracking) {
                      _stopTracking();
                    } else {
                      _startTracking();
                    }
                  },
          backgroundColor: trackingState.isTracking ? Colors.red : Colors.green,
          elevation: 8,
          child:
              trackingState.isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(
                    trackingState.isTracking ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
        ),
        const SizedBox(height: 12),

        // Current location button
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () {
            print('🗺️ Location button pressed');
            _centerOnCurrentLocation();
          },
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 8,
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),

        // Fit route button
        FloatingActionButton(
          heroTag: 'fit_route',
          onPressed: () {
            print('🗺️ Fit route button pressed');
            _fitRouteToMap();
          },
          backgroundColor: Colors.purple,
          elevation: 8,
          child: const Icon(Icons.fit_screen, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),

        // Refresh button
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: () {
            print('🗺️ Refresh button pressed');
            _refreshData();
          },
          backgroundColor: Colors.orange,
          elevation: 8,
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  /// Build route info card
  Widget _buildRouteInfoCard(TrackingState trackingState) {
    final trackingController = ref.read(trackingControllerProvider.notifier);
    final routeDetails = trackingController.routeDetails!;
    final sortedCheckpoints = trackingController.sortedRouteDetailsCheckpoints;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Route Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isInfoCardExpanded = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', routeDetails.routeName),
            _buildInfoRow('Start Point', routeDetails.startingPointName),
            _buildInfoRow('Status', routeDetails.status),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Checkpoints (${sortedCheckpoints.length}):',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Show checkpoints based on expansion state
            ...sortedCheckpoints
                .take(_isInfoCardExpanded ? sortedCheckpoints.length : 3)
                .map(
                  (checkpoint) => GestureDetector(
                    onTap: () => _showCheckpointDialog(checkpoint),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${checkpoint.order}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              checkpoint.label,
                              style: GoogleFonts.poppins(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            if (sortedCheckpoints.length > 3 && !_isInfoCardExpanded)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isInfoCardExpanded = true;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Row(
                    children: [
                      Text(
                        '... and ${sortedCheckpoints.length - 3} more',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF3B82F6),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
