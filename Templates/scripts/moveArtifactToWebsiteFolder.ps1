param (
    [parameter(Mandatory = $true)]
    [string] $websiteName
)

function moveArtifactToUsersFolder {
    param (
    [parameter(Mandatory = $true)]
    [string] $websiteName
    )
    $SourcePath = 'F:\Artifact'
    $DestinationPath = "F:\Apps\$($websiteName)"

    if (Test-Path $SourcePath) {
        Copy-Item "$SourcePath\*" -Destination $DestinationPath -Recurse -Force
        Write-Output "Files copied from $SourcePath to $DestinationPath successfully."
    } else {
        Write-Output "Source folder $SourcePath not found."
        }
}

function restoreFilesInTempFolder {
   
    param (
        [parameter(Mandatory = $true)]
        [string]$websiteName
    )

    $tempFolderPath = "F:\Apps\$($websiteName)\tempFolder"
    
    # Check if the temp folder exists
    if (Test-Path $tempFolderPath) {

        $licenseOriginalPath = "F:\Apps\$($websiteName)\bin"
        $configOriginalPath = "F:\Apps\$($websiteName)"

        try {
            Move-Item -Path "$($tempFolderPath)\license.bin" -Destination $licenseOriginalPath -Force -ErrorAction Stop
            Write-Host "Moved 'license.bin' to '$licenseOriginalPath'."
        } catch {
            Write-Host "Error moving 'license.bin': $_"
        }

        try {
            Move-Item -Path "$($tempFolderPath)\web.config" -Destination $configOriginalPath -Force -ErrorAction Stop
            Write-Host "Moved 'web.config' to '$configOriginalPath'."
        } catch {
            Write-Host "Error moving 'web.config': $_"
        }

    } else {
        Write-Host "Warning: Path '$tempFolderPath' does not exist."
    }

    # Get the items in the temp folder to check it's empty
    $tempItems = Get-ChildItem -Path $tempFolderPath

    # Check if the folder is empty
    if (-not $tempItems) {
        # Remove the folder
        Remove-Item -Path $tempFolderPath -Recurse -Force
        Write-Host "The folder '$tempFolderPath' was empty and has been removed."
    } else {
        Write-Host "The folder '$tempFolderPath' is not empty and can't be removed."
    }

    
}

moveArtifactToUsersFolder -websiteName $websiteName
restoreFilesInTempFolder -websiteName $websiteName
