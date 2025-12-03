import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';

/// Image Upload Service
/// 
/// Handles image picking, cropping, and uploading
/// Supports both mobile and web platforms
class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio;
  
  ImageUploadService(this._dio);
  
  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE UPLOAD] Error picking image: $e');
      }
      rethrow;
    }
  }
  
  /// Crop image with custom aspect ratio
  /// Default aspect ratio: 16:9 (landscape for trip cards)
  /// 
  /// Pass [context] parameter for web platform support
  /// 
  /// ⚠️ WEB PLATFORM: Cropping is skipped on web due to plugin limitations.
  /// The original image is returned as-is.
  Future<CroppedFile?> cropImage(
    String imagePath, {
    CropAspectRatio aspectRatio = const CropAspectRatio(ratioX: 16, ratioY: 9),
    BuildContext? context,
  }) async {
    try {
      // ⚠️ WEB PLATFORM WORKAROUND: Skip cropping on web
      // The image_cropper web implementation has plugin initialization issues
      // For web, we'll just return a CroppedFile-like object with the original path
      if (kIsWeb) {
        if (kDebugMode) {
          print('⚠️ [IMAGE UPLOAD] Web platform: Skipping crop, using original image');
        }
        // Return the original file wrapped as a CroppedFile
        // On web, the path is already a blob URL from the picker
        return CroppedFile(imagePath);
      }
      
      // Build platform-specific UI settings for mobile
      final List<PlatformUiSettings> uiSettings = [
        AndroidUiSettings(
          toolbarTitle: 'Crop Trip Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Trip Image',
        ),
      ];
      
      // Crop the image (mobile only)
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: aspectRatio,
        compressQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: uiSettings,
      );
      
      return croppedFile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE UPLOAD] Error cropping image: $e');
      }
      rethrow;
    }
  }
  
  /// Upload image to backend storage
  /// Returns the image URL from the server
  Future<String> uploadToBackend(String filePath, {String? fileName}) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Create multipart file
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: fileName ?? 'trip_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      
      // Upload to backend
      final response = await _dio.post(
        '/api/upload/image/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      // Extract image URL from response
      final imageUrl = response.data['url'] as String;
      
      if (kDebugMode) {
        print('✅ [IMAGE UPLOAD] Image uploaded successfully: $imageUrl');
      }
      
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE UPLOAD] Error uploading to backend: $e');
      }
      rethrow;
    }
  }
  
  /// Convert image to base64 string (fallback for backends without file upload)
  Future<String> imageToBase64(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final base64String = base64Encode(bytes);
      
      if (kDebugMode) {
        print('✅ [IMAGE UPLOAD] Image converted to base64 (${base64String.length} chars)');
      }
      
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE UPLOAD] Error converting to base64: $e');
      }
      rethrow;
    }
  }
  
  /// Complete flow: Pick → Crop → Upload
  Future<String?> pickCropAndUpload({
    ImageSource source = ImageSource.gallery,
    CropAspectRatio aspectRatio = const CropAspectRatio(ratioX: 16, ratioY: 9),
    bool useBase64 = false,
  }) async {
    try {
      // Step 1: Pick image
      final pickedImage = await pickImage(source: source);
      if (pickedImage == null) {
        if (kDebugMode) {
          print('⚠️  [IMAGE UPLOAD] No image selected');
        }
        return null;
      }
      
      if (kDebugMode) {
        print('📸 [IMAGE UPLOAD] Image picked: ${pickedImage.path}');
      }
      
      // Step 2: Crop image
      final croppedImage = await cropImage(
        pickedImage.path,
        aspectRatio: aspectRatio,
      );
      
      if (croppedImage == null) {
        if (kDebugMode) {
          print('⚠️  [IMAGE UPLOAD] Cropping cancelled');
        }
        return null;
      }
      
      if (kDebugMode) {
        print('✂️  [IMAGE UPLOAD] Image cropped: ${croppedImage.path}');
      }
      
      // Step 3: Upload or convert to base64
      if (useBase64) {
        return await imageToBase64(croppedImage.path);
      } else {
        return await uploadToBackend(croppedImage.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [IMAGE UPLOAD] Error in complete flow: $e');
      }
      rethrow;
    }
  }
}
