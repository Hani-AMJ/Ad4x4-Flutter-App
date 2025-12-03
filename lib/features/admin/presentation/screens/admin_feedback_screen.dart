import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/feedback.dart' as feedback_model;
import '../../../../data/repositories/main_api_repository.dart';

/// Admin Feedback Screen - Simple viewer for logged-in admin's feedback
/// Displays feedback from the database with local filtering
class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  final MainApiRepository _repository = MainApiRepository();
  
  List<feedback_model.Feedback> _allFeedback = [];
  List<feedback_model.Feedback> _filteredFeedback = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedback();
    });
  }

  /// Load feedback from backend
  Future<void> _loadFeedback() async {
    final user = ref.read(authProviderV2).user;
    if (user == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getMemberFeedback(
        memberId: user.id,
        pageSize: 100,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final feedbackList = results
          .map((item) => feedback_model.Feedback.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _allFeedback = feedbackList;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading feedback: $e');
      }
      setState(() {
        _error = 'Failed to load feedback';
        _isLoading = false;
      });
    }
  }

  /// Apply local filter
  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredFeedback = List.from(_allFeedback);
    } else {
      _filteredFeedback = _allFeedback
          .where((feedback) => feedback.feedbackType == _selectedFilter)
          .toList();
    }
  }

  /// Handle filter change
  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedFilter = value;
        _applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.surfaceContainerHighest,
            child: Row(
              children: [
                Text(
                  'Filter:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'bug', child: Text('🐛 Bug Reports')),
                      DropdownMenuItem(value: 'feature', child: Text('💡 Feature Requests')),
                      DropdownMenuItem(value: 'general', child: Text('💬 General Feedback')),
                      DropdownMenuItem(value: 'support', child: Text('❓ Support')),
                    ],
                    onChanged: _onFilterChanged,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(theme, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colors) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading feedback...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFeedback,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredFeedback.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No feedback submissions found'
                  : 'No ${feedback_model.FeedbackType.getLabel(_selectedFilter)} found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _allFeedback.isEmpty
                  ? 'Be the first to submit feedback!'
                  : 'Try selecting a different filter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFeedback.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final feedback = _filteredFeedback[index];
          return _buildFeedbackCard(feedback, theme, colors);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(
    feedback_model.Feedback feedback,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final hasImage = feedback.image != null && feedback.image!.isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type icon and label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feedback_model.FeedbackType.getIcon(feedback.feedbackType),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback_model.FeedbackType.getLabel(feedback.feedbackType),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasImage)
                        Row(
                          children: [
                            Icon(
                              Icons.image,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Image attached',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
