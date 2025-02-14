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

Get-EnvironmentVariables

# Variables from .env file
$accessToken = $ACCESS_TOKEN

# Set headers
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# OneDrive test file ID (Replace with an actual file ID if needed)
$testFileId = "B1D8B9E533757A9A!s8136e63b58b449b68ef7902c93fe4d2f"  # This tests root access, replace if needed

# Check GET (Read) Permissions
Write-Host "`nChecking GET (Read) permission..."
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me/drive/items/$testFileId" -Headers $headers -Method GET
    Write-Host "✅ GET request succeeded! You have read permissions."
} catch {
    Write-Host "❌ GET request failed! Insufficient permissions or invalid token."
    Write-Host "Error: $($_.Exception.Message)"
}

# Check PATCH (Modify) Permissions
Write-Host "`nChecking PATCH (Modify) permission..."
$updateBody = @{
    name = "test_rename2.txt"  # Attempt to rename the file
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me/drive/items/$testFileId" -Headers $headers -Method PATCH -Body $updateBody
    Write-Host "✅ PATCH request succeeded! You have write permissions."
} catch {
    Write-Host "❌ PATCH request failed! Insufficient permissions or invalid token."
    Write-Host "Error: $($_.Exception.Message)"
}
