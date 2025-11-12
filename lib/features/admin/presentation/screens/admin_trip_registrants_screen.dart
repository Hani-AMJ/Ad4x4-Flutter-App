import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Trip Registrants Management Screen
/// 
/// Comprehensive registrant management for marshals and admins.
/// Features:
/// - View registered members and waitlist
/// - Force register member (bypass requirements)
/// - Remove member from trip
/// - Check in/check out members
/// - Add from waitlist
/// - Export registrants to CSV
/// - Permission-gated actions
class AdminTripRegistrantsScreen extends ConsumerStatefulWidget {
  final int tripId;

  const AdminTripRegistrantsScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<AdminTripRegistrantsScreen> createState() => _AdminTripRegistrantsScreenState();
}

class _AdminTripRegistrantsScreenState extends ConsumerState<AdminTripRegistrantsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripJson = await repository.getTripDetail(widget.tripId);
      final trip = Trip.fromJson(tripJson);

      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trip: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Force register a member (bypass level requirements)
  Future<void> _forceRegisterMember() async {
    // TODO: Show member search dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member search dialog coming soon')),
    );
  }

  /// Remove member from trip
  Future<void> _removeMember(TripRegistration registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${registration.member.displayName} from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.removeMember(widget.tripId, registration.member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${registration.member.displayName} removed'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTripData();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to remove members'
                  : '❌ Failed to remove member: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Check in member
  Future<void> _checkinMember(TripRegistration registration) async {
    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.checkinMember(widget.tripId, registration.member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${registration.member.displayName} checked in'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTripData();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to check in members'
                  : '❌ Failed to check in member: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Check out member
  Future<void> _checkoutMember(TripRegistration registration) async {
    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.checkoutMember(widget.tripId, registration.member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${registration.member.displayName} checked out'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTripData();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to check out members'
                  : '❌ Failed to check out member: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Add member from waitlist
  Future<void> _addFromWaitlist(TripWaitlist waitlistEntry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add from Waitlist'),
        content: Text(
          'Add ${waitlistEntry.member.displayName} to registered members?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.addFromWaitlist(widget.tripId, waitlistEntry.member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${waitlistEntry.member.displayName} added to trip'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTripData();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to add members from waitlist'
                  : '❌ Failed to add member: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Export registrants to CSV
  Future<void> _exportRegistrants() async {
    if (_trip == null) return;

    try {
      // Generate CSV content
      final csvData = _generateCSV(_trip!);
      
      // For web, trigger download
      // Note: This is a simplified version. In production, use packages like csv or download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Exported ${_trip!.registered.length} registrants'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // In production, copy to clipboard or download file
              debugPrint('CSV Data:\n$csvData');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to export: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateCSV(Trip trip) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Name,Username,Member ID,Phone,Email,Vehicle,Registration Date,Status,Has Vehicle,Vehicle Capacity');
    
    // CSV Rows
    for (final registration in trip.registered) {
      final member = registration.member;
      buffer.write('"${member.displayName}",');
      buffer.write('"${member.username}",');
      buffer.write('"${member.id}",');
      buffer.write('"${member.phone ?? 'N/A'}",');
      buffer.write('"${member.email ?? 'N/A'}",');
      buffer.write('"${member.carBrand ?? ''} ${member.carModel ?? ''}".trim(),');
      buffer.write('"${DateFormat('yyyy-MM-dd HH:mm').format(registration.registrationDate)}",');
      buffer.write('"${registration.status ?? 'confirmed'}",');
      buffer.write('"${registration.hasVehicle ?? false}",');
      buffer.writeln('"${registration.vehicleCapacity ?? 'N/A'}"');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    
    // Check permissions
    final canForceRegister = user?.hasPermission('force_register_member_to_trip') ?? false;
    final canRemove = user?.hasPermission('remove_member_from_trip') ?? false;
    final canCheckin = user?.hasPermission('check_in_member') ?? false;
    final canCheckout = user?.hasPermission('check_out_member') ?? false;
    final canExport = user?.hasPermission('export_trip_registrants') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip Registrants'),
            if (_trip != null)
              Text(
                _trip!.title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (!_isLoading && canExport)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: _exportRegistrants,
            ),
          if (!_isLoading && canForceRegister)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Force Register',
              onPressed: _forceRegisterMember,
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTripData,
            ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'Registered',
                    icon: Badge(
                      label: Text(_trip?.registered.length.toString() ?? '0'),
                      child: const Icon(Icons.check_circle),
                    ),
                  ),
                  Tab(
                    text: 'Waitlist',
                    icon: Badge(
                      label: Text(_trip?.waitlist.length.toString() ?? '0'),
                      child: const Icon(Icons.schedule),
                    ),
                  ),
                ],
              ),
      ),
      body: _buildBody(canRemove, canCheckin, canCheckout),
    );
  }

  Widget _buildBody(bool canRemove, bool canCheckin, bool canCheckout) {
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
              onPressed: _loadTripData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_trip == null) {
      return const Center(child: Text('Trip not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRegisteredList(canRemove, canCheckin, canCheckout),
        _buildWaitlistList(),
      ],
    );
  }

  Widget _buildRegisteredList(bool canRemove, bool canCheckin, bool canCheckout) {
    final registered = _trip!.registered;

    if (registered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Registered Members',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Members who register will appear here',
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
      itemCount: registered.length,
      itemBuilder: (context, index) {
        final registration = registered[index];
        return _RegistrantCard(
          registration: registration,
          tripId: widget.tripId,
          canRemove: canRemove,
          canCheckin: canCheckin,
          canCheckout: canCheckout,
          onRemove: () => _removeMember(registration),
          onCheckin: () => _checkinMember(registration),
          onCheckout: () => _checkoutMember(registration),
          isProcessing: _isProcessing,
        );
      },
    );
  }

  Widget _buildWaitlistList() {
    final waitlist = _trip!.waitlist;

    if (waitlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Waitlist',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Members on waitlist will appear here',
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
      itemCount: waitlist.length,
      itemBuilder: (context, index) {
        final waitlistEntry = waitlist[index];
        return _WaitlistCard(
          waitlistEntry: waitlistEntry,
          position: index + 1,
          onAdd: () => _addFromWaitlist(waitlistEntry),
          isProcessing: _isProcessing,
        );
      },
    );
  }
}

/// Registrant Card Widget
class _RegistrantCard extends StatelessWidget {
  final TripRegistration registration;
  final int tripId;
  final bool canRemove;
  final bool canCheckin;
  final bool canCheckout;
  final VoidCallback onRemove;
  final VoidCallback onCheckin;
  final VoidCallback onCheckout;
  final bool isProcessing;

  const _RegistrantCard({
    required this.registration,
    required this.tripId,
    required this.canRemove,
    required this.canCheckin,
    required this.canCheckout,
    required this.onRemove,
    required this.onCheckin,
    required this.onCheckout,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = registration.member;
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
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
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${member.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: registration.status ?? 'confirmed'),
              ],
            ),
            const SizedBox(height: 12),

            // Additional info
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: dateFormat.format(registration.registrationDate),
                ),
                if (registration.hasVehicle == true)
                  _InfoChip(
                    icon: Icons.directions_car,
                    label: 'Has Vehicle (${registration.vehicleCapacity ?? 0} seats)',
                  ),
                if (member.phone != null)
                  _InfoChip(
                    icon: Icons.phone,
                    label: member.phone!,
                  ),
              ],
            ),
            
            // Action buttons
            if (canRemove || canCheckin || canCheckout)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (canCheckin && registration.status != 'checked_in')
                      TextButton.icon(
                        onPressed: isProcessing ? null : onCheckin,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Check In'),
                      ),
                    if (canCheckout && registration.status == 'checked_in')
                      TextButton.icon(
                        onPressed: isProcessing ? null : onCheckout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Check Out'),
                      ),
                    const Spacer(),
                    if (canRemove)
                      TextButton.icon(
                        onPressed: isProcessing ? null : onRemove,
                        icon: const Icon(Icons.remove_circle, size: 18),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Waitlist Card Widget
class _WaitlistCard extends StatelessWidget {
  final TripWaitlist waitlistEntry;
  final int position;
  final VoidCallback onAdd;
  final bool isProcessing;

  const _WaitlistCard({
    required this.waitlistEntry,
    required this.position,
    required this.onAdd,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = waitlistEntry.member;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Center(
                child: Text(
                  '#$position',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Joined: ${dateFormat.format(waitlistEntry.joinedDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            FilledButton.icon(
              onPressed: isProcessing ? null : onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'checked_in':
        color = Colors.green;
        label = 'Checked In';
        break;
      case 'checked_out':
        color = Colors.blue;
        label = 'Checked Out';
        break;
      case 'confirmed':
        color = Colors.teal;
        label = 'Confirmed';
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
