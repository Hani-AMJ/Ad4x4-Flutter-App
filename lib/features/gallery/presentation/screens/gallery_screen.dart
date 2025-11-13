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

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _galleryRepository = GalleryApiRepository();
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);

    try {
      print('📸 [GalleryScreen] Fetching galleries from API...');
      
      // Try to fetch from API regardless of auth state
      // The repository will handle authentication
      final response = await _galleryRepository.getGalleries(page: 1, limit: 20);
      
      // Parse response
      final List<Album> albums = [];
      final data = response['data'] ?? response['galleries'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            albums.add(Album.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [GalleryScreen] Error parsing album: $e');
          }
        }
      }

      if (albums.isEmpty) {
        print('⚠️ [GalleryScreen] No albums returned from API, using mock data');
        // If API returns empty, use mock data
        final mockAlbums = SampleGallery.getAlbums();
        setState(() {
          _albums = mockAlbums;
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
      
      // Fallback to mock data on error
      final albums = SampleGallery.getAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📸 Gallery server unavailable\n🎨 Showing sample galleries'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Auth Status Banner (only show if not authenticated)
          Consumer(
            builder: (context, ref, child) {
              final isGalleryAuth = ref.watch(isGalleryAuthenticatedProvider);
              if (isGalleryAuth) return const SizedBox.shrink();
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🔄 Using Mock Data - Gallery API Authentication Pending',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Main Content
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading albums...')
                : _albums.isEmpty
                    ? EmptyState(
                        icon: Icons.photo_library_outlined,
                        title: 'No Albums',
                        message: 'No photo albums available yet.',
                        actionText: 'Upload Photos',
                        onAction: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload coming soon!')),
                          );
                        },
                      )
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
                        onTap: () => context.push('/gallery/album/${album.id}'),  // ID is now int
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload photos coming soon!')),
          );
        },
        backgroundColor: colors.primary,
        child: Icon(Icons.add_a_photo, color: colors.onPrimary),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
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
                  Image.network(
                    album.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          Icons.photo_library,
                          size: 48,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                  // Photo count badge
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
                  Text(
                    album.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y').format(album.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
