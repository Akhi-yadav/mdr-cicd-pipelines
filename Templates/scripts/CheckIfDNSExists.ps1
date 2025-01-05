param (
    [parameter(Mandatory = $true)]
    [string]$websiteName
)
function Check-IfDNSExists {
    param (
        [parameter(Mandatory = $true)]
        [string]$websiteName
    )
    # Define the DNS record to check
    $dnsRecord = $websiteName

    # Perform the DNS query using nslookup
    $dnsResult = nslookup $dnsRecord 2>$null

    if ($dnsResult -match "Name:") {
        Write-Output "DNS record '$dnsRecord' exists. Exiting script."
        Write-Host "##vso[task.setvariable variable=DNSExists;]true"
        return $true
    } else {
        Write-Output "DNS record '$dnsRecord' does not exist. It needs to be created."
        Write-Host "##vso[task.setvariable variable=DNSExists;]false"
        return $false
    }
}
Check-IfDNSExists -websiteName $websiteName
