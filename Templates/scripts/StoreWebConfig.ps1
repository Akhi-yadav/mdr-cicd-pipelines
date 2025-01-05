param (
    [string]$websiteName
)

# Function to copy the web.config file to a website-files folder
function Copy-WebConfig {
    param (
        [string]$websiteName
    )

    # Define the source file path and destination folder path inside the function
    $sourceFilePath = "F:\NewClientsFiles\web.config"
    $destinationFolder = "F:\NewClientsFiles\$websiteName" + "-Files"

    # Check if the destination folder exists, create it if it doesn't
    if (-Not (Test-Path -Path $destinationFolder)) {
        Write-Error "Destination Folder was not found."
    }

    # Copy the file from source to destination
    $destinationFilePath = Join-Path -Path $destinationFolder -ChildPath "web.config"

    try {
        Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force
        Write-Host "Successfully copied 'web.config' to $destinationFilePath"
    } catch {
        Write-Error "Failed to copy the file: $_"
    }
}

# Call the function to copy the web.config file
Copy-WebConfig -websiteName $websiteName
