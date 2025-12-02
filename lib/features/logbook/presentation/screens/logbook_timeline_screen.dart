import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/logbook_enrichment_service.dart';

import '../../../../shared/widgets/widgets.dart';
import 'logbook_entry_detail_screen.dart';

/// Logbook Timeline Screen
/// 
/// Shows member's logbook entries (sign-offs) from trips in chronological order
/// User requirement: "Option A - show in member's logbook view so they can see their sign-offs"
class LogbookTimelineScreen extends ConsumerStatefulWidget {
  const LogbookTimelineScreen({super.key});

  @override
  ConsumerState<LogbookTimelineScreen> createState() => _LogbookTimelineScreenState();
}

class _LogbookTimelineScreenState extends ConsumerState<LogbookTimelineScreen> {
  final _repository = MainApiRepository();
  final _scrollController = ScrollController();
  
  List<LogbookEntry> _entries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLogbookEntries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load logbook entries for current user
  Future<void> _loadLogbookEntries({bool isLoadMore = false}) async {
    final user = ref.read(currentUserProviderV2);
    if (user == null) return;

    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      print('📚 [Logbook] Fetching entries for member ${user.id}, page $_currentPage...');
      
      final response = await _repository.getLogbookEntries(
        memberId: user.id,
        page: _currentPage,
      );

      // Parse response
      final List<LogbookEntry> newEntries = [];
      final data = response['results'] ?? response['data'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            newEntries.add(LogbookEntry.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [Logbook] Error parsing entry: $e');
          }
        }
      }

      print('✅ [Logbook] Loaded ${newEntries.length} entries');

      // Enrich entries with actual names
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      final enrichedEntries = await enrichmentService.enrichLogbookEntries(newEntries);
      print('✅ [Logbook] Enriched ${enrichedEntries.length} entries');

      setState(() {
        if (isLoadMore) {
          _entries.addAll(enrichedEntries);
        } else {
          _entries = enrichedEntries;
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = newEntries.length >= 20;
      });
    } catch (e) {
      print('❌ [Logbook] Error: $e');
      setState(() {
        _error = 'Failed to load logbook entries';
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load logbook: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _currentPage++;
        _loadLogbookEntries(isLoadMore: true);
      }
    }
  }

  /// Navigate to entry detail screen
  void _navigateToDetail(LogbookEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogbookEntryDetailScreen(entry: entry),
      ),
    ).then((changed) {
      // Refresh list if entry was edited or deleted
      if (changed == true) {
        _currentPage = 1;
        _loadLogbookEntries();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(currentUserProviderV2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Logbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: colors.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.edit_note,
                      label: 'Total Entries',
                      value: '${_entries.length}',
                      color: const Color(0xFF64B5F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.verified,
                      label: 'Skills Verified',
                      value: _getTotalSkillsVerified().toString(),
                      color: const Color(0xFF81C784),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      label: 'Current Level',
                      value: '${user.level?.numericLevel ?? 0}',
                      color: _getLevelColor(user.level?.numericLevel ?? 0),
                    ),
                  ),
                ],
              ),
            ),

          // Loading State
          if (_isLoading && _entries.isEmpty)
            const Expanded(
              child: LoadingIndicator(message: 'Loading logbook entries...'),
            ),

          // Error State
          if (_error != null && _entries.isEmpty)
            Expanded(
              child: ErrorState(
                message: _error!,
                onRetry: () {
                  _currentPage = 1;
                  _loadLogbookEntries();
                },
              ),
            ),

          // Empty State
          if (!_isLoading && _entries.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.edit_note_outlined,
                title: 'No Logbook Entries',
                message: 'Complete trips to earn logbook sign-offs from marshals',
                actionText: 'Browse Trips',
                onAction: () => Navigator.of(context).pop(),
              ),
            ),

          // Timeline List
          if (_entries.isNotEmpty)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _currentPage = 1;
                  await _loadLogbookEntries();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _entries.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final entry = _entries[index];
                    return _LogbookEntryCard(
                      entry: entry,
                      isFirst: index == 0,
                      isLast: index == _entries.length - 1,
                      onTap: () => _navigateToDetail(entry),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get total skills verified across all entries
  int _getTotalSkillsVerified() {
    final Set<int> uniqueSkills = {};
    for (var entry in _entries) {
      for (var skill in entry.skillsVerified) {
        uniqueSkills.add(skill.id);
      }
    }
    return uniqueSkills.length;
  }

  /// Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Logbook'),
        content: const Text(
          'Your logbook tracks your progress through the club\'s ranking system. '
          'After completing trips, marshals sign off on skills you\'ve demonstrated. '
          'Collect sign-offs to advance to higher levels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Get level color helper (avoids import)
Color _getLevelColor(int numericLevel) {
  if (numericLevel <= 10) {
    return const Color(0xFF4CAF50);  // Green
  } else if (numericLevel <= 100) {
    return const Color(0xFF2196F3);  // Blue
  } else if (numericLevel <= 200) {
    return const Color(0xFFE91E63);  // Pink/Red
  } else if (numericLevel <= 300) {
    return const Color(0xFF9C27B0);  // Purple
  } else if (numericLevel <= 400) {
    return const Color(0xFF673AB7);  // Deep Purple
  } else if (numericLevel <= 600) {
    return const Color(0xFFFF9800);  // Orange
  } else {
    return const Color(0xFFE5E4E2);  // Platinum instead of dark gray
  }
}

/// Logbook Entry Card Widget
class _LogbookEntryCard extends StatelessWidget {
  final LogbookEntry entry;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _LogbookEntryCard({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: colors.primary.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Entry Content
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Trip Info
                    if (entry.trip != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.terrain,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.trip!.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Signed by
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Signed by ${entry.signedBy.displayName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, y').format(entry.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    // Skills Verified
                    if (entry.skillsVerified.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Skills Verified:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.skillsVerified.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF81C784).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF81C784),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Color(0xFF81C784),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  skill.name,
                                  style: const TextStyle(
                                    color: Color(0xFF81C784),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Comment
                    if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.comment!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tap to view indicator
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),
        ],
      ),
    );
  }
}
