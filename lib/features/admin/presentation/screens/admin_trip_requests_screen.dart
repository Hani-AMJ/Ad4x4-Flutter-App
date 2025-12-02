import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_request_model.dart';
import '../../../../data/models/approval_status_choice_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/services/error_log_service.dart';
import '../providers/approval_status_provider.dart';

class AdminTripRequestsScreen extends ConsumerStatefulWidget {
  const AdminTripRequestsScreen({super.key});

  @override
  ConsumerState<AdminTripRequestsScreen> createState() =>
      _AdminTripRequestsScreenState();
}

class _AdminTripRequestsScreenState
    extends ConsumerState<AdminTripRequestsScreen> {
  final MainApiRepository _repository = MainApiRepository();

  List<TripRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  String _selectedFilter = 'all'; // all, pending, approved, declined, converted

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getAllTripRequests(
        pageSize: 100,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final requests = results
          .map((json) => TripRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by created date (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to load trip requests: $e';
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });

      // Log error to Error Log Service
      await ErrorLogService().logError(
        message: errorMsg,
        stackTrace: stackTrace.toString(),
        type: 'admin_trip_requests',
        context: 'AdminTripRequestsScreen._loadRequests',
      );
    }
  }

  Future<void> _updateRequestStatus(
    TripRequest request,
    String newStatus, {
    String? adminNotes,
  }) async {
    try {
      await _repository.updateTripRequestStatus(
        requestId: request.id,
        status: newStatus,
        adminNotes: adminNotes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${newStatus.toLowerCase()} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      }
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to update request: $e';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }

      // Log error to Error Log Service
      await ErrorLogService().logError(
        message: errorMsg,
        stackTrace: stackTrace.toString(),
        type: 'admin_trip_requests',
        context: 'AdminTripRequestsScreen._updateRequestStatus',
      );
    }
  }

  void _showRequestDetails(TripRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(
        request: request,
        onApprove: (notes) =>
            _updateRequestStatus(request, 'approved', adminNotes: notes),
        onDecline: (notes) =>
            _updateRequestStatus(request, 'declined', adminNotes: notes),
        onConvert: (notes) =>
            _updateRequestStatus(request, 'converted', adminNotes: notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Requests Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: Column(
        children: [
          // NEW: Dynamic Filter Chips
          Consumer(
            builder: (context, ref, _) {
              final statusesAsync = ref.watch(approvalStatusChoicesProvider);

              return statusesAsync.when(
                data: (statuses) => _buildDynamicFilters(statuses, colors),
                loading: () => _buildFallbackFilters(colors),
                error: (e, s) => _buildFallbackFilters(colors),
              );
            },
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trip requests',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trip requests will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _AdminTripRequestCard(
                          request: request,
                          onTap: () => _showRequestDetails(request),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build dynamic filter chips from approval statuses
  Widget _buildDynamicFilters(
    List<ApprovalStatusChoice> statuses,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.surfaceContainerHighest.withOpacity(0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" filter
            _FilterChip(
              label: 'All (${_requests.length})',
              isSelected: _selectedFilter == 'all',
              onTap: () {
                setState(() => _selectedFilter = 'all');
                _loadRequests();
              },
            ),
            const SizedBox(width: 8),

            // Dynamic status filters
            ...statuses.map((status) {
              // Calculate count for this status
              final count = _requests.where((r) {
                // Match both backend codes and legacy strings
                final requestStatus = r.status
                    .toString()
                    .split('.')
                    .last
                    .toLowerCase();
                final statusValue = status.value.toLowerCase();
                return requestStatus == statusValue ||
                    (statusValue == 'p' && requestStatus == 'pending') ||
                    (statusValue == 'a' && requestStatus == 'approved') ||
                    (statusValue == 'd' && requestStatus == 'declined');
              }).length;

              // Determine color
              Color? chipColor;
              if (status.value.toLowerCase() == 'pending' ||
                  status.value.toUpperCase() == 'P') {
                chipColor = Colors.orange;
              } else if (status.value.toLowerCase() == 'approved' ||
                  status.value.toUpperCase() == 'A') {
                chipColor = Colors.green;
              } else if (status.value.toLowerCase() == 'declined' ||
                  status.value.toUpperCase() == 'D') {
                chipColor = Colors.red;
              } else if (status.value.toLowerCase() == 'converted') {
                chipColor = Colors.purple;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: '${status.label} ($count)',
                  isSelected: _selectedFilter == status.value,
                  color: chipColor,
                  onTap: () {
                    setState(() => _selectedFilter = status.value);
                    _loadRequests();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Fallback filters for loading/error states
  Widget _buildFallbackFilters(ColorScheme colors) {
    // Calculate counts using legacy status enum
    final pendingCount = _requests
        .where((r) => r.status == TripRequestStatus.pending)
        .length;
    final approvedCount = _requests
        .where((r) => r.status == TripRequestStatus.approved)
        .length;
    final declinedCount = _requests
        .where((r) => r.status == TripRequestStatus.declined)
        .length;
    final convertedCount = _requests
        .where((r) => r.status == TripRequestStatus.converted)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.surfaceContainerHighest.withOpacity(0.3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All (${_requests.length})',
              isSelected: _selectedFilter == 'all',
              onTap: () {
                setState(() => _selectedFilter = 'all');
                _loadRequests();
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Pending ($pendingCount)',
              isSelected: _selectedFilter == 'pending',
              color: Colors.orange,
              onTap: () {
                setState(() => _selectedFilter = 'pending');
                _loadRequests();
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Approved ($approvedCount)',
              isSelected: _selectedFilter == 'approved',
              color: Colors.green,
              onTap: () {
                setState(() => _selectedFilter = 'approved');
                _loadRequests();
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Declined ($declinedCount)',
              isSelected: _selectedFilter == 'declined',
              color: Colors.red,
              onTap: () {
                setState(() => _selectedFilter = 'declined');
                _loadRequests();
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Converted ($convertedCount)',
              isSelected: _selectedFilter == 'converted',
              color: Colors.purple,
              onTap: () {
                setState(() => _selectedFilter = 'converted');
                _loadRequests();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? colors.primaryContainer,
      checkmarkColor: isSelected ? (color ?? colors.onPrimaryContainer) : null,
    );
  }
}

class _AdminTripRequestCard extends StatelessWidget {
  final TripRequest request;
  final VoidCallback onTap;

  const _AdminTripRequestCard({required this.request, required this.onTap});

  Color _getStatusColor(TripRequestStatus status) {
    switch (status) {
      case TripRequestStatus.pending:
        return Colors.orange;
      case TripRequestStatus.approved:
        return Colors.green;
      case TripRequestStatus.declined:
        return Colors.red;
      case TripRequestStatus.converted:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(TripRequestStatus status) {
    switch (status) {
      case TripRequestStatus.pending:
        return Icons.pending_outlined;
      case TripRequestStatus.approved:
        return Icons.check_circle_outline;
      case TripRequestStatus.declined:
        return Icons.cancel_outlined;
      case TripRequestStatus.converted:
        return Icons.rocket_launch_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Icon(
                    _getStatusIcon(request.status),
                    size: 20,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${request.level.displayName} in ${request.areaDisplayName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      request.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Trip details chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.location_on,
                    label: request.areaDisplayName,
                  ),
                  _InfoChip(
                    icon: Icons.terrain,
                    label: request.level.shortName,
                  ),
                  if (request.timeOfDay != null)
                    _InfoChip(
                      icon: Icons.schedule,
                      label: request.timeOfDayDisplayName!,
                    ),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: DateFormat('MMM dd, yyyy').format(request.date),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Member info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.memberName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(request.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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

class _RequestDetailsSheet extends StatefulWidget {
  final TripRequest request;
  final Function(String notes) onApprove;
  final Function(String notes) onDecline;
  final Function(String notes) onConvert;

  const _RequestDetailsSheet({
    required this.request,
    required this.onApprove,
    required this.onDecline,
    required this.onConvert,
  });

  @override
  State<_RequestDetailsSheet> createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<_RequestDetailsSheet> {
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showActionDialog(String action, Function(String) onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${action.toLowerCase()} this request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Admin Notes',
                hintText: 'Optional notes to member...',
                border: const OutlineInputBorder(),
                helperText: action == 'Convert'
                    ? 'These notes will be sent to the member'
                    : null,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notesController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              setState(() => _isProcessing = true);
              Navigator.pop(context);
              await onConfirm(_notesController.text);
              _notesController.clear();
              if (mounted) {
                setState(() => _isProcessing = false);
                Navigator.pop(context);
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final request = widget.request;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Status badge
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 16,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            request.status.displayName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title (synthesized from level and area)
                  Text(
                    '${request.level.displayName} in ${request.areaDisplayName}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Member info
                  _DetailSection(
                    icon: Icons.person,
                    title: 'Requested By',
                    child: Text(
                      request.memberName,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trip Level
                  _DetailSection(
                    icon: Icons.terrain,
                    title: 'Trip Level',
                    child: Text(
                      request.level.displayName,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Area
                  _DetailSection(
                    icon: Icons.location_on,
                    title: 'Area',
                    child: Text(
                      request.areaDisplayName,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  if (request.timeOfDay != null) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.access_time,
                      title: 'Preferred Time',
                      child: Text(
                        request.timeOfDayDisplayName!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Requested Date
                  _DetailSection(
                    icon: Icons.calendar_today,
                    title: 'Requested Date',
                    child: Text(
                      DateFormat('MMMM dd, yyyy').format(request.date),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date submitted
                  _DetailSection(
                    icon: Icons.schedule,
                    title: 'Submitted',
                    child: Text(
                      DateFormat(
                        'MMMM dd, yyyy \'at\' h:mm a',
                      ).format(request.createdAt),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                  if (request.adminNotes != null) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.notes,
                      title: 'Admin Notes',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.adminNotes!,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons (only show for pending requests)
                  if (request.status == TripRequestStatus.pending)
                    Column(
                      children: [
                        // Approve button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _showActionDialog(
                                    'Approve',
                                    widget.onApprove,
                                  ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve Request'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Decline button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _showActionDialog(
                                    'Decline',
                                    widget.onDecline,
                                  ),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Decline Request'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Convert button (for approved requests)
                  if (request.status == TripRequestStatus.approved)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _showActionDialog(
                                'Convert',
                                widget.onConvert,
                              ),
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text('Convert to Trip'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.request.status) {
      case TripRequestStatus.pending:
        return Colors.orange;
      case TripRequestStatus.approved:
        return Colors.green;
      case TripRequestStatus.declined:
        return Colors.red;
      case TripRequestStatus.converted:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.request.status) {
      case TripRequestStatus.pending:
        return Icons.pending_outlined;
      case TripRequestStatus.approved:
        return Icons.check_circle_outline;
      case TripRequestStatus.declined:
        return Icons.cancel_outlined;
      case TripRequestStatus.converted:
        return Icons.rocket_launch_outlined;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: child),
      ],
    );
  }
}
