/// Member Level Statistics Model
/// 
/// Represents aggregated statistics for members grouped by level.
/// Used for displaying member count per level on the members landing screen.
class MemberLevelStats {
  final int levelId;
  final String levelName;
  final String displayName;
  final int numericLevel;
  final int memberCount;
  final bool active;

  MemberLevelStats({
    required this.levelId,
    required this.levelName,
    required this.displayName,
    required this.numericLevel,
    required this.memberCount,
    required this.active,
  });

  factory MemberLevelStats.fromJson(Map<String, dynamic> json) {
    return MemberLevelStats(
      levelId: json['id'] as int,
      levelName: json['name'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String,
      numericLevel: json['numericLevel'] as int,
      memberCount: json['memberCount'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': levelId,
      'name': levelName,
      'displayName': displayName,
      'numericLevel': numericLevel,
      'memberCount': memberCount,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'MemberLevelStats(levelId: $levelId, levelName: $levelName, displayName: $displayName, numericLevel: $numericLevel, memberCount: $memberCount, active: $active)';
  }
}
