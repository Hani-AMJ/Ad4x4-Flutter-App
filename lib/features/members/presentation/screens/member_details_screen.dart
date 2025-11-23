import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/utils/level_display_helper.dart';

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
  bool _isLoading = true;
  bool _isLoadingTrips = true;
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
      print('👤 [MemberDetails] Fetching profile for member $memberId...');
      final profileResponse = await _repository.getMemberDetail(memberId);
      final member = UserModel.fromJson(profileResponse['data'] ?? profileResponse);
      
      setState(() {
        _member = member;
        _isLoading = false;
      });

      // Load trip history in background
      _loadTripHistory(memberId);
    } catch (e) {
      print('❌ [MemberDetails] Error: $e');
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

  /// Load trip history
  Future<void> _loadTripHistory(int memberId) async {
    setState(() => _isLoadingTrips = true);

    try {
      print('🚗 [MemberDetails] Fetching trip history for member $memberId...');
      
      final response = await _repository.getMemberTripHistory(
        memberId: memberId,
        page: 1,
        pageSize: 10,
      );

      final List<TripListItem> trips = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            trips.add(TripListItem.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [MemberDetails] Error parsing trip: $e');
          }
        }
      }

      print('✅ [MemberDetails] Loaded ${trips.length} trips');
      setState(() {
        _tripHistory = trips;
        _isLoadingTrips = false;
      });
    } catch (e) {
      print('❌ [MemberDetails] Error loading trips: $e');
      setState(() {
        _tripHistory = [];
        _isLoadingTrips = false;
      });
    }
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
            expandedHeight: 200,
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
                      value: '${member.level?.numericLevel ?? 0}',
                      color: const Color(0xFFFFB74D),
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
