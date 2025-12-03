import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';

/// Bulk Sign Off Bottom Sheet
/// 
/// Allows marshals to sign off the same skills for multiple members at once
/// Useful for common skills like "Trip Participation" or "Basic 4x4 Driving"
class BulkSignOffBottomSheet extends ConsumerStatefulWidget {
  final dynamic trip;
  final List<Map<String, dynamic>> members; // All registered members
  final Map<int, LogbookEntry?> existingEntries; // memberId -> existing entry
  final VoidCallback onSuccess;

  const BulkSignOffBottomSheet({
    super.key,
    required this.trip,
    required this.members,
    required this.existingEntries,
    required this.onSuccess,
  });

  @override
  ConsumerState<BulkSignOffBottomSheet> createState() => _BulkSignOffBottomSheetState();
}

class _BulkSignOffBottomSheetState extends ConsumerState<BulkSignOffBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final Set<int> _selectedMembers = {};
  final Set<int> _selectedSkills = {};
  List<Map<String, dynamic>> _availableSkills = [];
  bool _isLoadingSkills = false;
  bool _isSubmitting = false;
  String? _error;
  
  // Filter options
  bool _filterPendingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    
    // Auto-select members who haven't been signed off yet
    if (_filterPendingOnly) {
      for (var member in widget.members) {
        final memberId = member['id'] as int;
        if (widget.existingEntries[memberId] == null) {
          _selectedMembers.add(memberId);
        }
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Get all skills (not filtered by level for bulk operations)
      final response = await repository.getLogbookSkills(
        pageSize: 100,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      
      setState(() {
        _availableSkills = results.cast<Map<String, dynamic>>();
        _isLoadingSkills = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load skills: $e';
        _isLoadingSkills = false;
      });
    }
  }

  Future<void> _handleBulkSignOff() async {
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Sign-Off'),
        content: Text(
          'Sign off ${_selectedSkills.length} skill(s) for ${_selectedMembers.length} member(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Off'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final user = ref.read(authProviderV2).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final tripId = widget.trip['id'] as int;
      final comment = _commentController.text.trim();
      final skillIds = _selectedSkills.toList();

      int successCount = 0;
      int failCount = 0;

      // Process each member
      for (final memberId in _selectedMembers) {
        try {
          final existingEntry = widget.existingEntries[memberId];
          
          if (existingEntry != null) {
            // Update existing entry - merge skills
            final existingSkillIds = existingEntry.skillsVerified.map((s) => s.id).toSet();
            final mergedSkillIds = {...existingSkillIds, ...skillIds}.toList();
            
            await repository.updateLogbookEntry(
              id: existingEntry.id,
              tripId: tripId,
              memberId: memberId,
              skillsVerified: mergedSkillIds,
              signedBy: user.id,
              comment: comment.isNotEmpty ? comment : existingEntry.comment,
            );
          } else {
            // Create new entry
            await repository.createLogbookEntry(
              tripId: tripId,
              memberId: memberId,
              skillIds: skillIds,
              signedBy: user.id,
              comment: comment.isNotEmpty ? comment : null,
            );
          }
          
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('Failed to sign off for member $memberId: $e');
        }
      }

      if (mounted) {
        final message = failCount > 0
            ? '✅ Signed off $successCount member(s), ❌ $failCount failed'
            : '✅ Successfully signed off $successCount member(s)!';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          ),
        );
        
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk sign-off failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: colors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bulk Sign-Off Skills',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign off the same skills for multiple members at once',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trip info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, color: colors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.trip['title'] as String? ?? 'Trip',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Content
              Expanded(
                child: _isLoadingSkills
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState(theme, colors)
                        : _buildContent(scrollController, theme, colors),
              ),
              
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(
                      color: colors.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || _selectedMembers.isEmpty || _selectedSkills.isEmpty
                              ? null
                              : _handleBulkSignOff,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isSubmitting
                                ? 'Processing...'
                                : 'Sign Off (${_selectedMembers.length}/${_selectedSkills.length})',
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
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Error Loading Skills', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSkills,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ScrollController scrollController,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final filteredMembers = _filterPendingOnly
        ? widget.members.where((m) => widget.existingEntries[m['id'] as int] == null).toList()
        : widget.members;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Member selection section
        Row(
          children: [
            Icon(Icons.people, color: colors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select Members (${_selectedMembers.length}/${filteredMembers.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedMembers.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _selectedMembers.clear());
                },
                child: const Text('Clear'),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Filter toggle
        SwitchListTile(
          title: const Text('Pending members only'),
          subtitle: const Text('Show only members without logbook entries'),
          value: _filterPendingOnly,
          onChanged: (value) {
            setState(() {
              _filterPendingOnly = value;
              _selectedMembers.clear();
              
              // Auto-select pending members if filter enabled
              if (value) {
                for (var member in widget.members) {
                  final memberId = member['id'] as int;
                  if (widget.existingEntries[memberId] == null) {
                    _selectedMembers.add(memberId);
                  }
                }
              }
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // Members list
        if (filteredMembers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _filterPendingOnly
                    ? 'All members have been signed off!'
                    : 'No members available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          ...filteredMembers.map((member) {
            final memberId = member['id'] as int;
            final isSelected = _selectedMembers.contains(memberId);
            final hasEntry = widget.existingEntries[memberId] != null;
            
            return _buildMemberCheckbox(member, isSelected, hasEntry, theme, colors);
          }),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        
        // Skills selection section
        Row(
          children: [
            Icon(Icons.checklist, color: colors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select Skills (${_selectedSkills.length}/${_availableSkills.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedSkills.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _selectedSkills.clear());
                },
                child: const Text('Clear'),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Skills list
        ..._availableSkills.map((skill) {
          final skillId = skill['id'] as int;
          final skillName = skill['name'] as String? ?? 'Unnamed Skill';
          final skillDescription = skill['description'] as String?;
          final isSelected = _selectedSkills.contains(skillId);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 2 : 0,
            color: isSelected
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : colors.surface,
            child: CheckboxListTile(
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
              title: Text(
                skillName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: skillDescription != null
                  ? Text(
                      skillDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  : null,
              secondary: isSelected
                  ? Icon(Icons.check_circle, color: colors.primary)
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
              controlAffinity: ListTileControlAffinity.trailing,
              activeColor: colors.primary,
            ),
          );
        }),
        
        const SizedBox(height: 24),
        
        // Comments section
        Text(
          'Comments (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add comments for all selected members...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCheckbox(
    Map<String, dynamic> member,
    bool isSelected,
    bool hasEntry,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final firstName = member['firstName'] as String? ?? '';
    final lastName = member['lastName'] as String? ?? '';
    final username = member['username'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    
    // Extract level info
    String levelName = 'No Level';
    final levelData = member['level'];
    if (levelData is String) {
      levelName = levelData;
    } else if (levelData is Map<String, dynamic>) {
      levelName = levelData['name'] as String? ?? 'No Level';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : colors.surface,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            final memberId = member['id'] as int;
            if (value == true) {
              _selectedMembers.add(memberId);
            } else {
              _selectedMembers.remove(memberId);
            }
          });
        },
        title: Text(
          displayName.isNotEmpty ? displayName : username,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            if (username.isNotEmpty) ...[
              Text(
                '@$username',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Chip(
              label: Text(levelName),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: colors.secondaryContainer,
              labelStyle: TextStyle(
                fontSize: 11,
                color: colors.onSecondaryContainer,
              ),
            ),
            if (hasEntry) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, size: 16, color: colors.tertiary),
              const SizedBox(width: 4),
              Text(
                'Has entry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.tertiary,
                ),
              ),
            ],
          ],
        ),
        secondary: isSelected
            ? Icon(Icons.check_circle, color: colors.primary)
            : Icon(
                Icons.radio_button_unchecked,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: colors.primary,
      ),
    );
  }
}
