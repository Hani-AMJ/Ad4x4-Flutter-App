import 'package:flutter/foundation.dart';
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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreMembers();
      }
    }
  }

  /// Search members by username, first name, or last name
  Future<void> _searchMembers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _members = [];
        _hasSearched = false;
        _hasMore = true;
        _currentPage = 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _members = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // ✅ Use 'search' parameter (searches username, firstName, lastName)
      // ✅ Order by username for consistent results
      final response = await repository.getMembers(
        search: query,
        ordering: 'username',
        page: 1,
        pageSize: 50,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? 0;
      
      // Debug: Log first member structure
      if (results.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('👤 [MemberSearch] First member keys: ${(results.first as Map).keys.toList()}');
        }
      }
      
      setState(() {
        _members = results.cast<Map<String, dynamic>>();
        _hasMore = _members.length < count;
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

  /// Load more members (pagination)
  Future<void> _loadMoreMembers() async {
    if (_isLoading || !_hasMore || _searchController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      final response = await repository.getMembers(
        search: _searchController.text.trim(),
        ordering: 'username',
        page: _currentPage,
        pageSize: 50,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? 0;
      
      setState(() {
        _members.addAll(results.cast<Map<String, dynamic>>());
        _hasMore = _members.length < count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPage--; // Revert page increment on error
      });
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

                if (_members.isEmpty) {
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
                  controller: _scrollController,
                  itemCount: _members.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index >= _members.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final member = _members[index];
                    
                    // Safely extract member data with multiple fallbacks
                    final username = (member['username'] ?? member['user'] ?? '') as String;
                    final firstName = (member['firstName'] ?? member['first_name'] ?? '') as String;
                    final lastName = (member['lastName'] ?? member['last_name'] ?? '') as String;
                    final displayName = '$firstName $lastName'.trim();
                    
                    // Handle level - can be either a string or an object
                    String levelName;
                    final levelData = member['level'];
                    if (levelData is String) {
                      levelName = levelData;
                    } else if (levelData is Map<String, dynamic>) {
                      levelName = levelData['name'] as String? ?? 'No Level';
                    } else {
                      levelName = 'No Level';
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(displayName.isNotEmpty ? displayName : username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@$username', style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6))),
                          Text(levelName),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.of(context).pop({
                          'id': member['id'],
                          'username': username,
                          'firstName': firstName,
                          'lastName': lastName,
                          'displayName': displayName.isNotEmpty ? displayName : username,
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
