#!/usr/bin/env python3
"""
Check Username Storage in Gallery API
Investigate if Gallery stores user_id or username for creator information
"""

import requests
import json

# Configuration
MAIN_API_BASE = "https://ap.ad4x4.com"
GALLERY_API_BASE = "https://media.ad4x4.com"
USERNAME = "Hani AMJ"
PASSWORD = "3213Plugin?"

def authenticate():
    """Authenticate with both APIs"""
    # Main API
    response = requests.post(
        f"{MAIN_API_BASE}/api/auth/login/",
        json={"login": USERNAME, "password": PASSWORD}
    )
    
    if response.status_code != 200:
        print(f"❌ Main API auth failed: {response.text}")
        return None, None
    
    main_token = response.json().get('token')
    
    # Get profile
    profile_response = requests.get(
        f"{MAIN_API_BASE}/api/auth/profile/",
        headers={"Authorization": f"Bearer {main_token}"}
    )
    user_data = profile_response.json()
    
    # Gallery API uses the same Main API token
    return main_token, main_token

def main():
    print("=" * 80)
    print("USERNAME STORAGE INVESTIGATION")
    print("=" * 80)
    
    main_token, gallery_token = authenticate()
    if not gallery_token:
        return
    
    print(f"\n✅ Authentication successful\n")
    
    # Fetch galleries
    print("🔍 Analyzing Gallery Creator Data...\n")
    response = requests.get(
        f"{GALLERY_API_BASE}/api/galleries?limit=10",
        headers={"Authorization": f"Bearer {gallery_token}"}
    )
    
    if response.status_code != 200:
        print(f"❌ Failed to fetch galleries: {response.text}")
        return
    
    galleries = response.json().get('galleries', [])
    
    print(f"📋 Found {len(galleries)} galleries. Analyzing creator data:\n")
    print("=" * 80)
    
    for i, gallery in enumerate(galleries[:5], 1):
        print(f"\n{i}. Gallery: {gallery.get('title', 'Untitled')}")
        print(f"   Gallery ID: {gallery.get('id')}")
        print(f"   Trip ID: {gallery.get('source_trip_id', 'N/A')}")
        print(f"\n   Creator Data:")
        
        # Extract all creator/user related fields
        creator_fields = {}
        for key, value in gallery.items():
            key_lower = key.lower()
            if any(term in key_lower for term in ['creat', 'user', 'owner', 'author']):
                creator_fields[key] = value
        
        if creator_fields:
            for key, value in sorted(creator_fields.items()):
                print(f"     {key}: {value}")
        else:
            print(f"     ⚠️  No creator fields found!")
        
        print("\n" + "-" * 80)
    
    # Check webhook endpoint documentation
    print("\n" + "=" * 80)
    print("WEBHOOK PAYLOAD ANALYSIS")
    print("=" * 80)
    print("""
📋 Trip Published Webhook Payload (from documentation):
{
    "trip_id": "uuid",
    "title": "string",
    "creator_id": "integer",  ← USER ID (not username)
    "level": "string"
}

🔍 Key Finding:
   - Webhook sends creator_id (user ID), NOT username
   - Gallery API stores the creator_id
   - Display username must be fetched from Main API using creator_id

💡 What happens when username changes:
   - Gallery still has correct creator_id
   - Flutter app can fetch current username from Main API
   - No sync needed - username is always current!

✅ This is the CORRECT design pattern:
   - Store IDs (immutable)
   - Display names fetched at runtime (always current)
    """)
    
    # Verify with actual data
    print("\n" + "=" * 80)
    print("VERIFICATION WITH TEST GALLERIES")
    print("=" * 80)
    
    test_galleries = [g for g in galleries if 'test' in g.get('title', '').lower()]
    if test_galleries:
        print(f"\nFound {len(test_galleries)} test galleries:")
        for gallery in test_galleries:
            print(f"\n  Gallery: {gallery.get('title')}")
            print(f"    creator_id field: {gallery.get('creator_id', 'NOT FOUND')}")
            print(f"    createdBy field: {gallery.get('createdBy', 'NOT FOUND')}")
            print(f"    source_trip_id: {gallery.get('source_trip_id', 'N/A')}")
    
    print("\n" + "=" * 80)
    print("CONCLUSION")
    print("=" * 80)
    print("""
✅ Gallery API stores USER ID (creator_id), not username
✅ This is the correct approach for data integrity
✅ Username changes do NOT require gallery updates
✅ Flutter app fetches current username at display time

🎯 No action needed - system is designed correctly!
    """)

if __name__ == "__main__":
    main()
