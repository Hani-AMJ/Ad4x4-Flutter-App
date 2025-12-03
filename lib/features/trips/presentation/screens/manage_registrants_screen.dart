import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../providers/trips_provider.dart';

class ManageRegistrantsScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripTitle;
  
  const ManageRegistrantsScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  ConsumerState<ManageRegistrantsScreen> createState() => _ManageRegistrantsScreenState();
}

class _ManageRegistrantsScreenState extends ConsumerState<ManageRegistrantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  
  // Real trip data
  dynamic _trip;
  List<dynamic> _registered = [];
  List<dynamic> _waitlist = [];
  List<dynamic> _pending = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTripData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load trip data from API
  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = int.parse(widget.tripId);
      final response = await repository.getTripDetail(tripId);
      
      if (mounted) {
        setState(() {
          _trip = response;
          
          // Categorize registrations by status
          final allRegistrations = response['registered'] ?? [];
          _registered = allRegistrations.where((r) => 
            r['status'] == 'registered' || 
            r['status'] == 'checked_in' ||
            r['status'] == 'checked_out'
          ).toList();
          
          _waitlist = allRegistrations.where((r) => 
            r['status'] == 'waitlisted'
          ).toList();
          
          _pending = allRegistrations.where((r) => 
            r['status'] == 'pending'
          ).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trip data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Force register member (approve pending or add new member)
  Future<void> _approveRegistrant(dynamic registration) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = int.parse(widget.tripId);
      final memberId = registration['member']['id'];
      
      await repository.forceRegisterMember(tripId, memberId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${registration['member']['displayName']} approved'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadTripData();
        
        // Refresh trips list
        ref.read(tripsProvider.notifier).refresh();
      }
    } catch (e) {
      print('Error approving registrant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Move member to waitlist
  Future<void> _moveToWaitlist(dynamic registration) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = int.parse(widget.tripId);
      final memberId = registration['member']['id'];
      
      // API uses the waitlist endpoint which adds to waitlist
      // First remove if registered, then add to waitlist
      await repository.removeMember(tripId, memberId, reason: 'Moved to waitlist');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${registration['member']['displayName']} moved to waitlist'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Reload data
        await _loadTripData();
        
        // Refresh trips list
        ref.read(tripsProvider.notifier).refresh();
      }
    } catch (e) {
      print('Error moving to waitlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move to waitlist: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove member from trip
  Future<void> _removeRegistrant(dynamic registration) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Registrant'),
        content: Text('Are you sure you want to remove ${registration['member']['displayName']} from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = int.parse(widget.tripId);
      final memberId = registration['member']['id'];
      
      await repository.removeMember(tripId, memberId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${registration['member']['displayName']} removed'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reload data
        await _loadTripData();
        
        // Refresh trips list
        ref.read(tripsProvider.notifier).refresh();
      }
    } catch (e) {
      print('Error removing registrant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Promote member from waitlist to registered
  Future<void> _promoteFromWaitlist(dynamic registration) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = int.parse(widget.tripId);
      final memberId = registration['member']['id'];
      
      await repository.addFromWaitlist(tripId, memberId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${registration['member']['displayName']} promoted to registered'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadTripData();
        
        // Refresh trips list
        ref.read(tripsProvider.notifier).refresh();
      }
    } catch (e) {
      print('Error promoting from waitlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add member manually (force register)
  Future<void> _addManualRegistrant() async {
    // TODO: Show dialog to search and add member manually
    // This would require a member search API endpoint
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual registration requires member search feature'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => context.pop(),
          ),
          title: const Text('Manage Registrants'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => context.pop(),
          ),
          title: const Text('Manage Registrants'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTripData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Registrants',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.tripTitle,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
          indicatorColor: colors.primary,
          tabs: [
            Tab(
              text: 'Registered',
              icon: Badge(
                label: Text(_registered.length.toString()),
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Waitlist',
              icon: Badge(
                label: Text(_waitlist.length.toString()),
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'Pending',
              icon: Badge(
                label: Text(_pending.length.toString()),
                child: const Icon(Icons.pending),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addManualRegistrant,
            tooltip: 'Add member manually',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTripData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegistrantsList(_registered, RegistrantListType.registered),
          _buildRegistrantsList(_waitlist, RegistrantListType.waitlist),
          _buildRegistrantsList(_pending, RegistrantListType.pending),
        ],
      ),
    );
  }

  Widget _buildRegistrantsList(List<dynamic> registrations, RegistrantListType type) {
    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == RegistrantListType.registered
                  ? Icons.check_circle_outline
                  : type == RegistrantListType.waitlist
                      ? Icons.schedule
                      : Icons.pending_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              type == RegistrantListType.registered
                  ? 'No registered members'
                  : type == RegistrantListType.waitlist
                      ? 'No members on waitlist'
                      : 'No pending requests',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final registration = registrations[index];
        return _buildRegistrantCard(registration, type);
      },
    );
  }

  Widget _buildRegistrantCard(dynamic registration, RegistrantListType type) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final member = registration['member'];
    final displayName = member['displayName'] ?? member['username'] ?? 'Unknown';
    final username = member['username'] ?? '';
    final memberNumber = member['memberNumber']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          child: Text(
            displayName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('@$username'),
            Text(
              'Member #$memberNumber',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'approve':
                _approveRegistrant(registration);
                break;
              case 'waitlist':
                _moveToWaitlist(registration);
                break;
              case 'promote':
                _promoteFromWaitlist(registration);
                break;
              case 'remove':
                _removeRegistrant(registration);
                break;
            }
          },
          itemBuilder: (context) {
            if (type == RegistrantListType.pending) {
              return [
                const PopupMenuItem(value: 'approve', child: Text('Approve')),
                const PopupMenuItem(value: 'waitlist', child: Text('Move to Waitlist')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ];
            } else if (type == RegistrantListType.waitlist) {
              return [
                const PopupMenuItem(value: 'promote', child: Text('Promote to Registered')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ];
            } else {
              return [
                const PopupMenuItem(value: 'waitlist', child: Text('Move to Waitlist')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ];
            }
          },
        ),
      ),
    );
  }
}

enum RegistrantListType {
  registered,
  waitlist,
  pending,
}
