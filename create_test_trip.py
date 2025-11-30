#!/usr/bin/env python3
"""
Create Test Trip for Gallery Date Sync Testing
Creates a trip with future date for Hani to test in UI
"""

import requests
import json
from datetime import datetime, timedelta

# API Configuration
MAIN_API = "https://ap.ad4x4.com"
GALLERY_API = "https://media.ad4x4.com"

# Credentials
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

def authenticate():
    """Authenticate with Main API"""
    print("🔐 Authenticating...")
    response = requests.post(
        f"{MAIN_API}/api/auth/login/",
        json={"login": USERNAME, "password": PASSWORD}
    )
    
    if response.status_code == 200:
        data = response.json()
        token = data.get('token')
        user_id = data.get('user', {}).get('id')
        print(f"✅ Authenticated as {USERNAME}")
        if user_id:
            print(f"   User ID: {user_id}")
        return token, user_id
    else:
        print(f"❌ Authentication failed: {response.status_code}")
        print(f"   Response: {response.text}")
        return None, None

def create_trip_via_admin(token):
    """
    Create trip using Django admin action endpoint
    """
    # Future date: 10 days from now at 2:00 PM
    future_date = datetime.now() + timedelta(days=10)
    trip_date = future_date.replace(hour=14, minute=0, second=0, microsecond=0)
    trip_date_str = trip_date.strftime("%Y-%m-%dT%H:%M:%S")
    
    # Random identifier for uniqueness
    import random
    random_id = random.randint(10000, 99999)
    
    print(f"\n🚀 Creating test trip via Django admin...")
    print(f"   Title: 🧪 Gallery Date Sync Test {random_id}")
    print(f"   Start Time: {trip_date_str}")
    print(f"   Future Date: {trip_date.strftime('%A, %B %d, %Y at %I:%M %p')}")
    
    # Try creating via admin action endpoint
    trip_data = {
        "title": f"🧪 Gallery Date Sync Test {random_id}",
        "description": "Testing gallery date synchronization. Feel free to rename and change date from UI!",
        "levelNumeric": 1,  # Club Event
        "startTime": trip_date_str,
        "endTime": trip_date_str,
        "meetingPoint": 142,  # 2nd December Cafeteria
        "allowWaitlist": True,
        "maxParticipants": 20,
        "status": "published",
        "action": "create_trip"
    }
    
    # Try action endpoint
    response = requests.post(
        f"{MAIN_API}/api/admin-actions/",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json=trip_data
    )
    
    print(f"\nResponse Status: {response.status_code}")
    print(f"Response: {response.text[:500]}")
    
    if response.status_code in [200, 201]:
        try:
            result = response.json()
            # Try to extract trip ID from various response formats
            trip_id = (result.get('message', {}).get('id') or 
                      result.get('id') or 
                      result.get('trip_id') or
                      result.get('data', {}).get('id'))
            
            if trip_id:
                return trip_id, trip_date_str
            else:
                print("⚠️  Trip may have been created but ID not found in response")
                print(f"   Full response: {json.dumps(result, indent=2)}")
                return None, trip_date_str
        except:
            print("⚠️  Could not parse response as JSON")
            return None, trip_date_str
    
    return None, trip_date_str

def wait_for_gallery(token, trip_id, max_wait=30):
    """Wait for gallery to be created via webhook"""
    print(f"\n⏳ Waiting for gallery creation (webhook processing)...")
    
    import time
    for i in range(max_wait):
        time.sleep(1)
        
        # Check trip for gallery ID
        response = requests.get(
            f"{MAIN_API}/api/trips/{trip_id}/",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        if response.status_code == 200:
            trip = response.json()
            gallery_id = trip.get('galleryId')
            
            if gallery_id:
                print(f"✅ Gallery created! Gallery ID: {gallery_id}")
                return gallery_id
            
            if i % 5 == 0 and i > 0:
                print(f"   Still waiting... ({i}s)")
    
    print(f"⚠️  Gallery not created within {max_wait} seconds")
    return None

def check_gallery(token, gallery_id):
    """Check gallery details"""
    print(f"\n🖼️  Fetching gallery details...")
    response = requests.get(
        f"{GALLERY_API}/api/galleries/{gallery_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        gallery = response.json()
        print(f"✅ Gallery verified!")
        print(f"   Name: {gallery.get('name')}")
        print(f"   Trip Start Time: {gallery.get('trip_start_time')}")
        print(f"   Source Trip ID: {gallery.get('source_trip_id')}")
        return gallery
    else:
        print(f"⚠️  Could not fetch gallery: {response.status_code}")
        return None

def main():
    print("=" * 70)
    print("🧪 CREATING TEST TRIP FOR HANI")
    print("=" * 70)
    
    # Authenticate
    token, user_id = authenticate()
    if not token:
        print("\n❌ Cannot proceed without authentication")
        return
    
    # Create trip
    trip_id, trip_date = create_trip_via_admin(token)
    
    if not trip_id:
        print("\n❌ Failed to create trip automatically")
        print("\n📋 MANUAL CREATION REQUIRED:")
        print("=" * 70)
        print("Please create a trip manually in Django Admin:")
        print(f"1. Go to: {MAIN_API}/admin/trips/trip/add/")
        print(f"2. Title: 🧪 Gallery Date Sync Test")
        print(f"3. Start Time: {trip_date}")
        print(f"4. Level: Club Event")
        print(f"5. Status: Published")
        print(f"6. Save and note the Trip ID")
        print("=" * 70)
        return
    
    print(f"\n✅ Trip created successfully!")
    print(f"   Trip ID: {trip_id}")
    print(f"   Admin URL: {MAIN_API}/admin/trips/trip/{trip_id}/")
    
    # Wait for gallery
    gallery_id = wait_for_gallery(token, trip_id)
    
    if gallery_id:
        # Check gallery details
        gallery = check_gallery(token, gallery_id)
        
        if gallery:
            print("\n" + "=" * 70)
            print("✅ TEST TRIP READY!")
            print("=" * 70)
            print(f"\n📝 Trip Details:")
            print(f"   Trip ID: {trip_id}")
            print(f"   Gallery ID: {gallery_id}")
            print(f"   Start Date: {trip_date}")
            print(f"   Admin URL: {MAIN_API}/admin/trips/trip/{trip_id}/")
            
            print(f"\n🎯 Next Steps for Hani:")
            print(f"1. ✅ Check Flutter Gallery screen")
            print(f"2. ✅ Verify trip date is displayed with 📅 icon")
            print(f"3. ✅ Edit trip from Django Admin:")
            print(f"   - Change the title")
            print(f"   - Change the start date")
            print(f"4. ✅ Refresh Flutter Gallery screen")
            print(f"5. ✅ Verify gallery updated automatically!")
            
            print("\n🔗 Flutter App URL:")
            print("   https://5060-irq33n4be81tpb3bh5d3b-de59bda9.sandbox.novita.ai")
            print("\n💡 The gallery should show the trip date with a calendar icon!")
            print("=" * 70)
    else:
        print("\n⚠️  Gallery creation is still processing")
        print(f"   Trip ID: {trip_id}")
        print(f"   Check Django admin: {MAIN_API}/admin/trips/trip/{trip_id}/")
        print(f"   The galleryId field should populate within 30 seconds")

if __name__ == "__main__":
    main()
