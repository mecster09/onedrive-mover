# Function to read .env file
function Get-EnvironmentVariables {
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                Set-Variable -Name $key -Value $value -Scope Script
            }
        }
    } else {
        Write-Error "Environment file not found. Please create a .env file in the same directory as the script."
        exit 1
    }
}

# Function to move items (files only)
function Move-OneDriveItem {
    param (
        [string]$ItemId,
        [string]$ItemName,
        [string]$DestinationFolderId
    )

    try {
        $headers = @{
            Authorization = "Bearer $accessToken"
            'Content-Type' = 'application/json'
        }

        $destinationUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$DestinationFolderId"
        ##Write-RequestDetails -Step "Get Destination Info" -Uri $destinationUrl -Headers $headers
        $destinationInfo = Invoke-RestMethod -Uri $destinationUrl -Headers $headers
        $destinationDriveId = $destinationInfo.parentReference.driveId

        $patchUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$ItemId"
        $patchBody = @{
            parentReference = @{
                driveId = $destinationDriveId
                id = $DestinationFolderId
                name = $DestinationFolderName
                path = $DestinationFolderPath
            }
            name = $ItemName
        } | ConvertTo-Json -Depth 10

        if (-not (Test-AccessToken -AccessToken $accessToken)) {
            throw "Access token has expired during operation"
        }
        Write-Host "Attempting to move '$ItemName' @ '$patchUrl'" -ForegroundColor Green
        $response = Invoke-RestMethod -Method Patch -Uri $patchUrl -Headers $headers -Body $patchBody
        Write-Host "[Success] Moved file '$ItemName' to destination" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "[Error] Failed moving '$ItemName'" -ForegroundColor Red
        Write-Host "Step: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        Write-Host "Last Request URL: $patchUrl" -ForegroundColor Yellow
        Write-Host "Last Request Body: $patchBody" -ForegroundColor Yellow
        Write-Host "Headers: $($headers | ConvertTo-Json)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check if file exists in destination
function Test-ItemExists {
    param (
        [string]$ItemName,
        [string]$DestinationFolderId
    )

    $destinationUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$DestinationFolderId/children"
    $destinationItems = Invoke-RestMethod -Uri $destinationUrl -Headers @{Authorization = "Bearer $accessToken"}
    return $null -ne ($destinationItems.value | Where-Object { $_.name -eq $ItemName })
}

# Update Write-RequestDetails function
function Write-RequestDetails {
    param (
        [string]$Step,
        [string]$Method = "GET",
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Body
    )
    Write-Host "`n[$Step] Request Details:" -ForegroundColor Cyan
    Write-Host "Method: $Method" -ForegroundColor Yellow
    Write-Host "URI: $Uri" -ForegroundColor Yellow
    Write-Host "Headers: $($Headers | ConvertTo-Json)" -ForegroundColor Yellow
    if ($Body) {
        Write-Host "Body: $Body" -ForegroundColor Yellow
    }
    Write-Host "" # Empty line for readability
}

# Add this function after Get-EnvironmentVariables
function Test-AccessToken {
    param (
        [string]$AccessToken
    )
    
    try {
        ##Write-RequestDetails -Step "Validate Token" -Uri "https://graph.microsoft.com/v1.0/me" -Headers @{
        ##    Authorization = "Bearer $AccessToken"
        ##}
        
        $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers @{
            Authorization = "Bearer $AccessToken"
        }
        Write-Host "Access Token validated for user: $($response.userPrincipalName)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Invalid or expired access token" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to generate random alphanumeric string
function Get-RandomString {
    param (
        [int]$Length = 8
    )
    $chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    return -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Function to rename file with unique suffix
function Get-UniqueFileName {
    param (
        [string]$FileName
    )
    
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $extension = [System.IO.Path]::GetExtension($FileName)
    $uniqueSuffix = Get-RandomString
    return "${fileNameWithoutExt}_${uniqueSuffix}${extension}"
}

# Load environment variables
Get-EnvironmentVariables

# Variables from .env file
$accessToken = $ACCESS_TOKEN
$sourceFolderId = $SOURCE_FOLDER_ID
$destinationFolderId = $DESTINATION_FOLDER_ID
$destinationFolderName = $DESTINATION_FOLDER_NAME
$destinationFolderPath = $DESTINATION_FOLDER_PATH

# Validate access token first
if (-not (Test-AccessToken -AccessToken $accessToken)) {
    Write-Host "Please provide a valid access token" -ForegroundColor Red
    exit 1
}

# Then continue with folder validation
try {
    # Test source folder
    $sourceUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$sourceFolderId"
    $sourceInfo = Invoke-RestMethod -Uri $sourceUrl -Headers @{Authorization = "Bearer $accessToken"}
    Write-Host "Source folder: $($sourceInfo.name)" -ForegroundColor Green

    # Test destination folder
    $destinationUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$destinationFolderId"
    $destinationInfo = Invoke-RestMethod -Uri $destinationUrl -Headers @{Authorization = "Bearer $accessToken"}
    Write-Host "Destination folder: $($destinationInfo.name)" -ForegroundColor Green
}
catch {
    Write-Host "Error validating folders: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your access token and folder IDs" -ForegroundColor Red
    exit 1
}

# Start processing the source folder
Write-Host "Starting file and folder transfer..." -ForegroundColor Cyan

# Update the main script execution
try {
    # Get all items in the source folder
    $itemsUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$sourceFolderId/children"
    $itemsResponse = Invoke-RestMethod -Uri $itemsUrl -Headers @{Authorization = "Bearer $accessToken"}

    # Process only files (skip folders)
    $files = $itemsResponse.value | Where-Object { -not $_.folder }
    
    Write-Host "Found $($files.Count) files to process" -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $originalName = $file.name
        $fileExists = Test-ItemExists -ItemName $originalName -DestinationFolderId $destinationFolderId
        
        if ($fileExists) {
            $newName = Get-UniqueFileName -FileName $originalName
            Write-Host "File '$originalName' exists in destination - renaming to '$newName'" -ForegroundColor Yellow
            Move-OneDriveItem -ItemId $file.id -ItemName $newName -DestinationFolderId $destinationFolderId
        } else {
            Write-Host "Moving file: $originalName" -ForegroundColor White
            Move-OneDriveItem -ItemId $file.id -ItemName $originalName -DestinationFolderId $destinationFolderId
        }
    }
}
catch {
    Write-Host "Error processing files: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Transfer completed!" -ForegroundColor Green
