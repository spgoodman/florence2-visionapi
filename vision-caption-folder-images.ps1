# vision-caption-folder-images.ps1
#
# Usage: .\vision-caption-folder-images.ps1 <prompt> <caption_extension> <folder_path>
# Recursively caption all images in a folder and save captions to files with the specified extension.
# Example: .\vision-caption-folder-images.ps1 DETAILED_CAPTION txt C:\path\to\folder
#
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-07
# License: MIT

param(
    [Parameter(Mandatory=$false)][string]$prompt,
    [Parameter(Mandatory=$false)][string]$caption_extension,
    [Parameter(Mandatory=$false)][string]$folder_path
)

# Display usage if parameters are missing
if (-not $prompt -or -not $caption_extension -or -not $folder_path) {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) <prompt> <caption_extension> <folder_path>"
    Write-Host "Example: $($MyInvocation.MyCommand.Name) DETAILED_CAPTION txt C:\path\to\folder"
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
    $image_file = $_.FullName
    Write-Host "Processing image: $image_file"
    $caption_file = [System.IO.Path]::ChangeExtension($image_file, $caption_extension)
    
    try {
        $caption = & $VISION_CLIENT $prompt $image_file
        $caption | Out-File -FilePath $caption_file -Encoding utf8
        Write-Host "Caption saved to: $caption_file"
    }
    catch {
        Write-Error "Error processing image: $image_file"
    }
}