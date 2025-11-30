import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/sample_data/sample_gallery.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../shared/widgets/widgets.dart';
import 'photo_search_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _galleryRepository = GalleryApiRepository();
  List<Album> _albums = [];
  bool _isLoading = true;
  String _sortBy = 'recent-photo';  // recent-photo, name, newest, oldest, photo-count
  int? _tripLevelFilter;  // null = all, 1-8 = specific trip level
  String? _userFilter;  // 'my' = user's albums only, 'all' or null = all albums

  @override
  void initState() {
    super.initState();
    // Get filter parameter from route query parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final filterParam = uri.queryParameters['filter'];
      if (filterParam == 'my') {
        setState(() {
          _userFilter = 'my';
        });
      }
      _loadAlbums();
    });
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);

    try {
      print('📸 [GalleryScreen] Fetching galleries from API...');
      print('   Filter: ${_userFilter ?? "all"}');
      
      // Try to fetch from API with sorting and filtering
      final response = await _galleryRepository.getGalleries(
        page: 1,
        limit: 20,
        sortBy: _sortBy,
        tripLevel: _tripLevelFilter?.toString(),  // Convert int to string for API
        filter: _userFilter,  // FIXED: Pass user filter to API
      );
      
      // Parse response - Gallery API format: { "success": true, "galleries": [...] }
      final List<Album> albums = [];
      final data = response['galleries'] ?? response['data'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              final album = Album.fromJson(item);
              albums.add(album);
              // Debug: Log trip start time parsing
              if (album.tripId != null) {
                print('🔍 [GalleryScreen] Trip Gallery: ${album.title}');
                print('   tripStartTime: ${album.tripStartTime}');
                print('   createdAt: ${album.createdAt}');
                print('   displayDate: ${album.displayDate}');
                print('   isTripGallery: ${album.isTripGallery}');
              }
            } catch (e) {
              print('⚠️ [GalleryScreen] Error parsing album: $e');
              print('   Album data: $item');
            }
          }
        }
      } else {
        print('⚠️ [GalleryScreen] Unexpected data format: ${data.runtimeType}');
      }

      if (albums.isEmpty) {
        print('⚠️ [GalleryScreen] No albums returned from API');
        setState(() {
          _albums = [];
          _isLoading = false;
        });
      } else {
        print('✅ [GalleryScreen] Loaded ${albums.length} albums from API');
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [GalleryScreen] Error loading albums: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Gallery API: ${ApiConfig.galleryApiBaseUrl}');
      print('   Endpoint: /api/galleries?page=1&limit=20');
      
      // Show error state - NO MOCK DATA
      setState(() {
        _albums = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Gallery server unavailable\nPlease check your connection and try again'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAlbums,
            ),
          ),
        );
      }
    }
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 80,
              color: colors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Gallery Unavailable',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to connect to the gallery server.\\nPlease check your internet connection.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadAlbums,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Determine if user is filtering or not
    final isFiltering = _tripLevelFilter != null;
    
    String message;
    String description;
    IconData icon;
    
    if (isFiltering) {
      // User is filtering but no results
      final levelName = _getLevelName(_tripLevelFilter!);
      message = 'No Albums Found';
      description = 'No galleries available for $levelName level.\\nTry selecting a different level or view all galleries.';
      icon = Icons.filter_alt_off_outlined;
    } else {
      // No albums at all
      message = 'No Galleries Yet';
      description = 'Create your first gallery or wait for trip galleries to be auto-created.';
      icon = Icons.photo_library_outlined;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: colors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _tripLevelFilter = null);
                  _loadAlbums();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Get level name from level ID
  String _getLevelName(int levelId) {
    const levelNames = {
      1: '🎪 Club Event',
      2: '⭐ ANIT',
      3: '⭐ Newbie/ANIT',
      4: '⭐⭐ Intermediate',
      5: '⭐⭐⭐ Advanced',
      6: '⭐⭐⭐⭐ Expert',
      7: '⭐⭐⭐⭐ Explorer',
      8: '⭐⭐⭐⭐⭐ Marshal',
    };
    return levelNames[levelId] ?? 'Unknown Level';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PhotoSearchScreen(),
                ),
              );
            },
            tooltip: 'Search photos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sorting and Filtering Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                // Sort dropdown
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, size: 20),
                    items: const [
                      DropdownMenuItem(value: 'recent-photo', child: Text('Recent Photos')),
                      DropdownMenuItem(value: 'name', child: Text('Album Name')),
                      DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                      DropdownMenuItem(value: 'photo-count', child: Text('Most Photos')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _loadAlbums();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Trip level filter
                DropdownButton<int?>(
                  value: _tripLevelFilter,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_list, size: 20),
                  hint: const Text('All Levels'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Levels')),
                    DropdownMenuItem(value: 1, child: Text('🎪 Club Event')),
                    DropdownMenuItem(value: 2, child: Text('⭐ ANIT')),
                    DropdownMenuItem(value: 3, child: Text('⭐ Newbie/ANIT')),
                    DropdownMenuItem(value: 4, child: Text('⭐⭐ Intermediate')),
                    DropdownMenuItem(value: 5, child: Text('⭐⭐⭐ Advanced')),
                    DropdownMenuItem(value: 6, child: Text('⭐⭐⭐⭐ Expert')),
                    DropdownMenuItem(value: 7, child: Text('⭐⭐⭐⭐ Explorer')),
                    DropdownMenuItem(value: 8, child: Text('⭐⭐⭐⭐⭐ Marshal')),
                  ],
                  onChanged: (value) {
                    setState(() => _tripLevelFilter = value);
                    _loadAlbums();
                  },
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading albums...')
                : _albums.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAlbums,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _albums.length,
                    itemBuilder: (context, index) {
                      final album = _albums[index];
                      return _AlbumCard(
                        album: album,
                        onTap: () => context.push('/gallery/album/${album.id}', extra: album),  // Pass album data to avoid detail API call
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGalleryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Gallery'),
        tooltip: 'Create new gallery (Board members only)',
      ),
    );
  }
  
  // Show create gallery dialog
  Future<void> _showCreateGalleryDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    int selectedLevel = 4;  // Default to Intermediate

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Gallery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Gallery Title',
                    hintText: 'Enter gallery name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter gallery description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trip Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('🎪 Club Event')),
                    DropdownMenuItem(value: 2, child: Text('⭐ ANIT')),
                    DropdownMenuItem(value: 3, child: Text('⭐ Newbie/ANIT')),
                    DropdownMenuItem(value: 4, child: Text('⭐⭐ Intermediate')),
                    DropdownMenuItem(value: 5, child: Text('⭐⭐⭐ Advanced')),
                    DropdownMenuItem(value: 6, child: Text('⭐⭐⭐⭐ Expert')),
                    DropdownMenuItem(value: 7, child: Text('⭐⭐⭐⭐ Explorer')),
                    DropdownMenuItem(value: 8, child: Text('⭐⭐⭐⭐⭐ Marshal')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLevel = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a gallery title')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      // Create gallery
      try {
        final data = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'trip_level': selectedLevel,
        };

        await _galleryRepository.createGallery(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload galleries
          _loadAlbums();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }
}

class _AlbumCard extends StatelessWidget{
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.gridThumbnail.isNotEmpty
                      ? Image.network(
                          album.gridThumbnail,  // Uses static thumbnail (400x400, ~20-50KB)
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: colors.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colors.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: colors.onSurface.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: colors.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                  // Trip level badge (top-left)
                  if (album.tripLevelName != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getLevelEmoji(album.tripLevel ?? 1),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              album.tripLevelName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Photo count badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${album.photoCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Album Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album title
                  Text(
                    album.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Owner info (avatar + username)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(album.avatarUrl),
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          album.createdBy,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Date row
                  Row(
                    children: [
                      Icon(
                        album.isTripGallery ? Icons.event : Icons.create,
                        size: 12,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(album.displayDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get level emoji based on trip level ID
  String _getLevelEmoji(int levelId) {
    switch (levelId) {
      case 1: return '🎪';           // Club Event
      case 2: return '⭐';            // ANIT
      case 3: return '⭐';            // Newbie/ANIT
      case 4: return '⭐⭐';          // Intermediate
      case 5: return '⭐⭐⭐';        // Advanced
      case 6: return '⭐⭐⭐⭐';      // Expert
      case 7: return '⭐⭐⭐⭐';      // Explorer
      case 8: return '⭐⭐⭐⭐⭐';    // Marshal
      default: return '⚪';
    }
  }
}
