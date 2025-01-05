param (
    [parameter(Mandatory = $true)]
    [string] $websiteName
)

function restoreOldVersion {
    param (
    [parameter(Mandatory = $true)]
    [string] $websiteName
    )

    $appsPath = 'F:\Apps'  

    $SourcePath = "$($appsPath)\backUps\$($websiteName)_backup"
    $DestinationPath = "F:\Apps\$($websiteName)"

    # Clean the users folder to restore backup properly
    if (Test-Path $DestinationPath) {
        Remove-Item "$DestinationPath\\*" -Recurse -Force
        Write-Output "All files in $DestinationPath cleaned successfully."
    } else {
        Write-Output "Folder $DestinationPath not found."
    }

    # Copy the Old Version files to the users folder
    if (Test-Path $SourcePath) {
        Copy-Item "$SourcePath\*" -Destination $DestinationPath -Recurse -Force
        Write-Output "Files copied from $SourcePath to $DestinationPath successfully."
    } else {
        Write-Output "Source folder $SourcePath not found."
        }
}

restoreOldVersion -websiteName $websiteName
