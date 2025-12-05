# Firestore Security Rules for AD4x4 Real-Time Chat

## Overview

This document provides the Firestore security rules configuration required for the AD4x4 Flutter app's real-time chat feature.

**Important**: These rules must be deployed to Firebase Console before the real-time chat feature will work.

---

## Firebase Project Details

- **Project ID**: `ad4x4-afed6`
- **Database**: Firestore (Cloud Firestore)
- **Collection Structure**: `trips/{tripId}/messages/{messageId}`

---

## Security Rules

Copy and paste these rules into Firebase Console → Firestore Database → Rules:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Trips collection - messages subcollection
    match /trips/{tripId}/messages/{messageId} {
      
      // ✅ ALLOW READ: Any authenticated user can read messages
      // This allows all club members to see trip chat messages
      allow read: if request.auth != null;
      
      // ✅ ALLOW CREATE: Authenticated users can create messages
      // BUT only if the authorId matches their Firebase UID
      allow create: if request.auth != null 
                    && request.resource.data.authorId == int(request.auth.uid);
      
      // ✅ ALLOW UPDATE/DELETE: Users can only edit/delete their own messages
      allow update, delete: if request.auth != null 
                          && resource.data.authorId == int(request.auth.uid);
    }
    
    // Default: Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## How to Deploy Rules

### Method 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **ad4x4-afed6**
3. Navigate: **Firestore Database** → **Rules** tab
4. Replace existing rules with the rules above
5. Click **Publish**
6. Wait 1-2 minutes for rules to propagate

### Method 2: Firebase CLI

If you have Firebase CLI installed:

```bash
# 1. Login to Firebase
firebase login

# 2. Initialize Firestore (if not already done)
firebase init firestore

# 3. Edit firestore.rules file with the rules above

# 4. Deploy rules
firebase deploy --only firestore:rules
```

---

## Rule Explanation

### Authentication Check: `request.auth != null`

- Ensures only authenticated users (signed in via Firebase Custom Token) can access chat
- Anonymous users cannot read or write messages
- This protects chat data from unauthorized access

### Author ID Validation: `authorId == int(request.auth.uid)`

- When creating a message, the `authorId` field must match the user's Firebase UID
- This prevents users from impersonating others
- The `int()` cast is used because:
  - Firebase Auth UID is stored as string
  - AD4x4 user IDs are integers
  - We use the AD4x4 user ID as the Firebase UID (via custom token)

### Read Permissions

- **Allow**: Any authenticated user can read all messages in any trip
- **Reason**: Club members should be able to see all trip discussions
- **Security**: Only authenticated users can read (non-members cannot access)

### Write Permissions

- **Create**: Users can create messages, but `authorId` must match their UID
- **Update**: Users can only update their own messages
- **Delete**: Users can only delete their own messages

---

## Testing Rules

### Test Read Access

```dart
// Should succeed if user is authenticated
final messages = await FirebaseFirestore.instance
    .collection('trips')
    .doc('123')
    .collection('messages')
    .get();
```

### Test Write Access

```dart
// Should succeed if authorId matches authenticated user ID
await FirebaseFirestore.instance
    .collection('trips')
    .doc('123')
    .collection('messages')
    .add({
      'authorId': currentUser.id,  // Must match Firebase UID
      'authorName': 'Hani AMJ',
      'authorUsername': 'HaniAMJ',
      'text': 'Test message',
      'timestamp': FieldValue.serverTimestamp(),
    });
```

### Test Unauthorized Access

```dart
// Should FAIL - trying to create message with different authorId
await FirebaseFirestore.instance
    .collection('trips')
    .doc('123')
    .collection('messages')
    .add({
      'authorId': 99999,  // Different from Firebase UID
      'text': 'This should fail',
    });
// Error: PERMISSION_DENIED
```

---

## Production Considerations

### Current Rules (Development-Friendly)

The rules above allow all authenticated users to read any trip's messages. This is suitable for a club environment where members should have access to all discussions.

### Future Enhancements (Optional)

If you want to restrict access to specific trips:

```
// Only allow users who are registered for the trip
allow read: if request.auth != null 
            && isRegisteredForTrip(tripId, request.auth.uid);

function isRegisteredForTrip(tripId, userId) {
  // This would require a separate registrations collection
  return exists(/databases/$(database)/documents/trips/$(tripId)/registrants/$(userId));
}
```

---

## Troubleshooting

### Error: "Missing or insufficient permissions"

**Cause**: Firestore rules not deployed or user not authenticated

**Solution**:
1. Verify rules are published in Firebase Console
2. Check user is authenticated: `FirebaseAuth.instance.currentUser != null`
3. Verify custom token authentication succeeded

### Error: "PERMISSION_DENIED"

**Cause**: `authorId` doesn't match Firebase UID

**Solution**:
1. Ensure `authorId` in message matches `FirebaseAuth.instance.currentUser.uid`
2. Check custom token is created with correct user ID

### Messages not appearing in real-time

**Cause**: Firestore listener not subscribed

**Solution**:
1. Check Flutter console for Firebase initialization logs
2. Verify `TripChatProvider` is using Firestore mode
3. Look for "🔥 [TripChat] Subscribing to Firestore stream" log

---

## Security Best Practices

1. ✅ **Always validate `authorId`**: Prevents impersonation
2. ✅ **Use server timestamps**: Prevents timestamp manipulation
3. ✅ **Validate data types**: Ensures data integrity
4. ✅ **Limit query size**: Use pagination (already implemented with limit: 50)
5. ✅ **Monitor usage**: Check Firebase Console for suspicious activity

---

## Next Steps After Deployment

1. ✅ Deploy rules to Firebase Console
2. ✅ Test authentication flow
3. ✅ Test sending a message from Flutter app
4. ✅ Verify real-time updates work
5. ✅ Monitor Firebase Console → Firestore → Usage tab
6. ✅ Set up billing alerts (stay within free tier)

---

## Support

If you encounter issues:

1. Check Firebase Console → Firestore → Rules for syntax errors
2. Review Flutter app logs for authentication errors
3. Test rules using Firebase Console → Firestore → Rules → Rules Playground
4. Contact Firebase support if rules won't publish

---

**Last Updated**: 2025-01-11  
**Author**: Friday (AI Assistant)  
**App Version**: 1.6.2  
**Firebase Project**: ad4x4-afed6
