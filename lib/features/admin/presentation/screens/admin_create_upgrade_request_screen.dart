import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/level_model.dart';

/// Admin Create Upgrade Request Screen
/// 
/// Form to create new upgrade requests for self or others
class AdminCreateUpgradeRequestScreen extends ConsumerStatefulWidget {
  const AdminCreateUpgradeRequestScreen({super.key});

  @override
  ConsumerState<AdminCreateUpgradeRequestScreen> createState() => _AdminCreateUpgradeRequestScreenState();
}

class _AdminCreateUpgradeRequestScreenState extends ConsumerState<AdminCreateUpgradeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Level> _levels = [];
  List<Map<String, dynamic>> _members = [];
  
  int? _selectedMemberId;
  String? _selectedMemberName;
  String? _currentLevel;
  Level? _selectedRequestedLevel;
  
  bool _canCreateForOthers = false;
  bool _canCreateForSelf = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndLoadData();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    final user = ref.read(authProviderV2).user;
    if (user == null) return;

    setState(() {
      _canCreateForOthers = user.hasPermission('create_upgrade_req_for_other');
      _canCreateForSelf = user.hasPermission('create_upgrade_req_for_self');
      
      // If can only create for self, pre-select current user
      if (!_canCreateForOthers && _canCreateForSelf) {
        _selectedMemberId = user.id;
        _selectedMemberName = user.displayName;
        _currentLevel = user.level?.name ?? 'Unknown';
      }
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load levels
      final levelsResponse = await repository.getLevels();
      final levelsList = (levelsResponse as List<dynamic>?)
          ?.map((l) => Level.fromJson(l as Map<String, dynamic>))
          .where((level) => level.active)
          .toList() ?? [];
      
      // Load members if can create for others
      List<Map<String, dynamic>> membersList = [];
      if (_canCreateForOthers) {
        final membersResponse = await repository.getMembers(page: 1, pageSize: 100);
        membersList = (membersResponse['results'] as List<dynamic>?)
            ?.map((m) => m as Map<String, dynamic>)
            .toList() ?? [];
      }

      setState(() {
        _levels = levelsList;
        _members = membersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    if (_selectedRequestedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select requested level')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.createUpgradeRequest(
        memberId: _selectedMemberId!,
        requestedLevel: _selectedRequestedLevel!.name,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade request created successfully!'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
        
        // Navigate back to list
        context.go('/admin/upgrade-requests');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create request: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;

    // Permission check
    if (user == null || (!_canCreateForSelf && !_canCreateForOthers)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Permission Required', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'You do not have permission to create upgrade requests.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin/upgrade-requests'),
                child: const Text('Back to Upgrade Requests'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Upgrade Request'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              const Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Upgrade Request'),
        actions: [
          if (_isSubmitting)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submit an upgrade request for board review and voting.',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Member selection (if can create for others)
              if (_canCreateForOthers) ...[
                Text(
                  'Select Member',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedMemberId,
                  decoration: InputDecoration(
                    hintText: 'Choose a member',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: _members.map((member) {
                    final firstName = member['first_name'] as String? ?? member['firstName'] as String? ?? '';
                    final lastName = member['last_name'] as String? ?? member['lastName'] as String? ?? '';
                    final username = member['username'] as String? ?? 'Unknown';
                    final displayName = '$firstName $lastName'.trim();
                    final finalName = displayName.isNotEmpty ? displayName : username;
                    
                    return DropdownMenuItem<int>(
                      value: member['id'] as int,
                      child: Text(finalName),
                    );
                  }).toList(),
                  onChanged: _isSubmitting ? null : (value) {
                    if (value != null) {
                      final member = _members.firstWhere((m) => m['id'] == value);
                      final firstName = member['first_name'] as String? ?? member['firstName'] as String? ?? '';
                      final lastName = member['last_name'] as String? ?? member['lastName'] as String? ?? '';
                      final username = member['username'] as String? ?? 'Unknown';
                      final displayName = '$firstName $lastName'.trim();
                      final finalName = displayName.isNotEmpty ? displayName : username;
                      
                      // Get current level
                      final level = member['level'];
                      String? currentLevelName;
                      if (level != null && level is Map<String, dynamic>) {
                        currentLevelName = level['name'] as String? ?? 'Unknown';
                      }
                      
                      setState(() {
                        _selectedMemberId = value;
                        _selectedMemberName = finalName;
                        _currentLevel = currentLevelName ?? 'Unknown';
                        _selectedRequestedLevel = null; // Reset requested level
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a member';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Show current user info if creating for self
                Text(
                  'Member',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          (_selectedMemberName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMemberName ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Current Level: $_currentLevel',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Current level display
              if (_currentLevel != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Level',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium, color: colors.onSurface.withValues(alpha: 0.7)),
                                const SizedBox(width: 12),
                                Text(
                                  _currentLevel!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
                      child: Icon(Icons.arrow_forward, color: colors.primary, size: 32),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requested Level',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.primary),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Level>(
                                value: _selectedRequestedLevel,
                                hint: const Text('Select level'),
                                isExpanded: true,
                                items: _levels.map((level) {
                                  return DropdownMenuItem<Level>(
                                    value: level,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        level.displayName,
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isSubmitting ? null : (value) {
                                  setState(() {
                                    _selectedRequestedLevel = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              
              // Reason field
              Text(
                'Reason for Upgrade',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explain why this member should be upgraded. Be specific about achievements, contributions, and readiness.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 8,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Example: Has completed 15 trips as a participant, assisted with 5 trips as deputy lead, demonstrates excellent off-road skills and safety awareness...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  counterText: '',
                ),
                maxLength: 1000,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for this upgrade';
                  }
                  if (value.trim().length < 50) {
                    return 'Please provide a more detailed reason (at least 50 characters)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Upgrade Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : () => context.go('/admin/upgrade-requests'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
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
