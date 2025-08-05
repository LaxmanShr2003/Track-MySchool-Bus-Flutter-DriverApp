import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? loadingText;

  const LoadingOverlay({super.key, required this.isLoading, this.loadingText});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isLoading,
      child: Container(
        color: isLoading ? Colors.black54 : Colors.transparent,
        child:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loadingText ?? 'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : null,
      ),
    );
  }
}
