import 'package:flutter/material.dart';

class DirectionSelectionCard extends StatelessWidget {
  final VoidCallback onHomeToSchool;
  final VoidCallback onSchoolToHome;
  final bool isLoading;

  const DirectionSelectionCard({
    super.key,
    required this.onHomeToSchool,
    required this.onSchoolToHome,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 DirectionSelectionCard Build - isLoading: $isLoading');
    print(
      '🔍 DirectionSelectionCard Build - onHomeToSchool: ${onHomeToSchool != null}',
    );
    print(
      '🔍 DirectionSelectionCard Build - onSchoolToHome: ${onSchoolToHome != null}',
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Trip Direction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose the direction for your trip',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Direction Options
            Row(
              children: [
                Expanded(
                  child: _DirectionOption(
                    title: 'Home to School',
                    subtitle: 'Morning Trip',
                    icon: Icons.home,
                    iconColor: const Color(0xFF10B981),
                    onTap:
                        isLoading
                            ? null
                            : () {
                              print('🏠 Home to School button tapped');
                              onHomeToSchool();
                            },
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DirectionOption(
                    title: 'School to Home',
                    subtitle: 'Afternoon Trip',
                    icon: Icons.school,
                    iconColor: const Color(0xFFF59E0B),
                    onTap:
                        isLoading
                            ? null
                            : () {
                              print('🏫 School to Home button tapped');
                              onSchoolToHome();
                            },
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _DirectionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    print(
      '🔍 _DirectionOption Build - title: $title, onTap: ${onTap != null}, isLoading: $isLoading',
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
