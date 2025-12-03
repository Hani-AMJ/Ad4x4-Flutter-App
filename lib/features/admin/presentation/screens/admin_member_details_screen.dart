import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/trip_statistics.dart'; // ✅ NEW: Import TripStatistics
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Member Details Screen
/// 
/// Detailed member profile view for administrators.
/// Features:
/// - View complete member profile
/// - View trip history
/// - View member statistics
/// - Contact information
class AdminMemberDetailsScreen extends ConsumerStatefulWidget {
  final int memberId;

  const AdminMemberDetailsScreen({
    super.key,
    required this.memberId,
  });

  @override
  ConsumerState<AdminMemberDetailsScreen> createState() => _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends ConsumerState<AdminMemberDetailsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _errorMessage;
  BasicMember? _member;
  List<TripListItem> _tripHistory = [];
  TripStatistics? _tripStats; // ✅ NEW: Store trip statistics

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemberData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // ✅ Load member details, trip history, and trip statistics in parallel
      final results = await Future.wait([
        repository.getMemberDetail(widget.memberId),
        repository.getMemberTripHistory(memberId: widget.memberId, pageSize: 50),
        repository.getMemberTripCounts(widget.memberId), // ✅ NEW: Load trip statistics
      ]);

      final memberJson = results[0];
      final tripHistoryJson = results[1];
      final tripStatsJson = results[2]; // ✅ NEW

      final member = BasicMember.fromJson(memberJson);
      final tripsData = tripHistoryJson['results'] as List<dynamic>? ?? [];
      final trips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // ✅ NEW: Parse trip statistics
      final statsData = tripStatsJson['data'] ?? tripStatsJson['results'] ?? tripStatsJson;
      final tripStats = TripStatistics.fromJson(statsData is Map<String, dynamic> ? statsData : {});

      setState(() {
        _member = member;
        _tripHistory = trips;
        _tripStats = tripStats; // ✅ NEW: Store trip statistics
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load member: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permission - user must have view_members permission
    final canView = user?.hasPermission('view_members') ?? false;
    
    if (!canView) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin/members'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'View Members Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to view member details.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin/members'),
                child: const Text('Back to Members'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          if (!_isLoading && _member != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Member',
              onPressed: () async {
                final result = await context.push('/admin/members/${widget.memberId}/edit');
                if (result == true && mounted) {
                  _loadMemberData(); // Refresh data after edit
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemberData,
          ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Profile', icon: Icon(Icons.person)),
                  Tab(text: 'Trip History', icon: Icon(Icons.history)),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMemberData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_member == null) {
      return const Center(child: Text('Member not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildTripHistoryTab(),
      ],
    );
  }

  Widget _buildProfileTab() {
    final member = _member!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar and basic info
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: member.profileImage != null
                    ? NetworkImage(member.profileImage!)
                    : null,
                child: member.profileImage == null
                    ? Text(
                        member.displayName.split(' ').map((n) => n[0]).take(2).join(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                member.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${member.username}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              
              // Status badges
              Wrap(
                spacing: 8,
                children: [
                  if (member.paidMember == true)
                    Chip(
                      avatar: const Icon(Icons.verified, size: 16),
                      label: const Text('Paid Member'),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                  if (member.level != null)
                    Chip(
                      avatar: const Icon(Icons.terrain, size: 16),
                      label: Text('Level: ${member.level}'),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Contact Information
        _SectionHeader(title: 'Contact Information'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (member.email != null)
                _InfoTile(
                  icon: Icons.email,
                  label: 'Email',
                  value: member.email!,
                  onTap: () async {
                    final uri = Uri(scheme: 'mailto', path: member.email);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch email client')),
                        );
                      }
                    }
                  },
                ),
              if (member.phone != null)
                _InfoTile(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: member.phone!,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: member.phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch phone dialer')),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Vehicle Information
        if (member.carBrand != null || member.carModel != null) ...[
          _SectionHeader(title: 'Vehicle Information'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (member.carBrand != null || member.carModel != null)
                  _InfoTile(
                    icon: Icons.directions_car,
                    label: 'Vehicle',
                    value: '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim(),
                  ),
                if (member.carColor != null)
                  _InfoTile(
                    icon: Icons.palette,
                    label: 'Color',
                    value: member.carColor!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Statistics
        _SectionHeader(title: 'Statistics'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ✅ NEW: Show segregated trip counts
                _StatItem(
                  icon: Icons.star,
                  label: 'Trips Lead',
                  value: '${_tripStats?.asLeadTrips ?? 0}',
                  iconColor: Colors.amber,
                ),
                _StatItem(
                  icon: Icons.directions_car,
                  label: 'Trips Joined',
                  value: '${(_tripStats?.totalTrips ?? member.tripCount ?? 0) - (_tripStats?.asLeadTrips ?? 0)}',
                ),
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Member ID',
                  value: '#${member.id}',
                ),
              ],
            ),
          ),
        ),
        
        // ✅ NEW: Leadership Statistics Section (if member has leadership experience)
        if (_tripStats != null && _tripStats!.hasLeadershipExperience) ...[
          const SizedBox(height: 16),
          _buildLeadershipStatsSection(),
        ],
      ],
    );
  }

  Widget _buildTripHistoryTab() {
    if (_tripHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Trip History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This member has not joined any trips yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tripHistory.length,
      itemBuilder: (context, index) {
        final trip = _tripHistory[index];
        return _TripHistoryCard(trip: trip);
      },
    );
  }
  
  /// ✅ NEW: Build leadership statistics section
  Widget _buildLeadershipStatsSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    if (_tripStats == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Leadership Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Leadership Stats Grid
            Row(
              children: [
                Expanded(
                  child: _LeadershipStatCard(
                    icon: Icons.star,
                    label: 'As Lead',
                    value: _tripStats!.asLeadTrips.toString(),
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LeadershipStatCard(
                    icon: Icons.shield,
                    label: 'As Marshal',
                    value: _tripStats!.asMarshalTrips.toString(),
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LeadershipStatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: _tripStats!.completedTrips.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LeadershipStatCard(
                    icon: Icons.upcoming,
                    label: 'Upcoming',
                    value: _tripStats!.upcomingTrips.toString(),
                    color: Colors.blue,
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: onTap != null ? const Icon(Icons.open_in_new, size: 16) : null,
      onTap: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor; // ✅ NEW: Optional icon color

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor, // ✅ NEW: Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary; // ✅ Use iconColor if provided

    return Column(
      children: [
        Icon(icon, size: 32, color: color), // ✅ Use custom color
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color, // ✅ Use custom color
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// ✅ NEW: Leadership stat card widget for member details
class _LeadershipStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LeadershipStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  final TripListItem trip;

  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _TripStatusBadge(status: trip.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(trip.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.terrain, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    trip.level.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripStatusBadge extends StatelessWidget {
  final String status;

  const _TripStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'upcoming':
        color = Colors.blue;
        label = 'Upcoming';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'ongoing':
        color = Colors.orange;
        label = 'Ongoing';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
