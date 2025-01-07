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

# Load environment variables
Get-EnvironmentVariables

# Variables from .env file
$accessToken = $ACCESS_TOKEN
$sourceFolderId = $SOURCE_FOLDER_ID
$destinationFolderId = $DESTINATION_FOLDER_ID
$destinationDriveId = $DESTINATION_DRIVE_ID
$destinationFolderName = $DESTINATION_FOLDER_NAME
$destinationFolderPath = $DESTINATION_FOLDER_PATH

# Define the OneDrive API URL
$onedriveApiUrl = "https://graph.microsoft.com/v1.0/me/drive/items"

# List all files in the source folder
$sourceFilesUrl = "$onedriveApiUrl/$sourceFolderId/children"
$filesResponse = Invoke-RestMethod -Uri $sourceFilesUrl -Headers @{Authorization = "Bearer $accessToken"}

# Loop through each file and move it to the destination folder
foreach ($file in $filesResponse.value) {
    $fileId = $file.id
    $fileName = $file.name

    # Construct the source file path (just using the file name for simplicity)
    $sourceFilePath = "/$($file.parentReference.path)/$fileName"
    
    # Check if the file already exists in the destination folder
    $destinationFileUrl = "$onedriveApiUrl/$destinationFolderId/children"
    $destinationFolderFiles = Invoke-RestMethod -Uri $destinationFileUrl -Headers @{Authorization = "Bearer $accessToken"}
    $existingFile = $destinationFolderFiles.value | Where-Object { $_.name -eq $fileName }

    if ($existingFile) {
        Write-Host "File '$fileName' already exists in destination, skipping move or renaming..."
        # Optional: Rename the file to avoid conflict
        # $fileName = "Copy_of_$fileName"
    } else {
        # Log the source and destination file paths
        Write-Host "Source file path: $sourceFilePath"
        Write-Host "Destination folder path: $destinationFolderPath"

        # Log the URL for the PATCH request
        $patchUrl = "https://graph.microsoft.com/v1.0/me/drive/items/$fileId"
        Write-Host "PATCH URL: $patchUrl"

        # Prepare the body for the PATCH request
        $patchBody = @{
            parentReference = @{
                driveId = $destinationDriveId
                id = $destinationFolderId
                name = $destinationFolderName
                path = $destinationFolderPath
            }
            name = $fileName
        } | ConvertTo-Json

        try {
            # Execute the PATCH request to move the file
            $patchResponse = Invoke-RestMethod -Method Patch -Uri $patchUrl -Headers @{Authorization = "Bearer $accessToken"} -Body $patchBody -ContentType "application/json"
            Write-Host "Moved file '$fileName' to destination"
        }
        catch {
            Write-Host "Error moving '$fileName': $($_.Exception.Message)"
        }
    }
}

Write-Host "File moving completed!"
