#!/usr/bin/env python3
"""
Comprehensive API Endpoint Testing Script
Tests all auth-related endpoints and validation capabilities
"""

import requests
import json
from datetime import datetime

# API Configuration
BASE_URL = "https://ap.ad4x4.com"
TEST_EMAIL = "test_new_user_" + datetime.now().strftime("%Y%m%d%H%M%S") + "@test.com"
TEST_USERNAME = "test_user_" + datetime.now().strftime("%Y%m%d%H%M%S")

# Test Results Storage
test_results = {
    "timestamp": datetime.now().isoformat(),
    "base_url": BASE_URL,
    "tests": []
}

def log_test(name, endpoint, method, status_code, success, response_data=None, error=None):
    """Log test result"""
    result = {
        "test_name": name,
        "endpoint": endpoint,
        "method": method,
        "status_code": status_code,
        "success": success,
        "timestamp": datetime.now().isoformat()
    }
    
    if response_data:
        result["response_data"] = response_data
    if error:
        result["error"] = str(error)
    
    test_results["tests"].append(result)
    
    status = "✅" if success else "❌"
    print(f"{status} {name}: {method} {endpoint} -> {status_code}")
    if response_data:
        print(f"   Response: {json.dumps(response_data, indent=2)[:200]}...")
    if error:
        print(f"   Error: {error}")
    print()

def test_endpoint(name, endpoint, method="GET", data=None, headers=None, expected_status=None):
    """Generic endpoint test function"""
    url = f"{BASE_URL}{endpoint}"
    
    if headers is None:
        headers = {"Content-Type": "application/json"}
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=30)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=30)
        elif method == "PUT":
            response = requests.put(url, json=data, headers=headers, timeout=30)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=30)
        
        # Check for redirects
        if response.history:
            print(f"   ⚠️  REDIRECT DETECTED:")
            for resp in response.history:
                print(f"      {resp.status_code} -> {resp.url}")
            print(f"      Final: {response.status_code} -> {response.url}")
        
        try:
            response_data = response.json()
        except:
            response_data = {"raw_response": response.text[:500]}
        
        success = expected_status is None or response.status_code == expected_status
        
        log_test(name, endpoint, method, response.status_code, success, response_data)
        
        return response.status_code, response_data, success
        
    except requests.exceptions.Timeout:
        log_test(name, endpoint, method, 0, False, error="Request timeout (30s)")
        return 0, None, False
    except requests.exceptions.ConnectionError as e:
        log_test(name, endpoint, method, 0, False, error=f"Connection error: {e}")
        return 0, None, False
    except Exception as e:
        log_test(name, endpoint, method, 0, False, error=str(e))
        return 0, None, False

print("=" * 80)
print("AD4x4 API ENDPOINT COMPREHENSIVE TESTING")
print("=" * 80)
print()

# Test 1: Register endpoint (with and without trailing slash)
print("🔍 TEST GROUP 1: REGISTRATION ENDPOINT")
print("-" * 80)

print("\n📍 Test 1a: Register WITHOUT trailing slash")
test_endpoint(
    "Register (no slash)",
    "/api/auth/register",
    method="POST",
    data={
        "username": TEST_USERNAME,
        "email": TEST_EMAIL,
        "password": "TestPass123!",
        "password2": "TestPass123!"
    }
)

print("\n📍 Test 1b: Register WITH trailing slash")
test_endpoint(
    "Register (with slash)",
    "/api/auth/register/",
    method="POST",
    data={
        "username": TEST_USERNAME + "_2",
        "email": TEST_EMAIL.replace("@", "_2@"),
        "password": "TestPass123!",
        "password2": "TestPass123!"
    }
)

# Test 2: Login endpoint
print("\n🔍 TEST GROUP 2: LOGIN ENDPOINT")
print("-" * 80)

print("\n📍 Test 2a: Login WITHOUT trailing slash")
test_endpoint(
    "Login (no slash)",
    "/api/auth/login",
    method="POST",
    data={
        "login": "Hani AMJ",
        "password": "test_password_placeholder"  # This will fail but shows endpoint behavior
    }
)

print("\n📍 Test 2b: Login WITH trailing slash")
test_endpoint(
    "Login (with slash)",
    "/api/auth/login/",
    method="POST",
    data={
        "login": "Hani AMJ",
        "password": "test_password_placeholder"
    }
)

# Test 3: Validators endpoint (CRITICAL for live validation)
print("\n🔍 TEST GROUP 3: VALIDATORS ENDPOINT (Live Validation)")
print("-" * 80)

print("\n📍 Test 3a: Validate USERNAME (existing)")
test_endpoint(
    "Validate existing username",
    "/api/validators/",
    method="POST",
    data={"username": "Hani AMJ"}
)

print("\n📍 Test 3b: Validate USERNAME (new/available)")
test_endpoint(
    "Validate new username",
    "/api/validators/",
    method="POST",
    data={"username": "test_available_user_12345"}
)

print("\n📍 Test 3c: Validate EMAIL (existing)")
test_endpoint(
    "Validate existing email",
    "/api/validators/",
    method="POST",
    data={"email": "hani_janem@hotmail.com"}
)

print("\n📍 Test 3d: Validate EMAIL (new/available)")
test_endpoint(
    "Validate new email",
    "/api/validators/",
    method="POST",
    data={"email": "test_available_email_12345@test.com"}
)

print("\n📍 Test 3e: Validate PHONE (existing)")
test_endpoint(
    "Validate existing phone",
    "/api/validators/",
    method="POST",
    data={"phone": "+971501166676"}
)

print("\n📍 Test 3f: Validate PHONE (new/available)")
test_endpoint(
    "Validate new phone",
    "/api/validators/",
    method="POST",
    data={"phone": "+971500000000"}
)

print("\n📍 Test 3g: Validate MULTIPLE fields")
test_endpoint(
    "Validate multiple fields",
    "/api/validators/",
    method="POST",
    data={
        "username": "test_multi",
        "email": "test_multi@test.com",
        "phone": "+971500000001"
    }
)

# Test 4: Profile endpoint (check authentication behavior)
print("\n🔍 TEST GROUP 4: PROFILE ENDPOINT (Auth Check)")
print("-" * 80)

print("\n📍 Test 4a: Profile WITHOUT auth token")
test_endpoint(
    "Profile (no auth)",
    "/api/auth/profile/",
    method="GET"
)

print("\n📍 Test 4b: Profile WITH trailing slash")
test_endpoint(
    "Profile (with slash, no auth)",
    "/api/auth/profile/",
    method="GET"
)

# Test 5: Other auth endpoints
print("\n🔍 TEST GROUP 5: OTHER AUTH ENDPOINTS")
print("-" * 80)

print("\n📍 Test 5a: Logout endpoint")
test_endpoint(
    "Logout",
    "/api/auth/logout/",
    method="POST"
)

print("\n📍 Test 5b: Change password endpoint")
test_endpoint(
    "Change password",
    "/api/auth/change-password/",
    method="POST",
    data={
        "oldPassword": "old",
        "password": "new",
        "passwordConfirm": "new"
    }
)

# Save test results
print("\n" + "=" * 80)
print("SAVING TEST RESULTS")
print("=" * 80)

with open('api_endpoint_test_results.json', 'w') as f:
    json.dump(test_results, f, indent=2)

print(f"✅ Test results saved to: api_endpoint_test_results.json")

# Summary
print("\n" + "=" * 80)
print("TEST SUMMARY")
print("=" * 80)

total_tests = len(test_results["tests"])
successful_tests = sum(1 for t in test_results["tests"] if t["success"])
failed_tests = total_tests - successful_tests

print(f"Total Tests: {total_tests}")
print(f"Successful: {successful_tests} ✅")
print(f"Failed: {failed_tests} ❌")
print(f"Success Rate: {(successful_tests/total_tests*100):.1f}%")

# Critical findings
print("\n" + "=" * 80)
print("CRITICAL FINDINGS")
print("=" * 80)

# Check for redirects
redirects_found = []
for test in test_results["tests"]:
    if "redirect" in test.get("response_data", {}).get("raw_response", "").lower():
        redirects_found.append(test["endpoint"])

if redirects_found:
    print("⚠️  REDIRECTS DETECTED on:")
    for endpoint in redirects_found:
        print(f"   - {endpoint}")
else:
    print("✅ No redirects detected")

# Check validator endpoint functionality
validator_tests = [t for t in test_results["tests"] if "validators" in t["endpoint"].lower()]
if validator_tests:
    print(f"\n📋 Validator Endpoint Tests: {len(validator_tests)}")
    print("   Status codes:", [t["status_code"] for t in validator_tests])
    
    validator_working = all(t["status_code"] in [200, 201] for t in validator_tests)
    if validator_working:
        print("   ✅ Validators endpoint appears to be working!")
    else:
        print("   ❌ Validators endpoint may have issues")

print("\n" + "=" * 80)
print("TEST COMPLETE")
print("=" * 80)
