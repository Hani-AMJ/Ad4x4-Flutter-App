import requests
import json

# Test Gallery API
url = "https://media.ad4x4.com/api/galleries?page=1&limit=3"

try:
    print("📸 Testing Gallery API...")
    print(f"URL: {url}\n")
    
    response = requests.get(url, timeout=10)
    print(f"Status: {response.status_code}")
    print(f"Headers: {dict(response.headers)}\n")
    
    if response.status_code == 200:
        data = response.json()
        print("Response JSON:")
        print(json.dumps(data, indent=2))
    else:
        print(f"Error: {response.text}")
        
except Exception as e:
    print(f"❌ Request failed: {e}")
