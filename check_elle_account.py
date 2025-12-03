#!/usr/bin/env python3
"""
Check if Elle's account exists in the backend
Using admin credentials to search for the user
"""

import requests
import json

BASE_URL = "https://ap.ad4x4.com"

# Admin credentials
ADMIN_USERNAME = "Hani AMJ"
ADMIN_PASSWORD = "3213Plugin?"

# User to search for
SEARCH_USERNAME = "Elle"
SEARCH_EMAIL = "Richelle@ad4x4.com"

print("=" * 70)
print("CHECKING IF ELLE'S ACCOUNT EXISTS")
print("=" * 70)

# Step 1: Login as admin
print(f"\n🔐 STEP 1: Logging in as admin...")
print(f"   Username: {ADMIN_USERNAME}")

login_data = {
    "login": ADMIN_USERNAME,
    "password": ADMIN_PASSWORD
}

try:
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json=login_data,
        timeout=10
    )
    
    print(f"   Status: {login_response.status_code}")
    
    if login_response.status_code == 200:
        print(f"✅ Login successful!")
        
        # Get token from response
        response_data = login_response.json()
        token = response_data.get('token') or response_data.get('access')
        
        if token:
            print(f"   Token: ...{token[-20:]}")
        else:
            print(f"   Response keys: {list(response_data.keys())}")
            token = None
            
    else:
        print(f"❌ Login failed!")
        print(f"   Response: {login_response.text}")
        exit(1)
        
except Exception as e:
    print(f"❌ Login request failed: {e}")
    import traceback
    traceback.print_exc()
    exit(1)

# Prepare headers with token
if token:
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
else:
    print(f"⚠️  No token found, trying without authorization...")
    headers = {"Content-Type": "application/json"}

# Step 2: Search for Elle by username
print(f"\n🔍 STEP 2: Searching for user by username...")
print(f"   Username: {SEARCH_USERNAME}")

try:
    # Try members endpoint with search
    search_response = requests.get(
        f"{BASE_URL}/api/members/",
        params={"search": SEARCH_USERNAME},
        headers=headers,
        timeout=10
    )
    
    print(f"   Status: {search_response.status_code}")
    
    if search_response.status_code == 200:
        results = search_response.json()
        
        if isinstance(results, dict):
            members = results.get('results', [])
            count = results.get('count', len(members))
        else:
            members = results
            count = len(members)
        
        print(f"   Found {count} result(s)")
        
        if count > 0:
            print(f"\n✅ FOUND USER(S) MATCHING '{SEARCH_USERNAME}':")
            for i, member in enumerate(members[:5], 1):  # Show first 5
                print(f"\n   User {i}:")
                print(f"      ID: {member.get('id')}")
                print(f"      Username: {member.get('username')}")
                print(f"      Email: {member.get('email', 'N/A')}")
                print(f"      First Name: {member.get('firstName', 'N/A')}")
                print(f"      Last Name: {member.get('lastName', 'N/A')}")
                print(f"      Phone: {member.get('phone', 'N/A')}")
                print(f"      Level: {member.get('level', 'N/A')}")
                print(f"      Active: {member.get('isActive', 'N/A')}")
        else:
            print(f"\n⚠️  No users found matching '{SEARCH_USERNAME}'")
            
    else:
        print(f"   ⚠️  Search failed: {search_response.status_code}")
        print(f"   Response: {search_response.text[:200]}")
        
except Exception as e:
    print(f"❌ Search request failed: {e}")
    import traceback
    traceback.print_exc()

# Step 3: Search for Elle by email
print(f"\n🔍 STEP 3: Searching for user by email...")
print(f"   Email: {SEARCH_EMAIL}")

try:
    search_response = requests.get(
        f"{BASE_URL}/api/members/",
        params={"search": SEARCH_EMAIL},
        headers=headers,
        timeout=10
    )
    
    print(f"   Status: {search_response.status_code}")
    
    if search_response.status_code == 200:
        results = search_response.json()
        
        if isinstance(results, dict):
            members = results.get('results', [])
            count = results.get('count', len(members))
        else:
            members = results
            count = len(members)
        
        print(f"   Found {count} result(s)")
        
        if count > 0:
            print(f"\n✅ FOUND USER(S) MATCHING '{SEARCH_EMAIL}':")
            for i, member in enumerate(members[:5], 1):
                print(f"\n   User {i}:")
                print(f"      ID: {member.get('id')}")
                print(f"      Username: {member.get('username')}")
                print(f"      Email: {member.get('email', 'N/A')}")
                print(f"      First Name: {member.get('firstName', 'N/A')}")
                print(f"      Last Name: {member.get('lastName', 'N/A')}")
                print(f"      Phone: {member.get('phone', 'N/A')}")
                print(f"      Level: {member.get('level', 'N/A')}")
                print(f"      Active: {member.get('isActive', 'N/A')}")
        else:
            print(f"\n⚠️  No users found matching '{SEARCH_EMAIL}'")
            
    else:
        print(f"   ⚠️  Search failed: {search_response.status_code}")
        print(f"   Response: {search_response.text[:200]}")
        
except Exception as e:
    print(f"❌ Search request failed: {e}")

# Step 4: Try to get profile info (if admin has access to user management)
print(f"\n🔍 STEP 4: Checking available API endpoints...")

# Try to list all available endpoints to find user management
try:
    # Check if there's a users endpoint
    for endpoint in ['/api/users/', '/api/auth/users/', '/api/admin/users/']:
        try:
            response = requests.get(
                f"{BASE_URL}{endpoint}",
                headers=headers,
                timeout=5
            )
            if response.status_code in [200, 403]:  # 403 means endpoint exists but no permission
                print(f"   Found endpoint: {endpoint} (Status: {response.status_code})")
        except:
            pass
            
except Exception as e:
    print(f"   Endpoint discovery error: {e}")

print(f"\n" + "=" * 70)
print("SUMMARY")
print("=" * 70)
print("""
If Elle's account was found:
  ✅ Account was created despite 500 error
  → Login should work with correct credentials
  → Issue might be password mismatch or account inactive

If Elle's account was NOT found:
  ❌ Registration failed completely
  → 500 error prevented account creation
  → Backend needs to be fixed before registration works
""")
print("=" * 70)
