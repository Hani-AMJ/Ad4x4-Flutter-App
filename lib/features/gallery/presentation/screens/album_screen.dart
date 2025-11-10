import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/sample_data/sample_gallery.dart';
import '../../../../shared/widgets/widgets.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
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

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API call
    final album = SampleGallery.getAlbumById(widget.albumId);
    final photos = SampleGallery.getPhotosForAlbum(widget.albumId);

    setState(() {
      _album = album;
      _photos = photos;
      _isLoading = false;
    });
  }

  Future<void> _handleLike(int index) async {
    setState(() {
      final photo = _photos[index];
      _photos[index] = photo.copyWith(
        isLiked: !photo.isLiked,
        likes: photo.isLiked ? photo.likes - 1 : photo.likes + 1,
      );
    });

    // TODO: Implement actual like API call
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
              photo.thumbnailUrl,
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
