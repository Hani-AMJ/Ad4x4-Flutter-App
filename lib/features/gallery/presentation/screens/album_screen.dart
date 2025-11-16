import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/sample_data/sample_gallery.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../shared/widgets/widgets.dart';
import 'photo_upload_screen.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final String albumId;
  final Album? album;  // Optional pre-loaded album data to avoid detail API call

  const AlbumScreen({super.key, required this.albumId, this.album});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  final _galleryRepository = GalleryApiRepository();
  Album? _album;
  List<Photo> _photos = [];
  bool _isLoading = true;
  String _sortBy = 'newest';  // newest, oldest, recently-uploaded, camera, file-size
  
  // Batch operations state
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    _loadAlbumPhotos();
  }
  
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotoIds.clear();
      }
    });
  }
  
  void _togglePhotoSelection(String photoId) {
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
      _selectedPhotoIds.clear();
      _selectedPhotoIds.addAll(_photos.map((p) => p.id));
    });
  }
  
  void _clearSelection() {
    setState(() {
      _selectedPhotoIds.clear();
    });
  }

  Future<void> _loadAlbumPhotos() async {
    setState(() => _isLoading = true);

    try {
      print('📸 [AlbumScreen] Loading album photos...');
      print('   Album ID (UUID): ${widget.albumId}');
      
      // Use pre-loaded album if available (passed from gallery list)
      // This avoids calling the non-existent gallery detail API endpoint
      Album album;
      if (widget.album != null) {
        print('✅ [AlbumScreen] Using pre-loaded album data');
        album = widget.album!;
      } else {
        print('⚠️ [AlbumScreen] No pre-loaded album, attempting detail API call...');
        // Fallback: Try detail API (will likely fail as endpoint doesn't exist)
        final albumResponse = await _galleryRepository.getGalleryDetail(widget.albumId);
        album = Album.fromJson(albumResponse['data'] ?? albumResponse['gallery'] ?? albumResponse);
      }
      
      // Fetch photos with sorting
      final photosResponse = await _galleryRepository.getGalleryPhotos(
        galleryId: widget.albumId,
        page: 1,
        limit: 100,
        sortBy: _sortBy,
      );
      
      final List<Photo> photos = [];
      final data = photosResponse['data'] ?? photosResponse['photos'] ?? photosResponse;
      
      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              photos.add(Photo.fromJson(item));
            } catch (e) {
              print('⚠️ [AlbumScreen] Error parsing photo: $e');
              print('   Photo data: $item');
            }
          }
        }
      } else {
        print('⚠️ [AlbumScreen] Unexpected photos data format: ${data.runtimeType}');
      }

      print('✅ [AlbumScreen] Loaded album with ${photos.length} photos');
      setState(() {
        _album = album;
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [AlbumScreen] Error loading album: $e');
      print('   Album ID: ${widget.albumId}');
      print('   Error type: ${e.runtimeType}');
      
      // Show error state (no mock data for UUIDs)
      setState(() {
        _album = null;
        _photos = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load album: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAlbumPhotos,
            ),
          ),
        );
      }
    }
  }

  Future<void> _batchDeletePhotos() async {
    if (_selectedPhotoIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Photos?'),
        content: Text(
          'Are you sure you want to delete ${_selectedPhotoIds.length} photo(s)?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleting ${_selectedPhotoIds.length} photo(s)...'),
            duration: const Duration(seconds: 60),
          ),
        );
      }
      
      // Delete each photo
      int successCount = 0;
      for (final photoId in _selectedPhotoIds) {
        try {
          await _galleryRepository.deletePhoto(photoId);
          successCount++;
        } catch (e) {
          print('❌ [AlbumScreen] Error deleting photo $photoId: $e');
        }
      }
      
      // Remove deleted photos from UI
      setState(() {
        _photos.removeWhere((photo) => _selectedPhotoIds.contains(photo.id));
        _selectedPhotoIds.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deleted $successCount photo(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [AlbumScreen] Error in batch delete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to delete photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _batchRotatePhotos(String direction) async {
    if (_selectedPhotoIds.isEmpty) return;
    
    try {
      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotating ${_selectedPhotoIds.length} photo(s)...'),
            duration: const Duration(seconds: 60),
          ),
        );
      }
      
      // Rotate each photo
      int successCount = 0;
      for (final photoId in _selectedPhotoIds) {
        try {
          await _galleryRepository.rotatePhoto(photoId, direction: direction);
          successCount++;
        } catch (e) {
          print('❌ [AlbumScreen] Error rotating photo $photoId: $e');
        }
      }
      
      // Reload album to show updated photos
      await _loadAlbumPhotos();
      
      setState(() {
        _selectedPhotoIds.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rotated $successCount photo(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [AlbumScreen] Error in batch rotate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to rotate photos'),
            backgroundColor: Colors.red,
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

      // Call favorite/unfavorite API
      if (wasLiked) {
        await _galleryRepository.removeFromFavorites(photo.id);
        print('✅ [AlbumScreen] Photo ${photo.id} removed from favorites');
      } else {
        await _galleryRepository.addToFavorites(photo.id);
        print('✅ [AlbumScreen] Photo ${photo.id} added to favorites');
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
        appBar: AppBar(title: const Text('Album')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 80,
                  color: colors.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Album Not Available',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This album could not be loaded.\\nIt may have been deleted or moved.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _loadAlbumPhotos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: _buildUploadFAB(),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isSelectionMode
                    ? '${_selectedPhotoIds.length} selected'
                    : _album!.title
              ),
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
            actions: _isSelectionMode
              ? [
                  // Selection mode actions
                  if (_selectedPhotoIds.length < _photos.length)
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: 'Select All',
                      onPressed: _selectAll,
                    ),
                  if (_selectedPhotoIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.deselect),
                      tooltip: 'Clear Selection',
                      onPressed: _clearSelection,
                    ),
                  if (_selectedPhotoIds.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Batch actions',
                      onSelected: (value) {
                        switch (value) {
                          case 'rotate_left':
                            _batchRotatePhotos('left');
                            break;
                          case 'rotate_right':
                            _batchRotatePhotos('right');
                            break;
                          case 'delete':
                            _batchDeletePhotos();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rotate_left',
                          child: Row(
                            children: [
                              Icon(Icons.rotate_left),
                              SizedBox(width: 12),
                              Text('Rotate Left'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rotate_right',
                          child: Row(
                            children: [
                              Icon(Icons.rotate_right),
                              SizedBox(width: 12),
                              Text('Rotate Right'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete Selected'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Exit Selection Mode',
                    onPressed: _toggleSelectionMode,
                  ),
                ]
              : [
                  // Normal mode actions
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    tooltip: 'Select Photos',
                    onPressed: _toggleSelectionMode,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Gallery options',
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameDialog();
                          break;
                        case 'delete':
                          _showDeleteDialog();
                          break;
                        case 'stats':
                          _showStatsDialog();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Rename Gallery'),
                          ],
                        ),
                  ),
                  const PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.analytics),
                        SizedBox(width: 12),
                        Text('View Statistics'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Gallery', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
          
          // Sort Control
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 20, color: colors.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest (Date Taken)')),
                        DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                        DropdownMenuItem(value: 'recently-uploaded', child: Text('Recently Uploaded')),
                        DropdownMenuItem(value: 'camera', child: Text('By Camera')),
                        DropdownMenuItem(value: 'file-size', child: Text('File Size')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                          _loadAlbumPhotos();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Photo Grid or Empty State
          _photos.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            size: 64,
                            color: colors.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Photos Yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This album doesn\'t contain any photos.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
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
                        final isSelected = _selectedPhotoIds.contains(photo.id);
                        return _PhotoThumbnail(
                          photo: photo,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onTap: () {
                            if (_isSelectionMode) {
                              _togglePhotoSelection(photo.id);
                            } else {
                              _showPhotoDialog(context, index);
                            }
                          },
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
                  photo.photoUrl,  // Full resolution image for detail view
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

  Widget? _buildUploadFAB() {
    if (_album == null) return null;
    
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoUploadScreen(
              galleryId: widget.albumId,
              galleryTitle: _album!.title,
            ),
          ),
        ).then((uploaded) {
          // Refresh photos if upload was successful
          if (uploaded == true) {
            _loadAlbumPhotos();
          }
        });
      },
      icon: const Icon(Icons.cloud_upload),
      label: const Text('Upload Photos'),
    );
  }

  // Show rename gallery dialog
  Future<void> _showRenameDialog() async {
    if (_album == null) return;

    final controller = TextEditingController(text: _album!.title);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Gallery'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Gallery Title',
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _album!.title && mounted) {
      try {
        await _galleryRepository.renameGallery(widget.albumId, result);
        
        setState(() {
          _album = _album!.copyWith(title: result);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery renamed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    controller.dispose();
  }

  // Show delete gallery dialog
  Future<void> _showDeleteDialog() async {
    if (_album == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gallery?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${_album!.title}"?'),
            const SizedBox(height: 12),
            const Text(
              'This gallery will be soft-deleted and can be restored within 30 days.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _galleryRepository.deleteGallery(widget.albumId);
        
        if (mounted) {
          Navigator.pop(context); // Go back to gallery list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery deleted. Can be restored within 30 days.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show gallery statistics dialog
  Future<void> _showStatsDialog() async {
    if (_album == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final stats = await _galleryRepository.getGalleryStats(widget.albumId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gallery Statistics'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: 'Total Photos',
                  value: stats['total_photos']?.toString() ?? '0',
                  icon: Icons.photo_library,
                ),
                _StatRow(
                  label: 'Total Views',
                  value: stats['total_views']?.toString() ?? '0',
                  icon: Icons.visibility,
                ),
                _StatRow(
                  label: 'Total Likes',
                  value: stats['total_likes']?.toString() ?? '0',
                  icon: Icons.favorite,
                ),
                _StatRow(
                  label: 'Top Uploader',
                  value: stats['top_uploader']?.toString() ?? 'N/A',
                  icon: Icons.person,
                ),
                _StatRow(
                  label: 'Created',
                  value: stats['created_at']?.toString() ?? 'N/A',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load statistics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
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
          border: isSelected
              ? Border.all(color: colors.primary, width: 3)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.gridThumbnail,  // Grid thumbnail (400x400, ~20-50KB) for fast loading
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.error,
                  color: colors.error,
                );
              },
            ),
            // Selection overlay
            if (isSelectionMode)
              Positioned.fill(
                child: Container(
                  color: isSelected 
                      ? colors.primary.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
            // Selection checkbox
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colors.onPrimary,
                        )
                      : null,
                ),
              ),
            // Like indicator (only show in normal mode)
            if (!isSelectionMode && photo.isLiked)
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
