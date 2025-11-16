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
  static const String tripRequests = '/api/triprequests/';  // List all (admin)
  static const String createTripRequest = '/api/triprequests/';  // ✅ FIXED: Added trailing slash for Django compatibility
  static String tripRequestDetail(int id) => '/api/triprequests/$id/';  // Update/detail (admin)

  // Meeting points
  static const String meetingPoints = '/api/meetingpoints/';  // ✅ FIXED: Added trailing slash per API docs
  static String meetingPointDetail(int id) => '/api/meetingpoints/$id/';

  // Levels
  static const String levels = '/api/levels/';

  // Feedback
  static const String feedback = '/api/feedback/';  // List all (admin)
  static const String submitFeedback = '/api/feedback/';
  static String feedbackDetail(int id) => '/api/feedback/$id/';  // Update/detail (admin)

  // Members
  static const String members = '/api/members/';
  static String memberDetail(int id) => '/api/members/$id/';
  static String memberFeedback(int id) => '/api/members/$id/feedback';
  static String memberLogbookEntries(int id) => '/api/members/$id/logbookentries';
  static String memberLogbookSkills(int id) => '/api/members/$id/logbookskills';
  static String memberTripCounts(int id) => '/api/members/$id/tripcounts';
  static String memberTripHistory(int id) => '/api/members/$id/triphistory';
  static String memberTripRequests(int id) => '/api/members/$id/triprequests';
  static String memberUpgradeRequests(int id) => '/api/members/$id/upgraderequests';
  static String memberPayments(int id) => '/api/members/$id/payments';

  // Logbook endpoints
  static const String logbookEntries = '/api/logbookentries/';
  static const String logbookSkills = '/api/logbookskills/';
  static const String logbookSkillReferences = '/api/logbookskillreferences';

  // Trip reports - ✅ FIXED: Correct endpoint
  static const String tripReports = '/api/tripreports/';
  static String tripReportDetail(int id) => '/api/tripreports/$id/';

  // Club news
  static const String clubNews = '/api/clubnews/';

  // Sponsors
  static const String sponsors = '/api/sponsors/';
  static String sponsorDetail(int id) => '/api/sponsors/$id/';

  // FAQs
  static const String faqs = '/api/faqs/';

  // Global Settings
  static const String globalSettings = '/api/globalsettings/';

  // Groups
  static const String groups = '/api/groups/';
  static String groupDetail(int id) => '/api/groups/$id/';

  // Permission Matrix
  static const String permissionMatrix = '/api/permissionmatrix/';
  static String permissionMatrixDetail(int id) => '/api/permissionmatrix/$id/';

  // Notifications
  static const String notifications = '/api/notifications/';

  // Search (future unified endpoint)
  static const String search = '/api/search';

  // Choices endpoints (dropdown data)
  static const String choicesApprovalStatus = '/api/choices/approvalstatus';
  static const String choicesCarBrand = '/api/choices/carbrand';
  static const String choicesCountries = '/api/choices/countries';
  static const String choicesEmirates = '/api/choices/emirates';
  static const String choicesGender = '/api/choices/gender';
  static const String choicesPermissionMatrixAction = '/api/choices/permissionmatrixaction';
  static const String choicesTimeOfDay = '/api/choices/timeofday';
  static const String choicesTripRequestArea = '/api/choices/triprequestarea';
  static const String choicesUpgradeRequestStatus = '/api/choices/upgraderequeststatus';
  static const String choicesUpgradeRequestVote = '/api/choices/upgraderequestvote';

  // Upgrade requests
  // ✅ FIXED: Corrected to match API docs - no hyphen in "upgraderequests"
  static const String upgradeRequests = '/api/upgraderequests/';
  static String upgradeRequestDetail(int id) => '/api/upgraderequests/$id/';
  static String upgradeRequestVote(int id) => '/api/upgraderequests/$id/vote';  // ✅ POST {"vote": "Y" (yes), "N" (no), or "D" (defer)}
  static String upgradeRequestApprove(int id) => '/api/upgraderequests/$id/approve';
  static String upgradeRequestDecline(int id) => '/api/upgraderequests/$id/decline';
  // ✅ FIXED: Comment creation endpoint - POST /api/upgraderequestcomments/ with {"upgradeRequest": id, "text": text}
  // ✅ FIXED: Comment fetching endpoint - GET /api/upgraderequestcomments/?upgradeRequest=id
  static const String upgradeRequestCommentsCreate = '/api/upgraderequestcomments/';
  static String upgradeRequestCommentDelete(int commentId) => '/api/upgraderequestcomments/$commentId/';
}
