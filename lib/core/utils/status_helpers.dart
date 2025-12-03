/// Status Code Conversion Helpers
/// 
/// Utilities for converting between backend status codes and Flutter enums.
/// Backend uses single-letter codes (P, A, R, D) while Flutter uses enum types.
/// 
/// ⚠️ MIGRATION NOTE: This file is maintained for backward compatibility.
/// New code should use:
/// - ApprovalStatusChoice model (lib/data/models/approval_status_choice_model.dart)
/// - approvalStatusChoicesProvider (lib/features/admin/presentation/providers/approval_status_provider.dart)
/// 
/// These utility functions remain available for legacy code and quick status checks.
library;

/// Approval Status Enum - Used throughout the app for type-safe status handling
/// 
/// ⚠️ IMPORTANT: Backend uses SOFT DELETE (status change, not database removal)
/// - "D" status means DELETED (soft delete) - trips remain in database for audit
enum ApprovalStatus {
  approved,
  pending,
  declined,  // Backend 'D' = Deleted (soft delete), 'R' = Rejected
}

/// Parse backend approval status code to enum
/// 
/// Backend codes:
/// - "A" = Approved (active trips visible to members)
/// - "P" = Pending (awaiting admin approval)
/// - "R" = Rejected (admin denied approval)
/// - "D" = Deleted (soft delete - STAYS IN DATABASE for audit trail)
/// 
/// ⚠️ SOFT DELETE: 'D' status trips remain in database, just hidden from members.
/// Use `approvalStatus: 'A'` filter to show only active trips.
/// 
/// Handles both uppercase and lowercase codes.
/// Defaults to pending for null or unrecognized codes.
ApprovalStatus parseApprovalStatus(String? code) {
  if (code == null) return ApprovalStatus.pending;
  
  switch (code.toUpperCase()) {
    case 'A':
      return ApprovalStatus.approved;
    case 'D':
    case 'R':
      return ApprovalStatus.declined; // Maps both Rejected(R) and Deleted(D) to declined enum
    case 'P':
    default:
      return ApprovalStatus.pending;
  }
}

/// Convert approval status enum to backend code
/// 
/// Returns single-letter codes that the backend expects:
/// - Approved → "A"
/// - Declined → "D"
/// - Pending → "P"
String toBackendCode(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.approved:
      return 'A';
    case ApprovalStatus.declined:
      return 'D';
    case ApprovalStatus.pending:
      return 'P';
  }
}

/// Check if a status code represents an approved state
/// 
/// Handles various formats:
/// - Backend code: "A"
/// - Legacy full word: "approved"
/// - Case insensitive
bool isApproved(String? status) {
  if (status == null) return false;
  final normalized = status.toUpperCase();
  return normalized == 'A' || normalized == 'APPROVED';
}

/// Check if a status code represents a pending state
bool isPending(String? status) {
  if (status == null) return true;
  final normalized = status.toUpperCase();
  return normalized == 'P' || normalized == 'PENDING';
}

/// Check if a status code represents a declined/deleted state
/// 
/// Handles:
/// - Backend 'D' = Deleted (soft delete)
/// - Backend 'R' = Rejected
/// - Legacy 'declined' / 'deleted' strings
bool isDeclined(String? status) {
  if (status == null) return false;
  final normalized = status.toUpperCase();
  return normalized == 'D' || normalized == 'DECLINED' || normalized == 'DELETED';
}

/// Check if a status code represents a rejected state
/// 
/// Specifically checks for 'R' (Rejected) status
bool isRejected(String? status) {
  if (status == null) return false;
  final normalized = status.toUpperCase();
  return normalized == 'R' || normalized == 'REJECTED';
}

/// Get display text for approval status
/// 
/// Returns user-friendly text for UI display:
/// - "A" → "Approved"
/// - "P" → "Pending"
/// - "R" → "Rejected"
/// - "D" → "Deleted" (soft delete - stays in database)
String getApprovalStatusText(String? status) {
  if (status == null) return 'Unknown';
  
  // Check specific backend codes first before parsing to enum
  final normalized = status.toUpperCase();
  if (normalized == 'R' || normalized == 'REJECTED') {
    return 'Rejected';
  }
  if (normalized == 'D' || normalized == 'DELETED') {
    return 'Deleted'; // ✅ FIXED: Show "Deleted" instead of "Declined"
  }
  
  final parsed = parseApprovalStatus(status);
  switch (parsed) {
    case ApprovalStatus.approved:
      return 'Approved';
    case ApprovalStatus.pending:
      return 'Pending';
    case ApprovalStatus.declined:
      return 'Deleted'; // Fallback for 'declined' enum value
  }
}

/// Get full description for approval status
/// 
/// Returns detailed description for messages:
/// - "A" → "Approved and visible to members"
/// - "P" → "Pending board approval"
/// - "R" → "Rejected by board"
/// - "D" → "Deleted (soft delete - kept for audit trail)"
String getApprovalStatusDescription(String? status) {
  if (status == null) return 'Unknown status';
  
  // Check specific backend codes first
  final normalized = status.toUpperCase();
  if (normalized == 'R' || normalized == 'REJECTED') {
    return 'Rejected by board';
  }
  if (normalized == 'D' || normalized == 'DELETED') {
    return 'Deleted (kept in database for audit trail)'; // ✅ FIXED: Accurate description
  }
  
  final parsed = parseApprovalStatus(status);
  switch (parsed) {
    case ApprovalStatus.approved:
      return 'Approved and visible to members';
    case ApprovalStatus.pending:
      return 'Pending board approval';
    case ApprovalStatus.declined:
      return 'Deleted (kept in database for audit trail)';
  }
}
