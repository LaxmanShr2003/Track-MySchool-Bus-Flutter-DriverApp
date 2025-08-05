import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/models/route_details_response.dart';

class RouteInfoCard extends StatelessWidget {
  final RouteDetailsData routeDetails;
  final List<Checkpoint> checkpoints;
  final VoidCallback onClose;

  const RouteInfoCard({
    super.key,
    required this.routeDetails,
    required this.checkpoints,
    required this.onClose,
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
                  onPressed: onClose,
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
            ...checkpoints
                .take(3)
                .map(
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
