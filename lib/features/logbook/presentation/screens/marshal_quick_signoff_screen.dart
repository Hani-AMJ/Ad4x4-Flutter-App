import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/level_configuration_provider.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';

// Console logging that works in release mode
void _log(String message) {
  developer.log(message, name: 'QuickSignOff');
  // ignore: avoid_print
  print('[QuickSignOff] $message');
}


/// Marshal Quick Sign-Off Screen
/// Streamlined interface for marshals to quickly verify skills after trips
class MarshalQuickSignoffScreen extends ConsumerStatefulWidget {
  const MarshalQuickSignoffScreen({super.key});

  @override
  ConsumerState<MarshalQuickSignoffScreen> createState() => _MarshalQuickSignoffScreenState();
}

class _MarshalQuickSignoffScreenState extends ConsumerState<MarshalQuickSignoffScreen> {
  // Search and selection
  final TextEditingController _searchController = TextEditingController();
  final Map<int, UserModel> _selectedMembers = {};
  final Map<int, Set<int>> _memberSkills = {}; // memberId -> Set of skillIds
  final Map<int, String> _memberComments = {}; // memberId -> comment
  
  // Data
  List<UserModel> _searchResults = [];
  List<LogbookSkill> _allSkills = [];
  List<TripBasicInfo> _recentTrips = [];
  int? _selectedTripId;
  
  // UI State
  bool _isSearching = false;
  bool _isLoadingSkills = false;
  bool _isLoadingTrips = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Filter state
  int? _selectedLevelFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAllSkills(),
      _loadRecentTrips(),
    ]);
  }

  Future<void> _loadAllSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getLogbookSkills(page: 1, pageSize: 100);
      
      final skills = (response['results'] as List<dynamic>)
          .map((json) {
            try {
              return LogbookSkill.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Failed to parse skill: $e');
              }
              return null;
            }
          })
          .whereType<LogbookSkill>()
          .toList();
      
      // Sort by level, then order
      skills.sort((a, b) {
        final levelCompare = a.level.id.compareTo(b.level.id);
        if (levelCompare != 0) return levelCompare;
        return a.order.compareTo(b.order);
      });
      
      setState(() {
        _allSkills = skills;
        _isLoadingSkills = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load skills: $e';
        _isLoadingSkills = false;
      });
    }
  }

  Future<void> _loadRecentTrips() async {
    setState(() {
      _isLoadingTrips = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getTrips(
        page: 1, 
        pageSize: 10,
        ordering: '-start_time', // ✅ Show newest trips first
      );
      
      final trips = (response['results'] as List<dynamic>)
          .map((json) => TripBasicInfo.fromJson(json))
          .toList();
      
      // Debug: Log first 3 trips to verify ordering
      if (trips.isNotEmpty) {
        print('🔍 [QuickSignOff] Loaded ${trips.length} recent trips (first 3):');
        for (var i = 0; i < (trips.length > 3 ? 3 : trips.length); i++) {
          print('   ${i + 1}. ${trips[i].title} - Start: ${trips[i].startTime}');
        }
      }
      
      setState(() {
        _recentTrips = trips;
        _isLoadingTrips = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTrips = false;
      });
    }
  }

  Future<void> _searchMembers(String query) async {
    _log('🔍 Starting member search for query: "$query"');
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      _log('🔍 Calling getMembers API...');
      
      final response = await repository.getMembers(
        firstNameContains: query,
        page: 1,
        pageSize: 20,
      );
      
      _log('🔍 API response received');
      _log('🔍 Response keys: ${response.keys.toList()}');
      _log('🔍 Response has results: ${response.containsKey('results')}');
      
      // Safely parse results with error handling
      final results = response['results'];
      if (results == null) {
        throw Exception('No results field in response');
      }
      
      _log('🔍 Results is List: ${results is List}');
      _log('🔍 Results length: ${(results as List).length}');
      
      final members = <UserModel>[];
      int parseSuccessCount = 0;
      int parseFailCount = 0;
      
      for (final json in results as List<dynamic>) {
        try {
          final member = UserModel.fromJson(json as Map<String, dynamic>);
          members.add(member);
          parseSuccessCount++;
        } catch (parseError, stackTrace) {
          parseFailCount++;
          _log('❌ Failed to parse member: $parseError');
          _log('❌ Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
          _log('❌ Member data: $json');
        }
      }
      
      _log('✅ Parsing complete:');
      _log('   - Success: $parseSuccessCount members');
      _log('   - Failed: $parseFailCount members');
      _log('   - Final members list length: ${members.length}');
      if (members.isNotEmpty) {
        _log('   - First member: ${members.first.displayName} (ID: ${members.first.id})');
      }
      
      setState(() {
        _searchResults = members;
        _isSearching = false;
        _log('🔄 setState called with ${members.length} members');
        _log('🔄 _searchResults.length = ${_searchResults.length}');
        _log('🔄 _searchResults.isEmpty = ${_searchResults.isEmpty}');
      });
      
      _log('✅ Search completed successfully');
    } catch (e) {
      _log('❌ Search error: $e');
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isSearching = false;
      });
    }
  }

  void _toggleMemberSelection(UserModel member) {
    setState(() {
      if (_selectedMembers.containsKey(member.id)) {
        _selectedMembers.remove(member.id);
        _memberSkills.remove(member.id);
        _memberComments.remove(member.id);
      } else {
        _selectedMembers[member.id] = member;
        _memberSkills[member.id] = {};
      }
    });
  }

  void _toggleSkillForAllMembers(int skillId) {
    setState(() {
      final allHaveSkill = _selectedMembers.keys.every(
        (memberId) => _memberSkills[memberId]?.contains(skillId) ?? false,
      );
      
      for (final memberId in _selectedMembers.keys) {
        final skills = _memberSkills[memberId] ?? {};
        if (allHaveSkill) {
          skills.remove(skillId);
        } else {
          skills.add(skillId);
        }
        _memberSkills[memberId] = skills;
      }
    });
  }

  Future<void> _submitSignoffs() async {
    // Validate
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    final membersWithSkills = _memberSkills.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (membersWithSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill for a member')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final authState = ref.read(authProviderV2);
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      int successCount = 0;
      int errorCount = 0;

      // Create logbook entry for each member
      for (final entry in membersWithSkills) {
        final memberId = entry.key;
        final skillIds = entry.value.toList();
        final comment = _memberComments[memberId];

        try {
          await repository.createLogbookEntry(
            memberId: memberId,
            tripId: _selectedTripId ?? 0,
            skillIds: skillIds,
            comment: comment,
          );
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      if (mounted) {
        if (errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully signed off skills for $successCount member(s)'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear selections
          setState(() {
            _selectedMembers.clear();
            _memberSkills.clear();
            _memberComments.clear();
            _selectedTripId = null;
            _searchResults = [];
            _searchController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Completed with errors: $successCount success, $errorCount failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit sign-offs: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sign-Off'),
        actions: [
          if (_selectedMembers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    '${_selectedMembers.length} member(s)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: colors.primaryContainer,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Member Selection
                  _buildSectionCard(
                    context,
                    title: '1. Select Members',
                    icon: Icons.people,
                    child: Column(
                      children: [
                        _buildMemberSearchBar(),
                        const SizedBox(height: 12),
                        _buildSelectedMembersList(),
                        if (_searchResults.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              _log('🎨 Building search results UI with ${_searchResults.length} members');
                              return _buildSearchResults();
                            },
                          ),
                        ],
                        if (_searchResults.isEmpty && !_isSearching && _searchController.text.length >= 2)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No members found for "${_searchController.text}"',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Step 2: Trip Selection (Optional)
                  if (_selectedMembers.isNotEmpty)
                    _buildSectionCard(
                      context,
                      title: '2. Select Trip (Optional)',
                      icon: Icons.directions_car,
                      child: _buildTripSelector(),
                    ),

                  // Step 3: Skill Selection
                  if (_selectedMembers.isNotEmpty)
                    _buildSectionCard(
                      context,
                      title: '3. Select Skills to Verify',
                      icon: Icons.checklist,
                      child: _buildSkillSelector(),
                    ),

                  // Submit Button
                  if (_selectedMembers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitSignoffs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Sign Off Skills',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search members by name...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        if (value.length >= 2) {
          _searchMembers(value);
        } else if (value.isEmpty) {
          setState(() {
            _searchResults = [];
          });
        }
      },
    );
  }

  Widget _buildSelectedMembersList() {
    if (_selectedMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.person_add, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No members selected',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'Search and select members above',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Members (${_selectedMembers.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedMembers.values.map((member) {
            final skillCount = _memberSkills[member.id]?.length ?? 0;
            return Chip(
              avatar: CircleAvatar(
                child: Text(member.firstName.isNotEmpty ? member.firstName[0] : '?'),
              ),
              label: Text('${member.displayName} ($skillCount skills)'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _toggleMemberSelection(member),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = _searchResults[index];
          final isSelected = _selectedMembers.containsKey(member.id);
          
          return ListTile(
            leading: CircleAvatar(
              child: Text(member.firstName.isNotEmpty ? member.firstName[0] : '?'),
            ),
            title: Text(member.displayName),
            subtitle: Text('ID: ${member.id}'),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.add_circle_outline),
            onTap: () => _toggleMemberSelection(member),
          );
        },
      ),
    );
  }

  Widget _buildTripSelector() {
    if (_isLoadingTrips) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentTrips.isEmpty) {
      return Text(
        'No recent trips available',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Associate with a recent trip:'),
        const SizedBox(height: 12),
        ...(_recentTrips.take(5).map((trip) {
          return RadioListTile<int>(
            value: trip.id,
            groupValue: _selectedTripId,
            title: Text(trip.title),
            subtitle: Text(trip.startTime.toString().split(' ')[0]),
            onChanged: (value) {
              setState(() {
                _selectedTripId = value;
              });
            },
          );
        })),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedTripId = null;
            });
          },
          child: const Text('No trip association'),
        ),
      ],
    );
  }

  Widget _buildSkillSelector() {
    if (_isLoadingSkills) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_allSkills.isEmpty) {
      return const Text('No skills available');
    }

    // ✅ Use async FutureProvider to ensure cache is ready
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
    
    return levelConfigAsync.when(
      data: (levelConfig) {
        // Group skills by level
        final skillsByLevel = <int, List<LogbookSkill>>{};
        for (final skill in _allSkills) {
          final levelId = skill.level.id;
          skillsByLevel.putIfAbsent(levelId, () => []).add(skill);
        }

        // Filter if level filter is active
        final levelsToShow = _selectedLevelFilter != null
            ? [_selectedLevelFilter!]
            : skillsByLevel.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Levels'),
                    selected: _selectedLevelFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLevelFilter = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // ✅ Dynamic level filters based on actual levels with skills
                  ...skillsByLevel.keys.toList()..sort().map((levelId) {
                    final level = levelConfig.getLevelById(levelId);
                    if (level == null) return const SizedBox.shrink();
                    
                    final cleanName = levelConfig.getCleanLevelName(level.name);
                    final emoji = levelConfig.getLevelEmoji(levelId);
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$emoji $cleanName'),
                        selected: _selectedLevelFilter == levelId,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLevelFilter = selected ? levelId : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Skills by Level
            ...levelsToShow.map((levelId) {
              final skills = skillsByLevel[levelId] ?? [];
              return _buildLevelSkillSection(levelId, skills, levelConfig);
            }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading level config: $e'),
        ),
      ),
    );
  }

  Widget _buildLevelSkillSection(int levelId, List<LogbookSkill> skills, levelConfig) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                levelConfig.getLevelEmoji(levelId),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                () {
                  final level = levelConfig.getLevelById(levelId);
                  return level != null 
                      ? levelConfig.getCleanLevelName(level.name)
                      : 'Level $levelId';
                }(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Toggle all skills in this level for all members
                  for (final skill in skills) {
                    _toggleSkillForAllMembers(skill.id);
                  }
                },
                icon: const Icon(Icons.select_all, size: 16),
                label: const Text('Toggle All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        ...skills.map((skill) => _buildSkillCheckbox(skill)),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSkillCheckbox(LogbookSkill skill) {
    // Check if all selected members have this skill
    final allMembersHaveSkill = _selectedMembers.keys.every(
      (memberId) => _memberSkills[memberId]?.contains(skill.id) ?? false,
    );

    // Check if some members have this skill
    final someMembersHaveSkill = _selectedMembers.keys.any(
      (memberId) => _memberSkills[memberId]?.contains(skill.id) ?? false,
    );

    return CheckboxListTile(
      value: allMembersHaveSkill,
      tristate: true,
      title: Text(skill.name),
      subtitle: Text(
        skill.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      secondary: someMembersHaveSkill && !allMembersHaveSkill
          ? const Icon(Icons.remove_circle_outline, color: Colors.orange)
          : null,
      onChanged: (value) {
        _toggleSkillForAllMembers(skill.id);
      },
    );
  }

  // ✅ Removed hardcoded _getLevelName() function
  // Now using LevelConfigurationService for dynamic level names from API
}
