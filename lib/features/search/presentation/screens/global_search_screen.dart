import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/sample_data/sample_trips.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
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

    setState(() {
      _searchQuery = _searchController.text;
      _performSearch(_searchQuery);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final lowercaseQuery = query.toLowerCase();

      // Search trips
      _tripResults = SampleTrips.getTrips()
          .where((trip) =>
              trip.title.toLowerCase().contains(lowercaseQuery) ||
              trip.description.toLowerCase().contains(lowercaseQuery) ||
              (trip.location?.toLowerCase() ?? '').contains(lowercaseQuery))
          .map((trip) => SearchResult(
                type: SearchResultType.trip,
                id: trip.id.toString(),
                title: trip.title,
                subtitle: trip.location ?? 'Location TBA',
                description: trip.description,
                metadata: '${trip.participants}/${trip.maxParticipants} participants',
              ))
          .toList();

      // Search members (mock data)
      _memberResults = _searchMembers(lowercaseQuery);

      // Search photos (mock data)
      _photoResults = _searchPhotos(lowercaseQuery);

      // Search news (mock data)
      _newsResults = _searchNews(lowercaseQuery);

      // Combine all results
      _allResults = [
        ..._tripResults,
        ..._memberResults,
        ..._photoResults,
        ..._newsResults,
      ];

      setState(() => _isSearching = false);
    });
  }

  List<SearchResult> _searchMembers(String query) {
    final members = [
      SearchResult(
        type: SearchResultType.member,
        id: '1',
        title: 'Mohammed Al-Zaabi',
        subtitle: 'Member #M2001',
        description: 'Marshal, Expert off-roader',
        metadata: '150+ trips',
      ),
      SearchResult(
        type: SearchResultType.member,
        id: '2',
        title: 'Ahmad Al-Mansoori',
        subtitle: 'Member #M2015',
        description: 'Advanced level, Trip organizer',
        metadata: '85 trips',
      ),
      SearchResult(
        type: SearchResultType.member,
        id: '3',
        title: 'Khalid Al-Dhaheri',
        subtitle: 'Member #M2032',
        description: 'Intermediate level',
        metadata: '42 trips',
      ),
    ];

    return members
        .where((member) =>
            member.title.toLowerCase().contains(query) ||
            member.subtitle.toLowerCase().contains(query))
        .toList();
  }

  List<SearchResult> _searchPhotos(String query) {
    final photos = [
      SearchResult(
        type: SearchResultType.photo,
        id: '1',
        title: 'Empty Quarter Sunset',
        subtitle: 'Desert Expedition - Nov 2024',
        description: 'Amazing sunset over the dunes',
        metadata: '24 photos',
      ),
      SearchResult(
        type: SearchResultType.photo,
        id: '2',
        title: 'Liwa Dune Bash',
        subtitle: 'Safari Adventure - Oct 2024',
        description: 'Epic dune bashing action shots',
        metadata: '35 photos',
      ),
    ];

    return photos
        .where((photo) =>
            photo.title.toLowerCase().contains(query) ||
            photo.subtitle.toLowerCase().contains(query))
        .toList();
  }

  List<SearchResult> _searchNews(String query) {
    final news = [
      SearchResult(
        type: SearchResultType.news,
        id: '1',
        title: 'Club Annual Meeting Announced',
        subtitle: 'Event - Dec 15, 2024',
        description: 'Join us for the annual club meeting and elections',
        metadata: '2 days ago',
      ),
      SearchResult(
        type: SearchResultType.news,
        id: '2',
        title: 'New Safety Guidelines Released',
        subtitle: 'Important Update',
        description: 'Updated safety protocols for desert trips',
        metadata: '1 week ago',
      ),
    ];

    return news
        .where((newsItem) =>
            newsItem.title.toLowerCase().contains(query) ||
            newsItem.description.toLowerCase().contains(query))
        .toList();
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo gallery coming soon')),
              );
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
