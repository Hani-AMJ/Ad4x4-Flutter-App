import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../../../../core/services/vehicle_modifications_cache_service.dart';
import '../../../../data/models/feedback.dart' as feedback_model;
import '../../../../data/models/trip_statistics.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/vehicle_modifications_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/badges/verification_status_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MainApiRepository _repository = MainApiRepository();
  
  // State for enhanced statistics
  TripStatistics? _tripStats;
  bool _isLoadingStats = false;
  String? _statsError;
  
  // Feedback submission only - no history tracking
  
  // State for vehicle modifications
  List<VehicleModifications> _vehicleMods = [];
  bool _isLoadingVehicles = false;
  late VehicleModificationsCacheService _vehicleModsService;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load enhanced data after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }
  
  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _vehicleModsService = VehicleModificationsCacheService(prefs);
    await _loadEnhancedData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Load enhanced statistics and feedback data
  Future<void> _loadEnhancedData() async {
    final user = ref.read(authProviderV2).user;
    if (user == null) return;
    
    // Load trip statistics and vehicle modifications in parallel
    await Future.wait([
      _loadTripStatistics(user.id),
      _loadVehicleModifications(user.id),
    ]);
  }
  
  /// Load vehicle modifications
  Future<void> _loadVehicleModifications(int memberId) async {
    setState(() {
      _isLoadingVehicles = true;
    });
    
    try {
      final mods = await _vehicleModsService.getModificationsByMemberId(memberId);
      setState(() {
        _vehicleMods = mods;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading vehicle modifications: $e');
      }
      setState(() {
        _isLoadingVehicles = false;
      });
    }
  }
  
  /// Load detailed trip statistics
  Future<void> _loadTripStatistics(int userId) async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });
    
    try {
      // Step 1: Get trip counts (checked-in trips by level)
      final response = await _repository.getMemberTripCounts(userId);
      
      // 🔍 DEBUG: Log raw backend response
      print('🔍 [TripStats] Backend Response for user $userId:');
      print('   Full response: $response');
      
      // Handle both direct data and nested data structures
      final data = response['data'] ?? response['results'] ?? response;
      print('   Extracted data: $data');
      
      // Step 2: Get upcoming registered trips count
      // Use triphistory endpoint to count registered trips where checkedIn=false
      int upcomingCount = 0;
      try {
        final tripHistoryResponse = await _repository.getMemberTripHistory(
          memberId: userId,
          checkedIn: false, // Only get trips NOT checked in
          page: 1,
          pageSize: 1, // We only need the count, not all trips
        );
        upcomingCount = tripHistoryResponse['count'] ?? 0;
        print('   Upcoming (registered, not checked-in) trips: $upcomingCount');
      } catch (e) {
        print('   ⚠️ Failed to fetch upcoming trips count: $e');
      }
      
      setState(() {
        _tripStats = TripStatistics.fromJson(data is Map<String, dynamic> ? data : {});
        // Override upcomingTrips with actual count of registered non-checked-in trips
        _tripStats = _tripStats!.copyWith(upcomingTrips: upcomingCount);
        
        print('   ✅ Final parsed stats:');
        print('      Completed (checked-in): ${_tripStats!.completedTrips}');
        print('      Upcoming (registered, not checked-in): ${_tripStats!.upcomingTrips}');
        print('      Level breakdown: L1=${_tripStats!.level1Trips}, L2=${_tripStats!.level2Trips}, L3=${_tripStats!.level3Trips}, L4=${_tripStats!.level4Trips}, L5=${_tripStats!.level5Trips}');
        print('      Check-in count: ${_tripStats!.checkedInCount}, Attendance rate: ${_tripStats!.attendanceRate}%');
        _isLoadingStats = false;
      });
    } catch (e) {
      print('❌ [TripStats] Error loading trip statistics: $e');
      setState(() {
        _statsError = 'Failed to load statistics';
        _isLoadingStats = false;
      });
    }
  }
  

  
  /// Show submit feedback dialog with image upload support
  void _showSubmitFeedbackDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String selectedType = feedback_model.FeedbackType.bug;
    String message = '';
    String? imageUrl;
    XFile? selectedImage;
    bool isSubmitting = false;
    bool isUploadingImage = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Feedback'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feedback Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Feedback Type',
                      border: OutlineInputBorder(),
                    ),
                    items: feedback_model.FeedbackType.all
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(feedback_model.FeedbackType.getLabel(type)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Message Field
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Describe your feedback...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your feedback message';
                      }
                      if (value.trim().length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => message = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  
                  // Image Attachment Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file, 
                                size: 20, 
                                color: Theme.of(context).colorScheme.primary
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Attachment (Optional)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedImage == null) ...[
                            OutlinedButton.icon(
                              onPressed: isSubmitting || isUploadingImage 
                                  ? null 
                                  : () async {
                                      setDialogState(() => isUploadingImage = true);
                                      
                                      try {
                                        final ImagePicker picker = ImagePicker();
                                        final XFile? image = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 1920,
                                          maxHeight: 1080,
                                          imageQuality: 85,
                                        );
                                        
                                        if (image != null) {
                                          setDialogState(() {
                                            selectedImage = image;
                                            isUploadingImage = false;
                                          });
                                        } else {
                                          setDialogState(() => isUploadingImage = false);
                                        }
                                      } catch (e) {
                                        if (kDebugMode) {
                                          debugPrint('Error picking image: $e');
                                        }
                                        setDialogState(() => isUploadingImage = false);
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to pick image: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_photo_alternate),
                              label: Text(isUploadingImage 
                                  ? 'Selecting...' 
                                  : 'Add Screenshot'
                              ),
                            ),
                          ] else ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.image,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                selectedImage!.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: isSubmitting 
                                    ? null 
                                    : () {
                                        setDialogState(() {
                                          selectedImage = null;
                                          imageUrl = null;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting || isUploadingImage
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      formKey.currentState!.save();
                      
                      setDialogState(() => isSubmitting = true);
                      
                      try {
                        // Upload image first if selected
                        if (selectedImage != null) {
                          try {
                            // Convert image to base64 for submission
                            final bytes = await selectedImage!.readAsBytes();
                            final base64String = base64Encode(bytes);
                            imageUrl = 'data:image/jpeg;base64,$base64String';
                            
                            if (kDebugMode) {
                              debugPrint('✅ Image converted to base64 (${base64String.length} chars)');
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              debugPrint('Error converting image: $e');
                            }
                            // Continue without image if conversion fails
                            imageUrl = null;
                          }
                        }
                        
                        await _repository.submitFeedback(
                          feedbackType: selectedType,
                          message: message,
                          image: imageUrl,
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Feedback submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // Feedback submitted successfully - admin will view on backend
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Failed to submit feedback: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Get real user data from auth provider
    final authState = ref.watch(authProviderV2);
    final user = authState.user;
    final WidgetRef widgetRef = ref;

    // Show loading if user data not available
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Extract user data
    final userName = user.displayName;
    final userEmail = user.email;
    // FIXED: Check both phoneNumber and phone fields (backend might send either)
    final userPhone = user.phoneNumber ?? user.phone ?? 'Not provided';
    final memberSince = user.dateJoined != null && user.dateJoined!.isNotEmpty
        ? 'Member since ${user.dateJoined!.substring(0, 4)}'
        : 'Member';
    final userRole = user.level?.displayName ?? user.level?.name ?? 'Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined),
            onPressed: () => context.push('/profile/logbook/${user.id}?name=${Uri.encodeComponent(user.displayName)}'),
            tooltip: 'My Logbook',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    UserAvatar(
                      name: userName,
                      imageUrl: user.avatar != null && user.avatar!.isNotEmpty 
                          ? (user.avatar!.startsWith('http') 
                              ? user.avatar 
                              : 'https://media.ad4x4.com${user.avatar}')
                          : null,
                      radius: 60,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Level Badge - with consistent color
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: LevelDisplayHelper.getLevelColor(user.level?.numericLevel ?? 0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Member Since
                    Text(
                      memberSince,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.explore,  // ✅ Explore icon for trips
                      label: 'Trips',  // ✅ Shows total checked-in trips
                      value: _tripStats?.checkedInCount.toString() ?? user.tripCount?.toString() ?? '0',  // ✅ Total checked-in trips
                      colors: colors,
                      iconColor: Colors.amber,  // ✅ Gold color
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outline,
                    ),
                    _StatItem(
                      icon: Icons.photo_library,
                      label: 'Photos',
                      value: '0',  // TODO: Add photo count from Gallery API
                      colors: colors,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outline,
                    ),
                    _StatItem(
                      icon: Icons.local_fire_department,
                      label: 'Level',
                      value: '${user.level?.numericLevel ?? 0}',
                      colors: colors,
                      iconColor: LevelDisplayHelper.getLevelColor(user.level?.numericLevel ?? 0),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contact Information
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: userEmail,
                      iconColor: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      subtitle: userPhone,
                      iconColor: colors.primary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ✅ Vehicle Modifications Section (Replaced old mock vehicle info)
              _buildVehicleModificationsSection(context, theme, colors, user.id),

              const Divider(height: 1),

              // Emergency Contact (if available)
              if (user.iceName != null || user.icePhone != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contact',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (user.iceName != null)
                        InfoCard(
                          icon: Icons.person_outline,
                          title: 'ICE Contact',
                          subtitle: user.iceName!,
                          iconColor: const Color(0xFFFF5722),
                        ),
                      if (user.icePhone != null) ...[
                        const SizedBox(height: 12),
                        InfoCard(
                          icon: Icons.phone,
                          title: 'ICE Phone',
                          subtitle: user.icePhone!,
                          iconColor: const Color(0xFFFF5722),
                        ),
                      ],
                    ],
                  ),
                ),

              if (user.iceName != null || user.icePhone != null)
                const Divider(height: 1),

              // ✅ NEW: Enhanced Trip Statistics Section
              _buildEnhancedStatsSection(context, theme, colors, user),

              const Divider(height: 1),

              // ✅ NEW: Feedback Section
              _buildFeedbackSection(context, theme, colors),

              const Divider(height: 1),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoCard(
                      icon: Icons.garage,
                      title: 'My Vehicles',
                      subtitle: _vehicleMods.isEmpty 
                        ? 'Add and manage your vehicles'
                        : '${_vehicleMods.length} vehicle${_vehicleMods.length == 1 ? '' : 's'} with modifications',
                      iconColor: const Color(0xFF64B5F6),
                      onTap: () => context.push('/vehicles'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.explore,
                      title: 'My Trips',
                      subtitle: 'View your trip history',
                      iconColor: const Color(0xFF42B883),
                      onTap: () => context.push('/trips'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.event,
                      title: 'My Events',
                      subtitle: 'Registered events',
                      iconColor: const Color(0xFFFFC107),
                      onTap: () => context.push('/events'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.photo_library,
                      title: 'My Gallery',
                      subtitle: 'Your photo albums',
                      iconColor: const Color(0xFFE53935),
                      // FIXED: Pass filter=my to show only user's albums
                      onTap: () => context.push('/gallery?filter=my'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.book,
                      title: 'My Logbook',
                      subtitle: 'View your skills and logbook entries',
                      iconColor: const Color(0xFF9C27B0),
                      onTap: () => context.push('/profile/logbook/${user.id}?name=${Uri.encodeComponent(user.displayName)}'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Account Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoCard(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      iconColor: colors.onSurface.withValues(alpha: 0.7),
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      iconColor: const Color(0xFFE53935),
                      onTap: () {
                        _showLogoutDialog(context, widgetRef);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build enhanced statistics section
  /// ✅ NEW: Phase A Task #5 - Detailed trip statistics
  Widget _buildEnhancedStatsSection(BuildContext context, ThemeData theme, ColorScheme colors, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoadingStats)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_statsError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 32),
                  const SizedBox(height: 8),
                  Text(_statsError!, style: TextStyle(color: colors.error)),
                ],
              ),
            )
          else if (_tripStats != null) ...[
            // Participation Stats
            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: _tripStats!.completedTrips.toString(),
                    color: Colors.green,
                    onTap: () {
                      context.push(
                        '/trips/filtered/${user.id}?filterType=completed&title=Completed Trips (${_tripStats!.completedTrips})',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    icon: Icons.upcoming,
                    label: 'Upcoming',
                    value: _tripStats!.upcomingTrips.toString(),
                    color: Colors.blue,
                    onTap: () {
                      context.push(
                        '/trips/filtered/${user.id}?filterType=upcoming&title=Upcoming Trips (${_tripStats!.upcomingTrips})',
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Leadership Stats
            if (_tripStats!.hasLeadershipExperience) ...[
              Row(
                children: [
                  Expanded(
                    child: _StatsCard(
                      icon: Icons.star,
                      label: 'As Lead',
                      value: _tripStats!.asLeadTrips.toString(),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatsCard(
                      icon: Icons.shield,
                      label: 'As Marshal',
                      value: _tripStats!.asMarshalTrips.toString(),
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Level Breakdown - Enhanced Design
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trips by Level',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(5, (index) {
                      final level = index + 1;
                      final count = _tripStats!.getTripCountByLevel(level);
                      final levelLabel = LevelDisplayHelper.getTripLevelLabel(level);
                      
                      // Map level index to numeric level for backend filtering
                      int? levelNumeric;
                      Color levelColor;
                      IconData levelIcon;
                      
                      switch (level) {
                        case 1:
                          levelNumeric = 5; // Club Event
                          levelColor = const Color(0xFF4CAF50); // Green - matches trip cards
                          levelIcon = Icons.groups; // Same as LevelDisplayHelper
                          break;
                        case 2:
                          levelNumeric = 10; // Newbie/ANIT
                          levelColor = const Color(0xFF4CAF50); // Green - matches trip cards
                          levelIcon = Icons.school; // Same as LevelDisplayHelper
                          break;
                        case 3:
                          levelNumeric = 100; // Intermediate
                          levelColor = const Color(0xFF2196F3); // Blue - matches trip cards
                          levelIcon = Icons.terrain; // Same as LevelDisplayHelper
                          break;
                        case 4:
                          levelNumeric = 200; // Advanced
                          levelColor = const Color(0xFFE91E63); // Pink/Red - matches trip cards
                          levelIcon = Icons.landscape; // Same as LevelDisplayHelper
                          break;
                        case 5:
                          levelNumeric = 300; // Expert
                          levelColor = const Color(0xFF9C27B0); // Purple - matches trip cards
                          levelIcon = Icons.workspace_premium; // Same as LevelDisplayHelper
                          break;
                        default:
                          levelColor = colors.primary;
                          levelIcon = Icons.flag;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: count > 0 
                              ? levelColor.withValues(alpha: 0.08)
                              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: count > 0 && levelNumeric != null
                                ? () {
                                    context.push(
                                      '/trips/filtered/${user.id}?filterType=level&levelNumeric=$levelNumeric&title=$levelLabel Trips ($count)',
                                    );
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(
                                children: [
                                  // Level icon
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: count > 0 
                                          ? levelColor.withValues(alpha: 0.15)
                                          : colors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      levelIcon,
                                      size: 16,
                                      color: count > 0 
                                          ? levelColor
                                          : colors.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Level label
                                  Expanded(
                                    child: Text(
                                      levelLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: count > 0 
                                            ? colors.onSurface
                                            : colors.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  // Count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: count > 0 
                                          ? levelColor
                                          : colors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: count > 0 
                                            ? Colors.white
                                            : colors.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: levelColor.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Attendance Rate (if available) - Enhanced Design
            if (_tripStats!.attendanceRate > 0) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryContainer,
                        colors.primaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.onPrimaryContainer.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: colors.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Attendance Rate',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onPrimaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_tripStats!.attendanceRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Build feedback section - Clean, modern design
  /// User can submit feedback, admin views on backend
  Widget _buildFeedbackSection(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and submit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Feedback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showSubmitFeedbackDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Compact feedback card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact header with icon and title
                  Row(
                    children: [
                      // Smaller icon with gradient
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primaryContainer,
                              colors.secondaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.feedback_outlined,
                          size: 20,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Title and description inline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'We Value Your Feedback!',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Share thoughts, report bugs, or suggest features',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Compact feature chips in a grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip(
                        context,
                        icon: Icons.bug_report,
                        label: 'Bugs',
                        colors: colors,
                      ),
                      _buildFeatureChip(
                        context,
                        icon: Icons.lightbulb_outline,
                        label: 'Features',
                        colors: colors,
                      ),
                      _buildFeatureChip(
                        context,
                        icon: Icons.chat_bubble_outline,
                        label: 'General',
                        colors: colors,
                      ),
                      _buildFeatureChip(
                        context,
                        icon: Icons.help_outline,
                        label: 'Support',
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build feature chip for feedback types
  Widget _buildFeatureChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Call auth provider V2 logout
              await ref.read(authProviderV2.notifier).logout();
              
              // Router will auto-redirect to login after logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Build vehicle modifications section
  /// ✅ NEW: Vehicle modifications display with verification status
  Widget _buildVehicleModificationsSection(BuildContext context, ThemeData theme, ColorScheme colors, int memberId) {
    if (_isLoadingVehicles) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicleMods.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no vehicles
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehicle Modifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/vehicles'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._vehicleMods.take(3).map((mod) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.directions_car, color: colors.primary),
                  ),
                  title: Text('Vehicle #${mod.vehicleId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      VerificationStatusBadge(
                        status: mod.verificationStatus,
                        compact: true,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.push(
                        '/vehicles/${mod.vehicleId}/edit-modifications',
                        extra: memberId,
                      );
                    },
                  ),
                  onTap: () {
                    context.push(
                      '/vehicles/${mod.vehicleId}/edit-modifications',
                      extra: memberId,
                    );
                  },
                ),
              ),
            );
          }),
          if (_vehicleMods.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/vehicles'),
                icon: const Icon(Icons.arrow_forward),
                label: Text('View all ${_vehicleMods.length} vehicles'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final Color? iconColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: iconColor ?? colors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}



/// Stats card widget for enhanced statistics display
/// ✅ NEW: Phase A Task #5 - Profile Screen Enhancements
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              // Icon with circular gradient background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              // Value with larger, bolder font
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
