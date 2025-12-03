#!/usr/bin/env python3
"""
Test Registration -> Login Flow
Simulates the exact user journey you experienced
"""

import requests
import time
import json

BASE_URL = "https://ap.ad4x4.com"

# Test credentials
TEST_USERNAME = f"test_hani_{int(time.time())}"
TEST_EMAIL = f"test_hani_{int(time.time())}@example.com"
TEST_PASSWORD = "Test1234!"

print("=" * 70)
print("TESTING REGISTRATION -> LOGIN FLOW")
print("=" * 70)

# Step 1: Register
print(f"\n📝 STEP 1: Registering new account...")
print(f"   Username: {TEST_USERNAME}")
print(f"   Email: {TEST_EMAIL}")
print(f"   Password: {TEST_PASSWORD}")

register_data = {
    "username": TEST_USERNAME,
    "email": TEST_EMAIL,
    "password": TEST_PASSWORD,
    "password2": TEST_PASSWORD,
    "firstName": "Test",
    "lastName": "User",
    "phone": "+971500000000"
}

try:
    register_response = requests.post(
        f"{BASE_URL}/api/auth/register/",
        json=register_data,
        timeout=10
    )
    
    if register_response.status_code == 201:
        print(f"✅ Registration successful! (201 Created)")
        print(f"   Response: {register_response.json()}")
    elif register_response.status_code == 400:
        print(f"⚠️  Registration validation error (400)")
        print(f"   Error: {register_response.json()}")
        exit(1)
    else:
        print(f"❌ Registration failed ({register_response.status_code})")
        print(f"   Response: {register_response.text}")
        exit(1)
        
except Exception as e:
    print(f"❌ Registration request failed: {e}")
    exit(1)

# Wait a moment for backend processing
print(f"\n⏳ Waiting 2 seconds for backend processing...")
time.sleep(2)

# Step 2: Try login with USERNAME
print(f"\n🔐 STEP 2A: Attempting login with USERNAME...")
print(f"   Login field: {TEST_USERNAME}")
print(f"   Password: {TEST_PASSWORD}")

login_data_username = {
    "login": TEST_USERNAME,  # Using username
    "password": TEST_PASSWORD
}

try:
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json=login_data_username,
        timeout=10
    )
    
    if login_response.status_code == 200:
        print(f"✅ Login with USERNAME successful!")
        response_data = login_response.json()
        print(f"   Token received: {response_data.get('token', response_data.get('access', 'N/A'))[:50]}...")
    elif login_response.status_code == 400:
        print(f"❌ Login with USERNAME failed (400 Bad Request)")
        print(f"   Error: {login_response.json()}")
    else:
        print(f"❌ Login with USERNAME failed ({login_response.status_code})")
        print(f"   Response: {login_response.text}")
        
except Exception as e:
    print(f"❌ Login request (username) failed: {e}")

# Step 3: Try login with EMAIL
print(f"\n🔐 STEP 2B: Attempting login with EMAIL...")
print(f"   Login field: {TEST_EMAIL}")
print(f"   Password: {TEST_PASSWORD}")

login_data_email = {
    "login": TEST_EMAIL,  # Using email
    "password": TEST_PASSWORD
}

try:
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json=login_data_email,
        timeout=10
    )
    
    if login_response.status_code == 200:
        print(f"✅ Login with EMAIL successful!")
        response_data = login_response.json()
        print(f"   Token received: {response_data.get('token', response_data.get('access', 'N/A'))[:50]}...")
    elif login_response.status_code == 400:
        print(f"❌ Login with EMAIL failed (400 Bad Request)")
        print(f"   Error: {login_response.json()}")
    else:
        print(f"❌ Login with EMAIL failed ({login_response.status_code})")
        print(f"   Response: {login_response.text}")
        
except Exception as e:
    print(f"❌ Login request (email) failed: {e}")

print(f"\n" + "=" * 70)
print("TEST COMPLETE")
print("=" * 70)
