import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/auth/controller/login_controller.dart';

// Provider for managing password visibility state
final _obscurePasswordProvider = StateProvider<bool>((ref) => true);

// Provider for managing animation states
final _animationStateProvider = StateProvider<bool>((ref) => false);

// This screen uses Riverpod's ConsumerWidget to access the login controller and state.
// It displays the login form, handles user input, and reacts to login state changes.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _buttonController;
  late AnimationController _busController;
  late AnimationController _particleController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _busAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _busController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _busAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _busController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    // Start animations
    _cardController.forward();

    // Listen to text changes for form validation
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid =
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    _buttonController.dispose();
    _busController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the login state from the provider
    final loginState = ref.watch(loginControllerProvider);
    // Get the controller to trigger login actions
    final loginController = ref.read(loginControllerProvider.notifier);
    // Use StateProvider to manage password visibility state
    final obscurePassword = ref.watch(_obscurePasswordProvider);

    // Check if keyboard is visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Show error messages using a modern SnackBar
    void showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }

    void showSuccess(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }

    // Handle login button press
    Future<void> handleLogin() async {
      if (!_isFormValid) return;

      // Button press animation
      _buttonController.forward().then((_) {
        _buttonController.reverse();
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();

      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // Call the controller's login method
      await loginController.login(username, password);

      // Check for errors after login attempt
      final currentState = ref.read(loginControllerProvider);
      if (currentState.error != null) {
        showError(currentState.error!);
        HapticFeedback.heavyImpact();
      } else if (currentState.response != null) {
        // On successful login, show success message and navigate
        showSuccess('Welcome back, $username!');
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/map');
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A), // Deep blue
                      Color(0xFF3B82F6), // Blue
                      Color(0xFF06B6D4), // Cyan
                      Color(0xFF10B981), // Emerald
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      0.0,
                      0.3 + (_backgroundAnimation.value * 0.2),
                      0.6 + (_backgroundAnimation.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated particles/floating elements - hide when keyboard is visible
          if (!isKeyboardVisible)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

          // Floating geometric shapes - hide when keyboard is visible
          if (!isKeyboardVisible)
            AnimatedBuilder(
              animation: _busAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top:
                          80 +
                          (math.sin(_busAnimation.value * 2 * math.pi) * 15),
                      left: 30,
                      child: Transform.rotate(
                        angle: _busAnimation.value * 0.1,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom:
                          120 +
                          (math.cos(_busAnimation.value * 2 * math.pi) * 10),
                      right: 25,
                      child: Transform.rotate(
                        angle: -_busAnimation.value * 0.15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          // Main login form with proper keyboard handling
          SafeArea(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flexible spacer at top
                    Flexible(
                      flex: isKeyboardVisible ? 1 : 2,
                      child: Container(),
                    ),

                    // Bus icon - smaller when keyboard is visible
                    if (!isKeyboardVisible)
                      AnimatedBuilder(
                        animation: _busAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(_busAnimation.value * 2 * math.pi) * 6,
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber[300]!,
                                    Colors.orange[400]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),

                    // Smaller bus icon when keyboard is visible
                    if (isKeyboardVisible)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.amber[300]!, Colors.orange[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),

                    SizedBox(height: isKeyboardVisible ? 12 : 20),

                    // Login card with adjusted size
                    SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _cardAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: EdgeInsets.all(
                                isKeyboardVisible ? 20 : 24,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.white.withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Welcome text - condensed when keyboard is visible
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          'SafeRide',
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                isKeyboardVisible ? 24 : 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        if (!isKeyboardVisible) ...[
                                          SizedBox(height: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'School Bus Tracking',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Sign in to track and manage school buses safely',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isKeyboardVisible ? 16 : 24),

                                  // Username Field
                                  Text(
                                    'Driver ID / Username',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocus,
                                      keyboardType: TextInputType.text,
                                      onTap:
                                          () => HapticFeedback.selectionClick(),
                                      decoration: InputDecoration(
                                        prefixIcon: Container(
                                          margin: EdgeInsets.all(12),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[400],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.badge_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        hintText: 'Enter your driver ID',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: isKeyboardVisible ? 16 : 20,
                                          horizontal: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.blue[400]!,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isKeyboardVisible ? 16 : 20),

                                  // Password Field
                                  Text(
                                    'Password',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: obscurePassword,
                                      onTap:
                                          () => HapticFeedback.selectionClick(),
                                      decoration: InputDecoration(
                                        prefixIcon: Container(
                                          margin: EdgeInsets.all(12),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[400],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        hintText: 'Enter your password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: isKeyboardVisible ? 16 : 20,
                                          horizontal: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.green[400]!,
                                            width: 2,
                                          ),
                                        ),
                                        suffixIcon: AnimatedSwitcher(
                                          duration: Duration(milliseconds: 200),
                                          child: IconButton(
                                            key: ValueKey(obscurePassword),
                                            icon: Icon(
                                              obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              ref
                                                  .read(
                                                    _obscurePasswordProvider
                                                        .notifier,
                                                  )
                                                  .state = !obscurePassword;
                                            },
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isKeyboardVisible ? 16 : 24),

                                  // Login Button
                                  AnimatedBuilder(
                                    animation: _buttonAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _buttonAnimation.value,
                                        child: Container(
                                          width: double.infinity,
                                          height: isKeyboardVisible ? 48 : 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors:
                                                  _isFormValid
                                                      ? [
                                                        Colors.blue[600]!,
                                                        Colors.blue[400]!,
                                                      ]
                                                      : [
                                                        Colors.grey[400]!,
                                                        Colors.grey[300]!,
                                                      ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow:
                                                _isFormValid
                                                    ? [
                                                      BoxShadow(
                                                        color: Colors.blue
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        blurRadius: 15,
                                                        spreadRadius: 0,
                                                        offset: Offset(0, 8),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap:
                                                  (loginState.isLoading ||
                                                          !_isFormValid)
                                                      ? null
                                                      : handleLogin,
                                              child: Center(
                                                child:
                                                    loginState.isLoading
                                                        ? SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(Colors.white),
                                                            strokeWidth: 2.5,
                                                          ),
                                                        )
                                                        : Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.login,
                                                              color:
                                                                  Colors.white,
                                                              size: 22,
                                                            ),
                                                            SizedBox(width: 12),
                                                            Text(
                                                              'Start Tracking',
                                                              style: GoogleFonts.poppins(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Safety reminder - hide when keyboard is visible
                                  if (!isKeyboardVisible) ...[
                                    SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security,
                                            color: Colors.amber[300],
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Your login ensures student safety and route tracking',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flexible spacer at bottom
                    Flexible(flex: 1, child: Container()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 15; i++) {
      final progress = (animationValue + (i * 0.1)) % 1.0;
      final opacity = (math.sin(progress * math.pi) * 0.6).clamp(0.0, 0.6);

      paint.color = Colors.white.withValues(alpha: opacity * 0.3);

      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height) + (progress * size.height * 0.5);
      final radius = 1.0 + (random.nextDouble() * 2);

      canvas.drawCircle(Offset(x, y % size.height), radius, paint);
    }

    // Add some larger floating elements
    for (int i = 0; i < 5; i++) {
      final progress = (animationValue * 0.5 + (i * 0.2)) % 1.0;
      final opacity = (math.sin(progress * math.pi) * 0.3).clamp(0.0, 0.3);

      paint.color = Colors.white.withValues(alpha: opacity);

      final x = (size.width * 0.2) + (i * size.width * 0.15);
      final y = size.height * 0.3 + (math.sin(progress * 2 * math.pi) * 50);
      final radius = 3.0 + (math.sin(progress * math.pi) * 2);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
