import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../shared/widgets/widgets.dart';

/// Logbook Entry Detail Screen
/// 
/// Displays full details of a logbook entry with edit/delete options
/// - Members can view their sign-offs (read-only)
/// - Marshals who signed the entry can edit/delete
/// - Admins can edit/delete any entry
class LogbookEntryDetailScreen extends ConsumerStatefulWidget {
  final LogbookEntry entry;

  const LogbookEntryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<LogbookEntryDetailScreen> createState() => _LogbookEntryDetailScreenState();
}

class _LogbookEntryDetailScreenState extends ConsumerState<LogbookEntryDetailScreen> {
  final _repository = MainApiRepository();
  bool _isDeleting = false;

  /// Check if current user can edit this entry
  /// Returns true ONLY if user is the marshal who signed it (owner-only deletion)
  /// This aligns with backend API - no admin override permissions exist
  bool _canEditEntry() {
    final user = ref.read(currentUserProviderV2);
    if (user == null) return false;

    // Only the marshal who created this entry can delete it
    // Backend API does not provide admin override permissions for logbook entries
    if (user.id == widget.entry.signedBy.id) return true;

    return false;
  }

  /// Delete logbook entry with confirmation
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Logbook Entry'),
        content: Text(
          'Are you sure you want to delete this sign-off for ${widget.entry.member.displayName}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _repository.deleteLogbookEntry(widget.entry.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logbook entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to edit screen
  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogbookEntryEditScreen(entry: widget.entry),
      ),
    ).then((updated) {
      // If edit was successful, refresh by popping and indicating update
      if (updated == true && mounted) {
        Navigator.pop(context, true); // Return true to indicate update
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canEdit = _canEditEntry();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook Entry'),
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Entry',
              onPressed: _isDeleting ? null : _navigateToEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Entry',
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: _isDeleting
          ? const LoadingIndicator(message: 'Deleting entry...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Card
                  if (widget.entry.trip != null) ...[
                    _SectionCard(
                      icon: Icons.terrain,
                      title: 'Trip',
                      color: colors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entry.trip!.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, y').format(widget.entry.trip!.startTime),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              if (widget.entry.trip!.level != null) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.entry.trip!.level!.name,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Member Card
                  _SectionCard(
                    icon: Icons.person,
                    title: 'Member',
                    color: const Color(0xFF64B5F6),
                    child: Row(
                      children: [
                        if (widget.entry.member.profilePicture != null)
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(widget.entry.member.profilePicture!),
                          )
                        else
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colors.primary.withValues(alpha: 0.2),
                            child: Text(
                              widget.entry.member.firstName[0].toUpperCase(),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.entry.member.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.entry.member.level != null)
                                Text(
                                  widget.entry.member.level!.name,
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
                  const SizedBox(height: 16),

                  // Signed By Card
                  _SectionCard(
                    icon: Icons.verified_user,
                    title: 'Signed By',
                    color: const Color(0xFF81C784),
                    child: Row(
                      children: [
                        if (widget.entry.signedBy.profilePicture != null)
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(widget.entry.signedBy.profilePicture!),
                          )
                        else
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF81C784).withValues(alpha: 0.2),
                            child: Text(
                              widget.entry.signedBy.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF81C784),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.entry.signedBy.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.entry.signedBy.level != null)
                                Text(
                                  widget.entry.signedBy.level!.name,
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
                  const SizedBox(height: 16),

                  // Skills Verified Card
                  if (widget.entry.skillsVerified.isNotEmpty) ...[
                    _SectionCard(
                      icon: Icons.verified,
                      title: 'Skills Verified (${widget.entry.skillsVerified.length})',
                      color: const Color(0xFFFFB74D),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.entry.skillsVerified.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF81C784).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF81C784),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFF81C784),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      skill.name,
                                      style: const TextStyle(
                                        color: Color(0xFF81C784),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (skill.description.isNotEmpty)
                                      Text(
                                        skill.description,
                                        style: TextStyle(
                                          color: const Color(0xFF81C784).withValues(alpha: 0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Comment Card
                  if (widget.entry.comment != null && widget.entry.comment!.isNotEmpty) ...[
                    _SectionCard(
                      icon: Icons.comment,
                      title: 'Comment',
                      color: const Color(0xFFBA68C8),
                      child: Text(
                        widget.entry.comment!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Metadata Card
                  _SectionCard(
                    icon: Icons.info_outline,
                    title: 'Entry Information',
                    color: colors.onSurface.withValues(alpha: 0.6),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Created',
                          value: DateFormat('MMM d, y \'at\' h:mm a').format(widget.entry.createdAt),
                        ),
                        if (widget.entry.updatedAt != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Last Updated',
                            value: DateFormat('MMM d, y \'at\' h:mm a').format(widget.entry.updatedAt!),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Entry ID',
                          value: '#${widget.entry.id}',
                        ),
                      ],
                    ),
                  ),

                  // Permissions Notice
                  if (!canEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Only the marshal who signed this entry can edit or delete it.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Section Card Widget
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Logbook Entry Edit Screen
/// 
/// Allows marshals and admins to edit logbook entries
class LogbookEntryEditScreen extends ConsumerStatefulWidget {
  final LogbookEntry entry;

  const LogbookEntryEditScreen({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<LogbookEntryEditScreen> createState() => _LogbookEntryEditScreenState();
}

class _LogbookEntryEditScreenState extends ConsumerState<LogbookEntryEditScreen> {
  final _repository = MainApiRepository();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  
  List<LogbookSkillBasicInfo> _availableSkills = [];
  List<int> _selectedSkillIds = [];
  bool _isLoadingSkills = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.entry.comment ?? '';
    _selectedSkillIds = widget.entry.skillsVerified.map((s) => s.id).toList();
    _loadAvailableSkills();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Load available skills for the trip's level
  Future<void> _loadAvailableSkills() async {
    setState(() => _isLoadingSkills = true);

    try {
      final response = await _repository.getLogbookSkills(
        levelGte: widget.entry.trip?.level?.numericLevel,
        pageSize: 100,
      );

      final List<LogbookSkillBasicInfo> skills = [];
      final data = response['results'] ?? response['data'] ?? response;

      if (data is List) {
        for (var item in data) {
          try {
            skills.add(LogbookSkillBasicInfo.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ Error parsing skill: $e');
          }
        }
      }

      setState(() {
        _availableSkills = skills;
        _isLoadingSkills = false;
      });
    } catch (e) {
      print('❌ Error loading skills: $e');
      setState(() => _isLoadingSkills = false);
    }
  }

  /// Save changes to logbook entry
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _repository.patchLogbookEntry(
        id: widget.entry.id,
        updates: {
          'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          'skillsVerified': _selectedSkillIds,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logbook entry updated'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update entry: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Logbook Entry'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save Changes',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isSaving
          ? const LoadingIndicator(message: 'Saving changes...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Entry Info (Read-only)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entry Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.entry.trip != null)
                              _InfoRow(label: 'Trip', value: widget.entry.trip!.title),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'Member', value: widget.entry.member.displayName),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'Signed By', value: widget.entry.signedBy.displayName),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skills Selection
                    Text(
                      'Skills Verified',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select skills that were demonstrated during this trip',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingSkills)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableSkills.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No skills available for this level',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSkills.map((skill) {
                          final isSelected = _selectedSkillIds.contains(skill.id);
                          return FilterChip(
                            label: Text(skill.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSkillIds.add(skill.id);
                                } else {
                                  _selectedSkillIds.remove(skill.id);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF81C784).withValues(alpha: 0.3),
                            checkmarkColor: const Color(0xFF81C784),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // Comment Field
                    Text(
                      'Comment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add any comments about this sign-off...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
