#!/usr/bin/env python3
"""
Test Registration with Richelle's credential pattern
"""

import requests
import time
import json

BASE_URL = "https://ap.ad4x4.com"

# Test credentials matching your pattern
TEST_USERNAME = f"TestUser_{int(time.time())}"
TEST_EMAIL = f"testuser_{int(time.time())}@ad4x4.com"
TEST_PASSWORD = "3213Plugin?"  # Same pattern as yours (numbers + letters + special chars)

print("=" * 70)
print("TESTING REGISTRATION WITH YOUR CREDENTIAL PATTERN")
print("=" * 70)

# Step 1: Register
print(f"\n📝 STEP 1: Registering new account...")
print(f"   Username: {TEST_USERNAME}")
print(f"   Email: {TEST_EMAIL}")
print(f"   Password pattern: Numbers + Letters + Special char")

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
    
    print(f"\n📊 Registration Response:")
    print(f"   Status Code: {register_response.status_code}")
    
    if register_response.status_code == 201:
        print(f"✅ Registration successful!")
        try:
            print(f"   Response: {json.dumps(register_response.json(), indent=2)}")
        except:
            print(f"   Response: {register_response.text}")
    elif register_response.status_code == 400:
        print(f"⚠️  Validation error:")
        try:
            errors = register_response.json()
            for field, messages in errors.items():
                print(f"   - {field}: {messages}")
        except:
            print(f"   {register_response.text}")
    elif register_response.status_code == 500:
        print(f"❌ Server error - Backend issue")
        print(f"   This might indicate a backend problem, not a client issue")
    else:
        print(f"❌ Unexpected status: {register_response.status_code}")
        print(f"   Response: {register_response.text[:200]}")
        
except Exception as e:
    print(f"❌ Registration request failed: {e}")
    import traceback
    traceback.print_exc()
    exit(1)

# Only proceed with login if registration succeeded
if register_response.status_code != 201:
    print(f"\n⚠️  Registration did not succeed (status {register_response.status_code})")
    print(f"   Skipping login test")
    exit(1)

# Wait for backend processing
print(f"\n⏳ Waiting 2 seconds for backend processing...")
time.sleep(2)

# Step 2A: Try login with USERNAME
print(f"\n🔐 STEP 2A: Login attempt with USERNAME")
print(f"   Login: {TEST_USERNAME}")

login_data_username = {
    "login": TEST_USERNAME,
    "password": TEST_PASSWORD
}

try:
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json=login_data_username,
        timeout=10
    )
    
    print(f"   Status Code: {login_response.status_code}")
    
    if login_response.status_code == 200:
        print(f"✅ Login with USERNAME successful!")
        try:
            response_data = login_response.json()
            print(f"   Token: ...{str(response_data.get('token', response_data.get('access', '')))[-20:]}")
        except:
            print(f"   Response: {login_response.text[:100]}")
    else:
        print(f"❌ Login with USERNAME failed")
        try:
            print(f"   Error: {login_response.json()}")
        except:
            print(f"   Response: {login_response.text[:200]}")
        
except Exception as e:
    print(f"❌ Login request failed: {e}")

# Step 2B: Try login with EMAIL
print(f"\n🔐 STEP 2B: Login attempt with EMAIL")
print(f"   Login: {TEST_EMAIL}")

login_data_email = {
    "login": TEST_EMAIL,
    "password": TEST_PASSWORD
}

try:
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json=login_data_email,
        timeout=10
    )
    
    print(f"   Status Code: {login_response.status_code}")
    
    if login_response.status_code == 200:
        print(f"✅ Login with EMAIL successful!")
        try:
            response_data = login_response.json()
            print(f"   Token: ...{str(response_data.get('token', response_data.get('access', '')))[-20:]}")
        except:
            print(f"   Response: {login_response.text[:100]}")
    else:
        print(f"❌ Login with EMAIL failed")
        try:
            print(f"   Error: {login_response.json()}")
        except:
            print(f"   Response: {login_response.text[:200]}")
        
except Exception as e:
    print(f"❌ Login request failed: {e}")

print(f"\n" + "=" * 70)
print("ANALYSIS")
print("=" * 70)
print("""
If registration succeeded but login failed, possible causes:
1. Account needs email verification before login
2. Backend has different password requirements than client validation
3. Account created but marked as inactive/unverified
4. Special characters in password causing encoding issues
""")
print("=" * 70)
