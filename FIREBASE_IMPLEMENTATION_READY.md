# 🎉 Firebase Implementation - **READY TO DEPLOY**

## ✅ **What's Been Prepared**

All code has been created and is **ready to use** once the backend custom token endpoint is live!

---

## 📦 **1. Updated Notification Model**

**File**: `lib/data/models/notification_model.dart`

### ✅ **Fixed API Compatibility Issues**

```dart
class NotificationModel {
  final int id;                    // ✅ FIXED: Was String, now int (matches API)
  final String body;               // ✅ FIXED: Was 'message', now 'body' (matches API)
  final int? relatedObjectId;      // ✅ NEW: Related object ID from API
  final String? relatedObjectType; // ✅ NEW: Related object type (Trip, Event, etc.)
  
  // ... other fields
}
```

### **What This Fixes**

- ✅ **Type Mismatches**: `id` is now `int` instead of `String`
- ✅ **Field Names**: Uses `body` (API field) instead of `message`
- ✅ **Navigation**: Added `relatedObjectId` and `relatedObjectType` from API
- ✅ **Helper Method**: `navigationRoute` getter for automatic route generation

### **Backward Compatibility**

Legacy fields are kept with `@Deprecated` annotation:
```dart
@Deprecated('Use body instead')
String get message => body;
```

---

## 🔥 **2. Firestore Service (Real-Time Chat)**

**File**: `lib/core/services/firestore_service.dart`

### **Features**

- ✅ **Real-time message streaming** with `getMessagesStream()`
- ✅ **Send messages** with `sendMessage()`
- ✅ **Edit/Delete messages** with `editMessage()` and `deleteMessage()`
- ✅ **Reactions support** with `addReaction()` and `removeReaction()`
- ✅ **Pagination** for loading older messages
- ✅ **Message count** tracking
- ✅ **Connection health checks**

### **Usage Example**

```dart
// Get real-time messages stream
StreamBuilder<List<FirestoreMessage>>(
  stream: FirestoreService().getMessagesStream(tripId: 123),
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final messages = snapshot.data!;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => MessageTile(messages[index]),
    );
  },
)

// Send a message
await FirestoreService().sendMessage(
  tripId: 123,
  authorId: currentUser.id,
  authorName: currentUser.name,
  authorUsername: currentUser.username,
  authorAvatar: currentUser.avatar,
  text: 'Looking forward to this trip!',
);
```

### **Firestore Structure**

```
trips/
  {tripId}/
    messages/
      {messageId}
        - tripId: int
        - authorId: int
        - authorName: string
        - authorUsername: string
        - authorAvatar: string?
        - text: string
        - timestamp: timestamp
        - edited: boolean
        - editedAt: timestamp?
        - deleted: boolean
        - deletedAt: timestamp?
        - reactions: map<string, int>?
```

---

## 📱 **3. FCM Service (Push Notifications)**

**File**: `lib/core/services/fcm_service.dart`

### **Features**

- ✅ **Permission handling** (iOS + Android)
- ✅ **Token management** (get, refresh, delete)
- ✅ **Foreground notifications** (Android local notifications)
- ✅ **Background notifications** (native Firebase handling)
- ✅ **Notification tap handling** (deep linking)
- ✅ **Topic subscriptions** (broadcast messages)

### **Initialization (in main.dart)**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize FCM Service
  await FCMService.initialize(
    onMessageTap: (RemoteMessage message) {
      // Handle notification tap - navigate to relevant screen
      final tripId = message.data['tripId'];
      if (tripId != null) {
        navigatorKey.currentState?.pushNamed('/trips/$tripId');
      }
    },
  );
  
  runApp(MyApp());
}
```

### **Register FCM Token with Backend**

```dart
// After user logs in:
final fcmToken = await FCMService().getToken();
if (fcmToken != null) {
  await MainApiRepository().registerFCMDevice(
    token: fcmToken,
    deviceType: Platform.isAndroid ? 'android' : 'ios',
  );
}

// Listen for token refresh:
FCMService().onTokenRefresh.listen((newToken) async {
  await MainApiRepository().updateFCMToken(newToken);
});
```

### **Platform Setup Required**

**Android**: ✅ Nothing needed (google-services.json already configured)

**iOS**:
1. Add Push Notification capability in Xcode
2. Add Background Modes → Remote notifications
3. Upload APNS key to Firebase Console

---

## 🔐 **4. Firebase Auth Service (Custom Tokens)**

**File**: `lib/core/services/firebase_auth_service.dart`

### **Features**

- ✅ **Custom token authentication** from backend
- ✅ **Auto-refresh** when token expires
- ✅ **Authentication validation**
- ✅ **Sign out handling**
- ✅ **Auth state stream**

### **Usage**

```dart
// After user logs in to AD4x4 backend:
final firebaseUser = await FirebaseAuthService().signInWithCustomToken();

if (firebaseUser != null) {
  print('✅ Firebase authenticated: ${firebaseUser.uid}');
  // Now you can use Firestore and FCM
} else {
  print('❌ Firebase authentication failed');
}

// Ensure authentication is valid (call periodically):
final isValid = await FirebaseAuthService().ensureAuthenticated();

// Sign out when user logs out:
await FirebaseAuthService().signOut();
```

---

## 🚨 **CRITICAL: Backend Requirements**

### **1. Firebase Custom Token Endpoint (REQUIRED)**

Your backend **MUST** implement this endpoint:

```python
# POST /api/firebase/custom-token
from firebase_admin import auth

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def get_firebase_custom_token(request):
    """
    Generate Firebase custom token for authenticated user.
    
    This allows the Flutter app to authenticate with Firebase
    using the user's existing AD4x4 account.
    """
    try:
        # User is already authenticated via JWT
        user_id = request.user.id
        
        # Generate Firebase custom token
        # IMPORTANT: Use string(user_id) to match Firestore security rules
        custom_token = auth.create_custom_token(str(user_id))
        
        return Response({
            'token': custom_token.decode('utf-8'),
            'userId': user_id
        }, status=200)
        
    except Exception as e:
        logger.error(f"Error generating Firebase custom token: {e}")
        return Response({
            'error': 'Failed to generate Firebase token'
        }, status=500)
```

**Add to `urls.py`:**
```python
path('firebase/custom-token', views.get_firebase_custom_token, name='firebase-custom-token'),
```

### **2. FCM Device Registration (ALREADY EXISTS ✅)**

Backend already has this endpoint working:
- `POST /api/device/fcm/` - Register FCM token
- `PATCH /api/device/fcm/{registration_id}/` - Update device
- `DELETE /api/device/fcm/{registration_id}/` - Delete device

### **3. Firestore Security Rules (REQUIRED)**

Deploy these rules to Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Trip messages (chat)
    match /trips/{tripId}/messages/{messageId} {
      // Anyone authenticated can read messages
      allow read: if request.auth != null;
      
      // Users can create messages with their own ID
      allow create: if request.auth != null 
                    && request.resource.data.authorId == int(request.auth.uid);
      
      // Users can only edit/delete their own messages
      allow update, delete: if request.auth != null 
                            && resource.data.authorId == int(request.auth.uid);
    }
  }
}
```

**How to Deploy:**
1. Go to Firebase Console → Firestore Database → Rules
2. Copy the rules above
3. Click "Publish"

### **4. FCM Server Key (VERIFY)**

Ensure Firebase Cloud Messaging is configured:
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Verify **Server key** exists
3. For iOS: Upload APNS authentication key

---

## 📝 **Implementation Checklist**

### **Backend Team**
- [ ] Create `POST /api/firebase/custom-token` endpoint
- [ ] Deploy Firestore security rules to Firebase Console
- [ ] Verify FCM server key is configured
- [ ] Test custom token generation with Postman:
  ```bash
  curl -X POST https://ap.ad4x4.com/api/firebase/custom-token \
    -H "Authorization: Bearer YOUR_JWT_TOKEN"
  ```

### **Flutter Team (Hani)**
- [ ] Review all 4 service files created
- [ ] Decide on migration strategy:
  - **Option A**: Keep REST API + add Firestore (gradual rollout)
  - **Option B**: Full migration to Firestore (immediate switch)
- [ ] Test Firebase authentication with backend
- [ ] Test Firestore chat in development
- [ ] Test FCM notifications
- [ ] Update `trip_chat_screen.dart` to use Firestore

---

## 🎯 **Next Steps**

### **Immediate (Backend)**
1. **CREATE** `/api/firebase/custom-token` endpoint
2. **TEST** endpoint returns valid custom token
3. **DEPLOY** Firestore security rules

### **After Backend Ready**
1. **Add to MainApiRepository**:
   ```dart
   Future<String?> getFirebaseCustomToken() async {
     final response = await _apiClient.post('/firebase/custom-token');
     return response.data['token'] as String?;
   }
   ```

2. **Initialize services in main.dart**:
   ```dart
   // Initialize Firebase
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   
   // Initialize FCM
   await FCMService.initialize(onMessageTap: handleNotificationTap);
   
   // Sign in to Firebase (after user logs in)
   await FirebaseAuthService().signInWithCustomToken();
   ```

3. **Update trip_chat_screen.dart** to use `FirestoreService()`

4. **Register FCM token** after login

5. **Test everything** with real accounts

---

## 📊 **Timeline Estimate**

- **Backend Endpoint**: 2-3 hours
- **Security Rules Deployment**: 30 minutes
- **Flutter Integration**: 4-6 hours
- **Testing & Debugging**: 4-6 hours

**Total**: 10-15 hours (1-2 days)

---

## 🎉 **Status: READY FOR BACKEND**

✅ All Flutter code is **complete and ready to use**  
✅ All services are **documented with examples**  
✅ All dependencies are **installed**  
✅ Notification Model is **fixed for API compatibility**

**Waiting for**: Backend to implement `/api/firebase/custom-token` endpoint

---

## 📞 **Questions?**

If you have any questions about:
- Service implementation
- Migration strategy
- Testing approach
- Firestore structure

Just let me know! 🚀
