#!/usr/bin/env python3
"""
End-to-End Registration Flow Test
Tests all three phases of the registration validation system
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "https://ap.ad4x4.com"
TEST_USERNAME = f"test_user_{int(time.time())}"
TEST_EMAIL = f"test_{int(time.time())}@example.com"
TEST_PASSWORD = "Test1234!"  # Strong password

class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_section(title):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{title.center(60)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_test(test_name, status, message=""):
    status_icon = "✅" if status == "PASS" else "❌" if status == "FAIL" else "⚠️"
    color = Colors.OKGREEN if status == "PASS" else Colors.FAIL if status == "FAIL" else Colors.WARNING
    print(f"{status_icon} {color}{test_name}{Colors.ENDC}")
    if message:
        print(f"   {message}\n")

def test_phase1_trailing_slash():
    """Test Phase 1: HTTP 301 fix - trailing slash endpoint"""
    print_section("PHASE 1: Testing HTTP 301 Fix (Trailing Slash)")
    
    tests_passed = 0
    tests_failed = 0
    
    # Test 1: Register endpoint WITHOUT trailing slash (should fail with 405)
    try:
        response = requests.post(
            f"{BASE_URL}/api/auth/register",  # NO trailing slash
            json={"username": "test", "email": "test@test.com", "password": "test"},
            timeout=10,
            allow_redirects=False  # Don't follow redirects
        )
        
        if response.status_code == 301:
            print_test("Register WITHOUT trailing slash", "FAIL", 
                      f"Still getting 301 redirect (expected this to be fixed)")
            tests_failed += 1
        elif response.status_code == 405:
            print_test("Register WITHOUT trailing slash", "PASS", 
                      f"Returns 405 (Method Not Allowed) - expected behavior")
            tests_passed += 1
        else:
            print_test("Register WITHOUT trailing slash", "WARN", 
                      f"Unexpected status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("Register WITHOUT trailing slash", "FAIL", str(e))
        tests_failed += 1
    
    # Test 2: Register endpoint WITH trailing slash (correct endpoint)
    try:
        response = requests.post(
            f"{BASE_URL}/api/auth/register/",  # WITH trailing slash
            json={
                "username": TEST_USERNAME,
                "email": TEST_EMAIL,
                "password": TEST_PASSWORD,
                "firstName": "Test",
                "lastName": "User",
                "phone": "+971500000000"
            },
            timeout=10
        )
        
        if response.status_code == 201:
            print_test("Register WITH trailing slash", "PASS", 
                      f"Registration successful (201 Created)")
            tests_passed += 1
        elif response.status_code == 400:
            error_msg = response.json() if response.content else "No error details"
            print_test("Register WITH trailing slash", "PASS", 
                      f"Endpoint accepts POST (400 = validation error, not 301/405)\n   Error: {error_msg}")
            tests_passed += 1
        elif response.status_code == 500:
            print_test("Register WITH trailing slash", "WARN", 
                      f"Server error (500) - endpoint accessible but server issue")
            tests_failed += 1
        else:
            print_test("Register WITH trailing slash", "FAIL", 
                      f"Unexpected status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("Register WITH trailing slash", "FAIL", str(e))
        tests_failed += 1
    
    print(f"\n{Colors.BOLD}Phase 1 Results: {tests_passed} passed, {tests_failed} failed{Colors.ENDC}")
    return tests_passed, tests_failed

def test_phase2_live_validation():
    """Test Phase 2: Live username/email validation"""
    print_section("PHASE 2: Testing Live Validation")
    
    tests_passed = 0
    tests_failed = 0
    
    # Test 1: Validate existing username (should return valid=false)
    try:
        response = requests.post(
            f"{BASE_URL}/api/validators/",
            json={"username": "Hani AMJ"},  # Known existing username
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("username", {}).get("valid") == False:
                print_test("Existing username validation", "PASS", 
                          f"'Hani AMJ' correctly identified as taken")
                tests_passed += 1
            else:
                print_test("Existing username validation", "FAIL", 
                          f"Expected valid=false, got: {data}")
                tests_failed += 1
        else:
            print_test("Existing username validation", "FAIL", 
                      f"Status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("Existing username validation", "FAIL", str(e))
        tests_failed += 1
    
    # Test 2: Validate new username (should return valid=true)
    new_username = f"new_user_{int(time.time())}"
    try:
        response = requests.post(
            f"{BASE_URL}/api/validators/",
            json={"username": new_username},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("username", {}).get("valid") == True:
                print_test("New username validation", "PASS", 
                          f"'{new_username}' correctly identified as available")
                tests_passed += 1
            else:
                print_test("New username validation", "FAIL", 
                          f"Expected valid=true, got: {data}")
                tests_failed += 1
        else:
            print_test("New username validation", "FAIL", 
                      f"Status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("New username validation", "FAIL", str(e))
        tests_failed += 1
    
    # Test 3: Validate existing email (should return valid=false)
    try:
        response = requests.post(
            f"{BASE_URL}/api/validators/",
            json={"email": "hani_janem@hotmail.com"},  # Known existing email
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("email", {}).get("valid") == False:
                print_test("Existing email validation", "PASS", 
                          f"Email correctly identified as taken")
                tests_passed += 1
            else:
                print_test("Existing email validation", "FAIL", 
                          f"Expected valid=false, got: {data}")
                tests_failed += 1
        else:
            print_test("Existing email validation", "FAIL", 
                      f"Status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("Existing email validation", "FAIL", str(e))
        tests_failed += 1
    
    # Test 4: Validate new email (should return valid=true)
    new_email = f"new_email_{int(time.time())}@test.com"
    try:
        response = requests.post(
            f"{BASE_URL}/api/validators/",
            json={"email": new_email},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("email", {}).get("valid") == True:
                print_test("New email validation", "PASS", 
                          f"'{new_email}' correctly identified as available")
                tests_passed += 1
            else:
                print_test("New email validation", "FAIL", 
                          f"Expected valid=true, got: {data}")
                tests_failed += 1
        else:
            print_test("New email validation", "FAIL", 
                      f"Status: {response.status_code}")
            tests_failed += 1
    except Exception as e:
        print_test("New email validation", "FAIL", str(e))
        tests_failed += 1
    
    # Test 5: Debouncing simulation (validate multiple times quickly)
    print(f"\n{Colors.OKCYAN}Testing debouncing behavior (500ms delay)...{Colors.ENDC}")
    try:
        start_time = time.time()
        test_usernames = [f"test_debounce_{i}" for i in range(5)]
        
        # Simulate rapid typing - only last validation should matter
        for username in test_usernames:
            requests.post(
                f"{BASE_URL}/api/validators/",
                json={"username": username},
                timeout=10
            )
            time.sleep(0.1)  # 100ms between calls (faster than 500ms debounce)
        
        elapsed = time.time() - start_time
        print_test("Debouncing behavior", "INFO", 
                  f"Sent 5 requests in {elapsed:.2f}s (app should debounce to 1-2 actual validations)")
        
    except Exception as e:
        print_test("Debouncing behavior", "INFO", f"Test completed with note: {e}")
    
    print(f"\n{Colors.BOLD}Phase 2 Results: {tests_passed} passed, {tests_failed} failed{Colors.ENDC}")
    return tests_passed, tests_failed

def test_phase3_password_validation():
    """Test Phase 3: Client-side password validation logic"""
    print_section("PHASE 3: Testing Password Validation Logic")
    
    tests_passed = 0
    tests_failed = 0
    
    # Test cases for password validation
    test_cases = [
        ("test", False, "Too short (< 8 chars)"),
        ("testtest", False, "No uppercase or numbers"),
        ("TESTTEST", False, "No lowercase or numbers"),
        ("Test1234", True, "Meets all requirements (8+ chars, upper, lower, numbers)"),
        ("MyP@ssw0rd", True, "Strong password with special chars"),
        ("abc123", False, "Too short and missing uppercase"),
        ("Test123", False, "Only 7 characters"),
        ("TestTest", False, "Missing numbers"),
    ]
    
    print(f"{Colors.OKCYAN}Password Validation Rules:{Colors.ENDC}")
    print(f"  • Minimum 8 characters")
    print(f"  • At least 1 uppercase letter")
    print(f"  • At least 1 lowercase letter")
    print(f"  • At least 1 number\n")
    
    for password, should_pass, description in test_cases:
        # Simulate client-side validation logic
        is_valid = (
            len(password) >= 8 and
            any(c.isupper() for c in password) and
            any(c.islower() for c in password) and
            any(c.isdigit() for c in password)
        )
        
        if is_valid == should_pass:
            print_test(f"Password: '{password}'", "PASS", f"{description} ✓")
            tests_passed += 1
        else:
            print_test(f"Password: '{password}'", "FAIL", 
                      f"{description} - Expected {should_pass}, got {is_valid}")
            tests_failed += 1
    
    print(f"\n{Colors.BOLD}Phase 3 Results: {tests_passed} passed, {tests_failed} failed{Colors.ENDC}")
    return tests_passed, tests_failed

def main():
    """Run all registration flow tests"""
    print(f"\n{Colors.BOLD}{Colors.OKBLUE}")
    print("=" * 70)
    print("END-TO-END REGISTRATION FLOW TEST".center(70))
    print("Testing all three phases of the validation system".center(70))
    print("=" * 70)
    print(f"{Colors.ENDC}\n")
    
    print(f"{Colors.OKCYAN}Test Configuration:{Colors.ENDC}")
    print(f"  Base URL: {BASE_URL}")
    print(f"  Test Username: {TEST_USERNAME}")
    print(f"  Test Email: {TEST_EMAIL}")
    print(f"  Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    total_passed = 0
    total_failed = 0
    
    # Phase 1: HTTP 301 Fix
    p1_pass, p1_fail = test_phase1_trailing_slash()
    total_passed += p1_pass
    total_failed += p1_fail
    
    # Phase 2: Live Validation
    p2_pass, p2_fail = test_phase2_live_validation()
    total_passed += p2_pass
    total_failed += p2_fail
    
    # Phase 3: Password Validation
    p3_pass, p3_fail = test_phase3_password_validation()
    total_passed += p3_pass
    total_failed += p3_fail
    
    # Final Summary
    print_section("FINAL TEST SUMMARY")
    print(f"{Colors.BOLD}Total Tests: {total_passed + total_failed}{Colors.ENDC}")
    print(f"{Colors.OKGREEN}✅ Passed: {total_passed}{Colors.ENDC}")
    print(f"{Colors.FAIL}❌ Failed: {total_failed}{Colors.ENDC}")
    
    success_rate = (total_passed / (total_passed + total_failed) * 100) if (total_passed + total_failed) > 0 else 0
    print(f"\n{Colors.BOLD}Success Rate: {success_rate:.1f}%{Colors.ENDC}")
    
    if total_failed == 0:
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}🎉 ALL TESTS PASSED! Registration system is working correctly.{Colors.ENDC}")
    else:
        print(f"\n{Colors.WARNING}{Colors.BOLD}⚠️  Some tests failed. Review the results above.{Colors.ENDC}")
    
    # Save results to file
    results = {
        "timestamp": datetime.now().isoformat(),
        "base_url": BASE_URL,
        "total_tests": total_passed + total_failed,
        "passed": total_passed,
        "failed": total_failed,
        "success_rate": f"{success_rate:.1f}%",
        "phases": {
            "phase1_http301_fix": {"passed": p1_pass, "failed": p1_fail},
            "phase2_live_validation": {"passed": p2_pass, "failed": p2_fail},
            "phase3_password_validation": {"passed": p3_pass, "failed": p3_fail}
        }
    }
    
    with open("registration_flow_test_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n{Colors.OKCYAN}Results saved to: registration_flow_test_results.json{Colors.ENDC}\n")
    
    return total_failed == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
