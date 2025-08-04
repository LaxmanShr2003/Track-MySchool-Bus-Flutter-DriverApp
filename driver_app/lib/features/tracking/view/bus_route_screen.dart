import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:driver_app/features/tracking/controller/tracking_controller.dart';

class BusRouteScreen extends ConsumerStatefulWidget {
  const BusRouteScreen({super.key});

  @override
  ConsumerState<BusRouteScreen> createState() => _BusRouteScreenState();
}

class _BusRouteScreenState extends ConsumerState<BusRouteScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _showRouteInfo = false;
  bool _isMapReady = false;

  static const LatLng _defaultPosition = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled');
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        debugPrint(
          '✅ Location initialized: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing location: $e');
      if (mounted) {
        _showSnackBar('Error getting location: $e');
      }
    }
  }

  Future<void> _initializeTracking() async {
    try {
      final controller = ref.read(trackingControllerProvider.notifier);
      await controller.initializeTrackingWithNewFlow();
      await _updateRouteWithOSRM();
    } catch (e) {
      debugPrint('❌ Error initializing tracking: $e');
    }
  }

  Future<void> _updateRouteWithOSRM() async {
    final controller = ref.read(trackingControllerProvider.notifier);
    final routeDetails = controller.routeDetails;

    if (routeDetails != null) {
      final checkpoints = controller.sortedRouteDetailsCheckpoints;

      if (checkpoints.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingRoute = true;
          });
        }

        try {
          List<LatLng> waypoints = [
            LatLng(routeDetails.startLat, routeDetails.endLng), // Fixed: was using endLng for start
            ...checkpoints.map((cp) => LatLng(cp.lat, cp.lng)),
          ];

          final routePoints = await _getOSRMRoute(waypoints);
          if (mounted) {
            setState(() {
              _routePoints = routePoints;
              _isLoadingRoute = false;
            });
            
            // Auto-fit route to map after loading
            if (_isMapReady && routePoints.isNotEmpty) {
              _fitRouteToMap();
            }
          }
        } catch (e) {
          debugPrint('❌ Error updating route: $e');
          if (mounted) {
            setState(() {
              _isLoadingRoute = false;
            });
          }
        }
      }
    }
  }

  Future<List<LatLng>> _getOSRMRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    try {
      String coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

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
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
    }

    return waypoints;
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final controller = ref.read(trackingControllerProvider.notifier);
    final routeDetails = controller.routeDetails;

    // Current position marker
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
      // Start point marker
      markers.add(
        Marker(
          point: LatLng(routeDetails.startLat, routeDetails.endLng), // Fixed: was using endLng
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

      // Checkpoint markers
      final checkpoints = controller.sortedRouteDetailsCheckpoints;
      for (int i = 0; i < checkpoints.length; i++) {
        final checkpoint = checkpoints[i];
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
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];
    final controller = ref.read(trackingControllerProvider.notifier);
    final routeDetails = controller.routeDetails;

    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routePoints,
          color: const Color(0xFF3B82F6),
          strokeWidth: 4,
        ),
      );
    } else if (routeDetails != null) {
      final checkpoints = controller.sortedRouteDetailsCheckpoints;
      if (checkpoints.isNotEmpty) {
        final List<LatLng> polylinePoints = [
          LatLng(routeDetails.startLat, routeDetails.endLng), // Fixed: was using endLng
          ...checkpoints.map((cp) => LatLng(cp.lat, cp.lng)),
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

  void _centerOnCurrentLocation() {
    debugPrint('🗺️ Centering map on current location');
    if (_currentPosition != null && _isMapReady) {
      try {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        );
      } catch (e) {
        debugPrint('Error centering map: $e');
      }
    } else if (_currentPosition == null) {
      _initializeLocation();
    }
  }

  void _fitRouteToMap() {
    debugPrint('🗺️ Fitting map to show entire route');
    if (_routePoints.isNotEmpty && _isMapReady) {
      try {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        final cameraFit = CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        );
        _mapController.fitCamera(cameraFit);
      } catch (e) {
        debugPrint('Error fitting route to map: $e');
      }
    } else {
      // Fallback: fit based on markers if route points are empty
      final markers = _buildMarkers();
      if (markers.isNotEmpty && _isMapReady) {
        try {
          final points = markers.map((m) => m.point).toList();
          final bounds = LatLngBounds.fromPoints(points);
          final cameraFit = CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          );
          _mapController.fitCamera(cameraFit);
        } catch (e) {
          debugPrint('Error fitting markers to map: $e');
        }
      }
    }
  }

  Future<void> _startTracking() async {
    debugPrint('🔄 Starting GPS tracking');
    try {
      final controller = ref.read(trackingControllerProvider.notifier);
      await controller.startTracking();
      if (mounted) {
        _showSnackBar('GPS tracking started');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error starting tracking: $e');
      }
    }
  }

  Future<void> _stopTracking() async {
    debugPrint('🔄 Stopping GPS tracking');
    try {
      final controller = ref.read(trackingControllerProvider.notifier);
      await controller.stopTracking();
      if (mounted) {
        _showSnackBar('GPS tracking stopped');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error stopping tracking: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Refreshing data');
    try {
      await _initializeTracking();
      if (mounted) {
        _showSnackBar('Data refreshed');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error refreshing data: $e');
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingControllerProvider);
    final routeDetails = trackingState.routeDetails;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routeDetails != null
                  ? LatLng(routeDetails.startLat, routeDetails.endLng) // Fixed: was using endLng
                  : _defaultPosition,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Enable all interactions
              ),
              onMapReady: () {
                debugPrint('✅ Map is ready');
                setState(() {
                  _isMapReady = true;
                });
                // Delay the initial fit to ensure everything is loaded
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (_routePoints.isNotEmpty) {
                    _fitRouteToMap();
                  }
                });
              },
              onTap: (tapPosition, point) {
                debugPrint('🗺️ Map tapped at: ${point.latitude}, ${point.longitude}');
                // Hide route info when map is tapped
                if (_showRouteInfo) {
                  setState(() {
                    _showRouteInfo = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driver_app',
                maxZoom: 19,
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Status Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildStatusCard(trackingState),
          ),

          // Control Buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: _buildControlButtons(trackingState),
          ),

          // Route Info Toggle Button
          if (routeDetails != null && !_showRouteInfo)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'info_toggle',
                onPressed: () {
                  debugPrint('🗺️ Info button pressed');
                  setState(() {
                    _showRouteInfo = true;
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

          // Route Info Card
          if (routeDetails != null && _showRouteInfo)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 100,
              child: _buildRouteInfoCard(trackingState),
            ),

          // Loading Overlay
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
    );
  }

  Widget _buildStatusCard(TrackingState trackingState) {
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
                          color: trackingState.isTracking ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        trackingState.isWebSocketConnected
                            ? 'Server Connected'
                            : 'Server Disconnected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: trackingState.isWebSocketConnected
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(TrackingState trackingState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'tracking',
          onPressed: trackingState.isLoading
              ? null
              : () {
                  debugPrint('🗺️ Tracking button pressed');
                  if (trackingState.isTracking) {
                    _stopTracking();
                  } else {
                    _startTracking();
                  }
                },
          backgroundColor: trackingState.isTracking ? Colors.red : Colors.green,
          elevation: 8,
          child: trackingState.isLoading
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
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () {
            debugPrint('🗺️ Location button pressed');
            _centerOnCurrentLocation();
          },
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 8,
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fit_route',
          onPressed: () {
            debugPrint('🗺️ Fit route button pressed');
            _fitRouteToMap();
          },
          backgroundColor: Colors.purple,
          elevation: 8,
          child: const Icon(Icons.fit_screen, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: () {
            debugPrint('🗺️ Refresh button pressed');
            _refreshData();
          },
          backgroundColor: Colors.orange,
          elevation: 8,
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildRouteInfoCard(TrackingState trackingState) {
    final routeDetails = trackingState.routeDetails!;
    final controller = ref.read(trackingControllerProvider.notifier);
    final checkpoints = controller.sortedRouteDetailsCheckpoints;

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
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showRouteInfo = false;
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
                  'Checkpoints (${checkpoints.length}):',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...checkpoints.take(3).map(
                  (checkpoint) => Padding(
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
                      ],
                    ),
                  ),
                ),
            if (checkpoints.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Text(
                  '... and ${checkpoints.length - 3} more',
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