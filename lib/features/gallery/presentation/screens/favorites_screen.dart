import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../shared/widgets/widgets.dart';
import 'full_screen_photo_viewer.dart';

/// Gallery Favorites Screen
/// 
/// Displays user's favorite photos with:
/// - Grid view of favorited photos
/// - Quick access to favorites
/// - Remove from favorites
/// - Share favorites
/// - Full-screen photo viewing
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _galleryRepository = GalleryApiRepository();
  
  List<Photo> _favorites = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  
  // Selection mode for batch operations
  bool _isSelectionMode = false;
  Set<int> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool isLoadMore = false}) async {
    if (_isLoading && isLoadMore) return;
    if (!_hasMore && isLoadMore) return;

    setState(() {
      if (!isLoadMore) {
        _isLoading = true;
        _currentPage = 1;
      }
      _errorMessage = null;
    });

    try {
      // Check if Gallery API is authenticated
      final isGalleryAuth = ref.read(isGalleryAuthenticatedProvider);
      
      if (!isGalleryAuth) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gallery API not authenticated';
        });
        return;
      }

      final response = await _galleryRepository.getFavoritePhotos(
        page: _currentPage,
        limit: 50,
      );

      // Parse photos
      final List<Photo> newPhotos = [];
      final data = response['data'] ?? response['photos'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            newPhotos.add(Photo.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [FavoritesScreen] Error parsing photo: $e');
          }
        }
      }

      setState(() {
        if (isLoadMore) {
          _favorites.addAll(newPhotos);
        } else {
          _favorites = newPhotos;
        }
        _hasMore = newPhotos.length >= 50;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(int photoId) async {
    try {
      await _galleryRepository.removeFromFavorites(photoId);
      
      setState(() {
        _favorites.removeWhere((photo) => photo.id == photoId);
        _selectedPhotoIds.remove(photoId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSelectedFromFavorites() async {
    final selectedIds = List<int>.from(_selectedPhotoIds);
    
    setState(() {
      _favorites.removeWhere((photo) => selectedIds.contains(photo.id));
      _selectedPhotoIds.clear();
      _isSelectionMode = false;
    });

    // Remove from favorites in background
    for (var photoId in selectedIds) {
      try {
        await _galleryRepository.removeFromFavorites(photoId);
      } catch (e) {
        print('⚠️ Failed to remove photo $photoId from favorites: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${selectedIds.length} photo(s) from favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotoIds.clear();
      }
    });
  }

  void _togglePhotoSelection(int photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
      } else {
        _selectedPhotoIds.add(photoId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPhotoIds.length == _favorites.length) {
        _selectedPhotoIds.clear();
      } else {
        _selectedPhotoIds = _favorites.map((p) => p.id).toSet();
      }
    });
  }

  Future<void> _openPhotoViewer(int initialIndex) async {
    final updatedPhotos = await Navigator.push<List<Photo>>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: _favorites,
          initialIndex: initialIndex,
          albumTitle: 'Favorites',
        ),
      ),
    );

    // Update photos if changed (e.g., likes updated)
    if (updatedPhotos != null) {
      setState(() {
        _favorites = updatedPhotos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPhotoIds.length} selected')
            : const Text('Favorites'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedPhotoIds.length == _favorites.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedPhotoIds.isNotEmpty
                  ? _removeSelectedFromFavorites
                  : null,
              tooltip: 'Remove Selected',
            ),
          ] else ...[
            if (_favorites.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: _toggleSelectionMode,
                tooltip: 'Select',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadFavorites(isLoadMore: false),
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
      body: _isLoading && _favorites.isEmpty
          ? const LoadingIndicator(message: 'Loading favorites...')
          : _errorMessage != null && _favorites.isEmpty
              ? ErrorState(
                  title: 'Error Loading Favorites',
                  message: _errorMessage!,
                  onRetry: _loadFavorites,
                )
              : _favorites.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: 'No Favorites Yet',
                      message: 'Photos you favorite will appear here.\n'
                          'Tap the heart icon on any photo to add it to your favorites.',
                      actionText: 'Browse Gallery',
                      onAction: () => Navigator.pop(context),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadFavorites(isLoadMore: false),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _favorites.length + 1,
                        itemBuilder: (context, index) {
                          // Load more trigger
                          if (index == _favorites.length) {
                            if (_hasMore) {
                              _loadFavorites(isLoadMore: true);
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final photo = _favorites[index];
                          final isSelected = _selectedPhotoIds.contains(photo.id);

                          return _FavoritePhotoTile(
                            photo: photo,
                            isSelectionMode: _isSelectionMode,
                            isSelected: isSelected,
                            onTap: () {
                              if (_isSelectionMode) {
                                _togglePhotoSelection(photo.id);
                              } else {
                                _openPhotoViewer(index);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedPhotoIds.add(photo.id);
                                });
                              }
                            },
                            onRemove: () => _removeFromFavorites(photo.id),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FavoritePhotoTile extends StatelessWidget {
  final Photo photo;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  const _FavoritePhotoTile({
    required this.photo,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          Image.network(
            photo.thumbnailImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: colors.onSurface.withValues(alpha: 0.3),
                ),
              );
            },
          ),

          // Selection overlay
          if (isSelectionMode)
            Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

          // Favorite badge (when not in selection mode)
          if (!isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

          // Gradient overlay for better badge visibility
          if (!isSelectionMode)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
