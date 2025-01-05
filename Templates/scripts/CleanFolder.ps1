param(
    [Parameter(Mandatory = $false)]
    [string] $FolderPath
)

function cleanFolder {
    param(
        [Parameter(Mandatory = $false)]
        [string] $FolderPath
    )

    if (Test-Path $FolderPath) {
        Remove-Item "$FolderPath\\*" -Recurse -Force
        Write-Output "All files in $FolderPath cleaned successfully."
    } else {
        Write-Output "Folder $FolderPath not found."
            }
}

cleanFolder -FolderPath $FolderPath

                