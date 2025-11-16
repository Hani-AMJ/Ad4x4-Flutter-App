import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../../../../core/services/vehicle_modifications_cache_service.dart';
import '../../../../data/models/feedback.dart' as feedback_model;
import '../../../../data/models/trip_statistics.dart';
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
  
  // State for feedback history
  List<feedback_model.Feedback> _feedbackHistory = [];
  bool _isLoadingFeedback = false;
  String? _feedbackError;
  int _feedbackPage = 1;
  
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
    
    // Load trip statistics, feedback history, and vehicle modifications in parallel
    await Future.wait([
      _loadTripStatistics(user.id),
      _loadFeedbackHistory(user.id),
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
      final response = await _repository.getMemberTripCounts(userId);
      
      // Handle both direct data and nested data structures
      final data = response['data'] ?? response['results'] ?? response;
      
      setState(() {
        _tripStats = TripStatistics.fromJson(data is Map<String, dynamic> ? data : {});
        _isLoadingStats = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading trip statistics: $e');
      }
      setState(() {
        _statsError = 'Failed to load statistics';
        _isLoadingStats = false;
      });
    }
  }
  
  /// Load feedback history
  Future<void> _loadFeedbackHistory(int userId) async {
    setState(() {
      _isLoadingFeedback = true;
      _feedbackError = null;
    });
    
    try {
      final response = await _repository.getMemberFeedback(
        memberId: userId,
        page: _feedbackPage,
        pageSize: 20,
      );
      
      final results = response['results'] as List<dynamic>? ?? [];
      final feedbackList = results
          .map((item) => feedback_model.Feedback.fromJson(item as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _feedbackHistory = feedbackList;
        _isLoadingFeedback = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading feedback history: $e');
      }
      setState(() {
        _feedbackError = 'Failed to load feedback history';
        _isLoadingFeedback = false;
      });
    }
  }
  
  /// Show submit feedback dialog
  void _showSubmitFeedbackDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String selectedType = feedback_model.FeedbackType.bug;
    String message = '';
    bool isSubmitting = false;
    
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
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      formKey.currentState!.save();
                      
                      setDialogState(() => isSubmitting = true);
                      
                      try {
                        await _repository.submitFeedback(
                          feedbackType: selectedType,
                          message: message,
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Feedback submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // Reload feedback history
                          final user = ref.read(authProviderV2).user;
                          if (user != null) {
                            _loadFeedbackHistory(user.id);
                          }
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
    final userPhone = user.phoneNumber ?? 'Not provided';
    final memberSince = user.dateJoined != null && user.dateJoined!.isNotEmpty
        ? 'Member since ${user.dateJoined!.substring(0, 4)}'
        : 'Member';
    final userRole = user.level?.displayName ?? user.level?.name ?? 'Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
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
                      icon: Icons.directions_car,
                      label: 'Trips',
                      value: user.tripCount?.toString() ?? '0',
                      colors: colors,
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
              _buildEnhancedStatsSection(context, theme, colors),

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
                      onTap: () => context.push('/gallery'),
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
  Widget _buildEnhancedStatsSection(BuildContext context, ThemeData theme, ColorScheme colors) {
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    icon: Icons.upcoming,
                    label: 'Upcoming',
                    value: _tripStats!.upcomingTrips.toString(),
                    color: Colors.blue,
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
            
            // Level Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trips by Level',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(5, (index) {
                      final level = index + 1;
                      final count = _tripStats!.getTripCountByLevel(level);
                      final levelLabel = LevelDisplayHelper.getTripLevelLabel(level);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(levelLabel),
                            Text(
                              count.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Attendance Rate (if available)
            if (_tripStats!.attendanceRate > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart, color: colors.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Text(
                            'Attendance Rate',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_tripStats!.attendanceRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
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

  /// Build feedback section
  /// ✅ NEW: Phase A Task #5 - Feedback submission and history
  Widget _buildFeedbackSection(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          if (_isLoadingFeedback)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_feedbackError != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 32),
                  const SizedBox(height: 8),
                  Text(_feedbackError!, style: TextStyle(color: colors.error)),
                ],
              ),
            )
          else if (_feedbackHistory.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        size: 48,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No feedback submitted yet',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share your thoughts to help us improve!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Feedback history list (show last 3)
            Column(
              children: [
                ..._feedbackHistory.take(3).map((feedback) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          feedback_model.FeedbackType.getIcon(feedback.feedbackType),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        feedback_model.FeedbackType.getLabel(feedback.feedbackType),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            feedback.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (feedback.created != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(feedback.created!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: feedback.status != null
                          ? Chip(
                              label: Text(
                                feedback_model.FeedbackStatus.getLabel(feedback.status!),
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                  ),
                )),
                
                if (_feedbackHistory.length > 3)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to full feedback history screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full feedback history view coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: Text('View all ${_feedbackHistory.length} feedback'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? "s" : ""} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

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
          }).toList(),
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

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
