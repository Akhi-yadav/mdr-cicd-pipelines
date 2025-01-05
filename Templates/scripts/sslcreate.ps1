param(
    [string]$websiteName,
    [string]$provisioningModel,
    [string]$smuChargeCode,
    [string]$projectChargeCode,
    [string]$certificateOwner,
    [string]$applicationContact,
    [string]$domainName,
    [string]$platformType,
    [string]$deviceName,
    [string]$KeyVaultName
    )

# **Step 1: Check if the Certificate Exists**

$tempCertName = $websiteName -replace '\.', '-'
$cert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $tempCertName -ErrorAction SilentlyContinue

if ($cert) {
    Write-Host "The certificate '$tempCertName' already exists in the Key Vault '$KeyVaultName'."
    Write-Host "Certificate already exists. Exiting script."
    exit 0
} else {
    Write-Host "The certificate '$tempCertName' does not exist in the Key Vault '$KeyVaultName'."
}

# **Step 2: Retrieve Ansible Tower Credentials from Key Vault**

# Retrieve secrets from Key Vault
$AnsibleTowerUserSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'AnsibleTowerSP-User'
$AnsibleTowerPasswordSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'AnsibleTowerSP-Password'

$AnsibleTowerUser = $AnsibleTowerUserSecret.SecretValueText
$AnsibleTowerPassword = $AnsibleTowerPasswordSecret.SecretValueText
Write-Host "print the username:$AnsibleTowerUser,password:$AnsibleTowerPassword"


# **Step 3: Interact with Ansible Tower API**

# Define the Tower credentials and API URL
$TowerApiUrl = "https://tower.000ukso.sbp.eyclienthub.com:443/api/v2"

# Set the TLS version to ensure secure communication
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create a base64-encoded authorization
# $credPair = "$AnsibleTowerUser:$AnsibleTowerPassword"
$credPair = "$('$($AnsibleTowerUser)'):$('$($AnsibleTowerPassword)')"
$Authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credPair))

# Define the URI to fetch user information
$MeUri = "$TowerApiUrl/me/"
$MeResult = Invoke-RestMethod -Uri $MeUri -Headers @{ "Authorization" = "Basic $Authorization"; "Content-Type" = 'application/json' } -ErrorAction Stop -TimeoutSec 180

# Obtain a personal access token (PAT) for the user
$PATUri = "$TowerApiUrl/users/$($MeResult.id)/personal_tokens/"
$Tokens = Invoke-RestMethod -Uri $PATUri -Method POST -Headers @{ "Authorization" = "Basic $Authorization"; "Content-Type" = 'application/json' } -ContentType "application/json"

# Create headers with the PAT for subsequent API requests
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $($Tokens.token)"
}
$tokenId = $Tokens.id

# **Step 4: Prepare Parameters for the Job Launch**

# # Retrieve variables from environment variables
# $provisioningModel   = $env:provisioningModel
# $smuChargeCode       = $env:smuChargeCode
# $projectChargeCode   = $env:projectChargeCode
# $certificateOwner    = $env:certificateOwner
# $applicationContact  = $env:applicationContact
# $domainName          = $env:domainName
# $platformType        = $env:platformType
# $deviceName          = $env:deviceName
# $certName            = $tempCertName  # Using the same name as $tempCertName

# Define the credentials for SSL
$ansiblecredentials = @(4968,771,1334,1639,4)

# Set the template number for the job to launch (Development or Production)
$templateNumber = 3494

# Define parameters for the job to launch
$bodyParameters = @{
    credentials = $ansiblecredentials  # Call to Ansible Job Credentials
    extra_vars = @{
        var_certificate_name      = $websiteName
        var_request_type          = "create"
        var_provisioning_model    = $provisioningModel
        var_certificate_authority = "1"
        var_smu_chargecode        = $smuChargeCode
        var_project_chargecode    = $projectChargeCode
        var_certificate_owner     = $certificateOwner
        var_application_contact   = $applicationContact
        var_domain_name           = $domainName
        var_expiration_period     = "12"
        var_subject_altname       = @()
        var_device_input          = @(
            @{
                PlatformType     = $platformType
                DeviceName       = $deviceName
                ApplicationInput = @(
                    @{
                        TenantName       = "eygs.onmicrosoft.com"
                        PasswordRequired = "1"
                    }
                )
            }
        )
        var_schedule_request = @()
    }
}

$bodyParametersJson = $bodyParameters | ConvertTo-Json -Depth 10

# **Step 5: Launch the Job**

# Launch the job using the specified template number and parameters
$urlTemplate = "$TowerApiUrl/job_templates/$templateNumber/launch/"
$ansibleResponse = Invoke-RestMethod -Uri $urlTemplate -Method Post -Body $bodyParametersJson -Headers $headers

# Specify the jobId of the triggered job associated with the SSL certificate creation
$jobId = $ansibleResponse.id

# Get the status of the launched job
$urlJobStatus = "$TowerApiUrl/jobs/$jobId/"
$ansibleResponse = Invoke-RestMethod -Uri $urlJobStatus -Method Get -Headers $headers
$x = $ansibleResponse.status

do {
    Clear-Host
    Start-Sleep -Seconds 20
    $ansibleResponse = Invoke-RestMethod -Uri $urlJobStatus -Method Get -Headers $headers
    $x = $ansibleResponse.status
    Write-Host "Job Status: $x"
} while ($x -eq "running")

if ($x -eq "failed") {
    Write-Host "##[error]Job FAILED. Job details: $urlJobStatus"
    exit 1
} else {
    Write-Host "##[section]Job SUCCESSFUL. Job details: $urlJobStatus"
}

# **Step 6: Clean Up**

# Delete the personal access token to clean up after the job
$TokenDeleteUri = "$TowerApiUrl/tokens/$tokenId/"
$DeleteResult = Invoke-RestMethod -Uri $TokenDeleteUri -Method Delete -Headers @{ 'Authorization' = "Basic $Authorization" }

# **Step 7: Verify the Creation of the SSL Certificate**

if ($x -eq "successful") {
    $attempt     = 0
    $maxAttempts = 5
    $seconds     = 10
    do {
        $attempt++
        $cert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $tempCertName -ErrorAction SilentlyContinue
        if ($cert) {
            Write-Host "Certificate '$tempCertName' found in Key Vault."
            break
        } else {
            Write-Host "Certificate not found. Retrying... Attempt $attempt of $maxAttempts."
            Start-Sleep -Seconds $seconds
        }
    } while ($attempt -lt $maxAttempts)

    if (-not $cert) {
        Write-Host "##[error]Maximum attempts reached. Certificate '$tempCertName' not found."
        exit 1
    }
}
