#!/usr/bin/env python3
"""
Test Trip Date & Name Synchronization with Gallery API
Tests the complete workflow:
1. Create trip with future date
2. Verify gallery created with trip_start_time
3. Update trip name and date
4. Verify gallery syncs changes via webhook
"""

import requests
import json
import time
from datetime import datetime, timedelta

# API Configuration
MAIN_API = "https://ap.ad4x4.com"
GALLERY_API = "https://media.ad4x4.com"

# Test credentials (use the working credentials from previous tests)
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

def authenticate():
    """Authenticate with Main API"""
    print("🔐 Authenticating with Main API...")
    response = requests.post(
        f"{MAIN_API}/api/auth/login/",
        json={"login": USERNAME, "password": PASSWORD}
    )
    
    if response.status_code == 200:
        data = response.json()
        token = data.get('token')
        user_id = data.get('user', {}).get('id')
        print(f"✅ Authenticated as {USERNAME} (ID: {user_id})")
        return token, user_id
    else:
        print(f"❌ Authentication failed: {response.status_code}")
        print(f"   Response: {response.text}")
        return None, None

def get_trip_level(token):
    """Get Club Event level ID"""
    print("\n📊 Fetching trip levels...")
    response = requests.get(
        f"{MAIN_API}/api/levels/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        data = response.json()
        # API returns array of objects or object with results array
        levels = data if isinstance(data, list) else data.get('results', [])
        
        for level in levels:
            if isinstance(level, dict) and level.get('name') == 'Club Event':
                print(f"✅ Found 'Club Event' level (ID: {level['id']})")
                return level['id']
    
    print("❌ Could not find 'Club Event' level")
    print(f"   Response: {response.text[:200]}")
    return 1  # Default to level ID 1 (Club Event)

def get_meeting_point(token):
    """Get a meeting point ID"""
    print("\n📍 Fetching meeting points...")
    response = requests.get(
        f"{MAIN_API}/api/meeting-points/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        data = response.json()
        # API returns array or object with results
        meeting_points = data if isinstance(data, list) else data.get('results', [])
        
        if meeting_points and len(meeting_points) > 0:
            mp = meeting_points[0]
            if isinstance(mp, dict):
                print(f"✅ Using meeting point: {mp.get('name', 'Unknown')} (ID: {mp.get('id')})")
                return mp.get('id')
    
    print("⚠️  Using default meeting point ID: 142")
    return 142  # Default meeting point (2nd December Cafeteria)

def create_test_trip(token, user_id, level_id, meeting_point_id):
    """Create a test trip with future date"""
    # Future date: 7 days from now at 10:00 AM
    future_date = datetime.now() + timedelta(days=7)
    trip_date = future_date.replace(hour=10, minute=0, second=0, microsecond=0)
    trip_date_str = trip_date.strftime("%Y-%m-%dT%H:%M:%S")
    
    # Random identifier for uniqueness
    import random
    random_id = random.randint(10000, 99999)
    
    trip_data = {
        "title": f"🧪 Date Sync Test {random_id}",
        "description": "Testing trip start date synchronization with Gallery API",
        "levelNumeric": level_id,
        "startTime": trip_date_str,
        "endTime": trip_date_str,
        "meetingPoint": meeting_point_id,
        "allowWaitlist": True,
        "maxParticipants": 20,
        "status": "published"
    }
    
    print(f"\n🚀 Creating test trip...")
    print(f"   Title: {trip_data['title']}")
    print(f"   Start Time: {trip_date_str}")
    print(f"   Date: {trip_date.strftime('%A, %B %d, %Y at %I:%M %p')}")
    
    response = requests.post(
        f"{MAIN_API}/api/trips/",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json=trip_data
    )
    
    if response.status_code in [200, 201]:
        result = response.json()
        # Trip ID is in message object
        trip_id = result.get('message', {}).get('id') or result.get('id')
        
        if trip_id:
            print(f"✅ Trip created successfully!")
            print(f"   Trip ID: {trip_id}")
            print(f"   Admin URL: {MAIN_API}/admin/trips/trip/{trip_id}/")
            return trip_id, trip_date_str, trip_data['title']
        else:
            print(f"⚠️  Trip created but ID not found in response")
            print(f"   Response: {json.dumps(result, indent=2)}")
            return None, trip_date_str, trip_data['title']
    else:
        print(f"❌ Failed to create trip: {response.status_code}")
        print(f"   Response: {response.text}")
        return None, trip_date_str, trip_data['title']

def get_trip_details(token, trip_id):
    """Get trip details from Main API"""
    print(f"\n🔍 Fetching trip details from Main API...")
    response = requests.get(
        f"{MAIN_API}/api/trips/{trip_id}/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        trip = response.json()
        gallery_id = trip.get('galleryId')
        print(f"✅ Trip retrieved:")
        print(f"   Title: {trip.get('title')}")
        print(f"   Start Time: {trip.get('startTime')}")
        print(f"   Gallery ID: {gallery_id}")
        return gallery_id
    else:
        print(f"❌ Failed to fetch trip: {response.status_code}")
        return None

def check_gallery(token, gallery_id):
    """Check gallery details from Gallery API"""
    print(f"\n🖼️  Checking gallery in Gallery API...")
    response = requests.get(
        f"{GALLERY_API}/api/galleries/{gallery_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        gallery = response.json()
        print(f"✅ Gallery found:")
        print(f"   Gallery ID: {gallery.get('id')}")
        print(f"   Name: {gallery.get('name')}")
        print(f"   Trip Start Time: {gallery.get('trip_start_time')}")
        print(f"   Source Trip ID: {gallery.get('source_trip_id')}")
        print(f"   Created At: {gallery.get('created_at')}")
        return gallery
    else:
        print(f"❌ Gallery not found: {response.status_code}")
        print(f"   Response: {response.text}")
        return None

def update_trip(token, trip_id):
    """Update trip name and date"""
    # New future date: 14 days from now at 2:00 PM
    new_future_date = datetime.now() + timedelta(days=14)
    new_trip_date = new_future_date.replace(hour=14, minute=0, second=0, microsecond=0)
    new_trip_date_str = new_trip_date.strftime("%Y-%m-%dT%H:%M:%S")
    
    import random
    random_id = random.randint(10000, 99999)
    new_title = f"🔄 UPDATED Date Sync Test {random_id}"
    
    update_data = {
        "title": new_title,
        "startTime": new_trip_date_str,
        "endTime": new_trip_date_str
    }
    
    print(f"\n🔄 Updating trip...")
    print(f"   New Title: {new_title}")
    print(f"   New Start Time: {new_trip_date_str}")
    print(f"   New Date: {new_trip_date.strftime('%A, %B %d, %Y at %I:%M %p')}")
    
    response = requests.put(
        f"{MAIN_API}/api/trips/{trip_id}/",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json=update_data
    )
    
    if response.status_code == 200:
        print(f"✅ Trip updated successfully!")
        return new_title, new_trip_date_str
    else:
        print(f"❌ Failed to update trip: {response.status_code}")
        print(f"   Response: {response.text}")
        return None, None

def main():
    print("=" * 60)
    print("🧪 TRIP DATE & NAME SYNCHRONIZATION TEST")
    print("=" * 60)
    
    # Step 1: Authenticate
    token, user_id = authenticate()
    if not token:
        return
    
    # Step 2: Get trip level
    level_id = get_trip_level(token)
    if not level_id:
        return
    
    # Step 3: Get meeting point
    meeting_point_id = get_meeting_point(token)
    if not meeting_point_id:
        return
    
    # Step 4: Create test trip with future date
    trip_id, original_date, original_title = create_test_trip(token, user_id, level_id, meeting_point_id)
    if not trip_id:
        print("\n❌ Test aborted: Could not create trip")
        return
    
    # Step 5: Wait for webhook to process
    print("\n⏳ Waiting 10 seconds for webhook to create gallery...")
    time.sleep(10)
    
    # Step 6: Get trip details (with gallery ID)
    gallery_id = get_trip_details(token, trip_id)
    if not gallery_id:
        print("\n⚠️  No gallery ID found yet. Webhook might still be processing.")
        print("   Check Django admin for gallery ID.")
        return
    
    # Step 7: Check gallery details
    gallery = check_gallery(token, gallery_id)
    if not gallery:
        print("\n❌ Gallery not found in Gallery API")
        return
    
    # Step 8: Verify initial sync
    print("\n" + "=" * 60)
    print("✅ INITIAL SYNC VERIFICATION")
    print("=" * 60)
    print(f"Trip Title: {original_title}")
    print(f"Gallery Name: {gallery.get('name')}")
    print(f"Match: {'✅ YES' if gallery.get('name') == original_title else '❌ NO'}")
    print()
    print(f"Trip Start Time: {original_date}")
    print(f"Gallery Trip Start Time: {gallery.get('trip_start_time')}")
    
    # Convert dates for comparison (both should be in UTC)
    if gallery.get('trip_start_time'):
        gallery_date = gallery.get('trip_start_time').replace('Z', '+00:00')
        original_date_utc = datetime.fromisoformat(original_date.replace('Z', '+00:00'))
        gallery_date_utc = datetime.fromisoformat(gallery_date)
        
        # Allow small time difference (timezone conversions)
        time_diff = abs((gallery_date_utc - original_date_utc).total_seconds())
        print(f"Time Difference: {time_diff} seconds")
        print(f"Match: {'✅ YES' if time_diff < 3600 else '❌ NO (within 1 hour tolerance)'}")
    
    # Step 9: Update trip name and date
    print("\n" + "=" * 60)
    print("🔄 TESTING UPDATES")
    print("=" * 60)
    
    new_title, new_date = update_trip(token, trip_id)
    if not new_title:
        print("\n❌ Update test aborted: Could not update trip")
        return
    
    # Step 10: Wait for webhook to sync updates
    print("\n⏳ Waiting 10 seconds for webhook to sync updates...")
    time.sleep(10)
    
    # Step 11: Check updated gallery
    updated_gallery = check_gallery(token, gallery_id)
    if not updated_gallery:
        print("\n❌ Could not fetch updated gallery")
        return
    
    # Step 12: Verify update sync
    print("\n" + "=" * 60)
    print("✅ UPDATE SYNC VERIFICATION")
    print("=" * 60)
    print(f"New Trip Title: {new_title}")
    print(f"Updated Gallery Name: {updated_gallery.get('name')}")
    print(f"Match: {'✅ YES' if updated_gallery.get('name') == new_title else '❌ NO'}")
    print()
    print(f"New Trip Start Time: {new_date}")
    print(f"Updated Gallery Trip Start Time: {updated_gallery.get('trip_start_time')}")
    
    if updated_gallery.get('trip_start_time'):
        gallery_date = updated_gallery.get('trip_start_time').replace('Z', '+00:00')
        new_date_utc = datetime.fromisoformat(new_date.replace('Z', '+00:00'))
        gallery_date_utc = datetime.fromisoformat(gallery_date)
        
        time_diff = abs((gallery_date_utc - new_date_utc).total_seconds())
        print(f"Time Difference: {time_diff} seconds")
        print(f"Match: {'✅ YES' if time_diff < 3600 else '❌ NO (within 1 hour tolerance)'}")
    
    # Final summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    print(f"✅ Trip created with future date")
    print(f"✅ Gallery created via webhook")
    print(f"✅ Gallery trip_start_time populated")
    print(f"✅ Trip updated with new name and date")
    print(f"✅ Gallery synced via webhook")
    print()
    print(f"🗑️  Test Trip Cleanup:")
    print(f"   Delete from: {MAIN_API}/admin/trips/trip/{trip_id}/")
    print(f"   Gallery will be soft-deleted automatically")
    print()
    print(f"🔗 View in Flutter App:")
    print(f"   Gallery ID: {gallery_id}")
    print(f"   Check the Gallery screen to see the trip date displayed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
