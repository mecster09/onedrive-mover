# OneDrive File Moving Script

This PowerShell script automates the process of moving files between different folders in OneDrive using the Microsoft Graph API.

## Description

The script performs the following operations:
- Authenticates with Microsoft Graph API using an access token
- Lists all files in a specified source folder
- Moves each file to a designated destination folder
- Handles duplicate files by skipping them (can be modified to rename instead)
- Provides detailed logging of the move operations

## Prerequisites

- PowerShell 5.1 or higher
- Access to a Microsoft account with OneDrive
- Microsoft Graph API access token
- Source and destination folder IDs from OneDrive

## Setup

1. **Create Environment File:**
   - Create a `.env` file in the same directory as the script
   - Copy the following template and fill in your values:
   ```
   ACCESS_TOKEN=your_access_token_here
   SOURCE_FOLDER_ID=your_source_folder_id
   DESTINATION_FOLDER_ID=your_destination_folder_id
   DESTINATION_DRIVE_ID=your_drive_id
   DESTINATION_FOLDER_NAME=your_folder_name
   DESTINATION_FOLDER_PATH=your_folder_path
   ```

2. **Get Access Token:**
   - Visit [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
   - Sign in with your Microsoft account
   - Generate a new access token
   - Copy the token and replace the `$accessToken` value in the script

2. **Get Folder IDs:**
   - Navigate to the desired folders in OneDrive
   - From the URL, copy the folder IDs
   - Replace the following variables in the script:
     - `$sourceFolderId`: ID of the folder containing files to move
     - `$destinationFolderId`: ID of the folder where files should be moved to
     - `$destinationDriveId`: Your OneDrive drive ID
     - `$destinationFolderName`: Name of the destination folder
     - `$destinationFolderPath`: Full path to the destination folder

## Usage

1. Save the script as `OneDriveMove.ps1`
2. Open PowerShell
3. Navigate to the directory containing the script
4. Run the script:
   ```powershell
   .\OneDriveMove.ps1
   ```

## Output

The script provides detailed logging of its operations:
- Lists files being processed
- Shows source and destination paths
- Indicates successful moves
- Reports any errors or duplicate files

## Error Handling

The script includes basic error handling:
- Checks for existing files in the destination folder
- Skips duplicate files (can be modified to rename them)
- Catches and reports any API errors during file moves

## Notes

- The access token expires after a certain period and will need to be refreshed
- Large files may take longer to move
- Ensure you have proper permissions for both source and destination folders
- The script can be modified to handle duplicates differently by uncommenting the rename logic
- Limit of 200 files per move

## Security Note

Never share your access token or commit it to version control. Consider storing it in a secure configuration file or using environment variables.

## License

This script is provided "as is" without warranty of any kind, either expressed or implied.  