import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';

/// Admin Create Logbook Entry Screen
/// 
/// Form to create new logbook entry with skill sign-off
/// Accessible by users with create_logbook_entries permission
class AdminCreateLogbookEntryScreen extends ConsumerStatefulWidget {
  const AdminCreateLogbookEntryScreen({super.key});

  @override
  ConsumerState<AdminCreateLogbookEntryScreen> createState() =>
      _AdminCreateLogbookEntryScreenState();
}

class _AdminCreateLogbookEntryScreenState
    extends ConsumerState<AdminCreateLogbookEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  
  int? _selectedMemberId;
  String? _selectedMemberName;
  int? _selectedTripId;
  String? _selectedTripTitle;
  
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _trips = [];
  List<LogbookSkill> _skills = [];
  Set<int> _selectedSkillIds = {};
  
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load members
      final membersResponse = await repository.getMembers(page: 1, pageSize: 100);
      final membersList = (membersResponse['results'] as List<dynamic>?)
          ?.map((m) => m as Map<String, dynamic>)
          .toList() ?? [];
      
      // Load recent trips
      final tripsResponse = await repository.getTrips(page: 1, pageSize: 50);
      final tripsList = (tripsResponse['results'] as List<dynamic>?)
          ?.map((t) => t as Map<String, dynamic>)
          .toList() ?? [];
      
      // Load skills
      final skillsResponse = await repository.getLogbookSkills(pageSize: 100);
      final skillsData = LogbookSkillsResponse.fromJson(skillsResponse);
      
      setState(() {
        _members = membersList;
        _trips = tripsList;
        _skills = skillsData.results;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }
    
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip')),
      );
      return;
    }
    
    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(logbookActionsProvider.notifier).createEntry(
        tripId: _selectedTripId!,
        memberId: _selectedMemberId!,
        skillIds: _selectedSkillIds.toList(),
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logbook entry created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canCreate = user?.hasPermission('create_logbook_entries') ?? false;
    if (!canCreate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Logbook Entry')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Access Denied', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('You don\'t have permission to create logbook entries'),
            ],
          ),
        ),
      );
    }

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Logbook Entry')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Logbook Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Member selection
            _buildMemberSelection(theme, colors),
            const SizedBox(height: 16),
            
            // Trip selection
            _buildTripSelection(theme, colors),
            const SizedBox(height: 16),
            
            // Skills selection
            _buildSkillsSelection(theme, colors),
            const SizedBox(height: 16),
            
            // Comment
            _buildCommentField(theme, colors),
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Logbook Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedMemberId,
          decoration: InputDecoration(
            hintText: 'Select member',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _members.map((member) {
            final firstName = member['first_name'] as String? ?? member['firstName'] as String? ?? '';
            final lastName = member['last_name'] as String? ?? member['lastName'] as String? ?? '';
            final displayName = '$firstName $lastName'.trim();
            final id = member['id'] as int;
            
            return DropdownMenuItem<int>(
              value: id,
              child: Text(displayName.isNotEmpty ? displayName : 'Unknown'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMemberId = value;
              if (value != null) {
                final member = _members.firstWhere((m) => m['id'] == value);
                final firstName = member['first_name'] as String? ?? member['firstName'] as String? ?? '';
                final lastName = member['last_name'] as String? ?? member['lastName'] as String? ?? '';
                _selectedMemberName = '$firstName $lastName'.trim();
              }
            });
          },
          validator: (value) {
            if (value == null) return 'Please select a member';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTripSelection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedTripId,
          decoration: InputDecoration(
            hintText: 'Select trip',
            prefixIcon: const Icon(Icons.directions_car),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _trips.map((trip) {
            final title = trip['title'] as String? ?? 'Unknown Trip';
            final id = trip['id'] as int;
            
            return DropdownMenuItem<int>(
              value: id,
              child: Text(title),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTripId = value;
              if (value != null) {
                final trip = _trips.firstWhere((t) => t['id'] == value);
                _selectedTripTitle = trip['title'] as String?;
              }
            });
          },
          validator: (value) {
            if (value == null) return 'Please select a trip';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSkillsSelection(ThemeData theme, ColorScheme colors) {
    // Group skills by level
    final skillsByLevel = <LevelBasicInfo, List<LogbookSkill>>{};
    for (final skill in _skills) {
      skillsByLevel.putIfAbsent(skill.level, () => []).add(skill);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills Verified (${_selectedSkillIds.length} selected)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: skillsByLevel.entries.map((entry) {
              final level = entry.key;
              final skills = entry.value;
              
              return ExpansionTile(
                title: Text(level.name),
                subtitle: Text('${skills.length} skills'),
                children: skills.map((skill) {
                  final isSelected = _selectedSkillIds.contains(skill.id);
                  
                  return CheckboxListTile(
                    title: Text(skill.name),
                    subtitle: Text(skill.description),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSkillIds.add(skill.id);
                        } else {
                          _selectedSkillIds.remove(skill.id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Add any additional notes or observations...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.comment),
            ),
          ),
        ),
      ],
    );
  }
}
