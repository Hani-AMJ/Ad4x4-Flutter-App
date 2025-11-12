# Upgrade Request Management System - Complete Documentation

**System Version**: 1.0.0  
**Completion Date**: November 11, 2025  
**AD4x4 Admin Panel - Phase 2**

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [User Workflows](#user-workflows)
4. [Permission Matrix](#permission-matrix)
5. [API Documentation](#api-documentation)
6. [Screen Documentation](#screen-documentation)
7. [Testing Guide](#testing-guide)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 System Overview

### Purpose
The Upgrade Request Management System enables democratic member level progression through board voting. Members can request upgrades, board members can vote, and admins can approve final decisions.

### Key Features
- **Request Creation**: Members submit upgrade requests with justification
- **Board Voting**: Board members vote approve/decline with optional comments
- **Comments System**: Threaded discussions on requests
- **Approval Workflow**: Final admin approval/decline with reasons
- **Status Tracking**: Pending, Approved, Declined states
- **Vote Analytics**: Approval percentages, vote counts, voter details

### Stakeholders
- **Members**: Can create upgrade requests for themselves
- **Board Members**: Can view, vote, and comment on requests
- **Admins**: Full control - approve, decline, edit, delete requests
- **Marshals**: May have view/vote permissions based on configuration

---

## 🏗️ Architecture

### Data Layer

#### Models (`/lib/data/models/upgrade_request_model.dart`)
```dart
// Core Models
- UpgradeRequestListItem      // List display
- UpgradeRequestDetail         // Complete request data
- Vote                         // Individual board vote
- VoteSummary                  // Aggregated vote stats
- UpgradeRequestComment        // Comment with author
- ApprovalInfo                 // Final decision tracking
- MemberBasicInfo              // Member display data
- MemberDetailInfo             // Extended member data
- UpgradeRequestsResponse      // API pagination wrapper
```

#### API Repository (`/lib/data/repositories/main_api_repository.dart`)
```dart
// 9 API Methods
- getUpgradeRequests()         // List with filtering
- getUpgradeRequestDetail()    // Individual request
- voteUpgradeRequest()         // Cast vote
- approveUpgradeRequest()      // Final approval
- declineUpgradeRequest()      // Final decline
- createUpgradeRequestComment() // Add comment
- deleteUpgradeRequestComment() // Remove comment
- createUpgradeRequest()       // Create new request
- editUpgradeRequest()         // Modify request
- deleteUpgradeRequest()       // Delete request
```

### State Management Layer

#### Providers (`/lib/features/admin/presentation/providers/upgrade_requests_provider.dart`)
```dart
// 3 Riverpod Providers
- UpgradeRequestsNotifier          // List state + pagination
- upgradeRequestDetailProvider      // Individual request
- UpgradeRequestActionsNotifier     // Vote/comment/approve actions
```

**State Features**:
- Tab-based filtering (Pending/Approved/Declined/All)
- Pull-to-refresh support
- Pagination with load more
- Real-time updates after actions
- Optimistic UI updates
- Error handling with retry

### Presentation Layer

#### Screens
1. **AdminUpgradeRequestsScreen** - List with 4 tabs
2. **AdminUpgradeRequestDetailsScreen** - Complete details with actions
3. **AdminCreateUpgradeRequestScreen** - Form to create requests

#### Navigation
- Sidebar: "UPGRADE REQUESTS" section in admin panel
- Routes: `/admin/upgrade-requests`, `/admin/upgrade-requests/:id`, `/admin/upgrade-requests/create`

---

## 👥 User Workflows

### Workflow 1: Member Creates Upgrade Request

**Actors**: Member with `create_upgrade_req_for_self` permission

**Steps**:
1. Navigate to Admin Panel → Upgrade Requests
2. Tap FAB "Create Request"
3. Form shows:
   - Current user info (pre-filled)
   - Current level (auto-displayed)
   - Requested level dropdown
   - Reason text field (50-1000 characters)
4. Fill reason with achievements, contributions, readiness
5. Select requested level
6. Tap "Submit Upgrade Request"
7. System creates request in "Pending" status
8. Board members are notified (backend handles)

**Success**: Request appears in Pending tab, awaits board votes

---

### Workflow 2: Admin Creates Upgrade Request for Member

**Actors**: Admin with `create_upgrade_req_for_other` permission

**Steps**:
1. Navigate to Admin Panel → Upgrade Requests
2. Tap FAB "Create Request"
3. Form shows:
   - Member selection dropdown (all members)
   - Selected member's current level (auto-displayed)
   - Requested level dropdown
   - Reason text field
4. Select member from dropdown
5. Select requested level
6. Fill detailed reason
7. Tap "Submit Upgrade Request"
8. Request created on behalf of member

**Use Case**: Marshal or admin nominates member for upgrade

---

### Workflow 3: Board Member Votes on Request

**Actors**: Board member with `vote_upgrade_req` permission

**Steps**:
1. Navigate to Upgrade Requests → Pending tab
2. See list of pending requests with vote counts
3. Tap request card to view details
4. Review:
   - Member profile and stats
   - Current vs requested level
   - Reason for upgrade
   - Existing votes and comments
5. Decide: Approve or Decline
6. Tap vote button (green approve or red decline)
7. Vote is recorded immediately
8. Vote summary updates (approval percentage, counts)

**Voting Rules**:
- Each board member can vote once per request
- Vote can be changed by voting again
- Votes are tracked with timestamp and voter name
- Optional: Add comment with vote for context

---

### Workflow 4: Board Member Comments on Request

**Actors**: Board member with `create_comment_upgrade_req` permission

**Steps**:
1. Open upgrade request details
2. Scroll to Comments section
3. Type comment in text field
4. Tap send button
5. Comment appears with author name, photo, timestamp
6. Other board members see comment
7. Can delete own comments using delete icon

**Use Case**: 
- Ask questions about member's readiness
- Provide context for vote
- Discuss member's qualifications

---

### Workflow 5: Admin Approves/Declines Request

**Actors**: Admin with `approve_upgrade_req` permission

**Steps for Approval**:
1. Navigate to Upgrade Requests → Pending tab
2. Review request details
3. Check vote summary (approval percentage, counts)
4. **Quick Approve** (from list):
   - Tap "Approve" button on card
   - Confirm in dialog
   - Request moves to Approved tab
5. **OR Detailed Approve** (from details):
   - Open request details
   - Review all votes and comments
   - Tap "Approve Request" in admin actions panel
   - Confirm in dialog
   - Request marked approved

**Steps for Decline**:
1. Same navigation to Pending
2. Review request details
3. **From list**: Tap "Decline" → Opens details screen
4. **From details**: Tap "Decline Request" in admin panel
5. Dialog appears asking for decline reason
6. Enter detailed reason (required)
7. Confirm decline
8. Request moves to Declined tab
9. Member sees decline reason

**After Approval/Decline**:
- Member's level is updated (backend handles)
- Notification sent to member (backend handles)
- Request cannot be modified further
- Approval info shows: who decided, when, why (if declined)

---

### Workflow 6: Admin Edits/Deletes Request

**Actors**: Admin with `edit_upgrade_req` or `delete_upgrade_req`

**Edit**:
1. Open request details
2. Tap edit icon in AppBar
3. Modify requested level or reason
4. Save changes
5. Board members see updated info

**Delete**:
1. Open request details
2. Tap delete icon in AppBar
3. Confirm deletion
4. Request permanently removed
5. All votes and comments deleted

**Use Cases**:
- Fix typos in reason
- Adjust requested level if too aggressive
- Remove duplicate requests
- Clean up spam/test requests

---

## 🔐 Permission Matrix

### Complete Permission List (9 permissions)

| Permission | Action | Who Should Have It | Screen Access |
|-----------|--------|-------------------|---------------|
| `view_upgrade_req` | View upgrade requests | Board, Admins, Marshals | List, Details |
| `vote_upgrade_req` | Cast votes | Board Members | Details (voting panel) |
| `create_comment_upgrade_req` | Add comments | Board, Admins | Details (comment form) |
| `delete_comment_upgrade_req` | Delete any comment | Admins | Details (delete buttons) |
| `approve_upgrade_req` | Final approve/decline | Admins | List (quick actions), Details (admin panel) |
| `create_upgrade_req_for_self` | Create for yourself | All Members | List (FAB), Create screen |
| `create_upgrade_req_for_other` | Create for others | Admins, Marshals | Create screen (member dropdown) |
| `edit_upgrade_req` | Modify requests | Admins | Details (edit button) |
| `delete_upgrade_req` | Delete requests | Admins | Details (delete button) |

### Recommended Permission Sets

#### Regular Member
```
✅ create_upgrade_req_for_self
```
**Can**: Submit own upgrade requests  
**Cannot**: Vote, approve, or create for others

#### Board Member
```
✅ view_upgrade_req
✅ vote_upgrade_req
✅ create_comment_upgrade_req
✅ create_upgrade_req_for_self
```
**Can**: View, vote, comment, submit own requests  
**Cannot**: Approve/decline, edit, delete, create for others

#### Marshal
```
✅ view_upgrade_req
✅ vote_upgrade_req
✅ create_comment_upgrade_req
✅ create_upgrade_req_for_self
✅ create_upgrade_req_for_other
```
**Can**: Everything board members can + create for others  
**Cannot**: Final approve/decline, edit, delete

#### Admin
```
✅ All 9 permissions
```
**Can**: Everything - full control over upgrade request system

---

## 📡 API Documentation

### Base URL
```
https://ap.ad4x4.com
```

### Authentication
All endpoints require authentication via Bearer token:
```
Authorization: Bearer {token}
```

### Endpoints

#### 1. List Upgrade Requests
```http
GET /api/upgrade-requests/
```

**Query Parameters**:
- `status` (optional): Filter by status - `pending`, `approved`, `declined`
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response**:
```json
{
  "count": 45,
  "next": "https://ap.ad4x4.com/api/upgrade-requests/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "member": {
        "id": 123,
        "username": "john_doe",
        "first_name": "John",
        "last_name": "Doe",
        "profile_image": "https://..."
      },
      "current_level": "Silver",
      "requested_level": "Gold",
      "status": "pending",
      "submitted_at": "2025-11-10T10:30:00Z",
      "comment_count": 3,
      "vote_summary": {
        "approve_count": 5,
        "decline_count": 1,
        "current_user_voted": true,
        "current_user_vote": true
      }
    }
  ]
}
```

#### 2. Get Upgrade Request Details
```http
GET /api/upgrade-requests/{id}/
```

**Response**:
```json
{
  "id": 1,
  "member": {
    "id": 123,
    "username": "john_doe",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone_number": "+971501234567",
    "trip_count": 25,
    "date_joined": "2024-01-15T00:00:00Z",
    "profile_image": "https://..."
  },
  "current_level": "Silver",
  "requested_level": "Gold",
  "reason": "Has completed 15 trips as participant...",
  "status": "pending",
  "submitted_at": "2025-11-10T10:30:00Z",
  "votes": [
    {
      "id": 1,
      "voter": {
        "id": 456,
        "username": "board_member",
        "first_name": "Jane",
        "last_name": "Smith",
        "profile_image": null
      },
      "approve": true,
      "voted_at": "2025-11-10T12:00:00Z",
      "comment": "Excellent progress, ready for Gold"
    }
  ],
  "comments": [
    {
      "id": 1,
      "author": {
        "id": 789,
        "username": "another_member",
        "first_name": "Bob",
        "last_name": "Wilson",
        "profile_image": null
      },
      "text": "Great member, very helpful on trips",
      "created_at": "2025-11-10T11:00:00Z",
      "can_delete": false
    }
  ],
  "approval_info": null,
  "vote_summary": {
    "approve_count": 5,
    "decline_count": 1,
    "current_user_voted": true,
    "current_user_vote": true
  }
}
```

#### 3. Vote on Upgrade Request
```http
POST /api/upgrade-requests/{id}/vote/
```

**Request Body**:
```json
{
  "approve": true,
  "comment": "Optional comment with vote"
}
```

**Response**: `200 OK`

#### 4. Approve Upgrade Request
```http
POST /api/upgrade-requests/{id}/approve/
```

**Response**: `200 OK`

#### 5. Decline Upgrade Request
```http
POST /api/upgrade-requests/{id}/decline/
```

**Request Body**:
```json
{
  "reason": "Needs more trip experience"
}
```

**Response**: `200 OK`

#### 6. Add Comment
```http
POST /api/upgrade-requests/{id}/comments/
```

**Request Body**:
```json
{
  "text": "Comment text here"
}
```

**Response**:
```json
{
  "id": 5,
  "author": {...},
  "text": "Comment text here",
  "created_at": "2025-11-10T15:30:00Z",
  "can_delete": true
}
```

#### 7. Delete Comment
```http
DELETE /api/upgrade-requests/comments/{commentId}/
```

**Response**: `204 No Content`

#### 8. Create Upgrade Request
```http
POST /api/upgrade-requests/
```

**Request Body**:
```json
{
  "member_id": 123,
  "requested_level": "Gold",
  "reason": "Detailed reason for upgrade..."
}
```

**Response**: `201 Created` with full request object

#### 9. Edit Upgrade Request
```http
PATCH /api/upgrade-requests/{id}/
```

**Request Body** (all fields optional):
```json
{
  "requested_level": "Gold",
  "reason": "Updated reason..."
}
```

**Response**: `200 OK` with updated request

#### 10. Delete Upgrade Request
```http
DELETE /api/upgrade-requests/{id}/
```

**Response**: `204 No Content`

---

## 📱 Screen Documentation

### Screen 1: Upgrade Requests List

**Route**: `/admin/upgrade-requests`  
**File**: `lib/features/admin/presentation/screens/admin_upgrade_requests_screen.dart`

**Features**:
- 4 tabs with count badges: Pending, Approved, Declined, All
- Member cards showing:
  - Profile photo
  - Name
  - Current → Requested level
  - Vote counts (👍 approve, 👎 decline)
  - Comment count (💬)
  - Status badge (color-coded)
  - Submission date
- Quick actions (for admins):
  - Approve button (green)
  - Decline button (red)
  - View Details button
- FAB for creating new requests
- Pull-to-refresh
- Empty states for each tab
- Loading states
- Error handling with retry

**Permission Requirements**:
- `view_upgrade_req` - Required to access screen
- `approve_upgrade_req` - Shows quick action buttons
- `create_upgrade_req_for_self` - Shows FAB

---

### Screen 2: Upgrade Request Details

**Route**: `/admin/upgrade-requests/:id`  
**File**: `lib/features/admin/presentation/screens/admin_upgrade_request_details_screen.dart`

**Sections**:

1. **Member Header**
   - Large profile photo (96px diameter)
   - Full name and email
   - Current level → Requested level (visual cards with arrow)
   - Member stats: trip count, member since date

2. **Request Details**
   - Status badge (Pending/Approved/Declined)
   - Submission date
   - Reason for upgrade (highlighted container)

3. **Voting Panel**
   - Vote summary cards (approve vs decline counts)
   - Approval percentage with progress bar
   - "Your vote" status indicator
   - Vote buttons (if has permission and pending)
   - Individual board member votes list:
     - Voter name with photo
     - Vote (approve/decline icon)
     - Timestamp
     - Optional comment

4. **Comments Section**
   - Comment count header
   - Add comment form (text field + send button)
   - Comments list:
     - Author name with photo
     - Comment text
     - Timestamp
     - Delete button (if has permission)

5. **Admin Actions** (pending requests only)
   - Elevated panel with admin icon
   - Green "Approve Request" button
   - Red "Decline Request" button (with reason dialog)

6. **Approval Info** (completed requests)
   - Who decided (name)
   - When (date and time)
   - Decision (Approved/Declined)
   - Reason (if declined)
   - Color-coded container

**Actions Available**:
- Edit (AppBar icon) - if has `edit_upgrade_req`
- Delete (AppBar icon) - if has `delete_upgrade_req`
- Vote (buttons) - if has `vote_upgrade_req`
- Comment (form) - if has `create_comment_upgrade_req`
- Delete comment (icon) - if has `delete_comment_upgrade_req`
- Approve/Decline (panel) - if has `approve_upgrade_req`

---

### Screen 3: Create Upgrade Request

**Route**: `/admin/upgrade-requests/create`  
**File**: `lib/features/admin/presentation/screens/admin_create_upgrade_request_screen.dart`

**Form Fields**:

1. **Member Selection** (if `create_upgrade_req_for_other`)
   - Dropdown with all members
   - Search by name
   - Shows name (or username if name empty)
   - On select: loads member's current level

2. **Member Display** (if `create_upgrade_req_for_self`)
   - Shows current user info (non-editable)
   - Profile photo
   - Name
   - Current level

3. **Level Selection**
   - Current level (display only, left side)
   - Arrow icon (visual separator)
   - Requested level (dropdown, right side)
   - Lists all active levels
   - Format: "Level X - Name"

4. **Reason Field**
   - Multi-line text field (8 lines)
   - Character limit: 1000
   - Minimum required: 50 characters
   - Hint text with example
   - Validation: not empty, min length

**Buttons**:
- Submit (primary, blue) - Creates request
- Cancel (outlined) - Goes back to list

**Validation Rules**:
- Member must be selected
- Requested level must be selected
- Reason must be at least 50 characters
- Reason max 1000 characters

**Success Flow**:
1. Form validation passes
2. API call to create request
3. Success message shown (green)
4. Navigate to list screen
5. New request appears in Pending tab

**Error Flow**:
1. Form validation fails → Show field errors
2. API call fails → Show error message
3. User can retry without losing data

---

## 🧪 Testing Guide

### Manual Testing Checklist

#### Test 1: Create Upgrade Request (Self)
**User**: Member with `create_upgrade_req_for_self`

- [ ] Navigate to Upgrade Requests
- [ ] Tap FAB "Create Request"
- [ ] See pre-filled member info (current user)
- [ ] See current level displayed
- [ ] Select requested level from dropdown
- [ ] Enter reason (< 50 chars) → See validation error
- [ ] Enter valid reason (50+ chars)
- [ ] Tap Submit
- [ ] See success message
- [ ] Navigate to Pending tab
- [ ] See new request in list

**Expected**: Request created successfully, appears in Pending

---

#### Test 2: Create Upgrade Request (Other)
**User**: Admin with `create_upgrade_req_for_other`

- [ ] Navigate to Upgrade Requests
- [ ] Tap FAB "Create Request"
- [ ] See member dropdown (not pre-filled)
- [ ] Select member from dropdown
- [ ] See member's current level auto-populate
- [ ] Select requested level
- [ ] Enter detailed reason
- [ ] Tap Submit
- [ ] See success message
- [ ] Request created for selected member

**Expected**: Request created on behalf of member

---

#### Test 3: Vote on Upgrade Request
**User**: Board member with `vote_upgrade_req`

- [ ] Navigate to Pending tab
- [ ] See request with vote counts
- [ ] Tap request card
- [ ] See voting panel with approve/decline buttons
- [ ] Tap "Approve" button
- [ ] Vote recorded immediately
- [ ] See "You voted to approve" indicator
- [ ] Vote count increments
- [ ] Approval percentage updates
- [ ] Try voting again → Vote changes
- [ ] Return to list → See updated counts

**Expected**: Vote recorded, UI updates immediately

---

#### Test 4: Comment on Upgrade Request
**User**: Board member with `create_comment_upgrade_req`

- [ ] Open upgrade request details
- [ ] Scroll to Comments section
- [ ] Type comment in text field
- [ ] Tap send button
- [ ] Comment appears with your name, photo, timestamp
- [ ] Comment count increments
- [ ] Return to list → See updated comment count
- [ ] Re-open request → Comment still there

**Expected**: Comment saved and visible to all

---

#### Test 5: Approve Upgrade Request (Quick)
**User**: Admin with `approve_upgrade_req`

- [ ] Navigate to Pending tab
- [ ] See request with "Approve" button
- [ ] Tap "Approve" button
- [ ] See confirmation dialog
- [ ] Confirm approval
- [ ] Request moves to Approved tab
- [ ] Request no longer in Pending
- [ ] Open approved request
- [ ] See approval info (who, when)
- [ ] Cannot vote or comment anymore

**Expected**: Request approved, status updated

---

#### Test 6: Decline Upgrade Request
**User**: Admin with `approve_upgrade_req`

- [ ] Open pending request details
- [ ] Scroll to Admin Actions panel
- [ ] Tap "Decline Request" button
- [ ] See dialog asking for reason
- [ ] Leave reason empty → Cannot submit
- [ ] Enter decline reason
- [ ] Confirm decline
- [ ] Request moves to Declined tab
- [ ] Open declined request
- [ ] See decline info with reason

**Expected**: Request declined with reason saved

---

#### Test 7: Delete Comment
**User**: Admin with `delete_comment_upgrade_req`

- [ ] Open request with comments
- [ ] See delete icon on all comments
- [ ] Tap delete icon
- [ ] See confirmation dialog
- [ ] Confirm deletion
- [ ] Comment removed immediately
- [ ] Comment count decrements

**Expected**: Comment deleted, count updated

---

#### Test 8: Edit Upgrade Request
**User**: Admin with `edit_upgrade_req`

- [ ] Open pending request
- [ ] Tap edit icon in AppBar
- [ ] Modify requested level or reason
- [ ] Save changes
- [ ] Changes reflected in details
- [ ] Other users see updated info

**Expected**: Request updated successfully

---

#### Test 9: Delete Upgrade Request
**User**: Admin with `delete_upgrade_req`

- [ ] Open request details
- [ ] Tap delete icon in AppBar
- [ ] See confirmation warning
- [ ] Confirm deletion
- [ ] Navigate to list
- [ ] Request no longer appears
- [ ] Total count decremented

**Expected**: Request permanently deleted

---

#### Test 10: Permission-Based Access
**User**: Regular member (no permissions)

- [ ] Login with no upgrade request permissions
- [ ] Go to admin panel
- [ ] Upgrade Requests section NOT visible in sidebar
- [ ] Try direct URL `/admin/upgrade-requests`
- [ ] See "Access Denied" screen
- [ ] Cannot access any upgrade request features

**Expected**: Complete denial of access

---

### Automated Testing (Future)

#### Unit Tests
```dart
// Provider Tests
- Load upgrade requests list
- Filter by status (pending/approved/declined)
- Pagination (load more)
- Vote on request
- Add comment
- Approve/decline request

// Model Tests
- Parse API response to UpgradeRequestListItem
- Parse API response to UpgradeRequestDetail
- Calculate approval percentage
- Validate vote summary

// Repository Tests
- Mock API calls
- Test error handling
- Test response parsing
```

#### Widget Tests
```dart
// Screen Tests
- Render list screen with data
- Render empty state
- Render loading state
- Render error state
- Tap request card navigation
- Permission-based visibility

// Form Tests
- Validate reason field (min/max length)
- Validate member selection
- Validate level selection
- Submit with valid data
- Submit with invalid data
```

#### Integration Tests
```dart
// End-to-End Workflows
- Complete create request flow
- Complete vote flow
- Complete approve flow
- Complete decline flow
- Comment thread flow
```

---

## 🔧 Troubleshooting

### Issue 1: "Access Denied" Screen
**Symptom**: User sees access denied when trying to view upgrade requests

**Cause**: User lacks `view_upgrade_req` permission

**Solution**:
1. Check user permissions in admin backend
2. Assign `view_upgrade_req` permission to user
3. Refresh app or re-login
4. Try accessing upgrade requests again

---

### Issue 2: FAB Not Visible
**Symptom**: Create request button (FAB) not showing

**Cause**: User lacks `create_upgrade_req_for_self` permission

**Solution**:
1. Check if user has create permission
2. Assign appropriate permission (`create_upgrade_req_for_self` or `create_upgrade_req_for_other`)
3. Refresh list screen
4. FAB should appear

---

### Issue 3: Vote Buttons Not Showing
**Symptom**: Cannot see vote buttons in request details

**Causes**:
- User lacks `vote_upgrade_req` permission
- Request is not in pending status
- User already voted

**Solution**:
1. Check user has voting permission
2. Verify request status is "pending"
3. If already voted, "You voted..." indicator shows instead
4. Approved/declined requests cannot be voted on

---

### Issue 4: Cannot Add Comments
**Symptom**: Comment form not visible

**Causes**:
- User lacks `create_comment_upgrade_req` permission
- Request is not pending

**Solution**:
1. Check user has comment permission
2. Pending requests show comment form
3. Approved/declined requests show comments read-only

---

### Issue 5: Approval Buttons Not Working
**Symptom**: Admin actions panel not visible or not working

**Causes**:
- User lacks `approve_upgrade_req` permission
- Request is not pending
- API error

**Solution**:
1. Check user has approve permission
2. Only pending requests show admin actions
3. Check browser console for API errors
4. Check network tab for failed requests

---

### Issue 6: Member Dropdown Empty
**Symptom**: No members showing in create form dropdown

**Causes**:
- API failed to load members
- No members in database
- Permission issue

**Solution**:
1. Check browser console for errors
2. Verify API endpoint `/api/members/` works
3. Check network tab for 403/401 errors
4. Ensure user has proper authentication

---

### Issue 7: Request Not Appearing After Creation
**Symptom**: Submitted request not showing in list

**Causes**:
- API error during creation
- Wrong tab selected
- List not refreshed

**Solution**:
1. Check for error messages after submit
2. Navigate to "Pending" tab (not All)
3. Pull down to refresh list
4. Check browser console for errors

---

### Issue 8: Vote Count Not Updating
**Symptom**: Vote counts don't change after voting

**Causes**:
- Cache issue
- API response delayed
- State not refreshing

**Solution**:
1. Pull down to refresh
2. Navigate away and back
3. Check network tab for successful API response
4. Clear browser cache if persists

---

## 📞 Support & Maintenance

### For Issues
1. Check browser console for errors
2. Check network tab for failed API calls
3. Verify user has proper permissions
4. Review this documentation
5. Contact development team

### For Feature Requests
- Document use case and affected users
- Identify required permissions
- Provide mockups if UI changes needed
- Submit to product team for prioritization

### For Backend Issues
- Check API endpoint availability
- Verify authentication tokens
- Check response format matches models
- Contact backend team with error details

---

## 🎯 Success Metrics

### System Health
- **Request Creation Rate**: Avg requests per month
- **Vote Participation**: % board members voting
- **Approval Time**: Avg days from submission to decision
- **Comment Activity**: Avg comments per request

### User Engagement
- **Active Voters**: Board members voting regularly
- **Request Quality**: Avg character length of reasons
- **Approval Rate**: % requests approved vs declined
- **Resubmission Rate**: % members resubmitting after decline

---

**System Status**: ✅ Fully Operational  
**Documentation Version**: 1.0.0  
**Last Updated**: November 11, 2025

---

**For Questions**: Contact Friday AI Assistant or AD4x4 Development Team
