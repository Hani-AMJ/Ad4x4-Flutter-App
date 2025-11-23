import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';
import '../widgets/member_search_dialog.dart';
import '../widgets/trip_search_dialog.dart';

/// Admin Sign Off Skills Screen
/// 
/// ✅ REDESIGNED: Uses autocomplete search dialogs instead of dropdowns
/// ✅ FIXED: Proper pagination and search in member/trip selection
/// ✅ IMPROVED: Better UX with search-based selection
/// 
/// Dedicated interface for marshals to sign off skills for members
/// Shows member's current skill status and allows batch sign-off
/// Accessible by users with sign_logbook_skills permission
class AdminSignOffSkillsScreen extends ConsumerStatefulWidget {
  const AdminSignOffSkillsScreen({super.key});

  @override
  ConsumerState<AdminSignOffSkillsScreen> createState() =>
      _AdminSignOffSkillsScreenState();
}

class _AdminSignOffSkillsScreenState
    extends ConsumerState<AdminSignOffSkillsScreen> {
  int? _selectedMemberId;
  String? _selectedMemberName;
  String? _selectedMemberUsername;
  int? _selectedTripId;
  String? _selectedTripTitle;
  
  List<MemberSkillStatus>? _memberSkills;
  
  Set<int> _skillsToSignOff = {};
  final Map<int, TextEditingController> _commentControllers = {};
  
  bool _isLoadingSkills = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMemberSkills(int memberId) async {
    setState(() {
      _isLoadingSkills = true;
      _memberSkills = null;
      _skillsToSignOff.clear();
    });
    
    try {
      final result = await ref.read(memberSkillsStatusProvider(memberId).future);
      
      setState(() {
        _memberSkills = result;
        _isLoadingSkills = false;
      });
    } catch (e) {
      setState(() => _isLoadingSkills = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load member skills: $e')),
        );
      }
    }
  }

  Future<void> _handleBatchSignOff() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }
    
    if (_skillsToSignOff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill to sign off')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign-off'),
        content: Text(
          'Sign off ${_skillsToSignOff.length} skill(s) for $_selectedMemberName?',
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
      // Sign off each selected skill
      for (final skillId in _skillsToSignOff) {
        final comment = _commentControllers[skillId]?.text.trim();
        
        await ref.read(logbookActionsProvider.notifier).signOffSkill(
          memberId: _selectedMemberId!,
          skillId: skillId,
          tripId: _selectedTripId,
          comment: comment?.isNotEmpty == true ? comment : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully signed off ${_skillsToSignOff.length} skill(s)!'),
          ),
        );
        
        // Reload member skills
        await _loadMemberSkills(_selectedMemberId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign off skills: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showMemberSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const MemberSearchDialog(
        title: 'Select Member to Sign Off Skills',
        searchHint: 'Search by username or name...',
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMemberId = result['id'] as int;
        _selectedMemberName = result['displayName'] as String;
        _selectedMemberUsername = result['username'] as String?;
      });
      
      _loadMemberSkills(_selectedMemberId!);
    }
  }

  Future<void> _showTripSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const TripSearchDialog(
        title: 'Associate with Trip (Optional)',
        searchHint: 'Search by trip title...',
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTripId = result['id'] as int;
        _selectedTripTitle = result['title'] as String;
      });
    }
  }

  void _clearMemberSelection() {
    setState(() {
      _selectedMemberId = null;
      _selectedMemberName = null;
      _selectedMemberUsername = null;
      _memberSkills = null;
      _skillsToSignOff.clear();
    });
  }

  void _clearTripSelection() {
    setState(() {
      _selectedTripId = null;
      _selectedTripTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canSignOff = user?.hasPermission('sign_logbook_skills') ?? false;
    if (!canSignOff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign Off Skills')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Access Denied', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('You don\'t have permission to sign off skills'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Off Skills'),
        actions: [
          if (_skillsToSignOff.isNotEmpty && !_isSubmitting)
            TextButton.icon(
              onPressed: _handleBatchSignOff,
              icon: const Icon(Icons.check_circle),
              label: Text('Sign Off (${_skillsToSignOff.length})'),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selection section
          _buildSelectionSection(theme, colors),
          
          // Skills matrix
          Expanded(
            child: _buildSkillsMatrix(theme, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member selection
          InkWell(
            onTap: _showMemberSearch,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Select Member *',
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: _selectedMemberId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearMemberSelection,
                      )
                    : const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _selectedMemberId != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedMemberName ?? 'Unknown',
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (_selectedMemberUsername != null)
                          Text(
                            '@$_selectedMemberUsername',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    )
                  : Text(
                      'Tap to search members...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Trip selection (optional)
          InkWell(
            onTap: _showTripSearch,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Associate with Trip (Optional)',
                prefixIcon: const Icon(Icons.directions_car),
                suffixIcon: _selectedTripId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearTripSelection,
                      )
                    : const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedTripTitle ?? 'Tap to search trips...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _selectedTripId != null
                      ? colors.onSurface
                      : colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            'Tip: Use search to find members or trips by typing username, name, or trip title',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsMatrix(ThemeData theme, ColorScheme colors) {
    if (_selectedMemberId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'Select a Member',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the member field above to search and select a member',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showMemberSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search Members'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingSkills) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memberSkills == null || _memberSkills!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'No Skills Found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No skills available for this member',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group skills by verification status
    final unverifiedSkills = _memberSkills!.where((s) => !s.verified).toList();
    final verifiedSkills = _memberSkills!.where((s) => s.verified).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMemberName ?? 'Unknown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedMemberUsername != null)
                        Text(
                          '@$_selectedMemberUsername',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${unverifiedSkills.length} unverified',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${verifiedSkills.length} verified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Unverified skills section
        if (unverifiedSkills.isNotEmpty) ...[
          Text(
            'Unverified Skills (${unverifiedSkills.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...unverifiedSkills.map((skillStatus) =>
              _buildSkillCard(skillStatus, theme, colors, false)),
          const SizedBox(height: 24),
        ],
        
        // Verified skills section
        if (verifiedSkills.isNotEmpty) ...[
          Text(
            'Verified Skills (${verifiedSkills.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...verifiedSkills.map((skillStatus) =>
              _buildSkillCard(skillStatus, theme, colors, true)),
        ],
      ],
    );
  }

  Widget _buildSkillCard(
    MemberSkillStatus skillStatus,
    ThemeData theme,
    ColorScheme colors,
    bool isVerified,
  ) {
    final skill = skillStatus.skill;
    final isSelected = _skillsToSignOff.contains(skill.id);
    
    // Get or create comment controller for this skill
    if (!_commentControllers.containsKey(skill.id)) {
      _commentControllers[skill.id] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isVerified
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ExpansionTile(
        leading: isVerified
            ? Icon(Icons.verified, color: colors.primary)
            : Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _skillsToSignOff.add(skill.id);
                    } else {
                      _skillsToSignOff.remove(skill.id);
                    }
                  });
                },
              ),
        title: Text(skill.name),
        subtitle: Text(skill.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isVerified) ...[
                  // Show verification info
                  if (skillStatus.verifiedBy != null)
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Verified by: ${skillStatus.verifiedBy!.displayName}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  if (skillStatus.verifiedAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${skillStatus.verifiedAt!.toLocal().toString().split(' ')[0]}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (skillStatus.comment != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(skillStatus.comment!),
                    ),
                  ],
                ] else ...[
                  // Comment field for sign-off
                  TextField(
                    controller: _commentControllers[skill.id],
                    maxLines: 2,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Add comment (optional)...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
