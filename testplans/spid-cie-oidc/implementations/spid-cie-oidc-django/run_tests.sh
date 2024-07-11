#!/bin/bash

# Check if the input JSON file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 test.json"
    exit 1
fi

# Assign the input file to a variable
TEST_FILE=$1

# Check if the input file exists
if [ ! -f "$TEST_FILE" ]; then
    echo "Error: The file $TEST_FILE does not exist."
    exit 1
fi

# Validate the JSON file
if ! jq empty "$TEST_FILE" >/dev/null 2>&1; then
    echo "Error: The file $TEST_FILE is not a valid JSON."
    exit 1
fi

TEST_CONTENT=$(<"$TEST_FILE")

# Print test content
echo "Content of test:"
echo "$TEST_CONTENT"
echo    # Print a blank line for separation

# Extract the sessions array from the JSON using jq
SESSIONS=$(jq -r '.tests[].test.sessions[]' "$TEST_FILE")

# Check if sessions were extracted successfully
if [ -z "$SESSIONS" ]; then
    echo "No sessions found or unable to extract sessions."
    exit 1
fi

# Print the extracted sessions and their content
echo "Sessions:"
for SESSION in $SESSIONS; do
    echo "Session: $SESSION"
    SESSION_FILE="./input/mig-t/sessions/$SESSION"
    if [ -f "$SESSION_FILE" ]; then
        SESSION_CONTENT=$(<"$SESSION_FILE")
        echo "Content of $SESSION:"
        echo "$SESSION_CONTENT"
    else
        echo "Error: Session file $SESSION does not exist."
    fi
    echo    # Print a blank line for separation
done

# Generate random username and password
USERNAME=$(openssl rand -hex 8)
PASSWORD=$(openssl rand -hex 8)

# Register the user
echo "Registering user..."
curl -m 30 -X POST http://burpsuite:3000/users \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$USERNAME\", \"password\": \"$PASSWORD\"}"

# Login and capture the token
echo "Logging in and capturing token..."
RESPONSE=$(curl -m 30 -s -X POST http://burpsuite:3000/users/login \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

# Extract the token from the response
TOKEN=$(echo "$RESPONSE" | grep -o '"token": *"[^"]*' | grep -o '[^"]*$')

# Sending session and test and capturing output
echo "Sending session and test and capturing output..."
curl -m 180 -X POST http://burpsuite:3000/send_message \
-H "Content-Type: text/plain" \
-H "Authorization: Bearer $TOKEN" \
-d "$SESSION_CONTENT&$TEST_CONTENT" > output.json
echo "Output saved to output.json"
