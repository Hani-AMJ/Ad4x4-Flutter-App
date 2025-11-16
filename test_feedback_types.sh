#!/bin/bash

# Test script to identify valid feedback types accepted by backend
# Run this to determine what types the backend actually accepts

echo "Testing Feedback Types Against Backend API"
echo "==========================================="
echo ""

# Get auth token (replace with your actual token)
TOKEN="YOUR_JWT_TOKEN_HERE"
API_URL="http://localhost:8000/api/feedback/"

# Test types to check
TYPES=("BUG" "FEATURE" "IMPROVEMENT" "SUGGESTION" "COMPLAINT" "PRAISE" "OTHER")

echo "Testing each feedback type..."
echo ""

for TYPE in "${TYPES[@]}"; do
  echo "Testing type: $TYPE"
  RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"feedbackType\": \"$TYPE\",
      \"message\": \"Test message for $TYPE type\"
    }")
  
  # Check if response contains error
  if echo "$RESPONSE" | grep -q "not a valid choice"; then
    echo "  ❌ REJECTED: $TYPE is not accepted"
  elif echo "$RESPONSE" | grep -q "\"id\""; then
    echo "  ✅ ACCEPTED: $TYPE is valid"
  else
    echo "  ⚠️ UNKNOWN: $RESPONSE"
  fi
  echo ""
done

echo "==========================================="
echo "Test Complete"
