#!/usr/bin/env python3
"""
Manual Trip Date Sync Test
Tests gallery synchronization when trip is updated
"""

import requests
import json
import time
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
        token = response.json().get('token')
        print(f"✅ Authenticated successfully")
        return token
    else:
        print(f"❌ Authentication failed: {response.status_code}")
        return None

def check_trip_and_gallery(token, trip_id):
    """Check trip details and associated gallery"""
    print(f"\n🔍 Checking trip {trip_id}...")
    
    # Get trip details
    response = requests.get(
        f"{MAIN_API}/api/trips/{trip_id}/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code != 200:
        print(f"❌ Trip not found: {response.status_code}")
        return None, None
    
    trip = response.json()
    title = trip.get('title')
    start_time = trip.get('startTime')
    gallery_id = trip.get('galleryId')
    
    print(f"✅ Trip found:")
    print(f"   Title: {title}")
    print(f"   Start Time: {start_time}")
    print(f"   Gallery ID: {gallery_id}")
    
    if not gallery_id:
        print(f"⚠️  No gallery associated with this trip yet")
        return trip, None
    
    # Check gallery
    print(f"\n🖼️  Checking gallery {gallery_id}...")
    gallery_response = requests.get(
        f"{GALLERY_API}/api/galleries/{gallery_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if gallery_response.status_code != 200:
        print(f"❌ Gallery not found: {gallery_response.status_code}")
        return trip, None
    
    gallery = gallery_response.json()
    print(f"✅ Gallery found:")
    print(f"   Name: {gallery.get('name')}")
    print(f"   Trip Start Time: {gallery.get('trip_start_time')}")
    print(f"   Created At: {gallery.get('created_at')}")
    
    return trip, gallery

def update_trip(token, trip_id, new_title=None, new_date=None):
    """Update trip name and/or date"""
    update_data = {}
    
    if new_title:
        update_data['title'] = new_title
        print(f"\n🔄 Updating trip title to: {new_title}")
    
    if new_date:
        update_data['startTime'] = new_date
        update_data['endTime'] = new_date
        print(f"🔄 Updating trip date to: {new_date}")
    
    if not update_data:
        print("⚠️  No updates specified")
        return False
    
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
        return True
    else:
        print(f"❌ Failed to update trip: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

def main():
    print("=" * 70)
    print("🧪 MANUAL TRIP DATE & NAME SYNCHRONIZATION TEST")
    print("=" * 70)
    print()
    print("📋 INSTRUCTIONS:")
    print("1. Create a test trip in Django Admin with a FUTURE date")
    print("2. Note the Trip ID")
    print("3. Run this script with the Trip ID")
    print("4. The script will show current trip and gallery details")
    print("5. You can then update the trip name/date and verify sync")
    print()
    print("=" * 70)
    
    # Get trip ID from user
    trip_id = input("\n🔢 Enter Trip ID to test: ").strip()
    
    if not trip_id or not trip_id.isdigit():
        print("❌ Invalid trip ID")
        return
    
    trip_id = int(trip_id)
    
    # Authenticate
    token = authenticate()
    if not token:
        return
    
    # Check initial state
    print("\n" + "=" * 70)
    print("📊 INITIAL STATE")
    print("=" * 70)
    
    trip, gallery = check_trip_and_gallery(token, trip_id)
    if not trip:
        return
    
    if not gallery:
        print("\n⚠️  Waiting for gallery to be created...")
        print("   The webhook may still be processing.")
        print("   Try again in a few seconds.")
        return
    
    # Ask for updates
    print("\n" + "=" * 70)
    print("🔄 UPDATE OPTIONS")
    print("=" * 70)
    
    update_choice = input("\nDo you want to update this trip? (y/n): ").strip().lower()
    if update_choice != 'y':
        print("✅ Test complete. No updates applied.")
        return
    
    # Get new title
    new_title = input("\nEnter new title (or press Enter to skip): ").strip()
    if not new_title:
        new_title = None
    
    # Get new date
    print("\nEnter new date (or press Enter to skip):")
    print("Format: YYYY-MM-DDTHH:MM:SS")
    print("Example: 2025-12-15T14:00:00")
    new_date = input("New date: ").strip()
    if not new_date:
        new_date = None
    
    # Apply updates
    if new_title or new_date:
        success = update_trip(token, trip_id, new_title, new_date)
        if not success:
            return
        
        # Wait for webhook
        print("\n⏳ Waiting 10 seconds for webhook to sync...")
        time.sleep(10)
        
        # Check updated state
        print("\n" + "=" * 70)
        print("📊 UPDATED STATE")
        print("=" * 70)
        
        updated_trip, updated_gallery = check_trip_and_gallery(token, trip_id)
        
        if updated_trip and updated_gallery:
            print("\n" + "=" * 70)
            print("✅ SYNC VERIFICATION")
            print("=" * 70)
            
            if new_title:
                trip_title = updated_trip.get('title')
                gallery_name = updated_gallery.get('name')
                print(f"\nTitle Sync:")
                print(f"  Trip: {trip_title}")
                print(f"  Gallery: {gallery_name}")
                print(f"  Match: {'✅ YES' if trip_title == gallery_name else '❌ NO'}")
            
            if new_date:
                trip_start = updated_trip.get('startTime')
                gallery_start = updated_gallery.get('trip_start_time')
                print(f"\nDate Sync:")
                print(f"  Trip: {trip_start}")
                print(f"  Gallery: {gallery_start}")
                
                # Compare dates (allow timezone differences)
                if trip_start and gallery_start:
                    try:
                        trip_dt = datetime.fromisoformat(trip_start.replace('Z', '+00:00'))
                        gallery_dt = datetime.fromisoformat(gallery_start.replace('Z', '+00:00'))
                        time_diff = abs((trip_dt - gallery_dt).total_seconds())
                        print(f"  Time Diff: {time_diff} seconds")
                        print(f"  Match: {'✅ YES' if time_diff < 3600 else '❌ NO'}")
                    except Exception as e:
                        print(f"  ⚠️  Could not compare dates: {e}")
    
    print("\n" + "=" * 70)
    print("✅ TEST COMPLETE")
    print("=" * 70)
    print(f"\n🔗 Admin URL: {MAIN_API}/admin/trips/trip/{trip_id}/")
    print(f"🖼️  Gallery ID: {gallery.get('id')}")
    print("\n💡 Check the Flutter app Gallery screen to see the changes!")

if __name__ == "__main__":
    main()
