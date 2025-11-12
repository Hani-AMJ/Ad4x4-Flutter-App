/// Comment Moderation Models - Enhanced comment management with moderation features
/// 
/// Extended models for trip comment moderation including approval workflow,
/// flagging system, and moderation history tracking.

import 'trip_model.dart';
import 'trip_comment_model.dart';

/// TripCommentWithModeration - Extended comment model with moderation data
class TripCommentWithModeration {
  final int id;
  final int tripId;
  final BasicMember member;
  final String comment;
  final DateTime created;
  final DateTime? modified;
  
  // Moderation fields
  final bool approved;
  final BasicMember? moderatedBy;
  final DateTime? moderationDate;
  final String? moderationReason;
  final bool flagged;
  final int flagCount;
  final List<CommentFlag> flags;
  final ModerationStatus status;

  TripCommentWithModeration({
    required this.id,
    required this.tripId,
    required this.member,
    required this.comment,
    required this.created,
    this.modified,
    required this.approved,
    this.moderatedBy,
    this.moderationDate,
    this.moderationReason,
    required this.flagged,
    required this.flagCount,
    required this.flags,
    required this.status,
  });

  /// Get author's display name
  String get authorName => member.displayName;

  /// Get author's avatar (first letter of name)
  String get authorAvatar {
    final name = authorName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Check if comment was edited
  bool get isEdited => modified != null && modified != created;

  /// Check if comment is pending approval
  bool get isPending => status == ModerationStatus.pending;

  /// Check if comment was rejected
  bool get isRejected => status == ModerationStatus.rejected;

  /// Check if comment is auto-flagged (high flag count)
  bool get isAutoFlagged => flagCount >= 3;

  /// Convert to basic TripComment
  TripComment toBasicComment() {
    return TripComment(
      id: id,
      tripId: tripId,
      member: member,
      comment: comment,
      created: created,
      modified: modified,
    );
  }

  factory TripCommentWithModeration.fromJson(Map<String, dynamic> json) {
    // Handle member field - can be either integer ID or full object
    BasicMember parsedMember;
    final memberData = json['member'];
    
    if (memberData == null) {
      parsedMember = BasicMember(id: 0, username: 'Unknown');
    } else if (memberData is int) {
      parsedMember = BasicMember(id: memberData, username: 'User $memberData');
    } else if (memberData is Map<String, dynamic>) {
      parsedMember = BasicMember.fromJson(memberData);
    } else {
      parsedMember = BasicMember(id: 0, username: 'Unknown');
    }

    return TripCommentWithModeration(
      id: json['id'] as int? ?? 0,
      tripId: json['trip'] is int ? json['trip'] as int : (json['trip_id'] as int? ?? 0),
      member: parsedMember,
      comment: json['comment'] as String? ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'] as String)
          : DateTime.now(),
      modified: json['modified'] != null 
          ? DateTime.parse(json['modified'] as String)
          : null,
      approved: json['approved'] as bool? ?? true,  // Default approved for existing comments
      moderatedBy: json['moderated_by'] != null
          ? BasicMember.fromJson(json['moderated_by'] as Map<String, dynamic>)
          : null,
      moderationDate: json['moderation_date'] != null
          ? DateTime.parse(json['moderation_date'] as String)
          : null,
      moderationReason: json['moderation_reason'] as String?,
      flagged: json['flagged'] as bool? ?? false,
      flagCount: json['flag_count'] as int? ?? 0,
      flags: (json['flags'] as List<dynamic>? ?? [])
          .map((item) => CommentFlag.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: _parseModerationStatus(json['status'] as String? ?? 'approved'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'member': member.toJson(),
      'comment': comment,
      'created': created.toIso8601String(),
      if (modified != null) 'modified': modified!.toIso8601String(),
      'approved': approved,
      if (moderatedBy != null) 'moderated_by': moderatedBy!.toJson(),
      if (moderationDate != null) 'moderation_date': moderationDate!.toIso8601String(),
      if (moderationReason != null) 'moderation_reason': moderationReason,
      'flagged': flagged,
      'flag_count': flagCount,
      'flags': flags.map((f) => f.toJson()).toList(),
      'status': status.name,
    };
  }

  static ModerationStatus _parseModerationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ModerationStatus.pending;
      case 'rejected':
        return ModerationStatus.rejected;
      case 'approved':
      default:
        return ModerationStatus.approved;
    }
  }
}

/// ModerationStatus - Status of comment moderation
enum ModerationStatus {
  pending,
  approved,
  rejected,
}

/// CommentFlag - User-reported flag on comment
class CommentFlag {
  final int id;
  final BasicMember flaggedBy;
  final DateTime flagDate;
  final FlagReason reason;
  final String? details;

  CommentFlag({
    required this.id,
    required this.flaggedBy,
    required this.flagDate,
    required this.reason,
    this.details,
  });

  factory CommentFlag.fromJson(Map<String, dynamic> json) {
    return CommentFlag(
      id: json['id'] as int,
      flaggedBy: BasicMember.fromJson(json['flagged_by'] as Map<String, dynamic>),
      flagDate: DateTime.parse(json['flag_date'] as String),
      reason: _parseFlagReason(json['reason'] as String? ?? 'other'),
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flagged_by': flaggedBy.toJson(),
      'flag_date': flagDate.toIso8601String(),
      'reason': reason.name,
      if (details != null) 'details': details,
    };
  }

  static FlagReason _parseFlagReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'spam':
        return FlagReason.spam;
      case 'inappropriate':
        return FlagReason.inappropriate;
      case 'harassment':
        return FlagReason.harassment;
      case 'misinformation':
        return FlagReason.misinformation;
      case 'other':
      default:
        return FlagReason.other;
    }
  }
}

/// FlagReason - Reason for flagging a comment
enum FlagReason {
  spam,
  inappropriate,
  harassment,
  misinformation,
  other,
}

/// CommentModerationRequest - Request to moderate a comment
class CommentModerationRequest {
  final int commentId;
  final ModerationAction action;
  final String? reason;
  final String? editedText;  // For edit action

  CommentModerationRequest({
    required this.commentId,
    required this.action,
    this.reason,
    this.editedText,
  });

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'action': action.name,
      if (reason != null) 'reason': reason,
      if (editedText != null) 'edited_text': editedText,
    };
  }
}

/// ModerationAction - Type of moderation action
enum ModerationAction {
  approve,
  reject,
  delete,
  edit,
}

/// UserBanRequest - Request to ban user from commenting
class UserBanRequest {
  final int userId;
  final BanDuration duration;
  final String reason;
  final bool notifyUser;

  UserBanRequest({
    required this.userId,
    required this.duration,
    required this.reason,
    this.notifyUser = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'duration': duration.name,
      'reason': reason,
      'notify_user': notifyUser,
    };
  }
}

/// BanDuration - Duration of comment ban
enum BanDuration {
  oneDay,
  sevenDays,
  thirtyDays,
  permanent,
}

extension BanDurationExtension on BanDuration {
  String get displayName {
    switch (this) {
      case BanDuration.oneDay:
        return '1 Day';
      case BanDuration.sevenDays:
        return '7 Days';
      case BanDuration.thirtyDays:
        return '30 Days';
      case BanDuration.permanent:
        return 'Permanent';
    }
  }

  int? get days {
    switch (this) {
      case BanDuration.oneDay:
        return 1;
      case BanDuration.sevenDays:
        return 7;
      case BanDuration.thirtyDays:
        return 30;
      case BanDuration.permanent:
        return null;  // No expiration
    }
  }
}

/// UserBan - Active ban on user
class UserBan {
  final int id;
  final BasicMember user;
  final BasicMember bannedBy;
  final DateTime banDate;
  final DateTime? expiryDate;
  final String reason;
  final bool active;

  UserBan({
    required this.id,
    required this.user,
    required this.bannedBy,
    required this.banDate,
    this.expiryDate,
    required this.reason,
    required this.active,
  });

  /// Check if ban is permanent
  bool get isPermanent => expiryDate == null;

  /// Check if ban has expired
  bool get hasExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// Get remaining ban duration
  Duration? get remainingDuration {
    if (expiryDate == null) return null;  // Permanent
    if (hasExpired) return Duration.zero;
    return expiryDate!.difference(DateTime.now());
  }

  factory UserBan.fromJson(Map<String, dynamic> json) {
    return UserBan(
      id: json['id'] as int,
      user: BasicMember.fromJson(json['user'] as Map<String, dynamic>),
      bannedBy: BasicMember.fromJson(json['banned_by'] as Map<String, dynamic>),
      banDate: DateTime.parse(json['ban_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      reason: json['reason'] as String,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'banned_by': bannedBy.toJson(),
      'ban_date': banDate.toIso8601String(),
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      'reason': reason,
      'active': active,
    };
  }
}

/// CommentModerationResponse - Paginated response for comment moderation
class CommentModerationResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<TripCommentWithModeration> results;
  final int pendingCount;
  final int flaggedCount;

  CommentModerationResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    required this.pendingCount,
    required this.flaggedCount,
  });

  factory CommentModerationResponse.fromJson(Map<String, dynamic> json) {
    return CommentModerationResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => TripCommentWithModeration.fromJson(item as Map<String, dynamic>))
          .toList(),
      pendingCount: json['pending_count'] as int? ?? 0,
      flaggedCount: json['flagged_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      if (next != null) 'next': next,
      if (previous != null) 'previous': previous,
      'results': results.map((c) => c.toJson()).toList(),
      'pending_count': pendingCount,
      'flagged_count': flaggedCount,
    };
  }
}
