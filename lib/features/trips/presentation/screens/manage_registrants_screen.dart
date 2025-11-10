import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageRegistrantsScreen extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  
  const ManageRegistrantsScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  State<ManageRegistrantsScreen> createState() => _ManageRegistrantsScreenState();
}

class _ManageRegistrantsScreenState extends State<ManageRegistrantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Sample data - TODO: Replace with actual API calls
  final List<Registrant> _registered = [
    Registrant(id: '1', name: 'Mohammed Al-Zaabi', memberNumber: 'M2001', vehicle: 'Toyota Land Cruiser', status: RegistrationStatus.approved),
    Registrant(id: '2', name: 'Ahmad Al-Mansoori', memberNumber: 'M2015', vehicle: 'Nissan Patrol', status: RegistrationStatus.approved),
    Registrant(id: '3', name: 'Khalid Al-Dhaheri', memberNumber: 'M2032', vehicle: 'Jeep Wrangler', status: RegistrationStatus.approved),
    Registrant(id: '4', name: 'Saif Al-Ketbi', memberNumber: 'M2048', vehicle: 'Toyota FJ Cruiser', status: RegistrationStatus.approved),
  ];
  
  final List<Registrant> _waitlist = [
    Registrant(id: '5', name: 'Abdullah Al-Mazrouei', memberNumber: 'M2065', vehicle: 'Ford Raptor', status: RegistrationStatus.waitlisted),
    Registrant(id: '6', name: 'Rashid Al-Blooshi', memberNumber: 'M2078', vehicle: 'GMC Sierra', status: RegistrationStatus.waitlisted),
  ];
  
  final List<Registrant> _pending = [
    Registrant(id: '7', name: 'Salem Al-Kaabi', memberNumber: 'M2091', vehicle: 'Chevrolet Tahoe', status: RegistrationStatus.pending),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveRegistrant(Registrant registrant) async {
    setState(() => _isLoading = true);
    
    // TODO: API call to approve registrant
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _pending.remove(registrant);
        _registered.add(registrant.copyWith(status: RegistrationStatus.approved));
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${registrant.name} approved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _moveToWaitlist(Registrant registrant) async {
    setState(() => _isLoading = true);
    
    // TODO: API call to move to waitlist
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        if (_registered.contains(registrant)) {
          _registered.remove(registrant);
        } else if (_pending.contains(registrant)) {
          _pending.remove(registrant);
        }
        _waitlist.add(registrant.copyWith(status: RegistrationStatus.waitlisted));
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${registrant.name} moved to waitlist'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _removeRegistrant(Registrant registrant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Registrant'),
        content: Text('Are you sure you want to remove ${registrant.name} from this trip?'),
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
    
    setState(() => _isLoading = true);
    
    // TODO: API call to remove registrant
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _registered.remove(registrant);
        _waitlist.remove(registrant);
        _pending.remove(registrant);
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${registrant.name} removed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _promoteFromWaitlist(Registrant registrant) async {
    setState(() => _isLoading = true);
    
    // TODO: API call to promote from waitlist
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _waitlist.remove(registrant);
        _registered.add(registrant.copyWith(status: RegistrationStatus.approved));
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${registrant.name} promoted to registered'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addManualRegistrant() async {
    // TODO: Show dialog to search and add member manually
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual registration coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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

  Widget _buildRegistrantsList(List<Registrant> registrants, RegistrantListType type) {
    if (registrants.isEmpty) {
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
      itemCount: registrants.length,
      itemBuilder: (context, index) {
        final registrant = registrants[index];
        return _buildRegistrantCard(registrant, type);
      },
    );
  }

  Widget _buildRegistrantCard(Registrant registrant, RegistrantListType type) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          child: Text(
            registrant.name.split(' ').map((n) => n[0]).take(2).join(),
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          registrant.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Member #${registrant.memberNumber}'),
            Text(
              registrant.vehicle,
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
                _approveRegistrant(registrant);
                break;
              case 'waitlist':
                _moveToWaitlist(registrant);
                break;
              case 'promote':
                _promoteFromWaitlist(registrant);
                break;
              case 'remove':
                _removeRegistrant(registrant);
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

// Models
class Registrant {
  final String id;
  final String name;
  final String memberNumber;
  final String vehicle;
  final RegistrationStatus status;

  Registrant({
    required this.id,
    required this.name,
    required this.memberNumber,
    required this.vehicle,
    required this.status,
  });

  Registrant copyWith({
    String? id,
    String? name,
    String? memberNumber,
    String? vehicle,
    RegistrationStatus? status,
  }) {
    return Registrant(
      id: id ?? this.id,
      name: name ?? this.name,
      memberNumber: memberNumber ?? this.memberNumber,
      vehicle: vehicle ?? this.vehicle,
      status: status ?? this.status,
    );
  }
}

enum RegistrationStatus {
  approved,
  pending,
  waitlisted,
  declined,
}

enum RegistrantListType {
  registered,
  waitlist,
  pending,
}
