import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/features/profile/controller/profile_controller.dart';
import 'package:driver_app/models/profile_response.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    // Fetch profile when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!profileState.hasLoaded &&
          !profileState.isLoading &&
          profileState.error == null) {
        profileController.fetchProfile();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header - Fixed height
              _buildHeader(),
              // Content - Flexible to fill remaining space
              _buildContent(profileState, profileController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              children: [
                Text(
                  'Driver Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View your information and assignments',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(profileControllerProvider.notifier).refreshProfile();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ProfileState profileState,
    ProfileController profileController,
  ) {
    if (profileState.isLoading) {
      return _buildLoadingState();
    } else if (profileState.error != null) {
      return _buildErrorState(profileState.error!, profileController);
    } else if (profileState.user == null) {
      return _buildEmptyState(profileController);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileCard(profileState.user!),
          const SizedBox(height: 20),
          _buildPersonalInfoCard(profileState.user!),
          const SizedBox(height: 20),
          _buildRouteAssignmentsCard(profileState.user!),
          // Add extra padding at bottom for better scrolling
          const SizedBox(height: 40),
          // Add debug section to ensure scrolling works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'Debug Info - Scroll Test',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If you can see this, scrolling is working!',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  'Route Assignments: ${profileState.user!.routeAssignment.length}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  'User ID: ${profileState.user!.id}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          // Add a spacer to ensure content is scrollable
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Container(
            width: 60, // Reduced size
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16), // Reduced spacing
          Text(
            'Loading Profile...',
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced font size
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ProfileController profileController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, // Reduced size
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 30, // Reduced size
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: GoogleFonts.poppins(
                fontSize: 20, // Reduced font size
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14, // Reduced font size
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                profileController.refreshProfile();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ProfileController profileController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, // Reduced size
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 30, // Reduced size
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Profile Data',
              style: GoogleFonts.poppins(
                fontSize: 18, // Reduced font size
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to load your profile',
              style: GoogleFonts.poppins(
                fontSize: 14, // Reduced font size
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                profileController.fetchProfile();
              },
              icon: const Icon(Icons.person, size: 18),
              label: Text(
                'Load Profile',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfileUser user) {
    return Container(
      padding: const EdgeInsets.all(20), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Profile Image
          Container(
            width: 80, // Reduced size
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 15, // Reduced blur
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  (user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty &&
                          user.profileImageUrl != 'null')
                      ? Image.network(
                        user.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                      : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          // Name and Role
          Text(
            '${user.firstName} ${user.lastName}',
            style: GoogleFonts.poppins(
              fontSize: 20, // Reduced font size
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16), // Reduced radius
            ),
            child: Text(
              user.role.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11, // Reduced font size
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '@${user.userName}',
            style: GoogleFonts.poppins(
              fontSize: 13, // Reduced font size
              color: const Color(0xFF64748B),
            ),
            maxLines: 1, // Prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Color(0xFF3B82F6),
      ), // Reduced size
    );
  }

  Widget _buildPersonalInfoCard(ProfileUser user) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced font size
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          _buildInfoRow(Icons.email, 'Email', user.email),
          _buildInfoRow(Icons.phone, 'Mobile', user.mobileNumber),
          _buildInfoRow(Icons.home, 'Address', user.address),
          _buildInfoRow(
            Icons.badge,
            'License Number',
            user.licenseNumber ?? 'Not provided',
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Member Since',
            '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top for long text
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6), // Reduced radius
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF3B82F6),
            ), // Reduced size
          ),
          const SizedBox(width: 10), // Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11, // Reduced font size
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13, // Reduced font size
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3, // Allow wrapping for long text
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAssignmentsCard(ProfileUser user) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Route Assignments',
                  style: GoogleFonts.poppins(
                    fontSize: 16, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), // Reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10), // Reduced radius
                ),
                child: Text(
                  '${user.routeAssignment.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 11, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          if (user.routeAssignment.isEmpty)
            _buildEmptyAssignments()
          else
            ...user.routeAssignment
                .map((assignment) => _buildAssignmentCard(assignment))
                ,
        ],
      ),
    );
  }

  Widget _buildEmptyAssignments() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 32, // Reduced size
            color: const Color(0xFF64748B).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            'No Route Assignments',
            style: GoogleFonts.poppins(
              fontSize: 14, // Reduced font size
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You haven\'t been assigned to any routes yet',
            style: GoogleFonts.poppins(
              fontSize: 12, // Reduced font size
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(RouteAssignment assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Reduced margin
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6), // Reduced radius
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 16, // Reduced size
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      assignment.bus?.busName ?? 'Bus ID: ${assignment.busId}',
                      style: GoogleFonts.poppins(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Plate: ${assignment.bus?.plateNumber ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11, // Reduced font size
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), // Reduced padding
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    assignment.assignmentStatus ?? 'Pending',
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10), // Reduced radius
                ),
                child: Text(
                  (assignment.assignmentStatus ?? 'Pending').toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 9, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(
                      assignment.assignmentStatus ?? 'Pending',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (assignment.busRoute != null) ...[
            const SizedBox(height: 10), // Reduced spacing
            Container(
              padding: const EdgeInsets.all(10), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    assignment.busRoute!.routeName,
                    style: GoogleFonts.poppins(
                      fontSize: 13, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoutePoint(
                          Icons.trip_origin,
                          'From',
                          assignment.busRoute!.startingPointName,
                          const Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        width: 15, // Reduced width
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      Expanded(
                        child: _buildRoutePoint(
                          Icons.location_on,
                          'To',
                          'Destination',
                          const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6), // Reduced spacing
          if (assignment.assignedDate != null &&
                  assignment.assignedDate!.isNotEmpty ||
              assignment.endDate != null && assignment.endDate!.isNotEmpty) ...[
            Wrap(
              // Use Wrap to prevent overflow
              spacing: 10,
              runSpacing: 2,
              children: [
                if (assignment.assignedDate != null &&
                    assignment.assignedDate!.isNotEmpty)
                  Text(
                    'From: ${assignment.assignedDate}',
                    style: GoogleFonts.poppins(
                      fontSize: 11, // Reduced font size
                      color: const Color(0xFF64748B),
                    ),
                  ),
                if (assignment.endDate != null &&
                    assignment.endDate!.isNotEmpty)
                  Text(
                    'To: ${assignment.endDate}',
                    style: GoogleFonts.poppins(
                      fontSize: 11, // Reduced font size
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ],
          if (assignment.studentId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Student ID: ${assignment.studentId}',
              style: GoogleFonts.poppins(
                fontSize: 11, // Reduced font size
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutePoint(
    IconData icon,
    String label,
    String location,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color), // Reduced size
        const SizedBox(width: 3), // Reduced spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9, // Reduced font size
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: GoogleFonts.poppins(
                  fontSize: 11, // Reduced font size
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2, // Allow more lines for better readability
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    final statusLower = status?.toLowerCase() ?? 'pending';
    switch (statusLower) {
      case 'active':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'inactive':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}
