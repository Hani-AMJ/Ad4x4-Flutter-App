import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/album_model.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../shared/widgets/widgets.dart';
import 'photo_upload_screen.dart';
import 'full_screen_photo_viewer.dart';

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

    // Step 1: Get or create album object
    Album? album;
    try {
      print('📸 [AlbumScreen] Loading album photos...');
      print('   Album ID (UUID): ${widget.albumId}');
      
      // Use pre-loaded album if available (passed from gallery list)
      // This avoids calling the non-existent gallery detail API endpoint
      if (widget.album != null) {
        print('✅ [AlbumScreen] Using pre-loaded album data');
        album = widget.album!;
      } else {
        print('⚠️ [AlbumScreen] No pre-loaded album, creating minimal album object...');
        // The Gallery API doesn't have a detail endpoint, so create minimal album
        // The photos API call below will provide the actual data we need
        album = Album(
          id: widget.albumId,
          title: 'Trip Gallery', // Generic title for trip galleries
          description: '',
          coverImageUrl: null,
          photoCount: 0,
          createdAt: DateTime.now(),
          createdBy: '',
          tripId: null,
          tripTitle: null,
          samplePhotos: [],
        );
      }
      
      // Set album first so UI can display even if photos fail
      setState(() {
        _album = album;
      });
    } catch (e) {
      print('❌ [AlbumScreen] Error creating album object: $e');
      setState(() {
        _album = null;
        _photos = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Invalid album data'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    
    // Step 2: Load photos (separate try-catch to keep album if photos fail)
    try {
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
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [AlbumScreen] Error loading photos: $e');
      print('   Album ID: ${widget.albumId}');
      print('   Error type: ${e.runtimeType}');
      
      // Keep album, just show no photos
      setState(() {
        _photos = [];
        _isLoading = false;
      });
      
      if (mounted) {
        // Provide helpful error message for photo loading failures
        String errorMessage = 'Failed to load photos';
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMessage = 'Please log in again to view photos';
        } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
          errorMessage = 'Photos not found';
        } else {
          // For empty galleries, don't show error - it's expected
          if (_photos.isEmpty) {
            print('ℹ️ [AlbumScreen] No photos in gallery (expected for new galleries)');
            return; // Don't show error snackbar for empty galleries
          }
          errorMessage = 'Failed to load photos: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
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
            expandedHeight: 140,  // Increased to 140 for more vertical space
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16, 
                bottom: 20,  // More bottom padding for better separation
                right: 120,  // Much more right padding to avoid action buttons (2 icons * 48px each + padding)
              ),
              title: Text(
                _isSelectionMode
                    ? '${_selectedPhotoIds.length} selected'
                    : _album!.title,
                maxLines: 2,  // Allow title to wrap to 2 lines if needed
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),  // Slightly smaller font for better fit
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

          // Album Info - Ultra-compact layout
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Only show description if it's not auto-generated text
                if (_album!.description.isNotEmpty && 
                    !_album!.description.startsWith('Auto-created gallery'))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _album!.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                // Compact info row with all details
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      // Creator
                      _CompactInfoChip(
                        icon: Icons.person,
                        label: _album!.createdBy,
                        colors: colors,
                        theme: theme,
                      ),
                      
                      // Date
                      _CompactInfoChip(
                        icon: _album!.isTripGallery ? Icons.event : Icons.create,
                        label: DateFormat('MMM d, y').format(_album!.displayDate),
                        colors: colors,
                        theme: theme,
                      ),
                      
                      // Trip level (if available)
                      if (_album!.tripLevelName != null)
                        _CompactInfoChip(
                          emoji: _getLevelEmoji(_album!.tripLevel ?? 1),
                          label: _album!.tripLevelName!,
                          colors: colors,
                          theme: theme,
                          isBold: true,
                        ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.1)),
              ],
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

  void _showPhotoDialog(BuildContext context, int index) async {
    // Navigate to FullScreenPhotoViewer with navigation arrows and preloading
    final updatedPhotos = await Navigator.push<List<Photo>>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: _photos,
          initialIndex: index,
          albumTitle: _album?.title,
        ),
      ),
    );

    // Update photos if they were modified (e.g., liked, deleted)
    if (updatedPhotos != null && mounted) {
      setState(() {
        _photos = updatedPhotos;
      });
    }
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
  
  // Helper method to get trip level emoji
  String _getLevelEmoji(int level) {
    switch (level) {
      case 1: return '🎪'; // Club Event
      case 2: return '⭐'; // ANIT
      case 3: return '🟢'; // Intermediate
      case 4: return '🟡'; // Advanced
      case 5: return '🔴'; // Expert
      case 6: return '⚫'; // Extreme
      case 7: return '🏋️'; // Training
      case 8: return '🤝'; // Social
      default: return '📌';
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

// Compact info chip widget for album details
class _CompactInfoChip extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final ColorScheme colors;
  final ThemeData theme;
  final bool isBold;

  const _CompactInfoChip({
    this.icon,
    this.emoji,
    required this.label,
    required this.colors,
    required this.theme,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 13,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        if (emoji != null)
          Text(
            emoji!,
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.65),
            fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
