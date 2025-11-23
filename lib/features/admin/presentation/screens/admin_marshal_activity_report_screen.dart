import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';

/// Admin Marshal Activity Report Screen
/// 
/// Tracks marshal sign-off activity and statistics
/// Shows which marshals are most active and their performance metrics
class AdminMarshalActivityReportScreen extends ConsumerStatefulWidget {
  const AdminMarshalActivityReportScreen({super.key});

  @override
  ConsumerState<AdminMarshalActivityReportScreen> createState() => 
      _AdminMarshalActivityReportScreenState();
}

class _AdminMarshalActivityReportScreenState 
    extends ConsumerState<AdminMarshalActivityReportScreen> {
  bool _isLoading = false;
  String? _error;
  
  // Data
  List<LogbookEntry> _allEntries = [];
  List<Map<String, dynamic>> _marshalStats = [];
  
  // Filters
  String _sortBy = 'entries_desc'; // entries_desc, entries_asc, skills_desc, skills_asc, members_desc
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load all logbook entries
      final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
      final entriesResults = entriesResponse['results'] as List;
      final entries = entriesResults
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
      
      setState(() {
        _allEntries = entries;
        _isLoading = false;
      });
      
      _calculateMarshalStats();
    } catch (e) {
      setState(() {
        _error = 'Failed to load marshal activity report: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateMarshalStats() {
    var filteredEntries = List<LogbookEntry>.from(_allEntries);
    
    // Apply date filters
    if (_filterStartDate != null) {
      filteredEntries = filteredEntries.where((entry) {
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
      filteredEntries = filteredEntries.where((entry) {
        return entry.createdAt.isBefore(endOfDay) ||
               entry.createdAt.isAtSameMomentAs(endOfDay);
      }).toList();
    }
    
    // Group by marshal
    final marshalEntries = <int, List<LogbookEntry>>{};
    for (final entry in filteredEntries) {
      final marshalId = entry.signedBy.id;
      if (!marshalEntries.containsKey(marshalId)) {
        marshalEntries[marshalId] = [];
      }
      marshalEntries[marshalId]!.add(entry);
    }
    
    // Calculate stats for each marshal
    final stats = <Map<String, dynamic>>[];
    for (final marshalId in marshalEntries.keys) {
      final entries = marshalEntries[marshalId]!;
      final firstEntry = entries.first;
      
      // Unique members signed off
      final uniqueMembers = entries
          .map((e) => e.member.id)
          .toSet()
          .length;
      
      // Total skills verified
      final totalSkills = entries
          .expand((e) => e.skillsVerified)
          .length;
      
      // Average skills per entry
      final avgSkills = totalSkills / entries.length;
      
      // Last activity
      final lastActivity = entries
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          .createdAt;
      
      // Activity in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentEntries = entries
          .where((e) => e.createdAt.isAfter(thirtyDaysAgo))
          .length;
      
      stats.add({
        'marshalId': marshalId,
        'marshalName': firstEntry.signedBy.displayName,
        'totalEntries': entries.length,
        'uniqueMembers': uniqueMembers,
        'totalSkills': totalSkills,
        'avgSkills': avgSkills,
        'lastActivity': lastActivity,
        'recentEntries': recentEntries,
      });
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'entries_desc':
        stats.sort((a, b) => 
          (b['totalEntries'] as int).compareTo(a['totalEntries'] as int));
        break;
      case 'entries_asc':
        stats.sort((a, b) => 
          (a['totalEntries'] as int).compareTo(b['totalEntries'] as int));
        break;
      case 'skills_desc':
        stats.sort((a, b) => 
          (b['totalSkills'] as int).compareTo(a['totalSkills'] as int));
        break;
      case 'skills_asc':
        stats.sort((a, b) => 
          (a['totalSkills'] as int).compareTo(b['totalSkills'] as int));
        break;
      case 'members_desc':
        stats.sort((a, b) => 
          (b['uniqueMembers'] as int).compareTo(a['uniqueMembers'] as int));
        break;
    }
    
    setState(() {
      _marshalStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marshal Activity Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header with overall stats
        _buildHeader(theme, colors),
        
        // Filters
        _buildFilters(theme, colors),
        
        // Marshal list
        Expanded(
          child: _marshalStats.isEmpty
              ? _buildEmptyState(theme, colors)
              : _buildMarshalList(theme, colors),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    final totalMarshals = _marshalStats.length;
    final totalEntries = _marshalStats.isEmpty ? 0 : _marshalStats
        .map((m) => m['totalEntries'] as int)
        .reduce((a, b) => a + b);
    final totalSkills = _marshalStats.isEmpty ? 0 : _marshalStats
        .map((m) => m['totalSkills'] as int)
        .reduce((a, b) => a + b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat(
            'Marshals',
            totalMarshals.toString(),
            Icons.person_pin,
            colors.primary,
            theme,
          ),
          _buildHeaderStat(
            'Total Sign-Offs',
            totalEntries.toString(),
            Icons.receipt_long,
            colors.secondary,
            theme,
          ),
          _buildHeaderStat(
            'Skills Verified',
            totalSkills.toString(),
            Icons.verified,
            colors.tertiary,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme, ColorScheme colors) {
    final hasActiveFilters = _filterStartDate != null || _filterEndDate != null;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      prefixIcon: const Icon(Icons.sort, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'entries_desc', child: Text('Most Sign-Offs')),
                      DropdownMenuItem(value: 'entries_asc', child: Text('Least Sign-Offs')),
                      DropdownMenuItem(value: 'skills_desc', child: Text('Most Skills')),
                      DropdownMenuItem(value: 'skills_asc', child: Text('Least Skills')),
                      DropdownMenuItem(value: 'members_desc', child: Text('Most Members')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _calculateMarshalStats();
                      }
                    },
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                      _calculateMarshalStats();
                    },
                    tooltip: 'Clear Filters',
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date range filters
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
                        _calculateMarshalStats();
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _filterStartDate != null
                          ? DateFormat('MMM d, y').format(_filterStartDate!)
                          : 'From Date',
                      style: const TextStyle(fontSize: 12),
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
                        _calculateMarshalStats();
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _filterEndDate != null
                          ? DateFormat('MMM d, y').format(_filterEndDate!)
                          : 'To Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No marshal activity found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarshalList(ThemeData theme, ColorScheme colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _marshalStats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final marshal = _marshalStats[index];
        final rank = index + 1;
        return _buildMarshalCard(marshal, rank, theme, colors);
      },
    );
  }

  Widget _buildMarshalCard(
    Map<String, dynamic> marshal,
    int rank,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final marshalName = marshal['marshalName'] as String;
    final totalEntries = marshal['totalEntries'] as int;
    final uniqueMembers = marshal['uniqueMembers'] as int;
    final totalSkills = marshal['totalSkills'] as int;
    final avgSkills = marshal['avgSkills'] as double;
    final lastActivity = marshal['lastActivity'] as DateTime;
    final recentEntries = marshal['recentEntries'] as int;
    
    // Rank badge color
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = colors.outline;
    }
    
    return Card(
      elevation: rank <= 3 ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Rank and Name
            Row(
              children: [
                // Rank badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.black : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Marshal name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marshalName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last active: ${_formatRelativeDate(lastActivity)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Sign-Offs',
                    totalEntries.toString(),
                    Icons.receipt_long,
                    colors.primary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Members',
                    uniqueMembers.toString(),
                    Icons.people,
                    colors.secondary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Skills',
                    totalSkills.toString(),
                    Icons.verified,
                    colors.tertiary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Avg/Entry',
                    avgSkills.toStringAsFixed(1),
                    Icons.star,
                    const Color(0xFFFF9800),
                    theme,
                  ),
                ),
              ],
            ),
            
            // Recent activity indicator
            if (recentEntries > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      '$recentEntries sign-offs in last 30 days',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
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

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
