# Variables
$accessToken = "EwCIA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAXe7OCwxpIVHLg3D8kR+kYjFeqFtc9uLLlGrsdrNmfdCOvkuXWky25uXEs301DV2wxJ171eRNF014IPhPy26N2cs4wzpdEEMoGTUJtgc67P/h5Q8MoreoJyIAqa5wlwr+FUmNoAOTbkmNvgGPHOi6OP8BidHANwUsZKgPtLcPzgrxVfG0ja7AUnhOO5w4YRKTtNqPplSMKxQx9ikVbBrsjcbwOB9T04W9ozRCNp16MRs9RX0wusxrTUnGf5yw91MJejDKGgMr67i85VOQRdY2SBpGqkPgD8ZTqcd2IHfQdD+VQ+HWXUqESdI1rL2W8gc5agefRxtSdVrN4yAjFKic5YQZgAAENRBcu+m8GjxmJeZAt6bP1NQAhKRei/Mi5k5JbI4YNuJQFjFci/a4mRJYJeQKJ7RfrMkUFE6MCeMFk2g2ssKkqJmVCK2yFX77Pv6wPQ9EvBcov2XaW3LBJ7UctAwpL/D0/KcqtfpBmOHoKOvi722uCiXkdcmCjuLp2UCtdi61cvTXV+hVWQ+ze9yOSazCf/JyvnLynxOzxw+92znt3MmAm2oA5e53Yskx4wYaKa2UUoAgb8v8uR5ET8vtlRPRACZBy71SYWBQlGWN1CL6F8D3SCq1N6TfEfzTdxKk9QV0EVwGLJD1AO/9B1vw4eFJBe3lNYNeAIa7BIWSDUcYDTlzVYDzLaoYUW8wMhyE5L/MrB7zNfrIahJ0P0VrQ8rqqcDPYUvpHpej6uMQ22GYZA1eKb5HxA+xcN9ZeBkLJOrrwtPuUAktvkxG9U+T8TusSICr6Nv46ag1pUNCPjuEwC83RAgrLs42dtUtxO53pg+fIgwa0n0P8NNo/6cZEMq8hRfJX5dI93IvaBn19X+TqV3E6sbz3eg3XKRqSjpKaXYjAF21Os7O5z4K+AsOfDBcK1N6JVNUF/YPsiYKNQSbDOiRn4siTPGfv1vX5ho/CSC2NDmMQSlwnWoCgECB8BzjBbFSzIkiFFo79yc+G704osq1JnUiopgxlziq7Fb9El9V50jOdRHxjMMxHabMBx8kQ+8iTNk38Ozso6HHxy89zD1M4W+Y8UgyNp/PUoBmV6aFVrs3LbwclWc+fskgRUG5VIJFLPZeWekXiHpUt4XrPGeCnxPjCiNO6ckTuceCMdQgqYPAFaFAg=="   # Replace with the access token obtained from Graph Explorer
$sourceFolderId = "B1D8B9E533757A9A%212432" # "B1D8B9E533757A9A%21940"  # Replace with the ID of the source folder
$destinationFolderId = "B1D8B9E533757A9A%211241" #"B1D8B9E533757A9A%21583" # Replace with the ID of the destination folder

# Define the source and destination folder IDs
$sourceFolderId = "B1D8B9E533757A9A%21940"  # Replace with the ID of the source folder
$destinationFolderId = "B1D8B9E533757A9A%21583" # Replace with the ID of the destination folder
$destinationDriveId = "B1D8B9E533757A9A"  # The drive ID of the destination
$destinationFolderName = "Camera Roll"  # The name of the destination folder
$destinationFolderPath = "/drive/root:/Pictures/Camera Roll"  # The path of the destination folder

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
            name = $fileName  # Retain the original file name (or modify if needed)
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
