param(
    [string]$websiteName,
    [string]$datasource,
    [string]$catalogDbName,
    [string]$dbLoginUsername,
    [string]$dbLoginPassword,
    [string]$serviceUrl
)

# Function to update the connectionString in web.config file
function Update-ConnectionString {
    param (
        [string]$websiteName,
        [string]$datasource,
        [string]$catalogDbName,
        [string]$dbLoginUsername,
        [string]$dbLoginPassword,  
        [string]$serviceUrl
    )

    Write-Host "These are the parameters passed to the script:"
    $websiteName
    $datasource
    $catalogDbName
    $serviceUrl

    # Define the path to the web.config file
    $filePath = "F:\NewClientsFiles\$($websiteName)-Files\web.config"

    # Check if the file exists
    if (Test-Path $filePath) {
        Write-Host "Found web.config file at $filePath"

        # Read the content of the web.config file
        $webConfigContent = Get-Content $filePath

        try {
            $connectionStringPattern = 'connectionString="Server=tcp:(?<datasource>.*?),1433;Initial Catalog=(?<catalogDbName>.*?);Persist Security Info=False;User ID=(?<dbLoginUsername>.*?);Password=(?<dbLoginPassword>.*?);"'

            # Replacement string using the passed parameters (no single quotes around variables)
            $replacementString = "connectionString=`"Server=tcp:$($datasource),1433;Initial Catalog=$($catalogDbName);Persist Security Info=False;User ID=$($dbLoginUsername);Password=$($dbLoginPassword);MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`""

            # Replace the connection string using regex and variables
            $webConfigContent = $webConfigContent -replace $connectionStringPattern, $replacementString

        
            # Log the successful update of the connection string
            Write-Host "Connection string updated successfully with the following information:"
            Write-Host "'Datasource' was replaced by $($datasource) successfully."
            Write-Host "'CatalogDbName' was replaced by $($catalogDbName) successfully."
            Write-Host "'DbLoginUsername' was replaced successfully."
            Write-Host "'DbLoginPassword' was replaced successfully."
        }
        catch {
            # Catch any errors that occur during the replacement process
            Write-Host "Error occurred during connection string replacement:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            # Optionally, you can throw the error again to stop the pipeline or script
            throw $_
        }        


        try {
            # Regex to match and replace the serviceUrl value
            $serviceUrlPattern = 'serviceUrl="(?<httpServiceUrl>.*?)"'

            # Replacement string using the passed $httpServiceUrl parameter (without single quotes around the URL)
            $serviceUrlReplacement = "serviceUrl=`"$($serviceUrl)`""

            # Replace the serviceUrl in the web.config content
            $webConfigContent = $webConfigContent -replace $serviceUrlPattern, $serviceUrlReplacement

            # Log the successful update of the service URL
            Write-Host `n
            Write-Host "Service URL updated successfully with the following information:"
            Write-Host "'httpServiceUrl' was replaced by $($serviceUrl) successfully."
        }
        catch {
            # Catch any errors that occur during the replacement process
            Write-Host "Error occurred during service URL replacement:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            # Optionally, rethrow the error to stop the pipeline or script execution
            throw $_
        }


        # Write the updated content back to the web.config file
        Set-Content -Path $filePath -Value $webConfigContent
        Write-Host "web.config file updated successfully."
        
    } else {
        Write-Error "web.config file not found at $filePath"
    }
}

# Call the function to update the connectionString
Update-ConnectionString -websiteName $websiteName `
                        -datasource $datasource `
                        -catalogDbName $catalogDbName `
                        -dbLoginUsername $dbLoginUsername `
                        -dbLoginPassword $dbLoginPassword `
                        -serviceUrl $serviceUrl
