#!/bin/env bash
#
# vision-client.sh
#
# Caption image: vision-client.sh <prompt> <image_file_path>
# Show available prompts: vision-client.sh prompts
# Show model name: vision-client.sh model
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-11-13
# License: MIT

# Change the BASE_URL to match the --host and --port set when launching vision-server.sh / vision-server.py
base_url="http://localhost:54880"
timeout=30

if [[ ! $1 ]]; then
    echo "$(basename $0): Caption an image using a prompt."
    echo "Caption image: $0 <prompt> <image_file_path>"
    echo "Show available prompts: $0 prompts"
    echo "Show model name: $0 model"
    exit 1
fi

if [[ $1 == "prompts" ]]; then
    response=$(curl -s "$base_url/prompts")
    if [ -z "$response" ]; then
        echo "Error: Received empty response from the server."
        exit 1
    fi
    echo "Available prompts:"
    echo "$response"
    exit 0
elif [[ $1 == "model" ]]; then
    response=$(curl -s "$base_url/model" | jq -r '.model')
    if [ -z "$response" ]; then
        echo "Error: Received empty response from the server."
        exit 1
    fi
    echo "Model name:"
    echo "$response"
    exit 0
fi

if [ $# -ne 2 ]; then
    echo "Error: Please provide both prompt and image file path."
    exit 1
fi

prompt="$1"
image_file="$(realpath "$2")"

if [ ! -f "$image_file" ]; then
    echo "Error: Image file does not exist: $image_file"
    exit 1
fi

base64_image=$(base64 -w 0 "$image_file")

temp_file=$(mktemp)
cat > "$temp_file" <<EOF
{
  "image": "$base64_image",
  "prompt": "<$prompt>"
}
EOF

response=$(curl -s -X POST "$base_url/process_image" -H "Content-Type: application/json" -d @"$temp_file")

rm "$temp_file"
if [ -z "$response" ]; then
    echo "Timeout: No response from the server. If this is the first time you have used the vision client, the model may be downloading. Check the server console for details."
    exit 1
fi
echo "$response" | jq -r '.result' 2>/dev/null | tr -d '\n' || echo "$response"
