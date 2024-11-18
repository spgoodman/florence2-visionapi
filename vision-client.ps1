# vision-client.ps1
#
# Caption image: vision-client.ps1 <prompt> <image_file_path>
# Example: vision-client.ps1 CAPTION cat.jpg
# Show available prompts: vision-client.ps1 prompts
# Show model name: vision-client.ps1 model
# 
# Author: Steve Goodman (spgoodman)
# Date: 2024-11-13
# License: MIT

# Change the $baseUrl to match the --host and --port set when launching vision-server.sh / vision-server.py
# Check environment variable for VISION_HOST and if not set, use default
if ($env:VISION_HOST) {
    $baseUrl = $env:VISION_HOST
} else {
    $baseUrl = "http://127.0.0.1:54880"
}
$timeout = 120


if ($args.Count -eq 1 -and $args[0] -eq "prompts") {
    $response = Invoke-RestMethod -Uri "$baseUrl/prompts" -Method Get -TimeoutSec $timeout
    if ($response.Count -eq 0) {
        "Error: Received empty response from the server."
        exit 1
    }
    "Available prompts:"
    $response -replace '<|>' | ForEach-Object { $_}
    exit 0
} elseif ($args.Count -eq 1 -and $args[0] -eq "model") {
    $response = Invoke-RestMethod -Uri "$baseUrl/model" -Method Get -TimeoutSec $timeout
    if ($response.Length -eq 0) {
        "Error: Received empty response from the server."
        exit 1
    }
    "Model name: $($response)"
    exit 0
}

if ($args.Count -ne 2) {
    "$($MyInvocation.MyCommand.Name): Caption an image using a prompt."
    "Caption image: $($MyInvocation.MyCommand.Name) <prompt> <image_file_path>"
    "Example: $($MyInvocation.MyCommand.Name) CAPTION cat.jpg"
    "Show available prompts: $0 prompts"
    "Show model name: $0 model"
    exit 1
}

$prompt = $args[0]
$imageFile = $args[1]
# Resolve the full path of the image file
$imageFile = (Get-Item $imageFile).FullName

if (-not (Test-Path $imageFile)) {
    "Error: Image file does not exist: $imageFile"
    exit 1
}

if ((Get-Item $imageFile).length -eq 0) {
    "Error: Image file is empty: $imageFile"
    exit 1
}

$image = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $imageFile
# Resize the image to 256x256 pixels as [System.Drawing.Imaging.ImageFormat]::Jpeg and keep in memory
$image = $image.GetThumbnailImage(1024, 1024, $null, [System.IntPtr]::Zero)
$stream = New-Object -TypeName System.IO.MemoryStream
$image.Save($stream, [System.Drawing.Imaging.ImageFormat]::Jpeg)



#$base64Image = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($imageFile))
$base64Image = [Convert]::ToBase64String($stream.ToArray())

$jsonPayload = @{
    image = $base64Image
    prompt = "<$prompt>"
} | ConvertTo-Json

$headers = @{"Content-Type" = "application/json"}

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/process_image" -Method Post -Headers $headers -Body $jsonPayload -TimeoutSec $timeout
    if ($response.result) {
        $response.result.Trim()
    } else {
        "Error: Received empty result from the server."
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Error "Server Error: $($errorDetails.error)"
    } elseif ($_.Exception.Message -match "Unable to parse the JSON string") {
        Write-Error "Error: Unable to parse the server response as JSON. The server might be unavailable or returned an unexpected response."
    } elseif ($_.Exception.Message -match "The operation has timed out") {
        Write-Error  "Timeout: No response from the server. If this is the first time you have used the vision client, the model may be downloading. Check the server console for details."
    } else {
        Write-Error "Error: $_"
    }
    exit 1
}
