# Image Upload Backend Integration Issue

## 🔍 Problem

When attempting to create a trip with an image, the backend returns a 400 error:

```
❌ [CREATE TRIP] Error creating trip: {image: [The submitted data was not a file. Check the encoding type on the form.]}
```

**Root Cause**: The backend expects image uploads via `multipart/form-data` encoding, but we're sending a blob URL string in the JSON body.

## ❌ The Issue

### What We're Sending (Current)
```json
{
  "lead": 10613,
  "title": "Sample Trip",
  "description": "Trip description",
  "startTime": "2025-11-22T10:14:00.000",
  "endTime": "2025-11-23T10:14:00.000",
  "cutOff": "2025-11-21T10:14:00.000",
  "capacity": 20,
  "level": 5,
  "allowWaitlist": true,
  "image": "blob:https://5060-itvkzz7cz3cmn61dhwbxr-583b4d74.sandbox.novita.ai/13221052-0563-46dc-8cbe-89eb455d4d88",
  "meetingPoint": 154
}
```

**Problem**: The `image` field contains a blob URL (web browser's temporary URL for the file), which the backend cannot process.

### What the Backend Expects

According to the API documentation (`/home/user/docs/Ad4x4_Main_API_Documentation.docx`):

```
POST /api/trips
JSON Request Body Fields:
  - image: string
```

The backend expects one of the following:
1. **A permanent image URL** (e.g., `https://cdn.example.com/images/trip123.jpg`)
2. **An empty string** (no image)
3. **Multipart form upload** (not JSON) with the actual file data

## ✅ Temporary Solution

**Disable the image field** in trip creation until proper image upload is implemented:

**File**: `lib/features/trips/presentation/screens/create_trip_screen.dart` (Line ~1219)

```dart
final tripData = {
  'lead': currentUserId,
  'title': _titleController.text.trim(),
  'description': _descriptionController.text.trim(),
  'startTime': _startTime!.toIso8601String(),
  'endTime': _endTime!.toIso8601String(),
  'cutOff': (_cutOff ?? _startTime!.subtract(const Duration(hours: 24))).toIso8601String(),
  'capacity': int.parse(_capacityController.text),
  'level': _selectedLevelId,
  'allowWaitlist': _allowWaitlist,
  // ⚠️ NOTE: Image field temporarily disabled - backend expects file upload, not blob URL
  // TODO: Implement proper image upload endpoint integration
  // 'image': _tripImagePath ?? '',  // DISABLED: Blob URL causes "not a file" error
  if (_selectedMeetingPointId != null) 'meetingPoint': _selectedMeetingPointId,
};
```

**Result**: Trip creation now works, but images are not uploaded yet.

## 🔧 Proper Solutions (To Be Implemented)

### Option 1: Two-Step Upload Process ✅ RECOMMENDED

1. **Step 1: Upload Image**
   ```dart
   // Upload image to backend first
   final imageUrl = await imageUploadService.uploadToBackend(_tripImagePath!);
   ```

2. **Step 2: Create Trip with Image URL**
   ```dart
   final tripData = {
     ...
     'image': imageUrl,  // Use the returned URL
     ...
   };
   ```

**Implementation Needed**:
- Backend endpoint: `POST /api/upload/image/` (or similar)
- Returns: `{"url": "https://cdn.example.com/images/xyz.jpg"}`
- Service method already exists: `ImageUploadService.uploadToBackend()`

### Option 2: Multipart Form Upload

Change the create trip endpoint to accept `multipart/form-data`:

```dart
final formData = FormData.fromMap({
  'lead': currentUserId,
  'title': _titleController.text.trim(),
  'description': _descriptionController.text.trim(),
  // ... other fields ...
  'image': await MultipartFile.fromFile(_tripImagePath!),
});

await repository.createTripWithImage(formData);
```

**Challenges**:
- Requires backend API changes
- More complex than two-step process
- Harder to implement validation

### Option 3: Base64 Encoding

Convert image to base64 and send in JSON:

```dart
final base64Image = await imageUploadService.imageToBase64(_tripImagePath!);
final tripData = {
  ...
  'image': base64Image,
  ...
};
```

**Challenges**:
- Very large payload sizes
- Poor performance for large images
- Not recommended for production

## 📝 Recommended Implementation Plan

### Phase 1: Image Upload Endpoint (Backend)

**Backend Developer**: Create image upload endpoint

```python
# Django Backend (example)
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['POST'])
def upload_trip_image(request):
    image = request.FILES.get('image')
    if not image:
        return Response({'error': 'No image provided'}, status=400)
    
    # Save to storage (S3, local, etc.)
    url = save_image(image)
    
    return Response({'url': url}, status=200)
```

**Endpoint**: `POST /api/upload/image/`

**Request**: `multipart/form-data` with `image` file

**Response**:
```json
{
  "url": "https://cdn.ad4x4.com/trip-images/2025/11/xyz.jpg"
}
```

### Phase 2: Flutter Integration

**Update**: `lib/features/trips/presentation/screens/create_trip_screen.dart`

```dart
Future<void> _submitTrip() async {
  // ... validation code ...
  
  setState(() => _isSubmitting = true);
  
  try {
    final repository = ref.read(mainApiRepositoryProvider);
    final imageService = ref.read(imageUploadServiceProvider);
    
    // Step 1: Upload image if selected
    String? imageUrl;
    if (_tripImagePath != null) {
      try {
        imageUrl = await imageService.uploadToBackend(_tripImagePath!);
        if (kDebugMode) {
          print('✅ [CREATE TRIP] Image uploaded: $imageUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [CREATE TRIP] Image upload failed: $e');
        }
        // Continue without image rather than failing entire trip creation
      }
    }
    
    // Step 2: Create trip with image URL
    final tripData = {
      'lead': currentUserId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startTime': _startTime!.toIso8601String(),
      'endTime': _endTime!.toIso8601String(),
      'cutOff': (_cutOff ?? _startTime!.subtract(const Duration(hours: 24))).toIso8601String(),
      'capacity': int.parse(_capacityController.text),
      'level': _selectedLevelId,
      'allowWaitlist': _allowWaitlist,
      if (imageUrl != null) 'image': imageUrl,  // ✅ Use uploaded image URL
      if (_selectedMeetingPointId != null) 'meetingPoint': _selectedMeetingPointId,
    };
    
    final response = await repository.createTrip(tripData);
    
    // ... success handling ...
  } catch (e) {
    // ... error handling ...
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

### Phase 3: Error Handling & User Feedback

- Show progress indicator during image upload
- Handle upload failures gracefully
- Provide clear error messages
- Allow retry for failed uploads

## 🧪 Testing Checklist

### Current State (Image Disabled)
- ✅ Trip creation works without image
- ✅ No 400 error about image encoding
- ⚠️ Image picker UI still visible but non-functional

### After Implementation
- [ ] Image upload endpoint returns valid URL
- [ ] Trip creation includes uploaded image URL
- [ ] Image displays in trip details
- [ ] Error handling for failed uploads
- [ ] Large image compression works
- [ ] Progress indicator during upload

## 📊 Files Affected

### Current Changes (Temporary Fix)
- `lib/features/trips/presentation/screens/create_trip_screen.dart` - Disabled image field

### Future Changes (Proper Fix)
- `lib/core/services/image_upload_service.dart` - Already has uploadToBackend() method
- `lib/features/trips/presentation/screens/create_trip_screen.dart` - Add upload before create
- Backend: Add `/api/upload/image/` endpoint

## 🎯 User Impact

### Current (Temporary Fix)
- ✅ **Trip creation works**
- ❌ **Cannot upload images** (UI still shows image picker but images aren't saved)
- 💡 **Workaround**: Admin can add images later via trip edit feature (if available)

### After Proper Fix
- ✅ **Full image upload functionality**
- ✅ **Images saved with trips**
- ✅ **Proper error handling**

## 💡 Additional Recommendations

1. **Image Optimization**:
   - Compress images before upload
   - Resize to maximum dimensions (e.g., 1920x1080)
   - Convert to optimized format (WebP, JPEG)

2. **Storage Strategy**:
   - Use CDN for image delivery
   - Implement image caching
   - Generate thumbnails automatically

3. **User Experience**:
   - Show upload progress
   - Allow image preview before upload
   - Provide clear error messages
   - Allow retry on failure

4. **Security**:
   - Validate file types (JPEG, PNG, WebP only)
   - Limit file sizes (e.g., 5MB max)
   - Scan for malware
   - Authenticate upload requests

## 📚 References

- API Documentation: `/home/user/docs/Ad4x4_Main_API_Documentation.docx`
- Image Service: `lib/core/services/image_upload_service.dart`
- Create Trip Screen: `lib/features/trips/presentation/screens/create_trip_screen.dart`
- Image Cropper Fix: `docs/IMAGE_CROPPER_WEB_FIX.md`
