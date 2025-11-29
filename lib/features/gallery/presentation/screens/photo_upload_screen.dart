import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/gallery_auth_provider.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/services/error_log_service.dart';

/// Photo Upload Screen
/// 
/// Multi-photo uploader with:
/// - Multiple file selection
/// - Real-time progress tracking per file
/// - Cancellation support
/// - Error handling and retry
/// - Caption editing
class PhotoUploadScreen extends ConsumerStatefulWidget {
  final String galleryId;  // Changed to String (UUID)
  final String galleryTitle;

  const PhotoUploadScreen({
    super.key,
    required this.galleryId,
    required this.galleryTitle,
  });

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

/// Upload resolution options
enum UploadResolution {
  standard(1920, 'Standard (1920px)', 'Fast upload, good quality'),
  medium(2560, 'Medium (2560px)', 'Balanced quality and size'),
  high(3840, 'High (3840px)', 'Best quality, larger files');

  final int pixels;
  final String label;
  final String description;
  
  const UploadResolution(this.pixels, this.label, this.description);
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  final _galleryRepository = GalleryApiRepository();
  final _imagePicker = ImagePicker();

  List<UploadItem> _uploadItems = [];
  String? _sessionId;
  bool _isCreatingSession = false;
  bool _isUploading = false;
  UploadResolution _selectedResolution = UploadResolution.medium;

  @override
  void initState() {
    super.initState();
    _createUploadSession();
  }

  Future<void> _createUploadSession() async {
    setState(() => _isCreatingSession = true);

    try {
      final response = await _galleryRepository.createUploadSession(
        galleryId: widget.galleryId,
        maxResolution: _selectedResolution.pixels,
      );
      _sessionId = response['session_id'] as String;
      setState(() => _isCreatingSession = false);
    } catch (e, stackTrace) {
      // Log error to error logging service
      await ErrorLogService().logError(
        message: 'Failed to create gallery upload session: $e',
        stackTrace: stackTrace.toString(),
        type: 'network',
      );
      
      setState(() => _isCreatingSession = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create upload session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      // Add images to upload queue
      final newItems = images.map((image) {
        return UploadItem(
          file: File(image.path),
          xFile: image,  // Store XFile for web compatibility
          fileName: image.name,
          status: UploadStatus.pending,
          progress: 0.0,
        );
      }).toList();

      setState(() {
        _uploadItems.addAll(newItems);
      });

      // Start uploading if not already uploading
      if (!_isUploading) {
        _startUpload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      final newItem = UploadItem(
        file: File(image.path),
        xFile: image,  // Store XFile for web compatibility
        fileName: image.name,
        status: UploadStatus.pending,
        progress: 0.0,
      );

      setState(() {
        _uploadItems.add(newItem);
      });

      if (!_isUploading) {
        _startUpload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startUpload() async {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload session not ready. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    for (var i = 0; i < _uploadItems.length; i++) {
      final item = _uploadItems[i];

      // Skip if already uploaded or failed
      if (item.status == UploadStatus.completed ||
          item.status == UploadStatus.uploading) {
        continue;
      }

      // Upload the item
      await _uploadSingleItem(i);
    }

    setState(() => _isUploading = false);

    // Check if all uploads completed successfully
    final allCompleted = _uploadItems.every((item) => 
      item.status == UploadStatus.completed
    );

    if (allCompleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All photos uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Auto-close after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  Future<void> _uploadSingleItem(int index) async {
    final item = _uploadItems[index];

    // Update status to uploading
    setState(() {
      _uploadItems[index] = item.copyWith(status: UploadStatus.uploading);
    });

    try {
      // Read file bytes for web platform
      List<int>? fileBytes;
      if (item.xFile != null) {
        fileBytes = await item.xFile!.readAsBytes();
      }
      
      await _galleryRepository.uploadPhoto(
        sessionId: _sessionId!,
        filePath: item.file.path,
        fileBytes: fileBytes,  // Pass bytes for web
        fileName: item.fileName,
        caption: item.caption,
        onProgress: (count, total) {
          final progress = count / total;
          setState(() {
            _uploadItems[index] = item.copyWith(progress: progress);
          });
        },
      );

      // Mark as completed
      setState(() {
        _uploadItems[index] = item.copyWith(
          status: UploadStatus.completed,
          progress: 1.0,
        );
      });
    } catch (e, stackTrace) {
      // Log error to error logging service
      await ErrorLogService().logError(
        message: 'Gallery photo upload failed: ${item.fileName} - $e',
        stackTrace: stackTrace.toString(),
        type: 'network',
      );
      
      // Mark as failed
      setState(() {
        _uploadItems[index] = item.copyWith(
          status: UploadStatus.failed,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _retryUpload(int index) {
    final item = _uploadItems[index];
    setState(() {
      _uploadItems[index] = item.copyWith(
        status: UploadStatus.pending,
        progress: 0.0,
        errorMessage: null,
      );
    });

    if (!_isUploading) {
      _startUpload();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _uploadItems.removeAt(index);
    });
  }

  void _updateCaption(int index, String caption) {
    setState(() {
      _uploadItems[index] = _uploadItems[index].copyWith(caption: caption);
    });
  }

  void _clearCompleted() {
    setState(() {
      _uploadItems.removeWhere((item) => item.status == UploadStatus.completed);
    });
  }

  int get _completedCount => _uploadItems.where((item) => 
    item.status == UploadStatus.completed
  ).length;

  int get _failedCount => _uploadItems.where((item) => 
    item.status == UploadStatus.failed
  ).length;

  int get _pendingCount => _uploadItems.where((item) => 
    item.status == UploadStatus.pending || item.status == UploadStatus.uploading
  ).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Photos'),
            Text(
              widget.galleryTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          if (_completedCount > 0)
            TextButton(
              onPressed: _clearCompleted,
              child: const Text('Clear Completed'),
            ),
        ],
      ),
      body: _isCreatingSession
          ? const LoadingIndicator(message: 'Preparing upload...')
          : Column(
              children: [
                // Upload Stats
                if (_uploadItems.isNotEmpty) _buildStatsBar(colors),

                // Resolution Selector
                _buildResolutionSelector(colors),

                // Upload Queue
                Expanded(
                  child: _uploadItems.isEmpty
                      ? EmptyState(
                          icon: Icons.cloud_upload_outlined,
                          title: 'No Photos Selected',
                          message: 'Select photos from your gallery or take a new photo to upload.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _uploadItems.length,
                          itemBuilder: (context, index) {
                            final item = _uploadItems[index];
                            return _UploadItemCard(
                              item: item,
                              index: index,
                              onRetry: () => _retryUpload(index),
                              onRemove: () => _removeItem(index),
                              onCaptionChanged: (caption) => 
                                _updateCaption(index, caption),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _sessionId != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Select Photos'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatsBar(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatBadge(
            icon: Icons.upload,
            label: 'Total',
            value: '${_uploadItems.length}',
            color: colors.primary,
          ),
          _StatBadge(
            icon: Icons.check_circle,
            label: 'Completed',
            value: '$_completedCount',
            color: Colors.green,
          ),
          _StatBadge(
            icon: Icons.error,
            label: 'Failed',
            value: '$_failedCount',
            color: Colors.red,
          ),
          _StatBadge(
            icon: Icons.schedule,
            label: 'Pending',
            value: '$_pendingCount',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSelector(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_size_select_large,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Upload Quality:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<UploadResolution>(
              value: _selectedResolution,
              isExpanded: true,
              isDense: true,
              underline: Container(),
              items: UploadResolution.values.map((resolution) {
                return DropdownMenuItem(
                  value: resolution,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        resolution.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        resolution.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _uploadItems.isEmpty && !_isUploading
                  ? (UploadResolution? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedResolution = newValue;
                        });
                        // Recreate session with new resolution
                        _createUploadSession();
                      }
                    }
                  : null,  // Disable during upload or when items exist
            ),
          ),
          if (_uploadItems.isNotEmpty || _isUploading) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.lock_outline,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _UploadItemCard extends StatefulWidget {
  final UploadItem item;
  final int index;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final void Function(String) onCaptionChanged;

  const _UploadItemCard({
    required this.item,
    required this.index,
    required this.onRetry,
    required this.onRemove,
    required this.onCaptionChanged,
  });

  @override
  State<_UploadItemCard> createState() => _UploadItemCardState();
}

class _UploadItemCardState extends State<_UploadItemCard> {
  final _captionController = TextEditingController();
  bool _isEditingCaption = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.item.caption ?? '';
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.item.status) {
      case UploadStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case UploadStatus.uploading:
        statusColor = colors.primary;
        statusIcon = Icons.cloud_upload;
        statusText = 'Uploading ${(widget.item.progress * 100).toStringAsFixed(0)}%';
        break;
      case UploadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Uploaded';
        break;
      case UploadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                ),
                child: Image.file(
                  widget.item.file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Info Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Name
                      Text(
                        widget.item.fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error Message
                      if (widget.item.status == UploadStatus.failed &&
                          widget.item.errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    if (widget.item.status == UploadStatus.failed)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: widget.onRetry,
                        tooltip: 'Retry',
                        color: colors.primary,
                        iconSize: 20,
                      ),
                    if (widget.item.status != UploadStatus.uploading)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: widget.onRemove,
                        tooltip: 'Remove',
                        color: Colors.red,
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Progress Bar (for uploading items)
          if (widget.item.status == UploadStatus.uploading)
            LinearProgressIndicator(
              value: widget.item.progress,
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),

          // Caption Editor
          if (widget.item.status != UploadStatus.uploading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _isEditingCaption
                  ? TextField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        hintText: 'Add a caption (optional)...',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                widget.onCaptionChanged(_captionController.text);
                                setState(() => _isEditingCaption = false);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _captionController.text = widget.item.caption ?? '';
                                setState(() => _isEditingCaption = false);
                              },
                            ),
                          ],
                        ),
                      ),
                      maxLines: 2,
                      autofocus: true,
                    )
                  : InkWell(
                      onTap: () => setState(() => _isEditingCaption = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.caption?.isNotEmpty == true
                                    ? widget.item.caption!
                                    : 'Add a caption (optional)...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.item.caption?.isNotEmpty == true
                                      ? colors.onSurface
                                      : colors.onSurface.withValues(alpha: 0.5),
                                  fontStyle: widget.item.caption?.isNotEmpty == true
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Upload Item Model
class UploadItem {
  final File file;
  final XFile? xFile;  // For web platform compatibility
  final String fileName;
  final UploadStatus status;
  final double progress;
  final String? caption;
  final String? errorMessage;

  const UploadItem({
    required this.file,
    this.xFile,
    required this.fileName,
    required this.status,
    required this.progress,
    this.caption,
    this.errorMessage,
  });

  UploadItem copyWith({
    File? file,
    XFile? xFile,
    String? fileName,
    UploadStatus? status,
    double? progress,
    String? caption,
    String? errorMessage,
  }) {
    return UploadItem(
      file: file ?? this.file,
      xFile: xFile ?? this.xFile,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      caption: caption ?? this.caption,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
}
