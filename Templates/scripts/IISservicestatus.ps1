param(
  [Parameter(Mandatory = $false)]
        [switch]$stopIIS, 
        [switch]$startIIS
)


function stopIIS {

    $serviceStatus = Get-Service -Name "W3SVC"

    if ($serviceStatus.Status -eq "Running") {
        Write-Host "IIS service is running. Stopping it..."
        Stop-Service -Name "W3SVC"
        Write-Host "IIS service has been stopped."
    } elseif ($serviceStatus.Status -eq "Stopped") {
        Write-Host "IIS service is already stopped."
    } else {
        Write-Host "IIS service is in an unknown state: $($serviceStatus.Status)"
    }
}

function startIIS {

    $serviceStatus = Get-Service -Name "W3SVC"

    if ($serviceStatus.Status -eq "Running") {
        Write-Host "IIS service is running."
    } elseif ($serviceStatus.Status -eq "Stopped") {
        Start-Service -Name "W3SVC"
        Write-Host "IIS service is started"
    }
}

# Start IIS if the start flag is provided
if ($startIIS) {
    startIIS
}

# Stop IIS if the stop flag is provided
if ($stopIIS) {
    stopIIS
}

