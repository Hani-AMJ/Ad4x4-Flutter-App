/// Admin Bulk Registration Actions Screen - Registration management with bulk operations
/// 
/// Provides registration list with checkboxes, filtering, and bulk actions:
/// - Registration list with member details and status
/// - Checkbox selection system
/// - Bulk approve, reject, check-in operations
/// - Send notifications to selected registrants
/// - Filter by registration status
/// - Individual registration actions
/// 
/// Permission Required: edit_trip_registrations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/registration_analytics_model.dart';
import '../../../../data/models/trip_model.dart';
import '../providers/registration_management_provider.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../widgets/trip_search_autocomplete.dart';

/// Admin Bulk Registration Actions Screen
class AdminBulkRegistrationsScreen extends ConsumerStatefulWidget {
  final int? initialTripId;

  const AdminBulkRegistrationsScreen({
    super.key,
    this.initialTripId,
  });

  @override
  ConsumerState<AdminBulkRegistrationsScreen> createState() => _AdminBulkRegistrationsScreenState();
}

class _AdminBulkRegistrationsScreenState extends ConsumerState<AdminBulkRegistrationsScreen> {
  int? _selectedTripId;
  String? _statusFilter;
  final ScrollController _scrollController = ScrollController();

  // Status filter options
  static const List<String> _statusOptions = [
    'All',
    'Confirmed',
    'Checked-In',
    'Pending',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.initialTripId;
    
    // Load initial data if trip is selected
    if (_selectedTripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRegistrations();
      });
    }

    // Setup infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(registrationListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load registrations for selected trip
  void _loadRegistrations() {
    if (_selectedTripId != null) {
      ref.read(registrationListProvider.notifier).loadRegistrations(
        tripId: _selectedTripId!,
        status: _statusFilter == 'All' ? null : _statusFilter?.toLowerCase(),
      );
    }
  }

  /// Show notification dialog
  Future<void> _showNotificationDialog() async {
    final selectedIds = ref.read(registrationListProvider).selectedIds;
    
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select registrants to notify')),
      );
      return;
    }

    final messageController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sending to ${selectedIds.length} registrant(s)'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter notification message...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, messageController.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && _selectedTripId != null) {
      try {
        // Get member IDs from selected registrations
        final state = ref.read(registrationListProvider);
        final memberIds = state.selectedRegistrations
            .map((r) => r.registration.member.id)
            .toList();

        await ref.read(registrationBulkActionsProvider.notifier).notifyRegistrants(
          tripId: _selectedTripId!,
          message: result,
          memberIds: memberIds,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent successfully')),
          );
          ref.read(registrationListProvider.notifier).deselectAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send notification: $e')),
          );
        }
      }
    }
  }

  /// Show reject reason dialog
  Future<void> _showRejectReasonDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Reason'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Enter reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _bulkReject(result.isEmpty ? null : result);
    }
  }

  /// Bulk approve selected registrations
  Future<void> _bulkApprove() async {
    final selectedIds = ref.read(registrationListProvider).selectedIds;
    
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select registrations to approve')),
      );
      return;
    }

    try {
      await ref.read(registrationBulkActionsProvider.notifier).bulkApprove(selectedIds);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} registration(s) approved')),
        );
        ref.read(registrationListProvider.notifier).deselectAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve registrations: $e')),
        );
      }
    }
  }

  /// Bulk reject selected registrations
  Future<void> _bulkReject(String? reason) async {
    final selectedIds = ref.read(registrationListProvider).selectedIds;
    
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select registrations to reject')),
      );
      return;
    }

    try {
      await ref.read(registrationBulkActionsProvider.notifier).bulkReject(
        selectedIds,
        reason: reason,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} registration(s) rejected')),
        );
        ref.read(registrationListProvider.notifier).deselectAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject registrations: $e')),
        );
      }
    }
  }

  /// Bulk check-in selected registrations
  Future<void> _bulkCheckin() async {
    final selectedIds = ref.read(registrationListProvider).selectedIds;
    
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select registrations to check-in')),
      );
      return;
    }

    try {
      await ref.read(registrationBulkActionsProvider.notifier).bulkCheckin(selectedIds);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} registration(s) checked in')),
        );
        ref.read(registrationListProvider.notifier).deselectAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check-in registrations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permission
    final authState = ref.watch(authProviderV2);
    final hasPermission = authState.user?.hasPermission('edit_trip_registrations') ?? false;

    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bulk Registration Actions')),
        body: const Center(
          child: Text('You do not have permission to access this feature'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Registration Actions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedTripId != null 
                ? () => ref.read(registrationListProvider.notifier).refresh()
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip selector and filters
          _buildFilters(),
          
          // Bulk action bar
          _buildBulkActionBar(),
          
          // Registration list
          Expanded(
            child: _selectedTripId == null
                ? const Center(child: Text('Please select a trip'))
                : _buildRegistrationList(),
          ),
        ],
      ),
    );
  }

  /// Build filters section
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip search autocomplete
          TripSearchAutocomplete(
            initialTripId: _selectedTripId,
            onTripSelected: (Trip? trip) {
              setState(() {
                _selectedTripId = trip?.id;
              });
              if (trip != null) {
                _loadRegistrations();
              }
            },
            showFilters: true,
            hintText: 'Search trips for bulk actions...',
          ),
          
          const SizedBox(height: 12),
          
          // Status filter
          if (_selectedTripId != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusOptions.map((status) {
                  final isSelected = _statusFilter == status || 
                      (status == 'All' && _statusFilter == null);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _statusFilter = status == 'All' ? null : status;
                        });
                        _loadRegistrations();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Build bulk action bar
  Widget _buildBulkActionBar() {
    final state = ref.watch(registrationListProvider);
    final isLoading = ref.watch(registrationBulkActionsProvider);
    
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
            onPressed: isLoading 
                ? null 
                : () => ref.read(registrationListProvider.notifier).deselectAll(),
            child: const Text('Deselect All'),
          ),
          
          const SizedBox(width: 8),
          
          // Action buttons
          FilledButton.tonal(
            onPressed: isLoading ? null : _bulkApprove,
            child: const Text('Approve'),
          ),
          
          const SizedBox(width: 8),
          
          OutlinedButton(
            onPressed: isLoading ? null : _showRejectReasonDialog,
            child: const Text('Reject'),
          ),
          
          const SizedBox(width: 8),
          
          FilledButton(
            onPressed: isLoading ? null : _bulkCheckin,
            child: const Text('Check-in'),
          ),
          
          const SizedBox(width: 8),
          
          IconButton.filled(
            onPressed: isLoading ? null : _showNotificationDialog,
            icon: const Icon(Icons.notifications),
            tooltip: 'Send Notification',
          ),
        ],
      ),
    );
  }

  /// Build registration list
  Widget _buildRegistrationList() {
    final state = ref.watch(registrationListProvider);

    if (state.isLoading && state.registrations.isEmpty) {
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
              onPressed: () => ref.read(registrationListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.registrations.isEmpty) {
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
              'No registrations found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter != null
                  ? 'Try changing the filter'
                  : 'No registrations for this trip yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(registrationListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.registrations.length + 
            (state.hasMore ? 1 : 0) + 
            1, // +1 for select all header
        itemBuilder: (context, index) {
          // Select all header
          if (index == 0) {
            return _buildSelectAllHeader(state);
          }

          // Adjust index for registrations
          final registrationIndex = index - 1;

          // Loading indicator at the end
          if (registrationIndex >= state.registrations.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final registration = state.registrations[registrationIndex];
          return _RegistrationCard(
            registration: registration,
            isSelected: state.selectedIds.contains(registration.registration.id),
            onToggle: () => ref.read(registrationListProvider.notifier)
                .toggleSelection(registration.registration.id),
          );
        },
      ),
    );
  }

  /// Build select all header
  Widget _buildSelectAllHeader(RegistrationListState state) {
    final allSelected = state.registrations.isNotEmpty &&
        state.registrations.every((r) => state.selectedIds.contains(r.registration.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: CheckboxListTile(
        title: Text(
          'Select All (${state.registrations.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        value: allSelected,
        onChanged: (checked) {
          if (checked == true) {
            ref.read(registrationListProvider.notifier).selectAll();
          } else {
            ref.read(registrationListProvider.notifier).deselectAll();
          }
        },
      ),
    );
  }
}

/// Registration Card Widget
class _RegistrationCard extends StatelessWidget {
  final TripRegistrationWithAnalytics registration;
  final bool isSelected;
  final VoidCallback onToggle;

  const _RegistrationCard({
    required this.registration,
    required this.isSelected,
    required this.onToggle,
  });

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'checked_in':
      case 'checked-in':
        return Colors.blue;
      case 'checked_out':
      case 'checked-out':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = registration.registration;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
              ),
              
              const SizedBox(width: 12),
              
              // Member avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: reg.member.profileImage != null
                    ? NetworkImage(reg.member.profileImage!)
                    : null,
                child: reg.member.profileImage == null
                    ? Text(reg.member.displayName[0].toUpperCase())
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Registration details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reg.member.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reg.status ?? 'confirmed').withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(reg.status ?? 'confirmed'),
                            ),
                          ),
                          child: Text(
                            (reg.status ?? 'confirmed').toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(reg.status ?? 'confirmed'),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                          reg.member.level ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Registration date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Registered: ${_formatDate(reg.registrationDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    
                    // Vehicle info
                    if (reg.hasVehicle == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vehicle: ${reg.vehicleCapacity != null ? "${reg.vehicleCapacity} seats" : "Offered"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    
                    // Analytics info
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Trip count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${registration.tripCount} trips',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Days until trip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${registration.daysUntilTrip} days',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        
                        // Photo indicator
                        if (registration.hasUploadedPhotos) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_camera, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Photos',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
