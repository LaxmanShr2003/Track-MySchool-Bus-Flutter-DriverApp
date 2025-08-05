import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/models/route_details_response.dart';

class StatusCard extends StatelessWidget {
  final bool isTracking;
  final bool isWebSocketConnected;
  final RouteDetailsData? routeDetails;

  const StatusCard({
    super.key,
    required this.isTracking,
    required this.isWebSocketConnected,
    this.routeDetails,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: isTracking ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTracking ? Icons.gps_fixed : Icons.gps_off,
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
                        isTracking
                            ? 'GPS Tracking Active'
                            : 'GPS Tracking Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isTracking ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        isWebSocketConnected
                            ? 'Server Connected'
                            : 'Server Disconnected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              isWebSocketConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (routeDetails != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.route, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route: ${routeDetails!.routeName}',
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
}
