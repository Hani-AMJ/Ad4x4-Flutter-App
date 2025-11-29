# AD4x4 API Documentation

## Overview

This document provides comprehensive API documentation for the AD4x4 off-roading club management system.

**Base URL**: `ap.ad4x4.com` (development) or your production URL

**API Prefix**: All endpoints are prefixed with `/api/`

---

## Table of Contents

1. [Auth](#auth)
2. [Choices](#choices)
3. [Clubnews](#clubnews)
4. [Device](#device)
5. [Faqs](#faqs)
6. [Feedback](#feedback)
7. [Globalsettings](#globalsettings)
8. [Groups](#groups)
9. [Levels](#levels)
10. [Logbookentries](#logbookentries)
11. [Logbookskillreferences](#logbookskillreferences)
12. [Logbookskills](#logbookskills)
13. [Meetingpoints](#meetingpoints)
14. [Members](#members)
15. [Notifications](#notifications)
16. [Permissionmatrix](#permissionmatrix)
17. [Schema](#schema)
18. [Sponsors](#sponsors)
19. [Systemtime](#systemtime)
20. [Token](#token)
21. [Tripcomments](#tripcomments)
22. [Tripreports](#tripreports)
23. [Triprequests](#triprequests)
24. [Trips](#trips)
25. [Upgraderequestcomments](#upgraderequestcomments)
26. [Upgraderequests](#upgraderequests)
27. [Validators](#validators)

---
### New Endpoints (Added 2025-11-27)
- [🌍 Geocoding Endpoints](#-geocoding-endpoints)
- [⚙️ Settings Endpoints](#️-settings-endpoints)
- [🔒 Global Settings Endpoints](#-global-settings-endpoints)
- [👤 GDPR Compliance Endpoints](#-gdpr-compliance-endpoints)
- [📝 UI Strings Management Endpoints](#-ui-strings-management-endpoints)
- [📋 Trips Logbook Endpoints](#-trips-logbook-endpoints)


## Authentication

The API uses JWT (JSON Web Token) authentication. To authenticate:

1. **Obtain Token**: POST to `/api/token/` with username and password
2. **Use Token**: Include in Authorization header as `Bearer <token>`
3. **Refresh Token**: POST to `/api/token/refresh/` with refresh token

### Authentication Header Format
```
Authorization: Bearer <your_jwt_token>
```

### Token Endpoints

#### Obtain Token Pair
- **Endpoint**: `POST /api/token/`
- **Body**:
  ```json
  {
    "username": "your_username",
    "password": "your_password"
  }
  ```
- **Response**:
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
  ```

#### Refresh Token
- **Endpoint**: `POST /api/token/refresh/`
- **Body**:
  ```json
  {
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
  ```
- **Response**:
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
  ```

---

## Response Format

Most endpoints return responses in the following formats:

### Success Response (Unified)
```json
{
  "success": true,
  "message": "operation_successful" // or relevant data object
}
```

### Error Response (Unified)
```json
{
  "success": false,
  "message": "error_description" // or error details object
}
```

### List Response (Paginated)
```json
{
  "count": 100,
  "next": "http://api.example.org/api/items/?page=3",
  "previous": "http://api.example.org/api/items/?page=1",
  "results": [
    // Array of items
  ]
}
```

---

## Common Query Parameters

Many list endpoints support these common parameters:

- `page` - Page number for pagination (integer)
- `pageSize` - Number of results per page (integer)
- `search` - Search query string
- `ordering` - Field name to order by (prefix with `-` for descending)

---

## Auth

### POST `/api/auth/change-password/`

**Description**: Change user password - custom endpoint with unified response

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `ChangePasswordRequest`
  - `oldPassword`: string - **Required** - 
  - `password`: string - **Required** - 
  - `passwordConfirm`: string - **Required** - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/change-password/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/login/`

**Description**: Logs in the user via given login and password.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `DefaultLoginRequest`
  - `login`: string - **Required** - 
  - `password`: string - **Required** - 

**Responses**:

- `200`:  - Returns `DefaultLogin`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/login/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/logout/`

**Description**: Logs out the user. returns an error if the user is not
authenticated.

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `LogoutRequest`
  - `revokeToken`: boolean - Optional - 

**Responses**:

- `200`:  - Returns `Logout`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/logout/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/auth/profile/`

**Authentication**: JWT Authentication Required

**Responses**:

- `200`:  - Returns `Profile`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/auth/profile/`

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `ProfileRequest`
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carYear`: integer - Optional - 
  - `carColor`: string - Optional - 
  - `carImage`: string - Optional - 
  - `dob`: string - Optional - 
  - `iceName`: string - Optional - 
  - `icePhone`: string - Optional - 
  - `avatar`: string - Optional - 
  - `dateJoined`: string - Optional - 
  - `city`: string - Optional - 
  - `gender`: string - Optional - 
  - `nationality`: string - Optional - 

**Responses**:

- `200`:  - Returns `Profile`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PUT `/api/auth/profile/`

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `ProfileRequest`
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carYear`: integer - Optional - 
  - `carColor`: string - Optional - 
  - `carImage`: string - Optional - 
  - `dob`: string - Optional - 
  - `iceName`: string - Optional - 
  - `icePhone`: string - Optional - 
  - `avatar`: string - Optional - 
  - `dateJoined`: string - Optional - 
  - `city`: string - Optional - 
  - `gender`: string - Optional - 
  - `nationality`: string - Optional - 

**Responses**:

- `200`:  - Returns `Profile`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/auth/profile/`

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `PatchedProfileRequest`
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carYear`: integer - Optional - 
  - `carColor`: string - Optional - 
  - `carImage`: string - Optional - 
  - `dob`: string - Optional - 
  - `iceName`: string - Optional - 
  - `icePhone`: string - Optional - 
  - `avatar`: string - Optional - 
  - `dateJoined`: string - Optional - 
  - `city`: string - Optional - 
  - `gender`: string - Optional - 
  - `nationality`: string - Optional - 

**Responses**:

- `200`:  - Returns `Profile`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/auth/profile/notificationsettings`

**Authentication**: JWT Authentication Required

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedNotificationSettingsList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/auth/profile/notificationsettings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/auth/profile/notificationsettings`

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `NotificationSettingsRequest`
  - `clubNewsEnabledEmail`: boolean - Optional - 
  - `clubNewsEnabledAppPush`: boolean - Optional - 
  - `newTripAlertsEnabledEmail`: boolean - Optional - 
  - `newTripAlertsEnabledAppPush`: boolean - Optional - 
  - `upgradeRequestReminderEmail`: boolean - Optional - 
  - `newTripAlertsLevelFilter`: array - Optional - 

**Responses**:

- `200`:  - Returns `NotificationSettings`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/auth/profile/notificationsettings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/auth/profile/notificationsettings`

**Authentication**: JWT Authentication Required

**Request Body** (Optional):

Schema: `PatchedNotificationSettingsRequest`
  - `clubNewsEnabledEmail`: boolean - Optional - 
  - `clubNewsEnabledAppPush`: boolean - Optional - 
  - `newTripAlertsEnabledEmail`: boolean - Optional - 
  - `newTripAlertsEnabledAppPush`: boolean - Optional - 
  - `upgradeRequestReminderEmail`: boolean - Optional - 
  - `newTripAlertsLevelFilter`: array - Optional - 

**Responses**:

- `200`:  - Returns `NotificationSettings`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/auth/profile/notificationsettings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/register/`

**Description**: Register new user.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `MemberRegistrationRequest`
  - `username`: string - **Required** - 
  - `email`: string - **Required** - 
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carColor`: string - Optional - 
  - `carYear`: integer - Optional - 
  - `carImage`: string - Optional - 
  - `dob`: string - Optional - 
  - `iceName`: string - Optional - 
  - `icePhone`: string - Optional - 
  - `gender`: string - Optional - 
  - `nationality`: string - Optional - 
  - `city`: string - Optional - 
  - `avatar`: string - Optional - 
  - `password`: string - **Required** - 
  - `password2`: string - **Required** - 

**Responses**:

- `200`:  - Returns `MemberRegistration`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/register/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/register-email/`

**Description**: Register new email.

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `DefaultRegisterEmailRequest`
  - `email`: string - **Required** - 

**Responses**:

- `200`:  - Returns `DefaultRegisterEmail`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/register-email/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/reset-password/`

**Description**: Reset password, given the signature and timestamp from the link.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `ResetPasswordRequest`
  - `userId`: string - **Required** - 
  - `timestamp`: integer - **Required** - 
  - `signature`: string - **Required** - 
  - `password`: string - **Required** - 

**Responses**:

- `200`:  - Returns `ResetPassword`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/reset-password/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/send-reset-password-link/`

**Description**: Send email with reset password link.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `DefaultSendResetPasswordLinkRequest`
  - `login`: string - **Required** - 

**Responses**:

- `200`:  - Returns `DefaultSendResetPasswordLink`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/send-reset-password-link/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/verify-email/`

**Description**: Verify email via signature.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `VerifyEmailRequest`
  - `userId`: string - **Required** - 
  - `email`: string - **Required** - 
  - `timestamp`: integer - **Required** - 
  - `signature`: string - **Required** - 

**Responses**:

- `200`:  - Returns `VerifyEmail`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/verify-email/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/auth/verify-registration/`

**Description**: Verify registration via signature.

**Authentication**: Optional JWT Authentication

**Request Body** (Required):

Schema: `VerifyRegistrationRequest`
  - `userId`: string - **Required** - 
  - `timestamp`: integer - **Required** - 
  - `signature`: string - **Required** - 

**Responses**:

- `200`:  - Returns `VerifyRegistration`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/auth/verify-registration/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Choices

### GET `/api/choices/approvalstatus`

**Summary**: List trip approval status choices

**Description**: Retrieve a paginated list of available approval statuses as choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/approvalstatus \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/carbrand`

**Summary**: List car brand choices

**Description**: Retrieve a paginated list of available car brands as choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/carbrand \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/countries`

**Summary**: List country choices

**Description**: Retrieve a paginated list of available countries as choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/countries \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/emirates`

**Summary**: List Emirates choices

**Description**: Retrieve a paginated list of available Emirates choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/emirates \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/gender`

**Summary**: List gender choices

**Description**: Retrieve a paginated list of available genders as choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/gender \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/permissionmatrixaction`

**Summary**: List permission matrix action choices

**Description**: Retrieve a paginated list of available permission matrix action choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/permissionmatrixaction \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/timeofday`

**Summary**: List time of day choices

**Description**: Retrieve a paginated list of available time of day choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/timeofday \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/triprequestarea`

**Summary**: List area choices for trip requests

**Description**: Retrieve a paginated list of available area choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/triprequestarea \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/upgraderequeststatus`

**Summary**: List upgrade request status choices

**Description**: Retrieve a paginated list of available upgrade request statuses as choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/upgraderequeststatus \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/choices/upgraderequestvote`

**Summary**: List upgrade request vote choices

**Description**: Retrieve a paginated list of available upgrade request vote choices.

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Choice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/choices/upgraderequestvote \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Clubnews

### GET `/api/clubnews/`

**Description**: API endpoint that allows club news to be viewed.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedClubNewsList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/clubnews/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/clubnews/{id}/`

**Description**: API endpoint that allows club news to be viewed.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this Club News.

**Responses**:

- `200`:  - Returns `ClubNews`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/clubnews/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Device

### GET `/api/device/fcm/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedFCMDeviceList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/device/fcm/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/device/fcm/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `FCMDeviceRequest`
  - `name`: string - Optional - 
  - `registrationId`: string - **Required** - 
  - `deviceId`: string - Optional - Unique device identifier
  - `active`: boolean - Optional - Inactive devices will not be sent notifications
  - `type`: string - **Required** - 

**Responses**:

- `201`:  - Returns `FCMDevice`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/device/fcm/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/device/fcm/{registration_id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `registrationId` (path) - string - **Required** - 

**Responses**:

- `200`:  - Returns `FCMDevice`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/device/fcm/{registration_id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/device/fcm/{registration_id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `registrationId` (path) - string - **Required** - 

**Request Body** (Required):

Schema: `FCMDeviceRequest`
  - `name`: string - Optional - 
  - `registrationId`: string - **Required** - 
  - `deviceId`: string - Optional - Unique device identifier
  - `active`: boolean - Optional - Inactive devices will not be sent notifications
  - `type`: string - **Required** - 

**Responses**:

- `200`:  - Returns `FCMDevice`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/device/fcm/{registration_id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/device/fcm/{registration_id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `registrationId` (path) - string - **Required** - 

**Request Body** (Optional):

Schema: `PatchedFCMDeviceRequest`
  - `name`: string - Optional - 
  - `registrationId`: string - Optional - 
  - `deviceId`: string - Optional - Unique device identifier
  - `active`: boolean - Optional - Inactive devices will not be sent notifications
  - `type`: string - Optional - 

**Responses**:

- `200`:  - Returns `FCMDevice`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/device/fcm/{registration_id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/device/fcm/{registration_id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `registrationId` (path) - string - **Required** - 

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/device/fcm/{registration_id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Faqs

### GET `/api/faqs/`

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Faq`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/faqs/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/faqs/{id}/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this faq entry.

**Responses**:

- `200`:  - Returns `Faq`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/faqs/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Feedback

### POST `/api/feedback/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `FeedbackRequest`
  - `feedbackType`: string - Optional - 
  - `message`: string - **Required** - 
  - `image`: string - Optional - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/feedback/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Globalsettings

### GET `/api/globalsettings/`

**Description**: API endpoint that allows configurable settings objects to be viewed and updated

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `ConfigurableSettings`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/globalsettings/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Groups

### GET `/api/groups/`

**Description**: API endpoint that allows groups to be viewed

**Authentication**: Optional JWT Authentication

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedGroupList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/groups/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/groups/{id}/`

**Description**: API endpoint that allows groups to be viewed

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this group.

**Responses**:

- `200`:  - Returns `Group`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/groups/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Levels

### GET `/api/levels/`

**Description**: API endpoint that allows trips to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `active` (query) - boolean - Optional - 
- `name` (query) - string - Optional - 
- `name_Icontains` (query) - string - Optional - 
- `numericLevel` (query) - integer - Optional - 
- `numericLevel_Range` (query) - array - Optional - Multiple values may be separated by commas.
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedLevelList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/levels/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/levels/{id}/`

**Description**: API endpoint that allows trips to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this level.

**Responses**:

- `200`:  - Returns `Level`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/levels/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Logbookentries

### GET `/api/logbookentries/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedLogbookEntryList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookentries/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/logbookentries/`

**Description**: Create a new logbook entry with custom DRF response format

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `LogbookEntryRequest`
  - `comment`: string - Optional - 
  - `trip`: integer - **Required** - 
  - `member`: integer - **Required** - 
  - `signedBy`: integer - Optional - 
  - `skillsVerified`: array - Optional - 

**Responses**:

- `201`:  - Returns `LogbookEntry`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/logbookentries/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/logbookentries/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this Logbook Entry.

**Responses**:

- `200`:  - Returns `LogbookEntry`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookentries/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/logbookentries/{id}/`

**Description**: Update a logbook entry with custom DRF response format

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this Logbook Entry.

**Request Body** (Required):

Schema: `LogbookEntryRequest`
  - `comment`: string - Optional - 
  - `trip`: integer - **Required** - 
  - `member`: integer - **Required** - 
  - `signedBy`: integer - Optional - 
  - `skillsVerified`: array - Optional - 

**Responses**:

- `200`:  - Returns `LogbookEntry`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/logbookentries/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/logbookentries/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this Logbook Entry.

**Request Body** (Optional):

Schema: `PatchedLogbookEntryRequest`
  - `comment`: string - Optional - 
  - `trip`: integer - Optional - 
  - `member`: integer - Optional - 
  - `signedBy`: integer - Optional - 
  - `skillsVerified`: array - Optional - 

**Responses**:

- `200`:  - Returns `LogbookEntry`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/logbookentries/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/logbookentries/{id}/`

**Description**: Delete a logbook entry with custom DRF response format

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this Logbook Entry.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/logbookentries/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Logbookskillreferences

### GET `/api/logbookskillreferences/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedLogbookSkillReferenceList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookskillreferences/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/logbookskillreferences/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `LogbookSkillReferenceRequest`
  - `logbookSkill`: integer - **Required** - 
  - `member`: integer - **Required** - 
  - `trip`: integer - **Required** - 

**Responses**:

- `201`:  - Returns `LogbookSkillReference`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/logbookskillreferences/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/logbookskillreferences/{id}/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this logbook skill reference.

**Responses**:

- `200`:  - Returns `LogbookSkillReference`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookskillreferences/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/logbookskillreferences/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this logbook skill reference.

**Request Body** (Required):

Schema: `LogbookSkillReferenceRequest`
  - `logbookSkill`: integer - **Required** - 
  - `member`: integer - **Required** - 
  - `trip`: integer - **Required** - 

**Responses**:

- `200`:  - Returns `LogbookSkillReference`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/logbookskillreferences/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/logbookskillreferences/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this logbook skill reference.

**Request Body** (Optional):

Schema: `PatchedLogbookSkillReferenceRequest`
  - `logbookSkill`: integer - Optional - 
  - `member`: integer - Optional - 
  - `trip`: integer - Optional - 

**Responses**:

- `200`:  - Returns `LogbookSkillReference`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/logbookskillreferences/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/logbookskillreferences/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this logbook skill reference.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/logbookskillreferences/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Logbookskills

### GET `/api/logbookskills/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `levelEq` (query) - integer - Optional - Level ID equal to
- `levelGte` (query) - integer - Optional - Level ID greater than or equal to
- `levelLte` (query) - integer - Optional - Level ID less than or equal to
- `levelNull` (query) - boolean - Optional - Level reference is null
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedLogbookSkillList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookskills/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/logbookskills/{id}/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this logbook skill.

**Responses**:

- `200`:  - Returns `LogbookSkill`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/logbookskills/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Meetingpoints

### GET `/api/meetingpoints/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `area` (query) - string - Optional - * `DXB` - Dubai
* `NOR` - Northern Emirates
* `AUH` - Abu Dhabi
* `AAN` - Al Ain
* `LIW` - Liwa
- `name` (query) - string - Optional - 
- `name_Icontains` (query) - string - Optional - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedMeetingPointList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/meetingpoints/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/meetingpoints/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `MeetingPointRequest`
  - `name`: string - **Required** - 
  - `lat`: string - Optional - 
  - `lon`: string - Optional - 
  - `link`: string - Optional - 
  - `area`: string - Optional - 

**Responses**:

- `201`:  - Returns `MeetingPoint`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/meetingpoints/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/meetingpoints/{id}/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this meeting point.

**Responses**:

- `200`:  - Returns `MeetingPoint`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/meetingpoints/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/meetingpoints/{id}/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this meeting point.

**Request Body** (Optional):

Schema: `EditMeetingPointRequest`
  - `name`: string - Optional - 
  - `lat`: string - Optional - 
  - `lon`: string - Optional - 
  - `link`: string - Optional - 
  - `area`: string - Optional - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/meetingpoints/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/meetingpoints/{id}/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this meeting point.

**Request Body** (Optional):

Schema: `PatchedEditMeetingPointRequest`
  - `name`: string - Optional - 
  - `lat`: string - Optional - 
  - `lon`: string - Optional - 
  - `link`: string - Optional - 
  - `area`: string - Optional - 

**Responses**:

- `200`:  - Returns `EditMeetingPoint`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/meetingpoints/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/meetingpoints/{id}/`

**Description**: API endpoint that allows meeting points to be viewed or edited.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this meeting point.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/meetingpoints/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Members

### GET `/api/members/`

**Description**: This viewset automatically provides `list` and `detail` actions.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `carBrand` (query) - string - Optional - * `AB` - Abarth
* `AR` - Alfa Romeo
* `AM` - Aston Martin
* `AU` - Audi
* `BE` - Bentley
* `BM` - BMW
* `BU` - Bugatti
* `BY` - BYD
* `CA` - Cadillac
* `CH` - Chery
* `CV` - Chevrolet
* `CR` - Chrysler
* `CI` - Citroën
* `DA` - Dacia
* `DW` - Daewoo
* `DH` - Daihatsu
* `DO` - Dodge
* `DN` - Donkervoort
* `DS` - DS
* `FE` - Ferrari
* `FI` - Fiat
* `FK` - Fisker
* `FO` - Ford
* `GE` - Geely
* `HO` - Honda
* `HU` - Hummer
* `HY` - Hyundai
* `IN` - Infiniti
* `IV` - Iveco
* `JA` - Jaguar
* `JE` - Jeep
* `JT` - Jetour
* `KI` - Kia
* `KT` - KTM
* `LA` - Lada
* `LM` - Lamborghini
* `LN` - Lancia
* `LR` - Land Rover
* `LW` - Landwind
* `LE` - Lexus
* `LO` - Lotus
* `MA` - Maserati
* `MB` - Maybach
* `MZ` - Mazda
* `MC` - McLaren
* `ME` - Mercedes-Benz
* `MG` - MG
* `MI` - Mini
* `MT` - Mitsubishi
* `MO` - Morgan
* `NI` - Nissan
* `OP` - Opel
* `PE` - Peugeot
* `PO` - Porsche
* `RE` - Renault
* `RR` - Rolls-Royce
* `RO` - Rover
* `SA` - Saab
* `SE` - Seat
* `SK` - Skoda
* `SM` - Smart
* `SS` - SsangYong
* `SU` - Subaru
* `SZ` - Suzuki
* `TE` - Tesla
* `TO` - Toyota
* `VW` - Volkswagen
* `VO` - Volvo
* `OT` - Other
- `carBrand_Icontains` (query) - string - Optional - 
- `carYear` (query) - integer - Optional - 
- `carYear_Range` (query) - array - Optional - Multiple values may be separated by commas.
- `city` (query) - string - Optional - 
- `email` (query) - string - Optional - 
- `email_Icontains` (query) - string - Optional - 
- `firstName` (query) - string - Optional - 
- `firstName_Icontains` (query) - string - Optional - 
- `lastName` (query) - string - Optional - 
- `lastName_Icontains` (query) - string - Optional - 
- `level_Name` (query) - string - Optional - 
- `level_Name_Icontains` (query) - string - Optional - 
- `level_NumericLevel` (query) - integer - Optional - 
- `level_NumericLevel_Range` (query) - array - Optional - Multiple values may be separated by commas.
- `nationality` (query) - string - Optional - * `AF` - Afghanistan
* `AL` - Albania
* `DZ` - Algeria
* `AS` - American Samoa
* `AD` - Andorra
* `AO` - Angola
* `AI` - Anguilla
* `AQ` - Antarctica
* `AG` - Antigua and Barbuda
* `AR` - Argentina
* `AM` - Armenia
* `AW` - Aruba
* `AU` - Australia
* `AT` - Austria
* `AZ` - Azerbaijan
* `BS` - Bahamas
* `BH` - Bahrain
* `BD` - Bangladesh
* `BB` - Barbados
* `BY` - Belarus
* `BE` - Belgium
* `BZ` - Belize
* `BJ` - Benin
* `BM` - Bermuda
* `BT` - Bhutan
* `BO` - Bolivia, Plurinational State of
* `BQ` - Bonaire, Sint Eustatius and Saba
* `BA` - Bosnia and Herzegovina
* `BW` - Botswana
* `BR` - Brazil
* `IO` - British Indian Ocean Territory
* `BN` - Brunei Darussalam
* `BG` - Bulgaria
* `BF` - Burkina Faso
* `BI` - Burundi
* `KH` - Cambodia
* `CM` - Cameroon
* `CA` - Canada
* `CV` - Cape Verde
* `KY` - Cayman Islands
* `CF` - Central African Republic
* `TD` - Chad
* `CL` - Chile
* `CN` - China
* `CO` - Colombia
* `KM` - Comoros
* `CG` - Congo
* `CD` - Congo, the Democratic Republic of the
* `CK` - Cook Islands
* `CR` - Costa Rica
* `CI` - Côte d'Ivoire
* `HR` - Croatia
* `CU` - Cuba
* `CW` - Curaçao
* `CY` - Cyprus
* `CZ` - Czech Republic
* `DK` - Denmark
* `DJ` - Djibouti
* `DM` - Dominica
* `DO` - Dominican Republic
* `EC` - Ecuador
* `EG` - Egypt
* `SV` - El Salvador
* `GQ` - Equatorial Guinea
* `ER` - Eritrea
* `EE` - Estonia
* `ET` - Ethiopia
* `FK` - Falkland Islands (Malvinas)
* `FO` - Faroe Islands
* `FJ` - Fiji
* `FI` - Finland
* `FR` - France
* `GF` - French Guiana
* `PF` - French Polynesia
* `GA` - Gabon
* `GM` - Gambia
* `GE` - Georgia
* `DE` - Germany
* `GH` - Ghana
* `GI` - Gibraltar
* `GR` - Greece
* `GL` - Greenland
* `GD` - Grenada
* `GP` - Guadeloupe
* `GU` - Guam
* `GT` - Guatemala
* `GG` - Guernsey
* `GN` - Guinea
* `GW` - Guinea-Bissau
* `GY` - Guyana
* `HT` - Haiti
* `VA` - Holy See (Vatican City State)
* `HN` - Honduras
* `HK` - Hong Kong
* `HU` - Hungary
* `IS` - Iceland
* `IN` - India
* `ID` - Indonesia
* `IR` - Iran, Islamic Republic of
* `IQ` - Iraq
* `IE` - Ireland
* `IM` - Isle of Man
* `IL` - Israel
* `IT` - Italy
* `JM` - Jamaica
* `JP` - Japan
* `JE` - Jersey
* `JO` - Jordan
* `KZ` - Kazakhstan
* `KE` - Kenya
* `KI` - Kiribati
* `KP` - Korea, Democratic People's Republic of
* `KR` - Korea, Republic of
* `KW` - Kuwait
* `KG` - Kyrgyzstan
* `LA` - Lao People's Democratic Republic
* `LV` - Latvia
* `LB` - Lebanon
* `LS` - Lesotho
* `LR` - Liberia
* `LY` - Libya
* `LI` - Liechtenstein
* `LT` - Lithuania
* `LU` - Luxembourg
* `MO` - Macao
* `MK` - Macedonia, the Former Yugoslav Republic of
* `MG` - Madagascar
* `MW` - Malawi
* `MY` - Malaysia
* `MV` - Maldives
* `ML` - Mali
* `MT` - Malta
* `MH` - Marshall Islands
* `MQ` - Martinique
* `MR` - Mauritania
* `MU` - Mauritius
* `YT` - Mayotte
* `MX` - Mexico
* `FM` - Micronesia, Federated States of
* `MD` - Moldova, Republic of
* `MC` - Monaco
* `MN` - Mongolia
* `ME` - Montenegro
* `MS` - Montserrat
* `MA` - Morocco
* `MZ` - Mozambique
* `MM` - Myanmar
* `NA` - Namibia
* `NP` - Nepal
* `NL` - Netherlands
* `NC` - New Caledonia
* `NZ` - New Zealand
* `NI` - Nicaragua
* `NE` - Niger
* `NG` - Nigeria
* `NU` - Niue
* `NF` - Norfolk Island
* `MP` - Northern Mariana Islands
* `NO` - Norway
* `OM` - Oman
* `PK` - Pakistan
* `PW` - Palau
* `PS` - Palestine, State of
* `PA` - Panama
* `PG` - Papua New Guinea
* `PY` - Paraguay
* `PE` - Peru
* `PH` - Philippines
* `PL` - Poland
* `PT` - Portugal
* `PR` - Puerto Rico
* `QA` - Qatar
* `RE` - Réunion
* `RO` - Romania
* `RU` - Russian Federation
* `RW` - Rwanda
* `BL` - Saint Barthélemy
* `SH` - Saint Helena, Ascension and Tristan da Cunha
* `KN` - Saint Kitts and Nevis
* `LC` - Saint Lucia
* `MF` - Saint Martin (French part)
* `PM` - Saint Pierre and Miquelon
* `VC` - Saint Vincent and the Grenadines
* `WS` - Samoa
* `SM` - San Marino
* `ST` - Sao Tome and Principe
* `SA` - Saudi Arabia
* `SN` - Senegal
* `RS` - Serbia
* `SC` - Seychelles
* `SL` - Sierra Leone
* `SG` - Singapore
* `SX` - Sint Maarten (Dutch part)
* `SK` - Slovakia
* `SI` - Slovenia
* `SB` - Solomon Islands
* `SO` - Somalia
* `ZA` - South Africa
* `SS` - South Sudan
* `ES` - Spain
* `LK` - Sri Lanka
* `SD` - Sudan
* `SR` - Suriname
* `SJ` - Svalbard and Jan Mayen
* `SZ` - Eswatini
* `SE` - Sweden
* `CH` - Switzerland
* `SY` - Syrian Arab Republic
* `TW` - Taiwan, Province of China
* `TJ` - Tajikistan
* `TZ` - Tanzania, United Republic of
* `TH` - Thailand
* `TL` - Timor-Leste
* `TG` - Togo
* `TO` - Tonga
* `TT` - Trinidad and Tobago
* `TN` - Tunisia
* `TR` - Turkey
* `TM` - Turkmenistan
* `TC` - Turks and Caicos Islands
* `UG` - Uganda
* `UA` - Ukraine
* `AE` - United Arab Emirates
* `GB` - United Kingdom
* `US` - United States
* `UY` - Uruguay
* `UZ` - Uzbekistan
* `VU` - Vanuatu
* `VE` - Venezuela, Bolivarian Republic of
* `VN` - Viet Nam
* `VG` - Virgin Islands, British
* `VI` - Virgin Islands, U.S.
* `WF` - Wallis and Futuna
* `EH` - Western Sahara
* `YE` - Yemen
* `ZM` - Zambia
* `ZW` - Zimbabwe
* `XX` - Other
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `phone` (query) - string - Optional - 
- `phone_Icontains` (query) - string - Optional - 
- `tripCount` (query) - integer - Optional - 
- `tripCount_Range` (query) - array - Optional - Multiple values may be separated by commas.

**Responses**:

- `200`:  - Returns `PaginatedBasicMemberList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/`

**Description**: This viewset automatically provides `list` and `detail` actions.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this user.

**Responses**:

- `200`:  - Returns `Profile`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/members/{id}/`

**Description**: This viewset automatically provides `list` and `detail` actions.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this user.

**Request Body** (Optional):

Schema: `EditMemberRequest`
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carYear`: integer - Optional - 
  - `carColor`: string - Optional - 
  - `carImage`: string - Optional - 
  - `city`: string - Optional - 
  - `tripCount`: integer - Optional - 
  - `dob`: string - Optional - 
  - `iceName`: string - Optional - 
  - `icePhone`: string - Optional - 
  - `gender`: string - Optional - 
  - `nationality`: string - Optional - 
  - `avatar`: string - Optional - 
  - `paidMember`: boolean - Optional - 
  - `title`: string - Optional - 
  - `groups`: array - Optional - The groups this user belongs to. A user will get all permissions granted to each of their groups.
  - `userPermissions`: array - Optional - Specific permissions for this user.

**Responses**:

- `200`:  - Returns `EditMember`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/members/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/members/{id}/`

**Description**: This viewset automatically provides `list` and `detail` actions.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this user.

**Request Body** (Optional):

Schema: `PatchedBasicMemberRequest`
  - `username`: string - Optional - 
  - `firstName`: string - Optional - 
  - `lastName`: string - Optional - 
  - `phone`: string - Optional - 
  - `tripCount`: integer - Optional - 
  - `carBrand`: string - Optional - 
  - `carModel`: string - Optional - 
  - `carColor`: string - Optional - 
  - `carImage`: string - Optional - 
  - `email`: string - Optional - 
  - `paidMember`: boolean - Optional - 

**Responses**:

- `200`:  - Returns `BasicMember`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/members/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/members/{id}/feedback`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedFeedbackList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/feedback \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/logbookentries`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedListLogbookEntryList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/logbookentries \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/logbookskills`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedMemberLogbookSkillReferenceList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/logbookskills \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/members/{id}/payments`

**Description**: Manually update the paidMember field for a member. Only available to users with the EDIT_MEMBERSHIP_PAYMENTS permission.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `MembershipPaymentRequest`
  - `paymentReceived`: boolean - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/members/{id}/payments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/members/{id}/tripcounts`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `200`:  - Returns `DetailedTripStatsOverview`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/tripcounts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/triphistory`

**Description**: Shared logic for member trip history views

**Authentication**: JWT Authentication Required

**Parameters**:

- `checkedIn` (query) - boolean - Optional - Include only trips where member is checked in
- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedMemberTripHistoryList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/triphistory \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/triprequests`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedListMemberTripRequestList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/triprequests \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/{id}/upgraderequests`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedMemberUpgradeHistoryList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/{id}/upgraderequests \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/activetripleads`

**Authentication**: JWT Authentication Required

**Parameters**:

- `level` (query) - integer - Optional - Level for filtering to include only leads for trips for a specific level
- `maxNumericLevel` (query) - integer - Optional - Level for filtering to include only leads for trips of at most a given level
- `minNumericLevel` (query) - integer - Optional - Level for filtering to include only leads for trips of at least a given level

**Responses**:

- `200`:  - Returns array of `BasicMember`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/activetripleads \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/members/leadsearch`

**Authentication**: JWT Authentication Required

**Parameters**:

- `level` (query) - integer - Optional - Level for filtering to include only members that have permission to lead for a given level
- `search` (query) - string - Optional - Search term - will search in username first name and last name

**Responses**:

- `200`:  - Returns array of `BasicMember`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/members/leadsearch \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Notifications

### GET `/api/notifications/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedNotificationLogList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/notifications/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/notifications/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this notification log.

**Responses**:

- `200`:  - Returns `NotificationLog`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/notifications/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Permissionmatrix

### GET `/api/permissionmatrix/`

**Description**: API endpoint that allows permissions matrix objects to be viewed

**Authentication**: Optional JWT Authentication

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedPermissionMatrixList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/permissionmatrix/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/permissionmatrix/{id}/`

**Description**: API endpoint that allows permissions matrix objects to be viewed

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this permission matrix.

**Responses**:

- `200`:  - Returns `PermissionMatrix`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/permissionmatrix/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Schema

### GET `/api/schema/`

**Description**: OpenApi3 schema for this API. Format can be selected via content negotiation.

- YAML: application/vnd.oai.openapi
- JSON: application/vnd.oai.openapi+json

**Authentication**: Optional JWT Authentication

**Parameters**:

- `format` (query) - string - Optional - 
- `lang` (query) - string - Optional - 

**Responses**:

- `200`: 

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/schema/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Sponsors

### GET `/api/sponsors/`

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `Sponsorship`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/sponsors/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/sponsors/{id}/`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this sponsorship.

**Responses**:

- `200`:  - Returns `Sponsorship`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/sponsors/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Systemtime

### GET `/api/systemtime/`

**Authentication**: Optional JWT Authentication

**Responses**:

- `200`:  - Returns array of `SystemTime`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/systemtime/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Token

### POST `/api/token/`

**Description**: Takes a set of user credentials and returns an access and refresh JSON web
token pair to prove the authentication of those credentials.

**Authentication**: Public (No authentication required)

**Request Body** (Required):

Schema: `TokenObtainPairRequest`
  - `username`: string - **Required** - 
  - `password`: string - **Required** - 

**Responses**:

- `200`:  - Returns `TokenObtainPair`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/token/refresh/`

**Description**: Takes a refresh type JSON web token and returns an access type JSON web
token if the refresh token is valid.

**Authentication**: Public (No authentication required)

**Request Body** (Required):

Schema: `TokenRefreshRequest`
  - `refresh`: string - **Required** - 

**Responses**:

- `200`:  - Returns `TokenRefresh`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Tripcomments

### GET `/api/tripcomments/`

**Description**: API endpoint for managing trip comments.

**Authentication**: JWT Authentication Required

**Parameters**:

- `member` (query) - integer - Optional - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `trip` (query) - integer - Optional - 

**Responses**:

- `200`:  - Returns `PaginatedFullTripCommentList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/tripcomments/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/tripcomments/`

**Summary**: Create Trip Comment

**Description**: Create a new trip comment with the current user as author

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `CreateTripCommentRequest`
  - `comment`: string - **Required** - 
  - `trip`: integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/tripcomments/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/tripcomments/{id}/`

**Description**: API endpoint for managing trip comments.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip comment.

**Responses**:

- `200`:  - Returns `FullTripComment`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/tripcomments/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### DELETE `/api/tripcomments/{id}/`

**Description**: API endpoint for managing trip comments.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip comment.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/tripcomments/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Tripreports

### GET `/api/tripreports/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `member` (query) - integer - Optional - 
- `ordering` (query) - string - Optional - Which field to use when ordering the results.
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `trip` (query) - integer - Optional - 

**Responses**:

- `200`:  - Returns `PaginatedTripReportListList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/tripreports/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/tripreports/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `TripReportRequest`
  - `trip`: integer - **Required** - 
  - `title`: string - **Required** - 
  - `reportText`: string - **Required** - 
  - `trackFile`: string - Optional - 
  - `trackImage`: string - Optional - 
  - `imageFiles`: array - Optional - 

**Responses**:

- `201`:  - Returns `TripReport`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/tripreports/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/tripreports/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip report.

**Responses**:

- `200`:  - Returns `TripReport`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/tripreports/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/tripreports/{id}/`

**Description**: Update trip report

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip report.

**Request Body** (Required):

Schema: `TripReportRequest`
  - `trip`: integer - **Required** - 
  - `title`: string - **Required** - 
  - `reportText`: string - **Required** - 
  - `trackFile`: string - Optional - 
  - `trackImage`: string - Optional - 
  - `imageFiles`: array - Optional - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/tripreports/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/tripreports/{id}/`

**Description**: Update trip report

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip report.

**Request Body** (Optional):

Schema: `PatchedTripReportRequest`
  - `trip`: integer - Optional - 
  - `title`: string - Optional - 
  - `reportText`: string - Optional - 
  - `trackFile`: string - Optional - 
  - `trackImage`: string - Optional - 
  - `imageFiles`: array - Optional - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/tripreports/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/tripreports/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip report.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/tripreports/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Triprequests

### GET `/api/triprequests/`

**Description**: API endpoint that allows trip requests to be viewed, created or deleted

**Authentication**: Optional JWT Authentication

**Parameters**:

- `area` (query) - string - Optional - * `DXB` - Dubai
* `NOR` - Northern Emirates
* `AUH` - Abu Dhabi
* `AAN` - Al Ain
* `LIW` - Liwa
- `level` (query) - integer - Optional - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `timeOfDay` (query) - string - Optional - * `MOR` - Morning
* `MID` - Mid-day
* `AFT` - Afternoon
* `EVE` - Evening
* `ANY` - Any

**Responses**:

- `200`:  - Returns `PaginatedListTripRequestList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/triprequests/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/triprequests/`

**Description**: API endpoint that allows trip requests to be viewed, created or deleted

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `CreateNewTripRequestRequest`
  - `date`: string - **Required** - 
  - `level`: integer - Optional - 
  - `timeOfDay`: string - Optional - 
  - `area`: string - Optional - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/triprequests/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/triprequests/{id}/`

**Description**: API endpoint that allows trip requests to be viewed, created or deleted

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip request.

**Responses**:

- `200`:  - Returns `TripRequest`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/triprequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### DELETE `/api/triprequests/{id}/`

**Description**: API endpoint that allows trip requests to be viewed, created or deleted

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip request.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/triprequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/triprequests/aggregate`

**Summary**: Get aggregated trip request vote counts

**Description**: Returns a list of aggregated vote counts for trip requests, grouped by the specified fields (area, date, level, time_of_day). If no fields are selected, returns the total count of trip requests.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `firstSort` (query) - string - Optional - Comma-separated list of fields to sort by.
- `includeArea` (query) - boolean - Optional - Include 'area' in the grouping.
- `includeDate` (query) - boolean - Optional - Include 'date' in the grouping.
- `includeLevel` (query) - boolean - Optional - Include 'level' in the grouping.
- `includeTimeOfDay` (query) - boolean - Optional - Include 'time_of_day' in the grouping.
- `secondSort` (query) - string - Optional - Comma-separated list of fields to sort by.
- `thirdSort` (query) - string - Optional - Comma-separated list of fields to sort by.

**Responses**:

- `200`:  - Returns array

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/triprequests/aggregate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/triprequests/export`

**Description**: Export trip requests as CSV file in matrix format

**Authentication**: JWT Authentication Required

**Parameters**:

- `endDate` (query) - string - Optional - End date for filtering requests (YYYY-MM-DD format)
- `startDate` (query) - string - Optional - Start date for filtering requests (YYYY-MM-DD format)

**Responses**:

- `200`: 

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/triprequests/export \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Trips

### POST `/api/trips`

**Description**: Approval status will depend on request user permissions. If user has permission to post a trip for the given level without approval, the trip will be automatically approved. If user has permission to post trip with approval, then trip will be in pending state.

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `CreateTripRequest`
  - `lead`: integer - **Required** - 
  - `deputyLeads`: array - Optional - 
  - `level`: integer - **Required** - 
  - `meetingPoint`: integer - Optional - 
  - `image`: string - Optional - 
  - `title`: string - **Required** - 
  - `description`: string - **Required** - 
  - `startTime`: string - **Required** - 
  - `endTime`: string - **Required** - 
  - `cutOff`: string - **Required** - 
  - `capacity`: integer - Optional - 
  - `allowWaitlist`: boolean - Optional - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/trips/`

**Description**: API endpoint that allows trips to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `approvalStatus` (query) - string - Optional - * `P` - Pending Approval
* `A` - Approved
* `R` - Rejected
* `D` - Deleted
- `cutOffAfter` (query) - string - Optional - 
- `cutOffBefore` (query) - string - Optional - 
- `deputyLeads` (query) - array - Optional - 
- `endTimeAfter` (query) - string - Optional - 
- `endTimeBefore` (query) - string - Optional - 
- `lead` (query) - integer - Optional - 
- `level_Id` (query) - integer - Optional - 
- `level_NumericLevel` (query) - integer - Optional - 
- `level_NumericLevel_Range` (query) - array - Optional - Multiple values may be separated by commas.
- `meetingPoint` (query) - integer - Optional - 
- `meetingPoint_Area` (query) - string - Optional - * `DXB` - Dubai
* `NOR` - Northern Emirates
* `AUH` - Abu Dhabi
* `AAN` - Al Ain
* `LIW` - Liwa
- `ordering` (query) - string - Optional - Which field to use when ordering the results.
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `startTimeAfter` (query) - string - Optional - 
- `startTimeBefore` (query) - string - Optional - 

**Responses**:

- `200`:  - Returns `PaginatedListTripList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/trips/{id}`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Optional):

Schema: `UpdateTripRequest`
  - `lead`: integer - Optional - 
  - `deputyLeads`: array - Optional - 
  - `level`: integer - Optional - 
  - `startTime`: string - Optional - 
  - `endTime`: string - Optional - 
  - `cutOff`: string - Optional - 
  - `title`: string - Optional - 
  - `description`: string - Optional - 
  - `capacity`: integer - Optional - 
  - `image`: string - Optional - 
  - `meetingPoint`: integer - Optional - 
  - `allowWaitlist`: boolean - Optional - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/trips/{id} \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/trips/{id}`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Optional):

Schema: `PatchedUpdateTripRequest`
  - `lead`: integer - Optional - 
  - `deputyLeads`: array - Optional - 
  - `level`: integer - Optional - 
  - `startTime`: string - Optional - 
  - `endTime`: string - Optional - 
  - `cutOff`: string - Optional - 
  - `title`: string - Optional - 
  - `description`: string - Optional - 
  - `capacity`: integer - Optional - 
  - `image`: string - Optional - 
  - `meetingPoint`: integer - Optional - 
  - `allowWaitlist`: boolean - Optional - 

**Responses**:

- `200`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/trips/{id} \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/trips/{id}`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/trips/{id} \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/trips/{id}/`

**Description**: API endpoint that allows trips to be viewed or edited.

**Authentication**: Optional JWT Authentication

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this trip.

**Responses**:

- `200`:  - Returns `RetrieveTrip`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/addfromwaitlist`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `AddMemberFromWaitlistRequest`
  - `member`: integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/addfromwaitlist \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/trips/{id}/approve`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/approve \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/checkin`

**Description**: Check-in members for a trip. !WARNING: In Swagger you will only get failed ID's returned if sending application/json request!

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `TripCheckInOutRequestRequest`
  - `members`: array - **Required** - 

**Responses**:

- `201`:  - Returns `TripCheckInOutResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/checkin \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/trips/{id}/checkout`

**Description**: Check-out members for a trip. !WARNING: In Swagger you will only get failed ID's returned if sending application/json request!

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `TripCheckInOutRequestRequest`
  - `members`: array - **Required** - 

**Responses**:

- `201`:  - Returns `TripCheckInOutResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/checkout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/trips/{id}/comments`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `ordering` (query) - string - Optional - Which field to use when ordering the results.
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedTripCommentList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/{id}/comments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/decline`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/decline \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/trips/{id}/exportregistrants`

**Description**: Export trip registrants as CSV file

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `200`: 

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/{id}/exportregistrants \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/forceregister`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `ForceRegisterForTripRequest`
  - `member`: integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/forceregister \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/trips/{id}/register`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/removemember`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `CancelTripRegistrationRequest`
  - `member`: integer - **Required** - 
  - `reason`: string - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/removemember \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/trips/{id}/tripreports`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedTripReportList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/{id}/tripreports \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/unregister`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/unregister \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/trips/{id}/viewlogbooks`

**Description**: API endpoint that provides a list of members checked in to a trip,
along with their associated logbook entry if one exists.

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `200`:  - Returns `TripViewLogbookMember`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/trips/{id}/viewlogbooks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/trips/{id}/waitlist`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`: No response body

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/trips/{id}/waitlist \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/trips/{trip_id}/logbook-entries`

**Authentication**: JWT Authentication Required

**Parameters**:

- `tripId` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `SignLogbookEntryRequest`
  - `member`: integer - **Required** - 
  - `comment`: string - **Required** - 
  - `skillsVerified`: array - Optional - 

**Responses**:

- `200`:  - Returns `SignLogbookEntry`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/trips/{trip_id}/logbook-entries \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Upgraderequestcomments

### GET `/api/upgraderequestcomments/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `author` (query) - integer - Optional - 
- `createdAfter` (query) - string - Optional - 
- `createdBefore` (query) - string - Optional - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `upgradeRequest` (query) - integer - Optional - 

**Responses**:

- `200`:  - Returns `PaginatedListUpgradeRequestCommentList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequestcomments/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/upgraderequestcomments/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `CreateUpgradeRequestCommentRequest`
  - `upgradeRequest`: integer - **Required** - 
  - `text`: string - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/upgraderequestcomments/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/upgraderequestcomments/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this upgrade request comment.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/upgraderequestcomments/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Upgraderequests

### GET `/api/upgraderequests/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `applicant` (query) - integer - Optional - 
- `createdAfter` (query) - string - Optional - 
- `createdBefore` (query) - string - Optional - 
- `nominatedVoters` (query) - array - Optional - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.
- `status` (query) - string - Optional - * `N` - New
* `I` - In Progress
* `A` - Approved
* `D` - Declined
- `verdictDateAfter` (query) - string - Optional - 
- `verdictDateBefore` (query) - string - Optional - 

**Responses**:

- `200`:  - Returns `PaginatedListUpgradeRequestList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/upgraderequests/`

**Authentication**: JWT Authentication Required

**Request Body** (Required):

Schema: `CreateUpgradeRequestRequest`
  - `targetLevel`: integer - **Required** - 
  - `applicant`: integer - **Required** - 
  - `nominatedVoters`: array - **Required** - 
  - `autoGroup`: integer - Optional - 
  - `applicantReason`: string - Optional - 
  - `attachment`: string - Optional - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/upgraderequests/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/upgraderequests/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this upgrade request.

**Responses**:

- `200`:  - Returns `ListUpgradeRequest`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### PUT `/api/upgraderequests/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this upgrade request.

**Request Body** (Optional):

Schema: `UpdateUpgradeRequestRequest`
  - `targetLevel`: integer - Optional - 
  - `status`: string - Optional - 
  - `verdictDate`: string - Optional - 
  - `verdictReason`: string - Optional - 
  - `attachment`: string - Optional - 
  - `finalApprover`: integer - Optional - 
  - `nominatedVoters`: array - Optional - 

**Responses**:

- `200`:  - Returns `UpdateUpgradeRequest`

**Example Request**:
```bash
curl -X PUT \
  http://localhost:8000/api/upgraderequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### PATCH `/api/upgraderequests/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this upgrade request.

**Request Body** (Optional):

Schema: `PatchedUpdateUpgradeRequestRequest`
  - `targetLevel`: integer - Optional - 
  - `status`: string - Optional - 
  - `verdictDate`: string - Optional - 
  - `verdictReason`: string - Optional - 
  - `attachment`: string - Optional - 
  - `finalApprover`: integer - Optional - 
  - `nominatedVoters`: array - Optional - 

**Responses**:

- `200`:  - Returns `UpdateUpgradeRequest`

**Example Request**:
```bash
curl -X PATCH \
  http://localhost:8000/api/upgraderequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### DELETE `/api/upgraderequests/{id}/`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - A unique integer value identifying this upgrade request.

**Responses**:

- `204`: No response body

**Example Request**:
```bash
curl -X DELETE \
  http://localhost:8000/api/upgraderequests/{id}/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/upgraderequests/{id}/approve`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/upgraderequests/{id}/approve \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/upgraderequests/{id}/comments`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 
- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedListUpgradeRequestCommentConciseList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/{id}/comments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### POST `/api/upgraderequests/{id}/decline`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `UpgradeRequestRejectRequest`
  - `verdictReason`: string - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/upgraderequests/{id}/decline \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### POST `/api/upgraderequests/{id}/vote`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Request Body** (Required):

Schema: `UpgradeRequestVoteRequest`
  - `vote`: string - **Required** - 

**Responses**:

- `201`:  - Returns `UnifiedResponse`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/upgraderequests/{id}/vote \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

### GET `/api/upgraderequests/{id}/voted`

**Authentication**: JWT Authentication Required

**Parameters**:

- `id` (path) - integer - **Required** - 

**Responses**:

- `200`:  - Returns `InlineOneOff`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/{id}/voted \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/upgraderequests/latestapproved`

**Authentication**: Optional JWT Authentication

**Parameters**:

- `page` (query) - integer - Optional - A page number within the paginated result set.
- `pageSize` (query) - integer - Optional - Number of results to return per page.

**Responses**:

- `200`:  - Returns `PaginatedListUpgradeRequestConciseList`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/latestapproved \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

### GET `/api/upgraderequests/voted`

**Authentication**: JWT Authentication Required

**Responses**:

- `200`:  - Returns `ListUpgradeRequestUserHasVoted`

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/upgraderequests/voted \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
```

---

## Validators

### POST `/api/validators/`

**Authentication**: Optional JWT Authentication

**Request Body** (Optional):

Schema: `ValidatorRequest`
  - `email`: string - Optional - 
  - `username`: string - Optional - 
  - `phone`: string - Optional - 

**Responses**:

- `201`:  - Returns `Validator`

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/validators/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Data Schemas

This section documents the key data schemas used in the API.

### LogbookEntry

**Properties**:

- `id`: integer
- `comment`: string
- `trip`: integer
- `member`: integer
- `signedBy`: integer
- `skillsVerified`: Array of integer

---

### TripRegistration

**Properties**:

- `id`: integer
- `member`: Reference to BasicMember
- `registrationDate`: string
- `checkedIn`: boolean

---

### Level

**Properties**:

- `id`: integer
- `name`: string
- `numericLevel`: integer
- `displayName`: string
- `active`: boolean

---

### Group

**Properties**:

- `id`: integer
- `name`: string
- `permissions`: Array of integer

---

### MeetingPoint

**Properties**:

- `id`: integer
- `name`: string
- `lat`: string
- `lon`: string
- `link`: string
- `area`: unknown

---

### TripComment

**Properties**:

- `comment`: string
- `member`: unknown
- `trip`: integer
- `created`: string

---

### TripReport

**Properties**:

- `id`: integer
- `trip`: integer
- `title`: string
- `reportText`: string
- `trackFile`: string
- `trackImage`: string
- `images`: Array of TripReportImage
- `created`: string
- `member`: unknown

---

### ClubNews

**Properties**:

- `id`: integer
- `title`: string
- `content`: string
- `submitDate`: string
- `status`: Reference to ClubNewsStatusEnum
- `levels`: Array of integer
- `image`: string

---

### Feedback

**Properties**:

- `feedbackType`: Reference to FeedbackTypeEnum
- `message`: string
- `image`: string

---


---

## Practical Examples

This section provides complete, realistic examples for common use cases.

### Example 1: User Registration and Login Flow

#### Step 1: Register a New User
```bash
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+971501234567",
    "password": "SecurePassword123!",
    "password2": "SecurePassword123!",
    "car_brand": "TOYOTA",
    "car_model": "Land Cruiser",
    "car_color": "White",
    "car_year": 2020,
    "dob": "1990-05-15",
    "ice_name": "Jane Doe",
    "ice_phone": "+971507654321",
    "gender": "MALE",
    "nationality": "AE",
    "city": "Dubai"
  }'
```

**Response**:
```json
{
  "id": 123,
  "username": "john.doe",
  "email": "john.doe@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

#### Step 2: Verify Email (if required)
Check your email for verification link or use the verification endpoint with the signature received.

#### Step 3: Login
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "login": "john.doe",
    "password": "SecurePassword123!"
  }'
```

**Response**:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Step 4: Get Your Profile
```bash
curl -X GET http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

**Response**:
```json
{
  "id": 123,
  "username": "john.doe",
  "email": "john.doe@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+971501234567",
  "car_brand": "Toyota",
  "car_model": "Land Cruiser",
  "car_year": 2020,
  "car_color": "White",
  "level": {
    "id": 1,
    "name": "Level 1",
    "numericLevel": 1
  },
  "trip_count": 0,
  "paid_member": false,
  "permissions": []
}
```

---

### Example 2: Creating and Managing a Trip

#### Step 1: Get Available Levels
```bash
curl -X GET http://localhost:8000/api/levels/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 5,
  "results": [
    {
      "id": 1,
      "name": "Level 1",
      "numericLevel": 1,
      "displayName": "Beginner",
      "active": true
    },
    {
      "id": 2,
      "name": "Level 2",
      "numericLevel": 2,
      "displayName": "Intermediate",
      "active": true
    }
  ]
}
```

#### Step 2: Get Meeting Points
```bash
curl -X GET http://localhost:8000/api/meetingpoints/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 3,
  "results": [
    {
      "id": 1,
      "name": "ENOC Jebel Ali",
      "lat": "25.0123",
      "lon": "55.1234",
      "link": "https://maps.google.com/?q=25.0123,55.1234",
      "area": "DUBAI"
    }
  ]
}
```

#### Step 3: Create a New Trip
```bash
curl -X POST http://localhost:8000/api/trips \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "lead": 123,
    "deputyLeads": [124, 125],
    "level": 1,
    "meetingPoint": 1,
    "title": "Weekend Desert Safari",
    "description": "Easy desert drive suitable for beginners. We will explore the dunes near Al Qudra.",
    "startTime": "2024-12-15T07:00:00Z",
    "endTime": "2024-12-15T15:00:00Z",
    "cutOff": "2024-12-14T18:00:00Z",
    "capacity": 10,
    "allowWaitlist": true
  }'
```

**Response**:
```json
{
  "success": true,
  "message": {
    "id": 456,
    "title": "Weekend Desert Safari",
    "approval_status": "PENDING"
  }
}
```

#### Step 4: List Trips (with filters)
```bash
curl -X GET "http://localhost:8000/api/trips/?level=1&ordering=-start_time&page=1&pageSize=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 25,
  "next": "http://localhost:8000/api/trips/?page=2",
  "previous": null,
  "results": [
    {
      "id": 456,
      "title": "Weekend Desert Safari",
      "description": "Easy desert drive...",
      "startTime": "2024-12-15T07:00:00Z",
      "endTime": "2024-12-15T15:00:00Z",
      "cutOff": "2024-12-14T18:00:00Z",
      "capacity": 10,
      "lead": {
        "id": 123,
        "username": "john.doe",
        "firstName": "John",
        "lastName": "Doe"
      },
      "level": {
        "id": 1,
        "name": "Level 1",
        "numericLevel": 1
      },
      "registeredCount": 5,
      "waitlistCount": 2,
      "isRegistered": false,
      "isWaitlisted": false,
      "approvalStatus": "APPROVED"
    }
  ]
}
```

---

### Example 3: Trip Registration

#### Step 1: Register for a Trip
```bash
curl -X POST http://localhost:8000/api/trips/456/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Response**:
```json
{
  "success": true,
  "message": "registration_successful"
}
```

#### Step 2: Check Your Trip History
```bash
curl -X GET http://localhost:8000/api/members/123/triphistory \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 15,
  "results": [
    {
      "id": 456,
      "title": "Weekend Desert Safari",
      "startTime": "2024-12-15T07:00:00Z",
      "lead": {
        "id": 123,
        "username": "john.doe"
      },
      "level": {
        "id": 1,
        "name": "Level 1"
      },
      "checkedIn": false,
      "waitlist": false
    }
  ]
}
```

#### Step 3: Unregister from Trip (if needed)
```bash
curl -X POST http://localhost:8000/api/trips/456/unregister \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "PERSONAL",
    "comment": "Cannot make it due to family commitment"
  }'
```

**Response**:
```json
{
  "success": true,
  "message": "unregistration_successful"
}
```

---

### Example 4: Upgrade Requests

#### Step 1: Create an Upgrade Request
```bash
curl -X POST http://localhost:8000/api/upgraderequests/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requestedLevel": 2,
    "motivation": "I have completed 15 Level 1 trips and feel ready for more challenging terrain. I have practiced recovery techniques and understand convoy protocol."
  }'
```

**Response**:
```json
{
  "id": 789,
  "member": 123,
  "requestedLevel": 2,
  "currentLevel": 1,
  "status": "PENDING",
  "motivation": "I have completed 15 Level 1 trips...",
  "created": "2024-11-13T10:30:00Z"
}
```

#### Step 2: Vote on Upgrade Request (for eligible members)
```bash
curl -X POST http://localhost:8000/api/upgraderequests/789/vote \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "vote": "YES",
    "comment": "John has been a reliable member and is ready for Level 2"
  }'
```

**Response**:
```json
{
  "success": true,
  "message": "vote_registered"
}
```

#### Step 3: Check Upgrade Request Status
```bash
curl -X GET http://localhost:8000/api/upgraderequests/789/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "id": 789,
  "member": {
    "id": 123,
    "username": "john.doe",
    "firstName": "John",
    "lastName": "Doe"
  },
  "requestedLevel": {
    "id": 2,
    "name": "Level 2"
  },
  "currentLevel": {
    "id": 1,
    "name": "Level 1"
  },
  "status": "APPROVED",
  "motivation": "I have completed 15 Level 1 trips...",
  "votesSummary": {
    "yes": 12,
    "no": 1,
    "abstain": 2
  },
  "created": "2024-11-13T10:30:00Z"
}
```

---

### Example 5: Logbook Management

#### Step 1: Create Logbook Entry for a Trip
```bash
curl -X POST http://localhost:8000/api/trips/456/logbook-entries \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "member": 127,
    "comment": "Great performance on sand recovery. Showed good understanding of momentum and tire pressure.",
    "skillsVerified": [1, 3, 5]
  }'
```

**Response**:
```json
{
  "success": true,
  "message": {
    "id": 234,
    "trip": 456,
    "member": 127,
    "signedBy": 123,
    "comment": "Great performance on sand recovery...",
    "skillsVerified": [1, 3, 5]
  }
}
```

#### Step 2: Get Member's Logbook Entries
```bash
curl -X GET http://localhost:8000/api/members/127/logbookentries \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 8,
  "results": [
    {
      "id": 234,
      "trip": {
        "id": 456,
        "title": "Weekend Desert Safari"
      },
      "member": {
        "id": 127,
        "username": "sarah.smith"
      },
      "signedBy": {
        "id": 123,
        "username": "john.doe"
      },
      "comment": "Great performance on sand recovery...",
      "skillsVerified": [
        {
          "id": 1,
          "name": "Sand Recovery"
        },
        {
          "id": 3,
          "name": "Tire Pressure Management"
        }
      ]
    }
  ]
}
```

#### Step 3: Get Member's Skill Progress
```bash
curl -X GET http://localhost:8000/api/members/127/logbookskills \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "results": [
    {
      "skill": {
        "id": 1,
        "name": "Sand Recovery",
        "description": "Ability to recover stuck vehicle from sand"
      },
      "verificationCount": 5,
      "isVerified": true
    },
    {
      "skill": {
        "id": 2,
        "name": "Rock Crawling",
        "description": "Navigate rocky terrain safely"
      },
      "verificationCount": 2,
      "isVerified": false
    }
  ]
}
```

---

### Example 6: Search and Filters

#### Search Members
```bash
curl -X GET "http://localhost:8000/api/members/?search=john&ordering=username" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Filter Trips by Date Range
```bash
curl -X GET "http://localhost:8000/api/trips/?start_time__gte=2024-12-01&start_time__lte=2024-12-31&level=2" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Search for Trip Leads
```bash
curl -X GET "http://localhost:8000/api/members/leadsearch?search=john" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "results": [
    {
      "id": 123,
      "username": "john.doe",
      "firstName": "John",
      "lastName": "Doe",
      "level": {
        "id": 3,
        "name": "Level 3"
      }
    }
  ]
}
```

---

### Example 7: Feedback System

#### Submit Feedback
```bash
curl -X POST http://localhost:8000/api/feedback/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "feedbackType": "BUG",
    "message": "The trip registration button is not working on mobile devices.",
    "screenshot": null
  }'
```

**Response**:
```json
{
  "id": 567,
  "feedbackType": "BUG",
  "message": "The trip registration button...",
  "status": "SUBMITTED",
  "created": "2024-11-13T14:25:00Z"
}
```

---

### Example 8: Notifications

#### Get Notification Settings
```bash
curl -X GET http://localhost:8000/api/auth/profile/notificationsettings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "results": [
    {
      "notificationType": "TRIP_APPROVED",
      "enabled": true,
      "pushEnabled": true,
      "emailEnabled": false
    },
    {
      "notificationType": "TRIP_CANCELLED",
      "enabled": true,
      "pushEnabled": true,
      "emailEnabled": true
    }
  ]
}
```

#### Update Notification Settings
```bash
curl -X PATCH http://localhost:8000/api/auth/profile/notificationsettings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "notificationType": "TRIP_APPROVED",
      "enabled": true,
      "pushEnabled": true,
      "emailEnabled": true
    }
  ]'
```

#### Get Notification Log
```bash
curl -X GET "http://localhost:8000/api/notifications/?page=1&pageSize=20" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response**:
```json
{
  "count": 45,
  "results": [
    {
      "id": 890,
      "title": "Trip Approved",
      "message": "Your trip 'Weekend Desert Safari' has been approved",
      "notificationType": "TRIP_APPROVED",
      "read": false,
      "created": "2024-11-13T09:15:00Z",
      "relatedTrip": 456
    }
  ]
}
```

---

## Error Handling

The API uses standard HTTP status codes and returns detailed error messages.

### Common Error Responses

#### 400 Bad Request
```json
{
  "success": false,
  "message": {
    "field_name": ["This field is required."],
    "another_field": ["Invalid value."]
  }
}
```

#### 401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```

or

```json
{
  "detail": "Given token not valid for any token type"
}
```

#### 403 Forbidden
```json
{
  "success": false,
  "message": "no_permission_to_perform_action"
}
```

#### 404 Not Found
```json
{
  "detail": "Not found."
}
```

#### 422 Unprocessable Entity
```json
{
  "success": false,
  "message": "waitlist_enforced_globally"
}
```

#### 500 Internal Server Error
```json
{
  "error": "An unexpected error occurred. Please try again later."
}
```

---

## Rate Limiting

Currently, the API does not enforce rate limiting, but it may be added in future versions. Best practices:
- Cache responses when possible
- Use pagination for large datasets
- Avoid making excessive requests in short time periods

---

## Pagination

List endpoints support pagination with the following parameters:

- `page`: Page number (default: 1)
- `pageSize`: Results per page (default: varies by endpoint, typically 20-100)

Example response structure:
```json
{
  "count": 150,
  "next": "http://localhost:8000/api/trips/?page=2&pageSize=20",
  "previous": null,
  "results": [...]
}
```

---

## File Uploads

Endpoints that accept file uploads (images, track files, etc.) use `multipart/form-data` encoding.

### Example: Upload Trip Image
```bash
curl -X PATCH http://localhost:8000/api/trips/456/ \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "title=Updated Trip Title"
```

### Supported File Types
- **Images**: JPEG, PNG, GIF
- **Track Files**: GPX, KML
- **Documents**: PDF (for certain endpoints)

### File Size Limits
- Profile avatars: 5MB
- Car images: 5MB
- Trip images: 10MB
- Track files: 2MB

---

## Best Practices

1. **Always use HTTPS in production**
2. **Store JWT tokens securely** (not in localStorage for web apps)
3. **Refresh tokens before they expire**
4. **Handle token expiration gracefully**
5. **Use pagination for large datasets**
6. **Implement proper error handling**
7. **Validate data on the client side before sending**
8. **Use appropriate HTTP methods** (

---

## 🆕 New Endpoints (Added November 27, 2025)

**Testing Date**: 2025-11-27  
**Tested By**: Hani AMJ (Member ID: 10613)  
**Endpoints Count**: 13 (11 fully tested, 2 admin-only)  

The following endpoints were added in the latest API update and have been thoroughly tested:

## 🌍 Geocoding Endpoints

### POST `/api/geocoding/reverse/`

Convert latitude/longitude coordinates to human-readable location information.

**Authentication**: Required (Bearer Token)

**Request Body**:
```json
{
  "latitude": "25.0657",
  "longitude": "55.1713"
}
```

**Response** (Success - 200 OK):
```json
{
  "area": "Dubai, Al Thanyah 4",
  "city": "Dubai",
  "district": "Al Thanyah 4",
  "cached": false
}
```

**Use Cases**:
- Auto-detect area codes for meeting points
- Display location context in forms
- Validate GPS coordinates

**Testing Result**: ✅ **WORKING**

**Example Usage**:
```bash
curl -X POST "https://ap.ad4x4.com/api/geocoding/reverse/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude": "25.0657", "longitude": "55.1713"}'
```

---

## ⚙️ Settings Endpoints

### GET `/api/settings/here-maps-config/`

Retrieve HERE Maps integration configuration settings.

**Authentication**: Required (Bearer Token)

**Response** (Success - 200 OK):
```json
{
  "enabled": true,
  "selectedFields": ["city", "district"],
  "maxFields": 2,
  "availableFields": [
    "Place Name",
    "District",
    "City",
    "County",
    "Country",
    "Postal Code",
    "Full Address",
    "Category"
  ]
}
```

**Response Fields**:
- `enabled` (boolean): Whether HERE Maps is enabled globally
- `selectedFields` (array): Fields currently displayed to users
- `maxFields` (integer): Maximum number of fields that can be selected
- `availableFields` (array): All available field options

**Use Cases**:
- Configure HERE Maps display in mobile app
- Validate field selections
- Dynamic form rendering

**Testing Result**: ✅ **WORKING**

---

## 🔒 Global Settings Endpoints

### PUT `/api/globalsettings/{id}/`
### PATCH `/api/globalsettings/{id}/`

Update global application settings (full or partial update).

**Authentication**: Required (Bearer Token) + **Admin/Superuser Permissions**

**Access Control**:
- ❌ **Regular users**: 403 Forbidden
- ✅ **Admin/Superuser**: Full access

**PUT Request Example** (Full Update):
```json
{
  "emailSupportAddress": "support@ad4x4.com",
  "forceWaitlist": false,
  "enableAutoUpgradeOnCheckin": true,
  "hereMapsEnabled": true,
  "hereMapsApiBaseUrl": "https://revgeocode.search.hereapi.com/v1/revgeocode",
  "hereMapsSelectedFields": ["city", "district"],
  "hereMapsMaxFields": 2,
  "hereMapsCacheDuration": 1440,
  "hereMapsRequestTimeout": 10,
  "galleryApiUrl": "https://media.ad4x4.com",
  "galleryApiTimeout": 30
}
```

**PATCH Request Example** (Partial Update):
```json
{
  "emailSupportAddress": "newsupport@ad4x4.com"
}
```

**Error Response** (403 Forbidden):
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Testing Result**: 🔒 **RESTRICTED** (Tested with regular user account)

**Recommendation**: 
- Regular users should use `GET /api/globalsettings/` (read-only)
- Only superadmins can modify settings via API

---

## 👤 GDPR Compliance Endpoints

### POST `/api/members/request-deletion`

Request account deletion (GDPR "Right to be Forgotten" compliance).

**Authentication**: Required (Bearer Token)

**Request Body**: Empty object `{}`

**Response** (Success - 200 OK):
```json
{
  "success": true,
  "message": "deletion_request_submitted"
}
```

**Testing Result**: ✅ **WORKING**

**Workflow**:
1. User requests deletion via this endpoint
2. System flags account for deletion (scheduled process)
3. User can cancel deletion before processing

---

### GET `/api/members/deletion-request`

Retrieve the current user's account deletion request status.

**Authentication**: Required (Bearer Token)

**Request Body**: None (GET request)

**Response** (Success - 200 OK - Active deletion request exists):
```json
{
  "success": true,
  "message": {
    "id": 123,
    "requested_at": "2024-01-15T10:30:00Z",
    "scheduled_deletion_date": "2024-02-14T10:30:00Z",
    "status": "pending",
    "can_cancel": true
  }
}
```

**Response Fields**:
- `id` (integer): Deletion request ID
- `requested_at` (datetime): When the deletion was requested
- `scheduled_deletion_date` (datetime): When the account will be deleted (typically 30 days from request)
- `status` (string): Current status (`pending`, `processing`, `cancelled`)
- `can_cancel` (boolean): Whether the request can still be cancelled

**Response** (Not Found - 404 - No active deletion request):
```json
{
  "success": false,
  "message": "deletion_request_not_found"
}
```

**Testing Result**: ✅ **WORKING** - Returns 404 when no active deletion request

**Use Cases**:
- Check if user has pending deletion request
- Display deletion countdown to user
- Show/hide deletion-related UI elements
- GDPR transparency requirement

**Example Request**:
```bash
curl -X GET "https://ap.ad4x4.com/api/members/deletion-request" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### POST `/api/members/cancel-deletion`

Cancel a pending account deletion request.

**Authentication**: Required (Bearer Token)

**Request Body**: Empty object `{}`

**Response** (Success - 200 OK):
```json
{
  "success": true,
  "message": "deletion_request_cancelled"
}
```

**Testing Result**: ✅ **WORKING**

**Use Cases**:
- User changes mind about account deletion
- Accidental deletion request
- GDPR compliance - allow user to cancel before processing

**Complete GDPR Deletion Workflow**:
```bash
# 1. Check if deletion request exists
curl -X GET "https://ap.ad4x4.com/api/members/deletion-request" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 2. Request deletion
curl -X POST "https://ap.ad4x4.com/api/members/request-deletion" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'

# 3. Check deletion status again (should return pending request)
curl -X GET "https://ap.ad4x4.com/api/members/deletion-request" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 4. Cancel deletion (if needed)
curl -X POST "https://ap.ad4x4.com/api/members/cancel-deletion" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Related Endpoints**:
- `GET /api/members/deletion-request` - Check deletion status
- `POST /api/members/request-deletion` - Request account deletion
- `POST /api/members/cancel-deletion` - Cancel deletion request

---

## 📝 UI Strings Management Endpoints

Manage multilingual UI strings for web and mobile applications.

**Authentication**: Required (Bearer Token)

### GET `/api/strings/`

List all UI strings (paginated).

**Query Parameters**:
- `page` (integer): Page number
- `pageSize` (integer): Results per page

**Response** (Success - 200 OK):
```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

**Testing Result**: ✅ **WORKING** (Empty initially)

---

### POST `/api/strings/`

Create a new UI string entry.

**Request Body**:
```json
{
  "key": "test_welcome_message",
  "valuesEn": {
    "web": "Welcome to AD4x4 Off-Road Club!",
    "mobile": "Welcome to AD4x4!"
  },
  "valuesAr": {
    "web": "مرحبا بكم في نادي AD4x4 للطرق الوعرة!",
    "mobile": "مرحبا بكم في AD4x4!"
  }
}
```

**Response** (Success - 201 Created):
```json
{
  "key": "test_welcome_message",
  "valuesEn": {
    "web": "Welcome to AD4x4 Off-Road Club!",
    "mobile": "Welcome to AD4x4!"
  },
  "valuesAr": {
    "web": "مرحبا بكم في نادي AD4x4 للطرق الوعرة!",
    "mobile": "مرحبا بكم في AD4x4!"
  }
}
```

**Field Requirements**:
- `key` (string, required): Unique identifier (max 255 chars)
- `valuesEn` (object, required): English translations as JSON object
- `valuesAr` (object, optional): Arabic translations as JSON object

**Testing Result**: ✅ **WORKING**

---

### GET `/api/strings/{key}/`

Retrieve a specific UI string by key.

**Path Parameter**:
- `key` (string): The unique string key

**Response** (Success - 200 OK):
```json
{
  "key": "test_welcome_message",
  "values": {
    "web": "Welcome to AD4x4 Off-Road Club!",
    "mobile": "Welcome to AD4x4!"
  }
}
```

**Note**: Response uses `values` (singular) field that combines language-specific values.

**Testing Result**: ✅ **WORKING**

---

### PUT `/api/strings/{key}/`

Full update of a UI string entry.

**Request Body**:
```json
{
  "key": "test_welcome_message",
  "valuesEn": {
    "web": "Welcome to AD4x4 Off-Road Club - Updated!",
    "mobile": "Welcome to AD4x4 - Updated!"
  },
  "valuesAr": {
    "web": "مرحبا بكم - تحديث كامل!",
    "mobile": "مرحبا - تحديث!"
  }
}
```

**Response** (Success - 200 OK):
```json
{
  "key": "test_welcome_message",
  "valuesEn": {
    "web": "Welcome to AD4x4 Off-Road Club - Updated!",
    "mobile": "Welcome to AD4x4 - Updated!"
  },
  "valuesAr": {
    "web": "مرحبا بكم - تحديث كامل!",
    "mobile": "مرحبا - تحديث!"
  }
}
```

**Testing Result**: ✅ **WORKING**

---

### PATCH `/api/strings/{key}/`

Partial update of a UI string entry.

**Request Body** (Update only English values):
```json
{
  "valuesEn": {
    "web": "Welcome to AD4x4 - Patched!",
    "mobile": "Welcome - Patched!"
  }
}
```

**Response** (Success - 200 OK):
```json
{
  "key": "test_welcome_message",
  "valuesEn": {
    "web": "Welcome to AD4x4 - Patched!",
    "mobile": "Welcome - Patched!"
  },
  "valuesAr": {
    "web": "مرحبا بكم - تحديث كامل!",
    "mobile": "مرحبا - تحديث!"
  }
}
```

**Testing Result**: ✅ **WORKING**

---

### DELETE `/api/strings/{key}/`

Delete a UI string entry.

**Response** (Success - 204 No Content): Empty response

**Testing Result**: ✅ **WORKING**

---

## 📋 Trips Logbook Endpoints

### POST `/api/trips/{id}/logbook-entries`

Create a logbook entry for a specific trip.

**Authentication**: Required (Bearer Token)

**Path Parameter**:
- `id` (integer): Trip ID

**Request Body**:
```json
{
  "member": 10613,
  "comment": "Great off-road experience! Challenging terrain but well organized.",
  "date": "2025-11-27",
  "location": "Liwa Desert",
  "difficulty": "moderate"
}
```

**Required Fields**:
- `member` (integer): Member ID (must be checked-in for the trip)
- `comment` (string): Logbook entry comment/review

**Optional Fields**:
- `date` (string, ISO 8601): Entry date
- `location` (string): Location description
- `difficulty` (string): Difficulty level

**Response** (Success - 201 Created):
```json
{
  "success": true,
  "data": {
    "id": 12345,
    "member": 10613,
    "comment": "Great off-road experience!",
    "date": "2025-11-27",
    "location": "Liwa Desert",
    "difficulty": "moderate",
    "created_at": "2025-11-27T18:00:00Z"
  }
}
```

**Error Response** (Business Rule Violation):
```json
{
  "success": false,
  "message": "no_checked_in_member_registration_for_trip"
}
```

**Testing Result**: ⚠️ **CONDITIONAL**

**Business Rules**:
- User MUST be registered for the trip
- User MUST be checked-in (not just registered)
- Cannot create logbook entries for trips user hasn't attended

**Use Cases**:
- Post-trip reviews
- Logbook skill tracking
- Trip feedback collection

---

## 🔐 Authentication Notes

**All endpoints require Bearer token authentication**:

```bash
# 1. Login to get token
curl -X POST "https://ap.ad4x4.com/api/auth/login/" \
  -H "Content-Type: application/json" \
  -d '{"login": "USERNAME", "password": "PASSWORD"}'

# Response:
{
  "detail": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

# 2. Use token in subsequent requests
curl -X GET "https://ap.ad4x4.com/api/ENDPOINT/" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Important**: Use `Bearer` prefix, NOT `Token`.

---

## 📊 Testing Summary

### ✅ Successfully Tested Endpoints (11/13)

1. ✅ POST `/api/geocoding/reverse/` - Reverse geocoding
2. ✅ GET `/api/settings/here-maps-config/` - HERE Maps settings
3. ✅ POST `/api/members/request-deletion` - Request account deletion
4. ✅ POST `/api/members/cancel-deletion` - Cancel deletion request
5. ✅ GET `/api/strings/` - List UI strings
6. ✅ POST `/api/strings/` - Create UI string
7. ✅ GET `/api/strings/{key}/` - Get single UI string
8. ✅ PUT `/api/strings/{key}/` - Full update UI string
9. ✅ PATCH `/api/strings/{key}/` - Partial update UI string
10. ✅ DELETE `/api/strings/{key}/` - Delete UI string
11. ⚠️ POST `/api/trips/{id}/logbook-entries` - Conditional (requires check-in)

### 🔒 Admin-Only Endpoints (2/13)

12. 🔒 PUT `/api/globalsettings/{id}/` - Requires admin permissions
13. 🔒 PATCH `/api/globalsettings/{id}/` - Requires admin permissions

---

## 💡 Implementation Recommendations

### For Mobile App Developers:

1. **Geocoding**:
   - Use for meeting point auto-detection
   - Cache results to minimize API calls
   - Handle offline scenarios gracefully

2. **UI Strings**:
   - Implement local caching with TTL
   - Fetch strings on app startup
   - Support dynamic language switching

3. **GDPR Compliance**:
   - Add "Delete Account" option in settings
   - Show confirmation dialog before deletion
   - Explain deletion timeline (e.g., "Account will be deleted in 30 days")

4. **Trips Logbook**:
   - Only show logbook entry form after trip check-in
   - Validate check-in status before allowing entry creation
   - Handle business rule violations gracefully

### For Backend Developers:

1. **Global Settings**:
   - Implement admin-only endpoints carefully
   - Log all settings changes for audit trail
   - Consider adding settings change notifications

2. **Strings Management**:
   - Use strings for all UI text (future-proof for i18n)
   - Implement versioning for string changes
   - Consider adding string import/export for translations

---

## 🐛 Known Issues & Limitations

1. **GLOBALSETTINGS Endpoints**:
   - Regular users cannot modify settings (by design)
   - No granular permission control documented

2. **TRIPS Logbook**:
   - Strict business rule: must be checked-in
   - No API to check if user can create logbook entry
   - Consider adding `GET /api/trips/{id}/can-create-logbook/` helper endpoint

3. **STRINGS Endpoint**:
   - No bulk operations documented
   - No string import/export functionality
   - No versioning system documented

---

## 📚 Additional Resources

- **Main API Documentation**: `/docs/MAIN_API_DOCUMENTATION.md`
- **API Schema**: `/api_new.yaml` (OpenAPI 3.0.3)
- **Test Scripts**: `/home/user/test_all_new_endpoints.sh`
- **Test Results**: `/tmp/api_tests/`, `/tmp/api_tests_corrected/`

---

**Documentation Version**: 1.0  
**Last Updated**: 2025-11-27 (Added 13 new endpoints)
**Tested Against**: AD4x4 API Production Environment  


GET, POST, PUT, PATCH, DELETE)
9. **Include proper Content-Type headers**
10. **Test with the Swagger UI** at `/docs/swagger-ui/`

---

## Support and Documentation

- **Swagger UI**: `http://localhost:8000/docs/swagger-ui/`
- **ReDoc**: `http://localhost:8000/docs/redoc/`
- **Admin Panel**: `http://localhost:8000/admin/`
- **OpenAPI Schema**: `http://localhost:8000/api/schema/`

---

## Changelog

### Version History

#### Current Version
- Complete CRUD operations for trips, members, and upgrade requests
- Logbook system for skill tracking
- Notification system with push and email support
- Trip request aggregation
- Permission-based access control
- JWT authentication with refresh tokens

---

*Last Updated: November 2024*
*Generated from OpenAPI Schema Version 3.0.3*
