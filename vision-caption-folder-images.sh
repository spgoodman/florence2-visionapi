#!/bin/env bash
#
# vision-caption-folder-images.sh
#
# Usage: vision-caption-folder-images.sh <prompt> <caption_extension> <folder_path>
# Recursively caption all images in a folder and save captions to files with the specified extension.
# Example: vision-caption-folder-images.sh DETAILED_CAPTION txt /path/to/folder
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-13
# License: MIT

if [[ ! $3 ]]; then
    echo "Usage: $0 <prompt> <caption_extension> <folder_path>"
    echo "Example: $0 DETAILED_CAPTION txt /path/to/folder"
    exit 1
fi

VISION_CLIENT="$(dirname $0)/vision-client.sh"

prompt="$1"
caption_extension="$2"
folder_path="$3"

if [ ! -d "$folder_path" ]; then
    echo "Error: Folder does not exist: $folder_path"
    exit 1
fi

find "$folder_path" -type f -iregex '.*\.\(jpg\|jpeg\|png\|gif\|bmp\|tiff\|webp\)' | while read image_file; do
    echo "Processing image: $image_file"
    caption_file="${image_file%.*}.$caption_extension"
    if [[ -f "$caption_file" ]]; then
        echo "Caption file already exists, skipping: $caption_file"
        continue
    fi
    $VISION_CLIENT "$prompt" "$image_file" > "$caption_file" && echo "Caption saved to: $caption_file" || echo "Error processing image: $image_file"
done
