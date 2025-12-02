import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';

/// Admin Logbook History Screen
/// 
/// Displays a comprehensive timeline of all logbook sign-offs and entries
/// Shows chronological record of skills verified, members involved, and marshals
/// Note: This is NOT a true audit system - deleted entries are not tracked
/// Provides filtering by member, marshal, date range, and search
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() => 
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  bool _isLoading = false;
  String? _error;
  
  List<LogbookEntry> _allEntries = [];
  List<LogbookEntry> _filteredEntries = [];
  
  // Filters
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  int? _filterMemberId;
  int? _filterMarshalId;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuditLog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load all logbook entries (sorted by date)
      final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
      final entriesResults = entriesResponse['results'] as List;
      var entries = entriesResults
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
      
      // ✨ ENRICH ENTRIES to show actual names
      print('🔄 Audit Log (Logbook History): Enriching ${entries.length} entries...');
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      entries = await enrichmentService.enrichLogbookEntries(entries);
      print('✅ Audit Log (Logbook History): Enrichment complete!');
      
      // Sort by created date (most recent first)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _allEntries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load audit log: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<LogbookEntry>.from(_allEntries);
    
    // Date range filter
    if (_filterStartDate != null) {
      filtered = filtered.where((e) {
        return e.createdAt.isAfter(_filterStartDate!) || 
               e.createdAt.isAtSameMomentAs(_filterStartDate!);
      }).toList();
    }
    
    if (_filterEndDate != null) {
      final endOfDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
        23, 59, 59,
      );
      filtered = filtered.where((e) {
        return e.createdAt.isBefore(endOfDay) || 
               e.createdAt.isAtSameMomentAs(endOfDay);
      }).toList();
    }
    
    // Member filter
    if (_filterMemberId != null) {
      filtered = filtered.where((e) => e.member.id == _filterMemberId).toList();
    }
    
    // Marshal filter
    if (_filterMarshalId != null) {
      filtered = filtered.where((e) => e.signedBy.id == _filterMarshalId).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        final memberName = e.member.displayName.toLowerCase();
        final marshalName = e.signedBy.displayName.toLowerCase();
        final comment = (e.comment ?? '').toLowerCase();
        final skills = e.skillsVerified.map((s) => s.name.toLowerCase()).join(' ');
        
        return memberName.contains(query) ||
               marshalName.contains(query) ||
               comment.contains(query) ||
               skills.contains(query);
      }).toList();
    }
    
    setState(() {
      _filteredEntries = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _filterMemberId = null;
      _filterMarshalId = null;
      _searchQuery = '';
      _searchController.clear();
      _filteredEntries = _allEntries;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterStartDate != null && _filterEndDate != null
          ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _filterStartDate = picked.start;
        _filterEndDate = picked.end;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLog,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colors),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAuditLog,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by member, marshal, skill, or comment...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _applyFilters();
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
              _applyFilters();
            },
          ),
        ),
        
        // Active filters indicator
        if (_hasActiveFilters()) _buildActiveFiltersBar(theme, colors),
        
        // Entries list
        Expanded(
          child: _filteredEntries.isEmpty
              ? _buildEmptyState(theme, colors)
              : _buildEntriesList(theme, colors),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _filterStartDate != null ||
           _filterEndDate != null ||
           _filterMemberId != null ||
           _filterMarshalId != null ||
           _searchQuery.isNotEmpty;
  }

  Widget _buildActiveFiltersBar(ThemeData theme, ColorScheme colors) {
    final filterCount = [
      _filterStartDate != null || _filterEndDate != null,
      _filterMemberId != null,
      _filterMarshalId != null,
      _searchQuery.isNotEmpty,
    ].where((f) => f).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 20, color: colors.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$filterCount filter(s) active • ${_filteredEntries.length} of ${_allEntries.length} entries',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear All',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: colors.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() ? 'No entries match filters' : 'No audit log entries',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntriesList(ThemeData theme, ColorScheme colors) {
    // Group entries by date
    final groupedEntries = <String, List<LogbookEntry>>{};
    
    for (final entry in _filteredEntries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.createdAt);
      if (!groupedEntries.containsKey(dateKey)) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }
    
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final entries = groupedEntries[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8, top: index == 0 ? 0 : 16),
              child: Text(
                _formatDateHeader(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            
            // Entries for this date
            ...entries.map((entry) => _buildAuditLogCard(entry, theme, colors)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);
    
    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  Widget _buildAuditLogCard(
    LogbookEntry entry,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Time and Action
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(entry.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.verified_user, size: 16, color: colors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Skills Sign-Off',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Entry #${entry.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Marshal and Member info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marshal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            size: 16,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.signedBy.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.member.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Trip info (if available)
            if (entry.trip != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.explore,
                    size: 16,
                    color: colors.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Trip: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.trip!.title,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Skills verified
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.skillsVerified.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    skill.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            // Comment (if present)
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
                      Icons.comment,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.comment!,
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
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filter History'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range filter
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Date Range'),
                  subtitle: _filterStartDate != null && _filterEndDate != null
                      ? Text(
                          '${DateFormat('MMM d, yyyy').format(_filterStartDate!)} - ${DateFormat('MMM d, yyyy').format(_filterEndDate!)}',
                        )
                      : const Text('All dates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _selectDateRange();
                  },
                ),
                
                const Divider(),
                
                // Info about other filters
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Filters',
                        style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Use the search bar to filter by member, marshal, skill, or comment\n'
                        '• Date range filter allows you to view entries within specific timeframes\n'
                        '• Clear all filters using the "Clear All" button',
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_hasActiveFilters())
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _clearFilters();
                },
                child: const Text('Clear Filters'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
