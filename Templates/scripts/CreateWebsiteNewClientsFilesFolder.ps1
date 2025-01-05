param (
    [string]$websiteName
)

function CreateWebsiteNewClientsFilesFolder {
    param (
        [string]$websiteName
    )

    # Define the folder path
    $folderPath = "F:\NewClientsFiles\$websiteName" + "-Files"

    # Check if the folder exists
    if (-Not (Test-Path -Path $folderPath)) {
        # If the folder doesn't exist, create it
        New-Item -Path $folderPath -ItemType Directory
        Write-Host "Folder '$folderPath' has been created."
    } else {
        Write-Host "Folder '$folderPath' already exists."
    }
}

CreateWebsiteNewClientsFilesFolder -websiteName $websiteName
