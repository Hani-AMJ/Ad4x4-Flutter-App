import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';
import 'package:go_router/go_router.dart';

/// Admin Member Skills Report Screen
/// 
/// Shows all members and their skill progression
/// Allows filtering by skill level, search by name, and sorting
class AdminMemberSkillsReportScreen extends ConsumerStatefulWidget {
  const AdminMemberSkillsReportScreen({super.key});

  @override
  ConsumerState<AdminMemberSkillsReportScreen> createState() => 
      _AdminMemberSkillsReportScreenState();
}

class _AdminMemberSkillsReportScreenState 
    extends ConsumerState<AdminMemberSkillsReportScreen> {
  bool _isLoading = false;
  String? _error;
  
  // Data
  List<LogbookEntry> _allEntries = [];
  List<Map<String, dynamic>> _allSkills = [];
  List<Map<String, dynamic>> _memberProgress = [];
  
  // Filters
  String _searchQuery = '';
  String _sortBy = 'name_asc'; // name_asc, name_desc, skills_desc, skills_asc
  int? _filterByLevel;

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
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      
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
      
      // ✨ ENRICH ENTRIES to show actual member names
      print('🔄 Member Skills Report: Enriching ${entries.length} entries...');
      final enrichedEntries = await enrichmentService.enrichLogbookEntries(entries);
      print('✅ Member Skills Report: Enrichment complete!');
      
      // Load all skills
      final skillsResponse = await repository.getLogbookSkills(pageSize: 100);
      final skillsResults = skillsResponse['results'] as List;
      
      // Calculate member progress with enriched entries
      final memberProgress = _calculateMemberProgress(enrichedEntries);
      
      setState(() {
        _allEntries = enrichedEntries; // Use enriched entries
        _allSkills = skillsResults.cast<Map<String, dynamic>>();
        _memberProgress = memberProgress;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load member skills report: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _calculateMemberProgress(List<LogbookEntry> entries) {
    // Group entries by member
    final memberEntries = <int, List<LogbookEntry>>{};
    for (final entry in entries) {
      final memberId = entry.member.id;
      if (!memberEntries.containsKey(memberId)) {
        memberEntries[memberId] = [];
      }
      memberEntries[memberId]!.add(entry);
    }
    
    // Calculate progress for each member
    final progress = <Map<String, dynamic>>[];
    for (final memberId in memberEntries.keys) {
      final memberEntriesList = memberEntries[memberId]!;
      final firstEntry = memberEntriesList.first;
      
      // Get unique skills verified for this member
      final uniqueSkills = memberEntriesList
          .expand((e) => e.skillsVerified)
          .map((s) => s.id)
          .toSet();
      
      // Get member level
      final memberLevel = firstEntry.member.level;
      final levelId = memberLevel?.id;
      final levelName = memberLevel?.name ?? 'Unspecified';
      
      progress.add({
        'memberId': memberId,
        'memberName': firstEntry.member.displayName,
        'levelId': levelId,
        'levelName': levelName,
        'totalEntries': memberEntriesList.length,
        'totalSkills': uniqueSkills.length,
        'lastEntry': memberEntriesList
            .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
            .createdAt,
      });
    }
    
    return progress;
  }

  void _applyFilters() {
    setState(() {
      var filtered = List<Map<String, dynamic>>.from(_memberProgress);
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((member) {
          final name = (member['memberName'] as String).toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();
      }
      
      // Apply level filter
      if (_filterByLevel != null) {
        filtered = filtered.where((member) {
          return member['levelId'] == _filterByLevel;
        }).toList();
      }
      
      // Apply sorting
      switch (_sortBy) {
        case 'name_asc':
          filtered.sort((a, b) => 
            (a['memberName'] as String).compareTo(b['memberName'] as String));
          break;
        case 'name_desc':
          filtered.sort((a, b) => 
            (b['memberName'] as String).compareTo(a['memberName'] as String));
          break;
        case 'skills_desc':
          filtered.sort((a, b) => 
            (b['totalSkills'] as int).compareTo(a['totalSkills'] as int));
          break;
        case 'skills_asc':
          filtered.sort((a, b) => 
            (a['totalSkills'] as int).compareTo(b['totalSkills'] as int));
          break;
      }
      
      _memberProgress = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Skills Report'),
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
        // Header with stats
        _buildHeader(theme, colors),
        
        // Search and filters
        _buildSearchAndFilters(theme, colors),
        
        // Member list
        Expanded(
          child: _memberProgress.isEmpty
              ? _buildEmptyState(theme, colors)
              : _buildMemberList(theme, colors),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat(
            'Total Members',
            _memberProgress.length.toString(),
            Icons.people,
            colors.primary,
            theme,
          ),
          _buildHeaderStat(
            'Avg Skills',
            _memberProgress.isEmpty ? '0' : (_memberProgress
                .map((m) => m['totalSkills'] as int)
                .reduce((a, b) => a + b) / _memberProgress.length)
                .toStringAsFixed(1),
            Icons.star,
            colors.secondary,
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
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
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

  Widget _buildSearchAndFilters(ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Sort and level filter
            Row(
              children: [
                // Sort dropdown
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
                      DropdownMenuItem(value: 'name_asc', child: Text('Name (A-Z)')),
                      DropdownMenuItem(value: 'name_desc', child: Text('Name (Z-A)')),
                      DropdownMenuItem(value: 'skills_desc', child: Text('Most Skills')),
                      DropdownMenuItem(value: 'skills_asc', child: Text('Least Skills')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _applyFilters();
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Level filter
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _filterByLevel,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      prefixIcon: const Icon(Icons.filter_list, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      DropdownMenuItem(value: 1, child: Text('Beginner')),
                      DropdownMenuItem(value: 2, child: Text('Intermediate')),
                      DropdownMenuItem(value: 3, child: Text('Advanced')),
                      DropdownMenuItem(value: 4, child: Text('Expert')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterByLevel = value);
                      _applyFilters();
                    },
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
            'No members found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(ThemeData theme, ColorScheme colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _memberProgress.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = _memberProgress[index];
        return _buildMemberCard(member, theme, colors);
      },
    );
  }

  Widget _buildMemberCard(
    Map<String, dynamic> member,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final memberId = member['memberId'] as int;
    final memberName = member['memberName'] as String;
    final levelName = member['levelName'] as String;
    final totalSkills = member['totalSkills'] as int;
    final totalEntries = member['totalEntries'] as int;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to member logbook
          context.push('/profile/logbook/$memberId?name=${Uri.encodeComponent(memberName)}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  memberName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLevelColor(levelName).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getLevelColor(levelName),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            levelName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(levelName),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$totalSkills',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalEntries ${totalEntries == 1 ? 'entry' : 'entries'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF9C27B0);
      case 'intermediate':
        return const Color(0xFF2196F3);
      case 'advanced':
        return const Color(0xFFFF9800);
      case 'expert':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }
}
