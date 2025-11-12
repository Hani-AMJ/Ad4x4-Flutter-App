/// Album model for gallery
class Album {
  final int id;  // Changed to int for API compatibility
  final String title;
  final String description;
  final String? coverImageUrl;  // Nullable
  final int photoCount;
  final DateTime createdAt;
  final String createdBy;
  final int? tripId;  // Link to trip (nullable)
  final String? tripTitle;  // Trip title (nullable)

  Album({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.photoCount,
    required this.createdAt,
    required this.createdBy,
    this.tripId,
    this.tripTitle,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Album',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String? ?? json['coverImageUrl'] as String?,
      photoCount: json['photo_count'] as int? ?? json['photoCount'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? 'Unknown',
      tripId: json['trip_id'] as int? ?? json['tripId'] as int?,
      tripTitle: json['trip_title'] as String? ?? json['tripTitle'] as String?,
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
      if (tripId != null) 'trip_id': tripId,
      if (tripTitle != null) 'trip_title': tripTitle,
    };
  }
  
  /// Get cover image URL with media CDN fallback
  String get coverImage {
    if (coverImageUrl == null || coverImageUrl!.isEmpty) {
      return 'https://picsum.photos/400/300';  // Fallback placeholder
    }
    if (coverImageUrl!.startsWith('http')) {
      return coverImageUrl!;
    }
    return 'https://media.ad4x4.com$coverImageUrl';
  }
}

/// Photo model
class Photo {
  final int id;  // Changed to int for API compatibility
  final String url;
  final String? thumbnailUrl;  // Nullable
  final String caption;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int likes;
  final bool isLiked;
  final int? galleryId;  // Link to gallery

  Photo({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.likes,
    this.isLiked = false,
    this.galleryId,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      caption: json['caption'] as String? ?? '',
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String? ?? 'Unknown',
      uploadedAt: json['uploaded_at'] != null 
          ? DateTime.parse(json['uploaded_at'] as String) 
          : (json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt'] as String) : DateTime.now()),
      likes: json['likes'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      galleryId: json['gallery_id'] as int? ?? json['galleryId'] as int?,
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
      if (galleryId != null) 'gallery_id': galleryId,
    };
  }
  
  /// Get photo URL with media CDN fallback
  String get photoUrl {
    if (url.startsWith('http')) return url;
    return 'https://media.ad4x4.com$url';
  }
  
  /// Get thumbnail URL with fallback
  String get thumbnailImage {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      if (thumbnailUrl!.startsWith('http')) return thumbnailUrl!;
      return 'https://media.ad4x4.com$thumbnailUrl';
    }
    // Fallback to main photo
    return photoUrl;
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
      galleryId: galleryId,
    );
  }
}
