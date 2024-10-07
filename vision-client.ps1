# vision-client.ps1
#
# Usage: .\vision-client.ps1 <prompt> <image_file_path>
# Example: .\vision-client.ps1 CAPTION cat.jpg
# 
# Author: Steve Goodman (spgoodman)
# Date: 2024-10-07
# License: MIT

# Change the $baseUrl to match the --host and --port set when launching vision-server.sh / vision-server.py
$baseUrl = "http://127.0.0.1:54880"
$timeout = 10

if ($args.Count -ne 2) {
    Write-Error "Error: Incorrect number of arguments provided."
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) <prompt> <image_file_path>"
    Write-Host "Example: $($MyInvocation.MyCommand.Name) CAPTION cat.jpg"
    exit 1
}

$prompt = $args[0]
$imageFile = $args[1]

if (-not (Test-Path $imageFile)) {
    Write-Error "Error: Image file does not exist: $imageFile"
    exit 1
}

if ((Get-Item $imageFile).length -eq 0) {
    Write-Error "Error: Image file is empty: $imageFile"
    exit 1
}

$base64Image = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($imageFile))

$jsonPayload = @{
    image = $base64Image
    prompt = "<$prompt>"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/process_image" -Method Post -Headers $headers -Body $jsonPayload -TimeoutSec $timeout
    if ($response.result) {
        Write-Host $response.result.Trim() -NoNewline
    } else {
        Write-Error "Error: Received empty result from the server."
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Error "Server Error: $($errorDetails.error)"
    } elseif ($_.Exception.Message -match "Unable to parse the JSON string") {
        Write-Error "Error: Unable to parse the server response as JSON. The server might be unavailable or returned an unexpected response."
    } else {
        Write-Error "Error: $_"
    }
    exit 1
}
