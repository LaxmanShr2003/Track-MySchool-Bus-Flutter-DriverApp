import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
    } catch (e) {
      print('❌ Error initializing location: $e');
      _showSnackBar('Error getting location: $e');
    }
  }

  /// Initialize tracking with new flow
  Future<void> _initializeTrackingWithNewFlow() async {
    final trackingController = ref.read(trackingControllerProvider.notifier);
    await trackingController.initializeTrackingWithNewFlow();
  }

  /// Start GPS tracking
  Future<void> _startTracking() async {
    try {
      final trackingController = ref.read(trackingControllerProvider.notifier);
      await trackingController.startTracking();
      _showSnackBar('GPS tracking started');
    } catch (e) {
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
      _showSnackBar('Data refreshed');
    } catch (e) {
      _showSnackBar('Error refreshing data: $e');
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
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
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
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
                  color: Colors.black.withValues(alpha: 0.3),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
        );
      }
    }

    return markers;
  }

  /// Build polylines for the route
  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];
    final trackingController = ref.read(trackingControllerProvider.notifier);
    final routeDetails = trackingController.routeDetails;

    if (routeDetails != null) {
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
                onMapReady: () {
                  print('✅ Map is ready');
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
                PolylineLayer(polylines: _buildPolylines()),
                // Markers
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),

            // Status overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildStatusCard(trackingState),
            ),

            // Control buttons
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildControlButtons(trackingState),
            ),

            // Route info card
            if (routeDetails != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 100,
                child: _buildRouteInfoCard(trackingState),
              ),

            // Loading overlay
            if (trackingState.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.9),
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
                  Icon(Icons.route, color: const Color(0xFF3B82F6), size: 16),
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
                  Icon(
                    Icons.location_on,
                    color: const Color(0xFF3B82F6),
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
        FloatingActionButton(
          heroTag: 'tracking',
          onPressed: trackingState.isTracking ? _stopTracking : _startTracking,
          backgroundColor: trackingState.isTracking ? Colors.red : Colors.green,
          elevation: 8,
          child: Icon(
            trackingState.isTracking ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: _initializeLocation,
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 8,
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: _refreshData,
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
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.9),
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
                Text(
                  'Route Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                Icon(Icons.location_on, color: Colors.orange, size: 16),
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
            ...sortedCheckpoints
                .take(3)
                .map(
                  (checkpoint) => Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
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
                      ],
                    ),
                  ),
                ),
            if (sortedCheckpoints.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Text(
                  '... and ${sortedCheckpoints.length - 3} more',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
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
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
