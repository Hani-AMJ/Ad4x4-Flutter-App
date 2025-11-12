# API Query Parameters Documentation

## Overview
This document lists available query parameters for API endpoints to enable efficient filtering and searching without fetching and filtering locally.

⚠️ **CRITICAL**: Always check if query parameters are available before implementing client-side filtering!

---

## Members Endpoint

### Base URL
```
GET /api/members/
```

### Available Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `level_Name` | String | Filter by exact level name | `?level_Name=Marshal` |
| `level_NumericLevel_Range` | String | Filter by numeric level range (min,max) | `?level_NumericLevel_Range=600,900` |
| `firstName_Icontains` | String | Case-insensitive search in first name | `?firstName_Icontains=john` |
| `lastName_Icontains` | String | Case-insensitive search in last name | `?lastName_Icontains=smith` |
| `page` | Integer | Page number (1-based) | `?page=1` |
| `pageSize` | Integer | Items per page | `?pageSize=100` |

### Examples

**Get all Marshal members:**
```dart
final response = await apiClient.get(
  '/api/members/',
  queryParameters: {
    'level_Name': 'Marshal',
    'pageSize': 500,
  },
);
```

**Search members by name:**
```dart
final response = await apiClient.get(
  '/api/members/',
  queryParameters: {
    'firstName_Icontains': 'hani',
    'lastName_Icontains': 'janem',
  },
);
```

**Get Marshals and Board Members (for deputy selection):**
```dart
final response = await apiClient.get(
  '/api/members/',
  queryParameters: {
    'level_NumericLevel_Range': '600,900',  // Marshal=600, Board=800
    'pageSize': 500,
  },
);
```

**Level Numeric Values:**
- Club Event: 5
- Newbie: 10
- ANIT: 10
- Intermediate: 100
- Advanced: 200
- Explorer: 400
- Marshal: 600
- Board Member: 800

---

## Levels Endpoint

### Base URL
```
GET /api/levels/
```

### Response Format
⚠️ **NOTE**: Returns paginated response with structure:
```json
{
  "count": 9,
  "next": null,
  "previous": null,
  "results": [...]
}
```

**Always extract `results` array:**
```dart
if (response.data is Map && (response.data as Map).containsKey('results')) {
  return (response.data as Map)['results'] as List<dynamic>;
}
```

---

## Meeting Points Endpoint

### Base URL
```
GET /api/meetingpoints/
```

### Available Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `page` | Integer | Page number | `?page=1` |
| `pageSize` | Integer | Items per page | `?pageSize=100` |

### Response Format
Returns paginated response - extract `results` array.

---

## Trips Endpoint

### Base URL
```
GET /api/trips/
GET /api/trips/{id}/
POST /api/trips/
```

### GET /api/trips/ - List Trips

**Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `status` | String | Filter by status | `?status=upcoming` |
| `level` | Integer | Filter by level ID | `?level=5` |
| `page` | Integer | Page number | `?page=1` |
| `pageSize` | Integer | Items per page | `?pageSize=20` |

**Success Response Fields:**

Returns paginated list of `ListTrip` objects with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Trip ID |
| `title` | String | Trip title |
| `description` | String | Trip description |
| `startTime` | ISO DateTime | Trip start time |
| `endTime` | ISO DateTime | Trip end time |
| `cutOff` | ISO DateTime | Registration cutoff |
| `location` | String | Location description |
| `level` | Object | Level details (id, name, numericLevel) |
| `capacity` | Integer | Maximum participants |
| `registeredCount` | Integer | Current registered count |
| `waitlistCount` | Integer | Current waitlist count |
| `imageUrl` | String | Trip image URL |
| `lead` | Object | Trip lead member details |
| `meetingPoint` | Object | Meeting point details |
| `approvalStatus` | String | Trip approval status (pending/approved/declined) |
| `allowWaitlist` | Boolean | Whether waitlist is enabled |
| `created` | ISO DateTime | Trip creation time |
| **`isRegistered`** | **String (read-only)** | **Whether current logged-in user is registered for this trip** |
| **`isWaitlisted`** | **String (read-only)** | **Whether current logged-in user is on the waitlist for this trip** |

**Note:** The `isRegistered` and `isWaitlisted` fields are calculated server-side based on the authenticated user. This eliminates the need for multiple API calls to determine user registration status.

### GET /api/trips/{id}/ - Trip Details

**Success Response Fields:**

Returns a detailed `Trip` object with all fields from the list endpoint, plus:

| Field | Type | Description |
|-------|------|-------------|
| `registered` | Array | List of registered members with full details |
| `waitlist` | Array | List of waitlisted members with position |
| `deputyLeads` | Array | List of deputy marshal members |
| `requirements` | Array | List of trip requirements |
| `approvedBy` | Object | Member who approved the trip |
| `approvedAt` | ISO DateTime | When trip was approved |
| **`isRegistered`** | **String (read-only)** | **Whether current user is registered on this trip** |
| **`isWaitlisted`** | **String (read-only)** | **Whether current user is on the trip's waitlist** |

**Performance Benefit:** These read-only fields allow the client to immediately show "Registered" or "Waitlisted" badges without additional API calls to check user registration status.

### POST Request Body (Create Trip)

⚠️ **CRITICAL**: Field names are **camelCase**, not snake_case!

**Required Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `lead` | Integer | ID of trip lead (current user) | `1` |
| `title` | String (max 70) | Trip title | `"Sunset Drive"` |
| `description` | String | Detailed description | `"Easy drive for newbies"` |
| `startTime` | ISO DateTime | Trip start time | `"2025-12-05T15:00:00Z"` |
| `endTime` | ISO DateTime | Trip end time | `"2025-12-05T18:00:00Z"` |
| `cutOff` | ISO DateTime | Registration cutoff | `"2025-12-05T11:00:00Z"` |
| `level` | Integer | Trip difficulty level ID | `2` |

**Optional Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `meetingPoint` | Integer | Meeting point ID | `5` |
| `image` | String | Image URL/path | `"sample_image"` |
| `capacity` | Integer | Max participants | `20` |
| `allowWaitlist` | Boolean | Enable waitlist | `true` |

**Example Request:**
```dart
final tripData = {
  'lead': currentUserId,  // ✅ camelCase
  'title': 'Weekend Adventure',
  'description': 'A challenging off-road experience...',
  'startTime': '2025-12-05T15:00:00Z',  // ✅ camelCase
  'endTime': '2025-12-05T18:00:00Z',    // ✅ camelCase
  'cutOff': '2025-12-05T11:00:00Z',     // ✅ camelCase
  'level': 4,
  'meetingPoint': 142,                   // ✅ camelCase
  'capacity': 20,
  'allowWaitlist': true,                 // ✅ camelCase
  'image': '',                            // ✅ Optional - can be empty string
};
```

**Response:**
```json
{
  "success": true,
  "message": "Trip created"
}
```

---

## Best Practices

### ✅ DO:
1. **Check for query parameters first** before implementing client-side filtering
2. **Use server-side filtering** when available (faster, more efficient)
3. **Request appropriate page sizes** (100-500 for complete lists)
4. **Handle paginated responses** by extracting `results` array
5. **Log API queries** during development to verify parameters work

### ❌ DON'T:
1. **Fetch all data and filter locally** when server-side filtering exists
2. **Assume all endpoints support the same parameters** - check docs
3. **Use small page sizes** (20) when fetching complete datasets
4. **Ignore pagination** - always handle `count`, `next`, `previous`

---

## Example: Efficient Marshal Fetching

### ❌ WRONG (Inefficient):
```dart
// Fetches ALL members, then filters locally
List<Member> allMembers = [];
int page = 1;
do {
  final response = await getMembers(page: page, pageSize: 100);
  allMembers.addAll(response['results']);
  page++;
} while (page <= totalPages);

// Filter locally
final marshals = allMembers.where((m) => m.level.contains('Marshal')).toList();
```

### ✅ CORRECT (Efficient):
```dart
// Let backend do the filtering
final response = await apiClient.get(
  '/api/members/',
  queryParameters: {
    'level_Name': 'Marshal',
    'pageSize': 500,
  },
);
final marshals = (response.data['results'] as List)
    .map((json) => Member.fromJson(json))
    .toList();
```

**Performance Difference:**
- Wrong: 5-10 API calls, 10-20 seconds, 500KB+ data transfer
- Correct: 1 API call, 1-2 seconds, 50KB data transfer

---

## Testing Query Parameters

### Method 1: Direct API Testing
```bash
curl "https://ap.ad4x4.com/api/members/?level_Name=Marshal&pageSize=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Method 2: Flutter Debug Logging
```dart
print('🔍 [API] Fetching with params: $queryParameters');
final response = await apiClient.get(endpoint, queryParameters: queryParameters);
print('✅ [API] Response count: ${response.data['count']}');
```

---

## Common Query Parameter Patterns

### Django Rest Framework (DRF) Conventions
This API uses Django Rest Framework, which typically supports:

| Pattern | Description | Example |
|---------|-------------|---------|
| `field__exact` | Exact match | `level__exact=Marshal` |
| `field__icontains` | Case-insensitive contains | `firstName__icontains=john` |
| `field__in` | In list | `level__in=Marshal,Board member` |
| `field__gt` | Greater than | `tripCount__gt=10` |
| `field__lt` | Less than | `tripCount__lt=5` |
| `ordering` | Sort results | `?ordering=-created` |

### Discovering Available Parameters
1. Check API documentation (if available)
2. Test with Postman/curl
3. Check backend Django model filters
4. Ask backend team for filter classes

---

## Endpoint-Specific Notes

### Members
- ✅ Supports `level_Name` for filtering by level
- ✅ Supports name search with `_Icontains` suffix
- ❌ Does NOT support group filtering (use level instead)
- ⚠️ Profile images may be null - always check `profileImage != null`

### Trips
- ✅ Supports status filtering (`upcoming`, `completed`, `cancelled`)
- ✅ Supports level filtering by ID
- ⚠️ POST to `/api/trips/` requires specific permissions
- ⚠️ Returns 405 if user lacks `create_trip` permission

### Levels
- ⚠️ Always returns paginated response (not direct array)
- ✅ Use `active: true` filter if available
- 📝 Field names: `id`, `name`, `numeric_level`, `active`, `description`

### Meeting Points
- ⚠️ Returns paginated response
- 📝 Field names: `id`, `name`, `area`, `latitude`, `longitude`
- ⚠️ No search parameters discovered yet - may need client-side filtering

---

## Troubleshooting

### Issue: Getting empty results
**Check:**
1. Parameter name spelling (case-sensitive!)
2. API supports that parameter
3. Token has correct permissions
4. Values match exactly (e.g., "Marshal" not "marshal")

### Issue: 405 Method Not Allowed
**Causes:**
1. Missing permission for POST/PUT/DELETE
2. Endpoint is read-only
3. Wrong HTTP method
4. CORS preflight failure

**Solution:** Check user permissions in console logs

### Issue: Paginated response parsing fails
**Fix:** Always check for `results` key:
```dart
if (response.data is Map && (response.data as Map).containsKey('results')) {
  return (response.data as Map)['results'] as List<dynamic>;
}
return response.data as List<dynamic>;
```

---

## Future Improvements

### TODO: Document these endpoints
- [ ] Trip Registration endpoints
- [ ] Trip Comments endpoints
- [ ] Gallery endpoints
- [ ] Logbook endpoints
- [ ] Upgrade Request endpoints

### TODO: Test and document these potential parameters
- [ ] `search` - Global search parameter
- [ ] `fields` - Select specific fields to return
- [ ] `expand` - Include related objects
- [ ] `exclude` - Exclude specific fields

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-22 | 1.0 | Initial documentation created after Marshal filtering optimization |

---

## Contact

For questions about API parameters or to report missing documentation:
1. Check backend API schema: `https://ap.ad4x4.com/api/schema/`
2. Test parameters with Postman
3. Document findings here for future reference
