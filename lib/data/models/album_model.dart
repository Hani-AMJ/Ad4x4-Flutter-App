/// Album model for gallery
class Album {
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final int photoCount;
  final DateTime createdAt;
  final String createdBy;

  Album({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.photoCount,
    required this.createdAt,
    required this.createdBy,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      photoCount: json['photo_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'photo_count': photoCount,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

/// Photo model
class Photo {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String caption;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int likes;
  final bool isLiked;

  Photo({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.likes,
    this.isLiked = false,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      caption: json['caption'] as String,
      uploadedBy: json['uploaded_by'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      likes: json['likes'] as int,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'likes': likes,
      'is_liked': isLiked,
    };
  }

  Photo copyWith({
    bool? isLiked,
    int? likes,
  }) {
    return Photo(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
