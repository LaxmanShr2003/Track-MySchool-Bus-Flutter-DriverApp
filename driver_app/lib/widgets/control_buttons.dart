import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isLoading;
  final bool isTracking;
  final VoidCallback onTrackingToggle;
  final VoidCallback onLocationCenter;
  final VoidCallback onFitRoute;
  final VoidCallback onRefresh;

  const ControlButtons({
    super.key,
    required this.isLoading,
    required this.isTracking,
    required this.onTrackingToggle,
    required this.onLocationCenter,
    required this.onFitRoute,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'tracking',
          onPressed: isLoading ? null : onTrackingToggle,
          backgroundColor: isTracking ? Colors.red : Colors.green,
          elevation: 8,
          child:
              isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(
                    isTracking ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: onLocationCenter,
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 8,
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fit_route',
          onPressed: onFitRoute,
          backgroundColor: Colors.purple,
          elevation: 8,
          child: const Icon(Icons.fit_screen, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'refresh',
          onPressed: onRefresh,
          backgroundColor: Colors.orange,
          elevation: 8,
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        ),
      ],
    );
  }
}
