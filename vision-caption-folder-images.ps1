# vision-caption-folder-images.ps1
#
# Usage: vision-caption-folder-images.ps1 <prompt> <caption_extension> <folder_path>
# Recursively caption all images in a folder and save captions to files with the specified extension.
# Example: vision-caption-folder-images.ps1 DETAILED_CAPTION txt C:\path\to\folder
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-13
# License: MIT

param(
    [Parameter(Mandatory=$false)][string]$prompt,
    [Parameter(Mandatory=$false)][string]$caption_extension,
    [Parameter(Mandatory=$false)][string]$folder_path
)

# Display usage if parameters are missing
if (-not $prompt -or -not $caption_extension -or -not $folder_path) {
    "Usage: $($MyInvocation.MyCommand.Name) <prompt> <caption_extension> <folder_path>"
    "Example: $($MyInvocation.MyCommand.Name) DETAILED_CAPTION txt C:\path\to\folder"
    exit 1
}

# Check if the folder exists
if (-not (Test-Path -Path $folder_path -PathType Container)) {
    Write-Error "Error: Folder does not exist: $folder_path"
    exit 1
}

# Get the path of the vision-client.ps1 script
$VISION_CLIENT = Join-Path $PSScriptRoot "vision-client.ps1"

# Find and process image files
Get-ChildItem -Path $folder_path -Recurse -File | Where-Object {
    $_.Extension -match '\.(jpg|jpeg|png|gif|bmp|tiff|webp)$'
} | ForEach-Object {
    # Capture start time in milliseconds
    $image_file = $_.FullName
    "Processing image: $image_file"
    $caption_file = [System.IO.Path]::ChangeExtension($image_file, $caption_extension)
    if (Test-Path -Path $caption_file) {
        "Caption file already exists, skipping: $caption_file"
        return
    }
    try {
        # Accurately record how long it takes to call the vision-client.ps1 script
        $start = Get-Date
        $caption = & $VISION_CLIENT $prompt $image_file
        # get last error
        if ($LASTEXITCODE -ne 0) {
            # Exit
            exit $LASTEXITCODE
    }
        $end = Get-Date
        $elapsed = ($end - $start).TotalSeconds
        # Show elapsed time as X.XX seconds
        $elapsed = "{0:N2}" -f $elapsed
        $caption | Out-File -FilePath $caption_file -Encoding utf8
        # Capture end time in milliseconds
        "Caption saved to: $caption_file (elapsed time: $elapsed seconds)"
    }
    catch {
        Write-Error "Error processing image: $image_file"
        
    }
}