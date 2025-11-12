import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import 'package:intl/intl.dart';

/// Full-Screen Photo Viewer
/// 
/// Immersive photo viewing experience with:
/// - Swipe gestures for navigation
/// - Pinch-to-zoom support
/// - Double-tap to zoom
/// - Share functionality
/// - Like/unlike actions
/// - Photo info display
/// - Download support
class FullScreenPhotoViewer extends ConsumerStatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final String? albumTitle;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.albumTitle,
  });

  @override
  ConsumerState<FullScreenPhotoViewer> createState() =>
      _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends ConsumerState<FullScreenPhotoViewer> {
  final _galleryRepository = GalleryApiRepository();
  final _pageController = PageController();
  
  late int _currentIndex;
  bool _showControls = true;
  bool _showInfo = false;
  List<Photo> _photos = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _photos = List.from(widget.photos);
    
    // Initialize PageController with initial index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleInfo() {
    setState(() {
      _showInfo = !_showInfo;
    });
  }

  Future<void> _toggleLike() async {
    final currentPhoto = _photos[_currentIndex];
    
    // Optimistic update
    setState(() {
      _photos[_currentIndex] = currentPhoto.copyWith(
        isLiked: !currentPhoto.isLiked,
        likes: currentPhoto.isLiked 
            ? currentPhoto.likes - 1 
            : currentPhoto.likes + 1,
      );
    });

    try {
      if (currentPhoto.isLiked) {
        await _galleryRepository.unlikePhoto(currentPhoto.id);
      } else {
        await _galleryRepository.likePhoto(currentPhoto.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _photos[_currentIndex] = currentPhoto;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${currentPhoto.isLiked ? 'unlike' : 'like'} photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePhoto() async {
    final photo = _photos[_currentIndex];
    try {
      await Share.share(
        photo.photoUrl,
        subject: photo.caption.isNotEmpty ? photo.caption : 'Check out this photo!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentPhoto = _photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, _photos),
              ),
              title: widget.albumTitle != null
                  ? Text(
                      widget.albumTitle!,
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _sharePhoto,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: Icon(
                    _showInfo ? Icons.info : Icons.info_outline,
                    color: Colors.white,
                  ),
                  onPressed: _toggleInfo,
                  tooltip: 'Photo Info',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return _ZoomablePhotoView(
                photo: _photos[index],
                onTap: _toggleControls,
              );
            },
          ),

          // Bottom Controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Caption
                      if (currentPhoto.caption.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            currentPhoto.caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Like Button
                          _ActionButton(
                            icon: currentPhoto.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: '${currentPhoto.likes}',
                            onPressed: _toggleLike,
                            color: currentPhoto.isLiked ? Colors.red : Colors.white,
                          ),

                          // Photo Counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${_photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Download Button
                          _ActionButton(
                            icon: Icons.download,
                            label: 'Save',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download feature coming soon!'),
                                ),
                              );
                            },
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Photo Info Panel
          if (_showInfo)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _PhotoInfoPanel(
                photo: currentPhoto,
                onClose: _toggleInfo,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomablePhotoView extends StatefulWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _ZoomablePhotoView({
    required this.photo,
    required this.onTap,
  });

  @override
  State<_ZoomablePhotoView> createState() => _ZoomablePhotoViewState();
}

class _ZoomablePhotoViewState extends State<_ZoomablePhotoView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final position = details.localPosition;
    
    // If already zoomed, zoom out
    if (_transformationController.value != Matrix4.identity()) {
      _animateToZoom(Matrix4.identity());
      return;
    }

    // Zoom in to 2x at tap position
    final double scale = 2.0;
    final x = -position.dx * (scale - 1);
    final y = -position.dy * (scale - 1);
    final zoomed = Matrix4.identity()
      ..translate(x, y)
      ..scale(scale);

    _animateToZoom(zoomed);
  }

  void _animateToZoom(Matrix4 targetTransformation) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetTransformation,
    ).animate(
      CurveTween(curve: Curves.easeInOut).animate(_animationController),
    );

    _animationController.forward(from: 0).then((_) {
      _animation = null;
    });

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.photo.photoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhotoInfoPanel extends StatelessWidget {
  final Photo photo;
  final VoidCallback onClose;

  const _PhotoInfoPanel({
    required this.photo,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ),

            const SizedBox(height: 8),

            // Photo Details
            _InfoRow(
              icon: Icons.person,
              label: 'Uploaded by',
              value: photo.uploadedBy,
            ),
            const SizedBox(height: 12),
            
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _formatDate(photo.uploadedAt),
            ),
            const SizedBox(height: 12),
            
            _InfoRow(
              icon: Icons.favorite,
              label: 'Likes',
              value: '${photo.likes}',
            ),

            if (photo.caption.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Caption',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                photo.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
