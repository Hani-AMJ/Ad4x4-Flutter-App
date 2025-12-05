/// API Endpoints for AD4x4 application
class ApiEndpoints {
  // Base URLs
  static const String mainApi = 'https://ap.ad4x4.com';
  static const String galleryApi = 'https://media.ad4x4.com';

  // Auth Endpoints (trailing slashes required to prevent 301 redirects)
  static const String login = '/api/auth/login/';
  static const String register = '/api/auth/register/';
  static const String logout = '/api/auth/logout/';
  static const String refreshToken = '/api/auth/refresh/';
  static const String forgotPassword = '/api/auth/forgot-password/';
  static const String resetPassword = '/api/auth/reset-password/';
  static const String verifyEmail = '/api/auth/verify-email/';
  
  // Validators endpoint for live form validation
  static const String validators = '/api/validators/';

  // User Endpoints
  static const String userProfile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile/update';
  static const String uploadAvatar = '/api/users/avatar/upload';
  static const String changePassword = '/api/users/password/change';
  static const String userSettings = '/api/users/settings';

  // Trip Endpoints
  static const String trips = '/api/trips';
  static String tripDetails(String id) => '/api/trips/$id';
  static String joinTrip(String id) => '/api/trips/$id/join';
  static String leaveTrip(String id) => '/api/trips/$id/leave';
  static String tripParticipants(String id) => '/api/trips/$id/participants';
  static String tripComments(String id) => '/api/trips/$id/comments';
  static const String myTrips = '/api/trips/my-trips';
  static const String upcomingTrips = '/api/trips/upcoming';
  static const String pastTrips = '/api/trips/past';

  // Event Endpoints
  static const String events = '/api/events';
  static String eventDetails(String id) => '/api/events/$id';
  static String registerEvent(String id) => '/api/events/$id/register';
  static String unregisterEvent(String id) => '/api/events/$id/unregister';
  static const String myEvents = '/api/events/my-events';

  // Gallery Endpoints (Node.js API)
  static const String gallery = '/api/gallery';
  static const String galleryAlbums = '/api/gallery/albums';
  static String albumPhotos(String albumId) => '/api/gallery/albums/$albumId/photos';
  static const String uploadPhoto = '/api/gallery/upload';
  static String photoDetails(String photoId) => '/api/gallery/photos/$photoId';
  static String likePhoto(String photoId) => '/api/gallery/photos/$photoId/like';
  static String commentPhoto(String photoId) => '/api/gallery/photos/$photoId/comment';

  // Member Endpoints
  static const String members = '/api/members';
  static String memberProfile(String id) => '/api/members/$id';
  static const String memberSearch = '/api/members/search';
  static const String memberStats = '/api/members/stats';
  
  // Global Search Endpoint
  static const String globalSearch = '/api/search/';

  // Notification Endpoints
  static const String notifications = '/api/notifications';
  static const String markNotificationsAsRead = '/api/notifications/mark-as-read/';
  static const String notificationSettings = '/api/notifications/settings';

  // Vehicle Endpoints
  static const String vehicles = '/api/vehicles';
  static String vehicleDetails(String id) => '/api/vehicles/$id';
  static const String myVehicles = '/api/vehicles/my-vehicles';
  static const String addVehicle = '/api/vehicles/add';
  static String updateVehicle(String id) => '/api/vehicles/$id/update';
  static String deleteVehicle(String id) => '/api/vehicles/$id/delete';

  // Emergency Endpoints
  static const String emergencyContacts = '/api/emergency/contacts';
  static const String reportEmergency = '/api/emergency/report';
  static const String activeEmergencies = '/api/emergency/active';

  // News & Announcements
  static const String news = '/api/news';
  static String newsDetails(String id) => '/api/news/$id';
  static const String announcements = '/api/announcements';

  // Location & Tracking (for convoy mode)
  static String tripTracking(String tripId) => '/api/tracking/trips/$tripId';
  static String updateLocation(String tripId) => '/api/tracking/trips/$tripId/location';
  static String tripMembers(String tripId) => '/api/tracking/trips/$tripId/members';

  // Admin Endpoints (for admins and moderators)
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminUsers = '/api/admin/users';
  static const String adminTrips = '/api/admin/trips';
  static const String adminEvents = '/api/admin/events';
  static String approveTrip(String id) => '/api/admin/trips/$id/approve';
  static String rejectTrip(String id) => '/api/admin/trips/$id/reject';
}
