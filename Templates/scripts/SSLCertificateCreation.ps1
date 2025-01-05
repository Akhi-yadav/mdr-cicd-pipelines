param (
    [string]$websiteName,
    [string]$provisioningModel,
    [string]$smuChargeCode,
    [string]$projectChargeCode,
    [string]$certificateOwner,
    [string]$applicationContact,
    [string]$domainName,
    [string]$platformType,
    [string]$deviceName,
    [string]$username,
    [string]$password
)

# # Define the Tower credentials and API URL
# $username = Get-AzKeyVaultSecret -VaultName "EUNUMDRU01AKV01" -Name "AnsibleTowerSP-User" -asplaintext
# $Password = Get-AzKeyVaultSecret -VaultName "EUNUMDRU01AKV01" -Name "AnsibleTowerSP-Password" -asplaintext

$TowerApiUrl = "https://tower.000ukso.sbp.eyclienthub.com:443/api/v2"

# Set the TLS version to ensure secure communication
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create a base64-encoded authorization
# $credPair = "$UserName:$Password"
$credPair = "$('$UserName'):$('$Password')"
$Authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credPair))

# Define the URI to fetch user information
$MeUri = $TowerApiUrl + '/me/'
$MeResult = Invoke-RestMethod -Uri $MeUri -Headers @{ "Authorization" = "Basic $Authorization" ; "Content-Type" = 'application/json'} -ErrorAction Stop -TimeoutSec 180

# Obtain a personal access token (PAT) for the user
$PATUri = $TowerApiUrl + '/users/' + $($MeResult.Results.id) + '/personal_tokens/'
$Tokens = Invoke-RestMethod -Uri $PATUri -Method POST -Headers @{ "Authorization" = "Basic $Authorization" ; "Content-Type" = 'application/json'} -ContentType "application/json"

# Create headers with the PAT for subsequent API requests
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$tokenId = $Tokens.id
$headers.Add("Authorization", "Bearer " + $Tokens.token)

# Define the credentials for SSL
$ansiblecredentials = @(4968,771,1334,1639,4)

# Set the template number for the job to launch (Development or Production)
$templateNumber = 3494

# Define parameters for the job to launch
$bodyParameters = @{
    credentials = $ansiblecredentials
    extra_vars = @{
        var_certificate_name = $websiteName
        var_request_type = "create"
        var_provisioning_model = $provisioningModel
        var_certificate_authority = "1"
        var_smu_chargecode = $smuChargeCode
        var_project_chargecode = $projectChargeCode
        var_certificate_owner = $certificateOwner
        var_application_contact = $applicationContact
        var_domain_name = $domainName
        var_expiration_period = "12"
        var_subject_altname = @()
        var_device_input = @(
            @{
                PlatformType = $platformType
                DeviceName = $deviceName
                ApplicationInput = @(
                    @{
                        TenantName = "eygs.onmicrosoft.com"
                        PasswordRequired = "1"
                    }
                )
            }
        )
        var_schedule_request = @()
    }
}

$bodyParametersJson = $bodyParameters | ConvertTo-Json -Depth 10

# Launch the job using the specified template number and parameters
$urlTemplate = $TowerApiUrl + "/job_templates/" + $templateNumber + "/launch/"
$ansibleResponse = Invoke-RestMethod -Uri $urlTemplate -Method Post -Body $bodyParametersJson -Headers $headers
$ansibleResponse.id

# Specify the jobId of the triggered job associated to the DNS job launched
$jobId = $ansibleResponse.id

# Get the status of the launched job
$urlTemplate = $TowerApiUrl + "/jobs/$($ansibleResponse.id)/"
$ansibleResponse = Invoke-RestMethod -Uri $urlTemplate -Method Get -Headers $headers
$ansibleResponse.status

$x = $ansibleResponse.status
do {
    cls
    sleep 20
    $ansibleResponse = Invoke-RestMethod -Uri $urlTemplate -Method Get -Headers $headers
    $ansibleResponse.status
    $x = $ansibleResponse.status
} while ($x -eq "running")

if ($x -eq "failed") {
    Write-Host "##[error]Job FAILED. Job details: $urlTemplate"
} else {
    Write-Host "##[section]Job SUCCESSFUL. Job details: $urlTemplate"
}

# Delete the personal access token to clean up after the job
$TokenDeleteUri = "$TowerApiUrl/tokens/$tokenId/"
$DeleteResult = Invoke-RestMethod -Uri $TokenDeleteUri -Method Delete -Headers @{ 'Authorization' = "Basic $Authorization" }
