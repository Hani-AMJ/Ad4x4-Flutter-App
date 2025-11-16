import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Meeting Points Management Screen
/// 
/// Manage meeting points (list, create, edit, delete).
/// Features:
/// - View all meeting points
/// - Create new meeting points
/// - Edit existing meeting points
/// - Delete meeting points with confirmation
/// - Permission-gated actions
class AdminMeetingPointsScreen extends ConsumerStatefulWidget {
  const AdminMeetingPointsScreen({super.key});

  @override
  ConsumerState<AdminMeetingPointsScreen> createState() => _AdminMeetingPointsScreenState();
}

class _AdminMeetingPointsScreenState extends ConsumerState<AdminMeetingPointsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MeetingPoint> _meetingPoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetingPoints();
    });
  }

  Future<void> _loadMeetingPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final data = await repository.getMeetingPoints();
      final results = data['results'] as List<dynamic>? ?? [];
      final meetingPoints = results
          .map((json) => MeetingPoint.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _meetingPoints = meetingPoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meeting points: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeetingPoint(MeetingPoint meetingPoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Delete Meeting Point'),
        content: Text(
          'Are you sure you want to delete "${meetingPoint.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Note: Backend may need DELETE endpoint implementation
      // For now, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Delete endpoint not yet implemented in backend'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // TODO: Uncomment when backend supports delete
      // final repository = ref.read(mainApiRepositoryProvider);
      // await repository.deleteMeetingPoint(meetingPoint.id);
      // await _loadMeetingPoints();
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
                  ? '🚫 You are not authorized to delete meeting points'
                  : '❌ Failed to delete meeting point: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    
    // Check permissions (use plural form to match backend)
    final canCreate = user?.hasPermission('create_meeting_points') ?? false;
    final canEdit = user?.hasPermission('edit_meeting_points') ?? false;
    final canDelete = user?.hasPermission('delete_meeting_points') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Points'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeetingPoints,
          ),
        ],
      ),
      body: _buildBody(canEdit, canDelete),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push('/admin/meeting-points/create');
                if (result == true && mounted) {
                  _loadMeetingPoints();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Meeting Point'),
            )
          : null,
    );
  }

  Widget _buildBody(bool canEdit, bool canDelete) {
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
              onPressed: _loadMeetingPoints,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_meetingPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Meeting Points',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first meeting point',
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
      itemCount: _meetingPoints.length,
      itemBuilder: (context, index) {
        final meetingPoint = _meetingPoints[index];
        return _MeetingPointCard(
          meetingPoint: meetingPoint,
          canEdit: canEdit,
          canDelete: canDelete,
          onEdit: () async {
            final result = await context.push('/admin/meeting-points/${meetingPoint.id}/edit');
            if (result == true && mounted) {
              _loadMeetingPoints();
            }
          },
          onDelete: () => _deleteMeetingPoint(meetingPoint),
        );
      },
    );
  }
}

/// Meeting Point Card Widget
class _MeetingPointCard extends StatelessWidget {
  final MeetingPoint meetingPoint;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeetingPointCard({
    required this.meetingPoint,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetingPoint.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (meetingPoint.area != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meetingPoint.area!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Coordinates
            if (meetingPoint.lat != null && meetingPoint.lon != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lat: ${meetingPoint.lat}, Lon: ${meetingPoint.lon}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Google Maps link
            if (meetingPoint.link != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  if (meetingPoint.link != null) {
                    final uri = Uri.parse(meetingPoint.link!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Google Maps')),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'View on Google Maps',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons
            if (canEdit || canDelete) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canEdit)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (canEdit && canDelete) const SizedBox(width: 8),
                  if (canDelete)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
