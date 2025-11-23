import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';

/// Sign Off Bottom Sheet
/// 
/// Modal bottom sheet for marshals to sign off skills for a member
/// Pre-filled with trip and member context
class SignOffBottomSheet extends ConsumerStatefulWidget {
  final dynamic trip;
  final Map<String, dynamic> memberData;
  final LogbookEntry? existingEntry; // null if creating new
  final VoidCallback onSuccess;

  const SignOffBottomSheet({
    super.key,
    required this.trip,
    required this.memberData,
    this.existingEntry,
    required this.onSuccess,
  });

  @override
  ConsumerState<SignOffBottomSheet> createState() => _SignOffBottomSheetState();
}

class _SignOffBottomSheetState extends ConsumerState<SignOffBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final Set<int> _selectedSkills = {};
  List<Map<String, dynamic>> _availableSkills = [];
  bool _isLoadingSkills = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Pre-populate comment if editing existing entry
    if (widget.existingEntry?.comment != null) {
      _commentController.text = widget.existingEntry!.comment!;
    }
    
    // Pre-select existing skills if editing
    if (widget.existingEntry != null) {
      _selectedSkills.addAll(
        widget.existingEntry!.skillsVerified.map((skill) => skill.id),
      );
    }
    
    _loadSkills();
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
      
      // Get member's level to filter skills
      final memberLevel = widget.memberData['level'];
      int? levelId;
      
      if (memberLevel is Map<String, dynamic>) {
        levelId = memberLevel['id'] as int?;
      }

      // Get skills for member's level (or all skills if no level)
      final response = await repository.getLogbookSkills(
        levelEq: levelId,
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

  Future<void> _handleSignOff() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final user = ref.read(authProviderV2).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final tripId = widget.trip['id'] as int;
      final memberId = widget.memberData['id'] as int;
      final comment = _commentController.text.trim();

      if (widget.existingEntry != null) {
        // Update existing entry
        await repository.updateLogbookEntry(
          id: widget.existingEntry!.id,
          tripId: tripId,
          memberId: memberId,
          skillsVerified: _selectedSkills.toList(),
          signedBy: user.id,
          comment: comment.isNotEmpty ? comment : null,
        );
      } else {
        // Create new entry
        await repository.createLogbookEntry(
          tripId: tripId,
          memberId: memberId,
          skillIds: _selectedSkills.toList(),
          signedBy: user.id,
          comment: comment.isNotEmpty ? comment : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully signed off ${_selectedSkills.length} skill(s)!',
            ),
            backgroundColor: Colors.green,
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
            content: Text('Failed to sign off skills: $e'),
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
    
    // Extract member info
    final firstName = widget.memberData['firstName'] as String? ?? '';
    final lastName = widget.memberData['lastName'] as String? ?? '';
    final username = widget.memberData['username'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    
    // Extract level info
    String levelName = 'No Level';
    final levelData = widget.memberData['level'];
    if (levelData is String) {
      levelName = levelData;
    } else if (levelData is Map<String, dynamic>) {
      levelName = levelData['name'] as String? ?? 'No Level';
    }

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
                        Icon(Icons.verified_user, color: colors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.existingEntry != null
                                ? 'Update Skills Sign-Off'
                                : 'Sign Off Skills',
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
                    
                    const SizedBox(height: 16),
                    
                    // Member info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isNotEmpty ? displayName : username,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (username.isNotEmpty)
                                  Text(
                                    '@$username',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(levelName),
                            backgroundColor: colors.primaryContainer,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Trip info card
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.trip['title'] as String? ?? 'Trip',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Pre-filled trip context',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
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
                        : _buildSkillsSelection(scrollController, theme, colors),
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
                          onPressed: _isSubmitting || _selectedSkills.isEmpty
                              ? null
                              : _handleSignOff,
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
                                ? 'Signing Off...'
                                : 'Sign Off (${_selectedSkills.length})',
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
            Text(
              'Error Loading Skills',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
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

  Widget _buildSkillsSelection(
    ScrollController scrollController,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (_availableSkills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Skills Available',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'No skills defined for this member\'s level',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Skills checklist header
        Row(
          children: [
            Icon(Icons.checklist, color: colors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select Skills to Verify (${_selectedSkills.length}/${_availableSkills.length})',
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
                child: const Text('Clear All'),
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
        }).toList(),
        
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
            hintText: 'Add any comments about this sign-off...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
