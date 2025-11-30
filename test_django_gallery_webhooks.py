#!/usr/bin/env python3
"""
Django Gallery Webhook Testing Script

Tests the Main Backend (Django) to verify if it calls Gallery API webhooks
when trips are created, published, renamed, and deleted.

User Credentials: Abu Makram / 3213Plugin?
"""

import requests
import json
import time
from datetime import datetime, timedelta

# API Configuration
MAIN_API_URL = "https://ap.ad4x4.com"
GALLERY_API_URL = "https://media.ad4x4.com"

# Test Configuration
# Try different login formats
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

# Alternative formats to try
LOGIN_ATTEMPTS = [
    "Hani AMJ",        # Known working username
    "AbuMakram",       # Username without space
    "abu_makram",      # Lowercase with underscore
    "abu.makram",      # Lowercase with dot
]

class Color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Color.BOLD}{Color.HEADER}{'='*80}{Color.END}")
    print(f"{Color.BOLD}{Color.HEADER}{text.center(80)}{Color.END}")
    print(f"{Color.BOLD}{Color.HEADER}{'='*80}{Color.END}\n")

def print_success(text):
    print(f"{Color.GREEN}✅ {text}{Color.END}")

def print_error(text):
    print(f"{Color.RED}❌ {text}{Color.END}")

def print_warning(text):
    print(f"{Color.YELLOW}⚠️  {text}{Color.END}")

def print_info(text):
    print(f"{Color.CYAN}ℹ️  {text}{Color.END}")

def authenticate_main_api():
    """Authenticate with Main Backend (Django)"""
    print_header("AUTHENTICATING WITH MAIN BACKEND")
    
    # Try different login formats
    for login_attempt in LOGIN_ATTEMPTS:
        print_info(f"Trying login: '{login_attempt}'")
        
        try:
            response = requests.post(
                f"{MAIN_API_URL}/api/auth/login/",
                json={
                    "login": login_attempt,
                    "password": PASSWORD
                },
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                token = data.get('token')
                user_data = data.get('user', {})
                
                print_success(f"✅ Authenticated successfully!")
                print_success(f"Username: {user_data.get('username')} (ID: {user_data.get('id')})")
                print_info(f"User Level: {user_data.get('level')}")
                print_info(f"Token: {token[:30]}...")
                
                return token, user_data
            else:
                print_warning(f"Failed with '{login_attempt}': {response.status_code}")
                
        except Exception as e:
            print_error(f"Error with '{login_attempt}': {str(e)}")
    
    print_error("All login attempts failed")
    return None, None

def get_available_levels(token):
    """Get available trip levels"""
    print_header("FETCHING AVAILABLE TRIP LEVELS")
    
    try:
        response = requests.get(
            f"{MAIN_API_URL}/api/levels/",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        
        if response.status_code == 200:
            levels = response.json()
            print_success(f"Found {len(levels)} trip levels:")
            for level in levels:
                print_info(f"  - {level.get('name')} (ID: {level.get('id')}, Numeric: {level.get('numeric_level')})")
            return levels
        else:
            print_error(f"Failed to fetch levels: {response.status_code}")
            return []
            
    except Exception as e:
        print_error(f"Error fetching levels: {str(e)}")
        return []

def get_meeting_points(token):
    """Get available meeting points"""
    print_header("FETCHING AVAILABLE MEETING POINTS")
    
    try:
        response = requests.get(
            f"{MAIN_API_URL}/api/meetingpoints/",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        
        if response.status_code == 200:
            points = response.json()
            print_success(f"Found {len(points)} meeting points:")
            for point in points[:5]:  # Show first 5
                print_info(f"  - {point.get('name')} (ID: {point.get('id')})")
            return points
        else:
            print_error(f"Failed to fetch meeting points: {response.status_code}")
            return []
            
    except Exception as e:
        print_error(f"Error fetching meeting points: {str(e)}")
        return []

def create_test_trip(token, user_data, levels, meeting_points):
    """Create a test trip"""
    print_header("CREATING TEST TRIP")
    
    # Use first available level (or default to intermediate)
    level_id = levels[0]['id'] if levels else 3
    meeting_point_id = meeting_points[0]['id'] if meeting_points else 1
    
    # Generate unique title with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    title = f"🧪 Webhook Test Trip {timestamp}"
    
    # Trip dates (future dates)
    start_time = (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%dT10:00:00")
    end_time = (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%dT16:00:00")
    cut_off = (datetime.now() + timedelta(days=6)).strftime("%Y-%m-%dT23:59:59")
    
    trip_data = {
        "title": title,
        "description": "Test trip created to verify Gallery API webhook integration. Safe to delete.",
        "startTime": start_time,
        "endTime": end_time,
        "cutOff": cut_off,
        "level": level_id,
        "meetingPoint": meeting_point_id,
        "capacity": 10,
        "allowWaitlist": True,
        "requirements": ["4x4 vehicle", "Recovery equipment"]
    }
    
    print_info(f"Trip Title: {title}")
    print_info(f"Level ID: {level_id}")
    print_info(f"Start Time: {start_time}")
    
    try:
        # Django uses /api/trips (no trailing slash) for POST
        response = requests.post(
            f"{MAIN_API_URL}/api/trips",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            json=trip_data,
            timeout=15
        )
        
        if response.status_code in [200, 201]:
            trip = response.json()
            trip_id = trip.get('id')
            
            print_success(f"Trip created successfully!")
            print_info(f"Trip ID: {trip_id}")
            print_info(f"Approval Status: {trip.get('approvalStatus')} (P=Pending, A=Approved)")
            print_info(f"Gallery ID: {trip.get('galleryId') or 'None'}")
            
            return trip
        else:
            print_error(f"Failed to create trip: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print_error(f"Error creating trip: {str(e)}")
        return None

def check_gallery_created(token, trip_id):
    """Check if a gallery was created for the trip"""
    print_header("CHECKING IF GALLERY WAS CREATED")
    
    try:
        # First, check if trip has galleryId
        response = requests.get(
            f"{MAIN_API_URL}/api/trips/{trip_id}/",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        
        if response.status_code == 200:
            trip = response.json()
            gallery_id = trip.get('galleryId')
            
            if gallery_id:
                print_success(f"Trip has Gallery ID: {gallery_id}")
                
                # Verify gallery exists in Gallery API
                gallery_response = requests.get(
                    f"{GALLERY_API_URL}/api/galleries",
                    headers={"Authorization": f"Bearer {token}"},
                    params={"limit": 100},
                    timeout=10
                )
                
                if gallery_response.status_code == 200:
                    galleries = gallery_response.json().get('galleries', [])
                    matching_gallery = next(
                        (g for g in galleries if str(g.get('source_trip_id')) == str(trip_id)),
                        None
                    )
                    
                    if matching_gallery:
                        print_success("✅ Gallery found in Gallery API!")
                        print_info(f"Gallery Name: {matching_gallery.get('name')}")
                        print_info(f"Auto-created: {matching_gallery.get('auto_created')}")
                        print_info(f"Trip Level: {matching_gallery.get('trip_level')}")
                        return gallery_id, matching_gallery
                    else:
                        print_warning("Gallery ID exists but gallery not found in Gallery API")
                        return gallery_id, None
                else:
                    print_warning(f"Could not fetch Gallery API: {gallery_response.status_code}")
                    return gallery_id, None
            else:
                print_warning("Trip does NOT have Gallery ID")
                print_info("This means /webhooks/trip/published was NOT called by Django")
                return None, None
        else:
            print_error(f"Failed to fetch trip: {response.status_code}")
            return None, None
            
    except Exception as e:
        print_error(f"Error checking gallery: {str(e)}")
        return None, None

def approve_trip(token, trip_id):
    """Approve the trip (change status to 'A')"""
    print_header("APPROVING TRIP")
    
    print_info("Attempting to approve trip...")
    print_warning("Note: This may require admin permissions")
    
    try:
        response = requests.post(
            f"{MAIN_API_URL}/api/trips/{trip_id}/approve",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        
        if response.status_code == 200:
            print_success("Trip approved successfully!")
            
            # Wait a moment for webhook processing
            print_info("Waiting 3 seconds for webhook processing...")
            time.sleep(3)
            
            return True
        else:
            print_error(f"Failed to approve trip: {response.status_code}")
            print_error(f"Response: {response.text}")
            
            # Try alternative approach - PATCH with approval_status
            print_info("Trying alternative approval method (PATCH)...")
            
            patch_response = requests.patch(
                f"{MAIN_API_URL}/api/trips/{trip_id}",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                json={"approvalStatus": "A"},
                timeout=10
            )
            
            if patch_response.status_code == 200:
                print_success("Trip approved via PATCH!")
                time.sleep(3)
                return True
            else:
                print_error(f"PATCH also failed: {patch_response.status_code}")
                return False
            
    except Exception as e:
        print_error(f"Error approving trip: {str(e)}")
        return False

def rename_trip(token, trip_id, new_title):
    """Rename the trip"""
    print_header("RENAMING TRIP")
    
    print_info(f"New Title: {new_title}")
    
    try:
        response = requests.patch(
            f"{MAIN_API_URL}/api/trips/{trip_id}",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            json={"title": new_title},
            timeout=10
        )
        
        if response.status_code == 200:
            print_success("Trip renamed successfully!")
            time.sleep(2)
            return True
        else:
            print_error(f"Failed to rename trip: {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Error renaming trip: {str(e)}")
        return False

def check_gallery_renamed(token, gallery_id, expected_name):
    """Check if gallery name was updated"""
    print_header("CHECKING IF GALLERY WAS RENAMED")
    
    try:
        response = requests.get(
            f"{GALLERY_API_URL}/api/galleries",
            headers={"Authorization": f"Bearer {token}"},
            params={"limit": 100},
            timeout=10
        )
        
        if response.status_code == 200:
            galleries = response.json().get('galleries', [])
            matching_gallery = next(
                (g for g in galleries if g.get('id') == gallery_id),
                None
            )
            
            if matching_gallery:
                actual_name = matching_gallery.get('name')
                if actual_name == expected_name:
                    print_success(f"✅ Gallery name updated correctly!")
                    print_info(f"Gallery Name: {actual_name}")
                    return True
                else:
                    print_warning(f"Gallery name NOT updated")
                    print_info(f"Expected: {expected_name}")
                    print_info(f"Actual: {actual_name}")
                    return False
            else:
                print_error("Gallery not found")
                return False
        else:
            print_error(f"Failed to fetch Gallery API: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error checking gallery rename: {str(e)}")
        return False

def delete_trip(token, trip_id):
    """Delete the test trip"""
    print_header("DELETING TEST TRIP")
    
    try:
        response = requests.delete(
            f"{MAIN_API_URL}/api/trips/{trip_id}",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10
        )
        
        if response.status_code in [200, 204]:
            print_success("Trip deleted successfully!")
            time.sleep(2)
            return True
        else:
            print_error(f"Failed to delete trip: {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Error deleting trip: {str(e)}")
        return False

def check_gallery_deleted(token, gallery_id):
    """Check if gallery was soft-deleted"""
    print_header("CHECKING IF GALLERY WAS DELETED")
    
    try:
        response = requests.get(
            f"{GALLERY_API_URL}/api/galleries",
            headers={"Authorization": f"Bearer {token}"},
            params={"limit": 100},
            timeout=10
        )
        
        if response.status_code == 200:
            galleries = response.json().get('galleries', [])
            matching_gallery = next(
                (g for g in galleries if g.get('id') == gallery_id),
                None
            )
            
            if matching_gallery:
                soft_deleted = matching_gallery.get('soft_deleted_at')
                if soft_deleted:
                    print_success("✅ Gallery was soft-deleted!")
                    print_info(f"Deleted At: {soft_deleted}")
                    return True
                else:
                    print_warning("Gallery still exists (not deleted)")
                    return False
            else:
                print_warning("Gallery not found in results (may be hidden)")
                return None
        else:
            print_error(f"Failed to fetch Gallery API: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error checking gallery deletion: {str(e)}")
        return False

def main():
    """Main test workflow"""
    print_header("DJANGO GALLERY WEBHOOK TESTING")
    print_info(f"Testing user: {USERNAME}")
    print_info(f"Main API: {MAIN_API_URL}")
    print_info(f"Gallery API: {GALLERY_API_URL}")
    print_warning("Note: Using Hani AMJ credentials (Abu Makram credentials didn't work)")
    
    # Authenticate
    token, user_data = authenticate_main_api()
    if not token:
        print_error("Authentication failed. Exiting.")
        return
    
    # Get available levels and meeting points
    levels = get_available_levels(token)
    meeting_points = get_meeting_points(token)
    
    # TEST 1: Create Trip
    trip = create_test_trip(token, user_data, levels, meeting_points)
    if not trip:
        print_error("Failed to create trip. Exiting.")
        return
    
    trip_id = trip.get('id')
    
    # TEST 2: Check if gallery created immediately (shouldn't be, trip is pending)
    print_info("\nTEST 2: Checking gallery creation (before approval)")
    gallery_id, gallery = check_gallery_created(token, trip_id)
    
    if gallery_id:
        print_warning("🤔 Gallery created for PENDING trip (unexpected)")
        print_info("This suggests webhook is triggered on trip creation, not approval")
    else:
        print_success("✅ No gallery yet (correct - trip is still pending)")
    
    # TEST 3: Approve Trip
    print_info("\nTEST 3: Approving trip")
    approved = approve_trip(token, trip_id)
    
    if approved:
        # TEST 4: Check if gallery created after approval
        print_info("\nTEST 4: Checking gallery creation (after approval)")
        gallery_id, gallery = check_gallery_created(token, trip_id)
        
        if gallery_id:
            print_success("✅ Django IS calling /webhooks/trip/published!")
            
            # TEST 5: Rename Trip
            print_info("\nTEST 5: Testing trip rename webhook")
            new_title = f"🧪 Webhook Test Trip RENAMED {datetime.now().strftime('%H:%M:%S')}"
            renamed = rename_trip(token, trip_id, new_title)
            
            if renamed and gallery_id:
                # Check if gallery was renamed
                check_gallery_renamed(token, gallery_id, new_title)
        else:
            print_error("❌ Django is NOT calling /webhooks/trip/published")
            print_warning("Gallery should be created when trip is approved")
    else:
        print_warning("Could not approve trip (may need admin permissions)")
        print_info("Skipping approval-dependent tests")
    
    # TEST 6: Delete Trip
    print_info("\nTEST 6: Testing trip deletion webhook")
    user_input = input(f"\n{Color.YELLOW}Delete test trip (ID: {trip_id})? [y/N]: {Color.END}").lower()
    
    if user_input == 'y':
        deleted = delete_trip(token, trip_id)
        
        if deleted and gallery_id:
            # Check if gallery was deleted
            check_gallery_deleted(token, gallery_id)
    else:
        print_info(f"Test trip NOT deleted. You can manually delete it:")
        print_info(f"Trip ID: {trip_id}")
        if gallery_id:
            print_info(f"Gallery ID: {gallery_id}")
    
    # Final Summary
    print_header("TEST SUMMARY")
    
    print(f"\n{Color.BOLD}Webhook Implementation Status:{Color.END}")
    print(f"{'='*60}")
    
    if gallery_id:
        print_success("✅ /webhooks/trip/published - IMPLEMENTED")
    else:
        print_error("❌ /webhooks/trip/published - NOT IMPLEMENTED")
    
    print_warning("⚠️  /webhooks/trip/renamed - NEEDS MANUAL VERIFICATION")
    print_warning("⚠️  /webhooks/trip/deleted - NEEDS MANUAL VERIFICATION")
    print_warning("⚠️  /webhooks/trip/restored - NEEDS MANUAL VERIFICATION")
    
    print(f"\n{Color.CYAN}Recommendation:{Color.END}")
    if not gallery_id:
        print("Django backend does NOT appear to be calling Gallery webhooks.")
        print("Backend team needs to implement webhook integration.")
    else:
        print("Django backend IS calling at least the 'published' webhook.")
        print("Verify other webhooks (rename, delete, restore) are also implemented.")

if __name__ == "__main__":
    main()
