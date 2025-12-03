import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing account deletion state locally
/// 
/// **Why Local State?**
/// The backend GDPR API (/api/members/request-deletion) does NOT return
/// deletion status in the member profile response. To provide UI indicators
/// (warning banners, deletion timeline), we must track state client-side.
/// 
/// **State Management Strategy:**
/// - When deletion requested successfully → Store locally with timestamp
/// - When deletion cancelled successfully → Clear local state
/// - On app launch → Check local state to show warning banner
/// 
/// **Edge Case Handling:**
/// - If API returns "already_exists" → Set local state (was out of sync)
/// - If API returns "not_found" during cancel → Clear local state (was out of sync)
/// - This keeps frontend synchronized with backend state
/// 
/// **USER-SPECIFIC STATE (CRITICAL):**
/// - Keys are prefixed with user ID to prevent cross-user state leakage
/// - When user logs out, their deletion state is preserved for when they log back in
/// - Different users on the same device have separate deletion states
/// 
/// **Limitations:**
/// - State is device-specific (doesn't sync across devices)
/// - Cleared if app data is cleared or app reinstalled
/// - Acceptable trade-off given backend limitations
class DeletionStateService {
  final SharedPreferences _prefs;
  final String? _userId;
  
  DeletionStateService(this._prefs, {String? userId}) : _userId = userId;
  
  /// Get user-specific key for deletion requested flag
  String get _keyDeletionRequested {
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      return 'deletion_requested_$userId';
    }
    // Fallback to global key (backward compatibility)
    return 'deletion_requested';
  }
  
  /// Get user-specific key for deletion request date
  String get _keyDeletionRequestDate {
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      return 'deletion_request_date_$userId';
    }
    // Fallback to global key (backward compatibility)
    return 'deletion_request_date';
  }
  
  /// Check if account deletion is currently requested
  bool get isDeletionRequested {
    return _prefs.getBool(_keyDeletionRequested) ?? false;
  }
  
  /// Get the date when deletion was requested
  /// Returns null if no deletion request is active
  DateTime? get deletionRequestDate {
    final dateStr = _prefs.getString(_keyDeletionRequestDate);
    if (dateStr == null) return null;
    
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Invalid date format, clear state
      clearDeletionState();
      return null;
    }
  }
  
  /// Get the scheduled deletion date (30 days after request)
  /// Returns null if no deletion request is active
  DateTime? get deletionScheduledDate {
    final requestDate = deletionRequestDate;
    if (requestDate == null) return null;
    
    // Backend typically schedules deletion 30 days from request
    return requestDate.add(const Duration(days: 30));
  }
  
  /// Get days remaining until deletion
  /// Returns null if no deletion request is active
  int? get daysUntilDeletion {
    final scheduledDate = deletionScheduledDate;
    if (scheduledDate == null) return null;
    
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    return difference.inDays;
  }
  
  /// Check if deletion date has passed (account should be deleted)
  /// This is a safeguard - backend handles actual deletion
  bool get isDeletionOverdue {
    final scheduledDate = deletionScheduledDate;
    if (scheduledDate == null) return false;
    
    return DateTime.now().isAfter(scheduledDate);
  }
  
  /// Set deletion requested state
  /// Call this when deletion request API returns success
  Future<void> setDeletionRequested() async {
    await _prefs.setBool(_keyDeletionRequested, true);
    await _prefs.setString(
      _keyDeletionRequestDate,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Clear deletion state
  /// Call this when:
  /// - Deletion cancellation API returns success
  /// - Deletion cancellation API returns "not_found" (sync issue)
  /// - User logs out
  /// - Deletion date has passed (cleanup)
  Future<void> clearDeletionState() async {
    await _prefs.remove(_keyDeletionRequested);
    await _prefs.remove(_keyDeletionRequestDate);
  }
  
  /// Get human-readable deletion status message
  String? get deletionStatusMessage {
    if (!isDeletionRequested) return null;
    
    final daysLeft = daysUntilDeletion;
    if (daysLeft == null) return 'Account scheduled for deletion';
    
    if (daysLeft <= 0) {
      return 'Account deletion is overdue. Please contact support.';
    } else if (daysLeft == 1) {
      return 'Account will be deleted tomorrow';
    } else if (daysLeft <= 7) {
      return 'Account will be deleted in $daysLeft days';
    } else {
      return 'Account will be deleted in $daysLeft days';
    }
  }
  
  /// Get formatted deletion scheduled date
  /// Returns null if no deletion request is active
  String? get formattedDeletionDate {
    final scheduledDate = deletionScheduledDate;
    if (scheduledDate == null) return null;
    
    // Format: "January 15, 2025"
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[scheduledDate.month - 1]} ${scheduledDate.day}, ${scheduledDate.year}';
  }
  
  /// Clear deletion state for ALL users (logout cleanup)
  /// This should be called when user logs out to prevent state leakage
  /// Only clears the current user's state, not all users
  static Future<void> clearAllDeletionStatesOnLogout(SharedPreferences prefs, String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      // Clear user-specific keys
      await prefs.remove('deletion_requested_$userId');
      await prefs.remove('deletion_request_date_$userId');
      // ignore: avoid_print
      print('🧹 [DeletionService] Cleared deletion state for user: $userId');
    }
    // Also clear global keys (backward compatibility)
    await prefs.remove('deletion_requested');
    await prefs.remove('deletion_request_date');
  }
}
