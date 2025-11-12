import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/admin_wizard_provider.dart';

/// Wizard Step 3: User Filter (Optional)
/// 
/// Mobile-optimized user selection for filtering trips by lead
class WizardStepUserFilter extends ConsumerStatefulWidget {
  const WizardStepUserFilter({super.key});

  @override
  ConsumerState<WizardStepUserFilter> createState() => _WizardStepUserFilterState();
}

class _WizardStepUserFilterState extends ConsumerState<WizardStepUserFilter> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel>? _members;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getMembers(
        page: 1,
        pageSize: 200, // Load all active members
      );

      final membersData = response['results'] as List<dynamic>? ?? [];
      final members = membersData
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by display name
      members.sort((a, b) => a.displayName.compareTo(b.displayName));

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredMembers {
    if (_members == null) return [];
    if (_searchQuery.isEmpty) return _members!;

    final query = _searchQuery.toLowerCase();
    return _members!.where((member) {
      return member.displayName.toLowerCase().contains(query) ||
          member.username.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(adminWizardProvider);
    final currentUser = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by trip lead',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional: Select a specific trip organizer',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // Quick options
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All Users option
              FilterChip(
                label: const Text('All Users'),
                selected: wizardState.leadUserId == null,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(adminWizardProvider.notifier).setLeadFilter(null);
                  }
                },
              ),

              // My Trips option
              if (currentUser != null)
                FilterChip(
                  label: const Text('My Trips'),
                  selected: wizardState.leadUserId == currentUser.id,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(adminWizardProvider.notifier)
                          .setLeadFilter(currentUser.id);
                    } else {
                      ref.read(adminWizardProvider.notifier).setLeadFilter(null);
                    }
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Members list
        Expanded(
          child: _buildMembersList(),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading members'),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredMembers = _filteredMembers;

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final wizardState = ref.watch(adminWizardProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final isSelected = wizardState.leadUserId == member.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                member.firstName.isNotEmpty
                    ? member.firstName[0].toUpperCase()
                    : member.username[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${member.username}'),
                if (member.level != null)
                  Text(
                    member.level!.displayName ?? member.level!.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              if (isSelected) {
                ref.read(adminWizardProvider.notifier).setLeadFilter(null);
              } else {
                ref
                    .read(adminWizardProvider.notifier)
                    .setLeadFilter(member.id);
              }
            },
          ),
        );
      },
    );
  }
}
