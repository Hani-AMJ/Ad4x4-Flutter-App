

/// Album model for gallery
class Album {
  final String id;  // UUID string from Gallery API
  final String title;
  final String description;
  final String? coverImageUrl;  // Nullable
  final int photoCount;
  final DateTime createdAt;
  final String createdBy;
  final int? createdById;  // User ID
  final int? tripId;  // Link to trip (nullable)
  final String? tripTitle;  // Trip title (nullable)
  final List<String> samplePhotos;  // Sample photo filenames from Gallery API

  Album({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.photoCount,
    required this.createdAt,
    required this.createdBy,
    this.createdById,
    this.tripId,
    this.tripTitle,
    this.samplePhotos = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    // Parse sample_photos array
    List<String> samplePhotos = [];
    if (json['sample_photos'] != null && json['sample_photos'] is List) {
      samplePhotos = (json['sample_photos'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return Album(
      // Gallery API uses UUID strings
      id: json['id']?.toString() ?? '',
      // Gallery API uses 'name' field instead of 'title'
      title: json['name'] as String? ?? json['title'] as String? ?? 'Untitled Album',
      description: json['description'] as String? ?? '',
      // Gallery API provides sample_photos array, use first as cover
      coverImageUrl: json['cover_image_url'] as String? ?? 
                     json['coverImageUrl'] as String? ??
                     (samplePhotos.isNotEmpty ? samplePhotos.first : null),
      photoCount: json['photo_count'] as int? ?? json['photoCount'] as int? ?? 0,
      // Gallery API format: "2025-11-09 10:22:41" (no timezone)
      createdAt: json['created_at'] != null 
          ? _parseDateTime(json['created_at'] as String)
          : (json['createdAt'] != null ? _parseDateTime(json['createdAt'] as String) : DateTime.now()),
      // Gallery API provides created_by_username
      createdBy: json['created_by_username'] as String? ?? 
                 json['created_by'] as String? ?? 
                 json['createdBy'] as String? ?? 
                 'Unknown',
      createdById: json['created_by'] as int?,
      tripId: json['trip_id'] as int? ?? json['tripId'] as int? ?? json['source_trip_id'] as int?,
      tripTitle: json['trip_title'] as String? ?? json['tripTitle'] as String?,
      samplePhotos: samplePhotos,
    );
  }

  /// Parse datetime from Gallery API format ("2025-11-09 10:22:41")
  static DateTime _parseDateTime(String dateStr) {
    try {
      // Try ISO format first
      return DateTime.parse(dateStr);
    } catch (e) {
      // Fallback: Try Gallery API format (yyyy-MM-dd HH:mm:ss)
      try {
        // Add 'T' to make it ISO compatible
        final isoStr = dateStr.replaceFirst(' ', 'T');
        return DateTime.parse(isoStr);
      } catch (e2) {
        return DateTime.now();
      }
    }
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
  
  Album copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    int? photoCount,
    DateTime? createdAt,
    String? createdBy,
    int? createdById,
    int? tripId,
    String? tripTitle,
    List<String>? samplePhotos,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      tripId: tripId ?? this.tripId,
      tripTitle: tripTitle ?? this.tripTitle,
      samplePhotos: samplePhotos ?? this.samplePhotos,
    );
  }
  
  /// Get cover image URL (uses card thumbnail for better performance)
  String get coverImage {
    // Use card thumbnail (1200x675) for album covers
    if (samplePhotos.isNotEmpty) {
      final filename = samplePhotos.first;
      return 'https://media.ad4x4.com/thumbs/card/$filename';
    }
    return '';
  }
  
  /// Get grid thumbnail URL (400x400) for gallery list
  String get gridThumbnail {
    if (samplePhotos.isNotEmpty) {
      final filename = samplePhotos.first;
      return 'https://media.ad4x4.com/thumbs/grid/$filename';
    }
    return '';
  }
  
  /// Get photo ID from sample photos (extract from filename)
  String? get samplePhotoId {
    if (samplePhotos.isNotEmpty) {
      // Gallery API filenames are in format: {uuid}.jpg
      // Extract UUID from filename (remove extension)
      final filename = samplePhotos.first;
      if (filename.contains('.')) {
        return filename.substring(0, filename.lastIndexOf('.'));
      }
      return filename; // Return as-is if no extension
    }
    return null;
  }
}

/// Photo model
class Photo {
  final String id;  // UUID string from Gallery API
  final String url;
  final String? thumbnailUrl;  // Nullable
  final String caption;
  final String uploadedBy;
  final DateTime uploadedAt;
  final int likes;
  final bool isLiked;
  final String? galleryId;  // Link to gallery (UUID string)
  final String? filename;  // Photo filename
  final int? width;
  final int? height;

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
    this.filename,
    this.width,
    this.height,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    // Gallery API uses UUID strings for IDs
    final photoId = json['id']?.toString() ?? '';
    final galleryId = json['gallery_id']?.toString();
    final filename = json['filename'] as String?;
    
    return Photo(
      id: photoId,
      // Construct URL from gallery_id and filename
      url: filename != null && galleryId != null
          ? 'https://media.ad4x4.com/uploads/galleries/$galleryId/$filename'
          : json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      caption: json['description'] as String? ?? json['caption'] as String? ?? '',
      uploadedBy: json['uploaded_by_username'] as String? ?? 
                  json['uploaded_by'] as String? ?? 
                  json['uploadedBy'] as String? ?? 
                  'Unknown',
      uploadedAt: json['created_at'] != null 
          ? _parseDateTime(json['created_at'] as String)
          : (json['uploaded_at'] != null 
              ? _parseDateTime(json['uploaded_at'] as String)
              : (json['uploadedAt'] != null 
                  ? DateTime.parse(json['uploadedAt'] as String) 
                  : DateTime.now())),
      likes: json['likes'] as int? ?? json['download_count'] as int? ?? 0,
      isLiked: (json['is_favorite'] as int?) == 1 || (json['is_liked'] as bool?) == true || (json['isLiked'] as bool?) == true,
      galleryId: galleryId,
      filename: filename,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// Parse datetime from Gallery API format
  static DateTime _parseDateTime(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        final isoStr = dateStr.replaceFirst(' ', 'T');
        return DateTime.parse(isoStr);
      } catch (e2) {
        return DateTime.now();
      }
    }
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
  
  /// Get full resolution photo URL using download endpoint
  String get photoUrl {
    // Use download endpoint for full resolution images
    return 'https://media.ad4x4.com/api/photos/$id/download';
  }
  
  /// Get grid thumbnail URL (400x400) - Fast loading for gallery grids
  String get gridThumbnail {
    if (filename != null) {
      return 'https://media.ad4x4.com/thumbs/grid/$filename';
    }
    return photoUrl; // Fallback to full image
  }
  
  /// Get card thumbnail URL (1200x675) - High quality for featured images
  String get cardThumbnail {
    if (filename != null) {
      return 'https://media.ad4x4.com/thumbs/card/$filename';
    }
    return photoUrl; // Fallback to full image
  }
  
  /// Get list thumbnail URL (120x120) - Tiny for list views
  String get listThumbnail {
    if (filename != null) {
      return 'https://media.ad4x4.com/thumbs/list/$filename';
    }
    return photoUrl; // Fallback to full image
  }
  
  /// Legacy getter for backward compatibility (uses grid thumbnail)
  String get thumbnailImage => gridThumbnail;

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
      filename: filename,
      width: width,
      height: height,
    );
  }
}
