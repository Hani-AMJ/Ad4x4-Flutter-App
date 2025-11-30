#!/usr/bin/env python3
"""
Simple Django Gallery Webhook Test
Tests if Django backend calls Gallery API webhooks
"""

import requests
import json
from datetime import datetime, timedelta

MAIN_API = "https://ap.ad4x4.com"
GALLERY_API = "https://media.ad4x4.com"

# Credentials
LOGIN = "Hani AMJ"
PASSWORD = "3213Plugin?"

def print_section(title):
    print(f"\n{'='*70}")
    print(f" {title}")
    print('='*70)

# Step 1: Login
print_section("Step 1: Authenticating")
response = requests.post(
    f"{MAIN_API}/api/auth/login/",
    json={"login": LOGIN, "password": PASSWORD}
)
token = response.json()['token']
print(f"✅ Authenticated! Token: {token[:40]}...")

headers = {"Authorization": f"Bearer {token}"}

# Step 2: Get user profile
print_section("Step 2: Getting User Profile")
profile = requests.get(f"{MAIN_API}/api/auth/profile/", headers=headers).json()
user_id = profile['id']
username = profile['username']
print(f"✅ User: {username} (ID: {user_id})")

# Step 3: Get levels
print_section("Step 3: Getting Trip Levels")
levels_response = requests.get(f"{MAIN_API}/api/levels/", headers=headers).json()
levels = levels_response.get('results', [])
print(f"✅ Found {len(levels)} levels")
level_id = levels[0]['id'] if levels else 1
print(f"   Using level: {levels[0]['name']} (ID: {level_id})")

# Step 4: Get meeting points
print_section("Step 4: Getting Meeting Points")
mp_response = requests.get(f"{MAIN_API}/api/meetingpoints/", headers=headers).json()
meeting_points = mp_response.get('results', [])
print(f"✅ Found {len(meeting_points)} meeting points")
meeting_point_id = meeting_points[0]['id'] if meeting_points else 1
print(f"   Using: {meeting_points[0]['name']} (ID: {meeting_point_id})")

# Step 5: Create test trip
print_section("Step 5: Creating Test Trip")
timestamp = datetime.now().strftime("%H%M%S")
trip_data = {
    "title": f"🧪 Webhook Test {timestamp}",
    "description": "Testing Gallery webhook integration",
    "startTime": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%dT10:00:00"),
    "endTime": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%dT16:00:00"),
    "cutOff": (datetime.now() + timedelta(days=6)).strftime("%Y-%m-%dT23:59:59"),
    "level": level_id,
    "lead": user_id,  # Must provide lead (trip creator)
    "meetingPoint": meeting_point_id,
    "capacity": 10,
    "allowWaitlist": True
}

response = requests.post(
    f"{MAIN_API}/api/trips",
    headers=headers,
    json=trip_data
)

if response.status_code not in [200, 201]:
    print(f"❌ Failed to create trip: {response.status_code}")
    print(f"   Response: {response.text}")
    exit(1)

trip = response.json()
print(f"✅ Trip created! Response keys: {list(trip.keys())}")

# Response is: {"success": true, "message": {...trip data...}}
trip_data = trip.get('message', trip)
trip_id = trip_data.get('id')

if not trip_id:
    print(f"❌ Could not find trip ID in response")
    exit(1)

print(f"   Trip ID: {trip_id}")
print(f"   Title: {trip_data.get('title')}")
print(f"   Status: {trip_data.get('approvalStatus')} (A=Auto-Approved!)")
print(f"   Gallery ID: {trip_data.get('galleryId') or 'None'}")

# Step 6: Check if gallery exists (shouldn't yet - trip is pending)
print_section("Step 6: Checking Gallery (Before Approval)")
if trip.get('galleryId'):
    print(f"⚠️  Gallery already created! ID: {trip['galleryId']}")
    print("   This means webhook fired on trip CREATION (not approval)")
else:
    print("✅ No gallery yet (correct - trip is pending)")

# Step 7: Get fresh trip data
print_section("Step 7: Getting Fresh Trip Data")
trip_fresh = requests.get(f"{MAIN_API}/api/trips/{trip_id}/", headers=headers).json()
print(f"   Approval Status: {trip_fresh.get('approvalStatus')}")
print(f"   Gallery ID: {trip_fresh.get('galleryId') or 'None'}")

#Step 8: Search for gallery by trip_id in Gallery API
print_section("Step 8: Searching Gallery API for Trip")
galleries_response = requests.get(
    f"{GALLERY_API}/api/galleries",
    headers=headers,
    params={"limit": 100}
)

if galleries_response.status_code == 200:
    galleries = galleries_response.json().get('galleries', [])
    matching = [g for g in galleries if str(g.get('source_trip_id')) == str(trip_id)]
    
    if matching:
        gallery = matching[0]
        print(f"🎉 FOUND Gallery in Gallery API!")
        print(f"   Gallery ID: {gallery['id']}")
        print(f"   Name: {gallery['name']}")
        print(f"   Auto-created: {gallery.get('auto_created')}")
        print(f"   Trip Level: {gallery.get('trip_level')}")
        print("\n✅ Django IS calling /webhooks/trip/published!")
    else:
        print("❌ No gallery found in Gallery API")
        print("   Django is NOT calling /webhooks/trip/published")
else:
    print(f"⚠️  Could not access Gallery API: {galleries_response.status_code}")

# Step 9: Summary
print_section("TEST SUMMARY")
print(f"Trip ID: {trip_id}")
print(f"Trip Status: {trip_fresh.get('approvalStatus')}")
print(f"Trip has galleryId: {'YES' if trip_fresh.get('galleryId') else 'NO'}")

if trip_fresh.get('galleryId'):
    print("\n🎯 RESULT: Django backend IS calling Gallery webhooks!")
    print("   Webhook triggered on: Trip CREATION (not approval)")
else:
    print("\n❌ RESULT: Django backend is NOT calling Gallery webhooks")
    print("   Expected: Gallery should be created when trip is published")

print(f"\n💡 You can view the trip at:")
print(f"   {MAIN_API}/admin/trips/trip/{trip_id}/")
print(f"\n💡 To clean up, delete the trip manually from admin panel")
