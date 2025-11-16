---
name: Backend Integration Issue
about: Report issues with API integration or backend communication
title: '[API] '
labels: backend, api
assignees: ''
---

## 🌐 API Endpoint
- Base URL: [Main API / Gallery API]
- Endpoint: [e.g., POST /api/trips/create/]
- Method: [GET / POST / PUT / PATCH / DELETE]

## 🐛 Issue Description
Describe the integration issue clearly.

## 📤 Request Details
**Headers:**
```json
{
  "Authorization": "Bearer <token>",
  "Accept": "application/json",
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  // Paste actual request payload
}
```

## 📥 Response Details
**Status Code:** [e.g., 400, 500]

**Response Body:**
```json
{
  // Paste actual response
}
```

## ✅ Expected Behavior
What response/behavior were you expecting?

## ❌ Actual Behavior
What actually happened?

## 🔐 Authentication & Permissions
- [ ] User is authenticated
- [ ] Token is valid
- [ ] User has required permissions
- Required permission: [e.g., can_create_trips]

## 🔍 Troubleshooting Steps Taken
- [ ] Verified API endpoint URL
- [ ] Checked request headers
- [ ] Validated request payload format
- [ ] Tested with valid authentication token
- [ ] Confirmed user has required permissions
- [ ] Checked backend logs (if available)

## 📋 Backend Team Context
Information for backend developers:

**Related Flutter Code:**
- Service file: [e.g., lib/features/trips/data/services/trips_service.dart]
- Model file: [e.g., lib/features/trips/data/models/trip_model.dart]
- Line number: [if applicable]

**Expected Contract:**
```dart
// Paste relevant Retrofit interface or expected response model
```

## 🔄 API Documentation Reference
Refer to: [Section in BACKEND_INTEGRATION.md]

## 🚨 Impact
- [ ] Critical (app cannot function)
- [ ] High (major feature broken)
- [ ] Medium (workaround available)
- [ ] Low (minor inconvenience)

## 📋 Additional Context
- Environment: [Production / Development / Staging]
- Flutter version: 3.35.4
- Dio version: 5.4.0
- Retrofit version: 4.1.0

## 🔗 Related Issues
Link to any related issues or PRs.