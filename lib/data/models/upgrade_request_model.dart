import '../../shared/constants/level_constants.dart';

/// Upgrade Request Models
/// 
/// Models for member upgrade request system

/// Helper function to convert level ID/numeric to display name
String _getLevelNameFromId(dynamic levelValue) {
  if (levelValue == null) return 'Unknown';
  
  // Try to parse as integer ID
  int? levelId;
  if (levelValue is int) {
    levelId = levelValue;
  } else if (levelValue is String) {
    levelId = int.tryParse(levelValue);
  }
  
  // Look up level by ID
  if (levelId != null) {
    final levelData = LevelConstants.getById(levelId);
    if (levelData != null) {
      return levelData.name;
    }
  }
  
  // Fallback to string representation
  return levelValue.toString();
}

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
  final int deferCount;  // ✅ Added defer count support
  final bool currentUserVoted;
  final bool? currentUserVote; // true = approve, false = decline, null = not voted or deferred
  final String? currentUserVoteType; // 'Y' = yes/approve, 'N' = no/decline, 'D' = defer

  VoteSummary({
    required this.approveCount,
    required this.declineCount,
    this.deferCount = 0,  // Default to 0 for backwards compatibility
    required this.currentUserVoted,
    this.currentUserVote,
    this.currentUserVoteType,
  });

  int get totalVotes => approveCount + declineCount + deferCount;
  
  /// Approval percentage (0-100)
  double get approvalPercentage {
    if (totalVotes == 0) return 0;
    return (approveCount / totalVotes) * 100;
  }

  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    return VoteSummary(
      approveCount: json['approve_count'] as int? ?? json['approveCount'] as int? ?? 0,
      declineCount: json['decline_count'] as int? ?? json['declineCount'] as int? ?? 0,
      deferCount: json['defer_count'] as int? ?? json['deferCount'] as int? ?? 0,
      currentUserVoted: json['current_user_voted'] as bool? ?? json['currentUserVoted'] as bool? ?? false,
      currentUserVote: json['current_user_vote'] as bool? ?? json['currentUserVote'] as bool?,
      currentUserVoteType: json['current_user_vote_type'] as String? ?? json['currentUserVoteType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approve_count': approveCount,
      'decline_count': declineCount,
      'defer_count': deferCount,
      'current_user_voted': currentUserVoted,
      'current_user_vote': currentUserVote,
      'current_user_vote_type': currentUserVoteType,
    };
  }
}

/// Upgrade request list item - for displaying in lists
class UpgradeRequestListItem {
  final int id;
  final MemberBasicInfo member;
  final String currentLevel;
  final String requestedLevel;
  /// Status of upgrade request ('pending', 'approved', 'declined')
  /// 
  /// ⚠️ MIGRATION NOTE: For dynamic status management, see:
  /// - UpgradeStatusChoice model (lib/data/models/upgrade_status_choice_model.dart)
  /// - upgradeStatusChoicesProvider (lib/features/admin/presentation/providers/upgrade_status_provider.dart)
  final String status;
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

  /// Check if request is pending (awaiting votes/decision)
  /// ✅ FIXED: Backend uses "New" and "In Progress" (not "Pending")
  bool get isPending {
    final normalized = status.toLowerCase();
    return normalized == 'new' || normalized == 'in progress' || normalized == 'pending';
  }
  
  /// Check if request is approved
  bool get isApproved => status.toLowerCase() == 'approved';
  
  /// Check if request is declined
  bool get isDeclined => status.toLowerCase() == 'declined';

  factory UpgradeRequestListItem.fromJson(Map<String, dynamic> json) {
    // Debug logging to identify problematic fields
    try {
      final id = json['id'] as int;
      
      // ✅ FIXED: Backend uses 'applicant' field, not 'member'
      // The member upgrade history endpoint returns 'applicant' instead of 'member'
      final memberData = json['applicant'] ?? json['member'];
      if (memberData == null) {
        throw Exception('applicant/member field is null');
      }
      if (memberData is! Map<String, dynamic>) {
        throw Exception('applicant/member field is not Map<String, dynamic>, it is: ${memberData.runtimeType}');
      }
      
      final member = MemberBasicInfo.fromJson(memberData);
      
      // ✅ FIXED: Get current level from member's level field
      // Try multiple sources and convert ID to level name using constants
      String currentLevel = 'Unknown';
      
      if (memberData['level'] != null) {
        if (memberData['level'] is Map) {
          // Try name field first
          if (memberData['level']['name'] != null) {
            currentLevel = memberData['level']['name'] as String;
          } else if (memberData['level']['id'] != null) {
            // Convert ID to name using constants
            currentLevel = _getLevelNameFromId(memberData['level']['id']);
          }
        } else {
          // Level is a direct value (int or string)
          currentLevel = _getLevelNameFromId(memberData['level']);
        }
      } else if (json['currentLevel'] != null) {
        if (json['currentLevel'] is Map) {
          currentLevel = json['currentLevel']['name'] as String? ?? _getLevelNameFromId(json['currentLevel']['id']);
        } else {
          currentLevel = _getLevelNameFromId(json['currentLevel']);
        }
      } else if (json['current_level'] != null) {
        if (json['current_level'] is Map) {
          currentLevel = json['current_level']['name'] as String? ?? _getLevelNameFromId(json['current_level']['id']);
        } else {
          currentLevel = _getLevelNameFromId(json['current_level']);
        }
      }
      
      // If still unknown, try to infer from targetLevel (user is upgrading from one level below)
      if (currentLevel == 'Unknown' && json['targetLevel'] != null) {
        int? targetLevelId;
        if (json['targetLevel'] is int) {
          targetLevelId = json['targetLevel'] as int;
        } else if (json['targetLevel'] is Map) {
          targetLevelId = json['targetLevel']['id'] as int?;
        }
        
        // Get current level (one below target)
        if (targetLevelId != null && targetLevelId > 1) {
          currentLevel = _getLevelNameFromId(targetLevelId - 1);
        }
      }
      
      // ✅ FIXED: Get requested level and convert ID to name
      String requestedLevel = 'Unknown';
      
      if (json['targetLevel'] != null) {
        if (json['targetLevel'] is Map) {
          final targetLevelMap = json['targetLevel'] as Map<String, dynamic>;
          // Try name field first
          if (targetLevelMap['name'] != null) {
            requestedLevel = targetLevelMap['name'] as String;
          } else if (targetLevelMap['id'] != null) {
            // Convert ID to name using constants
            requestedLevel = _getLevelNameFromId(targetLevelMap['id']);
          }
        } else {
          // targetLevel is int or string - convert to name
          requestedLevel = _getLevelNameFromId(json['targetLevel']);
        }
      } else if (json['target_level'] != null) {
        if (json['target_level'] is Map) {
          requestedLevel = json['target_level']['name'] as String? ?? _getLevelNameFromId(json['target_level']['id']);
        } else {
          requestedLevel = _getLevelNameFromId(json['target_level']);
        }
      } else if (json['requested_level'] != null) {
        requestedLevel = json['requested_level'] as String;
      } else if (json['requestedLevel'] != null) {
        requestedLevel = json['requestedLevel'] as String;
      }
      
      final status = json['status'] as String? ?? 'pending';
      
      // ✅ FIXED: Handle 'created' field from member endpoint
      final submittedAtStr = json['created'] as String? ?? json['submitted_at'] as String? ?? json['submittedAt'] as String? ?? DateTime.now().toIso8601String();
      final submittedAt = DateTime.parse(submittedAtStr);
      
      final commentCount = json['comment_count'] as int? ?? json['commentCount'] as int? ?? 0;
      
      // ✅ FIXED: Handle actual API response format (yesVoters, noVoters, deferVoters)
      VoteSummary voteSummary;
      
      // Try nested vote_summary object first
      final voteSummaryData = json['vote_summary'] ?? json['voteSummary'];
      
      if (voteSummaryData != null && voteSummaryData is Map<String, dynamic>) {
        voteSummary = VoteSummary.fromJson(voteSummaryData);
      } else {
        // Parse from API's direct fields: yesVoters, noVoters, deferVoters
        final yesVoters = json['yesVoters'] as int? ?? 0;
        final noVoters = json['noVoters'] as int? ?? 0;
        final deferVoters = json['deferVoters'] as int? ?? 0;
        
        voteSummary = VoteSummary(
          approveCount: yesVoters,
          declineCount: noVoters,
          deferCount: deferVoters,  // ✅ Include defer count
          currentUserVoted: false,
          currentUserVote: null,
        );
      }
      
      return UpgradeRequestListItem(
        id: id,
        member: member,
        currentLevel: currentLevel,
        requestedLevel: requestedLevel,
        status: status,
        submittedAt: submittedAt,
        commentCount: commentCount,
        voteSummary: voteSummary,
      );
    } catch (e) {
      // Re-throw with more context
      throw Exception('Failed to parse UpgradeRequestListItem: $e\nJSON: $json');
    }
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
    // Handle author field - can be either nested object or just an ID
    MemberBasicInfo author;
    if (json['author'] is Map<String, dynamic>) {
      // Author is nested object
      author = MemberBasicInfo.fromJson(json['author'] as Map<String, dynamic>);
    } else if (json['author'] is int) {
      // ✅ FIXED: Author is just an ID - display as "Member #ID"
      final authorId = json['author'] as int;
      author = MemberBasicInfo(
        id: authorId,
        username: 'Member #$authorId',  // More user-friendly than "user_10613"
        firstName: '',
        lastName: '',
      );
    } else {
      // Fallback - create placeholder author
      author = MemberBasicInfo(
        id: 0,
        username: 'Unknown User',
        firstName: '',
        lastName: '',
      );
    }
    
    return UpgradeRequestComment(
      id: json['id'] as int,
      author: author,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['created'] as String? ?? json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
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
  final String? supportingDocument;  // ✅ Added attachment support

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
    this.supportingDocument,  // ✅ Added attachment support
  });

  /// Check if request is pending (awaiting votes/decision)
  /// ✅ FIXED: Backend uses "New" and "In Progress" (not "Pending")
  bool get isPending {
    final normalized = status.toLowerCase();
    return normalized == 'new' || normalized == 'in progress' || normalized == 'pending';
  }
  
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isDeclined => status.toLowerCase() == 'declined';

  factory UpgradeRequestDetail.fromJson(Map<String, dynamic> json) {
    // ✅ FIXED: Handle both 'applicant' (member endpoint) and 'member' (admin endpoint)
    final memberData = json['applicant'] ?? json['member'];
    if (memberData == null || memberData is! Map<String, dynamic>) {
      throw Exception('applicant/member field is missing or invalid');
    }
    
    // ✅ FIXED: Get current level from member's level field
    // Try multiple sources and convert ID to level name using constants
    String currentLevel = 'Unknown';
    
    if (memberData['level'] != null) {
      if (memberData['level'] is Map) {
        // Try name field first
        if (memberData['level']['name'] != null) {
          currentLevel = memberData['level']['name'] as String;
        } else if (memberData['level']['id'] != null) {
          // Convert ID to name using constants
          currentLevel = _getLevelNameFromId(memberData['level']['id']);
        }
      } else {
        // Level is a direct value (int or string)
        currentLevel = _getLevelNameFromId(memberData['level']);
      }
    } else if (json['currentLevel'] != null) {
      if (json['currentLevel'] is Map) {
        currentLevel = json['currentLevel']['name'] as String? ?? _getLevelNameFromId(json['currentLevel']['id']);
      } else {
        currentLevel = _getLevelNameFromId(json['currentLevel']);
      }
    } else if (json['current_level'] != null) {
      if (json['current_level'] is Map) {
        currentLevel = json['current_level']['name'] as String? ?? _getLevelNameFromId(json['current_level']['id']);
      } else {
        currentLevel = _getLevelNameFromId(json['current_level']);
      }
    }
    
    // If still unknown, try to infer from targetLevel (user is upgrading from one level below)
    if (currentLevel == 'Unknown' && json['targetLevel'] != null) {
      int? targetLevelId;
      if (json['targetLevel'] is int) {
        targetLevelId = json['targetLevel'] as int;
      } else if (json['targetLevel'] is Map) {
        targetLevelId = json['targetLevel']['id'] as int?;
      }
      
      // Get current level (one below target)
      if (targetLevelId != null && targetLevelId > 1) {
        currentLevel = _getLevelNameFromId(targetLevelId - 1);
      }
    }
    
    // ✅ FIXED: Get requested level and convert ID to name
    String requestedLevel = 'Unknown';
    
    if (json['targetLevel'] != null) {
      if (json['targetLevel'] is Map) {
        final targetLevelMap = json['targetLevel'] as Map<String, dynamic>;
        // Try name field first
        if (targetLevelMap['name'] != null) {
          requestedLevel = targetLevelMap['name'] as String;
        } else if (targetLevelMap['id'] != null) {
          // Convert ID to name using constants
          requestedLevel = _getLevelNameFromId(targetLevelMap['id']);
        }
      } else {
        // targetLevel is int or string - convert to name
        requestedLevel = _getLevelNameFromId(json['targetLevel']);
      }
    } else if (json['target_level'] != null) {
      if (json['target_level'] is Map) {
        requestedLevel = json['target_level']['name'] as String? ?? _getLevelNameFromId(json['target_level']['id']);
      } else {
        requestedLevel = _getLevelNameFromId(json['target_level']);
      }
    } else if (json['requested_level'] != null) {
      requestedLevel = json['requested_level'] as String;
    } else if (json['requestedLevel'] != null) {
      requestedLevel = json['requestedLevel'] as String;
    }
    
    // ✅ FIXED: Handle 'applicantReason' field name
    final reason = json['applicantReason'] as String? ?? json['reason'] as String? ?? '';
    
    // ✅ FIXED: Handle 'created' field from member endpoint
    final submittedAtStr = json['created'] as String? ?? json['submitted_at'] as String? ?? json['submittedAt'] as String? ?? DateTime.now().toIso8601String();
    
    // ✅ FIXED: vote_summary might not exist, create default
    final voteSummaryData = json['vote_summary'] ?? json['voteSummary'];
    VoteSummary voteSummary;
    if (voteSummaryData != null && voteSummaryData is Map<String, dynamic>) {
      voteSummary = VoteSummary.fromJson(voteSummaryData);
    } else {
      // Parse from API's direct fields if vote_summary object doesn't exist
      final yesVoters = json['yesVoters'] as int? ?? 0;
      final noVoters = json['noVoters'] as int? ?? 0;
      final deferVoters = json['deferVoters'] as int? ?? 0;
      
      voteSummary = VoteSummary(
        approveCount: yesVoters,
        declineCount: noVoters,
        deferCount: deferVoters,  // ✅ Include defer count
        currentUserVoted: false,
        currentUserVote: null,
      );
    }
    
    return UpgradeRequestDetail(
      id: json['id'] as int,
      member: MemberDetailInfo.fromJson(memberData),
      currentLevel: currentLevel,
      requestedLevel: requestedLevel,
      reason: reason,
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(submittedAtStr),
      votes: (json['votes'] as List<dynamic>?)?.map((v) => Vote.fromJson(v as Map<String, dynamic>)).toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)?.map((c) => UpgradeRequestComment.fromJson(c as Map<String, dynamic>)).toList() ?? [],
      approvalInfo: json['approval_info'] != null 
          ? ApprovalInfo.fromJson(json['approval_info'] as Map<String, dynamic>)
          : (json['approvalInfo'] != null ? ApprovalInfo.fromJson(json['approvalInfo'] as Map<String, dynamic>) : null),
      voteSummary: voteSummary,
      supportingDocument: json['supporting_document'] as String? ?? json['supportingDocument'] as String?,  // ✅ Added attachment support
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
      'supporting_document': supportingDocument,  // ✅ Added attachment support
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
