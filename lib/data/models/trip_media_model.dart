/// Trip Media Models - Photo and video management for trips
/// 
/// Models for handling trip photos, videos, galleries, and upload requests.
/// Supports admin moderation workflow with approval status.
library;

import 'trip_model.dart';

/// TripMedia - Individual photo or video uploaded to a trip
class TripMedia {
  final int id;
  final int tripId;
  final BasicMember uploadedBy;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime uploadDate;
  final DateTime? modifiedDate;
  final bool approved;
  final BasicMember? moderatedBy;
  final DateTime? moderationDate;
  final String? moderationReason;
  final MediaType mediaType;
  final int? fileSize;  // In bytes
  final MediaDimensions? dimensions;

  TripMedia({
    required this.id,
    required this.tripId,
    required this.uploadedBy,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.uploadDate,
    this.modifiedDate,
    required this.approved,
    this.moderatedBy,
    this.moderationDate,
    this.moderationReason,
    required this.mediaType,
    this.fileSize,
    this.dimensions,
  });

  /// Check if media is pending approval
  bool get isPending => !approved && moderatedBy == null;

  /// Check if media was rejected
  bool get isRejected => !approved && moderatedBy != null;

  /// Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    
    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  factory TripMedia.fromJson(Map<String, dynamic> json) {
    return TripMedia(
      id: json['id'] as int,
      tripId: json['trip'] is int ? json['trip'] as int : (json['trip_id'] as int? ?? 0),
      uploadedBy: BasicMember.fromJson(json['uploaded_by'] as Map<String, dynamic>),
      mediaUrl: json['media_url'] as String? ?? json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnail'] as String?,
      caption: json['caption'] as String?,
      uploadDate: DateTime.parse(json['upload_date'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      modifiedDate: json['modified_date'] != null ? DateTime.parse(json['modified_date'] as String) : null,
      approved: json['approved'] as bool? ?? false,
      moderatedBy: json['moderated_by'] != null 
          ? BasicMember.fromJson(json['moderated_by'] as Map<String, dynamic>)
          : null,
      moderationDate: json['moderation_date'] != null 
          ? DateTime.parse(json['moderation_date'] as String)
          : null,
      moderationReason: json['moderation_reason'] as String?,
      mediaType: _parseMediaType(json['media_type'] as String? ?? 'photo'),
      fileSize: json['file_size'] as int?,
      dimensions: json['dimensions'] != null
          ? MediaDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : (json['width'] != null && json['height'] != null
              ? MediaDimensions(width: json['width'] as int, height: json['height'] as int)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'uploaded_by': uploadedBy.toJson(),
      'media_url': mediaUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (caption != null) 'caption': caption,
      'upload_date': uploadDate.toIso8601String(),
      if (modifiedDate != null) 'modified_date': modifiedDate!.toIso8601String(),
      'approved': approved,
      if (moderatedBy != null) 'moderated_by': moderatedBy!.toJson(),
      if (moderationDate != null) 'moderation_date': moderationDate!.toIso8601String(),
      if (moderationReason != null) 'moderation_reason': moderationReason,
      'media_type': mediaType.name,
      if (fileSize != null) 'file_size': fileSize,
      if (dimensions != null) 'dimensions': dimensions!.toJson(),
    };
  }

  static MediaType _parseMediaType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'photo':
      case 'image':
      default:
        return MediaType.photo;
    }
  }
}

/// MediaType - Type of media (photo or video)
enum MediaType {
  photo,
  video,
}

/// MediaDimensions - Width and height of media
class MediaDimensions {
  final int width;
  final int height;

  MediaDimensions({
    required this.width,
    required this.height,
  });

  /// Get aspect ratio
  double get aspectRatio => width / height;

  /// Check if portrait orientation
  bool get isPortrait => height > width;

  /// Check if landscape orientation
  bool get isLandscape => width > height;

  /// Check if square
  bool get isSquare => width == height;

  factory MediaDimensions.fromJson(Map<String, dynamic> json) {
    return MediaDimensions(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }
}

/// TripMediaGallery - Collection of media for a trip
class TripMediaGallery {
  final int tripId;
  final int totalPhotos;
  final int totalVideos;
  final int pendingApproval;
  final TripMedia? coverPhoto;
  final List<TripMedia> recentUploads;
  final List<BasicMember> contributors;

  TripMediaGallery({
    required this.tripId,
    required this.totalPhotos,
    required this.totalVideos,
    required this.pendingApproval,
    this.coverPhoto,
    required this.recentUploads,
    required this.contributors,
  });

  /// Get total media count
  int get totalMedia => totalPhotos + totalVideos;

  /// Check if gallery is empty
  bool get isEmpty => totalMedia == 0;

  /// Check if there are pending items
  bool get hasPending => pendingApproval > 0;

  factory TripMediaGallery.fromJson(Map<String, dynamic> json) {
    return TripMediaGallery(
      tripId: json['trip_id'] as int? ?? json['trip'] as int,
      totalPhotos: json['total_photos'] as int? ?? 0,
      totalVideos: json['total_videos'] as int? ?? 0,
      pendingApproval: json['pending_approval'] as int? ?? 0,
      coverPhoto: json['cover_photo'] != null
          ? TripMedia.fromJson(json['cover_photo'] as Map<String, dynamic>)
          : null,
      recentUploads: (json['recent_uploads'] as List<dynamic>? ?? [])
          .map((item) => TripMedia.fromJson(item as Map<String, dynamic>))
          .toList(),
      contributors: (json['contributors'] as List<dynamic>? ?? [])
          .map((item) => BasicMember.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'total_photos': totalPhotos,
      'total_videos': totalVideos,
      'pending_approval': pendingApproval,
      if (coverPhoto != null) 'cover_photo': coverPhoto!.toJson(),
      'recent_uploads': recentUploads.map((m) => m.toJson()).toList(),
      'contributors': contributors.map((m) => m.toJson()).toList(),
    };
  }
}

/// MediaUploadRequest - Request data for uploading media
class MediaUploadRequest {
  final int tripId;
  final String filePath;  // Local file path
  final String? caption;
  final MediaType mediaType;

  MediaUploadRequest({
    required this.tripId,
    required this.filePath,
    this.caption,
    required this.mediaType,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip': tripId,
      if (caption != null && caption!.isNotEmpty) 'caption': caption,
      'media_type': mediaType.name,
    };
  }
}

/// MediaUploadProgress - Upload progress tracking
class MediaUploadProgress {
  final String uploadId;
  final int tripId;
  final double progress;  // 0.0 to 1.0
  final UploadStatus status;
  final String? errorMessage;
  final TripMedia? uploadedMedia;  // Available when complete

  MediaUploadProgress({
    required this.uploadId,
    required this.tripId,
    required this.progress,
    required this.status,
    this.errorMessage,
    this.uploadedMedia,
  });

  /// Check if upload is complete
  bool get isComplete => status == UploadStatus.completed;

  /// Check if upload failed
  bool get isFailed => status == UploadStatus.failed;

  /// Check if upload is in progress
  bool get isUploading => status == UploadStatus.uploading;

  /// Copy with updated fields
  MediaUploadProgress copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
    TripMedia? uploadedMedia,
  }) {
    return MediaUploadProgress(
      uploadId: uploadId,
      tripId: tripId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedMedia: uploadedMedia ?? this.uploadedMedia,
    );
  }
}

/// UploadStatus - Status of media upload
enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
}

/// TripMediaResponse - Paginated response for trip media list
class TripMediaResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<TripMedia> results;

  TripMediaResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TripMediaResponse.fromJson(Map<String, dynamic> json) {
    return TripMediaResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => TripMedia.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      if (next != null) 'next': next,
      if (previous != null) 'previous': previous,
      'results': results.map((m) => m.toJson()).toList(),
    };
  }
}
