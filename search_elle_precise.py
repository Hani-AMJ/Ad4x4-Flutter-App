#!/usr/bin/env python3
"""
Precise search for Elle's account
"""

import requests
import json

BASE_URL = "https://ap.ad4x4.com"

# Admin credentials
ADMIN_USERNAME = "Hani AMJ"
ADMIN_PASSWORD = "3213Plugin?"

print("=" * 70)
print("PRECISE SEARCH FOR ELLE'S ACCOUNT")
print("=" * 70)

# Login
print(f"\n🔐 Logging in as admin...")

login_response = requests.post(
    f"{BASE_URL}/api/auth/login/",
    json={"login": ADMIN_USERNAME, "password": ADMIN_PASSWORD},
    timeout=10
)

if login_response.status_code != 200:
    print(f"❌ Login failed: {login_response.status_code}")
    exit(1)

token = login_response.json().get('token') or login_response.json().get('access')
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

print(f"✅ Logged in successfully")

# Method 1: Get all members and filter locally
print(f"\n🔍 Method 1: Fetching recent members and filtering...")

try:
    # Get first page sorted by ID descending (most recent first)
    response = requests.get(
        f"{BASE_URL}/api/members/",
        params={"ordering": "-id", "pageSize": 50},  # Get last 50 users
        headers=headers,
        timeout=10
    )
    
    if response.status_code == 200:
        data = response.json()
        members = data.get('results', []) if isinstance(data, dict) else data
        
        print(f"   Fetched {len(members)} recent members")
        
        # Search for Elle or Richelle
        found = []
        for member in members:
            username = str(member.get('username', '')).lower()
            email = str(member.get('email', '')).lower()
            firstname = str(member.get('firstName', '')).lower()
            
            if ('elle' in username or 'richelle' in email or 
                'elle' in firstname or email == 'richelle@ad4x4.com'):
                found.append(member)
        
        if found:
            print(f"\n✅ FOUND {len(found)} MATCHING USER(S):")
            for member in found:
                print(f"\n   📋 Account Details:")
                print(f"      ID: {member.get('id')}")
                print(f"      Username: {member.get('username')}")
                print(f"      Email: {member.get('email')}")
                print(f"      First Name: {member.get('firstName')}")
                print(f"      Last Name: {member.get('lastName')}")
                print(f"      Phone: {member.get('phone')}")
                print(f"      Level: {member.get('level')}")
                print(f"      Created: {member.get('createdAt', 'N/A')}")
        else:
            print(f"\n⚠️  No users matching 'Elle' or 'Richelle@ad4x4.com' in recent 50 members")
            
    else:
        print(f"   Failed: {response.status_code}")
        
except Exception as e:
    print(f"   Error: {e}")

# Method 2: Try username exact match with validators endpoint
print(f"\n🔍 Method 2: Checking if username 'Elle' exists via validators...")

try:
    response = requests.post(
        f"{BASE_URL}/api/validators/",
        json={"username": "Elle"},
        timeout=10
    )
    
    if response.status_code == 200:
        result = response.json()
        username_valid = result.get('username', {}).get('valid')
        
        if username_valid == False:
            print(f"   ✅ Username 'Elle' EXISTS (validator says it's taken)")
        elif username_valid == True:
            print(f"   ❌ Username 'Elle' DOES NOT EXIST (validator says it's available)")
        else:
            print(f"   ⚠️  Unclear result: {result}")
    else:
        print(f"   Failed: {response.status_code}")
        
except Exception as e:
    print(f"   Error: {e}")

# Method 3: Check email with validators
print(f"\n🔍 Method 3: Checking if email 'Richelle@ad4x4.com' exists via validators...")

try:
    response = requests.post(
        f"{BASE_URL}/api/validators/",
        json={"email": "Richelle@ad4x4.com"},
        timeout=10
    )
    
    if response.status_code == 200:
        result = response.json()
        email_valid = result.get('email', {}).get('valid')
        
        if email_valid == False:
            print(f"   ✅ Email 'Richelle@ad4x4.com' EXISTS (validator says it's taken)")
        elif email_valid == True:
            print(f"   ❌ Email 'Richelle@ad4x4.com' DOES NOT EXIST (validator says it's available)")
        else:
            print(f"   ⚠️  Unclear result: {result}")
    else:
        print(f"   Failed: {response.status_code}")
        
except Exception as e:
    print(f"   Error: {e}")

# Method 4: Try searching all pages
print(f"\n🔍 Method 4: Deep search through multiple pages...")

try:
    found_elle = False
    page = 1
    max_pages = 10  # Search first 10 pages
    
    while page <= max_pages and not found_elle:
        response = requests.get(
            f"{BASE_URL}/api/members/",
            params={"page": page, "pageSize": 100, "ordering": "-id"},
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            members = data.get('results', [])
            
            for member in members:
                username = str(member.get('username', '')).lower()
                email = str(member.get('email', '')).lower()
                
                if username == 'elle' or email == 'richelle@ad4x4.com':
                    found_elle = True
                    print(f"\n   ✅ FOUND ELLE on page {page}!")
                    print(f"\n   📋 Account Details:")
                    print(f"      ID: {member.get('id')}")
                    print(f"      Username: {member.get('username')}")
                    print(f"      Email: {member.get('email')}")
                    print(f"      First Name: {member.get('firstName')}")
                    print(f"      Last Name: {member.get('lastName')}")
                    print(f"      Phone: {member.get('phone')}")
                    break
            
            if not found_elle:
                print(f"   Page {page}: Not found (checked {len(members)} users)")
                page += 1
        else:
            print(f"   Page {page} failed: {response.status_code}")
            break
    
    if not found_elle:
        print(f"\n   ❌ Elle not found in first {max_pages} pages (first {max_pages * 100} users)")
        
except Exception as e:
    print(f"   Error: {e}")

print(f"\n" + "=" * 70)
print("CONCLUSION")
print("=" * 70)
