/// Upgrade Request Models
/// 
/// Models for member upgrade request system

/// Basic member info for display in lists
class MemberBasicInfo {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profileImage;

  MemberBasicInfo({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profileImage,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : username;
  }

  factory MemberBasicInfo.fromJson(Map<String, dynamic> json) {
    return MemberBasicInfo(
      id: json['id'] as int,
      username: json['username'] as String? ?? 'user_${json['id']}',
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      profileImage: json['profile_image'] as String? ?? json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
    };
  }
}

/// Vote summary for quick display
class VoteSummary {
  final int approveCount;
  final int declineCount;
  final bool currentUserVoted;
  final bool? currentUserVote; // true = approve, false = decline, null = not voted

  VoteSummary({
    required this.approveCount,
    required this.declineCount,
    required this.currentUserVoted,
    this.currentUserVote,
  });

  int get totalVotes => approveCount + declineCount;
  
  /// Approval percentage (0-100)
  double get approvalPercentage {
    if (totalVotes == 0) return 0;
    return (approveCount / totalVotes) * 100;
  }

  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    return VoteSummary(
      approveCount: json['approve_count'] as int? ?? json['approveCount'] as int? ?? 0,
      declineCount: json['decline_count'] as int? ?? json['declineCount'] as int? ?? 0,
      currentUserVoted: json['current_user_voted'] as bool? ?? json['currentUserVoted'] as bool? ?? false,
      currentUserVote: json['current_user_vote'] as bool? ?? json['currentUserVote'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approve_count': approveCount,
      'decline_count': declineCount,
      'current_user_voted': currentUserVoted,
      'current_user_vote': currentUserVote,
    };
  }
}

/// Upgrade request list item - for displaying in lists
class UpgradeRequestListItem {
  final int id;
  final MemberBasicInfo member;
  final String currentLevel;
  final String requestedLevel;
  final String status; // 'pending', 'approved', 'declined'
  final DateTime submittedAt;
  final int commentCount;
  final VoteSummary voteSummary;

  UpgradeRequestListItem({
    required this.id,
    required this.member,
    required this.currentLevel,
    required this.requestedLevel,
    required this.status,
    required this.submittedAt,
    required this.commentCount,
    required this.voteSummary,
  });

  /// Check if request is pending
  bool get isPending => status.toLowerCase() == 'pending';
  
  /// Check if request is approved
  bool get isApproved => status.toLowerCase() == 'approved';
  
  /// Check if request is declined
  bool get isDeclined => status.toLowerCase() == 'declined';

  factory UpgradeRequestListItem.fromJson(Map<String, dynamic> json) {
    return UpgradeRequestListItem(
      id: json['id'] as int,
      member: MemberBasicInfo.fromJson(json['member'] as Map<String, dynamic>),
      currentLevel: json['current_level'] as String? ?? json['currentLevel'] as String? ?? 'Unknown',
      requestedLevel: json['requested_level'] as String? ?? json['requestedLevel'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] as String? ?? json['submittedAt'] as String? ?? DateTime.now().toIso8601String()),
      commentCount: json['comment_count'] as int? ?? json['commentCount'] as int? ?? 0,
      voteSummary: VoteSummary.fromJson(json['vote_summary'] as Map<String, dynamic>? ?? json['voteSummary'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'current_level': currentLevel,
      'requested_level': requestedLevel,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'comment_count': commentCount,
      'vote_summary': voteSummary.toJson(),
    };
  }
}

/// Individual vote on an upgrade request
class Vote {
  final int id;
  final MemberBasicInfo voter;
  final bool approve; // true = approve, false = decline
  final DateTime votedAt;
  final String? comment; // Optional vote comment

  Vote({
    required this.id,
    required this.voter,
    required this.approve,
    required this.votedAt,
    this.comment,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] as int,
      voter: MemberBasicInfo.fromJson(json['voter'] as Map<String, dynamic>),
      approve: json['approve'] as bool? ?? false,
      votedAt: DateTime.parse(json['voted_at'] as String? ?? json['votedAt'] as String? ?? DateTime.now().toIso8601String()),
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voter': voter.toJson(),
      'approve': approve,
      'voted_at': votedAt.toIso8601String(),
      'comment': comment,
    };
  }
}

/// Comment on an upgrade request
class UpgradeRequestComment {
  final int id;
  final MemberBasicInfo author;
  final String text;
  final DateTime createdAt;
  final bool canDelete; // Based on permission check

  UpgradeRequestComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.canDelete,
  });

  factory UpgradeRequestComment.fromJson(Map<String, dynamic> json, {bool canDelete = false}) {
    return UpgradeRequestComment(
      id: json['id'] as int,
      author: MemberBasicInfo.fromJson(json['author'] as Map<String, dynamic>),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      canDelete: json['can_delete'] as bool? ?? json['canDelete'] as bool? ?? canDelete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'can_delete': canDelete,
    };
  }
}

/// Approval/decline information
class ApprovalInfo {
  final MemberBasicInfo decidedBy;
  final DateTime decidedAt;
  final String decision; // 'approved' or 'declined'
  final String? reason; // Optional reason for decision

  ApprovalInfo({
    required this.decidedBy,
    required this.decidedAt,
    required this.decision,
    this.reason,
  });

  bool get isApproved => decision.toLowerCase() == 'approved';
  bool get isDeclined => decision.toLowerCase() == 'declined';

  factory ApprovalInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalInfo(
      decidedBy: MemberBasicInfo.fromJson(json['decided_by'] as Map<String, dynamic>),
      decidedAt: DateTime.parse(json['decided_at'] as String? ?? json['decidedAt'] as String? ?? DateTime.now().toIso8601String()),
      decision: json['decision'] as String? ?? 'pending',
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'decided_by': decidedBy.toJson(),
      'decided_at': decidedAt.toIso8601String(),
      'decision': decision,
      'reason': reason,
    };
  }
}

/// Detailed member info for upgrade request details
class MemberDetailInfo extends MemberBasicInfo {
  final String? email;
  final String? phoneNumber;
  final int tripCount;
  final DateTime? dateJoined;

  MemberDetailInfo({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    super.profileImage,
    this.email,
    this.phoneNumber,
    this.tripCount = 0,
    this.dateJoined,
  });

  factory MemberDetailInfo.fromJson(Map<String, dynamic> json) {
    return MemberDetailInfo(
      id: json['id'] as int,
      username: json['username'] as String? ?? 'user_${json['id']}',
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      profileImage: json['profile_image'] as String? ?? json['profileImage'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      tripCount: json['trip_count'] as int? ?? json['tripCount'] as int? ?? 0,
      dateJoined: json['date_joined'] != null 
          ? DateTime.parse(json['date_joined'] as String)
          : (json['dateJoined'] != null ? DateTime.parse(json['dateJoined'] as String) : null),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'email': email,
      'phone_number': phoneNumber,
      'trip_count': tripCount,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }
}

/// Complete upgrade request details
class UpgradeRequestDetail {
  final int id;
  final MemberDetailInfo member;
  final String currentLevel;
  final String requestedLevel;
  final String reason;
  final String status;
  final DateTime submittedAt;
  final List<Vote> votes;
  final List<UpgradeRequestComment> comments;
  final ApprovalInfo? approvalInfo;
  final VoteSummary voteSummary;

  UpgradeRequestDetail({
    required this.id,
    required this.member,
    required this.currentLevel,
    required this.requestedLevel,
    required this.reason,
    required this.status,
    required this.submittedAt,
    required this.votes,
    required this.comments,
    this.approvalInfo,
    required this.voteSummary,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isDeclined => status.toLowerCase() == 'declined';

  factory UpgradeRequestDetail.fromJson(Map<String, dynamic> json) {
    return UpgradeRequestDetail(
      id: json['id'] as int,
      member: MemberDetailInfo.fromJson(json['member'] as Map<String, dynamic>),
      currentLevel: json['current_level'] as String? ?? json['currentLevel'] as String? ?? 'Unknown',
      requestedLevel: json['requested_level'] as String? ?? json['requestedLevel'] as String? ?? 'Unknown',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] as String? ?? json['submittedAt'] as String? ?? DateTime.now().toIso8601String()),
      votes: (json['votes'] as List<dynamic>?)?.map((v) => Vote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)?.map((c) => UpgradeRequestComment.fromJson(c as Map<String, dynamic>)).toList() ?? [],
      approvalInfo: json['approval_info'] != null 
          ? ApprovalInfo.fromJson(json['approval_info'] as Map<String, dynamic>)
          : (json['approvalInfo'] != null ? ApprovalInfo.fromJson(json['approvalInfo'] as Map<String, dynamic>) : null),
      voteSummary: VoteSummary.fromJson(json['vote_summary'] as Map<String, dynamic>? ?? json['voteSummary'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'current_level': currentLevel,
      'requested_level': requestedLevel,
      'reason': reason,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'votes': votes.map((v) => v.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'approval_info': approvalInfo?.toJson(),
      'vote_summary': voteSummary.toJson(),
    };
  }
}

/// Paginated response wrapper
class UpgradeRequestsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<UpgradeRequestListItem> results;

  UpgradeRequestsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;

  factory UpgradeRequestsResponse.fromJson(Map<String, dynamic> json) {
    return UpgradeRequestsResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => UpgradeRequestListItem.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((r) => r.toJson()).toList(),
    };
  }
}
