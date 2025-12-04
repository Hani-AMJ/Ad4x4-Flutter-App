# 🔥 Firebase Configuration - Quick Reference Guide

**For**: Hani AMJ  
**Date**: December 4, 2025

---

## 📋 Package IDs - CRITICAL INFORMATION

### **Android**:
```
Package Name: com.ad4x4.ad4x4_mobile
File Needed: google-services.json
Location: android/app/google-services.json
```

### **iOS**:
```
Bundle ID: com.ad4x4.ad4x4Mobile
File Needed: GoogleService-Info.plist
Location: ios/Runner/GoogleService-Info.plist
```

**⚠️ IMPORTANT**: These package names MUST match exactly in Firebase Console!

---

## 📥 How to Download Configuration Files

### **Step 1: Open Firebase Console**
URL: https://console.firebase.google.com/project/ad4x4-afed6/settings/general

### **Step 2: Scroll to "Your apps" Section**

### **Step 3: For Android**

**If Android app already exists**:
1. Click on Android app card
2. Scroll down to "google-services.json" section
3. Click "Download google-services.json"

**If Android app doesn't exist**:
1. Click "Add app" button
2. Click Android icon (robot)
3. Enter package name: `com.ad4x4.ad4x4_mobile` ⚠️ **MUST BE EXACT**
4. Enter app nickname: "AD4x4 Mobile" (optional)
5. Skip SHA-1 (not needed now)
6. Click "Register app"
7. Click "Download google-services.json"
8. Click "Continue to console" (skip remaining steps)

### **Step 4: For iOS**

**If iOS app already exists**:
1. Click on iOS app card
2. Scroll down to "GoogleService-Info.plist" section
3. Click "Download GoogleService-Info.plist"

**If iOS app doesn't exist**:
1. Click "Add app" button
2. Click Apple icon
3. Enter bundle ID: `com.ad4x4.ad4x4Mobile` ⚠️ **MUST BE EXACT**
4. Enter app nickname: "AD4x4 iOS" (optional)
5. Skip App Store ID (not needed now)
6. Click "Register app"
7. Click "Download GoogleService-Info.plist"
8. Click "Continue to console" (skip remaining steps)

---

## ✅ Verification Checklist

### **After Downloading google-services.json**:
- [ ] File contains `"project_id": "ad4x4-afed6"`
- [ ] File contains `"package_name": "com.ad4x4.ad4x4_mobile"`
- [ ] File size is around 2-5 KB (JSON format)

### **After Downloading GoogleService-Info.plist**:
- [ ] File contains `<key>PROJECT_ID</key>`
- [ ] File contains `<string>ad4x4-afed6</string>`
- [ ] File contains `<key>BUNDLE_ID</key>`
- [ ] File contains `<string>com.ad4x4.ad4x4Mobile</string>`
- [ ] File size is around 2-5 KB (XML/PLIST format)

---

## 🚨 Common Mistakes to Avoid

### **❌ Wrong Package Names**:
```
Wrong: com.ad4x4.mobile
Wrong: com.ad4x4.app
Wrong: com.example.ad4x4
Correct: com.ad4x4.ad4x4_mobile (Android)
Correct: com.ad4x4.ad4x4Mobile (iOS)
```

### **❌ Wrong File Locations**:
```
Wrong: android/google-services.json
Wrong: android/app/src/google-services.json
Correct: android/app/google-services.json

Wrong: ios/GoogleService-Info.plist
Wrong: ios/Runner/Assets/GoogleService-Info.plist
Correct: ios/Runner/GoogleService-Info.plist
```

---

## 📤 How to Send Files to Me

### **Option 1: Upload in Chat** (Preferred)
Just drag and drop both files into our conversation

### **Option 2: Place in Project**
```bash
# Android
cp ~/Downloads/google-services.json /home/user/flutter_app/android/app/

# iOS
cp ~/Downloads/GoogleService-Info.plist /home/user/flutter_app/ios/Runner/
```

---

## 🔧 Backend Team Requirements

**They need to create this endpoint**:

```
POST /api/firebase/custom-token
Authorization: Bearer YOUR_JWT_TOKEN

Response:
{
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

**Backend Code** (Python/Django):
```python
import firebase_admin
from firebase_admin import credentials, auth

# Initialize (do once at startup)
cred = credentials.Certificate('/path/to/firebase-admin-sdk.json')
firebase_admin.initialize_app(cred)

# Create endpoint
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_firebase_custom_token(request):
    user_id = str(request.user.id)
    custom_token = auth.create_custom_token(user_id)
    return Response({
        'firebaseToken': custom_token.decode('utf-8'),
        'expiresIn': 3600
    })
```

---

## 🎯 Next Steps After Providing Files

1. **I'll configure Firebase** (30-45 minutes)
2. **I'll implement Firestore chat** (6-8 hours)
3. **I'll implement FCM notifications** (6-8 hours)
4. **We'll test together** (4-6 hours)

---

## 📞 Quick Links

- **Firebase Console**: https://console.firebase.google.com/project/ad4x4-afed6
- **Project Settings**: https://console.firebase.google.com/project/ad4x4-afed6/settings/general
- **Firestore**: https://console.firebase.google.com/project/ad4x4-afed6/firestore

---

**Ready when you are!** 🚀
