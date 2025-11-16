import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import 'full_screen_photo_viewer.dart';

/// Photo Search Screen
/// 
/// Features:
/// - Full-text search across photo filenames and gallery names
/// - Trip level filtering
/// - Camera make/model filtering
/// - Debounced search (500ms delay)
/// - Grid view of search results
class PhotoSearchScreen extends ConsumerStatefulWidget {
  const PhotoSearchScreen({super.key});

  @override
  ConsumerState<PhotoSearchScreen> createState() => _PhotoSearchScreenState();
}

class _PhotoSearchScreenState extends ConsumerState<PhotoSearchScreen> {
  final _galleryRepository = GalleryApiRepository();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  List<Photo> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _tripLevelFilter;
  String? _cameraFilter;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Debounce search (wait 500ms after user stops typing)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await _galleryRepository.searchPhotos(
        query: query.trim(),
        page: 1,
        limit: 50,
        tripLevel: _tripLevelFilter,
        camera: _cameraFilter,
      );

      final List<Photo> results = [];
      final data = response['data'] ?? response['photos'] ?? response;

      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              results.add(Photo.fromJson(item));
            } catch (e) {
              print('⚠️ [PhotoSearchScreen] Error parsing photo: $e');
            }
          }
        }
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [PhotoSearchScreen] Search error: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _tripLevelFilter = null;
      _cameraFilter = null;
    });
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search photos...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _hasSearched = false;
                });
              },
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(colors),

          // Search Results
          Expanded(
            child: _buildSearchResults(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme colors) {
    final hasActiveFilters = _tripLevelFilter != null || _cameraFilter != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Trip Level Filter
          Expanded(
            child: DropdownButton<String?>(
              value: _tripLevelFilter,
              hint: const Text('All Levels'),
              isExpanded: true,
              isDense: true,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Levels')),
                DropdownMenuItem(value: 'easy', child: Text('🟢 Easy')),
                DropdownMenuItem(value: 'moderate', child: Text('🟡 Moderate')),
                DropdownMenuItem(value: 'hard', child: Text('🟠 Hard')),
                DropdownMenuItem(value: 'extreme', child: Text('🔴 Extreme')),
              ],
              onChanged: (value) {
                setState(() => _tripLevelFilter = value);
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Clear Filters Button
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colors) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Searching...');
    }

    if (!_hasSearched) {
      return EmptyState(
        icon: Icons.image_search,
        title: 'Search Photos',
        message: 'Search for photos by filename, gallery name, or description.',
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        message: 'Try different search terms or adjust filters.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final photo = _searchResults[index];
        return _PhotoThumbnail(
          photo: photo,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FullScreenPhotoViewer(
                  photos: _searchResults,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colors.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.gridThumbnail,  // Grid thumbnail (400x400, ~20-50KB)
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.error,
                  color: colors.error,
                );
              },
            ),
            // Like indicator
            if (photo.isLiked)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
