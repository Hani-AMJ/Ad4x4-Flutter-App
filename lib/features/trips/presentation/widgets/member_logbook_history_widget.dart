import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';

/// Member Logbook History Widget
/// 
/// Displays all logbook entries for a specific member
/// Shows progression over time with trip details
class MemberLogbookHistoryWidget extends ConsumerStatefulWidget {
  final int memberId;
  final String memberName;
  final ColorScheme colors;

  const MemberLogbookHistoryWidget({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.colors,
  });

  @override
  ConsumerState<MemberLogbookHistoryWidget> createState() => 
      _MemberLogbookHistoryWidgetState();
}

class _MemberLogbookHistoryWidgetState 
    extends ConsumerState<MemberLogbookHistoryWidget> {
  bool _isLoading = false;
  List<LogbookEntry> _entries = [];
  List<LogbookEntry> _filteredEntries = [];
  String? _error;
  
  // Filter and sort state
  String _sortBy = 'date_desc'; // date_desc, date_asc, skills_desc, skills_asc
  String? _filterByMarshal;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadMemberLogbookEntries();
  }

  Future<void> _loadMemberLogbookEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load all logbook entries for this member
      final response = await repository.getLogbookEntries(
        memberId: widget.memberId,
        pageSize: 100, // Load all entries
      );
      
      final results = response['results'] as List;
      final entries = results
          .map((json) {
            try {
              return LogbookEntry.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Failed to parse logbook entry: $e');
              }
              return null;
            }
          })
          .whereType<LogbookEntry>()
          .toList();
      
      // ✨ ENRICH ENTRIES to show actual marshal names
      print('🔄 Member Logbook History: Enriching ${entries.length} entries...');
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      final enrichedEntries = await enrichmentService.enrichLogbookEntries(entries);
      print('✅ Member Logbook History: Enrichment complete!');
      
      setState(() {
        _entries = enrichedEntries; // Use enriched entries
        _isLoading = false;
      });
      
      // Apply filtering and sorting
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _error = 'Failed to load logbook history: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      // Start with all entries
      _filteredEntries = List.from(_entries);
      
      // Apply marshal filter
      if (_filterByMarshal != null && _filterByMarshal!.isNotEmpty) {
        _filteredEntries = _filteredEntries.where((entry) {
          final marshalName = entry.signedBy.displayName.toLowerCase();
          return marshalName.contains(_filterByMarshal!.toLowerCase());
        }).toList();
      }
      
      // Apply date range filter
      if (_filterStartDate != null) {
        _filteredEntries = _filteredEntries.where((entry) {
          return entry.createdAt.isAfter(_filterStartDate!) ||
                 entry.createdAt.isAtSameMomentAs(_filterStartDate!);
        }).toList();
      }
      
      if (_filterEndDate != null) {
        final endOfDay = DateTime(
          _filterEndDate!.year,
          _filterEndDate!.month,
          _filterEndDate!.day,
          23, 59, 59,
        );
        _filteredEntries = _filteredEntries.where((entry) {
          return entry.createdAt.isBefore(endOfDay) ||
                 entry.createdAt.isAtSameMomentAs(endOfDay);
        }).toList();
      }
      
      // Apply sorting
      switch (_sortBy) {
        case 'date_asc':
          _filteredEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'date_desc':
          _filteredEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'skills_asc':
          _filteredEntries.sort((a, b) => 
            a.skillsVerified.length.compareTo(b.skillsVerified.length));
          break;
        case 'skills_desc':
          _filteredEntries.sort((a, b) => 
            b.skillsVerified.length.compareTo(a.skillsVerified.length));
          break;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _sortBy = 'date_desc';
      _filterByMarshal = null;
      _filterStartDate = null;
      _filterEndDate = null;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: widget.colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.colors.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMemberLogbookEntries,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: widget.colors.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No logbook entries yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Attend trips and get your skills signed off by marshals',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with statistics
        _buildHeader(theme),
        
        const SizedBox(height: 16),
        
        // Filter and Sort Controls
        _buildFilterSortControls(theme),
        
        const SizedBox(height: 16),
        
        // Filtered entries count
        if (_filteredEntries.length != _entries.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Showing ${_filteredEntries.length} of ${_entries.length} entries',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Empty filtered state
        if (_filteredEntries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 48,
                    color: widget.colors.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No entries match your filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: widget.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          )
        else
          // Logbook entries timeline
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildLogbookEntryCard(theme, _filteredEntries[index]);
            },
          ),
      ],
    );
  }

  Widget _buildFilterSortControls(ThemeData theme) {
    final hasActiveFilters = _filterByMarshal != null || 
                              _filterStartDate != null || 
                              _filterEndDate != null ||
                              _sortBy != 'date_desc';
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: widget.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Filters & Sort',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Sort dropdown
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      prefixIcon: const Icon(Icons.sort, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'date_desc', child: Text('Newest First')),
                      DropdownMenuItem(value: 'date_asc', child: Text('Oldest First')),
                      DropdownMenuItem(value: 'skills_desc', child: Text('Most Skills')),
                      DropdownMenuItem(value: 'skills_asc', child: Text('Least Skills')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _applyFiltersAndSort();
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date range filters (collapsed by default)
            ExpansionTile(
              title: Text(
                'Date Range',
                style: theme.textTheme.bodyMedium,
              ),
              leading: const Icon(Icons.date_range, size: 20),
              tilePadding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _filterStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _filterStartDate = date);
                            _applyFiltersAndSort();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _filterStartDate != null
                              ? DateFormat('MMM d, y').format(_filterStartDate!)
                              : 'From Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _filterEndDate ?? DateTime.now(),
                            firstDate: _filterStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _filterEndDate = date);
                            _applyFiltersAndSort();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _filterEndDate != null
                              ? DateFormat('MMM d, y').format(_filterEndDate!)
                              : 'To Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    // Calculate statistics
    final totalEntries = _entries.length;
    final totalSkillsVerified = _entries
        .expand((entry) => entry.skillsVerified)
        .toSet()
        .length;
    final uniqueTrips = _entries
        .where((entry) => entry.trip != null)
        .map((entry) => entry.trip!.id)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logbook Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.assessment,
                label: 'Entries',
                value: totalEntries.toString(),
                theme: theme,
              ),
              _buildStatItem(
                icon: Icons.verified,
                label: 'Skills',
                value: totalSkillsVerified.toString(),
                theme: theme,
              ),
              _buildStatItem(
                icon: Icons.landscape,
                label: 'Trips',
                value: uniqueTrips.toString(),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: widget.colors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.colors.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: widget.colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLogbookEntryCard(ThemeData theme, LogbookEntry entry) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final signedByName = entry.signedBy.displayName;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and marshal info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: widget.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormatter.format(entry.createdAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.colors.primary,
                      ),
                    ),
                  ],
                ),
                // Time
                Text(
                  timeFormatter.format(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Marshal info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: widget.colors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Signed by: $signedByName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Skills verified
            if (entry.skillsVerified.isNotEmpty) ...[
              Text(
                'Skills Verified (${entry.skillsVerified.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.skillsVerified.map((skill) {
                  return _buildSkillChip(theme, skill);
                }).toList(),
              ),
            ],
            
            // Comment (if exists)
            if (entry.comment != null && entry.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.colors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.comment,
                      size: 14,
                      color: widget.colors.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.comment!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.colors.onSurface.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(ThemeData theme, LogbookSkillBasicInfo skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.colors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: widget.colors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            skill.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.colors.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _getLevelColor(skill.level.name),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              skill.level.name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return widget.colors.tertiary;
      case 'intermediate':
        return const Color(0xFF2196F3); // Blue
      case 'advanced':
        return const Color(0xFFFF9800); // Orange
      case 'expert':
        return const Color(0xFFE91E63); // Pink
      default:
        return widget.colors.outline;
    }
  }
}
