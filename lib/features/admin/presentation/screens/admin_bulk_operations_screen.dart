import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';

/// Admin Bulk Operations Screen
/// 
/// Allows bulk management of logbook skills
/// - Bulk skill assignment to multiple members
/// - Bulk skill removal
/// - Batch operations with progress tracking
class AdminBulkOperationsScreen extends ConsumerStatefulWidget {
  const AdminBulkOperationsScreen({super.key});

  @override
  ConsumerState<AdminBulkOperationsScreen> createState() => 
      _AdminBulkOperationsScreenState();
}

class _AdminBulkOperationsScreenState 
    extends ConsumerState<AdminBulkOperationsScreen> {
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  
  // Data
  List<Map<String, dynamic>> _allSkills = [];
  List<LogbookEntry> _allEntries = [];
  
  // Selected items
  final Set<int> _selectedSkills = {};
  final Set<int> _selectedMembers = {};
  
  // Operation results
  int _successCount = 0;
  int _failCount = 0;
  List<String> _errors = [];

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
      
      // Load skills
      final skillsResponse = await repository.getLogbookSkills(pageSize: 100);
      final skillsResults = skillsResponse['results'] as List;
      
      // Load entries to get member list
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
      print('🔄 Bulk Operations: Enriching ${entries.length} entries...');
      final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
      final enrichedEntries = await enrichmentService.enrichLogbookEntries(entries);
      print('✅ Bulk Operations: Enrichment complete!');
      
      setState(() {
        _allSkills = skillsResults.cast<Map<String, dynamic>>();
        _allEntries = enrichedEntries; // Use enriched entries
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _executeBulkOperation() async {
    if (_selectedSkills.isEmpty || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select skills and members'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _successCount = 0;
      _failCount = 0;
      _errors.clear();
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final user = ref.read(authProviderV2).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Process each member
      for (final memberId in _selectedMembers) {
        try {
          // Check if member already has an entry for any trip
          final memberEntries = _allEntries
              .where((e) => e.member.id == memberId)
              .toList();
          
          if (memberEntries.isNotEmpty) {
            // Update existing entry (use first entry's trip)
            final firstEntry = memberEntries.first;
            final existingSkillIds = firstEntry.skillsVerified.map((s) => s.id).toSet();
            final mergedSkillIds = {...existingSkillIds, ..._selectedSkills}.toList();
            
            await repository.updateLogbookEntry(
              id: firstEntry.id,
              tripId: firstEntry.trip?.id ?? 0,
              memberId: memberId,
              skillsVerified: mergedSkillIds,
              signedBy: user.id,
              comment: 'Bulk operation: Skills added by admin',
            );
          } else {
            // Create new entry (note: requires a trip context)
            // For bulk operations, we'll skip members without existing entries
            _errors.add('Member ID $memberId: No existing logbook entry (trip context required)');
            _failCount++;
            continue;
          }
          
          _successCount++;
        } catch (e) {
          _failCount++;
          _errors.add('Member ID $memberId: $e');
        }
      }

      setState(() {
        _isProcessing = false;
      });

      // Show results
      _showResultsDialog();
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bulk operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Operation Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Success: $_successCount'),
            Text('❌ Failed: $_failCount'),
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errors.map((error) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(error, style: const TextStyle(fontSize: 12)),
                      )
                    ).toList(),
                  ),
                ),
              ),
            ],
          ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colors),
      bottomNavigationBar: _buildBottomBar(theme, colors),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _buildInfoCard(theme, colors),
          
          const SizedBox(height: 24),
          
          // Skills selection
          _buildSkillsSection(theme, colors),
          
          const SizedBox(height: 24),
          
          // Members selection
          _buildMembersSection(theme, colors),
          
          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, ColorScheme colors) {
    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Bulk Operations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select skills and members below, then click "Execute" to perform bulk skill assignment.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Note: Only members with existing logbook entries can receive bulk assignments.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Skills (${_selectedSkills.length}/${_allSkills.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSkills.clear();
                      for (final skill in _allSkills) {
                        _selectedSkills.add(skill['id'] as int);
                      }
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedSkills.clear());
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allSkills.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final skill = _allSkills[index];
              final skillId = skill['id'] as int;
              final skillName = skill['name'] as String;
              final isSelected = _selectedSkills.contains(skillId);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedSkills.add(skillId);
                    } else {
                      _selectedSkills.remove(skillId);
                    }
                  });
                },
                title: Text(skillName),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection(ThemeData theme, ColorScheme colors) {
    // Get unique members from entries
    final uniqueMembers = <int, Map<String, dynamic>>{};
    for (final entry in _allEntries) {
      final memberId = entry.member.id;
      if (!uniqueMembers.containsKey(memberId)) {
        uniqueMembers[memberId] = {
          'id': memberId,
          'name': entry.member.displayName,
          'level': entry.member.level?.name ?? 'Unspecified',
        };
      }
    }
    
    final membersList = uniqueMembers.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Members (${_selectedMembers.length}/${membersList.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedMembers.clear();
                      for (final member in membersList) {
                        _selectedMembers.add(member['id'] as int);
                      }
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedMembers.clear());
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: membersList.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = membersList[index];
              final memberId = member['id'] as int;
              final memberName = member['name'] as String;
              final memberLevel = member['level'] as String;
              final isSelected = _selectedMembers.contains(memberId);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedMembers.add(memberId);
                    } else {
                      _selectedMembers.remove(memberId);
                    }
                  });
                },
                title: Text(memberName),
                subtitle: Text(memberLevel),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedSkills.length} skills × ${_selectedMembers.length} members',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _executeBulkOperation,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isProcessing ? 'Processing...' : 'Execute Bulk Operation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
