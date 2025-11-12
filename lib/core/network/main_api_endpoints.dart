/// Main API Endpoints
/// 
/// All endpoints for the Main API (Django backend)
class MainApiEndpoints {
  // Auth endpoints
  static const String login = '/api/auth/login/';
  static const String profile = '/api/auth/profile/';
  static const String changePassword = '/api/auth/change-password/';
  static const String sendResetPasswordLink = '/api/auth/send-reset-password-link/';
  static const String resetPassword = '/api/auth/reset-password/';
  static const String notificationSettings = '/api/auth/profile/notificationsettings';

  // Device registration
  static const String registerFCM = '/api/device/fcm/';
  static const String registerAPNS = '/api/device/apns/';

  // Trips endpoints
  // ⚠️ CRITICAL: Django API has different trailing slash rules for different operations!
  // - POST /api/trips (create) - NO trailing slash
  // - GET /api/trips/ (list) - HAS trailing slash
  // - PUT /api/trips/{id} (update) - NO trailing slash
  // - GET /api/trips/{id}/ (detail) - HAS trailing slash
  static const String tripsList = '/api/trips/';  // For GET (list trips)
  static const String tripsCreate = '/api/trips';  // For POST (create trip)
  static String tripDetail(int id) => '/api/trips/$id/';  // For GET (trip details)
  static String tripUpdate(int id) => '/api/trips/$id';  // For PUT/PATCH (update trip)
  static String tripDelete(int id) => '/api/trips/$id';  // For DELETE
  static String tripRegister(int id) => '/api/trips/$id/register';
  static String tripUnregister(int id) => '/api/trips/$id/unregister';
  static String tripWaitlist(int id) => '/api/trips/$id/waitlist';
  static String tripApprove(int id) => '/api/trips/$id/approve';
  static String tripDecline(int id) => '/api/trips/$id/decline';
  static String tripForceRegister(int id) => '/api/trips/$id/forceregister';
  static String tripRemoveMember(int id) => '/api/trips/$id/removemember';
  static String tripAddFromWaitlist(int id) => '/api/trips/$id/addfromwaitlist';
  static String tripCheckin(int id) => '/api/trips/$id/checkin';
  static String tripCheckout(int id) => '/api/trips/$id/checkout';
  static String tripExportRegistrants(int id, {String format = 'csv'}) =>
      '/api/trips/$id/exportregistrants?format=$format';
  static String tripBindGallery(int id) => '/api/trips/$id/bind-gallery';

  // Trip comments (chat)
  static String tripComments(int tripId) => '/api/trips/$tripId/comments';
  static const String postTripComment = '/api/tripcomments/';

  // Trip requests
  static String memberTripRequests(int memberId) => '/api/members/$memberId/triprequests';
  static const String createTripRequest = '/api/triprequests';

  // Meeting points
  static const String meetingPoints = '/api/meetingpoints/';  // ✅ FIXED: Added trailing slash per API docs

  // Levels
  static const String levels = '/api/levels/';

  // Members
  static const String members = '/api/members/';
  static String memberDetail(int id) => '/api/members/$id/';
  static String memberTripHistory(int id) => '/api/members/$id/triphistory';
  static String memberLogbookSkills(int id) => '/api/members/$id/logbookskills';
  static String memberTripCounts(int id) => '/api/members/$id/tripcounts';

  // Logbook endpoints
  static const String logbookEntries = '/api/logbookentries/';
  static const String logbookSkills = '/api/logbookskills/';
  static const String logbookSkillReferences = '/api/logbookskillreferences';
  static String createTripLogbookEntry(int tripId) => '/api/trips/$tripId/logbook-entries';

  // Club news
  static const String clubNews = '/api/clubnews/';

  // Sponsors
  static const String sponsors = '/api/sponsors/';

  // FAQs
  static const String faqs = '/api/faqs/';

  // Notifications
  static const String notifications = '/api/notifications/';

  // Search (future unified endpoint)
  static const String search = '/api/search';

  // Upgrade requests
  // ✅ FIXED: Corrected to match API docs - no hyphen in "upgraderequests"
  static const String upgradeRequests = '/api/upgraderequests/';
  static String upgradeRequestDetail(int id) => '/api/upgraderequests/$id/';
  static String upgradeRequestVote(int id) => '/api/upgraderequests/$id/vote';
  static String upgradeRequestApprove(int id) => '/api/upgraderequests/$id/approve';
  static String upgradeRequestDecline(int id) => '/api/upgraderequests/$id/decline';
  static String upgradeRequestComments(int id) => '/api/upgraderequests/$id/comments';
  static String upgradeRequestCommentDelete(int commentId) => '/api/upgraderequestcomments/$commentId/';
}
