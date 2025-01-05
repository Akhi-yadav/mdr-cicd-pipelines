param (
        [parameter(Mandatory = $true)]
        [string] $websiteName
    )

function SaveFilesInTempFolder {
    param (
        [parameter(Mandatory = $true)]
        [string] $websiteName
    )

    $appsPath = 'F:\Apps'   

    # Define the paths for the files to copy

    #WebConfig and test path
    $webConfigPath = Join-Path -Path $appsPath -ChildPath "$($websiteName)\web.config"

    if (Test-Path $webConfigPath) {
        Write-Host "Found web.config file at '$webConfigPath'."
    } else {
        Write-Host "Error: web.config file not found at '$webConfigPath'." -ForegroundColor Red
        Write-Error "Error: web.config file not found at '$webConfigPath'."
    }

    #Licensebin and test path
    $licenseBinPath = Join-Path -Path $appsPath -ChildPath "$($websiteName)\bin\license.bin"
    if (Test-Path $licenseBinPath) {
        Write-Host "Found license.bin file at '$licenseBinPath'."
    } else {
        Write-Host "Error: license.bin file not found at '$licenseBinPath'." -ForegroundColor Red
        Write-Error "Error: license.bin file not found at '$licenseBinPath'."
    }


    # Define the temp folder path
    $tempFolderPath = Join-Path -Path "$($appsPath)\$($websiteName)" -ChildPath "tempFolder"

    # Create the temp folder if it doesn't exist
    if (-not (Test-Path $tempFolderPath)) {
        New-Item -Path $tempFolderPath -ItemType Directory
    }

    # Copy the files to the temp folder
    try {
        Copy-Item -Path $webConfigPath -Destination $tempFolderPath -Force -ErrorAction Stop
        Copy-Item -Path $licenseBinPath -Destination $tempFolderPath -Force -ErrorAction Stop
        Write-Host "Files copied successfully to '$tempFolderPath'."
    } catch {
        Write-Host "Error occurred while copying files: $_"
    }
}

function cleanUsersFolder { # Except for tempFolder
    param (
        [parameter(Mandatory = $true)]
        [string] $websiteName 
    )

    $appsPath = 'F:\Apps'

    $websiteFolderPath = "$($appsPath)\$($websiteName)"
    $tempFolderPath = "$($websiteFolderPath)\tempFolder"

    # Check if the website folder exists
    if (Test-Path $websiteFolderPath) {
        # Get all items in the user folder except for the temp folder
        Get-ChildItem -Path $websiteFolderPath -Force | Where-Object { $_.FullName -ne $tempFolderPath } | ForEach-Object {
            # Remove the item
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        Write-Host "Removed all items in '$websiteFolderPath' except for '$tempFolderPath'."
    } else {
        Write-Error "Error: Path '$websiteFolderPath' does not exist." -ForegroundColor Red
    }

}

SaveFilesInTempFolder -websiteName $websiteName
cleanUsersFolder -websiteName $websiteName