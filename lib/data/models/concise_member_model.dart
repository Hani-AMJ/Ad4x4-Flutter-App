/// Concise Member Model
/// 
/// Simplified member model used in trip requests and other concise contexts
class ConciseMember {
  final int id;
  final String username;

  ConciseMember({
    required this.id,
    required this.username,
  });

  factory ConciseMember.fromJson(Map<String, dynamic> json) {
    return ConciseMember(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}
