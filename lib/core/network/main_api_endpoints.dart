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
  static const String trips = '/api/trips/';
  static String tripDetail(int id) => '/api/trips/$id/';
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
  static const String meetingPoints = '/api/meetingpoints';

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
}
