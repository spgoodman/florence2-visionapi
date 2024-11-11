# vision-client.ps1
#
# Caption image: vision-client.ps1 <prompt> <image_file_path>
# Example: vision-client.ps1 CAPTION cat.jpg
# Show available prompts: vision-client.ps1 prompts
# Show model name: vision-client.ps1 model
# 
# Author: Steve Goodman (spgoodman)
# Date: 2024-11-11
# License: MIT

# Change the $baseUrl to match the --host and --port set when launching vision-server.sh / vision-server.py
$baseUrl = "http://127.0.0.1:54880"
$timeout = 30

if ($args.Count -eq 1 -and $args[0] -eq "prompts") {
    $response = Invoke-RestMethod -Uri "$baseUrl/prompts" -Method Get -TimeoutSec $timeout
    if ($response.Count -eq 0) {
        Write-Host "Error: Received empty response from the server."
        exit 1
    }
    Write-Host "Available prompts:"
    $response -replace '<|>' | ForEach-Object { Write-Host $_}
    exit 0
} elseif ($args.Count -eq 1 -and $args[0] -eq "model") {
    $response = Invoke-RestMethod -Uri "$baseUrl/model" -Method Get -TimeoutSec $timeout
    if ($response.Length -eq 0) {
        Write-Host "Error: Received empty response from the server."
        exit 1
    }
    Write-Host "Model name: $($response)"
    exit 0
}

if ($args.Count -ne 2) {
    Write-Host "$($MyInvocation.MyCommand.Name): Caption an image using a prompt."
    Write-Host "Caption image: $($MyInvocation.MyCommand.Name) <prompt> <image_file_path>"
    Write-Host "Example: $($MyInvocation.MyCommand.Name) CAPTION cat.jpg"
    Write-Host "Show available prompts: $0 prompts"
    Write-Host "Show model name: $0 model"
    exit 1
}

$prompt = $args[0]
$imageFile = $args[1]
# Resolve the full path of the image file
$imageFile = (Get-Item $imageFile).FullName

if (-not (Test-Path $imageFile)) {
    Write-Host "Error: Image file does not exist: $imageFile"
    exit 1
}

if ((Get-Item $imageFile).length -eq 0) {
    Write-Host "Error: Image file is empty: $imageFile"
    exit 1
}

$base64Image = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($imageFile))

$jsonPayload = @{
    image = $base64Image
    prompt = "<$prompt>"
} | ConvertTo-Json

$headers = @{"Content-Type" = "application/json"}

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/process_image" -Method Post -Headers $headers -Body $jsonPayload -TimeoutSec $timeout
    if ($response.result) {
        Write-Host $response.result.Trim() -NoNewline
    } else {
        Write-Host "Error: Received empty result from the server."
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Server Error: $($errorDetails.error)"
    } elseif ($_.Exception.Message -match "Unable to parse the JSON string") {
        Write-Host "Error: Unable to parse the server response as JSON. The server might be unavailable or returned an unexpected response."
    } elseif ($_.Exception.Message -match "The operation has timed out") {
        Write-Host  "Timeout: No response from the server. If this is the first time you have used the vision client, the model may be downloading. Check the server console for details."
    } else {
        Write-Host "Error: $_"
    }
    exit 1
}
