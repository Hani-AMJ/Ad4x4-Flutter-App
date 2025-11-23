import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../data/repositories/main_api_repository.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> with SingleTickerProviderStateMixin {
  final _repository = MainApiRepository();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounceTimer;
  
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Search results
  List<SearchResult> _allResults = [];
  List<SearchResult> _tripResults = [];
  List<SearchResult> _memberResults = [];
  List<SearchResult> _photoResults = [];
  List<SearchResult> _newsResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchQuery = '';
        _allResults.clear();
        _tripResults.clear();
        _memberResults.clear();
        _photoResults.clear();
        _newsResults.clear();
      });
      return;
    }

    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _performSearch(_searchController.text);
    });
  }

  /// Perform search using real API
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      print('🔍 [Search] Searching for: $query');

      // Search all types
      final allResponse = await _repository.globalSearch(query: query, limit: 50);
      
      // Search by type for categorized results
      final tripResponse = await _repository.globalSearch(query: query, type: 'trip', limit: 20);
      final memberResponse = await _repository.globalSearch(query: query, type: 'member', limit: 20);
      
      // Parse results
      _allResults = _parseSearchResults(allResponse);
      _tripResults = _parseSearchResults(tripResponse, filterType: SearchResultType.trip);
      _memberResults = _parseSearchResults(memberResponse, filterType: SearchResultType.member);
      
      // Try gallery and news (may not be implemented in API)
      try {
        final galleryResponse = await _repository.globalSearch(query: query, type: 'gallery', limit: 20);
        _photoResults = _parseSearchResults(galleryResponse, filterType: SearchResultType.photo);
      } catch (e) {
        print('⚠️ [Search] Gallery search not available: $e');
        _photoResults = [];
      }

      try {
        final newsResponse = await _repository.globalSearch(query: query, type: 'news', limit: 20);
        _newsResults = _parseSearchResults(newsResponse, filterType: SearchResultType.news);
      } catch (e) {
        print('⚠️ [Search] News search not available: $e');
        _newsResults = [];
      }

      print('✅ [Search] Found ${_allResults.length} total results');

      setState(() => _isSearching = false);
    } catch (e) {
      print('❌ [Search] Error: $e');
      setState(() {
        _isSearching = false;
        _allResults.clear();
        _tripResults.clear();
        _memberResults.clear();
        _photoResults.clear();
        _newsResults.clear();
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

  /// Parse search results from API response
  List<SearchResult> _parseSearchResults(Map<String, dynamic> response, {SearchResultType? filterType}) {
    final List<SearchResult> results = [];
    
    // API may return results in different formats
    final data = response['results'] ?? response['data'] ?? response;
    
    if (data is List) {
      for (var item in data) {
        try {
          final type = _determineResultType(item);
          
          // Filter by type if specified
          if (filterType != null && type != filterType) continue;

          results.add(_createSearchResult(item, type));
        } catch (e) {
          print('⚠️ [Search] Error parsing result: $e');
        }
      }
    }
    
    return results;
  }

  /// Determine result type from API data
  SearchResultType _determineResultType(Map<String, dynamic> item) {
    // Check type field if present
    if (item['type'] != null) {
      final typeStr = item['type'].toString().toLowerCase();
      if (typeStr.contains('trip')) return SearchResultType.trip;
      if (typeStr.contains('member') || typeStr.contains('user')) return SearchResultType.member;
      if (typeStr.contains('photo') || typeStr.contains('gallery')) return SearchResultType.photo;
      if (typeStr.contains('news') || typeStr.contains('article')) return SearchResultType.news;
    }

    // Infer from fields
    if (item['start_time'] != null || item['max_participants'] != null) {
      return SearchResultType.trip;
    } else if (item['first_name'] != null || item['username'] != null) {
      return SearchResultType.member;
    } else if (item['url'] != null && item['caption'] != null) {
      return SearchResultType.photo;
    } else if (item['published_at'] != null || item['content'] != null) {
      return SearchResultType.news;
    }

    return SearchResultType.trip; // Default
  }

  /// Create SearchResult from API data
  SearchResult _createSearchResult(Map<String, dynamic> item, SearchResultType type) {
    switch (type) {
      case SearchResultType.trip:
        return SearchResult(
          type: SearchResultType.trip,
          id: item['id'].toString(),
          title: item['title'] ?? 'Untitled Trip',
          subtitle: item['location'] ?? item['destination'] ?? 'Location TBA',
          description: item['description'] ?? '',
          metadata: item['start_time'] != null 
              ? _formatDate(item['start_time'])
              : '${item['participants'] ?? 0}/${item['max_participants'] ?? 0} participants',
        );

      case SearchResultType.member:
        final firstName = item['first_name'] ?? item['firstName'] ?? '';
        final lastName = item['last_name'] ?? item['lastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        
        return SearchResult(
          type: SearchResultType.member,
          id: item['id'].toString(),
          title: fullName.isNotEmpty ? fullName : (item['username'] ?? 'Unknown'),
          subtitle: item['email'] ?? 'Member #${item['id']}',
          description: item['level']?['display_name'] ?? item['level']?['displayName'] ?? 'Member',
          metadata: '${item['trip_count'] ?? item['tripCount'] ?? 0} trips', // ✅ NOTE: Shows total count (backend provides mixed count)
        );

      case SearchResultType.photo:
        return SearchResult(
          type: SearchResultType.photo,
          id: item['id'].toString(),
          title: item['title'] ?? item['caption'] ?? 'Photo',
          subtitle: item['album_title'] ?? item['gallery_name'] ?? 'Gallery',
          description: item['caption'] ?? item['description'] ?? '',
          metadata: '${item['likes'] ?? 0} likes',
        );

      case SearchResultType.news:
        return SearchResult(
          type: SearchResultType.news,
          id: item['id'].toString(),
          title: item['title'] ?? 'News Article',
          subtitle: item['category'] ?? 'News',
          description: item['content'] ?? item['description'] ?? '',
          metadata: item['published_at'] != null 
              ? _formatDate(item['published_at'])
              : 'Recent',
        );
    }
  }

  /// Format date string
  String _formatDate(dynamic dateStr) {
    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        return '${(diff.inDays / 7).floor()} weeks ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search trips, members, photos, news...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
          indicatorColor: colors.primary,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('All'),
                  if (_allResults.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _allResults.length.toString(),
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Trips (${_tripResults.length})'),
            Tab(text: 'Members (${_memberResults.length})'),
            Tab(text: 'Photos (${_photoResults.length})'),
            Tab(text: 'News (${_newsResults.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchResults(_allResults),
          _buildSearchResults(_tripResults),
          _buildSearchResults(_memberResults),
          _buildSearchResults(_photoResults),
          _buildSearchResults(_newsResults),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<SearchResult> results) {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        message: 'Start typing to search',
        subtitle: 'Search across trips, members, photos, and news',
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'No results found',
        subtitle: 'Try different keywords',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    IconData icon;
    Color iconColor;

    switch (result.type) {
      case SearchResultType.trip:
        icon = Icons.terrain;
        iconColor = colors.primary;
        break;
      case SearchResultType.member:
        icon = Icons.person;
        iconColor = Colors.blue;
        break;
      case SearchResultType.photo:
        icon = Icons.photo_library;
        iconColor = Colors.purple;
        break;
      case SearchResultType.news:
        icon = Icons.article;
        iconColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          result.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              result.subtitle,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.description,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.type.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  result.metadata,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate based on type
          switch (result.type) {
            case SearchResultType.trip:
              context.push('/trips/${result.id}');
              break;
            case SearchResultType.member:
              context.push('/members/${result.id}');
              break;
            case SearchResultType.photo:
              context.push('/gallery/album/${result.id}');
              break;
            case SearchResultType.news:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('News details coming soon')),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colors.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Models
class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String metadata;

  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.metadata,
  });
}

enum SearchResultType {
  trip,
  member,
  photo,
  news,
}
