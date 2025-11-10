/// Gallery API Endpoints
/// 
/// All endpoints for the Gallery API (Node.js media service)
class GalleryApiEndpoints {
  // Galleries (Albums)
  static const String galleries = '/api/galleries';
  static String galleryDetail(int id) => '/api/galleries/$id';

  // Photos
  static String galleryPhotos(int galleryId) => '/api/photos/gallery/$galleryId';
  static const String photoSearch = '/api/photos/search';

  // Upload session and upload
  static const String uploadSession = '/api/photos/upload/session';
  static const String upload = '/api/photos/upload';

  // Photo actions (future)
  static String photoDetail(int id) => '/api/photos/$id';
  static String photoLike(int id) => '/api/photos/$id/like';
  static String photoUnlike(int id) => '/api/photos/$id/unlike';
}
