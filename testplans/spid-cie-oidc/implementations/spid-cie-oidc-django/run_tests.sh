#!/bin/bash

# Check if session.txt and test.txt are provided as arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 session.txt test.txt"
    exit 1
fi

# Read session.txt and test.txt
SESSION_CONTENT=$(<"$1")
TEST_CONTENT=$(<"$2")

# Print session content
echo "$SESSION_CONTENT"
echo    # Print a blank line

# Print test content
echo "$TEST_CONTENT"

# Generate random username and password
USERNAME=$(openssl rand -hex 8)
PASSWORD=$(openssl rand -hex 8)

# Register the user
echo "Registering user..."
curl -X POST http://burpsuite:3000/users \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$USERNAME\", \"password\": \"$PASSWORD\"}"

# Login and capture the token
echo "Logging in and capturing token..."
RESPONSE=$(curl -s -X POST http://burpsuite:3000/users/login \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

# Extract the token from the response
TOKEN=$(echo "$RESPONSE" | grep -o '"token": *"[^"]*' | grep -o '[^"]*$')

# Sending session and test and capturing output
echo "Sending session and test and capturing output..."
curl -X POST http://burpsuite:3000/send_message \
-H "Content-Type: text/plain" \
-H "Authorization: Bearer $TOKEN" \
-d "$SESSION_CONTENT&$TEST_CONTENT" > /output.txt
echo "Output saved to output.txt"
