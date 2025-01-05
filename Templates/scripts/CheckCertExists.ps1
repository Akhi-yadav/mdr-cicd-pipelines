# CheckCertExists.ps1
param (
    [parameter(Mandatory = $true)] 
    [string]$websiteName,
    [parameter(Mandatory = $false)]
    [string]$KeyVaultName
)
 
function Check-CertExists {
    param (
        [parameter(Mandatory = $true)] 
        [string]$websiteName,
        [parameter(Mandatory = $false)]
        [string]$KeyVaultName
    )

    $tempCertName = $websiteName -replace '\.', '-'
    $cert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $tempCertName -ErrorAction SilentlyContinue

    if ($cert) {
        Write-Host "The certificate '$tempCertName' already exists in the Key Vault '$KeyVaultName'."
        Write-Host "##vso[task.setvariable variable=certExists;]true"
    } else {
        Write-Host "The certificate '$tempCertName' does not exist in the Key Vault '$KeyVaultName'."
        Write-Host "##vso[task.setvariable variable=certExists;]false"
    }
}

 Check-CertExists -websiteName $websiteName -KeyVaultName $KeyVaultName
