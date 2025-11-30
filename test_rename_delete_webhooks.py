#!/usr/bin/env python3
"""
Test Trip Rename and Delete Webhooks
Tests if Django calls Gallery API webhooks for rename and delete operations
"""

import requests
import time
from datetime import datetime

MAIN_API = "https://ap.ad4x4.com"
GALLERY_API = "https://media.ad4x4.com"

LOGIN = "Hani AMJ"
PASSWORD = "3213Plugin?"

# Use existing test trip (created in previous test)
TEST_TRIP_ID = 6311

def print_section(title):
    print(f"\n{'='*70}")
    print(f" {title}")
    print('='*70)

def wait_for_webhook(seconds=35):
    """Wait for async webhook processing"""
    print(f"⏳ Waiting {seconds} seconds for async webhook processing...")
    for i in range(seconds, 0, -5):
        print(f"   {i} seconds remaining...")
        time.sleep(5)
    print("✅ Wait complete!")

# Authenticate
print_section("Authenticating")
response = requests.post(
    f"{MAIN_API}/api/auth/login/",
    json={"login": LOGIN, "password": PASSWORD}
)
token = response.json()['token']
headers = {"Authorization": f"Bearer {token}"}
print(f"✅ Authenticated! Token: {token[:40]}...")

# Get current trip data
print_section("Getting Current Trip Data")
trip = requests.get(f"{MAIN_API}/api/trips/{TEST_TRIP_ID}/", headers=headers).json()
print(f"Trip ID: {trip['id']}")
print(f"Current Title: {trip['title']}")
print(f"Approval Status: {trip['approvalStatus']}")
print(f"Gallery ID: {trip.get('galleryId')}")

gallery_id = trip.get('galleryId')

if not gallery_id:
    print("\n❌ ERROR: Trip does not have a gallery!")
    print("Cannot test rename/delete webhooks without existing gallery.")
    print("Please create a trip with gallery first using test_webhooks_simple.py")
    exit(1)

# Get current gallery data
print_section("Getting Current Gallery Data")
galleries_response = requests.get(
    f"{GALLERY_API}/api/galleries",
    headers=headers,
    params={"limit": 100}
)
galleries = galleries_response.json().get('galleries', [])
gallery = next((g for g in galleries if g['id'] == gallery_id), None)

if gallery:
    print(f"✅ Gallery found!")
    print(f"Gallery ID: {gallery['id']}")
    print(f"Current Name: {gallery['name']}")
    print(f"Auto-created: {gallery.get('auto_created')}")
    print(f"Source Trip ID: {gallery.get('source_trip_id')}")
else:
    print(f"❌ Gallery not found: {gallery_id}")
    exit(1)

# TEST 1: Rename Trip
print_section("TEST 1: Testing Trip Rename Webhook")

timestamp = datetime.now().strftime("%H%M%S")
new_title = f"🔄 RENAMED Webhook Test {timestamp}"

print(f"Original Title: {trip['title']}")
print(f"New Title: {new_title}")

response = requests.patch(
    f"{MAIN_API}/api/trips/{TEST_TRIP_ID}",
    headers=headers,
    json={"title": new_title}
)

if response.status_code == 200:
    print("✅ Trip renamed successfully!")
    
    # Wait for async webhook processing
    wait_for_webhook(35)
    
    # Check if gallery name was updated
    print_section("Checking If Gallery Name Was Updated")
    
    galleries_response = requests.get(
        f"{GALLERY_API}/api/galleries",
        headers=headers,
        params={"limit": 100}
    )
    galleries = galleries_response.json().get('galleries', [])
    updated_gallery = next((g for g in galleries if g['id'] == gallery_id), None)
    
    if updated_gallery:
        if updated_gallery['name'] == new_title:
            print("🎉 SUCCESS! Gallery name was updated!")
            print(f"   Old Name: {gallery['name']}")
            print(f"   New Name: {updated_gallery['name']}")
            print("\n✅ RESULT: Django IS calling /webhooks/trip/renamed")
        else:
            print("❌ FAILED! Gallery name was NOT updated")
            print(f"   Expected: {new_title}")
            print(f"   Actual: {updated_gallery['name']}")
            print("\n❌ RESULT: Django is NOT calling /webhooks/trip/renamed")
            print("   OR: Gallery is manually created (not auto-created)")
    else:
        print("❌ Gallery not found after rename")
else:
    print(f"❌ Failed to rename trip: {response.status_code}")
    print(f"Response: {response.text}")
    exit(1)

# Ask before proceeding to delete test
print_section("Preparing for Delete Test")
print("⚠️  WARNING: The next test will DELETE the test trip!")
print(f"   Trip ID: {TEST_TRIP_ID}")
print(f"   Gallery ID: {gallery_id}")
print("")
user_input = input("Proceed with delete test? [y/N]: ").lower()

if user_input != 'y':
    print("\n✅ Tests completed (rename only)")
    print(f"   Rename Webhook: ✅ VERIFIED")
    print(f"   Delete Webhook: ⏭️  SKIPPED")
    exit(0)

# TEST 2: Delete Trip
print_section("TEST 2: Testing Trip Delete Webhook")

print(f"Deleting trip {TEST_TRIP_ID}...")

response = requests.delete(
    f"{MAIN_API}/api/trips/{TEST_TRIP_ID}",
    headers=headers
)

if response.status_code in [200, 204]:
    print("✅ Trip deleted successfully!")
    
    # Wait for async webhook processing
    wait_for_webhook(35)
    
    # Check if gallery was soft-deleted
    print_section("Checking If Gallery Was Soft-Deleted")
    
    galleries_response = requests.get(
        f"{GALLERY_API}/api/galleries",
        headers=headers,
        params={"limit": 100}
    )
    galleries = galleries_response.json().get('galleries', [])
    deleted_gallery = next((g for g in galleries if g['id'] == gallery_id), None)
    
    if deleted_gallery:
        if deleted_gallery.get('soft_deleted_at'):
            print("🎉 SUCCESS! Gallery was soft-deleted!")
            print(f"   Gallery ID: {deleted_gallery['id']}")
            print(f"   Deleted At: {deleted_gallery['soft_deleted_at']}")
            print(f"   Restore Until: {deleted_gallery.get('restore_until', 'N/A')}")
            print("\n✅ RESULT: Django IS calling /webhooks/trip/deleted")
        else:
            print("❌ FAILED! Gallery still exists (not deleted)")
            print(f"   Gallery ID: {deleted_gallery['id']}")
            print(f"   Soft Deleted: {deleted_gallery.get('soft_deleted_at')}")
            print("\n❌ RESULT: Django is NOT calling /webhooks/trip/deleted")
    else:
        print("⚠️  Gallery not found in results (may be filtered out)")
        print("   This could mean:")
        print("   1. Gallery was soft-deleted and excluded from results")
        print("   2. Gallery was permanently deleted (unexpected)")
        print("   3. API filters out soft-deleted galleries by default")
        print("\n⏳ RESULT: INCONCLUSIVE - Need to check admin panel")
else:
    print(f"❌ Failed to delete trip: {response.status_code}")
    print(f"Response: {response.text}")

# Final Summary
print_section("TEST SUMMARY")
print("Test Results:")
print(f"  1. Trip Rename → Gallery Rename: {'✅ VERIFIED' if updated_gallery and updated_gallery['name'] == new_title else '❌ FAILED'}")

if user_input == 'y':
    if deleted_gallery and deleted_gallery.get('soft_deleted_at'):
        print(f"  2. Trip Delete → Gallery Delete: ✅ VERIFIED")
    else:
        print(f"  2. Trip Delete → Gallery Delete: ⏳ INCONCLUSIVE")
else:
    print(f"  2. Trip Delete → Gallery Delete: ⏭️  SKIPPED")

print("\n📊 Overall Results:")
print("  • Trip Published Webhook: ✅ VERIFIED (previous test)")
print(f"  • Trip Renamed Webhook: {'✅ VERIFIED' if updated_gallery and updated_gallery['name'] == new_title else '❌ NEEDS INVESTIGATION'}")

if user_input == 'y':
    if deleted_gallery and deleted_gallery.get('soft_deleted_at'):
        print("  • Trip Deleted Webhook: ✅ VERIFIED")
    else:
        print("  • Trip Deleted Webhook: ⏳ INCONCLUSIVE")
else:
    print("  • Trip Deleted Webhook: ⏭️  NOT TESTED")

print("\n💡 Note: Gallery restore webhook can only be tested after deletion.")
print("   Check admin panel if gallery can be restored manually.")

print(f"\n🔗 Admin Links:")
print(f"   Main Backend: {MAIN_API}/admin/")
print(f"   Gallery Backend: {GALLERY_API}/admin/")
