import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/sample_data/sample_gallery.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../shared/widgets/widgets.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  final _galleryRepository = GalleryApiRepository();
  Album? _album;
  List<Photo> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumPhotos();
  }

  Future<void> _loadAlbumPhotos() async {
    setState(() => _isLoading = true);

    try {
      // Parse albumId (can be String from route)
      final albumIdInt = int.parse(widget.albumId);
      
      // Check if Gallery API is authenticated
      final isGalleryAuth = ref.read(isGalleryAuthenticatedProvider);
      
      if (!isGalleryAuth) {
        print('⚠️ [AlbumScreen] Gallery API not authenticated, using mock data');
        // Use mock data as fallback
        final album = SampleGallery.getAlbumById(albumIdInt);
        final photos = SampleGallery.getPhotosForAlbum(albumIdInt);
        setState(() {
          _album = album;
          _photos = photos;
          _isLoading = false;
        });
        return;
      }

      print('📸 [AlbumScreen] Fetching album details from API...');
      
      // Fetch album details
      final albumResponse = await _galleryRepository.getGalleryDetail(albumIdInt);
      final album = Album.fromJson(albumResponse['data'] ?? albumResponse);
      
      // Fetch photos
      final photosResponse = await _galleryRepository.getGalleryPhotos(
        galleryId: albumIdInt,
        page: 1,
        limit: 100,
      );
      
      final List<Photo> photos = [];
      final data = photosResponse['data'] ?? photosResponse['photos'] ?? photosResponse;
      
      if (data is List) {
        for (var item in data) {
          try {
            photos.add(Photo.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [AlbumScreen] Error parsing photo: $e');
          }
        }
      }

      print('✅ [AlbumScreen] Loaded album with ${photos.length} photos');
      setState(() {
        _album = album;
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [AlbumScreen] Error loading album: $e');
      // Fallback to mock data
      try {
        final albumIdInt = int.parse(widget.albumId);
        final album = SampleGallery.getAlbumById(albumIdInt);
        final photos = SampleGallery.getPhotosForAlbum(albumIdInt);
        setState(() {
          _album = album;
          _photos = photos;
          _isLoading = false;
        });
      } catch (e2) {
        setState(() {
          _album = null;
          _photos = [];
          _isLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load album: Using sample data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleLike(int index) async {
    final photo = _photos[index];
    final wasLiked = photo.isLiked;
    
    // Optimistic update
    setState(() {
      _photos[index] = photo.copyWith(
        isLiked: !photo.isLiked,
        likes: photo.isLiked ? photo.likes - 1 : photo.likes + 1,
      );
    });

    try {
      // Check if Gallery API is authenticated
      final isGalleryAuth = ref.read(isGalleryAuthenticatedProvider);
      if (!isGalleryAuth) {
        print('⚠️ [AlbumScreen] Gallery API not authenticated, like action local only');
        return;
      }

      // Call like/unlike API
      if (wasLiked) {
        await _galleryRepository.unlikePhoto(photo.id);
        print('✅ [AlbumScreen] Photo ${photo.id} unliked');
      } else {
        await _galleryRepository.likePhoto(photo.id);
        print('✅ [AlbumScreen] Photo ${photo.id} liked');
      }
    } catch (e) {
      print('❌ [AlbumScreen] Error toggling like: $e');
      // Revert on error
      setState(() {
        _photos[index] = photo;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingIndicator(message: 'Loading photos...'),
      );
    }

    if (_album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorState(message: 'Album not found'),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_album!.title),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.3),
                      colors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Album Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _album!.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _album!.createdBy,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(_album!.createdAt),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ),

          // Photo Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = _photos[index];
                  return _PhotoThumbnail(
                    photo: photo,
                    onTap: () => _showPhotoDialog(context, index),
                  );
                },
                childCount: _photos.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final photo = _photos[index];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Photo
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  photo.url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.error,
                        size: 48,
                        color: colors.error,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Photo Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        photo.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            photo.uploadedBy,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              photo.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: photo.isLiked ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              _handleLike(index);
                              Navigator.pop(context);
                            },
                          ),
                          Text(
                            '${photo.likes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
              photo.thumbnailImage,
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
