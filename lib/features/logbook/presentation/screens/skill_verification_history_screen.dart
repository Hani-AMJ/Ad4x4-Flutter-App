import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/level_configuration_provider.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';
import '../../data/providers/skill_verification_history_provider.dart';

/// Skill Verification History Screen
/// Displays complete verification history for a member with filtering and search
class SkillVerificationHistoryScreen extends ConsumerStatefulWidget {
  final int? memberId; // null = current user

  const SkillVerificationHistoryScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<SkillVerificationHistoryScreen> createState() =>
      _SkillVerificationHistoryScreenState();
}

class _SkillVerificationHistoryScreenState
    extends ConsumerState<SkillVerificationHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedLevel; // Filter by level
  bool _showOnlyWithTrips = false;
  List<LogbookSkillReference>? _enrichedReferences;
  bool _isEnriching = false;
  int? _lastEnrichedDataHash; // Track which data was enriched to avoid re-enrichment

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Enrich skill references to resolve member/verifiedBy IDs to names
  Future<void> _enrichReferences(List<LogbookSkillReference> references) async {
    if (_isEnriching) return;

    // Calculate hash to avoid re-enriching same data
    final dataHash = references.length > 0 ? references.map((r) => r.id).join(',').hashCode : 0;
    if (_lastEnrichedDataHash == dataHash) {
      print('🔄 [SkillVerificationHistory] Data already enriched, skipping...');
      return;
    }

    setState(() {
      _isEnriching = true;
    });

    try {
      print('🔄 [SkillVerificationHistory] Starting enrichment for ${references.length} references...');
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      final enriched = await enrichmentService.enrichSkillReferences(references);
      print('✅ [SkillVerificationHistory] Enrichment complete!');

      if (mounted) {
        setState(() {
          _enrichedReferences = enriched;
          _lastEnrichedDataHash = dataHash;
          _isEnriching = false;
        });
      }
    } catch (e) {
      print('⚠️ [SkillVerificationHistory] Enrichment failed: $e');
      if (mounted) {
        setState(() {
          _enrichedReferences = references; // Fallback to original
          _lastEnrichedDataHash = dataHash;
          _isEnriching = false;
        });
      }
    }
  }

  List<LogbookSkillReference> _filterReferences(
      List<LogbookSkillReference> references) {
    var filtered = references;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((ref) =>
              ref.logbookSkill.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              ref.verifiedBy.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by level
    if (_selectedLevel != null) {
      filtered = filtered
          .where((ref) => ref.logbookSkill.level.numericLevel == _selectedLevel)
          .toList();
    }

    // Filter by trip association
    if (_showOnlyWithTrips) {
      filtered = filtered.where((ref) => ref.trip != null).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final targetMemberId = widget.memberId ?? authState.user?.id;

    final historyAsync =
        ref.watch(memberSkillVerificationHistoryProvider(targetMemberId));
    final statsAsync =
        ref.watch(memberVerificationStatsProvider(targetMemberId));

    final isViewingOwnHistory = targetMemberId == authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isViewingOwnHistory
            ? 'My Verification History'
            : 'Verification History'),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats, theme),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search skills or verifiers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active Filters Display
          if (_selectedLevel != null || _showOnlyWithTrips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedLevel != null)
                    Chip(
                      label: Text('Level $_selectedLevel'),
                      onDeleted: () {
                        setState(() {
                          _selectedLevel = null;
                        });
                      },
                    ),
                  if (_showOnlyWithTrips)
                    Chip(
                      label: const Text('With Trips Only'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyWithTrips = false;
                        });
                      },
                    ),
                ],
              ),
            ),

          // Verification History List
          Expanded(
            child: historyAsync.when(
              data: (references) {
                // Trigger enrichment ONCE when data first loads
                if (_enrichedReferences == null && !_isEnriching && references.isNotEmpty) {
                  // Use WidgetsBinding to avoid infinite loops
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_enrichedReferences == null && !_isEnriching) {
                      _enrichReferences(references);
                    }
                  });
                }

                // Use enriched references if available, otherwise show unenriched
                final referencesToUse = _enrichedReferences ?? references;
                final filteredReferences = _filterReferences(referencesToUse);

                if (filteredReferences.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          references.isEmpty
                              ? 'No verifications yet'
                              : 'No verifications match your filters',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (references.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedLevel = null;
                                _showOnlyWithTrips = false;
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // ✅ Use async FutureProvider to ensure cache is ready
                final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
                
                return levelConfigAsync.when(
                  data: (levelConfig) => Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _enrichedReferences = null; // Reset enrichment
                          });
                          ref.invalidate(
                              memberSkillVerificationHistoryProvider(targetMemberId));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReferences.length,
                          itemBuilder: (context, index) {
                            return _buildVerificationCard(
                              filteredReferences[index],
                              theme,
                              levelConfig,
                            );
                          },
                        ),
                      ),
                      // Show loading indicator while enriching
                      if (_isEnriching)
                        Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Loading names...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                    child: Text('Error loading level config: $e'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading verification history',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(error.toString(),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(memberSkillVerificationHistoryProvider(
                            targetMemberId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(VerificationStats stats, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    stats.totalVerifications.toString(),
                    Icons.verified,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Skills',
                    stats.uniqueSkills.toString(),
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Verifiers',
                    stats.uniqueVerifiers.toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Trips',
                    stats.verificationsWithTrips.toString(),
                    Icons.directions_car,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            if (stats.firstVerification != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Verification',
                          style: theme.textTheme.bodySmall),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(stats.firstVerification!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Latest Verification',
                          style: theme.textTheme.bodySmall),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(stats.lastVerification!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(
      LogbookSkillReference reference, ThemeData theme, levelConfig) {
    final levelColor = levelConfig.getLevelColor(reference.logbookSkill.level.id);
    final levelEmoji = levelConfig.getLevelEmoji(reference.logbookSkill.level.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showVerificationDetails(reference);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill Name and Level
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(levelEmoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'L${reference.logbookSkill.level.numericLevel}',
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reference.logbookSkill.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Verifier Info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Verified by ${reference.verifiedBy.displayName}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm')
                        .format(reference.verifiedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              // Trip Info (if available)
              if (reference.trip != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reference.trip!.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Comment (if available)
              if (reference.comment != null && reference.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reference.comment!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationDetails(LogbookSkillReference reference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reference.logbookSkill.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Level',
                  'Level ${reference.logbookSkill.level.numericLevel} - ${reference.logbookSkill.level.name}'),
              const SizedBox(height: 12),
              _buildDetailRow('Verified By', reference.verifiedBy.displayName),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Date',
                DateFormat('MMMM dd, yyyy • HH:mm').format(reference.verifiedAt),
              ),
              if (reference.trip != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Trip', reference.trip!.title),
                _buildDetailRow(
                  'Trip Date',
                  DateFormat('MMMM dd, yyyy').format(reference.trip!.startTime),
                ),
              ],
              if (reference.comment != null &&
                  reference.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Comments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(reference.comment!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Verifications'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by Level:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Levels'),
                      selected: _selectedLevel == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedLevel = null;
                        });
                      },
                    ),
                    for (int level = 1; level <= 5; level++)
                      FilterChip(
                        label: Text('Level $level'),
                        selected: _selectedLevel == level,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedLevel = selected ? level : null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Show only trip-based verifications'),
                  value: _showOnlyWithTrips,
                  onChanged: (value) {
                    setDialogState(() {
                      _showOnlyWithTrips = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLevel = null;
                _showOnlyWithTrips = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Trigger rebuild with new filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

}
