import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/main_api_endpoints.dart';

/// Main API Repository
///
/// Handles all API calls to the Main API (Django backend)
///
/// ============================================================================
/// 📚 COMPREHENSIVE API DOCUMENTATION REFERENCE
/// ============================================================================
///
/// **PRIMARY DOCUMENTATION SOURCE:**
/// `/home/user/docs/upload_files/Ad4x4_Main_API_Documentation_updated.md`
///
/// This comprehensive API documentation (5,051 lines) contains:
/// - ✅ Complete endpoint specifications (88 endpoints documented)
/// - ✅ All query parameters with types and constraints
/// - ✅ Request body schemas with required/optional fields
/// - ✅ Response schemas with exact field names (camelCase)
/// - ✅ Authentication requirements per endpoint
/// - ✅ Pagination parameters (page, pageSize)
/// - ✅ Filter parameters for list endpoints
/// - ✅ Exact HTTP methods (GET/POST/PUT/PATCH/DELETE)
/// - ✅ Trailing slash rules (Django routing conventions)
/// - ✅ Example cURL requests for each endpoint
///
/// **WHEN DEVELOPING NEW FEATURES:**
/// 1. ✅ ALWAYS reference the complete API documentation FIRST
/// 2. ✅ Check exact field names (API uses camelCase in responses)
/// 3. ✅ Verify query parameters available for filtering/search
/// 4. ✅ Check request body schema (required vs optional fields)
/// 5. ✅ Confirm pagination support (page, pageSize)
/// 6. ✅ Review authentication requirements
/// 7. ✅ Check trailing slash rules (GET /list/ vs POST /create)
///
/// **AUDIT REPORTS (for reference):**
/// - `/home/user/docs/AUDIT_REPORT_Section_1_Auth_Profile.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_2_Trip_Management.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_3_Comments_Reports.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_4_Member_Management.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_5_Logbook_System.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_6_Administrative.md`
/// - `/home/user/docs/AUDIT_REPORT_Section_7_Supporting.md`
/// - `/home/user/docs/AUDIT_REPORT_FINAL_COMPREHENSIVE.md`
///
/// **CONSOLIDATED TESTING GUIDE:**
/// `/home/user/docs/CONSOLIDATED_TESTING_GUIDE_All_Phases.md`
/// - 50+ test scenarios with cURL examples
/// - Complete testing instructions for all implemented features
///
/// **COMMON MISTAKES TO AVOID:**
/// - ❌ Using wrong field names (backend uses camelCase in responses)
/// - ❌ Forgetting query parameters (many endpoints support server-side filtering)
/// - ❌ Using wrong HTTP methods (check documentation!)
/// - ❌ Missing required fields in request body
/// - ❌ Incorrect trailing slash (POST /api/trips vs GET /api/trips/)
/// - ❌ Using 'limit' instead of 'pageSize' (API uses pageSize)
///
/// **HELPFUL TIPS:**
/// - 💡 Most list endpoints support pagination (page, pageSize)
/// - 💡 Many endpoints support _Icontains for case-insensitive search
/// - 💡 Range filters use format: 'min,max' or 'min,' or ',max'
/// - 💡 Array filters accept comma-separated values
/// - 💡 Date filters use ISO 8601 format (YYYY-MM-DD)
///
/// ============================================================================
///
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
      data: {'login': login, 'password': password},
    );
    return response.data;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    // Optional fields
    String? dob,
    String? gender,
    String? city,
    String? nationality,
    String? carBrand,
    String? carModel,
    String? carColor,
    int? carYear,
    String? iceName,
    String? icePhone,
    String? avatar,
  }) async {
    final data = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'password2': password, // Confirmation password (same as password)
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
    };

    // Add optional fields only if provided
    if (dob != null) data['dob'] = dob;
    if (gender != null) data['gender'] = gender;
    if (city != null) data['city'] = city;
    if (nationality != null) data['nationality'] = nationality;
    if (carBrand != null) data['carBrand'] = carBrand;
    if (carModel != null) data['carModel'] = carModel;
    if (carColor != null) data['carColor'] = carColor;
    if (carYear != null) data['carYear'] = carYear;
    if (iceName != null) data['iceName'] = iceName;
    if (icePhone != null) data['icePhone'] = icePhone;
    if (avatar != null) data['avatar'] = avatar;

    final response = await _apiClient.post(ApiEndpoints.register, data: data);
    return response.data;
  }

  /// Request password reset (forgot password)
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(MainApiEndpoints.profile);
    return response.data;
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    // Check if avatar file needs to be uploaded
    if (data.containsKey('avatar') && data['avatar'] is String) {
      final avatarPath = data['avatar'] as String;

      // Create FormData for multipart upload
      final formData = FormData();

      // Add avatar file
      if (kIsWeb) {
        // For web, use XFile bytes
        final bytes = await XFile(avatarPath).readAsBytes();
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
          ),
        );
      } else {
        // For mobile, use file path
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatarPath, filename: 'avatar.jpg'),
          ),
        );
      }

      // Add other fields
      data.forEach((key, value) {
        if (key != 'avatar' && value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      final response = await _apiClient.patch(
        MainApiEndpoints.profile,
        data: formData,
      );
      return response.data;
    } else {
      // Regular JSON update without file
      final response = await _apiClient.patch(
        MainApiEndpoints.profile,
        data: data,
      );
      return response.data;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirm,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'password': password,
        'passwordConfirm': passwordConfirm,
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
    required String userId,
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
  /// Get trips with comprehensive filtering and pagination
  ///
  /// Supports filtering by:
  /// - Time ranges: startTime, endTime, cutOff (after/before)
  /// - Approval status: P/A/R/D (Pending/Approved/Rejected/Deleted)
  /// - Level: levelId, levelNumericLevel (exact and range)
  /// - Meeting point: meetingPoint (ID) or meetingPointArea (area code)
  /// - Lead: lead (member ID), deputyLeads (array of member IDs)
  /// - Ordering: any trip field for sorting
  Future<Map<String, dynamic>> getTrips({
    // Time range filters
    String? startTimeAfter,
    String? startTimeBefore,
    String? endTimeAfter, // ✅ ADDED
    String? endTimeBefore, // ✅ ADDED
    String? cutOffAfter,
    String? cutOffBefore,

    // Status and approval
    String? approvalStatus, // ✅ FIXED: Backend DOES support (P/A/R/D)
    // Level filters
    int? levelId,
    int? levelNumericLevel,
    String? levelNumericLevelRange,

    // Meeting point filters
    int? meetingPoint, // ✅ ADDED: Filter by meeting point ID
    String? meetingPointArea, // Filter by area (DXB/NOR/AUH/AAN/LIW)
    // Lead filters
    int? lead, // ✅ ADDED: Filter by lead member ID
    List<int>? deputyLeads, // ✅ ADDED: Filter by deputy leads
    // Search and pagination
    String? search, // ✅ NEW: Search title, description, location
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};

    if (search != null) queryParams['search'] = search;
    if (ordering != null) queryParams['ordering'] = ordering;

    // Time filters
    if (startTimeAfter != null) queryParams['startTimeAfter'] = startTimeAfter;
    if (startTimeBefore != null) {
      queryParams['startTimeBefore'] = startTimeBefore;
    }
    if (endTimeAfter != null) queryParams['endTimeAfter'] = endTimeAfter;
    if (endTimeBefore != null) queryParams['endTimeBefore'] = endTimeBefore;
    if (cutOffAfter != null) queryParams['cutOffAfter'] = cutOffAfter;
    if (cutOffBefore != null) queryParams['cutOffBefore'] = cutOffBefore;

    // Status
    if (approvalStatus != null) queryParams['approvalStatus'] = approvalStatus;

    // Level filters
    if (levelId != null) queryParams['level_Id'] = levelId;
    if (levelNumericLevel != null) {
      queryParams['level_NumericLevel'] = levelNumericLevel;
    }
    if (levelNumericLevelRange != null) {
      queryParams['level_NumericLevel_Range'] = levelNumericLevelRange;
    }

    // Meeting point filters
    if (meetingPoint != null) queryParams['meetingPoint'] = meetingPoint;
    if (meetingPointArea != null) {
      queryParams['meetingPoint_Area'] = meetingPointArea;
    }

    // Lead filters
    if (lead != null) queryParams['lead'] = lead;
    if (deputyLeads != null && deputyLeads.isNotEmpty) {
      queryParams['deputyLeads'] = deputyLeads;
    }

    // Debug: Log query parameters
    print('🌐 [MainApiRepository] GET /api/trips/ with params: $queryParams');

    final response = await _apiClient.get(
      MainApiEndpoints.tripsList,
      queryParameters: queryParams,
    );

    // Debug: Log response summary
    final results = response.data['results'] as List?;
    if (results != null && results.isNotEmpty) {
      final firstTrip = results.first as Map<String, dynamic>;
      print(
        '📊 [MainApiRepository] First trip: ID=${firstTrip['id']}, Start=${firstTrip['startTime']}',
      );
    }

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
      MainApiEndpoints
          .tripsCreate, // ✅ FIXED: Use tripsCreate (no trailing slash) for POST
      data: data,
    );
    return response.data;
  }

  /// Update trip (full update)
  Future<Map<String, dynamic>> updateTrip(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      MainApiEndpoints.tripUpdate(
        id,
      ), // ✅ FIXED: Use tripUpdate (no trailing slash) for PUT
      data: data,
    );
    return response.data;
  }

  /// Partial update trip
  ///
  /// [id] - Trip ID
  /// [data] - Map of fields to update
  /// [imageFile] - Optional image file for multipart/form-data upload
  ///
  /// ✅ FIXED: Supports both JSON (text-only) and multipart/form-data (with image) updates
  /// When imageFile is provided, automatically switches to multipart/form-data format
  Future<Map<String, dynamic>> patchTrip(
    int id,
    Map<String, dynamic> data, {
    dynamic imageFile, // Can be File (mobile) or XFile (web)
  }) async {
    // If image file is provided, use multipart/form-data
    if (imageFile != null) {
      final formData = FormData();

      // Add image file
      if (imageFile is XFile) {
        // XFile from image_picker (web & mobile compatible)
        final bytes = await imageFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(bytes, filename: imageFile.name),
          ),
        );
      } else {
        // Regular File object (mobile)
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: 'trip_image.jpg',
            ),
          ),
        );
      }

      // Add other fields as form fields (not JSON)
      data.forEach((key, value) {
        if (value != null) {
          // Convert lists to JSON string for form data
          if (value is List) {
            formData.fields.add(MapEntry(key, jsonEncode(value)));
          } else {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        }
      });

      if (kDebugMode) {
        debugPrint(
          '🖼️ [patchTrip] Using multipart/form-data for trip $id with image',
        );
      }

      final response = await _apiClient.patch(
        MainApiEndpoints.tripUpdate(id),
        data: formData,
      );
      return response.data;
    } else {
      // No image - use regular JSON
      if (kDebugMode) {
        debugPrint('📝 [patchTrip] Using JSON for trip $id (no image)');
      }

      final response = await _apiClient.patch(
        MainApiEndpoints.tripUpdate(id),
        data: data,
      );
      return response.data;
    }
  }

  /// Delete trip
  Future<void> deleteTrip(int id) async {
    await _apiClient.delete(
      MainApiEndpoints.tripDelete(id),
    ); // ✅ FIXED: Use tripDelete (no trailing slash) for DELETE
  }

  /// Register for trip
  /// Optional: vehicle_capacity (int)
  Future<void> registerForTrip(int tripId, {int? vehicleCapacity}) async {
    await _apiClient.post(
      MainApiEndpoints.tripRegister(tripId),
      data: vehicleCapacity != null
          ? {'vehicle_capacity': vehicleCapacity}
          : null,
    );
  }

  /// Unregister from trip
  Future<void> unregisterFromTrip(int tripId) async {
    await _apiClient.post(MainApiEndpoints.tripUnregister(tripId));
  }

  /// Join trip waitlist
  Future<Map<String, dynamic>> joinWaitlist(int tripId) async {
    final response = await _apiClient.post(
      MainApiEndpoints.tripWaitlist(tripId),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Leave trip waitlist (same endpoint, acts as toggle)
  Future<Map<String, dynamic>> leaveWaitlist(int tripId) async {
    final response = await _apiClient.post(
      MainApiEndpoints.tripWaitlist(tripId),
    );
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
      data: {
        'member': memberId,
      }, // ✅ FIXED: API docs show 'member' not 'member_id'
    );
  }

  /// Remove member from trip (marshal)
  Future<void> removeMember(int tripId, int memberId, {String? reason}) async {
    final data = <String, dynamic>{
      'member': memberId,
    }; // ✅ FIXED: API docs show 'member' not 'member_id'
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
      data: {
        'member': memberId,
      }, // ✅ FIXED: API docs show 'member' not 'member_id'
    );
  }

  /// Check in member (marshal)
  Future<void> checkinMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckin(tripId),
      data: {
        'members': [memberId],
      }, // ✅ FIXED: API docs show 'members' array not 'member_id'
    );
  }

  /// Check out member (marshal)
  Future<void> checkoutMember(int tripId, int memberId) async {
    await _apiClient.post(
      MainApiEndpoints.tripCheckout(tripId),
      data: {
        'members': [memberId],
      }, // ✅ FIXED: API docs show 'members' array not 'member_id'
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
      data: {'trip': tripId, 'comment': comment},
    );
    return response.data;
  }

  // ============================================================================
  // MEETING POINTS & LEVELS
  // ============================================================================

  /// Get meeting points with filters
  /// Supports filtering by area and name search
  Future<Map<String, dynamic>> getMeetingPoints({
    String? area, // Filter by area: 'DXB', 'NOR', 'AUH', 'AAN', 'LIW'
    String? name, // Exact name match
    String? nameContains, // Partial name search
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (area != null) queryParams['area'] = area;
    if (name != null) queryParams['name'] = name;
    if (nameContains != null) queryParams['name_Icontains'] = nameContains;

    final response = await _apiClient.get(
      MainApiEndpoints.meetingPoints,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get meeting point detail
  Future<Map<String, dynamic>> getMeetingPointDetail(int id) async {
    final response = await _apiClient.get(
      MainApiEndpoints.meetingPointDetail(id),
    );
    return response.data;
  }

  /// Create meeting point
  Future<Map<String, dynamic>> createMeetingPoint({
    required String name,
    String? lat,
    String? lon,
    String? link,
    String? area, // 'DXB', 'NOR', 'AUH', 'AAN', 'LIW'
  }) async {
    final data = {
      'name': name,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (link != null) 'link': link,
      if (area != null) 'area': area,
    };
    final response = await _apiClient.post(
      MainApiEndpoints.meetingPoints,
      data: data,
    );
    return response.data;
  }

  /// Update meeting point (full update)
  Future<Map<String, dynamic>> updateMeetingPoint({
    required int id,
    String? name,
    String? lat,
    String? lon,
    String? link,
    String? area,
  }) async {
    final data = {
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (link != null) 'link': link,
      if (area != null) 'area': area,
    };
    final response = await _apiClient.put(
      MainApiEndpoints.meetingPointDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Patch meeting point (partial update)
  Future<Map<String, dynamic>> patchMeetingPoint({
    required int id,
    Map<String, dynamic>? updates,
  }) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.meetingPointDetail(id),
      data: updates,
    );
    return response.data;
  }

  /// Delete meeting point
  Future<void> deleteMeetingPoint(int id) async {
    await _apiClient.delete(MainApiEndpoints.meetingPointDetail(id));
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
  /// Get members list with extensive filtering support
  ///
  /// Supports comprehensive filtering by:
  /// - Name: firstName, lastName (exact and contains)
  /// - Contact: email, phone (exact and contains)
  /// - Location: city, nationality
  /// - Car: carBrand (exact and contains), carYear (exact and range)
  /// - Level: level_Name (exact and contains), level_NumericLevel (exact and range)
  /// - Activity: tripCount (exact and range)
  ///
  /// Example usage:
  /// ```dart
  /// // Find members with Land Rover, level 2-4, who've done 5+ trips
  /// final response = await apiClient.getMembers(
  ///   carBrand: 'LR',
  ///   levelNumericLevelRange: '2,4',
  ///   tripCountRange: '5,',
  /// );
  /// ```
  Future<Map<String, dynamic>> getMembers({
    // Pagination
    int page = 1,
    int pageSize = 20,

    // Search (searches username, firstName, lastName)
    String? search,

    // Ordering (e.g., 'username', '-username', 'firstName', '-createdAt')
    String? ordering,

    // Name filters
    String? firstName,
    String? firstNameContains,
    String? lastName,
    String? lastNameContains,

    // Contact filters
    String? email,
    String? emailContains,
    String? phone,
    String? phoneContains,

    // Location filters
    String? city,
    String? nationality,

    // Car filters
    String?
    carBrand, // Exact match (e.g., 'LR' for Land Rover, 'TO' for Toyota)
    String? carBrandContains, // Partial match
    int? carYear, // Exact year
    String? carYearRange, // Format: 'min,max' or 'min,' or ',max'
    // Level filters
    String? levelName, // Exact match (e.g., 'Marshal', 'Member')
    String? levelNameContains, // Partial match
    int? levelNumericLevel, // Exact level number
    String? levelNumericLevelRange, // Format: 'min,max' or 'min,' or ',max'
    // Activity filters
    int? tripCount, // Exact trip count
    String? tripCountRange, // Format: 'min,max' or 'min,' or ',max'
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};

    // Search and ordering
    if (search != null) queryParams['search'] = search;
    if (ordering != null) queryParams['ordering'] = ordering;

    // Name filters
    if (firstName != null) queryParams['firstName'] = firstName;
    if (firstNameContains != null) {
      queryParams['firstName_Icontains'] = firstNameContains;
    }
    if (lastName != null) queryParams['lastName'] = lastName;
    if (lastNameContains != null) {
      queryParams['lastName_Icontains'] = lastNameContains;
    }

    // Contact filters
    if (email != null) queryParams['email'] = email;
    if (emailContains != null) queryParams['email_Icontains'] = emailContains;
    if (phone != null) queryParams['phone'] = phone;
    if (phoneContains != null) queryParams['phone_Icontains'] = phoneContains;

    // Location filters
    if (city != null) queryParams['city'] = city;
    if (nationality != null) queryParams['nationality'] = nationality;

    // Car filters
    if (carBrand != null) queryParams['carBrand'] = carBrand;
    if (carBrandContains != null) {
      queryParams['carBrand_Icontains'] = carBrandContains;
    }
    if (carYear != null) queryParams['carYear'] = carYear;
    if (carYearRange != null) queryParams['carYear_Range'] = carYearRange;

    // Level filters
    if (levelName != null) queryParams['level_Name'] = levelName;
    if (levelNameContains != null) {
      queryParams['level_Name_Icontains'] = levelNameContains;
    }
    if (levelNumericLevel != null) {
      queryParams['level_NumericLevel'] = levelNumericLevel;
    }
    if (levelNumericLevelRange != null) {
      queryParams['level_NumericLevel_Range'] = levelNumericLevelRange;
    }

    // Activity filters
    if (tripCount != null) queryParams['tripCount'] = tripCount;
    if (tripCountRange != null) queryParams['tripCount_Range'] = tripCountRange;

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

  /// Get member statistics grouped by level
  /// 
  /// Returns a list of levels with member counts for each level.
  /// Only includes active levels with at least 1 member.
  /// Uses efficient API calls to fetch only counts, not full member data.
  Future<List<Map<String, dynamic>>> getMemberLevelStatistics() async {
    try {
      print('📊 [Repository] Fetching member level statistics...');
      
      // Step 1: Fetch all levels
      final levelsResponse = await _apiClient.get('/api/levels/');
      final levelsData = levelsResponse.data['results'] as List;
      
      print('✅ [Repository] Found ${levelsData.length} total levels');
      
      // Step 2: Fetch member count for each active level
      List<Map<String, dynamic>> stats = [];
      for (var levelJson in levelsData) {
        final levelMap = levelJson as Map<String, dynamic>;
        final active = levelMap['active'] as bool? ?? true;
        final levelName = levelMap['name'] as String;
        
        if (!active) {
          print('⏩ [Repository] Skipping inactive level: $levelName');
          continue; // Skip inactive levels
        }
        
        // Get member count for this level (efficient - only fetch count)
        int count = 0;
        try {
          print('🔄 [Repository] Fetching count for $levelName...');
          
          final membersResponse = await _apiClient.get(
            MainApiEndpoints.members,
            queryParameters: {
              'level_Name': levelName,
              'pageSize': 1, // We only need the count, not the actual members
              'page': 1, // Always fetch page 1
            },
          );
          
          count = membersResponse.data['count'] as int;
          print('✅ [Repository] $levelName: $count members');
          
          // Small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // If API returns error or connection fails, assume 0 members
          print('⚠️ [Repository] Error fetching $levelName count: $e');
          print('⚠️ [Repository] Assuming 0 members for $levelName');
          count = 0;
        }
        
        // Skip levels with 0 members
        if (count > 0) {
          stats.add({
            'id': levelMap['id'],
            'name': levelName,
            'displayName': levelMap['displayName'] ?? levelName,
            'numericLevel': levelMap['numericLevel'],
            'memberCount': count,
            'active': active,
          });
        } else {
          print('⏩ [Repository] Skipping empty level: $levelName');
        }
      }
      
      // Sort by numeric level (ascending)
      stats.sort((a, b) => (a['numericLevel'] as int).compareTo(b['numericLevel'] as int));
      
      print('✅ [Repository] Returning ${stats.length} level statistics');
      
      return stats;
    } catch (e) {
      print('❌ [Repository] Error fetching member level stats: $e');
      rethrow;
    }
  }

  /// Update member (admin) - full update
  /// ✅ NEW: Added for admin member editing
  Future<Map<String, dynamic>> updateMember(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      MainApiEndpoints.memberDetail(id),
      data: data,
    );
    return response.data;
  }

  /// Patch member (admin) - partial update
  /// ✅ NEW: Added for admin member editing
  Future<Map<String, dynamic>> patchMember(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.memberDetail(id),
      data: data,
    );
    return response.data;
  }

  // ==========================================
  // === GDPR COMPLIANCE - ACCOUNT DELETION ===
  // ==========================================

  /// Request account deletion (GDPR "Right to be Forgotten")
  ///
  /// This submits a request to delete the user's account. The backend will
  /// schedule the account for deletion (typically 30 days from request).
  /// User can cancel the deletion before it's processed.
  ///
  /// **Backend Behavior:**
  /// - On success: Returns `{"success": true, "message": "deletion_request_submitted"}`
  /// - If duplicate: Returns `{"success": false, "message": "deletion_request_already_exists"}`
  /// - Deletion status NOT returned in member profile (tracked server-side only)
  ///
  /// **Important Notes:**
  /// - Backend does NOT expose deletion status in member profile response
  /// - Frontend must track deletion state locally (SharedPreferences)
  /// - Calculate deletion date as: request_date + 30 days
  ///
  /// **Returns:**
  /// - `success` (bool): Whether request was successful
  /// - `message` (String): Response message key
  ///
  /// **Example Usage:**
  /// ```dart
  /// try {
  ///   final result = await repository.requestAccountDeletion();
  ///   if (result['success'] == true) {
  ///     // Store locally: deletion_requested = true, date = now
  ///     // Show success message with 30-day timeline
  ///     // Display warning banner in settings
  ///   } else if (result['message'] == 'deletion_request_already_exists') {
  ///     // Set local state to deletion requested
  ///     // Show message: "Deletion request already active"
  ///   }
  /// } catch (e) {
  ///   // Show error message
  /// }
  /// ```
  Future<Map<String, dynamic>> requestAccountDeletion() async {
    try {
      final response = await _apiClient.post(
        MainApiEndpoints.requestAccountDeletion,
        data: {},
      );
      return response.data;
    } catch (e) {
      // Handle ApiException and extract error message
      if (e is ApiException) {
        return {
          'success': false,
          'message': e.message,
          'error': e.message,
          'statusCode': e.statusCode,
        };
      }
      // Return error in expected format instead of throwing
      return {'success': false, 'message': e.toString(), 'error': e.toString()};
    }
  }

  /// Cancel pending account deletion request
  ///
  /// Allows user to cancel a deletion request before it's processed.
  /// Only works if deletion hasn't been executed yet (within 30-day window).
  ///
  /// **Backend Behavior:**
  /// - On success: Returns `{"success": true, "message": "deletion_request_cancelled"}`
  /// - If no request: Returns `{"success": false, "message": "deletion_request_not_found"}`
  ///
  /// **Important Notes:**
  /// - Clear local deletion state on successful cancellation
  /// - If returns "not_found", also clear local state (sync issue resolved)
  ///
  /// **Returns:**
  /// - `success` (bool): Whether cancellation was successful
  /// - `message` (String): Response message key
  ///
  /// **Example Usage:**
  /// ```dart
  /// try {
  ///   final result = await repository.cancelAccountDeletion();
  ///   if (result['success'] == true) {
  ///     // Clear local deletion state
  ///     // Hide warning banner
  ///     // Show success message
  ///   } else if (result['message'] == 'deletion_request_not_found') {
  ///     // Clear local state anyway (was out of sync)
  ///     // Show message: "No active deletion request found"
  ///   }
  /// } catch (e) {
  ///   // Show error message
  /// }
  /// ```
  Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final response = await _apiClient.post(
        MainApiEndpoints.cancelAccountDeletion,
        data: {},
      );
      return response.data;
    } catch (e) {
      // Handle ApiException and extract error message
      if (e is ApiException) {
        return {
          'success': false,
          'message': e.message,
          'error': e.message,
          'statusCode': e.statusCode,
        };
      }
      // Return error in expected format instead of throwing
      return {'success': false, 'message': e.toString(), 'error': e.toString()};
    }
  }

  /// Get member trip history
  /// [checkedIn] - Optional filter to include only trips where member is checked in
  Future<Map<String, dynamic>> getMemberTripHistory({
    required int memberId,
    bool? checkedIn,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (checkedIn != null) queryParams['checkedIn'] = checkedIn;

    final response = await _apiClient.get(
      MainApiEndpoints.memberTripHistory(memberId),
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get member feedback
  /// Returns paginated list of feedback for a specific member
  Future<Map<String, dynamic>> getMemberFeedback({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    // ✅ FIXED: Use admin feedback endpoint with user filter
    // The /api/members/{id}/feedback endpoint is for self-only access
    // Use /api/feedback/?user={id} to view another member's feedback (admin/marshal)
    final response = await _apiClient.get(
      MainApiEndpoints.feedback,  // Admin endpoint
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'user': memberId,  // Filter by user ID
      },
    );
    return response.data;
  }

  /// Submit feedback
  /// Submit user feedback (bug report, feature request, etc.)
  /// ✅ NEW: Phase A Task #5 - Profile Screen Enhancements
  ///
  /// [feedbackType] - Type of feedback (BUG, FEATURE, IMPROVEMENT, COMPLAINT, PRAISE, OTHER)
  /// [message] - Feedback message (required)
  /// [image] - Optional screenshot or image URL
  ///
  /// Returns the created feedback object with ID and status
  Future<Map<String, dynamic>> submitFeedback({
    required String feedbackType,
    required String message,
    String? image,
  }) async {
    // Send BOTH camelCase and snake_case to ensure backend compatibility
    final requestData = {
      'feedbackType': feedbackType, // camelCase (as per API docs)
      'feedback_type': feedbackType, // snake_case (backend might expect this)
      'message': message,
      if (image != null) 'image': image,
    };

    if (kDebugMode) {
      debugPrint('🔍 [submitFeedback] Sending: ${json.encode(requestData)}');
    }

    final response = await _apiClient.post(
      MainApiEndpoints.submitFeedback,
      data: requestData,
    );
    return response.data;
  }

  /// Get all feedback (admin only)
  /// ✅ NEW: Phase B Task #2 - Feedback Admin Management
  Future<Map<String, dynamic>> getAllFeedback({
    int page = 1,
    int pageSize = 20,
    String? status, // Filter by status: SUBMITTED, IN_REVIEW, RESOLVED, CLOSED
    String?
    feedbackType, // Filter by type: BUG, FEATURE, IMPROVEMENT, COMPLAINT, PRAISE, OTHER
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.feedback,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (feedbackType != null) 'feedbackType': feedbackType,
      },
    );
    return response.data;
  }

  /// Update feedback status and add admin response (admin only)
  /// ✅ NEW: Phase B Task #2 - Feedback Admin Management
  Future<Map<String, dynamic>> updateFeedback({
    required int feedbackId,
    String? status, // SUBMITTED, IN_REVIEW, RESOLVED, CLOSED
    String? adminResponse,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (adminResponse != null && adminResponse.isNotEmpty) {
      data['admin_response'] = adminResponse;
    }

    final response = await _apiClient.patch(
      MainApiEndpoints.feedbackDetail(feedbackId),
      data: data,
    );
    return response.data;
  }

  /// Delete feedback (admin only)
  /// ✅ NEW: Phase B Task #2 - Feedback Admin Management
  Future<void> deleteFeedback(int feedbackId) async {
    await _apiClient.delete(MainApiEndpoints.feedbackDetail(feedbackId));
  }

  /// Get member logbook entries
  /// Returns paginated list of logbook entries for a specific member
  Future<Map<String, dynamic>> getMemberLogbookEntries({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberLogbookEntries(memberId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Get member logbook skills
  /// Returns paginated list of skill references (sign-offs) for a specific member
  /// ✅ NEW: Proper endpoint implementation (was incomplete)
  Future<Map<String, dynamic>> getMemberLogbookSkills({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberLogbookSkills(memberId),
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'expand':
            'member,trip,signedBy,skill', // ✅ Request full nested objects for certificates
      },
    );
    return response.data;
  }

  /// Get member trip counts and statistics
  /// Returns detailed statistics about member's trip participation
  /// No pagination - returns single stats object
  Future<Map<String, dynamic>> getMemberTripCounts(int memberId) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberTripCounts(memberId),
    );
    return response.data;
  }

  /// Get member upgrade requests
  /// Returns paginated list of upgrade requests for a specific member
  Future<Map<String, dynamic>> getMemberUpgradeRequests({
    required int memberId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.memberUpgradeRequests(memberId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    // 🔍 DEBUG: Log response structure
    if (kDebugMode) {
      print('📦 [Repository] getMemberUpgradeRequests Response:');
      print('   Response type: ${response.runtimeType}');
      print('   Response.data type: ${response.data.runtimeType}');
      print('   Response.data: ${response.data}');
    }

    return response.data;
  }

  /// Update member payment status
  /// Admin-only endpoint to mark member as paid/unpaid
  /// Requires EDIT_MEMBERSHIP_PAYMENTS permission
  Future<Map<String, dynamic>> updateMemberPayment({
    required int memberId,
    required bool paymentReceived,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.memberPayments(memberId),
      data: {'paymentReceived': paymentReceived},
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
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _apiClient.post('${ApiEndpoints.notifications}/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    await _apiClient.post(ApiEndpoints.markAllRead);
  }

  // ============================================================================
  // NOTIFICATION SETTINGS
  // ============================================================================

  /// Get notification settings for current user
  Future<Map<String, dynamic>> getNotificationSettings({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.notificationSettings,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Update notification settings (full update)
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? clubNewsEnabledEmail,
    bool? clubNewsEnabledAppPush,
    bool? newTripAlertsEnabledEmail,
    bool? newTripAlertsEnabledAppPush,
    bool? upgradeRequestReminderEmail,
    List<int>? newTripAlertsLevelFilter,
  }) async {
    final data = <String, dynamic>{};
    if (clubNewsEnabledEmail != null) {
      data['clubNewsEnabledEmail'] = clubNewsEnabledEmail;
    }
    if (clubNewsEnabledAppPush != null) {
      data['clubNewsEnabledAppPush'] = clubNewsEnabledAppPush;
    }
    if (newTripAlertsEnabledEmail != null) {
      data['newTripAlertsEnabledEmail'] = newTripAlertsEnabledEmail;
    }
    if (newTripAlertsEnabledAppPush != null) {
      data['newTripAlertsEnabledAppPush'] = newTripAlertsEnabledAppPush;
    }
    if (upgradeRequestReminderEmail != null) {
      data['upgradeRequestReminderEmail'] = upgradeRequestReminderEmail;
    }
    if (newTripAlertsLevelFilter != null) {
      data['newTripAlertsLevelFilter'] = newTripAlertsLevelFilter;
    }

    final response = await _apiClient.put(
      MainApiEndpoints.notificationSettings,
      data: data,
    );
    return response.data;
  }

  /// Patch notification settings (partial update)
  Future<Map<String, dynamic>> patchNotificationSettings(
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.patch(
      MainApiEndpoints.notificationSettings,
      data: updates,
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
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Get club news detail
  /// ✅ NEW: Added detail endpoint for single news item
  Future<Map<String, dynamic>> getClubNewsDetail(int id) async {
    final response = await _apiClient.get('${MainApiEndpoints.clubNews}$id/');
    return response.data;
  }

  // ============================================================================
  // SPONSORS
  // ============================================================================

  /// Get sponsors list
  /// Returns list of all sponsors (non-paginated endpoint)
  Future<List<dynamic>> getSponsors() async {
    final response = await _apiClient.get(MainApiEndpoints.sponsors);
    return response.data is List ? response.data : [];
  }

  /// Get sponsor detail
  Future<Map<String, dynamic>> getSponsorDetail(int id) async {
    final response = await _apiClient.get(MainApiEndpoints.sponsorDetail(id));
    return response.data;
  }

  // ============================================================================
  // FAQS
  // ============================================================================

  /// Get FAQs list
  /// Returns list of frequently asked questions (non-paginated endpoint)
  Future<List<dynamic>> getFAQs() async {
    final response = await _apiClient.get(MainApiEndpoints.faqs);
    return response.data is List ? response.data : [];
  }

  // ============================================================================
  // GLOBAL SETTINGS
  // ============================================================================

  /// Get global settings
  /// Returns list of configurable settings (non-paginated endpoint)
  Future<List<dynamic>> getGlobalSettings() async {
    final response = await _apiClient.get(MainApiEndpoints.globalSettings);
    return response.data is List ? response.data : [];
  }

  // ============================================================================
  // GROUPS
  // ============================================================================

  /// Get groups list
  /// Returns paginated list of user groups
  Future<Map<String, dynamic>> getGroups({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.groups,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Get group detail
  Future<Map<String, dynamic>> getGroupDetail(int id) async {
    final response = await _apiClient.get(MainApiEndpoints.groupDetail(id));
    return response.data;
  }

  // ============================================================================
  // PERMISSION MATRIX
  // ============================================================================

  /// Get permission matrix list
  /// Returns paginated list of permission matrix entries
  Future<Map<String, dynamic>> getPermissionMatrix({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.permissionMatrix,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Get permission matrix detail
  Future<Map<String, dynamic>> getPermissionMatrixDetail(int id) async {
    final response = await _apiClient.get(
      MainApiEndpoints.permissionMatrixDetail(id),
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
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data;
  }

  /// Create trip request
  ///
  /// Creates a new trip request with structured data matching OpenAPI schema
  ///
  /// [date] - Required trip date
  /// [levelId] - Optional trip difficulty level ID
  /// [timeOfDay] - Optional time preference (MOR/MID/AFT/EVE/ANY)
  /// [area] - Optional area preference (DXB/NOR/AUH/AAN/LIW)
  Future<Map<String, dynamic>> createTripRequest({
    required DateTime date,
    int? levelId,
    String? timeOfDay,
    String? area,
  }) async {
    final data = {
      'date': date.toIso8601String().split(
        'T',
      )[0], // Required - YYYY-MM-DD format
      if (levelId != null) 'level': levelId,
      if (timeOfDay != null) 'timeOfDay': timeOfDay,
      if (area != null) 'area': area,
    };

    if (kDebugMode) {
      debugPrint('🔍 [TripRequestRepo] Creating trip request with data: $data');
    }

    final response = await _apiClient.post(
      MainApiEndpoints.createTripRequest,
      data: data,
    );

    if (kDebugMode) {
      debugPrint(
        '🔍 [TripRequestRepo] Response status: ${response.statusCode}',
      );
      debugPrint(
        '🔍 [TripRequestRepo] Response data type: ${response.data.runtimeType}',
      );
      debugPrint('🔍 [TripRequestRepo] Response data: ${response.data}');
    }

    return response.data;
  }

  /// Get all trip requests (admin only)
  Future<Map<String, dynamic>> getAllTripRequests({
    int page = 1,
    int pageSize = 20,
    String? status, // Filter by status: pending, approved, declined, converted
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.tripRequests,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  /// Update trip request status (admin only)
  Future<Map<String, dynamic>> updateTripRequestStatus({
    required int requestId,
    required String status, // pending, approved, declined, converted
    String? adminNotes,
  }) async {
    final data = {
      'status': status,
      if (adminNotes != null && adminNotes.isNotEmpty)
        'admin_notes': adminNotes,
    };

    final response = await _apiClient.patch(
      MainApiEndpoints.tripRequestDetail(requestId),
      data: data,
    );
    return response.data;
  }

  /// Delete trip request (admin only)
  Future<void> deleteTripRequest(int requestId) async {
    await _apiClient.delete(MainApiEndpoints.tripRequestDetail(requestId));
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
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      MainApiEndpoints.upgradeRequests,
      queryParameters: queryParams,
    );

    // 🔍 DEBUG: Log response structure
    if (kDebugMode) {
      print('📦 [Repository] getUpgradeRequests Response:');
      print('   Response type: ${response.runtimeType}');
      print('   Response.data type: ${response.data.runtimeType}');
      print(
        '   Response.data keys: ${response.data is Map ? (response.data as Map).keys.toList() : "Not a Map"}',
      );
      print('   Response.data: ${response.data}');
    }

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
  /// [vote] - Vote value: "Y" (yes/approve), "N" (no/decline), or "D" (defer)
  /// Note: Vote endpoint does not support comments - use createUpgradeRequestComment separately
  Future<void> voteUpgradeRequest({
    required int requestId,
    required String vote, // "Y" (yes), "N" (no), or "D" (defer)
  }) async {
    if (kDebugMode) {
      print('🗳️ [Repository] POST /api/upgraderequests/$requestId/vote');
      print('🗳️ [Repository] Vote data: {"vote": "$vote"}');
    }

    // ✅ FIXED: Send {"vote": "Y", "N", or "D"} per API spec
    final response = await _apiClient.post(
      MainApiEndpoints.upgradeRequestVote(requestId),
      data: {
        'vote': vote, // Must be "Y" (yes), "N" (no), or "D" (defer)
      },
    );

    if (kDebugMode) {
      print('✅ [Repository] Vote response: ${response.data}');
    }
  }

  /// Approve an upgrade request (final approval by admin/board)
  /// [requestId] - ID of the upgrade request
  Future<void> approveUpgradeRequest(int requestId) async {
    await _apiClient.post(MainApiEndpoints.upgradeRequestApprove(requestId));
  }

  /// Decline an upgrade request (final decline by admin/board)
  /// [requestId] - ID of the upgrade request
  /// [verdictReason] - Reason for declining (required by API)
  Future<void> declineUpgradeRequest({
    required int requestId,
    required String verdictReason,
  }) async {
    await _apiClient.post(
      MainApiEndpoints.upgradeRequestDecline(requestId),
      data: {'verdictReason': verdictReason},
    );
  }

  /// Fetch comments for an upgrade request
  /// [requestId] - ID of the upgrade request
  /// Returns list of comments with author, text, and created timestamp
  Future<List<Map<String, dynamic>>> getUpgradeRequestComments({
    required int requestId,
  }) async {
    final response = await _apiClient.get(
      MainApiEndpoints.upgradeRequestCommentsCreate,
      queryParameters: {
        'upgradeRequest': requestId, // Filter by upgrade request ID
      },
    );
    return List<Map<String, dynamic>>.from(response.data['results'] ?? []);
  }

  /// Add comment to an upgrade request
  /// [requestId] - ID of the upgrade request
  /// [text] - Comment text
  Future<Map<String, dynamic>> createUpgradeRequestComment({
    required int requestId,
    required String text,
  }) async {
    // ✅ FIXED: Use correct endpoint and request body per API spec (lines 3756-3780)
    final response = await _apiClient.post(
      MainApiEndpoints
          .upgradeRequestCommentsCreate, // Changed from upgradeRequestComments(requestId)
      data: {
        'upgradeRequest': requestId, // ✅ FIXED: Added upgradeRequest field
        'text': text,
      },
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
    List<int>? nominatedVoters, // Optional, backend may auto-assign
    dynamic supportingDocument, // XFile or File object for file upload
  }) async {
    // If file is provided, use multipart form data
    if (supportingDocument != null) {
      final formData = FormData.fromMap({
        'applicant': memberId,
        'targetLevel': int.parse(requestedLevel),
        'applicantReason': reason,
        'nominatedVoters': nominatedVoters ?? [],
      });

      // Add file to form data
      if (supportingDocument is XFile) {
        // XFile from image_picker (web & mobile compatible)
        final bytes = await supportingDocument.readAsBytes();
        formData.files.add(
          MapEntry(
            'supportingDocument',
            MultipartFile.fromBytes(bytes, filename: supportingDocument.name),
          ),
        );
      }

      final response = await _apiClient.post(
        MainApiEndpoints.upgradeRequests,
        data: formData,
      );

      if (response.data == null) {
        return {'success': true, 'message': 'Upgrade request created'};
      }
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'data': response.data};
    }

    // No file - use regular JSON request
    final response = await _apiClient.post(
      MainApiEndpoints.upgradeRequests,
      data: {
        'applicant':
            memberId, // ✅ FIXED: Changed from 'member_id' to 'applicant'
        'targetLevel': int.parse(
          requestedLevel,
        ), // ✅ FIXED: Changed to 'targetLevel' and convert to int
        'applicantReason':
            reason, // ✅ FIXED: Changed from 'reason' to 'applicantReason'
        'nominatedVoters':
            nominatedVoters ??
            [], // ✅ FIXED: Added required field (empty array if not provided)
      },
    );
    // ✅ FIXED: Handle different response types (UnifiedResponse might be string, null, or object)
    if (response.data == null) {
      return {'success': true, 'message': 'Upgrade request created'};
    }
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    // If response is a string or other type, wrap it
    return {'success': true, 'data': response.data};
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
    await _apiClient.delete(MainApiEndpoints.upgradeRequestDetail(requestId));
  }

  // ============================================================================
  // LOGBOOK ENDPOINTS
  // ============================================================================

  /// Get logbook entries
  /// Returns paginated list of logbook entries with full nested objects
  /// Optional filters: member (member ID), trip (trip ID)
  Future<Map<String, dynamic>> getLogbookEntries({
    int? memberId,
    int? tripId,
    int page = 1,
    int pageSize = 20, // ✅ FIXED: Changed from 'limit' to 'pageSize'
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'expand':
          'member,trip,signedBy,skillsVerified', // ✅ Request full nested objects
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
  /// [signedBy] - Optional: ID of person who signed/verified
  /// [comment] - Optional comment
  Future<Map<String, dynamic>> createLogbookEntry({
    required int tripId,
    required int memberId,
    required List<int> skillIds,
    int? signedBy,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.logbookEntries,
      data: {
        'trip': tripId,
        'member': memberId,
        'skillsVerified': skillIds,
        if (signedBy != null) 'signedBy': signedBy,
        if (comment != null) 'comment': comment,
      },
    );
    return response.data;
  }

  /// Get logbook entry detail
  Future<Map<String, dynamic>> getLogbookEntryDetail(int id) async {
    final response = await _apiClient.get(
      '${MainApiEndpoints.logbookEntries}$id/',
    );
    return response.data;
  }

  /// Update logbook entry (PUT - full update)
  Future<Map<String, dynamic>> updateLogbookEntry({
    required int id,
    required int tripId,
    required int memberId,
    List<int>? skillsVerified,
    int? signedBy,
    String? comment,
  }) async {
    final response = await _apiClient.put(
      '${MainApiEndpoints.logbookEntries}$id/',
      data: {
        'trip': tripId,
        'member': memberId,
        if (skillsVerified != null) 'skillsVerified': skillsVerified,
        if (signedBy != null) 'signedBy': signedBy,
        if (comment != null) 'comment': comment,
      },
    );
    return response.data;
  }

  /// Patch logbook entry (PATCH - partial update)
  Future<Map<String, dynamic>> patchLogbookEntry({
    required int id,
    Map<String, dynamic>? updates,
  }) async {
    final response = await _apiClient.patch(
      '${MainApiEndpoints.logbookEntries}$id/',
      data: updates ?? {},
    );
    return response.data;
  }

  /// Delete logbook entry
  Future<void> deleteLogbookEntry(int id) async {
    await _apiClient.delete('${MainApiEndpoints.logbookEntries}$id/');
  }

  /// Get all logbook skills
  /// Returns paginated list of available skills with level filtering
  Future<Map<String, dynamic>> getLogbookSkills({
    int? levelEq, // ✅ FIXED: Use correct API parameter name
    int? levelGte,
    int? levelLte,
    bool? levelNull,
    int page = 1,
    int pageSize = 100, // ✅ FIXED: Changed from 'limit' to 'pageSize'
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (levelEq != null) queryParams['levelEq'] = levelEq;
    if (levelGte != null) queryParams['levelGte'] = levelGte;
    if (levelLte != null) queryParams['levelLte'] = levelLte;
    if (levelNull != null) queryParams['levelNull'] = levelNull;

    final response = await _apiClient.get(
      MainApiEndpoints.logbookSkills,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get member's logbook skills status
  /// Returns list of skills with verification status for a specific member
  // ============================================================================
  // LOGBOOK SKILL REFERENCES - ✅ COMPLETE CRUD
  // ============================================================================

  /// Get logbook skill references with filters
  Future<Map<String, dynamic>> getLogbookSkillReferences({
    int? memberId,
    int? skillId,
    int? tripId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (memberId != null) queryParams['member'] = memberId;
    if (skillId != null) queryParams['logbookSkill'] = skillId;
    if (tripId != null) queryParams['trip'] = tripId;

    final response = await _apiClient.get(
      MainApiEndpoints.logbookSkillReferences,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get skill reference detail
  Future<Map<String, dynamic>> getLogbookSkillReferenceDetail(int id) async {
    final response = await _apiClient.get(
      '${MainApiEndpoints.logbookSkillReferences}$id/',
    );
    return response.data;
  }

  /// Sign off on a skill for a member (Create skill reference)
  /// ✅ FIXED: trip is required by API, removed comment (not in API schema)
  Future<Map<String, dynamic>> signOffSkill({
    required int memberId,
    required int skillId,
    required int tripId, // ✅ FIXED: Made required as per API
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.logbookSkillReferences,
      data: {'member': memberId, 'logbookSkill': skillId, 'trip': tripId},
    );
    return response.data;
  }

  /// Update skill reference (PUT - full update)
  Future<Map<String, dynamic>> updateLogbookSkillReference({
    required int id,
    required int logbookSkill,
    required int member,
    required int trip,
  }) async {
    final response = await _apiClient.put(
      '${MainApiEndpoints.logbookSkillReferences}$id/',
      data: {'logbookSkill': logbookSkill, 'member': member, 'trip': trip},
    );
    return response.data;
  }

  /// Patch skill reference (PATCH - partial update)
  Future<Map<String, dynamic>> patchLogbookSkillReference({
    required int id,
    Map<String, dynamic>? updates,
  }) async {
    final response = await _apiClient.patch(
      '${MainApiEndpoints.logbookSkillReferences}$id/',
      data: updates ?? {},
    );
    return response.data;
  }

  /// Delete skill reference
  Future<void> deleteLogbookSkillReference(int id) async {
    await _apiClient.delete('${MainApiEndpoints.logbookSkillReferences}$id/');
  }

  // ============================================================================
  // TRIP REPORTS - ✅ FIXED: Correct endpoint and schema
  // ============================================================================

  /// Create a trip report
  /// Uses correct /api/tripreports/ endpoint with proper schema
  Future<Map<String, dynamic>> createTripReport({
    required int tripId,
    required String title,
    required String reportText,
    String? trackFile,
    String? trackImage,
    List<String>? imageFiles,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.tripReports,
      data: {
        'trip': tripId,
        'title': title,
        'reportText': reportText,
        if (trackFile != null) 'trackFile': trackFile,
        if (trackImage != null) 'trackImage': trackImage,
        if (imageFiles != null) 'imageFiles': imageFiles,
      },
    );
    return response.data;
  }

  /// Get trip reports with filters
  Future<Map<String, dynamic>> getTripReports({
    int? tripId,
    int? memberId,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (tripId != null) queryParams['trip'] = tripId;
    if (memberId != null) queryParams['member'] = memberId;
    if (ordering != null) queryParams['ordering'] = ordering;

    final response = await _apiClient.get(
      MainApiEndpoints.tripReports,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Get trip report detail
  Future<Map<String, dynamic>> getTripReportDetail(int id) async {
    final response = await _apiClient.get(
      MainApiEndpoints.tripReportDetail(id),
    );
    return response.data;
  }

  /// Update trip report (PUT)
  Future<Map<String, dynamic>> updateTripReport({
    required int id,
    required int tripId,
    required String title,
    required String reportText,
    String? trackFile,
    String? trackImage,
    List<String>? imageFiles,
  }) async {
    final response = await _apiClient.put(
      MainApiEndpoints.tripReportDetail(id),
      data: {
        'trip': tripId,
        'title': title,
        'reportText': reportText,
        if (trackFile != null) 'trackFile': trackFile,
        if (trackImage != null) 'trackImage': trackImage,
        if (imageFiles != null) 'imageFiles': imageFiles,
      },
    );
    return response.data;
  }

  /// Delete trip report
  Future<void> deleteTripReport(int id) async {
    await _apiClient.delete(MainApiEndpoints.tripReportDetail(id));
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

    final response = await _apiClient.post('/api/trip-media/', data: formData);
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
      data: {'approved': approved, if (reason != null) 'reason': reason},
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
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};
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
      data: {if (reason != null) 'reason': reason},
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
    required String
    duration, // 'one_day', 'seven_days', 'thirty_days', 'permanent'
    required String reason,
    bool notifyUser = true,
  }) async {
    final response = await _apiClient.post(
      '/api/users/$userId/ban-from-comments/',
      data: {'duration': duration, 'reason': reason, 'notify_user': notifyUser},
    );
    return response.data;
  }

  /// Get flagged comments
  /// Admin endpoint - returns user-reported comments
  /// Uses the moderation endpoint with flagged=true filter
  Future<Map<String, dynamic>> getFlaggedComments({
    int page = 1,
    int pageSize = 20,
  }) async {
    // Use the moderation endpoint with flagged filter instead of non-existent /flagged/ endpoint
    return await getAllComments(
      flaggedOnly: true,
      page: page,
      pageSize: pageSize,
    );
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
      data: {'reason': reason, if (details != null) 'details': details},
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
      data: {'member_ids': memberIds, 'notify_members': notifyMembers},
    );
    return response.data;
  }

  /// Export registrations
  /// Returns download URL for CSV/PDF export
  Future<Map<String, dynamic>> exportRegistrations({
    required int tripId,
    required String format, // 'csv', 'pdf', 'excel'
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
    List<int>? memberIds, // null = all registrants
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
    required List<Map<String, int>>
    positions, // [{'member_id': x, 'position': y}]
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
    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};
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
      '/api/search/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ============================================================================
  // CHOICES - Dropdown Data
  // ============================================================================

  /// Get approval status choices
  /// Returns list of available trip approval statuses for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getApprovalStatusChoices() async {
    final response = await _apiClient.get(
      MainApiEndpoints.choicesApprovalStatus,
    );
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get car brand choices
  /// Returns list of available car brands for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getCarBrandChoices() async {
    final response = await _apiClient.get(MainApiEndpoints.choicesCarBrand);
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get country choices
  /// Returns list of available countries for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getCountryChoices() async {
    final response = await _apiClient.get(MainApiEndpoints.choicesCountries);
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get Emirates choices
  /// Returns list of available Emirates for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getEmiratesChoices() async {
    final response = await _apiClient.get(MainApiEndpoints.choicesEmirates);
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get gender choices
  /// Returns list of available gender options for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getGenderChoices() async {
    final response = await _apiClient.get(MainApiEndpoints.choicesGender);
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get permission matrix action choices
  /// Returns list of available permission actions for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getPermissionMatrixActionChoices() async {
    final response = await _apiClient.get(
      MainApiEndpoints.choicesPermissionMatrixAction,
    );
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get time of day choices
  /// Returns list of available time of day options for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getTimeOfDayChoices() async {
    final response = await _apiClient.get(MainApiEndpoints.choicesTimeOfDay);
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get trip request area choices
  /// Returns list of available areas for trip requests dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getTripRequestAreaChoices() async {
    final response = await _apiClient.get(
      MainApiEndpoints.choicesTripRequestArea,
    );
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get upgrade request status choices
  /// Returns list of available upgrade request statuses for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getUpgradeRequestStatusChoices() async {
    final response = await _apiClient.get(
      MainApiEndpoints.choicesUpgradeRequestStatus,
    );
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  /// Get upgrade request vote choices
  /// Returns list of available upgrade request vote options for dropdowns
  /// API returns paginated response: {count, next, previous, results}
  Future<List<dynamic>> getUpgradeRequestVoteChoices() async {
    final response = await _apiClient.get(
      MainApiEndpoints.choicesUpgradeRequestVote,
    );
    // Extract 'results' array from paginated response
    if (response.data is Map && response.data['results'] is List) {
      return response.data['results'];
    }
    return response.data is List ? response.data : [];
  }

  // ============================================================================
  // HERE MAPS GEOCODING (Backend-driven, Secure)
  // ============================================================================

  /// Get HERE Maps configuration
  ///
  /// Returns backend configuration for HERE Maps reverse geocoding:
  /// - hereMapsEnabled: bool (global enable/disable)
  /// - hereMapsSelectedFields: array (e.g., ["city", "district"])
  /// - hereMapsMaxFields: int (maximum fields to display)
  /// - hereMapsAvailableFields: array (all available field options)
  ///
  /// ✅ PUBLIC ENDPOINT - No authentication required
  /// ✅ Configuration managed via Django Admin panel
  /// ✅ API key secured on backend (not exposed to client)
  ///
  /// Example response:
  /// ```json
  /// {
  ///   "hereMapsEnabled": true,
  ///   "hereMapsSelectedFields": ["city", "district"],
  ///   "hereMapsMaxFields": 2,
  ///   "hereMapsAvailableFields": [
  ///     "Place Name", "District", "City", "County",
  ///     "Country", "Postal Code", "Full Address", "Category"
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>> getHereMapsConfig() async {
    final response = await _apiClient.get(MainApiEndpoints.hereMapsConfig);
    return response.data;
  }

  /// Reverse geocode coordinates to location information
  ///
  /// Converts latitude/longitude to human-readable location string
  /// using backend-secured HERE Maps API integration.
  ///
  /// ✅ AUTHENTICATED ENDPOINT - Requires JWT token
  /// ✅ Backend handles API key, caching, and rate limiting
  /// ✅ Returns pre-formatted string based on admin-selected fields
  ///
  /// Parameters:
  /// - [latitude]: Decimal degrees (-90 to 90)
  /// - [longitude]: Decimal degrees (-180 to 180)
  ///
  /// Returns:
  /// ```json
  /// {
  ///   "success": true,
  ///   "area": "Abu Dhabi, Al Karamah",  // Pre-formatted display string
  ///   "city": "Abu Dhabi",               // Individual fields (if selected)
  ///   "district": "Al Karamah"
  /// }
  /// ```
  ///
  /// Error handling:
  /// - Returns {"success": false, "error": "message"} on failure
  /// - Backend logs errors for monitoring
  ///
  /// Example usage:
  /// ```dart
  /// final result = await mainApiRepository.reverseGeocode(
  ///   latitude: 24.4539,
  ///   longitude: 54.3773,
  /// );
  /// if (result['success'] == true) {
  ///   print(result['area']); // "Abu Dhabi, Al Karamah"
  /// }
  /// ```
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.reverseGeocode,
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.data;
  }
}
