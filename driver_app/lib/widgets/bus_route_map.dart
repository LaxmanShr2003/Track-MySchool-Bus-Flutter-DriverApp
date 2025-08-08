import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/models/route_details_response.dart';

class BusRouteMap extends StatefulWidget {
  final RouteDetailsData? routeDetails;
  final List<Checkpoint> checkpoints;
  final List<LatLng> routePoints;
  final Position? currentPosition;
  final bool isMapReady;
  final VoidCallback onMapReady;
  final VoidCallback onMapTap;
  final MapController? mapController; // ✅ Added optional MapController

  const BusRouteMap({
    super.key,
    required this.routeDetails,
    required this.checkpoints,
    required this.routePoints,
    required this.currentPosition,
    required this.isMapReady,
    required this.onMapReady,
    required this.onMapTap,
    this.mapController, // ✅ Optional parameter
  });

  @override
  State<BusRouteMap> createState() => _BusRouteMapState();
}

class _BusRouteMapState extends State<BusRouteMap> {
  late final MapController _mapController;
  static const LatLng _defaultPosition = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    // ✅ Use provided controller or create new one
    _mapController = widget.mapController ?? MapController();
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // Current position marker
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
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

    if (widget.routeDetails != null) {
      // Start point marker - FIXED: Based on your API response structure
      markers.add(
        Marker(
          point: LatLng(
            widget.routeDetails!.startLat,
            widget
                .routeDetails!
                .endLng, // Using endLng as it's the only lng field available
          ),
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

      // Remove end point marker since your API doesn't provide endLat
      // If you need an end point, use the last checkpoint instead

      // Checkpoint markers
      for (int i = 0; i < widget.checkpoints.length; i++) {
        final checkpoint = widget.checkpoints[i];
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

  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];

    if (widget.routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: widget.routePoints,
          color: const Color(0xFF3B82F6),
          strokeWidth: 4,
        ),
      );
    } else if (widget.routeDetails != null) {
      if (widget.checkpoints.isNotEmpty) {
        final List<LatLng> polylinePoints = [
          LatLng(
            widget.routeDetails!.startLat,
            widget.routeDetails!.endLng,
          ), // Using available coordinates
          ...widget.checkpoints.map((cp) => LatLng(cp.lat, cp.lng)),
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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            widget.routeDetails != null
                ? LatLng(
                  widget.routeDetails!.startLat,
                  widget.routeDetails!.endLng, // Using available coordinates
                )
                : _defaultPosition,
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all, // ✅ This should enable all interactions
        ),
        onMapReady: () {
          debugPrint('✅ Map is ready');
          widget.onMapReady();
        },
        onTap: (tapPosition, point) {
          debugPrint(
            '🗺️ Map tapped at: ${point.latitude}, ${point.longitude}',
          );
          widget.onMapTap();
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
    );
  }
}
