import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import 'dart:async';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _repository = MainApiRepository();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  List<UserModel> _members = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load members from API
  Future<void> _loadMembers({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('📋 [Members] Fetching page $_currentPage...');
      
      final response = await _repository.getMembers(
        page: _currentPage,
        pageSize: 20,
        firstNameContains: _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      // Parse response
      final List<UserModel> newMembers = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            newMembers.add(UserModel.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [Members] Error parsing member: $e');
          }
        }
      }

      print('✅ [Members] Loaded ${newMembers.length} members');

      setState(() {
        if (isLoadMore) {
          _members.addAll(newMembers);
        } else {
          _members = newMembers;
        }
        _isLoading = false;
        _isSearching = false;
        _hasMore = newMembers.length >= 20;  // Has more if we got a full page
      });
    } catch (e) {
      print('❌ [Members] Error: $e');
      setState(() {
        _error = 'Failed to load members';
        _isLoading = false;
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_isSearching) {
        _currentPage++;
        _loadMembers(isLoadMore: true);
      }
    }
  }

  /// Handle search with debounce
  void _onSearchChanged(String query) {
    setState(() => _isSearching = true);
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      _loadMembers();
    });
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    _currentPage = 1;
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 1;
              _loadMembers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search members by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
              ),
            ),
          ),

          // Loading Indicator (first load)
          if (_isLoading && _members.isEmpty)
            const Expanded(
              child: LoadingIndicator(message: 'Loading members...'),
            ),

          // Error State
          if (_error != null && _members.isEmpty)
            Expanded(
              child: ErrorState(
                message: _error!,
                onRetry: () {
                  _currentPage = 1;
                  _loadMembers();
                },
              ),
            ),

          // Members List
          if (!_isLoading || _members.isNotEmpty)
            Expanded(
              child: _members.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: 'No Members Found',
                      message: _searchController.text.isNotEmpty
                          ? 'No members match your search'
                          : 'No members available',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        _currentPage = 1;
                        await _loadMembers();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading indicator at bottom
                          if (index == _members.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final member = _members[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MemberCard(
                              member: member,
                              onTap: () => context.push('/members/${member.id}'),
                            ),
                          );
                        },
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Enhanced Member Card Widget
class _MemberCard extends StatelessWidget {
  final UserModel member;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final levelColor = _getLevelColor(member.level?.displayName);
    final memberName = '${member.firstName} ${member.lastName}'.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                name: memberName,
                imageUrl: member.avatar != null && member.avatar!.isNotEmpty
                    ? (member.avatar!.startsWith('http')
                        ? member.avatar
                        : 'https://media.ad4x4.com${member.avatar}')
                    : null,
                radius: 30,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      memberName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Level + Stats
                    Row(
                      children: [
                        // Level Badge
                        if (member.level?.displayName?.isNotEmpty ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: levelColor, width: 1),
                            ),
                            child: Text(
                              member.level!.displayName!,
                              style: TextStyle(
                                color: levelColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),

                        // Trip Count
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.tripCount ?? 0} trips',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get level color
  Color _getLevelColor(String? level) {
    if (level == null) return Colors.grey;
    
    final levelLower = level.toLowerCase();
    if (levelLower.contains('marshal') || levelLower.contains('admin')) {
      return const Color(0xFFD32F2F);  // Red
    } else if (levelLower.contains('explorer')) {
      return const Color(0xFF1976D2);  // Blue
    } else if (levelLower.contains('advanced')) {
      return const Color(0xFF388E3C);  // Green
    } else if (levelLower.contains('intermediate')) {
      return const Color(0xFFFFA000);  // Orange
    } else if (levelLower.contains('newbie') || levelLower.contains('beginner')) {
      return const Color(0xFF7B1FA2);  // Purple
    }
    
    return Colors.grey;
  }
}
