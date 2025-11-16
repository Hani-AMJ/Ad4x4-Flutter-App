import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

/// Reusable Member Search Dialog
/// 
/// Searchable dialog for selecting a club member
/// Returns selected member data: {id, firstName, lastName, displayName, level}
class MemberSearchDialog extends ConsumerStatefulWidget {
  final String title;
  final String searchHint;

  const MemberSearchDialog({
    super.key,
    this.title = 'Select Member',
    this.searchHint = 'Search by name...',
  });

  @override
  ConsumerState<MemberSearchDialog> createState() => _MemberSearchDialogState();
}

class _MemberSearchDialogState extends ConsumerState<MemberSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search members by name
  Future<void> _searchMembers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredMembers = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Search by first name or last name
      final response = await repository.getMembers(
        firstNameContains: query,
        pageSize: 50,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      
      setState(() {
        _members = results.cast<Map<String, dynamic>>();
        _filteredMembers = _members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
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

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_search, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchMembers('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchMembers(value);
                    }
                  });
                },
                onSubmitted: _searchMembers,
              ),
            ),

            // Results list
            Expanded(
              child: () {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_hasSearched) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search members',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No members found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = _filteredMembers[index];
                    final firstName = member['firstName'] as String? ?? '';
                    final lastName = member['lastName'] as String? ?? '';
                    final displayName = '$firstName $lastName'.trim();
                    final level = member['level'] as Map<String, dynamic>?;
                    final levelName = level?['name'] as String? ?? 'No Level';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: Text(levelName),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.of(context).pop({
                          'id': member['id'],
                          'firstName': firstName,
                          'lastName': lastName,
                          'displayName': displayName,
                          'level': levelName,
                        });
                      },
                    );
                  },
                );
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
