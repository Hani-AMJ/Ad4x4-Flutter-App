import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/main_api_endpoints.dart';
import '../models/trip_model.dart';

/// Main API Repository
/// 
/// Handles all API calls to the Main API (Django backend)
/// 
/// ⚠️ IMPORTANT: Check docs/API_QUERY_PARAMETERS.md for available query parameters!
/// Many endpoints support server-side filtering - use it instead of fetching all data.
/// 
/// Examples:
/// - GET /api/members/?level_Name=Marshal (filter by level)
/// - GET /api/members/?firstName_Icontains=john (search by name)
/// - GET /api/trips/?status=upcoming (filter by status)
class MainApiRepository {
  final ApiClient _apiClient;

  MainApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: ApiConfig.mainApiBaseUrl);

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  /// Login with username/email and password
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.login,
      data: {
        'login': login,
        'password': password,
      },
    );
    return response.data;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(MainApiEndpoints.profile);
    return response.data;
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.profile,
      data: data,
    );
    return response.data;
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Send reset password link
  Future<void> sendResetPasswordLink({required String login}) async {
    await _apiClient.post(
      MainApiEndpoints.sendResetPasswordLink,
      data: {'login': login},
    );
  }

  /// Reset password with token
  Future<void> resetPassword({
    required int userId,
    required int timestamp,
    required String signature,
    required String password,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.resetPassword,
      data: {
        'userId': userId,
        'timestamp': timestamp,
        'signature': signature,
        'password': password,
      },
    );
  }

  // ============================================================================
  // TRIPS ENDPOINTS
  // ============================================================================

  /// Get trips list with filters
  /// Returns list of TripListItem objects
  /// 
  /// NOTE: Backend doesn't support approvalStatus filter yet.
  /// To get pending trips, fetch all and filter client-side by trip.approvalStatus == 'pending'
  Future<Map<String, dynamic>> getTrips({
    String? startTimeAfter,
    String? startTimeBefore,
    String? cutOffAfter,
    String? cutOffBefore,
    // String? approvalStatus,  // NOT SUPPORTED BY BACKEND - filter client-side
    int? levelId,
    int? levelNumericLevel,
    String? levelNumericLevelRange,
    String? meetingPointArea,
    String? ordering,  // ✅ FIXED: Make optional, no default - caller decides
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    
    // ✅ FIXED: Only add ordering if explicitly provided
    if (ordering != null) {
      queryParams['ordering'] = ordering;
    }

    if (startTimeAfter != null) queryParams['startTimeAfter'] = startTimeAfter;
    if (startTimeBefore != null) queryParams['startTimeBefore'] = startTimeBefore;
    if (cutOffAfter != null) queryParams['cutOffAfter'] = cutOffAfter;
    if (cutOffBefore != null) queryParams['cutOffBefore'] = cutOffBefore;
    if (levelId != null) queryParams['level_Id'] = levelId;
    if (levelNumericLevel != null) {
      queryParams['level_NumericLevel'] = levelNumericLevel;
    }
    if (levelNumericLevelRange != null) {
      queryParams['level_NumericLevel_Range'] = levelNumericLevelRange;
    }
    if (meetingPointArea != null) {
      queryParams['meetingPoint_Area'] = meetingPointArea;
    }
    // approvalStatus NOT supported by backend - removed

    final response = await _apiClient.get(
      MainApiEndpoints.tripsList,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get trip detail by ID
  /// Returns full Trip object with registered members and waitlist
  Future<Map<String, dynamic>> getTripDetail(int id) async {
    final response = await _apiClient.get(MainApiEndpoints.tripDetail(id));
    return response.data;
  }

  /// Create new trip
  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      MainApiEndpoints.tripsCreate,  // ✅ FIXED: Use tripsCreate (no trailing slash) for POST
      data: data,
    );
    return response.data;
  }

  /// Update trip (full update)
  Future<Map<String, dynamic>> updateTrip(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      MainApiEndpoints.tripUpdate(id),  // ✅ FIXED: Use tripUpdate (no trailing slash) for PUT
      data: data,
    );
    return response.data;
  }

  /// Partial update trip
  Future<Map<String, dynamic>> patchTrip(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.tripUpdate(id),  // ✅ FIXED: Use tripUpdate (no trailing slash) for PATCH
      data: data,
    );
    return response.data;
  }

  /// Delete trip
  Future<void> deleteTrip(int id) async {
    await _apiClient.delete(MainApiEndpoints.tripDelete(id));  // ✅ FIXED: Use tripDelete (no trailing slash) for DELETE
  }

  /// Register for trip
  /// Optional: vehicle_capacity (int)
  Future<void> registerForTrip(int tripId, {int? vehicleCapacity}) async {
    await _apiClient.post(
      MainApiEndpoints.tripRegister(tripId),
      data: vehicleCapacity != null ? {'vehicle_capacity': vehicleCapacity} : null,
    );
  }

  /// Unregister from trip
  Future<void> unregisterFromTrip(int tripId) async {
    await _apiClient.post(MainApiEndpoints.tripUnregister(tripId));
  }

  /// Join trip waitlist
  Future<Map<String, dynamic>> joinWaitlist(int tripId) async {
    final response = await _apiClient.post(MainApiEndpoints.tripWaitlist(tripId));
    return response.data as Map<String, dynamic>;
  }

  /// Leave trip waitlist (same endpoint, acts as toggle)
  Future<Map<String, dynamic>> leaveWaitlist(int tripId) async {
    final response = await _apiClient.post(MainApiEndpoints.tripWaitlist(tripId));
    return response.data as Map<String, dynamic>;
  }

  // ============================================================================
  // TRIP ADMIN ACTIONS
  // ============================================================================

  /// Approve trip (admin)
  Future<void> approveTrip(int tripId) async {
    await _apiClient.post(MainApiEndpoints.tripApprove(tripId));
  }

  /// Decline trip (admin)
  Future<void> declineTrip(int tripId, {String? reason}) async {
    await _apiClient.post(
      MainApiEndpoints.tripDecline(tripId),
      data: reason != null ? {'reason': reason} : null,
    );
  }

  /// Force register member (marshal)
  Future<void> forceRegisterMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripForceRegister(tripId),
      data: {'member': memberId},  // ✅ FIXED: API docs show 'member' not 'member_id'
    );
  }

  /// Remove member from trip (marshal)
  Future<void> removeMember(int tripId, int memberId, {String? reason}) async {
    final data = <String, dynamic>{'member': memberId};  // ✅ FIXED: API docs show 'member' not 'member_id'
    if (reason != null) data['reason'] = reason;
    await _apiClient.post(
      MainApiEndpoints.tripRemoveMember(tripId),
      data: data,
    );
  }

  /// Add member from waitlist (marshal)
  Future<void> addFromWaitlist(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripAddFromWaitlist(tripId),
      data: {'member': memberId},  // ✅ FIXED: API docs show 'member' not 'member_id'
    );
  }

  /// Check in member (marshal)
  Future<void> checkinMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckin(tripId),
      data: {'members': [memberId]},  // ✅ FIXED: API docs show 'members' array not 'member_id'
    );
  }

  /// Check out member (marshal)
  Future<void> checkoutMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckout(tripId),
      data: {'members': [memberId]},  // ✅ FIXED: API docs show 'members' array not 'member_id'
    );
  }

  // ============================================================================
  // TRIP COMMENTS (CHAT)
  // ============================================================================

  /// Get trip comments
  Future<Map<String, dynamic>> getTripComments({
    required int tripId,
    String ordering = 'created',
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.tripComments(tripId),
      queryParameters: {
        'ordering': ordering,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data;
  }

  /// Post trip comment
  Future<Map<String, dynamic>> postTripComment({
    required int tripId,
    required String comment,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.postTripComment,
      data: {
        'trip': tripId,
        'comment': comment,
      },
    );
    return response.data;
  }

  // ============================================================================
  // MEETING POINTS & LEVELS
  // ============================================================================

  /// Get meeting points
  Future<List<dynamic>> getMeetingPoints() async {
    final response = await _apiClient.get(MainApiEndpoints.meetingPoints);
    // API returns paginated response: {count, next, previous, results}
    // Extract the results array
    if (response.data is Map<String, dynamic>) {
      return response.data['results'] as List<dynamic>? ?? [];
    }
    // Fallback for non-paginated response (backward compatibility)
    return response.data is List ? response.data : [];
  }

  /// Create meeting point
  Future<Map<String, dynamic>> createMeetingPoint(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      MainApiEndpoints.meetingPoints,
      data: data,
    );
    return response.data;
  }

  /// Get levels
  Future<List<dynamic>> getLevels() async {
    final response = await _apiClient.get(MainApiEndpoints.levels);
    // Handle paginated response structure
    if (response.data is Map && (response.data as Map).containsKey('results')) {
      return (response.data as Map)['results'] as List<dynamic>;
    }
    return response.data as List<dynamic>;
  }

  // ============================================================================
  // MEMBERS
  // ============================================================================

  /// Get members list
  /// 
  /// ⚠️ NOTE: This method only exposes basic parameters. 
  /// For advanced filtering (e.g., by level), use ApiClient directly:
  /// 
  /// Example - Filter by level:
  /// ```dart
  /// final response = await apiClient.get('/api/members/', queryParameters: {
  ///   'level_Name': 'Marshal',
  ///   'pageSize': 500,
  /// });
  /// ```
  /// 
  /// See docs/API_QUERY_PARAMETERS.md for all available parameters.
  Future<Map<String, dynamic>> getMembers({
    String? firstNameContains,
    String? lastNameContains,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (firstNameContains != null) {
      queryParams['firstName_Icontains'] = firstNameContains;
    }
    if (lastNameContains != null) {
      queryParams['lastName_Icontains'] = lastNameContains;
    }

    final response = await _apiClient.get(
      MainApiEndpoints.members,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get member detail
  Future<Map<String, dynamic>> getMemberDetail(int id) async {
    final response = await _apiClient.get(MainApiEndpoints.memberDetail(id));
    return response.data;
  }

  /// Update member (admin) - full update
  /// ✅ NEW: Added for admin member editing
  Future<Map<String, dynamic>> updateMember(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      MainApiEndpoints.memberDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Patch member (admin) - partial update
  /// ✅ NEW: Added for admin member editing
  Future<Map<String, dynamic>> patchMember(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.memberDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Get member trip history
  Future<Map<String, dynamic>> getMemberTripHistory({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberTripHistory(memberId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data;
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Get notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data;
  }

  // ============================================================================
  // CLUB NEWS
  // ============================================================================

  /// Get club news
  Future<Map<String, dynamic>> getClubNews({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.clubNews,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data;
  }

  // ============================================================================
  // TRIP REQUESTS
  // ============================================================================

  /// Get member trip requests
  Future<Map<String, dynamic>> getMemberTripRequests({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberTripRequests(memberId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return response.data;
  }

  /// Create trip request
  Future<Map<String, dynamic>> createTripRequest({
    required String title,
    required String description,
    String? suggestedLocation,
    DateTime? suggestedDate,
  }) async {
    final data = {
      'title': title,
      'description': description,
      if (suggestedLocation != null) 'suggested_location': suggestedLocation,
      if (suggestedDate != null)
        'suggested_date': suggestedDate.toIso8601String().split('T')[0],
    };

    final response = await _apiClient.post(
      MainApiEndpoints.createTripRequest,
      data: data,
    );
    return response.data;
  }

  // ============================================================================
  // UPGRADE REQUESTS
  // ============================================================================

  /// Get upgrade requests list with filters
  /// [status] - Filter by status: 'pending', 'approved', 'declined'
  /// [page] - Page number (1-based)
  /// [limit] - Number of items per page
  Future<Map<String, dynamic>> getUpgradeRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      MainApiEndpoints.upgradeRequests,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get upgrade request details by ID
  Future<Map<String, dynamic>> getUpgradeRequestDetail(int requestId) async {
    final response = await _apiClient.get(
      MainApiEndpoints.upgradeRequestDetail(requestId),
    );
    return response.data;
  }

  /// Vote on an upgrade request
  /// [requestId] - ID of the upgrade request
  /// [approve] - true to approve, false to decline
  /// [comment] - Optional comment with the vote
  Future<void> voteUpgradeRequest({
    required int requestId,
    required bool approve,
    String? comment,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.upgradeRequestVote(requestId),
      data: {
        'approve': approve,
        if (comment != null) 'comment': comment,
      },
    );
  }

  /// Approve an upgrade request (final approval by admin/board)
  /// [requestId] - ID of the upgrade request
  Future<void> approveUpgradeRequest(int requestId) async {
    await _apiClient.post(
      MainApiEndpoints.upgradeRequestApprove(requestId),
    );
  }

  /// Decline an upgrade request (final decline by admin/board)
  /// [requestId] - ID of the upgrade request
  /// [reason] - Reason for declining
  Future<void> declineUpgradeRequest({
    required int requestId,
    required String reason,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.upgradeRequestDecline(requestId),
      data: {'reason': reason},
    );
  }

  /// Add comment to an upgrade request
  /// [requestId] - ID of the upgrade request
  /// [text] - Comment text
  Future<Map<String, dynamic>> createUpgradeRequestComment({
    required int requestId,
    required String text,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.upgradeRequestComments(requestId),
      data: {'text': text},
    );
    return response.data;
  }

  /// Delete a comment from an upgrade request
  /// [commentId] - ID of the comment to delete
  Future<void> deleteUpgradeRequestComment(int commentId) async {
    await _apiClient.delete(
      MainApiEndpoints.upgradeRequestCommentDelete(commentId),
    );
  }

  /// Create a new upgrade request
  /// [memberId] - ID of the member (for admins creating for others)
  /// [requestedLevel] - Requested level name
  /// [reason] - Reason for the upgrade request
  Future<Map<String, dynamic>> createUpgradeRequest({
    required int memberId,
    required String requestedLevel,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.upgradeRequests,
      data: {
        'member_id': memberId,
        'requested_level': requestedLevel,
        'reason': reason,
      },
    );
    return response.data;
  }

  /// Edit an existing upgrade request
  /// [requestId] - ID of the upgrade request
  /// [requestedLevel] - New requested level (optional)
  /// [reason] - New reason (optional)
  Future<Map<String, dynamic>> editUpgradeRequest({
    required int requestId,
    String? requestedLevel,
    String? reason,
  }) async {
    final data = <String, dynamic>{};
    if (requestedLevel != null) data['requested_level'] = requestedLevel;
    if (reason != null) data['reason'] = reason;

    final response = await _apiClient.patch(
      MainApiEndpoints.upgradeRequestDetail(requestId),
      data: data,
    );
    return response.data;
  }

  /// Delete an upgrade request
  /// [requestId] - ID of the upgrade request
  Future<void> deleteUpgradeRequest(int requestId) async {
    await _apiClient.delete(
      MainApiEndpoints.upgradeRequestDetail(requestId),
    );
  }

  // ============================================================================
  // LOGBOOK ENDPOINTS
  // ============================================================================

  /// Get logbook entries
  /// Returns paginated list of logbook entries
  /// Optional filters: member (member ID), trip (trip ID)
  Future<Map<String, dynamic>> getLogbookEntries({
    int? memberId,
    int? tripId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (memberId != null) queryParams['member'] = memberId;
    if (tripId != null) queryParams['trip'] = tripId;

    final response = await _apiClient.get(
      MainApiEndpoints.logbookEntries,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Create a new logbook entry
  /// [tripId] - ID of the trip
  /// [memberId] - ID of the member
  /// [skillIds] - List of skill IDs verified
  /// [comment] - Optional comment
  Future<Map<String, dynamic>> createLogbookEntry({
    required int tripId,
    required int memberId,
    required List<int> skillIds,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.logbookEntries,
      data: {
        'trip': tripId,
        'member': memberId,
        'skillsVerified': skillIds,
        if (comment != null) 'comment': comment,
      },
    );
    return response.data;
  }

  /// Get all logbook skills
  /// Returns paginated list of available skills
  Future<Map<String, dynamic>> getLogbookSkills({
    int? levelId,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (levelId != null) queryParams['level'] = levelId;

    final response = await _apiClient.get(
      MainApiEndpoints.logbookSkills,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get member's logbook skills status
  /// Returns list of skills with verification status for a specific member
  Future<Map<String, dynamic>> getMemberLogbookSkills(int memberId) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberLogbookSkills(memberId),
    );
    return response.data;
  }

  /// Sign off on a skill for a member
  /// Creates a logbook skill reference
  /// [memberId] - ID of the member
  /// [skillId] - ID of the skill
  /// [tripId] - Optional trip ID where skill was demonstrated
  /// [comment] - Optional comment
  Future<Map<String, dynamic>> signOffSkill({
    required int memberId,
    required int skillId,
    int? tripId,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.logbookSkillReferences,
      data: {
        'member': memberId,
        'logbookSkill': skillId,
        if (tripId != null) 'trip': tripId,
        if (comment != null) 'comment': comment,
      },
    );
    return response.data;
  }

  /// Create a trip report
  /// [tripId] - ID of the trip
  /// [report] - Main report content
  /// [safetyNotes] - Optional safety notes
  /// [weatherConditions] - Optional weather description
  /// [terrainNotes] - Optional terrain notes
  /// [participantCount] - Number of participants
  /// [issues] - Optional list of issues encountered
  Future<Map<String, dynamic>> createTripReport({
    required int tripId,
    required String report,
    String? safetyNotes,
    String? weatherConditions,
    String? terrainNotes,
    int? participantCount,
    List<String>? issues,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.createTripLogbookEntry(tripId),
      data: {
        'report': report,
        if (safetyNotes != null) 'safetyNotes': safetyNotes,
        if (weatherConditions != null) 'weatherConditions': weatherConditions,
        if (terrainNotes != null) 'terrainNotes': terrainNotes,
        if (participantCount != null) 'participantCount': participantCount,
        if (issues != null) 'issues': issues,
      },
    );
    return response.data;
  }

  /// Get trip reports
  /// Optional filter by trip ID
  Future<Map<String, dynamic>> getTripReports({
    int? tripId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (tripId != null) queryParams['trip'] = tripId;

    final response = await _apiClient.get(
      '/api/tripreports/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ============================================================================
  // TRIP MEDIA ENDPOINTS (Phase 3B)
  // ============================================================================

  /// Get trip media gallery
  /// Returns paginated list of photos/videos for a trip
  Future<Map<String, dynamic>> getTripMedia({
    required int tripId,
    int page = 1,
    int pageSize = 20,
    bool? approvedOnly,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'trip': tripId,
    };
    if (approvedOnly != null) queryParams['approved'] = approvedOnly;

    final response = await _apiClient.get(
      '/api/trip-media/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get trip media gallery summary
  /// Returns overview with counts and recent uploads
  Future<Map<String, dynamic>> getTripMediaGallery(int tripId) async {
    final response = await _apiClient.get('/api/trips/$tripId/media-gallery/');
    return response.data;
  }

  /// Upload photo to trip
  /// Uses multipart/form-data for file upload
  Future<Map<String, dynamic>> uploadTripPhoto({
    required int tripId,
    required String filePath,
    String? caption,
  }) async {
    final formData = FormData.fromMap({
      'trip': tripId,
      'media_file': await MultipartFile.fromFile(filePath),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'media_type': 'photo',
    });

    final response = await _apiClient.post(
      '/api/trip-media/',
      data: formData,
    );
    return response.data;
  }

  /// Delete trip photo
  /// User can delete their own photos, admins can delete any
  Future<void> deleteTripPhoto(int photoId) async {
    await _apiClient.delete('/api/trip-media/$photoId/');
  }

  /// Moderate photo (admin only)
  /// Approve or reject pending photo
  Future<Map<String, dynamic>> moderatePhoto({
    required int photoId,
    required bool approved,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/api/trip-media/$photoId/moderate/',
      data: {
        'approved': approved,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data;
  }

  /// Get pending photos for moderation
  /// Admin endpoint - returns photos awaiting approval
  Future<Map<String, dynamic>> getPendingPhotos({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/trip-media/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'approved': false,
        'moderated': false,
      },
    );
    return response.data;
  }

  // ============================================================================
  // COMMENT MODERATION ENDPOINTS (Phase 3B)
  // ============================================================================

  /// Get all comments with moderation data
  /// Admin endpoint - includes pending, flagged, and all comments
  Future<Map<String, dynamic>> getAllComments({
    int? tripId,
    bool? pendingOnly,
    bool? flaggedOnly,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (tripId != null) queryParams['trip'] = tripId;
    if (pendingOnly == true) queryParams['status'] = 'pending';
    if (flaggedOnly == true) queryParams['flagged'] = true;

    final response = await _apiClient.get(
      '/api/trip-comments/moderation/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Approve comment
  /// Admin endpoint
  Future<Map<String, dynamic>> approveComment(int commentId) async {
    final response = await _apiClient.post(
      '/api/trip-comments/$commentId/approve/',
    );
    return response.data;
  }

  /// Reject/delete comment
  /// Admin endpoint
  Future<Map<String, dynamic>> rejectComment({
    required int commentId,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/api/trip-comments/$commentId/reject/',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
    return response.data;
  }

  /// Edit comment (admin)
  /// Admin can edit any comment
  Future<Map<String, dynamic>> editComment({
    required int commentId,
    required String newText,
  }) async {
    final response = await _apiClient.patch(
      '/api/trip-comments/$commentId/',
      data: {'comment': newText},
    );
    return response.data;
  }

  /// Ban user from commenting
  /// Admin endpoint
  Future<Map<String, dynamic>> banUserFromCommenting({
    required int userId,
    required String duration,  // 'one_day', 'seven_days', 'thirty_days', 'permanent'
    required String reason,
    bool notifyUser = true,
  }) async {
    final response = await _apiClient.post(
      '/api/users/$userId/ban-from-comments/',
      data: {
        'duration': duration,
        'reason': reason,
        'notify_user': notifyUser,
      },
    );
    return response.data;
  }

  /// Get flagged comments
  /// Admin endpoint - returns user-reported comments
  Future<Map<String, dynamic>> getFlaggedComments({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/trip-comments/flagged/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data;
  }

  /// Flag comment (user action)
  /// Users can report inappropriate comments
  Future<Map<String, dynamic>> flagComment({
    required int commentId,
    required String reason,
    String? details,
  }) async {
    final response = await _apiClient.post(
      '/api/trip-comments/$commentId/flag/',
      data: {
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
    return response.data;
  }

  // ============================================================================
  // REGISTRATION ANALYTICS ENDPOINTS (Phase 3B)
  // ============================================================================

  /// Get registration analytics for a trip
  /// Returns comprehensive statistics and breakdown
  Future<Map<String, dynamic>> getRegistrationAnalytics(int tripId) async {
    final response = await _apiClient.get(
      '/api/trips/$tripId/registration-analytics/',
    );
    return response.data;
  }

  /// Bulk approve registrations
  /// Admin endpoint - approve multiple registrations at once
  Future<Map<String, dynamic>> bulkApproveRegistrations(
    List<int> registrationIds,
  ) async {
    final response = await _apiClient.post(
      '/api/trip-registrations/bulk-approve/',
      data: {'registration_ids': registrationIds},
    );
    return response.data;
  }

  /// Bulk reject registrations
  /// Admin endpoint
  Future<Map<String, dynamic>> bulkRejectRegistrations({
    required List<int> registrationIds,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/api/trip-registrations/bulk-reject/',
      data: {
        'registration_ids': registrationIds,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data;
  }

  /// Bulk check-in registrations
  /// Admin endpoint - check in multiple members at once
  Future<Map<String, dynamic>> bulkCheckinRegistrations(
    List<int> registrationIds,
  ) async {
    final response = await _apiClient.post(
      '/api/trip-registrations/bulk-checkin/',
      data: {'registration_ids': registrationIds},
    );
    return response.data;
  }

  /// Move multiple members from waitlist to confirmed
  /// Admin endpoint
  Future<Map<String, dynamic>> bulkMoveFromWaitlist({
    required int tripId,
    required List<int> memberIds,
    bool notifyMembers = true,
  }) async {
    final response = await _apiClient.post(
      '/api/trips/$tripId/waitlist/bulk-move/',
      data: {
        'member_ids': memberIds,
        'notify_members': notifyMembers,
      },
    );
    return response.data;
  }

  /// Export registrations
  /// Returns download URL for CSV/PDF export
  Future<Map<String, dynamic>> exportRegistrations({
    required int tripId,
    required String format,  // 'csv', 'pdf', 'excel'
    List<String>? fields,
    List<String>? statuses,
  }) async {
    final response = await _apiClient.post(
      '/api/trips/$tripId/registrations/export/',
      data: {
        'format': format,
        if (fields != null) 'fields': fields,
        if (statuses != null) 'statuses': statuses,
      },
    );
    return response.data;
  }

  /// Send notification to registrants
  /// Admin endpoint - send message to all or selected registrants
  Future<Map<String, dynamic>> notifyRegistrants({
    required int tripId,
    required String message,
    List<int>? memberIds,  // null = all registrants
    String notificationType = 'general',
    bool pushNotification = true,
    bool emailNotification = false,
  }) async {
    final response = await _apiClient.post(
      '/api/trips/$tripId/registrations/notify/',
      data: {
        'message': message,
        if (memberIds != null) 'member_ids': memberIds,
        'type': notificationType,
        'push_notification': pushNotification,
        'email_notification': emailNotification,
      },
    );
    return response.data;
  }

  /// Reorder waitlist
  /// Admin endpoint - manually reorder waitlist positions
  Future<Map<String, dynamic>> reorderWaitlist({
    required int tripId,
    required List<Map<String, int>> positions,  // [{'member_id': x, 'position': y}]
  }) async {
    final response = await _apiClient.post(
      '/api/trips/$tripId/waitlist/reorder/',
      data: {'positions': positions},
    );
    return response.data;
  }

  /// Get detailed registration list with analytics
  /// Enhanced registration data for admin management
  Future<Map<String, dynamic>> getDetailedRegistrations({
    required int tripId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _apiClient.get(
      '/api/trips/$tripId/registrations/detailed/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ============================================================================
  // GLOBAL SEARCH ENDPOINT
  // ============================================================================

  /// Global search across trips, members, gallery, and news
  /// 
  /// Endpoint: GET /api/search/?q=keyword&type=trip|member|gallery|news&limit=20&offset=0
  /// 
  /// Parameters:
  /// - q: Search query string
  /// - type: Optional filter by entity type (trip, member, gallery, news)
  /// - limit: Results per page (default: 20)
  /// - offset: Pagination offset (default: 0)
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'limit': limit,
      'offset': offset,
    };
    
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final response = await _apiClient.get(
      MainApiEndpoints.globalSearch,
      queryParameters: queryParams,
    );
    return response.data;
  }
}
