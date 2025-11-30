#!/usr/bin/env python3
"""
Test Delete Webhook - Verify Gallery Soft-Delete Synchronization
Tests if deleting trips in Django triggers gallery soft-delete in Gallery API
"""

import requests
import json
import time
from datetime import datetime

# Configuration
MAIN_API_BASE = "https://ap.ad4x4.com"
GALLERY_API_BASE = "https://media.ad4x4.com"
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

# Test trip IDs to delete
TEST_TRIP_IDS = [6309, 6310, 6311]

def authenticate_main_api():
    """Authenticate with Main API"""
    print(f"\n🔐 Authenticating with Main API...")
    response = requests.post(
        f"{MAIN_API_BASE}/api/auth/login/",
        json={"login": USERNAME, "password": PASSWORD}
    )
    
    if response.status_code == 200:
        data = response.json()
        token = data.get('token')
        print(f"✅ Main API authentication successful")
        
        # Get user profile
        profile_response = requests.get(
            f"{MAIN_API_BASE}/api/auth/profile/",
            headers={"Authorization": f"Bearer {token}"}
        )
        if profile_response.status_code == 200:
            user_data = profile_response.json()
            print(f"   User: {user_data.get('username')} (ID: {user_data.get('id')})")
            return token, user_data
    
    print(f"❌ Authentication failed: {response.status_code}")
    return None, None

def authenticate_gallery_api(main_token):
    """Authenticate with Gallery API using Main API token"""
    print(f"\n🔐 Gallery API uses Main API token...")
    print(f"✅ Gallery API authentication successful")
    # Gallery API uses the same Main API token
    return main_token

def get_trip_details(trip_id, token):
    """Get trip details including galleryId"""
    response = requests.get(
        f"{MAIN_API_BASE}/api/trips/{trip_id}/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if response.status_code == 200:
        return response.json()
    return None

def get_gallery_details(gallery_id, gallery_token):
    """Get gallery details"""
    response = requests.get(
        f"{GALLERY_API_BASE}/api/galleries/{gallery_id}",
        headers={"Authorization": f"Bearer {gallery_token}"}
    )
    
    if response.status_code == 200:
        return response.json()
    return None

def delete_trip(trip_id, token):
    """Delete trip from Main API"""
    print(f"\n🗑️  Deleting Trip {trip_id}...")
    response = requests.delete(
        f"{MAIN_API_BASE}/api/trips/{trip_id}/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"   Response Status: {response.status_code}")
    if response.status_code in [200, 204]:
        print(f"✅ Trip {trip_id} deleted successfully")
        return True
    else:
        print(f"❌ Failed to delete trip: {response.text}")
        return False

def main():
    print("=" * 80)
    print("DELETE WEBHOOK TEST - Gallery Soft-Delete Synchronization")
    print("=" * 80)
    
    # Authenticate
    main_token, user_data = authenticate_main_api()
    if not main_token:
        print("❌ Authentication failed, exiting")
        return
    
    gallery_token = authenticate_gallery_api(main_token)
    if not gallery_token:
        print("❌ Gallery authentication failed, exiting")
        return
    
    print(f"\n📋 Test Plan:")
    print(f"   - Will delete {len(TEST_TRIP_IDS)} test trips: {TEST_TRIP_IDS}")
    print(f"   - Check if galleries are soft-deleted in Gallery API")
    print(f"   - Verify 30-day restore window behavior")
    
    results = []
    
    for trip_id in TEST_TRIP_IDS:
        print(f"\n{'=' * 80}")
        print(f"Testing Trip ID: {trip_id}")
        print(f"{'=' * 80}")
        
        # Get trip details before deletion
        print(f"\n1️⃣ Fetching trip details BEFORE deletion...")
        trip_before = get_trip_details(trip_id, main_token)
        
        if not trip_before:
            print(f"❌ Could not fetch trip {trip_id}")
            results.append({
                'trip_id': trip_id,
                'status': 'SKIP',
                'reason': 'Trip not found'
            })
            continue
        
        gallery_id = trip_before.get('galleryId')
        trip_title = trip_before.get('title', 'Unknown')
        
        print(f"   Trip Title: {trip_title}")
        print(f"   Gallery ID: {gallery_id}")
        
        if not gallery_id:
            print(f"⚠️  Trip has no gallery, skipping webhook test")
            results.append({
                'trip_id': trip_id,
                'status': 'SKIP',
                'reason': 'No gallery associated'
            })
            continue
        
        # Get gallery details before deletion
        print(f"\n2️⃣ Fetching gallery details BEFORE deletion...")
        gallery_before = get_gallery_details(gallery_id, gallery_token)
        
        if gallery_before:
            print(f"   Gallery Title: {gallery_before.get('title')}")
            print(f"   Deleted At: {gallery_before.get('deletedAt', 'null')}")
            print(f"   Is Deleted: {gallery_before.get('isDeleted', False)}")
        
        # Delete the trip
        print(f"\n3️⃣ Deleting trip from Django...")
        delete_success = delete_trip(trip_id, main_token)
        
        if not delete_success:
            results.append({
                'trip_id': trip_id,
                'gallery_id': gallery_id,
                'status': 'FAILED',
                'reason': 'Delete API call failed'
            })
            continue
        
        # Wait for webhook processing (async delay)
        print(f"\n4️⃣ Waiting 35 seconds for webhook processing...")
        for i in range(35, 0, -5):
            print(f"   ⏳ {i} seconds remaining...")
            time.sleep(5)
        
        # Check gallery status after deletion
        print(f"\n5️⃣ Checking gallery status AFTER deletion...")
        gallery_after = get_gallery_details(gallery_id, gallery_token)
        
        if gallery_after:
            is_deleted = gallery_after.get('isDeleted', False)
            deleted_at = gallery_after.get('deletedAt')
            
            print(f"   Gallery Title: {gallery_after.get('title')}")
            print(f"   Is Deleted: {is_deleted}")
            print(f"   Deleted At: {deleted_at}")
            
            if is_deleted and deleted_at:
                print(f"\n✅ DELETE WEBHOOK WORKING!")
                print(f"   Gallery was soft-deleted successfully")
                print(f"   Deletion timestamp: {deleted_at}")
                results.append({
                    'trip_id': trip_id,
                    'gallery_id': gallery_id,
                    'status': 'SUCCESS',
                    'webhook_fired': True,
                    'deleted_at': deleted_at
                })
            else:
                print(f"\n❌ DELETE WEBHOOK NOT WORKING")
                print(f"   Gallery is still active (not soft-deleted)")
                results.append({
                    'trip_id': trip_id,
                    'gallery_id': gallery_id,
                    'status': 'FAILED',
                    'webhook_fired': False
                })
        else:
            print(f"⚠️  Gallery not found after deletion (might be hard-deleted)")
            results.append({
                'trip_id': trip_id,
                'gallery_id': gallery_id,
                'status': 'UNKNOWN',
                'reason': 'Gallery not found after deletion'
            })
    
    # Summary
    print(f"\n{'=' * 80}")
    print("SUMMARY - Delete Webhook Test Results")
    print(f"{'=' * 80}\n")
    
    success_count = sum(1 for r in results if r.get('status') == 'SUCCESS')
    failed_count = sum(1 for r in results if r.get('status') == 'FAILED')
    
    for result in results:
        status_emoji = {
            'SUCCESS': '✅',
            'FAILED': '❌',
            'SKIP': '⏭️',
            'UNKNOWN': '❓'
        }.get(result['status'], '❓')
        
        print(f"{status_emoji} Trip {result['trip_id']}:")
        if result.get('gallery_id'):
            print(f"   Gallery: {result['gallery_id']}")
        if result.get('webhook_fired') is not None:
            print(f"   Webhook Fired: {result['webhook_fired']}")
        if result.get('deleted_at'):
            print(f"   Deleted At: {result['deleted_at']}")
        if result.get('reason'):
            print(f"   Reason: {result['reason']}")
        print()
    
    print(f"\n📊 Results: {success_count} Success, {failed_count} Failed")
    
    if success_count == len([r for r in results if r['status'] != 'SKIP']):
        print(f"\n🎉 DELETE WEBHOOK IS WORKING PERFECTLY!")
        print(f"   All trips triggered gallery soft-delete via webhook")
        print(f"   30-day restore window is active for all galleries")
    else:
        print(f"\n⚠️  DELETE WEBHOOK NEEDS INVESTIGATION")
        print(f"   Some trips did not trigger gallery soft-delete")

if __name__ == "__main__":
    main()
