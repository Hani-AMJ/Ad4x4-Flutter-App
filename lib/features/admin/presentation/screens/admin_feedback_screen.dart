import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/feedback.dart' as feedback_model;
import '../../../../data/repositories/main_api_repository.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  final MainApiRepository _repository = MainApiRepository();
  
  List<feedback_model.Feedback> _feedbackList = [];
  bool _isLoading = false;
  String? _error;
  
  String _selectedStatusFilter = 'all';  // all, SUBMITTED, IN_REVIEW, RESOLVED, CLOSED
  String _selectedTypeFilter = 'all';  // all, BUG, FEATURE, GENERAL, SUPPORT (verified from Django admin)
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedback();
    });
  }
  
  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _repository.getAllFeedback(
        pageSize: 100,
        status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
        feedbackType: _selectedTypeFilter == 'all' ? null : _selectedTypeFilter,
      );
      
      final results = response['results'] as List<dynamic>? ?? [];
      final feedbackList = results
          .map((json) => feedback_model.Feedback.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Sort by created date (newest first)
      feedbackList.sort((a, b) {
        if (a.created == null && b.created == null) return 0;
        if (a.created == null) return 1;
        if (b.created == null) return -1;
        return b.created!.compareTo(a.created!);
      });
      
      setState(() {
        _feedbackList = feedbackList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load feedback: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateFeedbackStatus(
    feedback_model.Feedback feedback,
    String newStatus, {
    String? adminResponse,
  }) async {
    try {
      await _repository.updateFeedback(
        feedbackId: feedback.id!,
        status: newStatus,
        adminResponse: adminResponse,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback updated to ${feedback_model.FeedbackStatus.getLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFeedback();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showFeedbackDetails(feedback_model.Feedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackDetailsSheet(
        feedback: feedback,
        onUpdateStatus: (status, response) => _updateFeedbackStatus(
          feedback,
          status,
          adminResponse: response,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Count by status
    final submittedCount = _feedbackList.where((f) => f.status == feedback_model.FeedbackStatus.submitted).length;
    final inReviewCount = _feedbackList.where((f) => f.status == feedback_model.FeedbackStatus.inReview).length;
    final resolvedCount = _feedbackList.where((f) => f.status == feedback_model.FeedbackStatus.resolved).length;
    final closedCount = _feedbackList.where((f) => f.status == feedback_model.FeedbackStatus.closed).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${_feedbackList.length})',
                        isSelected: _selectedStatusFilter == 'all',
                        onTap: () {
                          setState(() => _selectedStatusFilter = 'all');
                          _loadFeedback();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Submitted ($submittedCount)',
                        isSelected: _selectedStatusFilter == feedback_model.FeedbackStatus.submitted,
                        color: Colors.orange,
                        onTap: () {
                          setState(() => _selectedStatusFilter = feedback_model.FeedbackStatus.submitted);
                          _loadFeedback();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Review ($inReviewCount)',
                        isSelected: _selectedStatusFilter == feedback_model.FeedbackStatus.inReview,
                        color: Colors.blue,
                        onTap: () {
                          setState(() => _selectedStatusFilter = feedback_model.FeedbackStatus.inReview);
                          _loadFeedback();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Resolved ($resolvedCount)',
                        isSelected: _selectedStatusFilter == feedback_model.FeedbackStatus.resolved,
                        color: Colors.green,
                        onTap: () {
                          setState(() => _selectedStatusFilter = feedback_model.FeedbackStatus.resolved);
                          _loadFeedback();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Closed ($closedCount)',
                        isSelected: _selectedStatusFilter == feedback_model.FeedbackStatus.closed,
                        color: Colors.grey,
                        onTap: () {
                          setState(() => _selectedStatusFilter = feedback_model.FeedbackStatus.closed);
                          _loadFeedback();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Type Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedTypeFilter == 'all',
                        onTap: () {
                          setState(() => _selectedTypeFilter = 'all');
                          _loadFeedback();
                        },
                      ),
                      ...feedback_model.FeedbackType.all.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: feedback_model.FeedbackType.getLabel(type),
                            isSelected: _selectedTypeFilter == type,
                            onTap: () {
                              setState(() => _selectedTypeFilter = type);
                              _loadFeedback();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
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
                            Icon(Icons.error_outline, size: 48, color: colors.error),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFeedback,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _feedbackList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.feedback_outlined,
                                  size: 64,
                                  color: colors.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No feedback',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Member feedback will appear here',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFeedback,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _feedbackList.length,
                              itemBuilder: (context, index) {
                                final feedback = _feedbackList[index];
                                return _FeedbackCard(
                                  feedback: feedback,
                                  onTap: () => _showFeedbackDetails(feedback),
                                );
                              },
                            ),
                          ),
          ),
        ],
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

class _FeedbackCard extends StatelessWidget {
  final feedback_model.Feedback feedback;
  final VoidCallback onTap;
  
  const _FeedbackCard({
    required this.feedback,
    required this.onTap,
  });
  
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case feedback_model.FeedbackStatus.submitted:
        return Colors.orange;
      case feedback_model.FeedbackStatus.inReview:
        return Colors.blue;
      case feedback_model.FeedbackStatus.resolved:
        return Colors.green;
      case feedback_model.FeedbackStatus.closed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _getStatusColor(feedback.status);
    
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
              // Header with type and status
              Row(
                children: [
                  Text(
                    feedback_model.FeedbackType.getIcon(feedback.feedbackType),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback_model.FeedbackType.getLabel(feedback.feedbackType),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (feedback.status != null)
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
                        feedback_model.FeedbackStatus.getLabel(feedback.status!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                feedback.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Member and date
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
                      feedback.memberName ?? 'Unknown Member',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (feedback.created != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(feedback.created!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Admin response indicator
              if (feedback.adminResponse != null && feedback.adminResponse!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Response sent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackDetailsSheet extends StatefulWidget {
  final feedback_model.Feedback feedback;
  final Function(String status, String? response) onUpdateStatus;
  
  const _FeedbackDetailsSheet({
    required this.feedback,
    required this.onUpdateStatus,
  });
  
  @override
  State<_FeedbackDetailsSheet> createState() => _FeedbackDetailsSheetState();
}

class _FeedbackDetailsSheetState extends State<_FeedbackDetailsSheet> {
  final _responseController = TextEditingController();
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.feedback.adminResponse != null) {
      _responseController.text = widget.feedback.adminResponse!;
    }
  }
  
  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
  
  void _showStatusUpdateDialog(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update to ${feedback_model.FeedbackStatus.getLabel(newStatus)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a response to the member (optional):'),
            const SizedBox(height: 16),
            TextField(
              controller: _responseController,
              decoration: const InputDecoration(
                labelText: 'Response to Member',
                hintText: 'Your response will be visible to the member...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              setState(() => _isProcessing = true);
              Navigator.pop(context);
              await widget.onUpdateStatus(
                newStatus,
                _responseController.text.isEmpty ? null : _responseController.text,
              );
              if (mounted) {
                setState(() => _isProcessing = false);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final feedback = widget.feedback;
    
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
                  // Type badge
                  Row(
                    children: [
                      Text(
                        feedback_model.FeedbackType.getIcon(feedback.feedbackType),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feedback_model.FeedbackType.getLabel(feedback.feedbackType),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (feedback.status != null)
                              Text(
                                feedback_model.FeedbackStatus.getLabel(feedback.status!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _getStatusColor(feedback.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Member info
                  _DetailSection(
                    icon: Icons.person,
                    title: 'Submitted By',
                    child: Text(
                      feedback.memberName ?? 'Unknown Member',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date submitted
                  if (feedback.created != null)
                    _DetailSection(
                      icon: Icons.access_time,
                      title: 'Submitted',
                      child: Text(
                        DateFormat('MMMM dd, yyyy \'at\' h:mm a').format(feedback.created!),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  _DetailSection(
                    icon: Icons.message,
                    title: 'Message',
                    child: Text(
                      feedback.message,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  
                  if (feedback.image != null && feedback.image!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.image,
                      title: 'Attachment',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          feedback.image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  
                  if (feedback.adminResponse != null && feedback.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      icon: Icons.reply,
                      title: 'Admin Response',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feedback.adminResponse!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (feedback.status == feedback_model.FeedbackStatus.submitted)
                    FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _showStatusUpdateDialog(feedback_model.FeedbackStatus.inReview),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Mark as In Review'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  
                  if (feedback.status == feedback_model.FeedbackStatus.inReview) ...[
                    FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _showStatusUpdateDialog(feedback_model.FeedbackStatus.resolved),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as Resolved'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _showStatusUpdateDialog(feedback_model.FeedbackStatus.closed),
                      icon: const Icon(Icons.close),
                      label: const Text('Close Feedback'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                  
                  if (feedback.status == feedback_model.FeedbackStatus.resolved)
                    OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _showStatusUpdateDialog(feedback_model.FeedbackStatus.closed),
                      icon: const Icon(Icons.archive),
                      label: const Text('Archive Feedback'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
  
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case feedback_model.FeedbackStatus.submitted:
        return Colors.orange;
      case feedback_model.FeedbackStatus.inReview:
        return Colors.blue;
      case feedback_model.FeedbackStatus.resolved:
        return Colors.green;
      case feedback_model.FeedbackStatus.closed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: child,
        ),
      ],
    );
  }
}
