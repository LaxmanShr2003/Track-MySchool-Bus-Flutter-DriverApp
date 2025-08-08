import 'package:driver_app/features/auth/view/login_screen.dart';
import 'package:driver_app/features/profile/view/profile_screen.dart';
import 'package:driver_app/features/tracking/view/map_screen.dart';
import 'package:driver_app/features/tracking/view/bus_route_screen.dart';
import 'package:driver_app/features/attendance/view/attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ModernBottomNavBar extends StatefulWidget {
  final String currentPath;

  const ModernBottomNavBar({super.key, required this.currentPath});

  @override
  State<ModernBottomNavBar> createState() => _ModernBottomNavBarState();
}

class _ModernBottomNavBarState extends State<ModernBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  int _selectedIndex = 0;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Map',
      path: '/map',
      color: const Color(0xFF4285F4),
    ),
    NavItem(
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time_rounded,
      label: 'Attendance',
      path: '/attendance',
      color: const Color(0xFFFF9800),
    ),
    NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
      path: '/chat',
      color: const Color(0xFF4CAF50),
    ),
    NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Notifications',
      path: '/notifications',
      color: const Color(0xFF9C27B0),
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      path: '/profile',
      color: const Color(0xFF607D8B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(ModernBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _navItems.indexWhere(
      (item) => item.path == widget.currentPath,
    );
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.lightImpact();

      setState(() {
        _selectedIndex = index;
      });

      _rippleController.forward().then((_) {
        _rippleController.reverse();
      });

      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      context.go(_navItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == _selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onItemTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _animationController,
                            _rippleController,
                          ]),
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripple effect
                                if (isSelected)
                                  Container(
                                    width: 60 * _rippleAnimation.value,
                                    height: 60 * _rippleAnimation.value,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(
                                        0.1 * (1 - _rippleAnimation.value),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                // Active background
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: isSelected ? 56 : 40,
                                  height: isSelected ? 56 : 40,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? item.color.withOpacity(0.15)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        isSelected
                                            ? Border.all(
                                              color: item.color.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            )
                                            : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Icon with scale animation
                                      Transform.scale(
                                        scale:
                                            isSelected
                                                ? _scaleAnimation.value
                                                : 1.0,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          transitionBuilder: (
                                            child,
                                            animation,
                                          ) {
                                            return ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            );
                                          },
                                          child: Icon(
                                            isSelected
                                                ? item.activeIcon
                                                : item.icon,
                                            key: ValueKey(isSelected),
                                            size: isSelected ? 26 : 24,
                                            color:
                                                isSelected
                                                    ? item.color
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ),

                                      // Animated label
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        height: isSelected ? 16 : 12,
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          opacity: isSelected ? 1.0 : 0.7,
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: isSelected ? 11 : 10,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                              color:
                                                  isSelected
                                                      ? item.color
                                                      : Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    required this.color,
  });
}

// Updated router with smooth page transitions
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => MapScreen(child: child),
      routes: [
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/attendance',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const AttendanceScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const BusRouteScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Center(child: Text('Chat')),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Center(child: Text('Notifications')),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);
