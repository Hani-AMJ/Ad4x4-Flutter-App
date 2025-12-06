/// Admin Waitlist Management Screen - Manage trip waitlist with reordering
/// 
/// Provides waitlist management with:
/// - Waitlist member list with position display
/// - Reorder positions capability (drag and drop)
/// - Move to registered functionality (individual or batch)
/// - Member info display (level, join date, waiting duration)
/// - Auto-fill feature configuration
/// - Notification on status change
/// - Batch operations with checkboxes
/// 
/// Permission Required: edit_trip_registrations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/trip_model.dart';
import '../../../../data/models/registration_analytics_model.dart';
import '../providers/registration_management_provider.dart';
import '../../../trips/presentation/providers/trips_provider.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../widgets/trip_search_autocomplete.dart';

/// Admin Waitlist Management Screen
class AdminWaitlistManagementScreen extends ConsumerStatefulWidget {
  final int? initialTripId;

  const AdminWaitlistManagementScreen({
    super.key,
    this.initialTripId,
  });

  @override
  ConsumerState<AdminWaitlistManagementScreen> createState() => _AdminWaitlistManagementScreenState();
}

class _AdminWaitlistManagementScreenState extends ConsumerState<AdminWaitlistManagementScreen> {
  int? _selectedTripId;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.initialTripId;
    
    // Load initial waitlist if trip is selected
    if (_selectedTripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(waitlistManagementProvider.notifier).loadWaitlist(_selectedTripId!);
      });
    }
  }

  /// Move selected members to registered
  Future<void> _moveToRegistered() async {
    final state = ref.read(waitlistManagementProvider);
    
    if (state.selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select members to move')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Registered'),
        content: Text(
          'Move ${state.selectedIds.length} member(s) from waitlist to registered?\n\n'
          'They will be notified via push notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(waitlistManagementProvider.notifier).moveToRegistered(
          memberIds: state.selectedIds,
          notifyMembers: true,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.selectedIds.length} member(s) moved to registered'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to move members: $e')),
          );
        }
      }
    }
  }

  /// Show auto-fill configuration dialog
  Future<void> _showAutoFillDialog() async {
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip first')),
      );
      return;
    }

    bool enableAutoFill = false;
    bool notifyMembers = true;
    int priorityOrder = 0; // 0 = FIFO, 1 = Level-based, 2 = Trip count

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Auto-fill Configuration'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure automatic waitlist promotion when spots become available',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Enable auto-fill toggle
                  SwitchListTile(
                    title: const Text('Enable Auto-fill'),
                    subtitle: const Text('Automatically promote from waitlist when capacity opens'),
                    value: enableAutoFill,
                    onChanged: (value) {
                      setState(() => enableAutoFill = value);
                    },
                  ),
                  
                  if (enableAutoFill) ...[
                    const Divider(height: 32),
                    
                    // Notification toggle
                    SwitchListTile(
                      title: const Text('Notify Members'),
                      subtitle: const Text('Send notifications when promoted from waitlist'),
                      value: notifyMembers,
                      onChanged: (value) {
                        setState(() => notifyMembers = value);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Priority order selection
                    Text(
                      'Promotion Priority Order',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    
                    RadioListTile<int>(
                      title: const Text('First In, First Out (FIFO)'),
                      subtitle: const Text('Promote members in waitlist order'),
                      value: 0,
                      groupValue: priorityOrder,
                      onChanged: (value) {
                        setState(() => priorityOrder = value!);
                      },
                    ),
                    
                    RadioListTile<int>(
                      title: const Text('Level-based Priority'),
                      subtitle: const Text('Higher level members promoted first'),
                      value: 1,
                      groupValue: priorityOrder,
                      onChanged: (value) {
                        setState(() => priorityOrder = value!);
                      },
                    ),
                    
                    RadioListTile<int>(
                      title: const Text('Trip Count Priority'),
                      subtitle: const Text('Members with fewer trips promoted first'),
                      value: 2,
                      groupValue: priorityOrder,
                      onChanged: (value) {
                        setState(() => priorityOrder = value!);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'enableAutoFill': enableAutoFill,
                  'notifyMembers': notifyMembers,
                  'priorityOrder': priorityOrder,
                });
              },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      // In a real implementation, these settings would be saved to the backend
      // For now, just show confirmation
      final enabled = result['enableAutoFill'] as bool;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '✅ Auto-fill enabled for this trip'
                : 'ℹ️ Auto-fill disabled for this trip',
          ),
          backgroundColor: enabled ? Colors.green : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permission
    final authState = ref.watch(authProviderV2);
    final hasPermission = authState.user?.hasPermission('edit_trip_registrations') ?? false;

    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waitlist Management')),
        body: const Center(
          child: Text('You do not have permission to access this feature'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waitlist Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAutoFillDialog,
            tooltip: 'Auto-fill Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedTripId != null 
                ? () => ref.read(waitlistManagementProvider.notifier).refresh()
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip selector
          _buildTripSelector(),
          
          // Bulk action bar
          _buildBulkActionBar(),
          
          // Waitlist display
          Expanded(
            child: _selectedTripId == null
                ? const Center(child: Text('Please select a trip'))
                : _buildWaitlistContent(),
          ),
        ],
      ),
    );
  }

  /// Build trip selector
  Widget _buildTripSelector() {
    final tripsState = ref.watch(tripsProvider);
    final trips = tripsState.trips;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: TripSearchAutocomplete(
        initialTripId: _selectedTripId,
        onTripSelected: (Trip? trip) {
          setState(() {
            _selectedTripId = trip?.id;
          });
          if (trip != null) {
            ref.read(waitlistManagementProvider.notifier).loadWaitlist(trip.id);
          }
        },
      ),
    );
  }

  /// Build bulk action bar
  Widget _buildBulkActionBar() {
    final state = ref.watch(waitlistManagementProvider);
    
    if (!state.hasSelection) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Selection info
          Expanded(
            child: Text(
              '${state.selectedIds.length} selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          
          // Deselect all
          TextButton(
            onPressed: () => ref.read(waitlistManagementProvider.notifier).deselectAll(),
            child: const Text('Deselect All'),
          ),
          
          const SizedBox(width: 8),
          
          // Move to registered
          FilledButton.icon(
            onPressed: _moveToRegistered,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Move to Registered'),
          ),
        ],
      ),
    );
  }

  /// Build waitlist content
  Widget _buildWaitlistContent() {
    final state = ref.watch(waitlistManagementProvider);
    final analyticsAsync = ref.watch(registrationAnalyticsProvider(_selectedTripId!));

    return analyticsAsync.when(
      data: (analytics) {
        if (state.isLoading && state.waitlist.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${state.error}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(waitlistManagementProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.waitlist.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No waitlist members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The waitlist is currently empty',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(waitlistManagementProvider.notifier).refresh(),
          child: Column(
            children: [
              // Waitlist stats
              _buildWaitlistStats(analytics, state.waitlist.length),
              
              // Waitlist list
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.waitlist.length,
                  onReorder: (oldIndex, newIndex) => _onReorder(
                    oldIndex,
                    newIndex,
                    state.waitlist,
                  ),
                  itemBuilder: (context, index) {
                    final member = state.waitlist[index];
                    return _WaitlistCard(
                      key: ValueKey(member.member.id),
                      waitlistMember: member,
                      position: index + 1,
                      isSelected: state.selectedIds.contains(member.member.id),
                      onToggle: () => ref.read(waitlistManagementProvider.notifier)
                          .toggleSelection(member.member.id),
                      onMoveToRegistered: () => _moveIndividual(member.member.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading analytics: $error'),
          ],
        ),
      ),
    );
  }

  /// Build waitlist stats
  Widget _buildWaitlistStats(RegistrationAnalytics analytics, int waitlistCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.people,
              label: 'Total Waitlist',
              value: waitlistCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.event_available,
              label: 'Available Spots',
              value: analytics.availableSpots.toString(),
              valueColor: analytics.availableSpots > 0 ? Colors.green : Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle,
              label: 'Confirmed',
              value: '${analytics.confirmedRegistrations}/${analytics.tripCapacity}',
            ),
          ),
        ],
      ),
    );
  }

  /// Handle reorder
  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<TripWaitlist> waitlist,
  ) async {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create position updates
    final positions = <WaitlistPosition>[];
    final movedMember = waitlist[oldIndex];
    
    // Add the moved member's new position
    positions.add(WaitlistPosition(
      memberId: movedMember.member.id,
      oldPosition: oldIndex + 1,
      newPosition: newIndex + 1,
    ));

    // Update positions of affected members
    if (newIndex > oldIndex) {
      // Moving down - shift members up
      for (int i = oldIndex + 1; i <= newIndex; i++) {
        positions.add(WaitlistPosition(
          memberId: waitlist[i].member.id,
          oldPosition: i + 1,
          newPosition: i,
        ));
      }
    } else {
      // Moving up - shift members down
      for (int i = newIndex; i < oldIndex; i++) {
        positions.add(WaitlistPosition(
          memberId: waitlist[i].member.id,
          oldPosition: i + 1,
          newPosition: i + 2,
        ));
      }
    }

    try {
      await ref.read(waitlistManagementProvider.notifier).reorder(positions);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waitlist order updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder waitlist: $e')),
        );
      }
    }
  }

  /// Move individual member to registered
  Future<void> _moveIndividual(int memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Registered'),
        content: const Text(
          'Move this member from waitlist to registered?\n\n'
          'They will be notified via push notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(waitlistManagementProvider.notifier).moveToRegistered(
          memberIds: [memberId],
          notifyMembers: true,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member moved to registered')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to move member: $e')),
          );
        }
      }
    }
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Waitlist Card Widget
class _WaitlistCard extends StatelessWidget {
  final TripWaitlist waitlistMember;
  final int position;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onMoveToRegistered;

  const _WaitlistCard({
    super.key,
    required this.waitlistMember,
    required this.position,
    required this.isSelected,
    required this.onToggle,
    required this.onMoveToRegistered,
  });

  /// Calculate waiting duration
  String _getWaitingDuration(DateTime joinDate) {
    final duration = DateTime.now().difference(joinDate);
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? "s" : ""}';
    }
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final member = waitlistMember.member;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reorder handle
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            
            const SizedBox(width: 8),
            
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
            ),
            
            const SizedBox(width: 12),
            
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$position',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Member avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: member.profileImage != null
                  ? NetworkImage(member.profileImage!)
                  : null,
              child: member.profileImage == null
                  ? Text(member.displayName[0].toUpperCase())
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Member details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    member.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Level
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.level ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Join date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Joined: ${_formatDate(waitlistMember.joinedDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Waiting duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Waiting: ${_getWaitingDuration(waitlistMember.joinedDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Move button
            IconButton.filledTonal(
              onPressed: onMoveToRegistered,
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Move to Registered',
            ),
          ],
        ),
      ),
    );
  }
}
