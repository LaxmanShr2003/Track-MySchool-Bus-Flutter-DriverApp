import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  final Widget child;
  const MapScreen({super.key, required this.child});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const List<String> _routes = [
    '/menu', // Changed from '/profile' to '/menu'
    '/attendance',
    '/map',
    '/chat',
    '/notifications',
  ];

  static const List<IconData> _icons = [
    Icons.menu_outlined, // Changed from Icons.person_outline
    Icons.access_time_outlined,
    Icons.location_on_outlined,
    Icons.chat_bubble_outline,
    Icons.notifications_outlined,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.menu, // Changed from Icons.person
    Icons.access_time,
    Icons.location_on,
    Icons.chat_bubble,
    Icons.notifications,
  ];

  static const List<String> _labels = [
    'Menu', // Changed from 'Profile'
    'Attendance',
    'Map',
    'Chat',
    'Alerts',
  ];

  // Define consistent color scheme
  static const Color primaryColor = Color(0xFF3B82F6); // Blue
  static const Color primaryLightColor = Color(0xFF60A5FA); // Light blue
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color successColor = Color(0xFF10B981); // Emerald

  late AnimationController _mainController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late List<AnimationController> _tabControllers;

  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _floatingAnimation;

  int _selectedIndex = 2; // Default to map
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Faster animations - reduced durations
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 1200
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250), // Reduced from 600
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Reduced from 2000
      vsync: this,
    )..repeat();

    _tabControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150), // Reduced from 300
        vsync: this,
      ),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ), // Changed curve
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      // Reduced effect
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Reduced movement
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize selected tab animation
    _tabControllers[_selectedIndex].forward();
    _slideController.forward(); // Start slide animation immediately
  }

  @override
  void dispose() {
    _mainController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    for (var controller in _tabControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int _routeToIndex(String location) {
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    return idx == -1 ? 2 : idx;
  }

  Future<void> _onTabTapped(int index, String route) async {
    // Special handling for hamburger menu (index 0)
    if (index == 0) {
      HapticFeedback.selectionClick();
      _showMenuBottomSheet();
      return;
    }

    if (_selectedIndex != index && !_isAnimating) {
      _isAnimating = true;

      try {
        // Immediate haptic feedback
        HapticFeedback.selectionClick();

        // Parallel animations instead of sequential
        final previousIndex = _selectedIndex;

        setState(() {
          _selectedIndex = index;
        });

        // Start all animations simultaneously
        final animations = <Future>[
          _tabControllers[previousIndex].reverse(),
          _tabControllers[index].forward(),
        ];

        // Trigger slide animation immediately
        _slideController.reset();
        _slideController.forward();

        // Wait for tab animations only
        await Future.wait(animations);

        // Navigate without waiting
        context.go(route);
      } catch (e) {
        print('Animation error: $e');
      } finally {
        _isAnimating = false;
      }
    }
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _routeToIndex(location);

    // Don't update selected index for menu route since it's handled differently
    if (_selectedIndex != currentIndex && !location.startsWith('/menu')) {
      _selectedIndex = currentIndex;
      _slideController.forward(); // Ensure slide animation is active
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          widget.child,
          // Optimized background effects
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return CustomPaint(
                painter: ModernEffectsPainter(
                  animation: _mainController,
                  selectedIndex: _selectedIndex,
                ),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            height: 68, // Reduced from 70 to prevent overflow
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Backdrop blur effect simulation
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.85),
                  ),
                ),
                // Sliding indicator with consistent colors (skip for hamburger menu)
                if (_selectedIndex != 0)
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left:
                            (_selectedIndex *
                                (MediaQuery.of(context).size.width - 32) /
                                5) +
                            8,
                        top: 6, // Adjusted for new height
                        child: Transform.scale(
                          scale: _slideAnimation.value,
                          child: Container(
                            width:
                                (MediaQuery.of(context).size.width - 32) / 5 -
                                16,
                            height: 56, // Adjusted for new container height
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withValues(alpha: 0.25),
                                  accentColor.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Navigation items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return _buildModernTab(
                      index,
                      _icons[index],
                      _selectedIcons[index],
                      _labels[index],
                      _routes[index],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTab(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    String route,
  ) {
    final isSelected =
        _selectedIndex == index &&
        index != 0; // Hamburger menu is never "selected"

    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([_tabControllers[index], _pulseAnimation]),
        builder: (context, child) {
          final tabAnimation = _tabControllers[index];
          final scale =
              isSelected
                  ? 1.0 +
                      (tabAnimation.value * 0.05) *
                          _pulseAnimation
                              .value // Reduced scale effect
                  : 1.0;

          return GestureDetector(
            onTapDown: (_) {
              _tabControllers[index].forward();
            },
            onTapUp: (_) {
              if (!isSelected) {
                _tabControllers[index].reverse();
              }
            },
            onTapCancel: () {
              if (!isSelected) {
                _tabControllers[index].reverse();
              }
            },
            onTap: () => _onTabTapped(index, route),
            child: SizedBox(
              height: 66, // Fixed height to prevent overflow
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset:
                        isSelected
                            ? _floatingAnimation.value * 2
                            : Offset.zero, // Reduced movement
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Prevent overflow
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glowing effect for selected item with consistent colors
                              if (isSelected)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryColor.withValues(alpha: 0.3),
                                        primaryColor.withValues(alpha: 0.0),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              // Icon with faster morphing animation
                              AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 120,
                                ), // Faster
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  isSelected ? selectedIcon : icon,
                                  key: ValueKey(isSelected),
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : Colors.grey[600],
                                  size:
                                      22, // Slightly smaller to prevent overflow
                                ),
                              ),
                              // Ripple effect on tap with consistent colors
                              if (tabAnimation.value > 0 && !isSelected)
                                Container(
                                  width:
                                      28 *
                                      (1 +
                                          tabAnimation.value *
                                              0.5), // Reduced expansion
                                  height: 28 * (1 + tabAnimation.value * 0.5),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: primaryColor.withValues(
                                        alpha:
                                        0.3 * (1 - tabAnimation.value),
                                      ),
                                      width: 1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3), // Reduced spacing
                          // Animated label with consistent colors
                          AnimatedDefaultTextStyle(
                            duration: const Duration(
                              milliseconds: 120,
                            ), // Faster
                            style: TextStyle(
                              fontSize:
                                  isSelected ? 10.5 : 9.5, // Slightly smaller
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color:
                                  isSelected ? primaryColor : Colors.grey[600],
                            ),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Active indicator dot with consistent colors
                          AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 120,
                            ), // Faster
                            width: isSelected ? 3 : 0, // Smaller dot
                            height: isSelected ? 3 : 0,
                            margin: const EdgeInsets.only(
                              top: 1,
                            ), // Reduced margin
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color:
                                              primaryColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 3,
                                          spreadRadius: 0.5,
                                        ),
                                      ]
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
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
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        const Color(0xFF06B6D4).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu,
                    color: const Color(0xFF3B82F6),
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
          // Menu items
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
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
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
                            ? Colors.red.withValues(alpha: 0.1)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.1),
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

class ModernEffectsPainter extends CustomPainter {
  final Animation<double> animation;
  final int selectedIndex;

  ModernEffectsPainter({required this.animation, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    // Optimized floating particles effect with consistent colors
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(selectedIndex);

    for (int i = 0; i < 4; i++) {
      // Reduced from 6 for better performance
      final progress = (animation.value + (i * 0.2)) % 1.0;
      final opacity = (math.sin(progress * math.pi) * 0.15).clamp(
        0.0,
        0.15,
      ); // Reduced opacity

      paint.color = const Color(0xFF3B82F6).withValues(alpha: opacity);

      final x = random.nextDouble() * size.width;
      final y = size.height - 80 + (random.nextDouble() * 40);
      final radius = 1.5 + (random.nextDouble() * 1.5); // Smaller particles

      canvas.drawCircle(
        Offset(x, y - (progress * 60)), // Reduced travel distance
        radius * (1 - progress),
        paint,
      );
    }

    // Subtle gradient overlay effect with consistent colors
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [
              const Color(
                0xFF3B82F6,
              ).withValues(alpha: 0.03 * animation.value), // Reduced opacity
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 120, size.width, 120), // Reduced height
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(ModernEffectsPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
