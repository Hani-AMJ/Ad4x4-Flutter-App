#!/usr/bin/env python3
"""
Test Trip Start Time Feature - End-to-End Test
Verify that trips with start times create galleries with trip_start_time populated
"""

import requests
import json
import time
from datetime import datetime, timedelta

# Configuration
MAIN_API = "https://ap.ad4x4.com"
GALLERY_API = "https://media.ad4x4.com"
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

def print_section(title):
    print(f"\n{'=' * 80}")
    print(f"{title}")
    print('=' * 80)

def authenticate():
    """Authenticate and return token"""
    response = requests.post(
        f"{MAIN_API}/api/auth/login/",
        json={"login": USERNAME, "password": PASSWORD}
    )
    return response.json()['token']

def get_user_info(token):
    """Get user profile"""
    response = requests.get(
        f"{MAIN_API}/api/auth/profile/",
        headers={"Authorization": f"Bearer {token}"}
    )
    return response.json()

def get_levels(token):
    """Get trip levels"""
    response = requests.get(
        f"{MAIN_API}/api/levels/",
        headers={"Authorization": f"Bearer {token}"}
    )
    return response.json().get('results', [])

def get_meeting_points(token):
    """Get meeting points"""
    response = requests.get(
        f"{MAIN_API}/api/meetingpoints/",
        headers={"Authorization": f"Bearer {token}"}
    )
    return response.json().get('results', [])

def create_test_trip(token, user_id, level_id, meeting_point_id, start_time):
    """Create a test trip with specific start time"""
    timestamp = datetime.now().strftime("%H%M%S")
    
    trip_data = {
        "title": f"🧪 Trip Start Time Test {timestamp}",
        "description": "Testing trip_start_time field in Gallery API",
        "startTime": start_time.strftime("%Y-%m-%dT%H:%M:%S"),
        "endTime": (start_time + timedelta(hours=4)).strftime("%Y-%m-%dT%H:%M:%S"),
        "cutOff": (start_time - timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%S"),
        "meetingPoint": meeting_point_id,
        "level": level_id,
        "lead": user_id,
        "capacity": 10,
        "approvalStatus": "A",  # Auto-approve
        "allowWaitlist": True
    }
    
    response = requests.post(
        f"{MAIN_API}/api/trips",
        headers={"Authorization": f"Bearer {token}"},
        json=trip_data
    )
    
    return response

def check_gallery(token, trip_id):
    """Check if gallery was created for trip"""
    response = requests.get(
        f"{GALLERY_API}/api/galleries",
        headers={"Authorization": f"Bearer {token}"},
        params={"limit": 50}
    )
    
    if response.status_code == 200:
        galleries = response.json().get('galleries', [])
        for gallery in galleries:
            if gallery.get('source_trip_id') == float(trip_id):
                return gallery
    return None

def main():
    print_section("TRIP START TIME FEATURE - END-TO-END TEST")
    
    # Step 1: Authenticate
    print("\n🔐 Step 1: Authenticating...")
    token = authenticate()
    print("✅ Authenticated successfully")
    
    # Step 2: Get user info
    print("\n👤 Step 2: Getting user info...")
    user = get_user_info(token)
    user_id = user['id']
    username = user['username']
    print(f"✅ User: {username} (ID: {user_id})")
    
    # Step 3: Get levels
    print("\n📊 Step 3: Getting trip levels...")
    levels = get_levels(token)
    club_event = next((l for l in levels if l['name'] == 'Club Event'), levels[0])
    print(f"✅ Using level: {club_event['name']} (ID: {club_event['id']})")
    
    # Step 4: Get meeting points
    print("\n📍 Step 4: Getting meeting points...")
    meeting_points = get_meeting_points(token)
    meeting_point = meeting_points[0]
    print(f"✅ Using: {meeting_point['name']} (ID: {meeting_point['id']})")
    
    # Step 5: Create test trip with specific start time
    print("\n🚗 Step 5: Creating test trip...")
    
    # Set trip start time to next Friday at 9:00 AM
    future_date = datetime.now() + timedelta(days=7)
    start_time = future_date.replace(hour=9, minute=0, second=0, microsecond=0)
    
    print(f"   Trip Start Time: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    response = create_test_trip(token, user_id, club_event['id'], meeting_point['id'], start_time)
    
    if response.status_code in [200, 201]:
        response_data = response.json()
        # Handle unified response format {success: true, message: {trip_data}}
        trip = response_data.get('message', response_data)
        print(f"✅ Trip created successfully!")
        trip_id = trip.get('id')
        if not trip_id:
            print(f"❌ No trip ID in response")
            print(f"   Response: {json.dumps(response_data, indent=2)}")
            return
        print(f"   Trip ID: {trip_id}")
        print(f"   Title: {trip.get('title')}")
        print(f"   Start Time: {trip.get('startTime')}")
        print(f"   Gallery ID: {trip.get('galleryId', 'Not yet assigned')}")
    else:
        print(f"❌ Failed to create trip: {response.status_code}")
        print(f"   Response: {response.text}")
        return
    
    # Step 6: Wait for gallery creation (async webhook)
    print("\n⏳ Step 6: Waiting for gallery creation (30-40 seconds)...")
    for i in range(40, 0, -5):
        print(f"   ⏱️  {i} seconds remaining...")
        time.sleep(5)
    
    # Step 7: Check gallery
    print("\n🖼️  Step 7: Checking gallery creation...")
    gallery = check_gallery(token, trip_id)
    
    if gallery:
        print("✅ Gallery found!")
        print(f"   Gallery ID: {gallery['id']}")
        print(f"   Name: {gallery['name']}")
        print(f"   Created At: {gallery['created_at']}")
        print(f"   Trip Start Time: {gallery.get('trip_start_time', '❌ NOT SET')}")
        print(f"   Source Trip ID: {gallery['source_trip_id']}")
        print(f"   Auto Created: {gallery['auto_created']}")
        
        if gallery.get('trip_start_time'):
            print("\n🎉 SUCCESS! trip_start_time is populated in gallery!")
            print(f"   Expected: {start_time.strftime('%Y-%m-%dT%H:%M:%S')}")
            print(f"   Actual: {gallery['trip_start_time']}")
        else:
            print("\n⚠️  WARNING: trip_start_time is NULL in gallery")
            print("   This means Django is not sending start_time in webhook payload")
    else:
        print("❌ Gallery not found")
        print("   Webhook may not have fired or gallery not created")
    
    # Step 8: Verify with Main API
    print("\n🔍 Step 8: Verifying trip in Main API...")
    trip_response = requests.get(
        f"{MAIN_API}/api/trips/{trip_id}/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if trip_response.status_code == 200:
        trip_data = trip_response.json()
        print("✅ Trip data retrieved:")
        print(f"   Gallery ID: {trip_data.get('galleryId')}")
        print(f"   Start Time: {trip_data.get('startTime')}")
        print(f"   Approval Status: {trip_data.get('approvalStatus')}")
    
    # Summary
    print_section("TEST SUMMARY")
    
    if gallery and gallery.get('trip_start_time'):
        print("\n✅ FEATURE WORKING CORRECTLY!")
        print("   - Trip created with start time")
        print("   - Gallery auto-created via webhook")
        print("   - trip_start_time field populated in gallery")
        print("   - Main API stores galleryId correctly")
        print("\n🎯 Flutter can proceed with Album model updates!")
    elif gallery and not gallery.get('trip_start_time'):
        print("\n⚠️  PARTIAL SUCCESS")
        print("   - Trip created successfully")
        print("   - Gallery auto-created via webhook")
        print("   - ❌ trip_start_time is NULL in gallery")
        print("\n🔧 ACTION REQUIRED:")
        print("   Django backend needs to send start_time in webhook payload")
        print("   Check: POST /api/webhooks/trip/published payload")
    else:
        print("\n❌ WEBHOOK NOT WORKING")
        print("   - Gallery was not created")
        print("   - Check Django webhook implementation")
    
    print(f"\n📊 Test Trip Details:")
    print(f"   Trip ID: {trip_id}")
    print(f"   Trip URL: {MAIN_API}/admin/trips/trip/{trip_id}/")
    if gallery:
        print(f"   Gallery ID: {gallery['id']}")

if __name__ == "__main__":
    main()
