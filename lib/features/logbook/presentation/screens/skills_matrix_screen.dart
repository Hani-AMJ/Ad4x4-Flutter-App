import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/level_configuration_provider.dart';
import '../../../../shared/widgets/widgets.dart';

/// Skills Matrix Screen
/// 
/// Interactive logbook skills visualization organized by level
/// Shows verified/unverified skills, progress tracking, and skill details
class SkillsMatrixScreen extends ConsumerStatefulWidget {
  final int? memberId; // Optional - defaults to current user

  const SkillsMatrixScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<SkillsMatrixScreen> createState() => _SkillsMatrixScreenState();
}

class _SkillsMatrixScreenState extends ConsumerState<SkillsMatrixScreen> {
  final _repository = MainApiRepository();
  
  List<LogbookSkill> _allSkills = [];
  List<MemberSkillStatus> _memberSkills = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _userProfileLevelId; // User's profile level from database
  
  // Filter states
  int? _selectedLevelId;
  bool _showVerifiedOnly = false;
  bool _showUnverifiedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSkillsData();
    });
  }

  Future<void> _loadSkillsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get target member ID and user profile level (source of truth)
      final user = ref.read(currentUserProviderV2);
      final targetMemberId = widget.memberId ?? user?.id ?? 0;
      final userProfileLevelId = user?.level?.id; // Profile level from database

      if (kDebugMode) {
        debugPrint('🔍 [SkillsMatrix] Loading data for member $targetMemberId');
        debugPrint('👤 [SkillsMatrix] User profile level ID: $userProfileLevelId');
      }

      // Load all skills and member's skill references in parallel
      final results = await Future.wait([
        _repository.getLogbookSkills(pageSize: 200),
        _repository.getMemberLogbookSkills(memberId: targetMemberId, pageSize: 200),
      ]);
      
      if (kDebugMode) {
        debugPrint('📊 [SkillsMatrix] API responses received');
      }

      // Parse all skills
      final skillsData = results[0]['results'] ?? results[0]['data'] ?? results[0];
      final List<LogbookSkill> skills = [];
      if (skillsData is List) {
        for (var item in skillsData) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              skills.add(LogbookSkill.fromJson(item));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Failed to parse skill: $e');
              }
            }
          }
        }
      }

      // Parse skill references (sign-offs)
      final skillReferencesData = results[1]['results'] ?? results[1]['data'] ?? results[1];
      final List<LogbookSkillReference> skillReferences = [];
      
      // ALWAYS log in release mode by using print instead of debugPrint
      print('🔍 [SkillsMatrix] Member skills response type: ${skillReferencesData.runtimeType}');
      print('🔍 [SkillsMatrix] Count: ${skillReferencesData is List ? skillReferencesData.length : 'N/A'}');
      
      if (skillReferencesData is List) {
        print('🔍 [SkillsMatrix] Processing ${skillReferencesData.length} items...');
        if (skillReferencesData.isNotEmpty) {
          print('🔍 [SkillsMatrix] First item: ${skillReferencesData.first}');
        }
        
        for (var item in skillReferencesData) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              final ref = LogbookSkillReference.fromJson(item);
              skillReferences.add(ref);
              print('   ✅ Skill ${ref.logbookSkill.id}: ${ref.logbookSkill.name}');
            } catch (e, stackTrace) {
              print('   ❌ Parse error: $e');
              print('   Item: $item');
              print('   Stack: $stackTrace');
            }
          } else {
            print('   ⚠️ Skipping non-map item: $item');
          }
        }
      } else {
        print('⚠️ [SkillsMatrix] Response is not a List!');
      }
      
      // Convert skill references to member skill status objects
      final List<MemberSkillStatus> memberSkills = skillReferences.map((ref) {
        return MemberSkillStatus(
          id: ref.id,
          skill: ref.logbookSkill,
          verified: true, // All skill references are verified skills
          verifiedBy: ref.verifiedBy,
          verifiedAt: ref.verifiedAt,
          verifiedOnTrip: ref.trip,
          comment: ref.comment,
        );
      }).toList();
      
      print('📊 [SkillsMatrix] Final result: ${memberSkills.length} verified skills');
      print('   Skill IDs: ${memberSkills.map((ms) => ms.skill.id).toList()}');

      setState(() {
        _allSkills = skills;
        _memberSkills = memberSkills;
        _userProfileLevelId = userProfileLevelId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Group skills by level
  Map<String, List<LogbookSkill>> get _skillsByLevel {
    final Map<String, List<LogbookSkill>> grouped = {};
    
    for (var skill in _allSkills) {
      final levelName = skill.level.name;
      if (!grouped.containsKey(levelName)) {
        grouped[levelName] = [];
      }
      grouped[levelName]!.add(skill);
    }
    
    // Sort skills within each level by order
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.order.compareTo(b.order));
    }
    
    return grouped;
  }

  /// Check if skill is verified for member
  bool _isSkillVerified(int skillId) {
    return _memberSkills.any((ms) => ms.skill.id == skillId && ms.verified);
  }

  /// Get member skill status for a skill
  MemberSkillStatus? _getMemberSkillStatus(int skillId) {
    try {
      return _memberSkills.firstWhere((ms) => ms.skill.id == skillId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate overall progress
  double get _overallProgress {
    if (_allSkills.isEmpty) return 0.0;
    final verifiedCount = _memberSkills.where((ms) => ms.verified).length;
    return verifiedCount / _allSkills.length;
  }

  /// Get filtered skills
  List<LogbookSkill> _getFilteredSkills() {
    var filtered = _allSkills;
    
    // Filter by level
    if (_selectedLevelId != null) {
      filtered = filtered.where((s) => s.level.id == _selectedLevelId).toList();
    }
    
    // Filter by verification status
    if (_showVerifiedOnly) {
      filtered = filtered.where((s) => _isSkillVerified(s.id)).toList();
    } else if (_showUnverifiedOnly) {
      filtered = filtered.where((s) => !_isSkillVerified(s.id)).toList();
    }
    
    return filtered;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Skills',
            onPressed: () {
              context.push('/logbook/skills-comparison');
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSkillsData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading skills matrix...')
          : _errorMessage != null
              ? ErrorState(
                  title: 'Error Loading Skills',
                  message: _errorMessage!,
                  onRetry: _loadSkillsData,
                )
              : _allSkills.isEmpty
                  ? const EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'No Skills Available',
                      message: 'No logbook skills have been configured yet.',
                    )
                  : Column(
                      children: [
                        // Progress Header
                        _buildProgressHeader(colors),
                        
                        // Filter Chips
                        if (_selectedLevelId != null || _showVerifiedOnly || _showUnverifiedOnly)
                          _buildActiveFilters(colors),
                        
                        // Skills List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadSkillsData,
                            child: _buildSkillsList(theme, colors),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildProgressHeader(ColorScheme colors) {
    final verifiedCount = _memberSkills.where((ms) => ms.verified).length;
    final totalCount = _allSkills.length;
    final percentage = (_overallProgress * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Overall Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$verifiedCount / $totalCount',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% Complete',
            style: TextStyle(
              fontSize: 14,
              color: colors.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 8,
              backgroundColor: colors.surface.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedLevelId != null)
            Chip(
              label: Text('Level ${_allSkills.firstWhere((s) => s.level.id == _selectedLevelId).level.name}'),
              onDeleted: () => setState(() => _selectedLevelId = null),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (_showVerifiedOnly)
            Chip(
              label: const Text('Verified Only'),
              onDeleted: () => setState(() => _showVerifiedOnly = false),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          if (_showUnverifiedOnly)
            Chip(
              label: const Text('Unverified Only'),
              onDeleted: () => setState(() => _showUnverifiedOnly = false),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedLevelId = null;
                _showVerifiedOnly = false;
                _showUnverifiedOnly = false;
              });
            },
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsList(ThemeData theme, ColorScheme colors) {
    final skillsByLevel = _skillsByLevel;
    final filteredSkills = _getFilteredSkills();
    
    // If filters are active, show flat list
    if (_selectedLevelId != null || _showVerifiedOnly || _showUnverifiedOnly) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSkills.length,
        itemBuilder: (context, index) {
          final skill = filteredSkills[index];
          final isVerified = _isSkillVerified(skill.id);
          final memberSkillStatus = _getMemberSkillStatus(skill.id);
          
          return _SkillCard(
            skill: skill,
            isVerified: isVerified,
            memberSkillStatus: memberSkillStatus,
            onTap: () => _showSkillDetails(skill, memberSkillStatus),
          );
        },
      );
    }
    
    // Otherwise show grouped by level
    final sortedLevels = skillsByLevel.keys.toList()
      ..sort((a, b) {
        final aLevel = _allSkills.firstWhere((s) => s.level.name == a).level.numericLevel;
        final bLevel = _allSkills.firstWhere((s) => s.level.name == b).level.numericLevel;
        return aLevel.compareTo(bLevel);
      });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLevels.length,
      itemBuilder: (context, index) {
        final levelName = sortedLevels[index];
        final skills = skillsByLevel[levelName]!;
        final verifiedCount = skills.where((s) => _isSkillVerified(s.id)).length;
        final levelProgress = skills.isEmpty ? 0.0 : verifiedCount / skills.length;
        final levelId = skills.first.level.id;
        final isCurrentLevel = levelId == _userProfileLevelId;
        
        // Use LevelConfigurationService for dynamic level display
        final levelConfig = ref.read(levelConfigurationProvider);
        final cleanName = levelConfig.getCleanLevelName(levelName);
        final levelColor = levelConfig.getLevelColor(levelId);
        final levelEmoji = levelConfig.getLevelEmoji(levelId);
        
        return _LevelSection(
          levelName: cleanName,
          levelColor: levelColor,
          levelEmoji: levelEmoji,
          skills: skills,
          verifiedCount: verifiedCount,
          levelProgress: levelProgress,
          isCurrentLevel: isCurrentLevel,
          isSkillVerified: _isSkillVerified,
          getMemberSkillStatus: _getMemberSkillStatus,
          onSkillTap: _showSkillDetails,
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Skills'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            final levels = _allSkills.map((s) => s.level).toSet().toList()
              ..sort((a, b) => a.numericLevel.compareTo(b.numericLevel));
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level filter
                const Text('Filter by Level:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: levels.map((level) {
                    final isSelected = _selectedLevelId == level.id;
                    return ChoiceChip(
                      label: Text(level.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedLevelId = selected ? level.id : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Verification status filter
                const Text('Filter by Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Verified Only'),
                  value: _showVerifiedOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showVerifiedOnly = value ?? false;
                      if (_showVerifiedOnly) _showUnverifiedOnly = false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Unverified Only'),
                  value: _showUnverifiedOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showUnverifiedOnly = value ?? false;
                      if (_showUnverifiedOnly) _showVerifiedOnly = false;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLevelId = null;
                _showVerifiedOnly = false;
                _showUnverifiedOnly = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSkillDetails(LogbookSkill skill, MemberSkillStatus? status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return _SkillDetailsSheet(
            skill: skill,
            status: status,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Level Section Widget
class _LevelSection extends StatelessWidget {
  final String levelName;
  final Color levelColor;
  final String levelEmoji;
  final List<LogbookSkill> skills;
  final int verifiedCount;
  final double levelProgress;
  final bool isCurrentLevel;
  final bool Function(int) isSkillVerified;
  final MemberSkillStatus? Function(int) getMemberSkillStatus;
  final void Function(LogbookSkill, MemberSkillStatus?) onSkillTap;

  const _LevelSection({
    required this.levelName,
    required this.levelColor,
    required this.levelEmoji,
    required this.skills,
    required this.verifiedCount,
    required this.levelProgress,
    required this.isCurrentLevel,
    required this.isSkillVerified,
    required this.getMemberSkillStatus,
    required this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentLevel ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentLevel
            ? BorderSide(color: levelColor, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentLevel
                  ? levelColor.withValues(alpha: 0.15)
                  : levelColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  levelEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            levelName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: levelColor,
                            ),
                          ),
                          if (isCurrentLevel) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$verifiedCount / ${skills.length} verified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: levelProgress,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(levelProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Skills List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: skills.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final skill = skills[index];
              final isVerified = isSkillVerified(skill.id);
              final status = getMemberSkillStatus(skill.id);
              
              return _SkillCard(
                skill: skill,
                isVerified: isVerified,
                memberSkillStatus: status,
                onTap: () => onSkillTap(skill, status),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Skill Card Widget
class _SkillCard extends StatelessWidget {
  final LogbookSkill skill;
  final bool isVerified;
  final MemberSkillStatus? memberSkillStatus;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.isVerified,
    required this.memberSkillStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isVerified 
          ? colors.primaryContainer.withValues(alpha: 0.2)
          : colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isVerified ? colors.primary : colors.outline.withValues(alpha: 0.2),
          width: isVerified ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Verification Icon
              Icon(
                isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isVerified ? colors.primary : colors.onSurface.withValues(alpha: 0.3),
                size: 24,
              ),
              const SizedBox(width: 12),
              
              // Skill Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isVerified ? FontWeight.bold : FontWeight.w600,
                        color: isVerified ? colors.primary : colors.onSurface,
                      ),
                    ),
                    if (skill.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        skill.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isVerified && memberSkillStatus?.verifiedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Verified ${_formatDate(memberSkillStatus!.verifiedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else {
      return '${(diff.inDays / 365).floor()} years ago';
    }
  }
}

/// Skill Details Bottom Sheet
class _SkillDetailsSheet extends StatelessWidget {
  final LogbookSkill skill;
  final MemberSkillStatus? status;
  final ScrollController scrollController;

  const _SkillDetailsSheet({
    required this.skill,
    required this.status,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isVerified = status?.verified ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Verification Status Badge
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.pending_outlined,
                color: isVerified ? colors.primary : colors.onSurface.withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isVerified ? 'Skill Verified' : 'Not Yet Verified',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isVerified ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Skill Name
          Text(
            skill.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Level ${skill.level.numericLevel}: ${skill.level.name}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            skill.description.isNotEmpty ? skill.description : 'No description available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          
          // Verification Details (if verified)
          if (isVerified && status != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Verification Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (status!.verifiedBy != null)
              _DetailRow(
                icon: Icons.person,
                label: 'Verified By',
                value: status!.verifiedBy!.displayName,
              ),
            
            if (status!.verifiedAt != null)
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Verified On',
                value: _formatFullDate(status!.verifiedAt!),
              ),
            
            if (status!.verifiedOnTrip != null)
              _DetailRow(
                icon: Icons.directions_car,
                label: 'Trip',
                value: status!.verifiedOnTrip!.title,
              ),
            
            if (status!.comment != null && status!.comment!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.comment,
                label: 'Marshal Comment',
                value: status!.comment!,
                maxLines: null,
              ),
            ],
          ],
          
          const SizedBox(height: 32),
          
          // Action Button
          if (!isVerified)
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skill verification is done by marshals on trips'),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('How to Get Verified'),
            ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int? maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                  maxLines: maxLines,
                  overflow: maxLines != null ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
