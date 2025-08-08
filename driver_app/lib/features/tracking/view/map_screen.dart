import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatefulWidget {
  final Widget child;
  const MapScreen({super.key, required this.child});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const List<String> _routes = [
    '/menu',
    '/attendance',
    '/map',
    '/chat',
    '/notifications',
  ];

  static const List<IconData> _icons = [
    Icons.menu_outlined,
    Icons.access_time_outlined,
    Icons.location_on_outlined,
    Icons.chat_bubble_outline,
    Icons.notifications_outlined,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.menu,
    Icons.access_time,
    Icons.location_on,
    Icons.chat_bubble,
    Icons.notifications,
  ];

  static const List<String> _labels = [
    'Menu',
    'Attendance',
    'Map',
    'Chat',
    'Alerts',
  ];

  static const Color primaryColor = Color(0xFF3B82F6);

  int _selectedIndex = 2; // Default to map

  int _routeToIndex(String location) {
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    return idx == -1 ? 2 : idx;
  }

  void _onTabTapped(int index, String route) {
    // Special handling for hamburger menu (index 0)
    if (index == 0) {
      HapticFeedback.selectionClick();
      _showMenuBottomSheet();
      return;
    }

    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();

      setState(() {
        _selectedIndex = index;
      });

      // Navigate immediately
      context.go(route);
    }
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MenuBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _routeToIndex(location);

    if (_selectedIndex != currentIndex && !location.startsWith('/menu')) {
      _selectedIndex = currentIndex;
    }

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return _buildSimpleTab(
                  index,
                  _icons[index],
                  _selectedIcons[index],
                  _labels[index],
                  _routes[index],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTab(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    String route,
  ) {
    final isSelected = _selectedIndex == index && index != 0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index, route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? primaryColor : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuBottomSheet extends StatelessWidget {
  const MenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.2),
                        const Color(0xFF06B6D4).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Access your account and settings',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildMenuItem(
                  context,
                  Icons.person_outline,
                  'Profile',
                  'Manage your account information',
                  () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  'App preferences and configuration',
                  () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.help_outline,
                  'Help & Support',
                  'Get help and contact support',
                  () {
                    Navigator.pop(context);
                    context.go('/help');
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  'Review our privacy policy',
                  () {
                    Navigator.pop(context);
                    context.go('/privacy');
                  },
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'About',
                  'App version and information',
                  () {
                    Navigator.pop(context);
                    context.go('/about');
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context,
                  Icons.logout,
                  'Sign Out',
                  'Sign out of your account',
                  () {
                    Navigator.pop(context);
                    // Handle sign out logic
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDestructive
                            ? Colors.red.withOpacity(0.1)
                            : const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : const Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? Colors.red : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
