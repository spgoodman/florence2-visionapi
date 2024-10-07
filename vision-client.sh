#!/bin/env bash
#
# vision-client.sh
#
# Usage: vision-client.sh <prompt> <image_file_path>
# Example: vision-client.sh CAPTION cat.jpg
# 
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-07
# License: MIT

# Change the BASE_URL to match the --host and --port set when launching vision-server.sh / vision-server.py
base_url="http://localhost:54880"
timeout=10

if [[ ! $1 ]]; then
    echo "Usage: $0 <prompt> <image_file_path>"
    echo "Example: $0 CAPTION cat.jpg"
    exit 1
fi

if [ $# -ne 2 ]; then
    echo "Error: Please provide both prompt and image file path."
    exit 1
fi

prompt="$1"
image_file="$2"

if [ ! -f "$image_file" ]; then
    echo "Error: Image file does not exist: $image_file"
    exit 1
fi

base64_image=$(base64 -w 0 "$image_file")

prompts=$(echo $prompts | tr ',' ' ')
count=0
temp_file=$(mktemp)
cat > "$temp_file" <<EOF
{
  "image": "$base64_image",
  "prompt": "<$prompt>"
}
EOF
response=$(curl -s -X POST "$base_url/process_image" -H "Content-Type: application/json" -d @"$temp_file" --max-time $timeout)
rm "$temp_file"
if [ -z "$response" ]; then
    echo "Error: Received empty response from the server."
    exit 1
fi
echo "$response" | jq -r '.result' 2>/dev/null | tr -d '\n' || echo "$response"