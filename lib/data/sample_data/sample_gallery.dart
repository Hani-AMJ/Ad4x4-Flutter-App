import '../models/album_model.dart';

/// Sample gallery data
class SampleGallery {
  static List<Album> getAlbums() {
    return [
      Album(
        id: 1,
        title: 'Desert Safari 2024',
        description: 'Amazing desert adventure with the crew',
        coverImageUrl: 'https://picsum.photos/seed/desert1/400/300',
        photoCount: 24,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'Hani Al-Mansouri',
      ),
      Album(
        id: 2,
        title: 'Empty Quarter Expedition',
        description: '3-day journey through the Empty Quarter',
        coverImageUrl: 'https://picsum.photos/seed/desert2/400/300',
        photoCount: 48,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        createdBy: 'Ahmad Al-Mansoori',
      ),
      Album(
        id: 3,
        title: 'Sunset Dune Bash',
        description: 'Evening fun on the dunes',
        coverImageUrl: 'https://picsum.photos/seed/sunset1/400/300',
        photoCount: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        createdBy: 'Khalid Al-Dhaheri',
      ),
      Album(
        id: 4,
        title: 'Hafeet Mountain Trail',
        description: 'Scenic drive up Jebel Hafeet',
        coverImageUrl: 'https://picsum.photos/seed/mountain1/400/300',
        photoCount: 32,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        createdBy: 'Saif Al-Ketbi',
      ),
      Album(
        id: 5,
        title: 'Night Desert Camp',
        description: 'Camping under the stars',
        coverImageUrl: 'https://picsum.photos/seed/camp1/400/300',
        photoCount: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        createdBy: 'Rashid Al-Blooshi',
      ),
      Album(
        id: 6,
        title: 'Coastal Dunes Adventure',
        description: 'Beach and dunes combination',
        coverImageUrl: 'https://picsum.photos/seed/coast1/400/300',
        photoCount: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        createdBy: 'Abdullah Al-Mazrouei',
      ),
    ];
  }

  static Album getAlbumById(int id) {
    return getAlbums().firstWhere(
      (album) => album.id == id,
      orElse: () => getAlbums().first,
    );
  }

  static List<Photo> getPhotosForAlbum(int albumId) {
    // Generate sample photos for the album
    return List.generate(
      12,
      (index) => Photo(
        id: albumId * 100 + index,  // Generate unique int ID
        url: 'https://picsum.photos/seed/photo${albumId}_$index/800/600',
        thumbnailUrl: 'https://picsum.photos/seed/photo${albumId}_$index/200/150',
        caption: 'Amazing moment from the trip #${index + 1}',
        uploadedBy: index % 3 == 0
            ? 'Hani Al-Mansouri'
            : index % 3 == 1
                ? 'Ahmad Al-Mansoori'
                : 'Khalid Al-Dhaheri',
        uploadedAt: DateTime.now().subtract(Duration(hours: index * 2)),
        likes: (index + 1) * 5,
        isLiked: index % 4 == 0,
      ),
    );
  }
}
