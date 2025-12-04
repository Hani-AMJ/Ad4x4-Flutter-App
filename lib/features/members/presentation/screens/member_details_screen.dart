import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/trip_statistics.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../../../../core/services/error_log_service.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  final _repository = MainApiRepository();
  
  UserModel? _member;
  List<TripListItem> _tripHistory = [];
  TripStatistics? _tripStatistics;  // ✅ NEW: Phase 2 - Trip statistics (enhanced model)
  List<Map<String, dynamic>> _upgradeHistory = [];  // ✅ NEW: Phase 3 - Upgrade requests
  List<Map<String, dynamic>> _tripRequests = [];  // ✅ NEW: Phase 3 - Trip requests
  List<Map<String, dynamic>> _memberFeedback = [];  // ✅ NEW: Phase 3 - Member feedback
  
  bool _isLoading = true;
  bool _isLoadingTrips = true;
  bool _isLoadingStats = true;  // ✅ NEW: Phase 2
  bool _isLoadingUpgrades = true;  // ✅ NEW: Phase 3
  bool _isLoadingRequests = true;  // ✅ NEW: Phase 3
  bool _isLoadingFeedback = true;  // ✅ NEW: Phase 3
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  /// Load member profile and trip history
  Future<void> _loadMemberData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final memberId = int.parse(widget.memberId);
      
      // Load member profile
      if (kDebugMode) {
        print('👤 [MemberDetails] Fetching profile for member $memberId...');
      }
      final profileResponse = await _repository.getMemberDetail(memberId);
      final member = UserModel.fromJson(profileResponse['data'] ?? profileResponse);
      
      setState(() {
        _member = member;
        _isLoading = false;
      });

      // Load all additional data in background
      _loadTripHistory(memberId);
      _loadTripStatistics(memberId);  // ✅ NEW: Phase 2
      _loadUpgradeHistory(memberId);  // ✅ NEW: Phase 3
      _loadTripRequests(memberId);  // ✅ NEW: Phase 3
      _loadMemberFeedback(memberId);  // ✅ NEW: Phase 3
    } catch (e) {
      if (kDebugMode) {
        print('❌ [MemberDetails] Error: $e');
      }
      setState(() {
        _error = 'Failed to load member profile';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load trip history (completed trips only)
  Future<void> _loadTripHistory(int memberId) async {
    setState(() => _isLoadingTrips = true);

    try {
      if (kDebugMode) {
        print('🚗 [MemberDetails] Fetching completed trip history for member $memberId...');
      }
      
      final response = await _repository.getMemberTripHistory(
        memberId: memberId,
        checkedIn: true,  // ✅ FIXED: Only fetch trips where member was checked in
        page: 1,
        pageSize: 10,
      );

      final List<TripListItem> trips = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            final trip = TripListItem.fromJson(item as Map<String, dynamic>);
            // ✅ FIXED: Additional filter for completed trips only
            if (trip.status == 'completed' || DateTime.now().isAfter(trip.endTime)) {
              trips.add(trip);
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ [MemberDetails] Error parsing trip: $e');
            }
          }
        }
      }

      if (kDebugMode) {
        print('✅ [MemberDetails] Loaded ${trips.length} completed trips');
      }
      setState(() {
        _tripHistory = trips;
        _isLoadingTrips = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [MemberDetails] Error loading trips: $e');
      }
      setState(() {
        _tripHistory = [];
        _isLoadingTrips = false;
      });
    }
  }

  /// Load trip statistics (Phase 2)
  /// ✅ NEW: Shows breakdown of trips by level
  Future<void> _loadTripStatistics(int memberId) async {
    setState(() => _isLoadingStats = true);

    try {
      debugPrint('📊 [MemberDetails] Fetching trip statistics for member $memberId...');
      
      final response = await _repository.getMemberTripCounts(memberId);

      // ALWAYS log the raw response (unconditional - not wrapped in kDebugMode)
      debugPrint('✅ [MemberDetails] Loaded trip statistics for member $memberId');
      debugPrint('   Raw Response: $response');
      debugPrint('   Response Type: ${response.runtimeType}');
      debugPrint('   Response Keys: ${response is Map ? response.keys.toList() : 'Not a map'}');
      
      // Safe extraction of data
      Map<String, dynamic> rawData;
      if (response is Map<String, dynamic>) {
        // Handle wrapped response: {"data": {...}} or direct response
        if (response.containsKey('data') && response['data'] != null) {
          rawData = response['data'] is Map<String, dynamic> 
              ? response['data'] as Map<String, dynamic>
              : Map<String, dynamic>.from(response['data'] as Map);
        } else {
          rawData = response;
        }
      } else {
        debugPrint('⚠️ [MemberDetails] Unexpected response type: ${response.runtimeType}');
        debugPrint('   Raw Data: $response');
        debugPrint('   Available Keys: ${response is Map ? (response as Map).keys : 'N/A'}');
        rawData = {};
      }

      debugPrint('   Raw Data Content: $rawData');

      // Use TripStatistics model to parse the response
      // The model handles both NEW API format (tripStats array) and OLD format
      final tripStats = TripStatistics.fromJson(rawData);
      
      debugPrint('   ✅ Parsed Trip Statistics:');
      debugPrint('      Total: ${tripStats.totalTrips}');
      debugPrint('      Completed: ${tripStats.completedTrips}');
      debugPrint('      Upcoming: ${tripStats.upcomingTrips}');
      debugPrint('      Level 1 (Club Event): ${tripStats.level1Trips}');
      debugPrint('      Level 2 (Newbie): ${tripStats.level2Trips}');
      debugPrint('      Level 3 (Intermediate): ${tripStats.level3Trips}');
      debugPrint('      Level 4 (Advanced): ${tripStats.level4Trips}');
      debugPrint('      Level 5 (Expert): ${tripStats.level5Trips}');
      debugPrint('      As Lead: ${tripStats.asLeadTrips}');
      debugPrint('      As Marshal: ${tripStats.asMarshalTrips}');
      debugPrint('      Attendance Rate: ${tripStats.attendanceRate}%');

      setState(() {
        _tripStatistics = tripStats;
        _isLoadingStats = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [MemberDetails] Error loading trip statistics: $e');
      debugPrint('   Stack Trace: $stackTrace');
      
      // Detect error type and log to ErrorLogService
      final errorType = _detectErrorType(e);
      await ErrorLogService().logError(
        message: 'Failed to load trip statistics: $e',
        stackTrace: stackTrace.toString(),
        type: errorType,
        context: 'MemberDetailsScreen - Trip Statistics (Widget 5)',
      );
      
      setState(() {
        _tripStatistics = null;
        _isLoadingStats = false;
      });
    }
  }

  /// Load upgrade history (Phase 3)
  /// ✅ NEW: Shows member's level progression timeline
  Future<void> _loadUpgradeHistory(int memberId) async {
    setState(() => _isLoadingUpgrades = true);

    try {
      if (kDebugMode) {
        print('⬆️ [MemberDetails] Fetching upgrade history for member $memberId...');
      }
      
      final response = await _repository.getMemberUpgradeRequests(memberId: memberId, page: 1, pageSize: 10);

      final List<Map<String, dynamic>> upgrades = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          upgrades.add(item as Map<String, dynamic>);
        }
      }

      if (kDebugMode) {
        print('✅ [MemberDetails] Loaded ${upgrades.length} upgrade requests');
      }
      setState(() {
        _upgradeHistory = upgrades;
        _isLoadingUpgrades = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [MemberDetails] Error loading upgrade history: $e');
      }
      setState(() {
        _upgradeHistory = [];
        _isLoadingUpgrades = false;
      });
    }
  }

  /// Load trip requests (Phase 3)
  /// ✅ NEW: Shows trips member has requested from marshals
  Future<void> _loadTripRequests(int memberId) async {
    setState(() => _isLoadingRequests = true);

    try {
      if (kDebugMode) {
        print('📝 [MemberDetails] Fetching trip requests for member $memberId...');
      }
      
      final response = await _repository.getMemberTripRequests(memberId: memberId, page: 1, pageSize: 10);

      final List<Map<String, dynamic>> requests = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          requests.add(item as Map<String, dynamic>);
        }
      }

      if (kDebugMode) {
        print('✅ [MemberDetails] Loaded ${requests.length} trip requests');
      }
      setState(() {
        _tripRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [MemberDetails] Error loading trip requests: $e');
      }
      setState(() {
        _tripRequests = [];
        _isLoadingRequests = false;
      });
    }
  }

  /// Load member feedback (Phase 3)
  /// ✅ NEW: Shows ratings and reviews for member
  Future<void> _loadMemberFeedback(int memberId) async {
    setState(() => _isLoadingFeedback = true);

    try {
      if (kDebugMode) {
        print('⭐ [MemberDetails] Fetching feedback for member $memberId...');
      }
      
      final response = await _repository.getMemberFeedback(memberId: memberId, page: 1, pageSize: 10);

      final List<Map<String, dynamic>> feedback = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          feedback.add(item as Map<String, dynamic>);
        }
      }

      if (kDebugMode) {
        print('✅ [MemberDetails] Loaded ${feedback.length} feedback entries');
      }
      setState(() {
        _memberFeedback = feedback;
        _isLoadingFeedback = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [MemberDetails] Error loading feedback: $e');
      }
      setState(() {
        _memberFeedback = [];
        _isLoadingFeedback = false;
      });
    }
  }

  /// Get level stars emoji based on level name
  /// Uses the same logic as LevelConfigurationService
  String _getLevelStars(UserLevel? level) {
    if (level == null) return '⭐';
    
    final levelName = level.displayName ?? level.name ?? '';
    final cleanName = levelName.toLowerCase();
    
    // Match the logic from LevelConfigurationService.getLevelEmoji()
    if (cleanName.contains('board')) return '🎖️'; // Badge for Board Member
    if (cleanName.contains('marshal')) return '⭐⭐⭐⭐⭐'; // 5 stars
    if (cleanName.contains('expert') || cleanName.contains('explorer')) return '⭐⭐⭐⭐'; // 4 stars
    if (cleanName.contains('advanced') || cleanName.contains('advance')) return '⭐⭐⭐'; // 3 stars
    if (cleanName.contains('intermediate')) return '⭐⭐'; // 2 stars
    if (cleanName.contains('anit')) return '⭐'; // 1 star (same as Newbie)
    if (cleanName.contains('newbie') || cleanName.contains('beginner')) return '⭐'; // 1 star
    
    return '⭐'; // Default: 1 star
  }

  /// Detect error type for intelligent error handling
  String _detectErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission_denied') || 
        errorString.contains('unauthorized') ||
        errorString.contains('403')) {
      return 'unauthorized';
    }
    
    if (errorString.contains('not_found') || errorString.contains('404')) {
      return 'not_found';
    }
    
    if (errorString.contains('network') || 
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'network';
    }
    
    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503')) {
      return 'server_error';
    }
    
    return 'exception';
  }

  /// Build enhanced statistics section (copied from profile_screen.dart)
  /// Shows detailed trip statistics with beautiful gradient cards
  Widget _buildEnhancedStatsSection(BuildContext context, ThemeData theme, ColorScheme colors, int memberId) {
    if (_tripStatistics == null) {
      return const SizedBox.shrink();
    }

    final stats = _tripStatistics!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Participation Stats (Completed/Upcoming)
          Row(
            children: [
              Expanded(
                child: _StatsCard(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: stats.completedTrips.toString(),
                  color: Colors.green,
                  onTap: () {
                    context.push(
                      '/trips/filtered/$memberId?filterType=completed&title=Completed Trips (${stats.completedTrips})',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatsCard(
                  icon: Icons.upcoming,
                  label: 'Upcoming',
                  value: stats.upcomingTrips.toString(),
                  color: Colors.blue,
                  onTap: () {
                    context.push(
                      '/trips/filtered/$memberId?filterType=upcoming&title=Upcoming Trips (${stats.upcomingTrips})',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Leadership Stats (conditional)
          if (stats.hasLeadershipExperience) ...[
            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    icon: Icons.star,
                    label: 'As Lead',
                    value: stats.asLeadTrips.toString(),
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    icon: Icons.shield,
                    label: 'As Marshal',
                    value: stats.asMarshalTrips.toString(),
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
                    final count = stats.getTripCountByLevel(level);
                    final levelLabel = LevelDisplayHelper.getTripLevelLabel(level);

                    // Map level index to numeric level for colors
                    int levelNumeric;
                    Color levelColor;
                    IconData levelIcon;

                    switch (level) {
                      case 1:
                        levelNumeric = 5; // Club Event
                        levelColor = const Color(0xFF4CAF50);
                        levelIcon = Icons.groups;
                        break;
                      case 2:
                        levelNumeric = 10; // Newbie/ANIT
                        levelColor = const Color(0xFF4CAF50);
                        levelIcon = Icons.school;
                        break;
                      case 3:
                        levelNumeric = 100; // Intermediate
                        levelColor = const Color(0xFF2196F3);
                        levelIcon = Icons.terrain;
                        break;
                      case 4:
                        levelNumeric = 200; // Advanced
                        levelColor = const Color(0xFFE91E63);
                        levelIcon = Icons.landscape;
                        break;
                      case 5:
                        levelNumeric = 300; // Expert
                        levelColor = const Color(0xFF9C27B0);
                        levelIcon = Icons.workspace_premium;
                        break;
                      default:
                        levelNumeric = 0;
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
                          onTap: count > 0
                              ? () {
                                  context.push(
                                    '/trips/filtered/$memberId?filterType=level&levelNumeric=$levelNumeric&title=$levelLabel Trips ($count)',
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

          // Attendance Rate (conditional)
          if (stats.attendanceRate > 0) ...[
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
                            Icons.check_circle,
                            color: colors.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Rate',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stats.checkedInCount} of ${stats.totalTrips} trips',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${stats.attendanceRate.toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: const LoadingIndicator(message: 'Loading member...'),
      );
    }

    if (_error != null || _member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: ErrorState(
          message: _error ?? 'Member not found',
          onRetry: _loadMemberData,
        ),
      );
    }

    final member = _member!;
    final memberName = '${member.firstName} ${member.lastName}'.trim();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Member Header
          SliverAppBar(
            expandedHeight: 280,  // ✅ FIXED: Increased from 200 to prevent cropping
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.3),
                      colors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      UserAvatar(
                        name: memberName,
                        imageUrl: member.avatar != null && member.avatar!.isNotEmpty
                            ? (member.avatar!.startsWith('http')
                                ? member.avatar
                                : 'https://media.ad4x4.com${member.avatar}')
                            : null,
                        radius: 50,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        memberName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ✅ FIXED: Wrap level badge in proper constraints to prevent cropping
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: member.level != null
                              ? LevelDisplayHelper.buildCompactBadgeFromString(
                                  levelName: member.level!.displayName ?? member.level!.name,
                                  numericLevel: member.level!.numericLevel,
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Member',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // ✅ NEW: Phase 2 - Member Since Date
                      if (member.dateJoined != null && member.dateJoined!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Member since ${_formatMemberSinceDate(member.dateJoined!)}',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_car,
                      label: 'Trips',
                      value: '${member.tripCount ?? 0}',
                      color: const Color(0xFF64B5F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      label: 'Level',
                      value: _getLevelStars(member.level),  // ✅ FIXED: Show stars instead of text
                      color: LevelDisplayHelper.getLevelColor(member.level?.numericLevel ?? 0),  // ✅ FIXED: Dynamic color
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.card_membership,
                      label: 'Status',
                      value: member.paidMember ? 'Paid' : 'Free',
                      color: member.paidMember ? const Color(0xFF81C784) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contact Info (if available)
          if ((member.email?.isNotEmpty ?? false) || (member.phone?.isNotEmpty ?? false))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (member.email != null)
                      InfoCard(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: member.email!,
                        iconColor: const Color(0xFF64B5F6),
                      ),
                    if (member.phone != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: InfoCard(
                          icon: Icons.phone,
                          title: 'Phone',
                          subtitle: member.phone!,
                          iconColor: const Color(0xFF81C784),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

          // Vehicle Info (if available)
          if (member.carBrand != null || member.carModel != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.directions_car,
                      title: 'Vehicle',
                      subtitle: '${member.carBrand ?? ''} ${member.carModel ?? ''} ${member.carYear != null ? '(${member.carYear})' : ''}'.trim(),
                      iconColor: const Color(0xFFFFB74D),
                    ),
                    if (member.carColor != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: InfoCard(
                          icon: Icons.palette,
                          title: 'Color',
                          subtitle: member.carColor!,
                          iconColor: const Color(0xFFBA68C8),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

          // ✅ ENHANCED: Phase 2 - Trip Statistics Section (matching profile_screen.dart)
          if (!_isLoadingStats && _tripStatistics != null)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildEnhancedStatsSection(context, theme, colors, int.parse(widget.memberId)),
                  const SizedBox(height: 24),
                ],
              ),
            ),

          // ✅ NEW: Phase 3 - Upgrade History Section
          if (!_isLoadingUpgrades && _upgradeHistory.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Progress',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

          // ✅ NEW: Phase 3 - Upgrade History List
          if (!_isLoadingUpgrades && _upgradeHistory.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final upgrade = _upgradeHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _UpgradeHistoryCard(upgrade: upgrade),
                  );
                },
                childCount: _upgradeHistory.length,
              ),
            ),

          if (!_isLoadingUpgrades && _upgradeHistory.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ✅ NEW: Phase 3 - Trip Requests Section
          if (!_isLoadingRequests && _tripRequests.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Requests',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trips requested from marshals',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

          // ✅ NEW: Phase 3 - Trip Requests List
          if (!_isLoadingRequests && _tripRequests.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final request = _tripRequests[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _TripRequestCard(request: request),
                  );
                },
                childCount: _tripRequests.length,
              ),
            ),

          if (!_isLoadingRequests && _tripRequests.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ✅ NEW: Phase 3 - Member Feedback Section
          if (!_isLoadingFeedback && _memberFeedback.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Feedback',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

          // ✅ NEW: Phase 3 - Member Feedback List
          if (!_isLoadingFeedback && _memberFeedback.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final feedback = _memberFeedback[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _MemberFeedbackCard(feedback: feedback),
                  );
                },
                childCount: _memberFeedback.length,
              ),
            ),

          if (!_isLoadingFeedback && _memberFeedback.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Trip History Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recent Trips',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingTrips) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Trip History List
          if (!_isLoadingTrips && _tripHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'No Trip History',
                  message: 'This member has not participated in any trips yet',
                ),
              ),
            ),

          if (_tripHistory.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = _tripHistory[index];
                  // ✅ FIXED: Add error boundary for trip card rendering
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Builder(
                      builder: (context) {
                        try {
                          return _TripHistoryCard(trip: trip);
                        } catch (e) {
                          if (kDebugMode) {
                            debugPrint('❌ Error rendering trip card: $e');
                          }
                          // Fallback: Show error message
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: colors.error),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error loading trip details',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: _tripHistory.length,
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  /// Format member since date
  /// ✅ NEW: Phase 2 - Helper method
  String _formatMemberSinceDate(String dateJoined) {
    try {
      final date = DateTime.parse(dateJoined);
      return DateFormat('MMMM yyyy').format(date);  // e.g., "January 2020"
    } catch (e) {
      return 'Recently';
    }
  }

}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trip History Card Widget
class _TripHistoryCard extends StatelessWidget {
  final TripListItem trip;

  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Trip Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Trip Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y').format(trip.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(trip.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trip.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(trip.status),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF388E3C);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'upcoming':
        return const Color(0xFF1976D2);
      default:
        return Colors.grey;
    }
  }
}

/// ✅ NEW: Phase 2 - Trip Statistics Card Widget
/// ✅ NEW: Phase 3 - Upgrade History Card Widget
class _UpgradeHistoryCard extends StatelessWidget {
  final Map<String, dynamic> upgrade;

  const _UpgradeHistoryCard({required this.upgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Parse upgrade data
    final requestedLevel = upgrade['requestedLevel'] ?? upgrade['requested_level'];
    final currentLevel = upgrade['currentLevel'] ?? upgrade['current_level'];
    final status = (upgrade['status'] as String? ?? 'PENDING').toUpperCase();
    final created = upgrade['created'] as String?;

    // Get level names
    String requestedLevelName = 'Unknown';
    String currentLevelName = 'Unknown';

    if (requestedLevel is Map) {
      requestedLevelName = requestedLevel['name'] ?? requestedLevel['displayName'] ?? 'Unknown';
    } else if (requestedLevel is String) {
      requestedLevelName = requestedLevel;
    }

    if (currentLevel is Map) {
      currentLevelName = currentLevel['name'] ?? currentLevel['displayName'] ?? 'Unknown';
    } else if (currentLevel is String) {
      currentLevelName = currentLevel;
    }

    // Status color
    Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF388E3C);
        break;
      case 'REJECTED':
      case 'DECLINED':
        statusColor = const Color(0xFFD32F2F);
        break;
      default:
        statusColor = const Color(0xFFFFA726);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status == 'APPROVED'
                    ? Icons.arrow_upward
                    : status.contains('REJECT') || status.contains('DECLINE')
                        ? Icons.close
                        : Icons.pending,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Upgrade Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentLevelName → $requestedLevelName',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (created != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(DateTime.parse(created)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ NEW: Phase 3 - Trip Request Card Widget
class _TripRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const _TripRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Parse request data
    final level = request['level'];
    final area = request['area'] as String? ?? 'Unknown Area';
    final date = request['date'] as String?;
    final timeOfDay = request['timeOfDay'] ?? request['time_of_day'] as String? ?? 'Unknown Time';
    final status = (request['status'] as String? ?? 'PENDING').toUpperCase();

    // Get level name
    String levelName = 'Unknown';
    if (level is Map) {
      levelName = level['name'] ?? level['displayName'] ?? 'Unknown';
    } else if (level is String) {
      levelName = level;
    }

    // Status color
    Color statusColor;
    switch (status) {
      case 'APPROVED':
      case 'SCHEDULED':
        statusColor = const Color(0xFF388E3C);
        break;
      case 'REJECTED':
      case 'DECLINED':
        statusColor = const Color(0xFFD32F2F);
        break;
      default:
        statusColor = const Color(0xFFFFA726);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Trip Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Request Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$levelName • $area',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${DateFormat('MMM d, y').format(DateTime.parse(date))} • $timeOfDay'
                        : timeOfDay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ NEW: Phase 3 - Member Feedback Card Widget
class _MemberFeedbackCard extends StatelessWidget {
  final Map<String, dynamic> feedback;

  const _MemberFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Parse feedback data
    final rating = feedback['rating'] as int? ?? 0;
    final comment = feedback['comment'] as String? ?? '';
    final created = feedback['created'] as String?;
    final author = feedback['author'];

    // Get author name
    String authorName = 'Anonymous';
    if (author is Map) {
      final firstName = author['firstName'] ?? author['first_name'] ?? '';
      final lastName = author['lastName'] ?? author['last_name'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        authorName = '$firstName $lastName'.trim();
      } else {
        authorName = author['username'] ?? 'Anonymous';
      }
    } else if (author is String) {
      authorName = author;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stars and author
            Row(
              children: [
                // Star rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFA726),
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '($rating/5)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),
            // Footer with author and date
            Row(
              children: [
                Text(
                  authorName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (created != null) ...[
                  Text(
                    ' • ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(DateTime.parse(created)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Stats Card Widget (copied from profile_screen.dart)
/// Beautiful gradient card for displaying trip statistics
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
