/// Gallery API Endpoints
/// 
/// All endpoints for the Gallery API (Node.js media service)
class GalleryApiEndpoints {
  // Galleries (Albums) - Gallery API uses UUID strings for IDs
  static const String galleries = '/api/galleries';
  static String galleryDetail(String id) => '/api/galleries/$id';

  // Photos - Gallery API uses UUID strings for gallery IDs, integers for photo IDs
  static String galleryPhotos(String galleryId) => '/api/photos/gallery/$galleryId';
  static const String photoSearch = '/api/photos/search';

  // Upload session and upload
  static const String uploadSession = '/api/photos/upload/session';
  static const String upload = '/api/photos/upload';

  // Photo actions - Photo IDs are UUID strings
  static String photoDetail(String id) => '/api/photos/$id';
  static String photoLike(String id) => '/api/photos/$id/like';
  static String photoUnlike(String id) => '/api/photos/$id/unlike';
}
