import requests

# Try to get levels from API
try:
    response = requests.get('https://api.ad4x4.com/api/levels/')
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        levels = response.json()
        print(f"\nTotal levels: {len(levels)}")
        print("\n=== LEVEL NAMES ===\n")
        for level in levels:
            print(f"ID: {level.get('id', 'N/A'):3} | "
                  f"Name: {level.get('name', 'N/A'):20} | "
                  f"Display: {level.get('displayName', 'N/A'):20} | "
                  f"Numeric: {level.get('numericLevel', 'N/A'):4} | "
                  f"Active: {level.get('active', 'N/A')}")
    else:
        print(f"Error: {response.text}")
except Exception as e:
    print(f"Exception: {e}")
