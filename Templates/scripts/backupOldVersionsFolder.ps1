param (
        [parameter(Mandatory = $true)]
        [string] $websiteName
    )

function copyOldVersionsFolder {
    param (
        [parameter(Mandatory = $true)]
        [string] $websiteName
    )

    #Write-Error "Error: test error" -ForegroundColor Red

    $appsPath = 'F:\Apps'   

    # Define the back up folder path
    $backUpFolderPath = "$($appsPath)\backUps\$($websiteName)_backup"

    # Create the back up folder if it doesn't exist
    if (-not (Test-Path $backUpFolderPath)) {
        New-Item -Path $backUpFolderPath -ItemType Directory
    }

    # Clean the back up folder
    if (Test-Path $backUpFolderPath) {
        Remove-Item "$backUpFolderPath\\*" -Recurse -Force
        Write-Output "All files in $backUpFolderPath cleaned successfully."
    } else {
        Write-Output "Folder $backUpFolderPath not found."
    }    


    # Copy the files to the back up folder
    try {
        Copy-Item -Path "$($appsPath)\$($websiteName)\*" -Destination "$backUpFolderPath" -Recurse -Force -ErrorAction Stop
        Write-Host "Files copied successfully to '$($backUpFolderPath)'."
    } catch {
        Write-Host "Error occurred while copying files: $_"
    }
}

copyOldVersionsFolder -websiteName $websiteName