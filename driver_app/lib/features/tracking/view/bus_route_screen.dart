import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:driver_app/features/tracking/controller/tracking_controller.dart';
import 'package:driver_app/widgets/loading_overlay.dart';
import 'package:driver_app/widgets/status_card.dart';
import 'package:driver_app/widgets/control_buttons.dart';
import 'package:driver_app/widgets/route_info_card.dart';
import 'package:driver_app/widgets/bus_route_map.dart';

class BusRouteScreen extends ConsumerStatefulWidget {
  const BusRouteScreen({super.key});

  @override
  ConsumerState<BusRouteScreen> createState() => _BusRouteScreenState();
}

class _BusRouteScreenState extends ConsumerState<BusRouteScreen> {
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _showRouteInfo = false;
  bool _isMapReady = false;
  final MapController _mapController = MapController(); // ✅ Added MapController

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
    _mapController.dispose(); // ✅ Dispose controller
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
            LatLng(
              routeDetails.startLat,
              routeDetails.endLng, // Using available coordinate from API
            ),
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

  void _centerOnCurrentLocation() {
    debugPrint('🗺️ Centering map on current location');
    if (_currentPosition != null && _isMapReady) {
      try {
        // ✅ Add safety check and delay to ensure map is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isMapReady) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            );
          }
        });
      } catch (e) {
        debugPrint('Error centering map: $e');
      }
    } else {
      _initializeLocation();
    }
  }

  void _fitRouteToMap() {
    debugPrint('🗺️ Fitting map to show entire route');
    if (_routePoints.isNotEmpty && _isMapReady) {
      try {
        // ✅ Add safety check and delay to ensure map is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isMapReady && _routePoints.isNotEmpty) {
            // Calculate bounds and fit to map
            double minLat = _routePoints.first.latitude;
            double maxLat = _routePoints.first.latitude;
            double minLng = _routePoints.first.longitude;
            double maxLng = _routePoints.first.longitude;

            for (final point in _routePoints) {
              minLat = minLat < point.latitude ? minLat : point.latitude;
              maxLat = maxLat > point.latitude ? maxLat : point.latitude;
              minLng = minLng < point.longitude ? minLng : point.longitude;
              maxLng = maxLng > point.longitude ? maxLng : point.longitude;
            }

            final bounds = LatLngBounds(
              LatLng(minLat, minLng),
              LatLng(maxLat, maxLng),
            );

            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        });
      } catch (e) {
        debugPrint('Error fitting route to map: $e');
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
    final controller = ref.read(trackingControllerProvider.notifier);
    final checkpoints = controller.sortedRouteDetailsCheckpoints;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Map - ✅ Make sure it's at the bottom of the stack
          Positioned.fill(
            child: BusRouteMap(
              routeDetails: routeDetails,
              checkpoints: checkpoints,
              routePoints: _routePoints,
              currentPosition: _currentPosition,
              isMapReady: _isMapReady,
              mapController: _mapController, // ✅ Pass the controller
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
              onMapTap: () {
                if (_showRouteInfo) {
                  setState(() {
                    _showRouteInfo = false;
                  });
                }
              },
            ),
          ),

          // Status Card - ✅ Ensure proper positioning
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: StatusCard(
              isTracking: trackingState.isTracking,
              isWebSocketConnected: trackingState.isWebSocketConnected,
              routeDetails: routeDetails,
            ),
          ),

          // Control Buttons - ✅ Ensure they're clickable
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: ControlButtons(
              isLoading: trackingState.isLoading,
              isTracking: trackingState.isTracking,
              onTrackingToggle: () {
                debugPrint('🔘 Tracking button pressed'); // ✅ Debug print
                if (trackingState.isTracking) {
                  _stopTracking();
                } else {
                  _startTracking();
                }
              },
              onLocationCenter: () {
                debugPrint('🔘 Location button pressed'); // ✅ Debug print
                _centerOnCurrentLocation();
              },
              onFitRoute: () {
                debugPrint('🔘 Fit route button pressed'); // ✅ Debug print
                _fitRouteToMap();
              },
              onRefresh: () {
                debugPrint('🔘 Refresh button pressed'); // ✅ Debug print
                _refreshData();
              },
            ),
          ),

          // Route Info Toggle Button
          if (routeDetails != null && !_showRouteInfo)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'info_toggle',
                onPressed: () {
                  debugPrint('🔘 Info button pressed'); // ✅ Debug print
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
              child: RouteInfoCard(
                routeDetails: routeDetails,
                checkpoints: checkpoints,
                onClose: () {
                  setState(() {
                    _showRouteInfo = false;
                  });
                },
              ),
            ),

          // Loading Overlay - ✅ Make sure it doesn't block buttons when not loading
          if (trackingState.isLoading || _isLoadingRoute)
            LoadingOverlay(
              isLoading: trackingState.isLoading || _isLoadingRoute,
              loadingText: _isLoadingRoute ? 'Loading route...' : 'Loading...',
            ),
        ],
      ),
    );
  }
}
