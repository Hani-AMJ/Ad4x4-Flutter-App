/// Status Code Conversion Helpers
/// 
/// Utilities for converting between backend status codes and Flutter enums.
/// Backend uses single-letter codes (A, P, D) while Flutter uses enum types.

/// Approval Status Enum - Used throughout the app for type-safe status handling
enum ApprovalStatus {
  approved,
  pending,
  declined,
}

/// Parse backend approval status code to enum
/// 
/// Backend codes:
/// - "A" = Approved
/// - "P" = Pending
/// - "D" = Declined
/// 
/// Handles both uppercase and lowercase codes.
/// Defaults to pending for null or unrecognized codes.
ApprovalStatus parseApprovalStatus(String? code) {
  if (code == null) return ApprovalStatus.pending;
  
  switch (code.toUpperCase()) {
    case 'A':
      return ApprovalStatus.approved;
    case 'D':
      return ApprovalStatus.declined;
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

/// Check if a status code represents a declined state
bool isDeclined(String? status) {
  if (status == null) return false;
  final normalized = status.toUpperCase();
  return normalized == 'D' || normalized == 'DECLINED';
}

/// Get display text for approval status
/// 
/// Returns user-friendly text for UI display:
/// - "A" → "Approved"
/// - "P" → "Pending"
/// - "D" → "Declined"
String getApprovalStatusText(String? status) {
  final parsed = parseApprovalStatus(status);
  switch (parsed) {
    case ApprovalStatus.approved:
      return 'Approved';
    case ApprovalStatus.pending:
      return 'Pending';
    case ApprovalStatus.declined:
      return 'Declined';
  }
}

/// Get full description for approval status
/// 
/// Returns detailed description for messages:
/// - "A" → "Approved and visible to members"
/// - "P" → "Pending board approval"
/// - "D" → "Declined by board"
String getApprovalStatusDescription(String? status) {
  final parsed = parseApprovalStatus(status);
  switch (parsed) {
    case ApprovalStatus.approved:
      return 'Approved and visible to members';
    case ApprovalStatus.pending:
      return 'Pending board approval';
    case ApprovalStatus.declined:
      return 'Declined by board';
  }
}
