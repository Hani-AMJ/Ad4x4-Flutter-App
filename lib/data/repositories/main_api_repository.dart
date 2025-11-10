import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/main_api_endpoints.dart';
import '../models/trip_model.dart';

/// Main API Repository
/// 
/// Handles all API calls to the Main API (Django backend)
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
  Future<Map<String, dynamic>> getTrips({
    String? startTimeAfter,
    String? startTimeBefore,
    String? cutOffAfter,
    String? cutOffBefore,
    String? approvalStatus,  // pending, approved, declined
    int? levelId,
    int? levelNumericLevel,
    String? levelNumericLevelRange,
    String? meetingPointArea,
    String ordering = 'startTime',
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'ordering': ordering,
      'page': page,
      'pageSize': pageSize,
    };

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
    if (approvalStatus != null) {
      queryParams['approvalStatus'] = approvalStatus;
    }

    final response = await _apiClient.get(
      MainApiEndpoints.trips,
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
      MainApiEndpoints.trips,
      data: data,
    );
    return response.data;
  }

  /// Update trip (full update)
  Future<Map<String, dynamic>> updateTrip(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      MainApiEndpoints.tripDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Partial update trip
  Future<Map<String, dynamic>> patchTrip(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.tripDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Delete trip
  Future<void> deleteTrip(int id) async {
    await _apiClient.delete(MainApiEndpoints.tripDetail(id));
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
      data: {'member_id': memberId},
    );
  }

  /// Remove member from trip (marshal)
  Future<void> removeMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripRemoveMember(tripId),
      data: {'member_id': memberId},
    );
  }

  /// Add member from waitlist (marshal)
  Future<void> addFromWaitlist(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripAddFromWaitlist(tripId),
      data: {'member_id': memberId},
    );
  }

  /// Check in member (marshal)
  Future<void> checkinMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckin(tripId),
      data: {'member_id': memberId},
    );
  }

  /// Check out member (marshal)
  Future<void> checkoutMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckout(tripId),
      data: {'member_id': memberId},
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
    return response.data;
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
    return response.data;
  }

  // ============================================================================
  // MEMBERS
  // ============================================================================

  /// Get members list
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
}
